# base image
FROM python:3.13.1-alpine@sha256:804ad02b9ba67ea1f8307eeb6407b121c6bd6bb19d3f182aae166821eb59d6a4 AS base
WORKDIR /app

## set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1

# dependencies
FROM node:18-alpine@sha256:291dbe40243c47dc85fdc3690bc8edf17891dd02eaba36c577fbe73a45b97334 AS node
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
FROM nginx:alpine@sha256:4ff102c5d78d254a6f0da062b3cf39eaf07f01eec0927fd21e219d0af8bc0591 AS runtime-nginx

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
