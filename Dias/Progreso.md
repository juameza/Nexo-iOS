# 📊 Progreso y calificaciones

Cada día se califica **después** de revisar el código final (tras las correcciones), sobre **100 puntos**.

## 📏 Rúbrica

| Área | Puntos | Qué se evalúa |
|---|---|---|
| 💻 Código | 40 | Funciona, sigue la guía, sin bugs, nombres correctos, buenas prácticas |
| 🧪 Tests | 20 | Todos pasan (⌘U), cubren los casos pedidos, nombres claros |
| 🌿 Git y proceso | 15 | Rama, commits claros, merge a `main`, repo limpio |
| 🧠 Conceptos | 25 | Preguntas de repaso (5 pts c/u: ✅ 5 · 🟡 3 · 🔴 0) |
| ⭐ Bonus | +5 | Reto extra o algo más allá de lo pedido (máx. 100) |

| Rango | Nivel |
|---|---|
| 90–100 | 🏆 Excelente |
| 80–89 | ✅ Muy bien |
| 70–79 | 👍 Bien, con puntos a reforzar |
| 60–69 | ⚠️ Suficiente: repasa antes de avanzar |
| < 60 | 🔁 Repetir el día |

---

## 📈 Resumen

| Día | Tema | Código | Tests | Git | Conceptos | Bonus | **Total** | Nivel |
|---|---|---|---|---|---|---|---|---|
| 1 | Login en Storyboard + `EmailValidator` | 30 | 15 | 13 | 16 | 0 | **74** | 👍 Bien |
| 2 | Modelos, `Codable`, JSON mock | 31 | 18 | 11 | 18 | 0 | **78** | 👍 Bien |
| 3 | Registro, segues, delegate, `PasswordValidator` | 30 | 19 | 12 | 11 | 0 | **72** | 👍 Bien |
| 4 | Feed con `UITableView`, ARC y test de memory leak | 31 | 19 | 13 | 11 | 0 | **74** | 👍 Bien |
| 5 | Raíz por código, tabs, `UserDefaults` y SwiftUI | 31 | 15 | 10 | 8 | 0 | **64** | ⚠️ Suficiente |
| 6 | `URLSession`, GCD, caché y celdas recicladas | 37 | 18 | 15 | 16 | 0 | **86** | ✅ Muy bien |
| 7 | Carga asíncrona, `enum State`, pull to refresh | 32 | 18 | 13 | 11 | 0 | **74** | 👍 Bien |
| 8 | MVVM: `FeedViewModel` y binding por closures | 36 | 20 | 13 | 3 | 0 | **72** | 👍 Bien |

