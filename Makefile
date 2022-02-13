.git-env:
	@echo Generating .git-env ...; \
	branch=$$(git rev-parse --abbrev-ref HEAD); \
	hash=$$(git rev-parse HEAD); \
	echo "GIT_BRANCH=$${hash}\
	\nGIT_HASH=$${hash}" > .git-env;

beanstalk-docker-image:
	docker build -t localhost:5000/beanstalkd:latest -f docker/Dockerfile.beanstalkd .

.buildx-builder:
	docker buildx create --name ledger \
		--driver-opt network=host > $@

ledger-local-image: .buildx-builder
	docker build -t localhost:5000/ledger:latest .

ledger-local-dev-image: .buildx-builder
	docker buildx build \
		--builder ledger \
		--build-arg BUNDLE_WITHOUT="" \
		--output=type=registry \
		-t localhost:5000/ledger:latest . \

ledger-public-image: ledger-local-image
	docker tag localhost:5000/ledger:latest evgenymyasishchev/ledger:latest

push-local-images: ledger-docker-image beanstalk-docker-image
	docker push localhost:5000/ledger:latest
	docker push localhost:5000/beanstalkd:latest