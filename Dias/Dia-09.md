# 📅 Día 9: CI con GitHub Actions: Pull Requests y `main` protegida

**Nivel:** 🐣 Junior (herramientas profesionales) · **Duración:** 2–2.5 h (la primera vez en GitHub siempre toma más)
**Temas:** **CI vs CD**, Git remoto (`origin`, `push`, `pull`), **SSH** vs HTTPS, **Pull Requests**, **GitHub Actions** (workflow, job, step, runner), `xcodebuild` desde la terminal, **scheme compartido**, firma de código en CI, `set -o pipefail`, **Rulesets** 🟢 vs *Branch protection* 🟤.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Tu repo en **GitHub**, con tus 8 días de historia.
2. Un **workflow** que compila y corre los **77 tests** en una Mac de GitHub en **cada Pull Request**.
3. **`main` protegida**: ni tú puedes hacer merge (ni `push` directo) si los tests están en rojo.
4. Un script `scripts/test.sh` que corre **exactamente lo mismo** que el CI, en tu Mac.
5. Tu **primer PR con código**: quitar el warning de `UIWindow(frame:)` deprecado.

Hoy casi no escribes Swift. Escribes **proceso**: la regla "⌘U antes del merge" la va a cumplir una máquina, no tu memoria (Día 5 🙃).

---

## 📚 Concepto 1: CI vs CD

| | Qué hace | Cuándo | En Nexo |
|---|---|---|---|
| **CI** (Integración Continua) | Compila y corre los tests **en una máquina limpia** | En cada PR y en cada cambio de `main` | **Hoy** |
| **CD** (Entrega Continua) | Genera la app firmada y la sube a **TestFlight** | Al hacer merge a `main` o al crear un tag | Senior (necesita Apple Developer Program) |
| **CD** (Despliegue Continuo) | Además la **publica** sin intervención humana | Casi nunca en iOS (App Review lo impide) | — |

**¿Por qué una "máquina limpia"?** Porque tu Mac **miente**: tiene DerivedData viejo, archivos que nunca agregaste a Git, un scheme que solo existe en tu usuario, tu certificado de firma… El CI descarga **solo lo que está en Git**. Si ahí compila, compila para cualquiera.

---

## 📚 Concepto 2: Lo viejo 🟤 y lo nuevo 🟢

| Tema | 🟤 Viejo (lo vas a encontrar en empresas) | 🟢 Nuevo |
|---|---|---|
| Servidor de CI | **Jenkins** con Mac mini propias, Travis CI, CircleCI, Bitrise | **GitHub Actions**, **Xcode Cloud** (de Apple) |
| Automatización iOS | **Fastlane** (`fastlane scan`, `gym`, `match`) | Sigue vivo; para tests simples basta `xcodebuild` |
| Configuración | Clics en la web de Jenkins (nadie sabe qué cambió) | **YAML en el repo** (*pipeline as code*): se revisa en el PR como el código |
| Autenticación Git | Usuario + contraseña por HTTPS (**GitHub lo eliminó en 2021**) | **SSH** o *Personal Access Token* |
| Proteger ramas | *Branch protection rules* | **Rulesets** (más flexibles, varias ramas, con historial) |
| Integrar código | `git merge` local a `main` (lo que hacías) | **Pull Request** con checks y revisión |

> 💡 En entrevistas de Mid/Senior te preguntan: *"¿cómo es tu pipeline?"*. "Corro ⌘U antes de hacer merge" **no** es una respuesta. "Cada PR corre los tests en GitHub Actions y `main` exige el check en verde" **sí**.

---

## 📚 Concepto 3: Anatomía de un workflow

```
Evento (pull_request)  →  Workflow (ci.yml)  →  Job "Tests (iOS)"  →  Runner (Mac macos-26 de GitHub)
                                                     │
                                                     ├─ step 1: descargar el código
                                                     ├─ step 2: elegir Xcode 26.6
                                                     ├─ step 3: xcodebuild test
                                                     └─ step 4: si falló, subir resultados
```
- **Workflow:** un archivo `.yml` dentro de `.github/workflows/`.
- **Evento (`on:`):** qué lo dispara. Hoy: abrir/actualizar un PR hacia `main`, y cada `push` a `main`.
- **Job:** un conjunto de pasos que corre en **una** máquina. Su `name` (`Tests (iOS)`) es el **check** que vas a exigir en `main`.
- **Runner:** la máquina. `macos-26` es una Mac de GitHub que **se borra** al terminar cada corrida.
- **Step:** un comando (`run:`) o una acción reutilizable (`uses:`).

