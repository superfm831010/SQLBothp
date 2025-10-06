# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SQLBot is an intelligent text-to-SQL system based on large language models (LLMs) and RAG (Retrieval-Augmented Generation). It allows users to query databases using natural language and generates SQL queries, visualizations, and analytics.

The system consists of three main components:
- **Backend**: FastAPI application (Python 3.11) with LangChain/LangGraph for LLM orchestration
- **Frontend**: Vue 3 + TypeScript + Element Plus UI
- **G2-SSR**: Node.js service for server-side chart rendering using AntV G2

## Development Commands

### Backend (Python)

The backend uses `uv` for dependency management. All commands should be run from the `backend/` directory.

**Install dependencies:**
```bash
cd backend
uv sync --extra cpu  # For CPU-only PyTorch
# or
uv sync --extra cu128  # For CUDA 12.8
```

**Run development server:**
```bash
cd backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

**Run MCP server (port 8001):**
```bash
cd backend
uvicorn main:mcp_app --host 0.0.0.0 --port 8001
```

**Run tests:**
```bash
cd backend
pytest
```

**Linting and formatting:**
```bash
cd backend
ruff check . --fix  # Lint and auto-fix
ruff format .       # Format code
mypy .              # Type checking
```

**Database migrations:**
```bash
cd backend
# Migrations run automatically on startup via lifespan
# Manual migration: alembic upgrade head
# Create new migration: alembic revision --autogenerate -m "description"
```

### Frontend (Vue 3)

Frontend commands should be run from the `frontend/` directory.

**Install dependencies:**
```bash
cd frontend
npm install
```

**Development server:**
```bash
cd frontend
npm run dev
```

**Build for production:**
```bash
cd frontend
npm run build
```

**Lint:**
```bash
cd frontend
npm run lint
```

### Docker

**Run with docker-compose:**
```bash
docker-compose up -d
```

**Build Docker image:**
```bash
docker build -t dataease/sqlbot .
```

**Access the application:**
- Frontend: http://localhost:8000
- Backend API: http://localhost:8000/api/v1
- MCP Server: http://localhost:8001
- Default credentials: admin / SQLBot@123456

## Code Architecture

### Backend Structure

The backend follows a modular FastAPI architecture:

```
backend/
├── apps/                      # Application modules (domain-driven)
│   ├── ai_model/             # LLM model configuration management
│   ├── chat/                 # Chat interface and conversation handling
│   │   └── task/llm.py      # Core LLM orchestration with LangGraph
│   ├── datasource/           # Database connection management
│   │   ├── crud/            # CRUD operations
│   │   ├── embedding/       # Vector embeddings for schemas
│   │   └── utils/           # DB-specific utilities
│   ├── data_training/        # Training data and examples
│   ├── terminology/          # Business terminology/glossary
│   ├── template/            # LLM prompt templates and generators
│   │   ├── generate_sql/    # SQL generation templates
│   │   ├── generate_chart/  # Chart type selection
│   │   ├── generate_analysis/  # Data analysis templates
│   │   ├── filter/          # Filter generation
│   │   └── select_datasource/  # Datasource selection
│   ├── dashboard/           # Dashboard management
│   ├── system/              # User, auth, workspace management
│   │   ├── middleware/auth.py  # JWT token authentication
│   │   └── crud/           # System CRUD operations
│   └── mcp/                 # Model Context Protocol endpoints
├── common/                   # Shared utilities
│   ├── core/
│   │   ├── config.py        # Settings (Pydantic BaseSettings)
│   │   ├── response_middleware.py  # Response formatting
│   │   └── sqlbot_cache.py  # Redis/memory caching
│   └── utils/               # Utilities, embedding threads
├── alembic/                 # Database migrations
├── main.py                  # FastAPI app entry point
├── template.yaml            # LLM prompt templates (SQL, charts, etc.)
└── pyproject.toml          # Project config with uv
```

**Key architectural patterns:**

1. **LLM Pipeline (apps/chat/task/llm.py)**: Uses LangGraph for multi-step LLM workflows:
   - Datasource selection → Schema retrieval → SQL generation → Validation → Chart type selection
   - RAG integration with pgvector for terminology and training data

2. **Template System (apps/template/)**: Each template has a `generator.py` with prompt generation logic. The actual prompts are defined in `template.yaml` with placeholders for dynamic content.

3. **Database Support**: Multi-database support via SQLAlchemy with custom drivers:
   - PostgreSQL (pgvector for embeddings)
   - MySQL, Oracle, SQL Server, ClickHouse, DM, Redshift, Elasticsearch

4. **Authentication**: Token-based auth via `X-SQLBOT-TOKEN` header, workspace isolation for multi-tenancy.

5. **Embedding System**: Background threads (`common/utils/embedding_threads.py`) process terminology and training data into pgvector embeddings for RAG.

### Frontend Structure

```
frontend/src/
├── views/                    # Page components
│   ├── chat/                # Chat interface
│   ├── dashboard/           # Dashboard builder
│   ├── system/              # System settings
│   │   ├── aimodel/        # AI model configuration
│   │   ├── datasource/     # Datasource management
│   │   ├── terminology/    # Terminology editor
│   │   └── data-training/  # Training data management
│   └── login/              # Authentication
├── components/              # Reusable components
├── api/                     # API client (axios)
├── stores/                  # Pinia state management
├── router/                  # Vue Router config
└── utils/                   # Utilities
```

**Key patterns:**
- Element Plus for UI components
- Pinia for state management
- AntV G2 for client-side charts, S2 for pivot tables
- TinyMCE for rich text editing
- Markdown rendering with highlight.js for code

### Configuration

Environment variables (see `docker-compose.yaml` for full list):
- `POSTGRES_SERVER`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`: Database config
- `SECRET_KEY`: JWT signing key
- `BACKEND_CORS_ORIGINS`: CORS allowed origins
- `CACHE_TYPE`: Cache backend (redis/memory/None)
- `CACHE_REDIS_URL`: Redis connection string if using Redis cache
- `LOG_LEVEL`: Logging level (DEBUG/INFO/WARNING/ERROR)
- `SERVER_IMAGE_HOST`: MCP server image URL base

Configuration is managed via Pydantic Settings in `backend/common/core/config.py`.

## Important Development Notes

### When working with LLM prompts:
- Main templates are in `backend/template.yaml` (YAML format with placeholders)
- Template generators in `backend/apps/template/*/generator.py` prepare context for prompts
- The system uses Chinese prompts by default but supports i18n via `{lang}` placeholder

### When modifying database schemas:
- Update SQLModel models in `backend/apps/*/models/`
- Create migration: `cd backend && alembic revision --autogenerate -m "description"`
- Migrations auto-run on startup via `lifespan` in `main.py`

### When adding new datasource types:
- Add driver dependencies to `pyproject.toml`
- Implement connection logic in `backend/apps/datasource/utils/`
- Update SQL generation rules in `template.yaml` for engine-specific syntax (quoting, pagination, etc.)

### LLM Integration:
- Supports OpenAI-compatible APIs via LangChain
- Model configs stored in database, encrypted credentials
- Uses `langchain-openai`, `langchain-community`, `dashscope` for various providers

### Pre-commit hooks:
The project uses pre-commit for code quality (see `.pre-commit-config.yaml`):
- ruff (linting + formatting)
- yaml/toml validators
- trailing whitespace/EOF fixers

### 其他要求
- 所有答复需用简体中文显示
- 讨论过程和修改过程总结到本地文档
