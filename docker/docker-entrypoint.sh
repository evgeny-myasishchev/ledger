#!/bin/bash
set -e

: "${PGHOST:?PGHOST needs to be provided.}"
: "${LEDGER_PGPASS:?LEDGER_PGPASS needs to be provided.}"
DATABASE_URL=postgresql://ledger:${LEDGER_PGPASS}@${PGHOST}/ledger

if [ "$1" = 'passenger-start' ]; then
  echo 'Making sure the database is up to date...'
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:migrate

  echo 'Starting passenger'
  passenger start --user ledger
elif [ "$1" = 'db-setup' ]; then
  echo 'doing db setup...'
  : "${PGPASSWORD:?PGPASSWORD needs to be provided.}"
  CREATE_ROLE_SQL="DO
  \$body\$
  BEGIN
     IF NOT EXISTS (
        SELECT *
        FROM   pg_catalog.pg_user
        WHERE  usename = 'ledger') THEN

        CREATE ROLE ledger LOGIN PASSWORD '${LEDGER_PGPASS}' CREATEDB;
     END IF;
  END
  \$body\$;
  "
  psql -U postgres -c "${CREATE_ROLE_SQL}"
  cd /apps/ledger/app
  gosu ledger bundle exec rake db:create
  gosu ledger bundle exec rake db:setup
else
  exec "$@"
fi