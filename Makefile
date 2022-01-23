.git-env:
	@echo Generating .git-env ...; \
	branch=$$(git rev-parse --abbrev-ref HEAD); \
	hash=$$(git rev-parse HEAD); \
	echo "GIT_BRANCH=$${hash}\
	\nGIT_HASH=$${hash}" > .git-env;

docker-image:
	docker build -t evgenymyasishchev/ledger:latest -t localhost:5000/ledger:latest .

push-local-image: docker-image
	docker push localhost:5000/ledger:latest