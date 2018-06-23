# Ledger [<img src="https://travis-ci.org/evgeny-myasishchev/ledger.svg?branch=master" alt="Build Status" />](https://travis-ci.org/evgeny-myasishchev/ledger)

Personal accounting book

# Development

Development is done via docker. Follow steps below to have dev env ready:

Get alphavantage api key. This is optional but some features may not work.
You can get the key here: https://www.alphavantage.co/support/#api-key.
Then init your env with the api key:
`export ALPHAVANTAGE_API_KEY=xxx`

`docker-compose build`

`docker-compose up -d db beanstalkd`

Optionally start pgadmin

`docker-compose up -d pgadmin`

## Do initial setup

`docker-compose run --rm app bash -c "rake db:setup && rake ledger:dummy_seed"`

## Start web app

`docker-compose run --rm -p 3000:3000 app bash`

Start worker
`backburner -d`

Start web app
`passenger start`

# Deployment Dependencies

Ledger expects following environment variables to be initialized. It will automatically load .env file if present.

```
DATABASE_URL=postgres://ledger:password@pg-prod/ledger
GOAUTH_CLIENT_ID=TODO: Google Client ID of the web application
GOAUTH_CLIENT_SECRET=TODO: Client Secret
JWT_AUD_WHITELIST=OPTIONAL: Coma separated list of accepted jwt aud values
DEVISE_SECRET_KEY=TODO: Use to generate random tokens by devise
SECRET_KEY_BASE=TODO: Used by rails
SMTP_HOST=TODO: host of the SMTP server
SMTP_PORT=TODO: port of the SMTP server
SMTP_DOMAIN=OPTIONAL: domain if required by SMTP server
SMTP_USER_NAME=OPTIONAL: SMTP user name (if required)
SMTP_PASSWORD=OPTIONAL: SMTP password (if required)
BEANSTALKD_URL=beanstalk://beanstalkd-prod
BACKBURNER_TUBE_NS=prod.my-ledger.com
FULL_HOST=https://my-ledger.com
```

**Note:**

* **JWT_AUD_WHITELIST** - GOAUTH_CLIENT_ID will be added automatically to this list.

# Docker Environment Setup

This section contains some hints to setup production|staging environment.

For each container a restart policy like ```--restart=unless-stopped``` may need to be added.

To simplify service discovery a user defined bridge network can be used:

```docker network create -d=bridge ledger-prod```

## Beanstalk container

Build image: 

```docker build -t beanstalkd -f docker/Dockerfile.beanstalkd .```

Create container: 

```docker run --net ledger-prod --name beanstalkd-prod -d beanstalkd```

## Postgres container

```docker run --net ledger-prod --name pg-prod -e POSTGRES_PASSWORD=password -d postgres:9.5```

Create ledger database
* role - ```docker exec -it pg-prod psql -d postgres -U postgres -c "CREATE ROLE ledger LOGIN PASSWORD 'password'"```
* database - ```docker exec -it pg-prod psql -d postgres -U postgres -c "CREATE DATABASE ledger OWNER ledger"```

## Ledger Containers

Prepare env file with contents explained in a Deployment Dependencies.

Setup ledger database: ```docker run --env-file app.env --net ledger-prod --rm -it evgenymyasishchev/ledger db-setup```

Create and start web container: ```docker run --env-file app.env --net ledger-prod --name ledger-prod-web -p 3000:3000 -d evgenymyasishchev/ledger```

Create and start worker container: ```docker run --env-file app.env --net ledger-prod --name ledger-prod-worker -d evgenymyasishchev/ledger backburner```

# Automated Deployment

Deploy new version. Makes sense when new image is available or due to environment changes.

```
cap staging|production deploy
```

Cold deployment (no ledger containers yet)
```
cap staging|production deploy:create_containers
```
