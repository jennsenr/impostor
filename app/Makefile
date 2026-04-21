LOCAL_IP := $(shell ifconfig 2>/dev/null | awk '/inet / && $$2 != "127.0.0.1" { print $$2; exit }')
DEV_API_URL := http://$(LOCAL_IP):8080
API_URL := https://impostor.manggio.com
FLUTTER_DEV_RUN := flutter run --release -t lib/main_dev.dart --dart-define=API_URL=$(DEV_API_URL)
FLUTTER_PROD_RUN := flutter run --release -t lib/main_prod.dart --dart-define=API_URL=$(API_URL)

.PHONY: check-local-ip run-iyi run-jenn run-vanessa run-all

check-local-ip:
	@if [ -z "$(LOCAL_IP)" ]; then \
		echo "No se pudo detectar la IP local del host."; \
		echo "Conectate a la red local o lanza Flutter con --dart-define=API_URL=http://<tu-ip-local>:8080."; \
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
	@osascript <<APPLESCRIPT
tell application "Terminal"
	do script "cd '$(CURDIR)' && make run-dev-iyi"
	do script "cd '$(CURDIR)' && make run-dev-jenn"
	do script "cd '$(CURDIR)' && make run-dev-vanessa"
	activate
end tell
APPLESCRIPT

run-iyi: check-local-ip
	$(FLUTTER_PROD_RUN) -d 00008150-001164E21A6A401C

run-jenn: check-local-ip
	$(FLUTTER_PROD_RUN) -d 00008150-001948611E92401C

run-vanessa: check-local-ip
	$(FLUTTER_PROD_RUN) -d 00008110-000A314011F2801E

run-all: check-local-ip
	@echo "Abriendo una ventana de Terminal por dispositivo..."
	@osascript <<APPLESCRIPT
tell application "Terminal"
	do script "cd '$(CURDIR)' && make run-iyi"
	do script "cd '$(CURDIR)' && make run-jenn"
	do script "cd '$(CURDIR)' && make run-vanessa"
	activate
end tell
APPLESCRIPT
