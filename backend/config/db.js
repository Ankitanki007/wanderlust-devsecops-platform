import mongoose from 'mongoose';
import { MONGODB_URI } from './utils.js';

export default function connectDB() {
  mongoose.connection.once('open', () => {
    console.log('Database connected');
  });

  mongoose.connection.on('error', () => {
    console.error('Database connection error');
  });

  mongoose.connect(MONGODB_URI).catch(() => {
    console.error('Initial database connection failed');
    process.exit(1);
  });
}
