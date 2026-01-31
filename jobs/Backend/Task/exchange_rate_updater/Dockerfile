FROM --platform=linux/amd64 ruby:3.4.8-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN gem install bundler -v 2.6.5

COPY Gemfile Gemfile.lock ./

RUN bundle install --jobs 4 --retry 3

COPY . .

RUN bundle exec rails assets:precompile || true

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
