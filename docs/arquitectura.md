# Arquitectura y estructura del código

## Organización

La aplicación sigue una organización por funcionalidades (`features`) y capas
con responsabilidades de dominio, datos y presentación:

```text
inventario_inteligente/
├── lib/
│   ├── main.dart
│   └── core/
│       ├── database/
│       │   └── database_helper.dart
│       └── features/
│           ├── productos/
│           │   ├── domain/
│           │   │   ├── entities/
│           │   │   ├── repositories/
│           │   │   └── usecases/
│           │   ├── data/
│           │   │   ├── datasource/
│           │   │   ├── models/
│           │   │   └── repositories/
│           │   └── presentation/
│           │       ├── pages/
│           │       ├── provider/
│           │       └── services/
│           ├── inventario/
│           │   ├── domain/
│           │   ├── data/
│           │   └── presentation/pages/
│           └── escaner/presentation/pages/
└── test/
```

- **Domain:** entidades (`Producto`, `Movimiento`), contratos de repositorio y
  casos de uso/reglas independientes de Flutter y SQLite.
- **Data:** modelos que convierten entidades a mapas SQLite, datasources locales
  y repositorios que implementan los contratos del dominio.
- **Presentation:** pantallas, formularios, estado de interfaz y servicio que
  compone la etiqueta PDF.
- **Database:** `DatabaseHelper` mantiene la instancia singleton y crea o migra
  el esquema SQLite.

## Dependencias y flujo

El flujo previsto es:

```text
Pantalla → estado/caso de uso → contrato de repositorio
         → implementación → datasource SQLite → DatabaseHelper
```

En `main.dart`, las dependencias del catálogo se construyen y entregan a
`ProductoProvider`. Las pantallas observan ese provider con `provider`. El
dominio de productos define las operaciones; los modelos convierten la entidad
de dominio al formato de almacenamiento.

Hay excepciones a la separación ideal: las páginas de historial, formulario de
movimiento y escaneo construyen o invocan algunas implementaciones/datasources
directamente. `RegistrarMovimiento` se crea en la pantalla de movimiento, y la
búsqueda por código escaneado consulta el datasource local desde la pantalla
principal. Por ello, la inyección de dependencias está centralizada para
productos, pero no para todas las funcionalidades.

## Inicialización

`main()` inicializa Flutter, prepara `DatabaseHelper`, crea el datasource y
repositorio de productos, configura sus casos de uso y registra
`ProductoProvider` en `MultiProvider`. El provider carga la lista al iniciar y
`ProductosPage` presenta la navegación principal.

## Tecnologías

- Flutter y Material 3 para interfaz y navegación.
- Dart para lógica de aplicación.
- SQLite mediante `sqflite` para almacenamiento local.
- Plugins Flutter para cámara/lectura, selección de imágenes, PDF, impresión y
  compartir archivos.

No hay backend ni protocolo de comunicación entre servicios.
