# Ledger [<img src="https://travis-ci.org/evgeny-myasishchev/ledger.svg?branch=master" alt="Build Status" />](https://travis-ci.org/evgeny-myasishchev/ledger)

Personal accounting book

## Docker Environment Setup

This section contains some hints to setup production|staging environment.

For each container a restart policy like ```--restart=on-failure:10``` may need to be added.

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
