# Virtual Try-On Backend API

REST API for Virtual Try-On E-commerce Application

## 🚀 Features

- ✅ RESTful API architecture
- ✅ MySQL database integration (XAMPP)
- ✅ JWT authentication for admin
- ✅ File upload handling (Multer)
- ✅ Stripe payment integration
- ✅ AI-powered virtual try-on
- ✅ PDF receipt generation
- ✅ CORS enabled
- ✅ Error handling

## 📋 Prerequisites

- Node.js (v16+)
- XAMPP (MySQL)
- Stripe Account (for payments)
- Hugging Face API Key (for AI try-on)

## 🛠️ Installation

```bash
# Install dependencies
npm install

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Start server
npm start

# Development mode (auto-restart)
npm run dev
```

## 📡 API Endpoints

### Public Endpoints

#### Dresses
- `GET /api/dresses` - Get all dresses
- `GET /api/dresses/:id` - Get dress details
- `GET /api/dresses/search/query` - Search dresses

#### Reviews
- `GET /api/reviews/:dressId` - Get dress reviews
- `POST /api/reviews` - Add review

#### Orders
- `POST /api/orders` - Create order
- `GET /api/orders/:orderId` - Get order details
- `POST /api/orders/calculate` - Calculate total

#### Payment
- `POST /api/payment/create-intent` - Create payment intent
- `POST /api/payment/confirm` - Confirm payment

#### Try-On
- `POST /api/tryon` - Process virtual try-on

### Admin Endpoints (Requires Authentication)

#### Authentication
- `POST /api/admin/login` - Admin login

#### Dress Management
- `POST /api/dresses` - Add dress
- `PUT /api/dresses/:id` - Update dress
- `DELETE /api/dresses/:id` - Delete dress
- `POST /api/dresses/upload` - Upload dress image

#### Analytics
- `GET /api/admin/analytics` - Get sales analytics
- `GET /api/admin/transactions` - Get all transactions

## 🔐 Authentication

Admin endpoints require JWT token in Authorization header:

```
Authorization: Bearer <token>
```

Get token by calling `/api/admin/login`

## 📁 Project Structure

```
virtual-tryon-backend/
├── config/          # Configuration files
├── controllers/     # Business logic
├── routes/          # API routes
├── middleware/      # Custom middleware
├── services/        # External services
├── uploads/         # Uploaded files
├── server.js        # Entry point
└── package.json     # Dependencies
```

## 🌍 Environment Variables

Create `.env` file with:

```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=virtual_tryon_db
JWT_SECRET=your_secret_key
STRIPE_SECRET_KEY=sk_test_...
HUGGINGFACE_API_KEY=hf_...
```

## 🧪 Testing

Use Postman or any API client:

```bash
# Health check
GET http://localhost:5000

# Get dresses
GET http://localhost:5000/api/dresses

# Admin login
POST http://localhost:5000/api/admin/login
{
  "username": "admin",
  "password": "admin123"
}
```

## 📝 License

ISC

## 👨‍💻 Author

Saswat Suman Dwibedy