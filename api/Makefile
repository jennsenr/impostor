.PHONY: dev build docker-up docker-down test

# Variables
APP_NAME=impostor-api

dev:
	@echo "Iniciando entorno de desarrollo local..."
	@go run cmd/main.go

test:
	@echo "Ejecutando tests..."
	@go test ./... -v

build:
	@echo "Compilando binario para producción..."
	@go build -o bin/$(APP_NAME) cmd/main.go

up:
	@echo "Levantando servicios con Docker Compose..."
	@docker compose up --build -d

down:
	@echo "Deteniendo servicios de Docker..."
	@docker compose down

logs:
	@docker compose logs -f

clean:
	@rm -rf bin/
	@echo "Limpieza completada."
