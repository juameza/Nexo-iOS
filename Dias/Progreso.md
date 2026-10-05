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

**Promedio:** 74.5 · **Tendencia:** ➡️ estable. El código y Git mejoran; los conceptos siguen siendo el área débil.

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

---

## 🔁 Patrones a vigilar
1. **Typos en nombres:** aparecieron los tres días, y el Día 3 uno en un *String* rompió la funcionalidad. Hábito: `git add .` y luego `git --no-pager diff --staged`, leyendo cada nombre y cada String.
2. **Copiar y pegar:** revisa lo pegado y no confíes solo en que compile.
3. **Git:** haz commit **antes** de cambiar de rama.
4. **Memoria (ARC):** `weak`, `strong` y retain cycles salieron dos veces (Día 1 P1 y Día 3 P1). En el Día 4 ya mejoró (P3 ✅), pero falta explicar la cadena completa del ciclo.
5. **Preguntas incompletas:** en el Día 4 una quedó sin responder y otra respondió solo 1 de sus 3 partes. Contesta cada parte por separado.
6. **Caracteres parecidos:** `.` en lugar de `·`, `*` en lugar de `✓`. Copia los símbolos de la guía.