---

## 📚 Concepto 4: "En mi Mac sí funciona": las 4 trampas de iOS en CI

| Trampa | Qué pasa en el CI | Solución de hoy |
|---|---|---|
| **Scheme no compartido** | Tu scheme vive en `xcuserdata/` (que el `.gitignore` ignora). El CI depende de que Xcode lo invente solo, y ese scheme "inventado" puede no incluir los tests | **Shared** → `xcshareddata/xcschemes/` (Paso 2) |
| **Firma de código** | El runner no tiene tu certificado ni tu cuenta: falla al firmar | `CODE_SIGNING_ALLOWED=NO` (para el simulador no hace falta firmar) |
| **Simulador o Xcode distinto** | Tu proyecto exige **iOS 26.5**. Si el runner usara Xcode 26.4, no compilaría | Fijar `Xcode_26.6` y `OS=26.5` (revisé la imagen `macos-26`: los tiene) |
| **La tubería se "traga" el error** | `xcodebuild … \| xcbeautify` devuelve el código de salida de **xcbeautify** (0), no el de xcodebuild. **Tests en rojo, CI en verde** 😱 | `set -o pipefail` (experimento 7.3) |

> Comprobado en tu Mac:
> ```
> false | cat   → sin pipefail: 0   (¡éxito!)
> false | cat   → con pipefail: 1   (falla, como debe)
> ```

---

## 📚 Concepto 5: Flujo de trabajo desde hoy

```
main ─────●──────────────────────●──────────────▶   (protegida: solo entra por PR con ✅)
           \                    /
            feature/dia-09-ci ●──●   → push → PR → CI ✅ → Merge en GitHub
```
1. `git checkout -b feature/...` (igual que siempre)
2. Commits (igual que siempre)
3. **`git push -u origin feature/...`** (nuevo)
4. **Abrir un PR en GitHub** → el CI corre solo (nuevo)
5. **Merge en GitHub** cuando esté ✅ (ya no `git merge` local)
6. `git checkout main && git pull` (nuevo)

> 💡 *"¿Un PR si trabajo solo?"* Sí: el PR es donde corre el CI, donde **tú mismo** revisas el diff completo antes de integrar (tu punto débil: los typos) y donde queda el historial de *por qué* cambió algo.

---

## 💻 Paso 0: Preparación local

### 0.1 Tu identidad en Git
Tus commits hoy salen como `MMJ <mmj@MMJs-MacBook-Pro.local>`. Ese correo no existe, así que **GitHub no los asocia a tu cuenta** (no salen en tu perfil ni con tu foto).

1. En GitHub: foto → **Settings → Emails**. Copia tu correo `…@users.noreply.github.com` (protege tu correo real en un repo público).
2. En Terminal:
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "123456+tuusuario@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global pull.rebase false     # 'git pull' hace merge (lo que ya conoces)
```
> Los commits viejos se quedan con el correo anterior. No vale la pena reescribir la historia por eso.

### 0.2 Limpia ramas viejas
Tienes 13 ramas locales ya mergeadas. No se suben, pero estorban:
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git branch --merged main        # mira la lista: todas deberían estar mergeadas
git branch --merged main | grep -vE '^\*|^[[:space:]]*main$' | xargs git branch -d
git branch                      # solo debe quedar: * main
```
> ⚠️ Una versión anterior de esta guía usaba `grep -v "main"`, que también excluía `fix/dia-05-main-interface` porque **contiene** la palabra "main". La regex de arriba solo excluye la línea que es **exactamente** `main` y la rama actual (`*`). Lección de *shell*: filtra por patrón exacto, no por "contiene".
> `-d` (minúscula) **se niega** a borrar una rama que no esté mergeada. Es seguro. `-D` (mayúscula) borra sin preguntar: evítalo.

