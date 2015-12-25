# Docker configuration file for production deployment
FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install node -y
RUN mkdir /app && mkdir -p /shared/bundle
ADD . /app
RUN bundle install --gemfile=/app/Gemfile --deployment --path /shared/bundle --without development test