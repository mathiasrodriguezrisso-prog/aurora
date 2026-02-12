# 🌱 Aurora — Cannabis Cultivation Companion

> AI-powered cannabis cultivation assistant with social community, grow tracking, and intelligent recommendations.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter 3.x (Dart), Riverpod, GoRouter |
| **Backend** | Python, FastAPI, Pydantic |
| **Database** | Supabase (PostgreSQL + Auth + Storage) |
| **AI** | Groq LLM API (mixtral/llama3) |
| **Design** | Glassmorphism dark theme, Material 3 |

## Architecture

```
aurora/
├── lib/                          # Flutter frontend
│   ├── core/
│   │   ├── config/               # app_router, app_theme, env_config
│   │   ├── network/              # api_client (Dio + interceptors)
│   │   └── presentation/         # main_scaffold, aurora_bottom_nav
│   ├── shared/widgets/           # glass_container, aurora_button, shimmer, etc.
│   └── features/
│       ├── auth/                 # login, register, splash
│       ├── dashboard/            # home_screen, widgets (cycle, daily_ops, stats)
│       ├── grow/                 # grow_active, growing plan flow
│       ├── social/               # feed, post_card, create_post, post_detail
│       ├── profile/              # profile, edit_profile, settings
│       └── chat/                 # AI chat interface
├── backend/
│   └── app/
│       ├── main.py               # FastAPI app entry
│       ├── config.py             # Settings (pydantic-settings)
│       ├── dependencies.py       # Supabase client, auth dependency
│       ├── routers/              # social, users, tasks, sensors, grow, chat, health
│       └── services/             # alert_service, image_service
└── pubspec.yaml
```

## Quick Start

### Backend

```bash
cd backend
python -m venv venv
venv\Scripts\activate        # Windows
# source venv/bin/activate   # macOS/Linux

pip install -r requirements.txt
cp .env.example .env         # Edit with your Supabase & Groq keys
uvicorn app.main:app --reload --port 8000
```

Backend docs: http://localhost:8000/docs

### Frontend

```bash
# From project root
flutter pub get
flutter run
```

> **Note**: Update `lib/core/config/env_config.dart` with your backend URL and Supabase credentials.

## API Endpoints (25 total)

| Router | Prefix | Endpoints |
|--------|--------|-----------|
| Social | `/social` | `GET /feed`, `POST /posts`, `GET /posts/{id}`, `POST /posts/{id}/like`, `GET /posts/{id}/comments`, `POST /posts/{id}/comments`, `POST /report` |
| Users | `/users` | `GET /me`, `PATCH /me`, `GET /{id}`, `GET /me/stats`, `GET /me/settings`, `PATCH /me/settings` |
| Tasks | `/tasks` | `GET /today`, `PATCH /{id}`, `POST /generate`, `GET /history` |
| Sensors | `/sensors` | `POST /readings`, `GET /latest/{id}`, `GET /history/{id}`, `GET /alerts`, `PATCH /alerts/{id}/read` |

## Key Features

- **AI Grow Plans** — Generates customized cultivation plans using Groq LLM
- **Social Feed** — Community posts with likes, comments, and strain tags
- **Sensor Monitoring** — Track temperature, humidity, pH with auto-alerts and VPD calculation
- **Daily Tasks** — Auto-generated checklists based on active grow plans
- **Glassmorphism UI** — Dark theme with blur effects, neon accents, and smooth animations

## Environment Variables

See [`backend/.env.example`](backend/.env.example) for the complete list.

## License

Private — All rights reserved.