### 0.3 Antes de hacer público: ¿hay secretos?
Buscar la palabra `password` da **falsos positivos** (`PasswordValidator`, `form.password`…). Busca **formatos** de llaves reales y **archivos** sensibles, también en la **historia** (un secreto borrado en un commit nuevo sigue visible en los viejos):
```bash
# 1) Formatos de llaves (GitHub, AWS, Google, OpenAI, llaves privadas)
git grep -n -E "ghp_[A-Za-z0-9]{20,}|github_pat_|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|sk-[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY"
# 2) Archivos que nunca deben estar en Git
git ls-files | grep -i -E "\.env$|\.p12$|\.pem$|\.mobileprovision$|GoogleService-Info|credentials"
# 3) Toda la historia (debe dar 0)
git log --all -p | grep -c -E "ghp_|github_pat_|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY"
```
Las dos primeras no deben imprimir nada y la tercera debe dar `0`. Tu `DEVELOPMENT_TEAM` (Team ID) aparece en `project.pbxproj`: **no es secreto** (viene dentro de cada app firmada).

---

## 💻 Paso 1: Llave SSH (no tienes ninguna en `~/.ssh`)

```bash
ssh-keygen -t ed25519 -C "123456+tuusuario@users.noreply.github.com"
# Enter para la ruta por defecto. Pon una passphrase (se guarda en el llavero de macOS).
```
Crea (o edita) `~/.ssh/config`:
```bash
open -e ~/.ssh/config 2>/dev/null || (touch ~/.ssh/config && open -e ~/.ssh/config)
```
Con este contenido:
```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```
Luego:
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub          # copia la llave PÚBLICA (.pub)
```
En GitHub: **Settings → SSH and GPG keys → New SSH key** → Title: `MacBook Pro` → pega → **Add SSH key**.

Comprueba:
```bash
ssh -T git@github.com
# "Hi tuusuario! You've successfully authenticated, but GitHub does not provide shell access."
```
> 🔐 **La primera vez** saldrá `The authenticity of host 'github.com' can't be established` con una huella. Compárala con la [oficial de GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints). La Ed25519 es `SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`. Si coincide, escribe **`yes`**: queda guardada en `~/.ssh/known_hosts`. Si algún día sale `REMOTE HOST IDENTIFICATION HAS CHANGED`, **no aceptes** sin volver a comparar.
>
> ⚠️ **Nunca** compartas `id_ed25519` (sin `.pub`): es la llave privada. La `.pub` sí se puede compartir.

---

## 💻 Paso 2: Compartir el scheme

Hoy tu proyecto **no tiene un scheme compartido**: Xcode genera uno automático para tu usuario. En Xcode:

1. **Product → Scheme → Manage Schemes…**
2. En la fila **RoadmapSwift**, marca la casilla **Shared**. → **Close**.
3. **Product → Scheme → Edit Scheme… → Test**: confirma que aparece **NexoTests**.

Comprueba en Terminal:
```bash
git status
# Untracked: RoadmapSwift.xcodeproj/xcshareddata/
ls RoadmapSwift.xcodeproj/xcshareddata/xcschemes/
# RoadmapSwift.xcscheme
```
> 💡 Ese archivo es XML: dice qué target se compila, qué tests corren y con qué configuración. **Ahora está en Git**, así que tu Mac y el CI usan el mismo.

---

## 💻 Paso 3: El repo en GitHub y tu primer `push`

### 3.1 Crear el repo (web)
**github.com → + → New repository**
- **Name:** `RoadmapSwift` (o `nexo-ios`, como prefieras)
- **Public** ✅ → CI de macOS **gratis e ilimitado** y te sirve de portafolio.
  > ⚠️ En un repo **privado** con plan Free, GitHub **no aplica** las reglas de protección de `main` (Paso 6). Si lo haces privado, el CI corre pero el merge no se bloquea.
- **NO** marques README, .gitignore ni license: tu repo ya existe y tiene historia. Si los marcas, GitHub crea un commit que choca con el tuyo.
- **Create repository**.

### 3.2 Conectar y subir `main`
GitHub te muestra la URL SSH (`git@github.com:tuusuario/RoadmapSwift.git`):
```bash
git remote add origin git@github.com:tuusuario/RoadmapSwift.git
git remote -v                  # origin (fetch) y origin (push)
git push -u origin main
```
- `origin`: el **nombre** del remoto (convención).
- `-u` (*upstream*): enlaza tu `main` con `origin/main`. Desde ahora basta `git push` / `git pull`.

Recarga la página del repo: ahí están tu código y tus 8 días de commits. Revisa en la pestaña **Commits** que la historia esté completa.

