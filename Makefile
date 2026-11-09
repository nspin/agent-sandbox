ID ?= rv-agent-sandbox

W ?= ../work

work_local_path := $(W)
work_remote_path:= /work

here_local_path := .
here_remote_path:= /here

id := $(ID)
image_tag := $(id)
container_name := $(id)
volume_name := $(id)

uid := $(shell id -u)
gid := $(shell id -g)

.PHONY: none
none:

.PHONY: clean
clean: rm-container rm-volume

vscode_container_config := "$(HOME)/Library/Application\ Support/Code/User/globalStorage/ms-vscode-remote.remote-containers/nameConfigs/$(id).json"

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
		--mount type=volume,src=$(volume_name),dst=/nix \
		--mount type=bind,src=$(abspath $(work_local_path)),dst=$(work_remote_path) \
		--mount type=bind,src=$(abspath $(here_local_path)),dst=$(here_remote_path) \
		$(image_tag)

.PHONY: activate
activate:
	docker exec -it $(container_name) \
		/bin/bash -c \
			'$$(/home/x/.nix-profile/bin/nix-build --no-out-link /here -A activate)/bin/activate'

.PHONY: exec
exec:
	docker exec -it $(container_name) \
		/home/x/.nix-profile/bin/bash -l

.PHONY: start
start:
	docker start $(container_name)

.PHONY: rm-container
rm-container:
	for id in $$(docker ps -aq -f "name=^$(container_name)$$"); do \
		docker rm -f --volumes $$id; \
	done

.PHONY: rm-volume
rm-volume: rm-container
	for id in $$(docker volume ls -q -f "name=^$(volume_name)$$"); do \
		docker volume rm $$id; \
	done
