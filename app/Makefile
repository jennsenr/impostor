LOCAL_IP ?= $(shell \
	for iface in en0 en1; do \
		ip=$$(ipconfig getifaddr $$iface 2>/dev/null); \
		if [ -n "$$ip" ] && ! echo "$$ip" | grep -q '^169\.254\.'; then \
			echo $$ip; \
			exit; \
		fi; \
	done; \
	ifconfig 2>/dev/null | awk '/inet / { print $$2 }' | grep -vE '^(127\.|169\.254\.)' | head -n 1 \
)
DEV_API_URL := http://$(LOCAL_IP):8080
API_URL := https://impostor.manggio.com
FLUTTER_DEV_RUN := flutter run --release -t lib/main_dev.dart --dart-define=API_URL=$(DEV_API_URL)
FLUTTER_PROD_RUN := flutter run --release -t lib/main_prod.dart --dart-define=API_URL=$(API_URL)

.PHONY: check-local-ip run-iyi run-jenn run-vanessa run-all

check-local-ip:
	@if [ -z "$(LOCAL_IP)" ]; then \
		echo "No se pudo detectar la IP local del host."; \
		echo "Conectate a la red local o lanza Flutter con LOCAL_IP=<tu-ip-local> make run-dev-jenn."; \
		exit 1; \
	fi
	@echo "Usando API_URL=$(DEV_API_URL)"

run-dev-iyi: check-local-ip
	$(FLUTTER_DEV_RUN) -d 00008150-001164E21A6A401C

run-dev-jenn: check-local-ip
	$(FLUTTER_DEV_RUN) -d 00008150-001948611E92401C

run-dev-vanessa: check-local-ip
	$(FLUTTER_DEV_RUN) -d 00008110-000A314011F2801E

run-dev-all: check-local-ip
	@echo "Abriendo una ventana de Terminal por dispositivo..."
	@osascript \
		-e 'tell application "Terminal"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-dev-iyi"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-dev-jenn"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-dev-vanessa"' \
		-e 'activate' \
		-e 'end tell'

run-iyi:
	$(FLUTTER_PROD_RUN) -d 00008150-001164E21A6A401C

run-jenn:
	$(FLUTTER_PROD_RUN) -d 00008150-001948611E92401C

run-vanessa:
	$(FLUTTER_PROD_RUN) -d 00008110-000A314011F2801E

run-all:
	@echo "Abriendo una ventana de Terminal por dispositivo..."
	@osascript \
		-e 'tell application "Terminal"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-iyi"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-jenn"' \
		-e 'do script "cd \"$(CURDIR)\" && make run-vanessa"' \
		-e 'activate' \
		-e 'end tell'
