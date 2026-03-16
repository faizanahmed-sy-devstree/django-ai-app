FROM python:3.12-slim

# 1. Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# 2. Copy dependency files
COPY pyproject.toml uv.lock ./

# 3. Install dependencies globally in the container (System-wide)
# This avoids all the "no such file or directory" errors with .venv
RUN uv pip install --system --no-cache -r pyproject.toml

# 4. Copy project code
COPY . .

# 5. Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 6. Run using the python module flag for daphne
CMD ["python3", "-m", "daphne", "-b", "0.0.0.0", "-p", "8000", "my_project.asgi:application"]