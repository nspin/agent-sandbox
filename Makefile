ID ?= r-agent-sandbox

W ?= ../work

work_local_path := $(W)
work_remote_path:= /work

id := $(ID)
image_tag := $(id)
container_name := $(id)

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: none
none:

.PHONY: clean
clean: rm-container

vscode_container_config := $(HOME)/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/nameConfigs/$(id).json

.PHONY: $(vscode_container_config) # TODO shouldn't have to be .PHONY
$(vscode_container_config): remote-container-config.jsonc
	cp $< $@

.PHONY: sync-config
sync-config: $(vscode_container_config)

.PHONY: clean-config
clean-config:
	rm -f $(vscode_container_config)

.PHONY: build
build:
	docker build \
		--build-arg UID=$(uid) \
		--build-arg GID=$(gid) \
		-t $(image_tag) .

.PHONY: run
run: build
	docker run -d -it \
		--name $(container_name) \
		--mount type=bind,src=/nix/store,dst=/nix/store,ro \
		--mount type=bind,src=/nix/var/nix/db,dst=/nix/var/nix/db,ro \
		--mount type=bind,src=/nix/var/nix/daemon-socket,dst=/nix/var/nix/daemon-socket,ro \
		--mount type=bind,src=$(abspath $(work_local_path)),dst=$(work_remote_path) \
		$(image_tag)

.PHONY: activate
activate:
	docker exec -it $(container_name) \
		$$(nix-build --no-out-link -A activate)/bin/activate

.PHONY: exec
exec:
	docker exec -it $(container_name) \
		$$(nix-build --no-out-link -A home.activationPackage)/home-path/bin/bash -l

.PHONY: start
start:
	docker start $(container_name)

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f $$id; \
	done
