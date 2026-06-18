FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL=""
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
ARG SUPABASE_PRODUCT_BUCKET="product-images"
RUN flutter build web --release --base-href / \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=SUPABASE_PRODUCT_BUCKET=${SUPABASE_PRODUCT_BUCKET}

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
