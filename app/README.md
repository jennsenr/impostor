# Impostor App

## Flavors

La app soporta dos entornos:

- `dev`: usa por defecto `http://192.168.68.63:8080`
- `prod`: usa por defecto `https://impostor.manggio.com`

Ambos pueden sobreescribirse con `--dart-define=API_URL=...`.

## Comandos útiles

Desarrollo local:

```bash
flutter run -t lib/main_dev.dart --dart-define=FLAVOR=dev
```

Producción con la URL oficial:

```bash
flutter run --flavor prod -t lib/main_prod.dart --dart-define=FLAVOR=prod
```

Build Android de producción:

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define=FLAVOR=prod
```

Si necesitas apuntar temporalmente a otra API:

```bash
flutter run --flavor prod -t lib/main_prod.dart --dart-define=FLAVOR=prod --dart-define=API_URL=https://tu-api.example.com
```
