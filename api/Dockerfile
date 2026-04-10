# Etapa de construcción
FROM golang:1.25.6-alpine AS builder

# Instalar dependencias necesarias para la construcción
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Instalar dependencias
COPY go.mod go.sum ./
RUN go mod download

# Copiar el código fuente
COPY . .

# Compilar para producción
RUN CGO_ENABLED=0 GOOS=linux go build -o bin/server cmd/main.go

# Etapa final (producción)
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata wget

WORKDIR /app

# Copiar binario y archivos necesarios
COPY --from=builder /app/bin/server .
COPY --from=builder /app/internal/infrastructure/data/words.json ./internal/infrastructure/data/words.json
COPY --from=builder /app/public ./public

# Configurar variables de entorno por defecto
ENV PORT=8080
ENV WORDS_FILE_PATH=internal/infrastructure/data/words.json
ENV PUBLIC_DIR_PATH=public

EXPOSE 8080

CMD ["./server"]
