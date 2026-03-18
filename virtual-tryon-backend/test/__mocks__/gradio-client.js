// Mock for @gradio/client
const mockClient = {
  predict: jest.fn(),
  view_api: jest.fn()
};

module.exports = {
  Client: jest.fn().mockImplementation(() => mockClient)
};