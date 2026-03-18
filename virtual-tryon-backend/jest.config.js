module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/test/**/*.test.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  transform: {},
  transformIgnorePatterns: [
    'node_modules/(?!(mysql2)/)'
  ],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '@gradio/client': '<rootDir>/test/__mocks__/gradio-client.js'
  },
  setupFilesAfterEnv: ['<rootDir>/test/setup.js'],
  testTimeout: 10000
};
