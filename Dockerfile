# Docker configuration file for production deployment
# To initialize database run it like this:
# docker run -it --net ledger_dev_br --rm=true -e "DATABASE_URL=postgresql://pg-ledger-staging/ledger" -e "POSTGRES_HOST=pg-ledger-staging" ledger db-setup
# Then to create web worker:
# docker create -p 3000:3000 --net ledger_dev_br --env-file=.env --name ledger-web ledger
# docker create --net ledger_dev_br --env-file=.env --name ledger-worker ledger gosu ledger backburner

FROM debian
FROM ruby:2.2
RUN apt-get update && apt-get install nodejs -y && apt-get install vim -y && apt-get install postgresql-client -y

ARG RAILS_ENV=production
ARG DISABLE_SPRING=true

ENV RAILS_ENV=${RAILS_ENV} DISABLE_SPRING=${DISABLE_SPRING}

RUN mkdir -p /apps/ledger/app /apps/ledger/app/shared/bundle
WORKDIR /apps/ledger/app

# Caching bundle install
COPY Gemfile Gemfile.lock ./
RUN if test "$RAILS_ENV" = "production"; \
	then echo Installing prod bundle && bundle install --without development test --deployment; \
	else echo Installing dev bundle && bundle install; \
	fi

# Making sure passenger native support is built
RUN passenger-config build-native-support
RUN passenger-config install-standalone-runtime

# Adding app sources
COPY . .
RUN mkdir tmp

ENTRYPOINT ["docker/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["passenger-start"]
