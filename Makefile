.git-env:
	@echo Generating .git-env ...; \
	branch=$$(git rev-parse --abbrev-ref HEAD); \
	hash=$$(git rev-parse HEAD); \
	echo "GIT_BRANCH=$${hash}\
	\nGIT_HASH=$${hash}" > .git-env;

docker-image:
	docker build -t evgenymyasishchev/ledger:latest .