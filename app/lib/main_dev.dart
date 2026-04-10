import 'src/shared/config/app_config.dart';
import 'main.dart' as app;

void main() async {
  AppConfig.configureFlavor(AppFlavor.dev);
  await app.bootstrap();
}
