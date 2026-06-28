FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
ARG API_BASE_URL=""
ARG SUPABASE_URL=""
ARG SUPABASE_ANON_KEY=""
ARG SUPABASE_PRODUCT_BUCKET="product-images"
ARG SUPABASE_CATEGORY_BUCKET="category-images"
ARG SUPABASE_PAYMENT_SLIP_BUCKET="payment-slips"
RUN flutter build web --release --base-href / \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=SUPABASE_URL=${SUPABASE_URL} \
  --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY} \
  --dart-define=SUPABASE_PRODUCT_BUCKET=${SUPABASE_PRODUCT_BUCKET} \
  --dart-define=SUPABASE_CATEGORY_BUCKET=${SUPABASE_CATEGORY_BUCKET} \
  --dart-define=SUPABASE_PAYMENT_SLIP_BUCKET=${SUPABASE_PAYMENT_SLIP_BUCKET}

FROM caddy:2-alpine
COPY --from=build /app/build/web /srv
COPY <<'CADDYFILE' /etc/caddy/Caddyfile
:{$PORT:8080}

@laravel_api path /api /api/*
handle @laravel_api {
  reverse_proxy {$BACKEND_URL:http://localhost:8000} {
    header_up Host {upstream_hostport}
    header_up X-Forwarded-Host {host}
    header_up X-Forwarded-Proto {scheme}
  }
}

handle /meta-feed.xml {
  reverse_proxy {$BACKEND_URL:http://localhost:8000} {
    header_up Host {upstream_hostport}
    header_up X-Forwarded-Host {host}
    header_up X-Forwarded-Proto {scheme}
  }
}

handle {
  root * /srv
  try_files {path} {path}/ /index.html
  file_server
}
CADDYFILE
EXPOSE 8080
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
