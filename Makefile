.git-env:
	@echo Generating .git-env ...; \
	branch=$$(git rev-parse --abbrev-ref HEAD); \
	hash=$$(git rev-parse HEAD); \
	echo "GIT_BRANCH=$${hash}\
	\nGIT_HASH=$${hash}" > .git-env;

beanstalk-docker-image:
	docker build -t localhost:5000/beanstalkd:latest -f docker/Dockerfile.beanstalkd .

ledger-docker-image:
	docker build -t evgenymyasishchev/ledger:latest -t localhost:5000/ledger:latest .

push-local-images: ledger-docker-image beanstalk-docker-image
	docker push localhost:5000/ledger:latest
	docker push localhost:5000/beanstalkd:latest