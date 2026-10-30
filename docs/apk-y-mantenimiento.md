# Compilación APK, limitaciones y mantenimiento

## Generar e instalar el APK

Desde `inventario_inteligente/`:

```powershell
flutter pub get
flutter build apk --debug
```

El APK de depuración se genera en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

**Verificación registrada:** `flutter build apk --debug` terminó con éxito.
La salida informó advertencias de compatibilidad de herramientas Android (XML
SDK versión 4 frente a soporte hasta versión 3) y de acceso nativo restringido
en Java; no bloquearon la compilación.

Para generar una compilación release:

```powershell
flutter build apk --release
```

El artefacto release se genera en
`build/app/outputs/flutter-apk/app-release.apk`. Para instalar en un dispositivo
conectado puede usarse `flutter install`, o transferir el APK y permitir su
instalación conforme a la configuración del dispositivo.

## Firma y distribución

La configuración `release` en
[`app/build.gradle.kts`](../inventario_inteligente/android/app/build.gradle.kts)
usa actualmente la firma de depuración. No debe distribuirse como lanzamiento
de producción: configurar una clave de firma release fuera del repositorio,
proteger sus credenciales y verificar la configuración antes de publicar. El
`applicationId` actual es `com.example.inventario_inteligente`; debe cambiarse
por un identificador de distribución propio antes de publicar.

## Limitaciones conocidas

- La base y las fotografías son locales al dispositivo; no hay usuarios,
  autorización, sincronización, recuperación ni respaldo remoto.
- La cámara, permisos, impresión y compartir archivos dependen del sistema
  operativo y requieren pruebas en dispositivos reales.
- Los tests automatizados no cubren la capa SQLite, triggers, migraciones,
  permisos ni integración completa de interfaz.
- El esquema declara claves foráneas, pero el helper no activa explícitamente
  `PRAGMA foreign_keys`; no se debe depender de su aplicación automática.
- Las fotos se guardan en archivos privados y se persisten por ruta. No hay
  rutina de limpieza para imágenes huérfanas.
- El QR solo codifica el identificador, no la información del producto ni
  existencias.
- La etiqueta usa fuentes PDF estándar; la ejecución de pruebas reportó que
  esas fuentes no soportan todos los caracteres Unicode.
- `flutter_bloc` está en dependencias, aunque la aplicación observada usa
  `provider`.

## Mantenimiento

1. Cambiar la versión de esquema en `DatabaseHelper` al modificar tablas y
   agregar una migración incremental explícita. No borrar la base de datos de
   usuarios para aplicar cambios.
2. Mantener el código de producto como identificador estable: etiquetas
   impresas existentes dependen de él.
3. Mantener las reglas de existencias en el dominio y volver a verificarlas en
   la transacción de persistencia.
4. Al actualizar Flutter/plugins/Gradle, ejecutar `flutter pub get`,
   `flutter analyze`, `flutter test` y una compilación APK.
5. Validar permisos de cámara, flujos de compartir/impresión y exportación CSV
   en los dispositivos objetivo antes de publicar.
6. Configurar firma e identificador propios y documentar un procedimiento de
   respaldo/recuperación local antes de un despliegue de producción.
