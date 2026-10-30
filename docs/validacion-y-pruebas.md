# Validación, errores, consistencia y pruebas

## Validaciones

El formulario y los casos de uso validan campos de producto, precios finitos
mayores que cero, stock mínimo no negativo y stock inicial igual a cero. En los
movimientos se valida identificador de producto, tipo, cantidad, motivo,
responsable, estado activo y límites de stock. La persistencia añade
protecciones con triggers para operaciones que no deben permitirse aunque se
intenten fuera de la interfaz.

## Consistencia de movimientos

`InventarioLocalDataSource.registrarMovimiento` ejecuta en una transacción:

1. Comprueba que el identificador de producto coincida con el movimiento y
   exige motivo, responsable y fecha.
2. Lee el producto actual y rechaza producto inexistente o inactivo.
3. Compara `stockAnterior` con el stock guardado para detectar datos obsoletos.
4. Calcula el resultado esperado según el tipo y valida el valor recibido.
5. Inserta el movimiento y actualiza `productos.stockActual` con condición de
   stock y estado activos previos.
6. Lanza error si no se actualizó exactamente un producto.

Una excepción revierte la transacción completa. Los triggers impiden editar o
eliminar movimientos confirmados. Para corregir un movimiento se registra otro
movimiento con su motivo.

## Manejo de errores

Los casos de uso y datasources lanzan `ArgumentError` para entradas inválidas y
`StateError` para estados no permitidos, como stock obsoleto o insuficiente.
Las pantallas muestran errores mediante mensajes o texto en pantalla; el
provider conserva el último error de catálogo. Los errores al seleccionar o
guardar fotografías, exportar CSV y compartir/imprimir etiquetas se notifican
al usuario.

## Pruebas automatizadas

Ejecutadas desde `inventario_inteligente/`:

```powershell
flutter test
```

**Resultado registrado:** 14 pruebas aprobadas (`All tests passed!`).

| Archivo | Evidencia/cobertura |
| --- | --- |
| [`registrar_producto_test.dart`](../inventario_inteligente/test/registrar_producto_test.dart) | Stock inicial cero, campos requeridos, categoría, límites de precio/stock mínimo y regla de alerta. |
| [`registrar_movimiento_test.dart`](../inventario_inteligente/test/registrar_movimiento_test.dart) | Entrada/salida, cantidades inválidas, insuficiencia de stock, cálculo de ajuste y rechazo de producto inactivo. |
| [`producto_provider_test.dart`](../inventario_inteligente/test/producto_provider_test.dart) | Búsqueda sin distinguir mayúsculas/minúsculas por nombre y código. |
| [`etiqueta_producto_pdf_test.dart`](../inventario_inteligente/test/etiqueta_producto_pdf_test.dart) | PDF no vacío y firma `%PDF-`. |

El caso de PDF emite advertencias de las fuentes Helvetica estándar sobre
soporte Unicode; no impidieron que la prueba pasara. No hay pruebas de widget,
integración de SQLite/transacciones, permisos de cámara, impresión en
dispositivo ni flujo completo de CSV.

## Análisis estático y pasos de reproducción

Ejecutado desde `inventario_inteligente/`:

```powershell
flutter analyze
```

**Resultado registrado:** `No issues found!`.

Para reproducir el conjunto automatizado y el análisis:

```powershell
cd inventario_inteligente
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

**Resultado registrado:** la compilación Android debug finalizó correctamente.
En este entorno Gradle mostró advertencias de acceso nativo restringido de Java
y de herramientas Android que reconocen XML SDK hasta la versión 3, al
encontrar un XML versión 4; no impidieron generar el APK.

Para pruebas manuales de inventario, crear un producto, añadir una entrada,
intentar una salida mayor al stock, hacer un ajuste físico, filtrar el
historial y confirmar que stock previo/resultante y responsable coinciden.
Repetir con producto inactivo y confirmar que no permite registrar movimientos.
Los pasos de cámara están en [Códigos y cámara](./codigos-y-camara.md).

## Evidencia y límites

La evidencia versionada actualmente consiste en los archivos de pruebas
anteriores y la salida reproducible de los comandos; no se guardan capturas,
reportes de cobertura ni evidencia de pruebas en dispositivos. Las pruebas de
movimientos usan repositorios falsos, por lo que no verifican el comportamiento
real de SQLite ni los triggers.
