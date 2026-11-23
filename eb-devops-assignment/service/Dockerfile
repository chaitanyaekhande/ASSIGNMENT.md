# ---- build stage: byte-compile so the runtime stage needs no writable FS ----
FROM python:3.12.7-slim-bookworm AS build
WORKDIR /src
COPY app.py .
RUN python -m compileall -q app.py

# ---- runtime stage ----
FROM python:3.12.7-slim-bookworm
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
RUN groupadd --system --gid 10001 app \
 && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app
WORKDIR /app
COPY --from=build --chown=10001:10001 /src/app.py .
USER 10001:10001
EXPOSE 8080
CMD ["python", "/app/app.py"]
