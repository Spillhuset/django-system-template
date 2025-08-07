# base image
FROM python:3.13.6-alpine@sha256:7f9d4ab05a18a368db663461919926cd869343de781199a6748b61a60f28dd0a AS base
WORKDIR /app

## set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1

# dependencies
FROM node:18-alpine@sha256:8d6421d663b4c28fd3ebc498332f249011d118945588d0a35cb9bc4b8ca09d9e AS node
FROM base AS builder

## poetry
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

RUN pip install poetry

COPY poetry.lock pyproject.toml ./
RUN mkdir docs && touch docs/README.md

RUN --mount=type=cache,target=${POETRY_CACHE_DIR} poetry install --only=main
ENV PATH="/app/.venv/bin:$PATH"

# tailwind needs node 💀
COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/share /usr/local/share
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

COPY ./src ./src
WORKDIR /app/src

RUN SECRET_KEY=dummy \
    python3 manage.py tailwind install && \
    python3 manage.py tailwind build && \
    python3 manage.py collectstatic --noinput

# runtime nginx image
FROM nginx:alpine@sha256:d67ea0d64d518b1bb04acde3b00f722ac3e9764b3209a9b0a98924ba35e4b779 AS runtime-nginx

COPY --from=builder /app/src/static_built /var/www/html/static
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf

# runtime image
FROM base AS runtime

ENV DB_ENGINE=postgresql

COPY --from=builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

COPY ./src ./src
COPY --from=builder /app/src/static_built/staticfiles*.json /app/src/static_built/

WORKDIR /app/src
CMD ["gunicorn", "core.wsgi", "--bind", "0.0.0.0:80", "--workers", "3"]
EXPOSE 80
