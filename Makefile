# PingAM Basics lab. Linux, macOS, and Windows via WSL2.
#   make check     - tools + artifacts + checksums
#   make secrets   - create .env with random passwords + shared DS deployment ID
#   make up        - build + start three DS + AM, wait until healthy
#   make config    - one-shot Amster install + external CTS wiring (idempotent)
#   make seed      - load sample users into ds-identities
#   make smoke     - quick end-to-end checks
#   make down      - stop containers, keep data
#   make reset     - stop and DELETE all lab volumes and .env (YES=1 = no prompt)
SHELL   := /usr/bin/env bash
COMPOSE := docker compose

.PHONY: help check secrets build up config seed smoke logs ps down reset
help:
	@sed -n '2,10p' Makefile

check:
	@scripts/check.sh

secrets:
	@scripts/gen-env.sh

build: check secrets
	$(COMPOSE) build

up: check secrets
	@# Some hosts drop Docker inter-container FORWARD; ensure ACCEPT exists.
	@sudo iptables -C FORWARD -j ACCEPT 2>/dev/null || sudo iptables -I FORWARD 1 -j ACCEPT 2>/dev/null || true
	$(COMPOSE) build ds-config pingam
	$(COMPOSE) up -d --wait

config: secrets
	docker compose --profile config run --rm -T --build amster
	@echo "Restarting pingam so external CTS takes effect..."
	$(COMPOSE) restart pingam
	@echo "Waiting for pingam healthy..."
	@for i in $$(seq 1 60); do \
	  id=$$(docker compose ps -q pingam); \
	  s=$$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$$id" 2>/dev/null || echo starting); \
	  if [ "$$s" = healthy ]; then echo "pingam healthy"; exit 0; fi; \
	  sleep 5; \
	done; \
	echo "pingam did not become healthy in time"; exit 1

seed:
	@docker compose cp pingds/sample-users.ldif ds-identities:/tmp/sample-users.ldif
	@# Lab passwords (TestUser@2024) trip "Common passwords"; detach that validator for the demo seed.
	@docker compose exec -T ds-identities sh -c '\
	  /opt/opendj/bin/dsconfig set-password-policy-prop --policy-name "Default Password Policy" \
	    --remove password-validator:"Common passwords" \
	    --hostname localhost --port 4444 \
	    --bindDN "cn=Directory Manager" --bindPassword "$$DS_ROOT_PASSWORD" --trustAll --no-prompt; \
	  /opt/opendj/bin/ldapmodify -h localhost -p 1636 --useSSL --trustAll \
	    -D "cn=Directory Manager" -w "$$DS_ROOT_PASSWORD" --continueOnError -f /tmp/sample-users.ldif'


smoke:
	@scripts/smoke.sh

logs:
	$(COMPOSE) logs -f --tail=100

ps:
	$(COMPOSE) ps

down:
	docker compose --profile '*' down

reset:   ## YES=1 skips the prompt
	@[ "$(YES)" = 1 ] || { read -r -p "Delete ALL lab containers, volumes and .env? [y/N] " a && [ "$$a" = y ]; }
	@if [ -f .env ]; then docker compose --profile '*' down -v --remove-orphans; \
	else p=$$(sed -n 's/^COMPOSE_PROJECT_NAME=//p' .env.example); \
	  ids=$$(docker ps -aq --filter label=com.docker.compose.project=$$p); [ -z "$$ids" ] || docker rm -f $$ids; \
	  vols=$$(docker volume ls -q --filter label=com.docker.compose.project=$$p); [ -z "$$vols" ] || docker volume rm $$vols; \
	  nets=$$(docker network ls -q --filter label=com.docker.compose.project=$$p); [ -z "$$nets" ] || docker network rm $$nets; fi
	rm -f .env
