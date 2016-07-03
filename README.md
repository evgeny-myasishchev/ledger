# Ledger [<img src="https://travis-ci.org/evgeny-myasishchev/ledger.svg?branch=master" alt="Build Status" />](https://travis-ci.org/evgeny-myasishchev/ledger)

Personal accounting book

## Docker Environment Setup

This section contains some hints to setup production|staging environment.

For each container a restart policy like ```--restart=unless-stopped``` may need to be added.

To simplify service discovery a user defined bridge network can be used:
```docker network create -d=bridge ledger-prod```

### Beanstalk container

Build image: ```docker build -t beanstalkd -f docker/Dockerfile.beanstalkd .```

Create container: ```docker run --net ledger-prod --name beanstalkd-prod -d beanstalkd```

### Postgres container
```docker run --net ledger-prod --name pg-prod -e POSTGRES_PASSWORD=password -d postgres:9.5```

Create ledger database
* role - ```docker exec -it pg-prod psql -d postgres -U postgres -c "CREATE ROLE ledger LOGIN PASSWORD 'password'"```
* database - ```docker exec -it pg-prod psql -d postgres -U postgres -c "CREATE DATABASE ledger OWNER ledger"```

### Ledger Containers

Prepare env file with contents like below:
```
DATABASE_URL=postgres://ledger:password@pg-prod/ledger
GOAUTH_CLIENT_ID=TODO
GOAUTH_CLIENT_SECRET=TODO
DEVISE_SECRET_KEY=TODO
SECRET_KEY_BASE=TODO
SMTP_HOST=TODO
SMTP_PORT=TODO
SMTP_DOMAIN=OPTIONAL
SMTP_USER_NAME=OPTIONAL
SMTP_PASSWORD=OPTIONAL
BEANSTALKD_URL=beanstalk://beanstalkd-prod
BACKBURNER_TUBE_NS=prod.my-ledger.com
FULL_HOST=https://my-ledger.com.com
```

Setup ledger database: ```docker run --env-file .env-docker --net ledger-prod --rm -it evgenymyasishchev/ledger db-setup```

Create and start web container: ```docker run --env-file .env-docker --net ledger-prod --name ledger-prod-web -p 3000:3000 -d evgenymyasishchev/ledger```

Create and start worker container: ```docker run --env-file .env-docker --net ledger-prod --name ledger-prod-worker -d evgenymyasishchev/ledger backburner```
