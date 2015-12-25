# Docker configuration file for production deployment
FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install node -y && apt-get install vim -y
RUN mkdir /apps
RUN useradd -d /apps/ledger --create-home -s /bin/bash -U ledger
WORKDIR /apps/ledger
USER ledger
RUN mkdir -p app shared/bundle
ADD . app
ENV BUNDLE_APP_CONFIG ~/.bundle
ENV RAILS_ENV=production
RUN cd app && bundle install --gemfile=Gemfile --deployment --path ~/shared/bundle --without development test