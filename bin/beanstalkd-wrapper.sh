#!/usr/bin/env bash

if [[ -x $(which beanstalkd) ]]
then
    beanstalkd "$@" &> log/beanstalkd.log
else
    echo "The 'beanstalkd' has not been found. Please install it:
    - on Linux: sudo apt-get install beanstalkd
    - on OSX: sudo port install beanstalkd or sudo brew install beanstalkd"
    exit 1
fi
