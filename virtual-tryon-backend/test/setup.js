// Test setup file to configure Jest environment
process.env.NODE_ENV = 'test';

// Mock global database connection
global.db = {
  execute: jest.fn(),
  query: jest.fn()
};

// Mock Stripe
global.stripe = {
  paymentIntents: {
    create: jest.fn()
  }
};

// Suppress console errors during tests
const originalConsoleError = console.error;
console.error = jest.fn();

// Restore console.error after tests
afterAll(() => {
  console.error = originalConsoleError;
});