> 💡 `ROADMAP.md` y `Dias/Dia-09.md` todavía **no** tienen commit: no se subieron. Se van en la rama del Paso 4.

### 3.3 Una opción útil
**Settings → General → Pull Requests** → marca **Automatically delete head branches**. Así, al hacer merge de un PR, GitHub borra la rama remota sola.

---

## 💻 Paso 4: La rama del CI

```bash
git checkout -b feature/dia-09-ci
```

### 4.1 📁 `scripts/test.sh` (nuevo, en la raíz del repo)
**Regla de oro del CI:** lo que corre en el CI **debe poder correr en tu Mac** con un comando. Si el CI falla, lo reproduces sin adivinar.
```bash
#!/bin/bash
# Corre los tests igual que el CI. Uso: ./scripts/test.sh
set -euo pipefail

cd "$(dirname "$0")/.."

DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

echo "▶️  Tests en: $DESTINATION"
xcodebuild test \
  -project RoadmapSwift.xcodeproj \
  -scheme RoadmapSwift \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  -quiet
echo "✅ Todos los tests pasaron"
```
```bash
chmod +x scripts/test.sh      # permiso de ejecución (sin esto: "permission denied")
./scripts/test.sh             # ~40 s la primera vez
```
| Parte | Para qué |
|---|---|
| `set -e` | Si un comando falla, el script **se detiene** |
| `set -u` | Usar una variable no definida es error (atrapa typos como `$DESTINATON`) |
| `set -o pipefail` | Concepto 4 |
| `cd "$(dirname "$0")/.."` | Funciona sin importar desde qué carpeta lo llames |
| `${DESTINATION:-…}` | Valor por defecto; puedes cambiarlo: `DESTINATION="platform=iOS Simulator,name=iPhone Air,OS=26.5" ./scripts/test.sh` |
| `-quiet` | Solo muestra errores, warnings y el resultado de los tests |

### 4.2 📁 `.github/workflows/ci.yml` (nuevo)
Créalo desde Terminal (las carpetas que empiezan con `.` no se ven en Finder):
```bash
mkdir -p .github/workflows
open -e .github/workflows/ci.yml 2>/dev/null || (touch .github/workflows/ci.yml && open -e .github/workflows/ci.yml)
```
> ⚠️ En **TextEdit**: menú **Formato → Convertir a texto normal** (⇧⌘T) antes de pegar. Mejor aún, ábrelo en Xcode: `xed .github/workflows/ci.yml`.
>
> ⚠️ YAML usa **espacios, nunca tabs**, y la **indentación es sintaxis** (como en Python). Un espacio de más rompe el archivo.

```yaml
name: CI

# Cuándo corre
on:
  pull_request:
    branches: [main]      # cada PR hacia main (y cada push nuevo a ese PR)
  push:
    branches: [main]      # después del merge: confirma que main sigue en verde
  workflow_dispatch:      # botón "Run workflow" para correrlo a mano

# Si subes otro commit al mismo PR, cancela la corrida anterior (ahorra minutos)
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

# Mínimo privilegio: el CI solo necesita LEER el código
permissions:
  contents: read

jobs:
  test:
    name: Tests (iOS)        # ⚠️ este nombre es el "check" que exigirás en el Paso 6
    runs-on: macos-26
    timeout-minutes: 30      # si algo se cuelga, no quema minutos para siempre
    env:
      SCHEME: RoadmapSwift
      DESTINATION: platform=iOS Simulator,name=iPhone 17,OS=26.5

    steps:
      - name: Descargar el código
        uses: actions/checkout@v7

      - name: Seleccionar Xcode 26.6
        run: sudo xcode-select -s /Applications/Xcode_26.6.app

      - name: Mostrar versiones
        run: |
          xcodebuild -version
          xcrun simctl list devices available | grep "iPhone 17"

      - name: Compilar y correr los tests
        run: |
          set -o pipefail
          xcodebuild test \
            -project RoadmapSwift.xcodeproj \
            -scheme "$SCHEME" \
            -destination "$DESTINATION" \
            -resultBundlePath TestResults.xcresult \
            CODE_SIGNING_ALLOWED=NO \
            | xcbeautify --renderer github-actions

      - name: Subir resultados si algo falló
        if: failure()
        uses: actions/upload-artifact@v7
        with:
          name: TestResults
          path: TestResults.xcresult
          retention-days: 7
```
| Pieza | Qué hace |
|---|---|
| `actions/checkout@v7` | Clona tu repo en el runner (sin esto, la Mac está vacía) |
| `xcode-select -s …26.6` | La imagen trae 7 versiones de Xcode; fijamos **la misma que la tuya** |
| `-resultBundlePath` | Guarda un `.xcresult`: el mismo reporte que ves en Xcode (⌘9) |
| `xcbeautify --renderer github-actions` | Hace legible la salida **y** marca los tests fallidos como anotaciones en el PR |
| `if: failure()` | Ese paso solo corre si algo anterior falló |
| `upload-artifact` | Puedes **descargar** el `.xcresult` y abrirlo en tu Xcode para ver el fallo |

