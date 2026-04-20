# Inventory Management System
Hotel inventory management system for Crowne Plaza Dushanbe.

## Stack
- **Backend** — FastAPI, PostgreSQL 15, Redis, Celery, MinIO
- **Admin** — React
- **Mobile** — Flutter (Android/iOS), offline-capable with barcode scanning

## Requirements
- Docker & Docker Compose
- Flutter SDK (for mobile)

## Quick Start

```bash
# 1. Start all services
make up

# 2. Run database migrations
make migrate

# 3. Create admin user
make admin USERNAME=admin PASSWORD=yourpassword FULLNAME="Your Name"
```

## Services

| Service | URL |
|---------|-----|
| Backend API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| MinIO Console | http://localhost:9001 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

## Environment Variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Key variables:

| Variable | Description |
|----------|-------------|
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `REDIS_PASSWORD` | Redis password |
| `JWT_SECRET_KEY` | Secret key for JWT tokens (use `openssl rand -hex 32`) |
| `MINIO_ROOT_PASSWORD` | MinIO admin password |
| `CORS_ORIGINS` | Allowed origins for CORS |

## Make Commands

```bash
make up            # Start all services
make down          # Stop all services
make migrate       # Run database migrations
make migrate-down  # Rollback last migration
make admin         # Create admin user
make logs          # Follow backend logs
make shell         # Open bash inside backend container
make test          # Run tests
make lint          # Run linter
```

## Mobile App

```bash
# Generate code (run once after pulling)
make mobile-gen

# Run on connected device/emulator
cd mobile && flutter run

# Build APK pointing to production server
flutter build apk --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:8000/api/v1
```

The APK will be at `mobile/build/app/outputs/flutter-apk/app-release.apk`.

## Deployment

```bash
# On the server
git clone https://github.com/Dzheka/inventory.git
cd inventory
cp .env.example .env
# Edit .env with production values
make up
make migrate
make admin USERNAME=admin PASSWORD=strongpassword FULLNAME="Administrator"
```
