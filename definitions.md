# 🕵️ Juego del Impostor – Especificación MVP Offline Multi-Dispositivo

## 📌 Visión general

Este documento define el MVP de un juego social de deducción en persona donde:

- Los jugadores están físicamente juntos
- Cada jugador usa su propio móvil
- No hay cuentas ni chat
- La entrada a la partida se realiza mediante deep link compartido por el host
- La interacción del juego ocurre en el mundo real, no dentro de un chat

---

## 🎯 Alcance del MVP

### ✅ Incluido
- Partidas multi-dispositivo en físico
- Creación de partida por parte de un host
- Unión a partida mediante deep link
- Pantalla de selección de personaje al entrar mediante el enlace
- Nombre + avatar por jugador
- Asignación de roles
- Rondas y turnos
- Votación
- Modo Supervivencia
- Temporizador opcional
- Monetización con anuncios al iniciar la partida
- Premium del host que elimina anuncios para todos

### ❌ Excluido
- Modo un solo dispositivo
- Matchmaking online
- Chat entre jugadores
- Cuentas y autenticación persistente
- Perfil de usuario permanente
- Personalización de avatar fuera de los 10 del sistema

---

## 🧠 Estados del juego

- `WAITING`: sala de espera, jugadores entrando
- `AD_PHASE`: fase de anuncios antes de iniciar
- `READY`: revelación de rol y confirmación de listo
- `PLAYING`: ronda activa con turnos
- `DECISION`: decidir si votar o pasar a siguiente ronda
- `VOTING`: emisión de votos
- `RESULT`: resultado de votación
- `FINISHED`: partida finalizada

---

## ⚙️ Configuración de la partida

```json
{
  "category": "string",
  "junior_mode": true,
  "timer_enabled": true,
  "timer_seconds": 60,
  "survival_mode": true
}
```

### Campos
- `category`: categoría elegida por el host
- `junior_mode`: si está activo, las palabras son más sencillas y se muestra imagen
- `timer_enabled`: activa temporizador en turnos y votación
- `timer_seconds`: duración del temporizador si está activo
- `survival_mode`: si está activo, una expulsión incorrecta no termina la partida automáticamente

---

## 👤 Flujo de entrada a la partida

### Host
1. Crea la partida
2. Obtiene un enlace tipo:
   - `app://game/{game_id}`
   - o fallback web: `https://dominio.com/game/{game_id}`
3. Comparte el enlace con el botón de compartir del sistema

### Jugador invitado
1. Abre el enlace
2. Entra en la pantalla de selección de personaje
3. Escribe su nombre
4. Elige un avatar entre 10 disponibles
5. Pulsa “Unirse”
6. Entra en la sala de espera

---

## 🎭 Pantalla de selección de personaje

Esta pantalla es obligatoria al abrir el enlace de una partida.

### Objetivo
Permitir que cada jugador entre a la partida con identidad visual clara desde el inicio.

### Elementos de UI
- Título: “Únete a la partida”
- Campo de texto para nombre
- Selector de avatar
- Botón “Unirse”

### Campo de nombre
- Obligatorio
- Longitud recomendada: 2 a 20 caracteres
- Debe ser único dentro de la partida
- Se permiten letras, números y espacios
- Se recomienda normalizar espacios al inicio y al final

### Selector de avatar
- Deben existir exactamente 10 avatares predefinidos en el MVP
- Cada jugador debe seleccionar 1 avatar antes de entrar
- El avatar seleccionado se muestra junto al nombre durante toda la partida

### Regla de disponibilidad de avatar
Para el MVP, dos opciones posibles:
1. **Avatares únicos por partida** → recomendado
2. Avatares repetibles

### Decisión para el MVP
**Los avatares serán únicos por partida**.

Esto implica:
- Un avatar ya elegido por otro jugador no puede volver a seleccionarse
- Debe mostrarse como deshabilitado en la UI
- Si dos jugadores intentan elegir el mismo avatar al mismo tiempo, el backend decide y uno recibe error de conflicto

### Validaciones al unirse
- Nombre obligatorio
- Avatar obligatorio
- Nombre no repetido
- Avatar disponible
- La partida debe seguir en estado `WAITING`
- No se puede unir nadie una vez iniciada la partida

---

## 👥 Modelo de jugador

```json
{
  "id": "string",
  "name": "string",
  "avatar_id": "string",
  "is_impostor": false,
  "is_alive": true,
  "is_ready": false,
  "has_voted": false,
  "order_index": 0,
  "ad_completed": false
}
```

### Campos
- `id`: identificador del jugador
- `name`: nombre visible
- `avatar_id`: identificador del avatar elegido entre los 10 disponibles
- `is_impostor`: indica si el jugador es impostor
- `is_alive`: indica si sigue activo en la partida
- `is_ready`: indica si confirmó que ya vio su rol
- `has_voted`: indica si ya votó en la fase actual
- `order_index`: posición inicial en el orden de turnos
- `ad_completed`: indica si completó el anuncio previo al inicio

---

## 🎮 Modelo de partida

