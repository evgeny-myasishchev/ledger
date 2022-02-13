# Docker configuration file for production deployment
# To initialize database run it like this:
# docker run -it --net ledger_dev_br --rm=true -e "DATABASE_URL=postgresql://pg-ledger-staging/ledger" -e "POSTGRES_HOST=pg-ledger-staging" ledger db-setup
# Then to create web worker:
# docker create -p 3000:3000 --net ledger_dev_br --env-file=.env --name ledger-web ledger
# docker create --net ledger_dev_br --env-file=.env --name ledger-worker ledger gosu ledger backburner

FROM ruby:2.2
RUN apt-get update && apt-get install nodejs -y && apt-get install vim -y && apt-get install postgresql-client -y

ARG BUNDLE_WITHOUT="development:test"
ARG DISABLE_SPRING=true

ENV DISABLE_SPRING=${DISABLE_SPRING}

RUN mkdir -p /apps/ledger/app /apps/ledger/app/shared/bundle
RUN bundle config --global github.https true;

WORKDIR /apps/ledger/app

# Caching bundle install
COPY Gemfile Gemfile.lock ./
RUN bundle install \
    --retry 3 \
    --jobs 4 \
    --binstubs

# Making sure passenger native support is built
RUN passenger-config build-native-support
RUN passenger-config install-standalone-runtime

# Adding app sources
COPY . .
RUN mkdir tmp

ENTRYPOINT ["docker/docker-entrypoint.sh"]
EXPOSE 3000
CMD ["passenger-start"]
