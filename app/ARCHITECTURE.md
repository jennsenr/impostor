# Arquitectura del Proyecto

Este proyecto sigue una arquitectura orientada a **Funcionalidades (Features)** utilizando principios de **Clean Architecture** y **Domain Driven Design (DDD)** simplificados para asegurar escalabilidad y mantenibilidad.

## Estructura de Carpetas Principal

Todos los archivos fuente se encuentran en `lib/src/`, organizados por módulos funcionales (features).

```text
lib/src/
├── <feature>/                # Ejemplo: auth, profile, recipes, plan
│   ├── domain/               # Capa de Dominio (Núcleo)
│   ├── application/          # Capa de Aplicación (Lógica de Negocio)
│   ├── infrastructure/       # Capa de Infraestructura (Datos/Implementación)
│   └── presentation/         # Capa de Presentación (UI/Flutter)
└── shared/                   # Código compartido entre múltiples módulos
```

---

## Definición de las Capas

### 1. `domain/` (Capa de Dominio)
Es el núcleo de la lógica de negocio. Es totalmente independiente de librerías externas o detalles técnicos de la plataforma.
- **Entities**: Objetos de negocio con identidad propia (ej: `User`, `Recipe`).
- **Value Objects**: Conceptos de negocio sin identidad propia (ej: `Email`, `Password`).
- **Interfaces de Repositorio**: Definición de contratos que indican *qué* datos necesitamos, sin detallar *cómo* se obtienen.
- **Failures / Errors**: Definición de estados de error específicos del dominio.

### 2. `application/` (Capa de Aplicación)
Gestiona el estado y orquesta el flujo de datos entre la UI y el Dominio.
- **Cubits / BLoCs**: Controladores de estado reactivos que manejan la lógica de la vista.
- **States**: Representación inmutable de los diferentes estados de la interfaz.

### 3. `infrastructure/` (Capa de Infraestructura)
Implementa los detalles técnicos y la comunicación con el exterior.
- **Implementación de Repositorios**: Código real que realiza llamadas a APIs o bases de datos (ej: `ApiAuthRepository`).
- **DTOs (Data Transfer Objects)**: Modelos de datos para la serialización de respuestas externas (JSON).
- **Mappers**: Lógica para transformar DTOs en Entities de dominio y viceversa.
- **Data Sources / Services**: Clientes específicos para servicios externos (ej: `DioClient`, `NotificationService`).

### 4. `presentation/` (Capa de Presentación)
Contiene todo lo relacionado con Flutter y la experiencia de usuario.
- **Pages**: Pantallas completas de la aplicación.
- **Widgets**: Componentes visuales reutilizables específicos de la funcionalidad actual.
- **Utils**: Helpers visuales o formateadores exclusivos de la UI.

---

## `shared/` (Recursos Compartidos)

Para mantener el código DRY (Don't Repeat Yourself), los elementos comunes se centralizan aquí:
- **shared/presentation/widgets/**: Componentes globales como `ButtonWidget` e `InputFieldWidget`.
- **shared/infrastructure/**: Cliente HTTP (`Dio`), interceptores globales e inyección de dependencias (`bindings`).
- **shared/presentation/l10n/**: Traducciones centralizadas gestionadas por `intl`.
- **shared/config/**: Configuraciones globales de entorno y constantes de la aplicación.

---

## Flujo de Datos Típico
1. El **Widget** (`presentation`) solicita una acción al **Cubit** (`application`).
2. El **Cubit** llama a un método de la **Interface del Repositorio** (`domain`).
3. La **Implementación del Repositorio** (`infrastructure`) realiza la llamada técnica, mapea el resultado a una **Entity** y la devuelve.
4. El **Cubit** emite un nuevo **State**, y la **UI** se reconstruye reflejando los cambios.
