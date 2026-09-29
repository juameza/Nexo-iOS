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

**Promedio:** 76 · **Tendencia:** ⬆️ subiendo

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

---

## 🔁 Patrones a vigilar
1. **Typos en nombres:** aparecieron los dos días. Hábito: antes del commit, corre `git diff` y lee cada nombre nuevo.
2. **Copiar y pegar:** revisa lo pegado y no confíes solo en que compile.
3. **Git:** haz commit **antes** de cambiar de rama.
