.PHONY: help api-dev api-test api-build api-up api-down api-logs app-dev app-prod app-ios-prod app-android-prod app-test app-analyze app-build-android app-build-apk app-build-ios app-run-all

help:
	@echo "Targets disponibles:"
	@echo "  api-dev           Ejecuta la API en local"
	@echo "  api-test          Ejecuta los tests del backend"
	@echo "  api-build         Compila el binario de la API"
	@echo "  api-up            Levanta la API con Docker Compose"
	@echo "  api-down          Detiene Docker Compose de la API"
	@echo "  api-logs          Muestra logs de Docker Compose"
	@echo "  app-dev           Ejecuta la app Flutter en flavor dev"
	@echo "  app-prod          Ejecuta la app Flutter en flavor prod"
	@echo "  app-ios-prod      Ejecuta la app iOS en flavor prod"
	@echo "  app-android-prod  Ejecuta la app Android en flavor prod"
	@echo "  app-test          Ejecuta los tests de Flutter"
	@echo "  app-analyze       Ejecuta el análisis estático de Flutter"
	@echo "  app-build-android Genera el App Bundle Android de prod"
	@echo "  app-build-apk     Genera el APK Android de prod"
	@echo "  app-build-ios     Genera el build iOS de prod"
	@echo "  app-run-all       Abre una ventana de Terminal por dispositivo iOS definido"

api-dev:
	@$(MAKE) -C api dev

api-test:
	@$(MAKE) -C api test

api-build:
	@$(MAKE) -C api build

api-up:
	@$(MAKE) -C api up

api-down:
	@$(MAKE) -C api down

api-logs:
	@$(MAKE) -C api logs

app-dev:
	@cd app && flutter run -t lib/main_dev.dart

app-prod:
	@cd app && flutter run --flavor prod -t lib/main_prod.dart

app-ios-prod:
	@cd app && flutter run -d ios --flavor prod -t lib/main_prod.dart

app-android-prod:
	@cd app && flutter run -d android --flavor prod -t lib/main_prod.dart

app-test:
	@cd app && flutter test

app-analyze:
	@cd app && flutter analyze

app-build-android:
	@cd app && flutter build appbundle --flavor prod -t lib/main_prod.dart

app-build-apk:
	@cd app && flutter build apk --flavor prod -t lib/main_prod.dart

app-build-ios:
	@cd app && flutter build ios --flavor prod -t lib/main_prod.dart

app-run-all:
	@$(MAKE) -C app run-all
