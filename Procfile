# Running beanstalk on custom port to avoid possible system installed beanstalkd conflict
beanstalkd: bin/beanstalkd-wrapper.sh -l 127.0.0.1 -p 11321 -V
web: BEANSTALKD_URL=beanstalk://127.0.0.1:11321 rails s
worker: BEANSTALKD_URL=beanstalk://127.0.0.1:11321 backburner

