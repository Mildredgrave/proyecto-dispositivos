# Instalación, configuración y ejecución

## Herramientas y dependencias

La versión del lenguaje y las dependencias directas se declaran en
[`pubspec.yaml`](../inventario_inteligente/pubspec.yaml). Instala Flutter con
Dart `^3.13.7`, Android Studio o Android SDK, y configura un emulador o
dispositivo Android. Comprueba el entorno con:

```powershell
flutter doctor
```

Paquetes principales:

| Paquete | Uso |
| --- | --- |
| `sqflite`, `path` | Persistencia SQLite y rutas |
| `provider` | Estado observable del catálogo |
| `mobile_scanner` | Lectura de códigos con cámara |
| `barcode_widget` | Vista de Code 128 y QR |
| `pdf`, `printing` | Crear, compartir e imprimir etiquetas |
| `csv`, `share_plus`, `path_provider` | Exportar y compartir inventario |
| `image_picker` | Seleccionar fotografías de productos |
| `flutter_bloc` | Declarado como dependencia; no se identifica uso en el código de la aplicación |

Las versiones exactas resueltas se encuentran en
[`pubspec.lock`](../inventario_inteligente/pubspec.lock).

## Descargar dependencias y ejecutar

Desde la raíz del repositorio:

```powershell
cd inventario_inteligente
flutter pub get
flutter devices
flutter run
```

Para analizar el código y ejecutar pruebas automatizadas:

```powershell
flutter analyze
flutter test
```

La base de datos se crea bajo el directorio de bases de datos de la plataforma
con el nombre `inventario_inteligente.db`. No se necesita un servicio remoto ni
archivo `.env` para la configuración actual.

## Android

El proyecto utiliza Gradle Kotlin DSL, Android Gradle Plugin, Kotlin y Java
17. Las versiones del plugin se configuran en
[`settings.gradle.kts`](../inventario_inteligente/android/settings.gradle.kts),
y Gradle Wrapper está configurado en
[`gradle-wrapper.properties`](../inventario_inteligente/android/gradle/wrapper/gradle-wrapper.properties).
El permiso de cámara declarado para Android está en
[`AndroidManifest.xml`](../inventario_inteligente/android/app/src/main/AndroidManifest.xml).

La configuración de SDK mínimo y objetivo se hereda de las variables de
Flutter (`flutter.minSdkVersion` y `flutter.targetSdkVersion`) en
[`app/build.gradle.kts`](../inventario_inteligente/android/app/build.gradle.kts).
Mantener Android Studio, Android SDK, Flutter y Gradle compatibles evita
errores de compilación por versiones dispares.
