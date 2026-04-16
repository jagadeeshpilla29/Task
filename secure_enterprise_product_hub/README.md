# Secure Enterprise Product Hub

Secure Enterprise Product Hub is a Flutter mobile app with a FastAPI backend. It supports JWT authentication, role-based access control, product CRUD, image upload, search, category filtering, pagination, and MongoDB indexes for common product queries.

## Tech Stack

- Flutter, clean feature folders, Cubit-style state classes
- Secure token storage with `flutter_secure_storage`
- FastAPI, Motor, MongoDB
- JWT access tokens with admin/user RBAC
- Multipart product image upload

## Project Structure

```text
backend/
  app/
    api/                  # Thin FastAPI route controllers and auth dependencies
    core/                 # Config, MongoDB client, JWT/password helpers
    models/               # Shared ObjectId/serialization helpers
    repositories/         # MongoDB data access classes
    schemas/              # Pydantic request/response models
    services/             # Auth, product, and file-upload business logic
lib/
  core/             # API client, secure storage, Cubit base
  features/
    auth/
      data/
        datasources/      # Remote API calls and token persistence
        models/           # JSON models
        repositories/     # Repository implementation
      domain/
        entities/         # Plain business entities
        repositories/     # Abstract repository contracts
        usecases/         # Login, register, logout, restore session
      presentation/
        cubit/            # Cubit and state
        screens/          # Login/register UI
    products/
      data/
        datasources/      # Product API calls and upload calls
        models/           # JSON models and page model
        repositories/     # Repository implementation
      domain/
        entities/         # Product and pagination entities
        repositories/     # Abstract product repository
        usecases/         # CRUD, list, details, image upload
      presentation/
        cubit/            # Products cubit and state
        screens/          # Dashboard, details, form UI
```

## Backend Setup

1. Create and activate a Python environment.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

2. Start MongoDB locally or update `.env` with your MongoDB URI.

3. Run the API.

```bash
uvicorn app.main:app --reload
```

The API runs at `http://localhost:8000`.

## Backend Environment Variables

All backend variables use the `SPH_` prefix.

```env
SPH_MONGO_URI=mongodb://localhost:27017
SPH_MONGO_DB=secure_product_hub
SPH_JWT_SECRET=replace-with-a-long-random-secret
SPH_ACCESS_TOKEN_MINUTES=60
SPH_PUBLIC_BASE_URL=http://localhost:8000
```

## Flutter Setup

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

For Android emulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

The app stores the JWT in secure storage, restores the session on launch, and clears the token on logout.

## Demo Credentials

Use these accounts for testing role-based access.

| Role | Email | Password | Access |
| --- | --- | --- | --- |
| Admin | `admin@example.com` | `Password123` | Add, edit, delete, upload images, view products |
| User | `user@example.com` | `Password123` | View products, search, filter, pagination |

If the database is empty, create the accounts from the app registration screen or with the register API.

## API Documentation

### Register

`POST /api/auth/register`

```json
{
  "name": "Admin User",
  "email": "admin@example.com",
  "password": "Password123",
  "role": "admin"
}
```

Response `201`:

```json
{
  "success": true,
  "message": "User registered successfully"
}
```

### Login

`POST /api/auth/login`

```json
{
  "email": "admin@example.com",
  "password": "Password123"
}
```

Response `200`:

```json
{
  "success": true,
  "data": {
    "accessToken": "jwt_token_here",
    "expiresIn": 3600
  }
}
```

### Current User

`GET /api/auth/me`

Header:

```text
Authorization: Bearer <jwt_token>
```

### Logout

`POST /api/auth/logout`

Protected route. The mobile app also clears the local secure token.

### List Products

`GET /api/products?page=1&limit=10&search=laptop&category=electronics`

Roles: user, admin

Response:

```json
{
  "success": true,
  "data": {
    "products": [],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 120
    }
  }
}
```

### Create Product

`POST /api/products`

Role: admin

```json
{
  "name": "MacBook Pro",
  "price": 2500,
  "currency": "USD",
  "category": "electronics"
}
```

### Product Details

`GET /api/products/{id}`

Roles: user, admin

### Update Product

`PUT /api/products/{id}`

Role: admin

```json
{
  "name": "MacBook Pro M3",
  "price": 2700,
  "currency": "INR",
  "category": "electronics"
}
```

### Delete Product

`DELETE /api/products/{id}`

Role: admin. Returns `204 No Content`.

### Upload Product Image

`POST /api/products/{id}/image`

Role: admin. Multipart form field name: `image`.

Response:

```json
{
  "success": true,
  "imageUrl": "http://localhost:8000/uploads/product.png"
}
```

## MongoDB Index Definitions

Indexes are created during FastAPI startup in `backend/app/core/database.py`.

Product documents include:

```json
{
  "_id": "ObjectId",
  "name": "string",
  "price": 2500,
  "currency": "USD",
  "category": "electronics",
  "imageUrl": "http://localhost:8000/uploads/product.png",
  "createdBy": "ObjectId",
  "createdAt": "date",
  "updatedAt": "date"
}
```

```python
await db.users.create_index("email", unique=True)
await db.products.create_index([("name", TEXT)])
await db.products.create_index([("category", ASCENDING)])
await db.products.create_index([("name", ASCENDING), ("category", ASCENDING)])
await db.products.create_index([("createdAt", ASCENDING)])
```

## Security Notes

- JWT is required for every product route.
- Admin-only dependencies protect create, update, delete, and image upload routes.
- Passwords are stored as bcrypt hashes.
- Flutter sends `Authorization: Bearer <token>` automatically through the API client.
- Users can view products only; admins get add, edit, delete, and image upload controls.
- Flutter prints every API request and response in the debug console.
- FastAPI prints every API method, path, status code, and duration in the backend console.

## Validation And Error Handling

The backend returns structured error responses for:

- `400` validation errors
- `401` missing or invalid JWT
- `403` non-admin access to admin routes
- `404` missing products
- `500` unexpected server errors

## Verification

```bash
flutter analyze
flutter test
python3 -m py_compile backend/app/main.py backend/app/api/auth.py backend/app/api/products.py backend/app/api/dependencies.py backend/app/core/config.py backend/app/core/database.py backend/app/core/security.py backend/app/models/common.py backend/app/schemas/auth.py backend/app/schemas/product.py
```
