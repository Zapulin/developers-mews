# Stage 1: Builder - Install dependencies and build assets
FROM --platform=linux/amd64 ruby:3.4.8-slim AS builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler -v 2.6.5

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3

COPY . .

# Stage 2: Runtime - Minimal image with only runtime dependencies
FROM --platform=linux/amd64 ruby:3.4.8-slim AS runtime

# Install only runtime dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    curl \
    libyaml-0-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler -v 2.6.5

COPY --from=builder /usr/local/bundle /usr/local/bundle

COPY --from=builder /app /app

RUN useradd -m appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