```json
{
  "id": "string",
  "status": "WAITING",
  "players": [],
  "settings": {},
  "current_round": 1,
  "current_turn_index": 0,
  "word": "string",
  "votes": [],
  "host_id": "string",
  "host_is_premium": false
}
```

---

## 🧑‍🤝‍🧑 Estado WAITING

### Objetivo
Esperar a que entren todos los jugadores y mostrar quién está en la sala.

### UI
- Lista de jugadores unidos
- Cada jugador se muestra con:
  - avatar
  - nombre
- Botón “Iniciar partida” solo para el host

### Reglas
- Mínimo: 3 jugadores
- Nombres únicos
- Avatares únicos
- Solo se puede unir gente mientras el estado sea `WAITING`

---

## 💰 Monetización

### Modelo
- Gratis con anuncios
- Premium del host elimina anuncios para todos los jugadores de esa sala

### Regla principal
Todos los jugadores deben completar la fase de anuncio antes de empezar la partida, salvo que el host tenga premium activo.

### Comportamiento
#### Si el host NO es premium
- Al iniciar la partida se entra en `AD_PHASE`
- Todos los jugadores deben ver un anuncio
- Hasta que todos completen el anuncio no se pasa a `READY`

#### Si el host SÍ es premium
- Se omite `AD_PHASE`
- La partida pasa directamente a `READY`

---

## 📺 Estado AD_PHASE

### UI
- Lista de jugadores con avatar + nombre
- Estado individual:
  - “Listo”
  - “Pendiente”
- Mensaje: “Esperando a que todos completen el anuncio”

### Reglas
- Si un jugador no completa el anuncio, la partida no puede empezar
- Debe permitirse reintentar si el anuncio falla
- El backend debe marcar `ad_completed` como verdadero solo tras confirmación válida del flujo de anuncio

---

## 🎭 Estado READY

### Flujo
Cada jugador:
1. Toca para revelar su rol
2. Ve:
   - La palabra si es civil
   - “ERES EL IMPOSTOR” si es impostor
3. Si `junior_mode` está activo y no es impostor, también ve una imagen asociada
4. Pulsa “Estoy listo”

### Reglas
- El rol/palabra se muestra solo una vez
- No se puede volver a abrir
- Cuando todos están listos, empieza la partida

---

## 🔄 Estado PLAYING

### Objetivo
Gestionar una ronda por turnos.

### UI
- Número de ronda
- Nombre y avatar del jugador actual
- Temporizador si está activo
- Botón “Listo” o “Ya hablé” para el jugador actual
- El resto ve un estado de espera

### Reglas
- Solo el jugador activo puede avanzar el turno
- El backend debe validar esto
- Si el temporizador llega a 0, el turno avanza automáticamente

### Orden de turnos
- Existe un orden base de jugadores
- En cada ronda cambia el jugador inicial
- El resto mantiene el orden relativo

Ejemplo:
- Ronda 1: A B C D
- Ronda 2: B C D A
- Ronda 3: C D A B

Si un jugador fue expulsado en Modo Supervivencia:
- se elimina del orden
- la siguiente ronda conserva el orden rotado sobre los jugadores vivos

---

## 🔚 Estado DECISION

### Objetivo
Al terminar una ronda, decidir entre votar o pasar a la siguiente ronda.

### Opciones
- Votar
- Siguiente ronda

### Regla
- La opción con mayoría simple gana
- Si hay empate en esta decisión, se recomienda que gane “Votar” o definir una regla fija

### Decisión cerrada para MVP
**Si hay empate en DECISION, gana “Votar”.**

Esto evita bucles largos y acelera la partida.

---

## 🗳️ Estado VOTING

### UI
- Lista de jugadores vivos
- Cada opción muestra avatar + nombre
- Selección única
- Temporizador si está activo

### Reglas
- No se puede votar a uno mismo
- No votar dentro del tiempo = voto nulo
- Solo se puede votar a jugadores vivos

### Modelo de voto

```json
{
  "voter_id": "string",
  "target_id": "string"
}
```

---

## 💀 Estado RESULT

### Objetivo
Mostrar el resultado de la votación.

### Mostrar
- Jugador expulsado con avatar + nombre
- Confirmación de si era o no el impostor

### Reglas
- Si hay empate en votos, nadie es expulsado
- Si nadie es expulsado, la partida continúa a la siguiente ronda

---

## 🔄 Lógica de continuidad

### Caso 1: expulsan al impostor
- Ganan los civiles
- Estado → `FINISHED`

### Caso 2: expulsan a un civil
#### Si `survival_mode` está desactivado
- Gana el impostor
- Estado → `FINISHED`

#### Si `survival_mode` está activado
- El jugador expulsado deja de estar vivo
- Si quedan 2 jugadores vivos o menos:
  - Gana el impostor
  - Estado → `FINISHED`
- En caso contrario:
  - Continúa la partida
  - Se pasa a la siguiente ronda

### Caso 3: empate en votos
- Nadie es expulsado
- Se pasa a la siguiente ronda

### Caso 4: los jugadores eligen “Siguiente ronda”
- Se pasa a la siguiente ronda directamente

---

## 🔁 Siguiente ronda

