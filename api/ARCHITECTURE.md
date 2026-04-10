# Arquitectura del API - Juego del Impostor

Este documento describe la arquitectura técnica elegida para el backend del proyecto, basada en **Arquitectura Hexagonal (Puertos y Adaptadores)** y principios de **Diseño Orientado al Dominio (DDD)**.

## Estructura de Capas

La lógica se organiza en tres capas principales situadas dentro de `api/internal`.

### 1. Dominio (`/internal/domain`)
Es el núcleo de la aplicación y contiene la lógica de negocio pura. No puede depender de capas exteriores ni librerías de terceros (BD, Web, etc.).

- **`entity`**: Objetos con identidad (ej. `Game`, `Player`). Contienen las reglas de negocio críticas.
- **`vo` (Value Objects)**: Objetos inmutables definidos por sus atributos (ej. `AvatarID`, `Status`).
- **`errs`**: Definiciones de errores de dominio. Centraliza todos los posibles fallos del sistema desde el punto de vista del negocio.
- **`repository`**: Interfaces (puertos) que definen cómo se debe acceder a los datos.

### 2. Aplicación (`/internal/application`)
Orquesta el flujo de datos y los casos de uso del sistema.

- **`service`**: Implementación de los casos de uso (ej. `CreateGameService`). Coordina entidades y repositorios.
- **`request`**: Objetos de transferencia (DTOs) que representan las intenciones del usuario externo.

### 3. Infraestructura (`/internal/infrastructure`)
Contiene las implementaciones técnicas y adaptadores hacia el mundo exterior.

- **`handler`**: Controladores que reciben peticiones externas (ej. HTTP).
- **`router`**: Configuración de rutas, middlewares y puesta en marcha del servidor.
- **`repository`**: Implementaciones concretas de las interfaces de dominio (ej. `PostgresRepository`, `InMemoryRepository`).
- **`dto`**: Objetos para mapeos de base de datos o respuestas del API.

---

## Política de Manejo de Errores

Se aplica un principio de **Aislamiento de Errores Técnicos**:

1. **Logueo en Infraestructura**: Los errores de terceros (drivers de DB, librerías externas) se **loguean** inmediatamente en la capa de **Infraestructura** con todos los detalles técnicos posibles.
2. **Transformación a Dominio**: La Infraestructura **nunca** devuelve errores de terceros a las capas superiores. Debe mapearlos a un error definido en `domain/errs`.
3. **Propagación Limpia**: Las capas de **Aplicación** y **Dominio** solo trabajan con errores de dominio. Se encargan de propagarlos hacia arriba.
4. **Respuesta al Cliente**: El `handler` interpreta el error de dominio y lo traduce al código de respuesta correspondiente (ej. HTTP 404, 400).

---

## Flujo de Ejecución Típico

`Request` -> `Handler` -> `Service` -> `Domain Entity` -> `Repository (Interface)` -> `Repository (Implementation)`

1. El `Handler` recibe la petición.
2. Llama al `Service` de la capa de Aplicación.
3. El `Service` utiliza las entidades de `Dominio` para ejecutar lógica.
4. Si necesita persistencia, el `Service` llama a la interfaz de `Repository`.
5. La implementación concreta en `Infraestructura` realiza la operación, maneja/loguea errores técnicos y devuelve un error de `Dominio` si falla.