**Promedio:** 74.3 · **Tendencia:** ➡️ código y tests en su mejor nivel (56/60 el Día 8); la nota se queda en 70s solo por las preguntas en blanco (Día 7: 2, Día 8: 4
**Promedio:** 74.3 · **Tendencia:** ➡️ código y tests en su mejor nivel (56/60 el Día 8); la nota se queda en 70s solo por las preguntas en blanco (Día 7: 2, Día 8: 4).

---

## 📝 Detalle

### Día 1: 74/100 👍
- **💻 Código 30/40:** funcionó al primer intento y la estructura es buena. Restas: faltó el Navigation Controller, varios typos en nombres (`EmailValidatiosError`, `logintButtonTapped`) y textos, y `==` en lugar de `===`.
- **🧪 Tests 15/20:** 7/7 en verde. Resta: al borrar el bridging header quedó la referencia en Build Settings y ⌘U dejó de compilar.
- **🌿 Git 13/15:** rama, commits y merge correctos. Resta: typo en el mensaje (`emiail`).
- **🧠 Conceptos 16/25:** P1 🟡 · P2 🔴 (`==` vs `===`) · P3 🟡 · P4 ✅ · P5 ✅
- **✨ Lo mejor:** usaste Refactor → Rename correctamente con el selector del storyboard.
- **🎯 A reforzar:** identidad vs igualdad; revisar nombres antes del commit.

### Día 2: 78/100 👍
- **💻 Código 31/40:** todos los modelos, el loader y el `switch` como expresión funcionan. Restas: `CodinKeys` provocaba un **bug silencioso** (todos los avatares en `nil`), typos (`decondingFailed`, `PostDecondingTests`) y un UUID corrupto al copiar el test nuevo.
- **🧪 Tests 18/20:** 19/19 en verde, incluido el test de `avatarURL` que cubre el bug. Resta: el test nuevo falló al principio por el copiado.
- **🌿 Git 11/15:** commits claros y merge final correcto. Resta: dejaste el merge sin hacer por no entender el cambio de rama, y había cambios sin commit.
- **🧠 Conceptos 18/25:** P1 🔴 (`let` + `mutating`) · P2 ✅ · P3 ✅ · P4 ✅ · P5 ✅
- **✨ Lo mejor:** corregiste **todo** lo señalado, incluidos los menores, y el razonamiento de P3–P5 es sólido.
- **🎯 A reforzar:** semántica de `let`/`var` en structs; releer el código pegado (el compilador no detecta typos en strings ni en nombres de `CodingKeys`).

### Día 3: 72/100 👍
- **💻 Código 30/40:** `RegistrationForm`, `PasswordValidator` y el delegate quedaron bien. Restas: dos bugs funcionales, el typo `"howRegister"` (el email no llegaba y el delegate quedaba en `nil`) y `passwordChanged:` conectado a *Editing Did End*; además `isSatified` y textos sin acento. Todo quedó corregido.
- **🧪 Tests 19/20:** 32/32 en verde y bien escritos. Resta menor: ningún test detectó los dos bugs (tampoco los pedía la guía).
- **🌿 Git 12/15:** rama, commit y merge correctos, y la corrección se hizo en su propia rama `fix/`. Resta: no supiste usar `git diff` (no muestra lo que ya está en el *stage* ni los archivos nuevos).
- **🧠 Conceptos 11/25:** P1 🔴 (`weak`/`AnyObject`) · P2 🟡 · P3 🔴 · P4 ✅ · P5 🟡
- **✨ Lo mejor:** reportaste el checklist con honestidad (❌ incluidos) y describiste bien el síntoma ("cambia cuando me cambio de campo"), lo que llevó directo al bug.
- **🎯 A reforzar:** gestión de memoria (ARC, `weak`, retain cycles); para qué sirve separar la lógica de la UI (testabilidad); `git diff --staged`.

### Día 4: 74/100 👍
- **💻 Código 31/40:** el Feed funciona completo (4 posts, alto automático, ❤️, `poll` y navegación con `creator:`), el `[weak self]` está bien y el storyboard está correcto. Restas: punto `.` en lugar de `·` en `previewText` (lo detectó el test) y en `metaLabel` (ningún test lo detecta), `*` en lugar de `✓`, código comentado del experimento y métodos vacíos en el Login, botón ❤️ otra vez en *Touch Up Inside* y typos en comentarios (`Usam`, `Initiañ ViewContoller`).
- **🧪 Tests 19/20:** 40/40 en verde. Comprobaste que el test de leak falla sin `[weak self]`. Resta menor: el test de `previewText` falló al principio por el typo.
- **🌿 Git 13/15:** rama, commit y merge correctos, y usaste `diff --staged`. Resta: el código comentado del experimento entró en el commit, aunque el Paso 9 pedía revisarlo.
- **🧠 Conceptos 11/25:** P1 🔴 (reciclaje) · P2 🟡 · P3 ✅ · P4 🔴 (sin respuesta) · P5 🟡
- **✨ Lo mejor:** hiciste todos los experimentos (Memory Graph y test de leak que falla y pasa), y P3 (`weak` vs `unowned`) ya sale bien: avance real en ARC.
- **🎯 A reforzar:** responder **todas** las partes de cada pregunta; reciclaje de celdas; inyección de dependencias; borrar el código de los experimentos antes del commit.

### Día 5: 64/100 ⚠️
- **💻 Código 31/40:** router, sesión, tabs, `AccountView` y los dos `[weak self]` funcionan; los pendientes del Día 4 quedaron corregidos. Restas: `AppInfo` distinto de la guía (sin paréntesis, parámetro no opcional y un `!`), y **Main Interface** sigue con `Main` y se agregó `UIStatusBarStyle = ""` sin querer.
- **🧪 Tests 15/20:** 50/50 en verde tras la corrección. Restas: se cambió un test (`nil` → `["":""]`) para que se ajustara al código, y un typo en el dato de otro (`ane@`).
- **🌿 Git 10/15:** la corrección se hizo en su rama `fix/`. Resta: **merge a `main` con 3 tests en rojo**.
- **🧠 Conceptos 8/25:** P1 🟡 · P2 🔴 · P3 🔴 (sin respuesta) · P4 🔴 (sin respuesta) · P5 ✅
- **✨ Lo mejor:** completaste los tres experimentos y el checklist, y P5 (UserDefaults contra Keychain) está bien.
- **🎯 A reforzar:** ⌘U **antes** de cada commit; si un test no compila, revisa primero el código y no el test; quién es dueño de cada objeto (ARC); responder todas las preguntas.

### Día 6: 86/100 ✅
- **💻 Código 37/40:** loader, caché, validación de `statusCode`, las dos defensas contra la imagen equivocada y el storyboard (stack horizontal, 40×40) están bien, sin `print` ni código comentado. Restas: cambiaste el valor de `CodingKeys` por la URL (lo regresaste antes del commit) y typos en comentarios (`vacai`, `interner`, `rela`).
- **🧪 Tests 18/20:** 58/58 en verde. Resta: al copiar, dos tests de `RemoteImageLoaderTests` quedaron en uno (nombre de un caso, contenido de otro); se corrigió antes del commit.
- **🌿 Git 15/15:** rama, ⌘U en verde **antes** del commit, diff revisado y merge a `main`. Lección del Día 5 aplicada.
- **🧠 Conceptos 16/25:** P1 🟡 · P2 🟡 · P3 ✅ · P4 🔴 · P5 ✅
- **✨ Lo mejor:** el proceso completo, y notaste por tu cuenta que Xcode contaba 57 y no 58.
- **🎯 A reforzar:** retain cycle contra "objeto que vive de más" en closures asíncronas; qué es `error` en `URLSession` (transporte) y qué es un status HTTP.

### Día 7: 74/100 👍
- **💻 Código 32/40:** estados con `enum`, `render` único, pull to refresh, `guard !isLoading` y `[weak self]` quedaron bien. Restas: faltó `refreshControl = refresh` (el refresh no funcionaba), `isLoading = true` en `handle` (habría bloqueado el segundo refresh), líneas viejas duplicadas en `toggleLike` y el `// print("pidiendo el feed")` comentado entró en el commit.
- **🧪 Tests 18/20:** 66/66 en verde antes del commit. Resta: a `test_refreshCompletes_replacesPosts` le faltaba `simulatePullToRefresh()` (crash `Index out of range`). Punto a favor: agregaste el `guard` con `XCTFail` al spy.
- **🌿 Git 13/15:** rama, ⌘U en verde, commit y merge a `main`. Resta: el checklist marca "sin código comentado" ✅, pero el `print` comentado está en el commit.
- **🧠 Conceptos 11/25:** P1 🟡 · P2 🟡 · P3 🔴 (sin respuesta) · P4 ✅ · P5 🔴 (sin respuesta)
- **✨ Lo mejor:** describiste bien los síntomas ("no aparece el loading", "no imprime nada") y eso llevó directo a la línea faltante; P4 (quién debe guardar el like) es correcta.
- **🎯 A reforzar:** responder **todas** las preguntas; revisar que el checklist refleje lo que de verdad hay en el commit.

### Día 8: 72/100 👍
- **💻 Código 36/40:** `FeedViewModel` sin UIKit, las cuatro closures con `[weak self]`, `bind()` antes de `load()`, `refreshPulled` y el router correctos; sin `print` de experimentos ni código comentado. Restas: el texto de vacío sigue con `"Se"` sin acento (se había señalado), typos en comentarios (`Privaod`, `setStatus`, `ya hay un peticion`).
- **🧪 Tests 20/20:** 77/77 en verde antes del commit, 13 + 13 en las clases del Feed, helper `flushMainQueue` compartido. Sin errores de copiado.
- **🌿 Git 13/15:** rama, commit y merge a `main` correctos y repo limpio. Resta: el checklist quedó vacío y no se anotaron los resultados de los experimentos 6.1–6.3.
- **🧠 Conceptos 3/25:** P1 🟡 · P2 🔴 (sin respuesta) · P3 🔴 (sin respuesta) · P4 🔴 (sin respuesta) · P5 🔴 (sin respuesta)
- **✨ Lo mejor:** el refactor más limpio hasta ahora: código y tests al primer intento (salvo el nombre del parámetro en `bind`).
- **🎯 A reforzar:** las preguntas. Con código y tests así, contestarlas a medias habría dado **84+**.

---

## 🔁 Patrones a vigilar
1. **Typos en nombres:** aparecieron los tres días, y el Día 3 uno en un *String* rompió la funcionalidad. Hábito: `git add .` y luego `git --no-pager diff --staged`, leyendo cada nombre y cada String.
2. **Copiar y pegar:** revisa lo pegado y no confíes solo en que compile.
3. **Git:** haz commit **antes** de cambiar de rama.
4. **Memoria (ARC):** `weak`, `strong` y retain cycles salieron dos veces (Día 1 P1 y Día 3 P1). En el Día 4 ya mejoró (P3 ✅), pero falta explicar la cadena completa del ciclo.
5. **Preguntas incompletas:** Día 4 (1 en blanco), Día 5 (2 en blanco), Día 7 (2 en blanco) y Día 8 (4 en blanco). Es lo que más puntos te cuesta. Contesta cada parte por separado, aunque sea con lo que viste en el experimento.
6. **Caracteres parecidos:** `.` en lugar de `·`, `*` en lugar de `✓`. Copia los símbolos de la guía.
7. **Tests en rojo:** el Día 5 se hizo merge con 3 tests fallando y se modificó un test para que compilara. Regla: ⌘U en verde → commit → merge. ✅ Corregido en el Día 6.
8. **Contar los tests:** si el total no coincide con la guía, `grep -rc "func test" NexoTests` y compara archivo por archivo (Día 6).