> ⚠️ **Diferencias con tu script:** el CI usa `xcbeautify` (ya viene instalado en el runner; en tu Mac no lo tienes y no hace falta) y guarda el `.xcresult`. El comando de `xcodebuild` es el mismo.

### 4.3 📁 `.github/pull_request_template.md` (nuevo)
GitHub lo usa como texto inicial de **cada** PR. Es tu checklist anti-typos:
```markdown
## ¿Qué cambia?
<!-- 1–3 líneas -->

## ¿Cómo lo probé?
- [ ] `./scripts/test.sh` en verde en mi Mac
- [ ] Corrí la app (⌘R) y probé el flujo

## Revisión propia (antes de pedir merge)
- [ ] Leí el diff completo en la pestaña "Files changed"
- [ ] Sin `print` de experimentos ni código comentado
- [ ] Sin typos en nombres, textos y acentos
```

### 4.4 Revisar y subir
```bash
git status
# Nuevos: .github/, scripts/, RoadmapSwift.xcodeproj/xcshareddata/, Dias/Dia-09.md
# Modificado: ROADMAP.md
git add .
git --no-pager diff --staged --stat
git commit -m "ci: GitHub Actions con tests en cada PR, scheme compartido y script local"
git push -u origin feature/dia-09-ci
```
La terminal te muestra un enlace `Create a pull request for 'feature/dia-09-ci'…`.

---

## 💻 Paso 5: Tu primer Pull Request

1. Abre el enlace (o en GitHub verás un aviso amarillo **Compare & pull request**).
2. **base:** `main` ← **compare:** `feature/dia-09-ci`.
3. Título: `CI con GitHub Actions`. La descripción ya trae tu plantilla: llénala.
4. **Create pull request**.
5. Abajo aparece **Tests (iOS)** en amarillo 🟡 (corriendo). Clic en **Details** para ver el log en vivo.
   - La primera corrida tarda unos **4–8 min** (la Mac arranca el simulador desde cero; en tu Mac fueron ~40 s porque ya está caliente).
6. Cuando salga ✅ **All checks have passed**:
   - Pestaña **Files changed**: lee tu diff completo (la plantilla te lo pide).
   - **Merge pull request → Confirm merge**.
7. En tu Mac:
```bash
git checkout main
git pull                          # trae el merge que hizo GitHub
git branch -d feature/dia-09-ci   # la local ya no sirve
git fetch --prune                 # limpia la referencia a la rama remota borrada
```
8. Pestaña **Actions** del repo: verás **dos** corridas: la del PR y la del `push` a `main` (el merge).

> 🆘 **Si el CI falla en el primer intento:** abre el log del step en rojo y busca la primera línea con `error`. Los casos más probables: `Unable to find a destination` (nombre del simulador), `scheme … is not currently configured for the test action` (Paso 2), `Signing requires a development team` (falta `CODE_SIGNING_ALLOWED=NO`). Si no lo resuelves, mándame el log.

---

## 💻 Paso 6: Proteger `main` (Ruleset 🟢)

> ⚠️ Hazlo **después** del Paso 5: GitHub solo te deja elegir el check `Tests (iOS)` si ya corrió al menos una vez.

**Settings → Rules → Rulesets → New ruleset → New branch ruleset**
- **Ruleset name:** `Proteger main`
- **Enforcement status:** `Active`
- **Bypass list:** **vacía** (ni tú te saltas la regla: esa es la idea)
- **Target branches → Add target → Include default branch**
- **Rules**, marca:
  - ✅ **Restrict deletions** (nadie borra `main`)
  - ✅ **Block force pushes** (nadie reescribe la historia de `main`)
  - ✅ **Require a pull request before merging** → *Required approvals:* **0** (trabajas solo; en un equipo serían 1–2)
  - ✅ **Require status checks to pass** → **Add checks** → escribe `Tests (iOS)` y elígelo (fuente: GitHub Actions)
    - ✅ **Require branches to be up to date before merging**
- **Create**.

> 🟤 Lo verás en empresas como *Settings → Branches → Branch protection rules*. Hace lo mismo con menos opciones. Los **Rulesets** son lo nuevo: aplican a varias ramas con un patrón, se pueden poner en modo "Evaluate" para probar, y GitHub guarda el historial de quién los cambió.

---

## ▶️ Paso 7: Experimentos (aquí está el aprendizaje)

### 7.1 🚫 `push` directo a `main`
```bash
git checkout main
git status                                   # debe estar limpio
git commit --allow-empty -m "prueba: push directo"
git push
```
Debe fallar con algo como `GH013: Repository rule violations found… Changes must be made through a pull request`.
Deshaz el commit local (está vacío, no pierdes nada):
```bash
git reset HEAD~1
git status                                   # "up to date with 'origin/main'"
```
✍️ Copia el mensaje de error en tus respuestas.

### 7.2 🔴 Un PR con un test roto
```bash
git checkout -b experiment/ci-rojo
```
En `NexoTests/Features/Feed/FeedViewModelTests.swift`, en `test_load_whileLoading_doesNotRequestAgain`, cambia `XCTAssertEqual(loader.requestCount, 1)` por `2`.
```bash
git commit -am "experimento: test roto a propósito"
git push -u origin experiment/ci-rojo
```
Abre el PR (no hace falta llenar la plantilla). Espera al CI y anota:
1. ¿Qué dice el botón de merge? ¿Puedes hacer clic?
2. En **Files changed**, ¿aparece una anotación roja en la línea del test? (Eso lo hace `--renderer github-actions`.)
3. En el resumen de la corrida (**Summary**), descarga el artefacto **TestResults**, descomprímelo y ábrelo con doble clic: se abre en **Xcode**. ¿Qué ves?

### 7.3 😱 Quitar `pipefail` (en el mismo PR)
En `.github/workflows/ci.yml` **borra** la línea `set -o pipefail`.
```bash
git commit -am "experimento: sin pipefail"
git push
```
Espera el CI. Con el test **todavía roto**: ¿qué color sale? ¿El botón de merge se habilita?
✍️ Esta es la pregunta 3.

### 7.4 Cierra sin merge
En el PR: **Close pull request** (abajo). **No** hagas merge. Luego:
```bash
git checkout main
git branch -D experiment/ci-rojo         # -D porque NO está mergeada (a propósito)
git push origin --delete experiment/ci-rojo
```
> 💡 Aquí sí usas `-D`: sabes **por qué** la rama no está mergeada y la quieres tirar.

---

## 💻 Paso 8: Tu primer PR con código: quitar un warning

Desde el Día 8, cada build muestra:
```
AppRouterTests.swift:59: 'init(frame:)' was deprecated in iOS 26.0: Use init(windowScene:) instead.
```
```bash
git checkout -b chore/tests-window-scene
```
📁 `NexoTests/App/AppRouterTests.swift`, en `makeSUT`:
```swift
    private func makeSUT(loggedInAs email: String? = nil) throws -> (AppRouter, UIWindow, SessionStore) {
        let session = SessionStore(defaults: makeIsolatedDefaults())
        if let email { session.logIn(email: email) }
        // 🟢 iOS 26: una ventana debe pertenecer a una escena. Usamos la escena de la app que hospeda los tests.
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        let sut = AppRouter(window: window, session: session)
        assertNoMemoryLeak(sut)
        return (sut, window, session)
    }
```
Como ahora `makeSUT` es `throws`, en los **4** tests cambia `makeSUT(` por **`try makeSUT(`** (los 4 ya son `throws`, no hay que cambiar nada más).
> 💡 Borra también el comentario viejo *"Una ventana suelta (sin escena)…"*: ya no es cierto. Un comentario desactualizado es peor que ninguno.

```bash
./scripts/test.sh                 # 77 en verde y SIN el warning de deprecated
git add .
git --no-pager diff --staged
git commit -m "chore(tests): UIWindow(windowScene:) en AppRouterTests"
git push -u origin chore/tests-window-scene
```
Abre el PR, llena la plantilla **de verdad**, espera ✅, revisa **Files changed** y haz merge. Luego `git checkout main && git pull` y borra la rama local.

> 💡 Prefijos de rama/commit que ya usas: `feature/` (funcionalidad), `fix/` (bug), `chore/` (mantenimiento sin cambio de comportamiento), `ci:` (pipeline), `docs:` (documentación). Se llama **Conventional Commits**.

---

## ✅ Checklist del día
- [ ] `git config --global user.email` con tu correo `noreply` de GitHub
- [ ] `ssh -T git@github.com` te saluda por tu usuario
- [ ] Scheme **Shared** y `xcshareddata/` en Git
- [ ] `./scripts/test.sh` → 77 en verde en tu Mac
- [ ] Repo **público** con toda la historia
- [ ] PR #1 (CI) con ✅ y mergeado en GitHub
- [ ] Ruleset `Proteger main` activo con el check `Tests (iOS)`
- [ ] 7.1: el `push` directo fue rechazado (copiaste el error)
- [ ] 7.2 y 7.3: anotaste qué pasó con y sin `pipefail`
- [ ] PR de experimento **cerrado sin merge** y ramas borradas
- [ ] PR #3 (`UIWindow(windowScene:)`) mergeado; el warning ya no aparece
- [ ] En tu Mac: `git branch` solo muestra `main`, y `git status` dice *up to date with 'origin/main'*

## 🔥 Reto extra (opcional, +5 puntos)
1. **Badge en un `README.md`** (el repo no tiene): título, una línea de qué es Nexo, cómo correr los tests (`./scripts/test.sh`) y el badge:
   `![CI](https://github.com/tuusuario/RoadmapSwift/actions/workflows/ci.yml/badge.svg)`
   (por PR, claro).
2. **Dependabot para las acciones:** `.github/dependabot.yml` que revise cada semana si hay versiones nuevas de `actions/checkout` y `upload-artifact` y te abra PRs solo (`package-ecosystem: "github-actions"`, `directory: "/"`, `schedule: interval: "weekly"`).
3. **Corrida nocturna:** agrega un evento `schedule:` con `cron` que corra el CI todos los días a las 3 a. m. ¿Para qué serviría si nadie cambió código? (Pista: la imagen del runner cambia sola.)
4. **Matriz:** que el job corra en **iPhone 17** y en **iPad (A16)** con `strategy.matrix`. ¿Cuántos checks aparecen ahora en el PR, y qué tienes que cambiar en el Ruleset?

## 🧠 Preguntas de repaso (respóndelas antes del Día 10)
> 💡 **Cada parte en su propia línea.** Si no sabes, escribe lo que viste en el experimento. **Una respuesta en blanco vale 0.** (Llevas 6 en blanco entre los Días 7 y 8.)

1. ¿Qué diferencia hay entre **CI** y **CD**? ¿Por qué el workflow corre en `pull_request` **y** en `push` a `main`? ¿Qué gana un equipo con que el CI corra en una "máquina limpia" en lugar de confiar en el ⌘U de cada quien?
2. Explica las tres trampas de iOS en CI que resolvimos con: **(a)** el scheme Shared, **(b)** `CODE_SIGNING_ALLOWED=NO`, **(c)** fijar `Xcode_26.6` y `OS=26.5`. ¿Qué error verías en cada caso si no lo hicieras?
3. En el 7.3, ¿de qué color salió el CI sin `pipefail` con el test roto? ¿Por qué? ¿Qué habría pasado en `main` si ese cambio se hubiera mergeado sin que nadie lo notara?
4. ¿Por qué el Ruleset tiene la **Bypass list vacía**, aunque seas el dueño del repo? ¿Qué te pasó el Día 5 que esta regla habría impedido?
5. ¿Qué diferencia hay entre la llave `id_ed25519` y `id_ed25519.pub`? ¿Cuál subiste a GitHub y por qué la otra nunca debe salir de tu Mac?

---
**Próximo (Día 10):** **Coordinator**: sacar la navegación de `AppRouter` y de los ViewControllers a coordinadores (`AuthCoordinator`, `MainCoordinator`), con *child coordinators* y el ciclo de memoria padre ↔ hijo. Desde hoy, **cada día termina con un PR en verde**, no con un `git merge` local.
