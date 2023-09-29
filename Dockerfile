# base image
FROM python:3.10-alpine AS base
WORKDIR /app

## set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1

# dependencies
FROM base AS deps

## poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

RUN pip install poetry

COPY poetry.lock pyproject.toml ./
RUN mkdir docs && touch README.md

RUN --mount=type=cache,target=${POETRY_CACHE_DIR} poetry install --only=main
ENV PATH="/app/.venv/bin:$PATH"

# runtime image
FROM base AS runtime

ENV DB_ENGINE=postgresql

COPY --from=deps /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

COPY ./src ./src

WORKDIR /app/src
CMD ["gunicorn", "core.wsgi", "--bind", "0.0.0.0:80", "--workers", "3"]
EXPOSE 80
