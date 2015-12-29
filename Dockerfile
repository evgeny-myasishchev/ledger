# Docker configuration file for production deployment
FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install node -y && apt-get install vim -y
RUN mkdir /apps
RUN useradd -d /apps/ledger --create-home -s /bin/bash -U ledger

WORKDIR /apps/ledger
RUN mkdir -p app shared/bundle

# ENV RAILS_ENV=production

# Caching bundle install
WORKDIR app
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --gemfile=Gemfile --deployment --path shared/bundle --without development test

# Making sure passenger native support is built
RUN passenger-config build-native-support
RUN passenger-config install-standalone-runtime

# Adding app sources and making assets ready
ADD . .
RUN rake assets:precompile

ENTRYPOINT ["docker/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["passenger-start"]
