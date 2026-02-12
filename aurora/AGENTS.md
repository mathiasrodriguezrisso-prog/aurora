# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Aurora is an AI-powered cannabis cultivation companion with a Flutter frontend and Python/FastAPI backend. Uses Supabase (PostgreSQL + Auth + Storage) and Groq LLM for AI features.

## Development Commands

### Backend (from `backend/` directory)
```powershell
# Setup (first time)
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env

# Run server
uvicorn app.main:app --reload --port 8000

# API docs available at http://localhost:8000/docs
```

### Frontend (from `aurora/` root)
```powershell
# Install dependencies
flutter pub get

# Run code generators (freezed, riverpod_generator, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation during development
dart run build_runner watch --delete-conflicting-outputs

# Run app
flutter run

# Analyze code
flutter analyze
```

### Configuration
- Backend: Copy `backend/.env.example` to `backend/.env`
- Frontend: Environment via `--dart-define` flags or defaults in `lib/core/config/env_config.dart`
- Android emulator uses `10.0.2.2` for localhost backend automatically

## Architecture

### Frontend (`lib/`)
Feature-based clean architecture:
```
lib/
├── core/                    # Cross-cutting concerns
│   ├── config/              # app_router, app_theme, env_config
│   ├── network/             # api_client (Dio with interceptors)
│   └── presentation/        # main_scaffold, aurora_bottom_nav
├── shared/widgets/          # Reusable glassmorphism widgets
└── features/{feature}/
    ├── data/
    │   ├── datasources/     # Remote/local data sources
    │   ├── models/          # DTOs with freezed/json_serializable
    │   └── repositories/    # Repository implementations
    ├── domain/
    │   ├── entities/        # Business models
    │   ├── repositories/    # Repository interfaces
    │   └── usecases/        # Business logic
    └── presentation/
        ├── providers/       # Riverpod providers
        ├── screens/         # Page widgets
        └── widgets/         # Feature-specific widgets
```

**Key patterns:**
- State management: Riverpod (`flutter_riverpod`, `riverpod_annotation`)
- Navigation: GoRouter with `StatefulShellRoute` for persistent bottom nav
- Models: Use `@freezed` for immutable data classes, `@JsonSerializable` for DTOs
- HTTP: Dio client at `core/network/api_client.dart`

### Backend (`backend/app/`)
```
app/
├── main.py              # FastAPI entry, CORS, middleware, router registration
├── config.py            # pydantic-settings configuration
├── dependencies.py      # Dependency injection (Supabase, Groq clients)
├── models.py            # Pydantic models
├── routers/             # API endpoints by domain (social, users, tasks, etc.)
├── services/            # Business logic (ai_service, chat_service, rag_service)
└── core/                # Scheduler, utilities
```

**API routers:** `/social`, `/users`, `/tasks`, `/sensors`, `/grow`, `/chat`, `/health`, `/media`

## Database

Supabase PostgreSQL with migrations in `supabase/migrations/`. Key tables include `profiles`, `posts`, `grows`, `tasks`, `sensor_readings`.

## Code Style

### Flutter/Dart
- Follow existing glassmorphism widget patterns in `shared/widgets/`
- New features should include all three layers (data/domain/presentation)
- Use `CustomTransitionPage` with slide/fade animations for route transitions
- Widget files named with `_screen.dart` for pages, `_widget.dart` for components

### Python
- Async endpoints preferred
- Use Pydantic models for request/response validation
- Services contain business logic; routers are thin
- Routers imported lazily in `main.py` for incremental development

## Environment Variables

**Backend** (in `backend/.env`):
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- `GROQ_API_KEY`
- `ENVIRONMENT`, `DEBUG`, `CORS_ORIGINS`

**Frontend** (via `--dart-define`):
- `APP_ENV`, `BACKEND_HOST`, `BACKEND_PORT`
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
