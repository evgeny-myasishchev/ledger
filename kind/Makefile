.PHONY: deps download_mods install_tools

deps: download_mods install_tools

download_mods:
	go mod download

install_tools:
	echo "hello"
	@for package in $$(grep '_ \"' tools/tools.go | sed 's/_ //g' | sed 's/[^a-zA-Z0-9/.]//g'); do \
		echo "Installing package $${package} or skipping if already installed..."; \
		go install $${package}; \
	done