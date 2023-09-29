# base image
FROM python:3.10-alpine AS builder
WORKDIR /app

## set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

RUN pip install poetry

COPY ../poetry.lock ../pyproject.toml ./
RUN mkdir docs && touch README.md

RUN --mount=type=cache,target=${POETRY_CACHE_DIR} poetry install --only=main
ENV PATH="/app/.venv/bin:$PATH"

COPY ./src ./src
WORKDIR /app/src

RUN SECRET_KEY=dummy python3 manage.py collectstatic --noinput

# nginx runtime image
FROM nginx:alpine AS runtime

COPY --from=builder /app/src/static_built /var/www/html/static
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf
