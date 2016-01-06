# Docker configuration file for production deployment
FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install nodejs -y && apt-get install vim -y && apt-get install postgresql-client -y
RUN mkdir /apps
RUN useradd -d /apps/ledger --create-home -s /bin/bash -U ledger

#TODO: Add gosu
# THEN adjust docker-entrypoint to use it to perform maintenance tasks

WORKDIR /apps/ledger
RUN mkdir -p app shared/bundle

# TODO: Should be configurable
# ENV RAILS_ENV=production

# Caching bundle install
WORKDIR app
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --gemfile=Gemfile
# --without development test --deployment --path shared/bundle

# Making sure passenger native support is built
RUN passenger-config build-native-support
RUN passenger-config install-standalone-runtime

# Adding app sources and making assets ready
ADD . .
RUN mkdir tmp
RUN chown -R ledger tmp
RUN chown -R ledger log

ENTRYPOINT ["docker/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["passenger-start"]
