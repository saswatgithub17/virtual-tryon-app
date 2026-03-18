// Mock modules at the very top
jest.mock('../config/database', () => ({
  query: jest.fn(),
  execute: jest.fn(),
  on: jest.fn(),
  connect: jest.fn((cb) => cb && cb(null))
}));

const mockStripe = {
  paymentIntents: {
    create: jest.fn()
  }
};

jest.mock('stripe', () => {
  return jest.fn().mockImplementation(() => mockStripe);
});

jest.mock('../middleware/auth', () => ({
  verifyToken: jest.fn((req, res, next) => {
    req.user = { id: 1, email: 'test@example.com', role: 'user' };
    next();
  }),
  isAdmin: jest.fn((req, res, next) => {
    next();
  })
}));

const request = require('supertest');
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const mockDb = require('../config/database');
const authMiddleware = require('../middleware/auth');

const dressRoutes = require('../routes/dressRoutes');
const orderRoutes = require('../routes/orderRoutes');
const paymentRoutes = require('../routes/paymentRoutes');
const reviewRoutes = require('../routes/reviewRoutes');
const tryonRoutes = require('../routes/tryonRoutes');
const adminRoutes = require('../routes/adminRoutes');

const { specs, swaggerUi } = require('../config/swagger');

const createApp = () => {
  const app = express();
  app.use(cors());
  app.use(bodyParser.json());
  app.use(bodyParser.urlencoded({ extended: true }));
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
  app.use('/api/dresses', dressRoutes);
  app.use('/api/orders', orderRoutes);
  app.use('/api/payments', paymentRoutes);
  app.use('/api/reviews', reviewRoutes);
  app.use('/api/tryon', tryonRoutes);
  app.use('/api/admin', adminRoutes);
  app.get('/', (req, res) => {
    res.status(200).json({ success: true, message: 'API is running' });
  });
  return app;
};

describe('API Routes', () => {
  let app;

  beforeEach(() => {
    app = createApp();
    jest.clearAllMocks();
    authMiddleware.verifyToken.mockImplementation((req, res, next) => {
      req.user = { id: 1, email: 'test@example.com', role: 'admin' };
      next();
    });
    authMiddleware.isAdmin.mockImplementation((req, res, next) => next());
  });

  describe('Base and Swagger Routes', () => {
    it('should return 200 for health check', async () => {
      const response = await request(app).get('/').expect(200);
      expect(response.body).toEqual({ success: true, message: 'API is running' });
    });

    it('should return 200 for Swagger UI', async () => {
      const response = await request(app).get('/api-docs/').expect(200);
      expect(response.text).toContain('swagger');
    });
  });

  describe('Dress Routes', () => {
    describe('GET /api/dresses', () => {
      it('should return all dresses', async () => {
        const mockData = [{ dress_id: 1, name: 'Test', price: 99.99, sizes: 'S:10' }];
        mockDb.query.mockImplementation((q, p, cb) => cb ? cb(null, mockData) : p(null, mockData));
        const res = await request(app).get('/api/dresses').expect(200);
        expect(res.body.success).toBe(true);
      });
    });

    describe('POST /api/dresses', () => {
      it('should create a new dress', async () => {
        mockDb.query.mockImplementation((q, p, cb) => (cb || p)(null, { insertId: 1 }));
        const res = await request(app)
          .post('/api/dresses')
          .send({ name: 'New', price: 99, image_url: 'test.jpg' })
          .expect(201);
        expect(res.body.success).toBe(true);
      });
    });
  });

  describe('Order Routes', () => {
    it('should create order', async () => {
      mockDb.query.mockImplementation((q, p, cb) => {
        const callback = cb || p;
        if (q.includes('SELECT')) callback(null, [{ dress_id: 1, price: 10 }]);
        else callback(null, { insertId: 1 });
      });
      const res = await request(app)
        .post('/api/orders')
        .send({ customer_name: 'Test', customer_email: 't@t.com', items: [{ dress_id: 1 }] })
        .expect(201);
      expect(res.body.success).toBe(true);
    });
  });
});
