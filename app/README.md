# Impostor App

## Flavors

La app soporta dos entornos:

- `dev`: resuelve automáticamente `http://localhost:8080` y en Android usa `http://10.0.2.2:8080`
- `prod`: usa por defecto `https://impostor.manggio.com`

Ambos pueden sobreescribirse con `--dart-define=API_URL=...`.

## Comandos útiles

Desarrollo local:

```bash
flutter run -t lib/main_dev.dart
```

Dispositivos fisicos desde este Mac:

```bash
make run-iyi
make run-jenn
make run-vanessa
make run-all
```

Esos targets detectan automaticamente la IP local del host y lanzan Flutter con `--dart-define=API_URL=http://<tu-ip-local>:8080`.

`make run-all` abre una ventana de Terminal por dispositivo definido para evitar el problema de un único `flutter run` interactivo bloqueando el resto.

Producción con la URL oficial:

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

Build Android de producción:

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

Build iOS de producción:

```bash
flutter build ios --flavor prod -t lib/main_prod.dart
```

Abrir en Xcode con esquemas compartidos:

```bash
open ios/Runner.xcworkspace
```

Si necesitas apuntar temporalmente a otra API:

```bash
flutter run --flavor prod -t lib/main_prod.dart --dart-define=API_URL=https://tu-api.example.com
```

Si necesitas lanzar manualmente en un dispositivo fisico:

```bash
flutter run -t lib/main_dev.dart --dart-define=API_URL=http://<tu-ip-local>:8080
```
