FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /

FROM caddy:2-alpine
COPY --from=build /app/build/web /srv
COPY <<'CADDYFILE' /etc/caddy/Caddyfile
:{$PORT:8080}
root * /srv
try_files {path} {path}/ /index.html
file_server
CADDYFILE
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
