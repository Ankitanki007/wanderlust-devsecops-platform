const fs = require('node:fs');

const [reportPath, lockPath] = process.argv.slice(2);

try {
  const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
  const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));

  if (
    report.error ||
    report.auditReportVersion !== 2 ||
    !report.vulnerabilities ||
    !report.metadata?.vulnerabilities ||
    !lock.packages
  ) {
    throw new Error('Missing or invalid audit/lockfile data');
  }

  const exceptionUrl =
    'https://github.com/advisories/GHSA-vfj7-8cjw-p6xm';
  const expires = Date.parse('2026-11-18T00:00:00Z');

  const blockers = new Set();
  const accepted = new Set();

  function inspect(name, visiting = new Set()) {
    if (visiting.has(name)) return;

    const finding = report.vulnerabilities[name];
    if (!finding || !Array.isArray(finding.via) || !finding.via.length) {
      throw new Error(`Incomplete advisory chain: ${name}`);
    }

    const next = new Set(visiting);
    next.add(name);

    for (const via of finding.via) {
      if (typeof via === 'string') {
        inspect(via, next);
        continue;
      }

      if (!via || typeof via !== 'object' || !via.severity) {
        throw new Error(`Invalid advisory: ${name}`);
      }

      if (!['high', 'critical'].includes(via.severity)) continue;

      const scopedException =
        name === 'braces' &&
        via.url === exceptionUrl &&
        via.severity === 'high' &&
        Date.now() < expires &&
        Array.isArray(finding.nodes) &&
        finding.nodes.length > 0 &&
        finding.nodes.every((path) => {
          const pkg = lock.packages[path];
          return pkg?.version === '3.0.3' && pkg.dev === true;
        });

      if (scopedException) {
        accepted.add(via.url);
      } else {
        blockers.add(`${name}: ${via.url || via.title || 'unknown advisory'}`);
      }
    }
  }

  // Inspect every package, including underlying advisories reached
  // through npm's transitive vulnerability chains.
  for (const name of Object.keys(report.vulnerabilities)) {
    inspect(name);
  }

  console.log('Audit counts:', report.metadata.vulnerabilities);

  for (const advisory of accepted) {
    console.log(`TEMPORARY EXCEPTION until 2026-11-18: ${advisory}`);
  }

  for (const blocker of blockers) {
    console.error(`BLOCKED: ${blocker}`);
  }

  process.exitCode = blockers.size ? 1 : 0;
} catch (error) {
  console.error(`Audit policy failed: ${error.message}`);
  process.exitCode = 1;
}