### Acciones
- Incrementar número de ronda
- Rotar jugador inicial
- Limpiar votos
- Reiniciar flags temporales de la ronda

---

## 🏁 Estado FINISHED

### UI
- Ganador: Impostor o Civiles
- Mostrar quién era el impostor
- Mostrar nombres y avatares
- Botón “Revancha”

### Revancha
Para MVP puede significar:
- crear una nueva partida con la misma configuración
- los jugadores deben volver a entrar

### Mejora futura
Permitir revancha instantánea con mismos jugadores sin rehacer la sala

---

## 🤖 Reglas de impostores

### Cantidad de impostores
- 3 a 5 jugadores → 1 impostor
- 6 a 10 jugadores → 2 impostores

### Reglas
- Los impostores no conocen la palabra
- Los impostores no saben quiénes son los otros impostores
- Todos actúan igual externamente durante la partida

---

## 🧠 Sistema de palabras

### MVP
- Una sola palabra por partida
- La palabra depende de la categoría elegida

### Junior Mode
- Usa palabras más sencillas
- Muestra imagen para ayudar al reconocimiento
- La imagen solo se muestra a jugadores no impostores

### Categorias

- Las categorias tendran un flag para saber si estan disponibles en modo junior o no.

- Esto para que cuando el modo junior este activo solo se pueda elegir entre las categorias que si tienen modo junior.

- lo mismo con las palabras, deben tener un flag para saber si es junior o no, entonces si el modo no es junior esa categoria no retornara palabras junior, y lo mismo viceversa, si el modo junior esta activo entonces solo debe retornar palabras que si son junior.

- las palabras junior ademas deben ir acompañadas de una imagen

Categorias:

Animales (Junior disponible)
Lugares (Junior disponible)
Objetos (Junior disponible)
Comida (Junior disponible)
Celebridades
Epocas
Peliculas
Deportes
Profesiones
Marcas

---

## ⚠️ Casos límite

### Desconexión durante WAITING
- El jugador puede volver a entrar si la partida sigue en `WAITING`
- Si no se conservan sesiones en MVP, puede requerirse volver a unirse manualmente

### Desconexión durante partida
- Para MVP, el jugador queda bloqueado fuera de la experiencia si pierde conexión prolongada
- Puede definirse más adelante lógica de reconexión

### Inactividad en turno
- Si hay temporizador, el turno avanza al llegar a 0
- Si no hay temporizador, la partida queda esperando hasta acción manual

### No votar
- El voto cuenta como nulo

### Conflicto de avatar o nombre
- El backend devuelve error y el usuario debe elegir otro

---

## 🔐 Anti-trampas

- La palabra o rol se muestran solo una vez
- No se pueden reabrir
- El backend valida el turno activo
- El backend valida disponibilidad de avatar al entrar
- El backend valida que nadie se una cuando la partida ya empezó
- El backend no debe confiar en estados críticos enviados por cliente sin validación

---

## 🌐 API mínima sugerida

```text
POST /games
POST /games/{id}/join
POST /games/{id}/start
POST /games/{id}/ads/complete
POST /games/{id}/ready
POST /games/{id}/next-turn
POST /games/{id}/decision
POST /games/{id}/vote
GET  /games/{id}
```

### Notas
- `POST /games/{id}/join` debe recibir nombre + avatar
- `POST /games/{id}/ads/complete` marca anuncio como completado
- `GET /games/{id}` devuelve estado completo de la partida para polling o sincronización

---

## 🧱 Backend

### Principios
- API stateless, preferiblemente
- Estado autoritativo en servidor
- Polling suficiente para MVP; WebSockets opcional

### Requisitos mínimos
- Control de nombres únicos por partida
- Control de avatares únicos por partida
- Validación de transiciones de estado
- Validación de quién puede ejecutar cada acción

---

## 📱 UX

### Principios
- Sin login
- Onboarding rápido
- Todo debe ser obvio
- Cada pantalla debe dejar claro qué debe hacer el usuario
- Los nombres y avatares deben hacer fácil identificar a cada jugador

### Importancia del avatar
El avatar no es decorativo; es parte central de la claridad del juego:
- ayuda a identificar rápidamente a los jugadores
- mejora la legibilidad en votaciones
- hace la partida más visual y divertida
- reduce confusión cuando hay nombres similares

---

## 🚀 Objetivos del MVP

- Fluidez total de la partida
- Reglas claras en segundos
- Cero fricción al entrar
- Buena identificación de jugadores
- Rejugabilidad alta
- Monetización desde el primer día

---

## ✅ Resumen de decisiones cerradas para MVP

- Modo inicial: offline multi-dispositivo en persona
- Entrada mediante deep link
- Pantalla obligatoria de selección de personaje al entrar
- Cada jugador debe elegir nombre + 1 avatar entre 10 disponibles
- Los avatares son únicos por partida
- Monetización con anuncios antes de iniciar
- Si el host tiene premium, nadie ve anuncios
- Modo Supervivencia incluido
- Modo Junior incluido
- Sin cuentas ni chat
- Sin reconexión avanzada
- Sin modo online aún
- Sin modo un solo dispositivo aún

---
