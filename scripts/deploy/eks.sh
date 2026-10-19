#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

: "${GITHUB_SHA:?}"
: "${GITHUB_RUN_ID:?}"
: "${GITHUB_RUN_ATTEMPT:?}"
: "${RUNNER_TEMP:?}"
: "${GITHUB_STEP_SUMMARY:?}"

export AWS_REGION=ap-southeast-2
export AWS_PAGER=""

DEPLOY_DIR="$(mktemp -d "$RUNNER_TEMP/wanderlust-deploy.XXXXXX")"
trap 'rm -rf -- "$DEPLOY_DIR"' EXIT
export KUBECONFIG="$DEPLOY_DIR/kubeconfig"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
test "$ACCOUNT_ID" = "895196059533"

REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_TAG="$GITHUB_SHA-$GITHUB_RUN_ID-$GITHUB_RUN_ATTEMPT"

declare -A images
for app in backend frontend; do
  digest="$(aws ecr describe-images \
    --region "$AWS_REGION" \
    --repository-name "wanderlust-$app" \
    --image-ids "imageTag=$IMAGE_TAG" \
    --query 'imageDetails[0].imageDigest' \
    --output text)"

  [[ "$digest" =~ ^sha256:[0-9a-f]{64}$ ]] || {
    echo "::error::Invalid ECR digest for $app"
    exit 1
  }
  images[$app]="$REGISTRY/wanderlust-$app@$digest"
done

aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name wanderlust-eks \
  --alias wanderlust-eks

kube() {
  kubectl --context wanderlust-eks \
    --namespace wanderlust --request-timeout=20s "$@"
}

# Verify access to both existing deployments before updating either.
for app in backend frontend; do
  kube get deployment "$app" -o name
  test "$(kube auth can-i patch "deployment/$app")" = "yes"
done

for app in backend frontend; do
  previous="$(kube get deployment "$app" \
    -o "jsonpath={.spec.template.spec.containers[?(@.name=='$app')].image}")"

  {
    printf '\n### EKS deployment: %s\n' "$app"
    printf 'Previous: `%s`\n\n' "$previous"
    printf 'Requested: `%s`\n' "${images[$app]}"
  } >> "$GITHUB_STEP_SUMMARY"

  kube set image "deployment/$app" "$app=${images[$app]}"

  ready=0
  for attempt in $(seq 1 60); do
    # Poll by name; no namespace-wide deployment list permission required.
    if kube rollout status "deployment/$app" --watch=false; then
      ready=1
      break
    fi
    sleep 5
  done

  if [ "$ready" -ne 1 ]; then
    echo "::error::$app rollout did not complete; inspect deployment before retrying."
    exit 1
  fi

  actual="$(kube get deployment "$app" \
    -o "jsonpath={.spec.template.spec.containers[?(@.name=='$app')].image}")"
  test "$actual" = "${images[$app]}"

  printf '\nRollout verified: **%s**\n' "$app" >> "$GITHUB_STEP_SUMMARY"
done
