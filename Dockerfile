# Docker configuration file for production deployment
# To initialize database run it like this:
# docker run -it --net ledger_dev_br --rm=true -e "DATABASE_URL=postgresql://pg-ledger-staging/ledger" -e "POSTGRES_HOST=pg-ledger-staging" ledger db-setup
# Then to start a server:
# docker run -d -p 3000:3000 --net ledger_dev_br -e "DATABASE_URL=postgresql://pg-ledger-staging/ledger" --name ledger ledger
# TODO: Start backburner worker

FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install nodejs -y && apt-get install vim -y && apt-get install postgresql-client -y
RUN curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.0/gosu' \
	&& chmod +x /usr/local/bin/gosu
RUN mkdir /apps
RUN useradd -d /apps/ledger --create-home -s /bin/bash -U ledger

WORKDIR /apps/ledger
RUN mkdir -p app shared/bundle

# TODO: Should be configurable
ENV RAILS_ENV=production DISABLE_SPRING=true

# Caching bundle install
WORKDIR app
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install --gemfile=Gemfile --without development test --deployment --path shared/bundle

# Making sure passenger native support is built
RUN passenger-config build-native-support
RUN passenger-config install-standalone-runtime

# Adding app sources and making assets ready
ADD . .
RUN mkdir tmp
RUN chown -R ledger tmp
RUN chown -R ledger log

# TODO: This must be only for dev/test env
RUN chmod o+w db/schema.rb

ENTRYPOINT ["docker/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["passenger-start"]
