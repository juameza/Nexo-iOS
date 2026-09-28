# 📅 Día 1: Estructura del proyecto y pantalla de Login (Storyboard)

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** ciclo de vida de la app, `UIViewController`, Storyboard, Auto Layout, `UIStackView`, `IBOutlet`/`IBAction`, patrón Delegate, optionals, `guard`, `Result`, XCTest y Git.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. El proyecto con estructura profesional de carpetas y control de versiones con Git.
2. Una pantalla de **Login hecha en Storyboard**, con Auto Layout.
3. Un validador de email (`EmailValidator`) con su **primer test unitario** en XCTest.

---

## ✅ Ya preparado (lo hice por ti)
- Carpetas creadas y archivos movidos:
```
RoadmapSwift/
├── App/                 AppDelegate.swift, SceneDelegate.swift
├── Core/Validation/     (aquí va EmailValidator)
├── Features/Auth/Login/ ViewController.swift  (hoy lo renombras)
├── Resources/           Assets.xcassets, Base.lproj (Main y LaunchScreen)
└── Info.plist
```
- Tu proyecto usa **carpetas sincronizadas** (Xcode 16+): lo que creas en disco aparece solo en Xcode. 🟢
  En proyectos viejos 🟤 cada archivo se registraba a mano en el `.pbxproj` y los *merge conflicts* eran frecuentes.
- Nombre visible de la app: **Nexo** (`INFOPLIST_KEY_CFBundleDisplayName`).
- `.gitignore` en la raíz.

> Si tenías Xcode abierto, ciérralo y vuelve a abrir `RoadmapSwift.xcodeproj` para que refresque las carpetas.

---

## 📚 Concepto 1: Ciclo de vida de la app (viejo vs nuevo)

| Época | Quién arranca la app | Quién crea la ventana |
|---|---|---|
| 🟤 iOS ≤ 12 | `AppDelegate` | `AppDelegate.window` |
| 🟡 iOS 13+ (tu proyecto) | `AppDelegate` | **`SceneDelegate`**: una escena por ventana (multiventana en iPad) |
| 🟢 SwiftUI | `@main struct NexoApp: App` | `WindowGroup { ... }` |

Abre tus archivos y fíjate:
- `AppDelegate.swift` → `didFinishLaunchingWithOptions`: **la app** arrancó (una vez). Aquí se configuran cosas globales: analytics, push, etc.
- `SceneDelegate.swift` → `scene(_:willConnectTo:)`: **una ventana** se creó. Como usas Storyboard, iOS lee `UISceneStoryboardFile = Main` del `Info.plist` y crea la ventana solo.
- `sceneDidEnterBackground`, `sceneWillEnterForeground`: eventos por ventana.

> 📌 Apple anunció que, después de iOS 26, las apps **deberán** usar el ciclo de vida con escenas (`UIScene`). Las apps que solo usan `AppDelegate` son legacy y hay que migrarlas. Es un buen ejemplo de por qué un Staff+ tiene que conocer ambos modelos.

**Mini ejercicio:** agrega un `print("🟣 sceneWillEnterForeground")` en `sceneWillEnterForeground` y un `print("🟠 sceneDidEnterBackground")` en `sceneDidEnterBackground`. Luego, en el simulador, ve al Home (⇧⌘H) y regresa a la app. Mira la consola.

---

## 📚 Concepto 2: Ciclo de vida de un `UIViewController`

```
init → loadView → viewDidLoad (1 vez) → viewWillAppear → viewIsAppearing 🟢(iOS 17) → viewDidAppear
                                         ↑                                                   ↓
                                   viewDidDisappear  ←────────────────────────────  viewWillDisappear
```
- `viewDidLoad`: configurar la vista **una vez**. Los outlets ya están conectados.
- `viewWillAppear`: cada vez que la pantalla va a mostrarse (por ejemplo, para refrescar datos).
- `viewIsAppearing` 🟢: aquí ya son correctos el tamaño y los *traits* de la vista. Es el mejor lugar para ajustes de layout.

---

## 💻 Paso 0: Git (5 min)
En la Terminal:
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git init
git add .
git commit -m "chore: estructura inicial del proyecto Nexo"
git checkout -b feature/dia-01-login
```
> Trabajar en ramas (`feature/...`) y luego hacer merge o un PR es la práctica estándar en equipos.

---

## 💻 Paso 1: Renombrar `ViewController` → `LoginViewController`
1. Abre `Features/Auth/Login/ViewController.swift`.
2. Clic derecho sobre el nombre `ViewController` en `class ViewController` → **Refactor → Rename…** → `LoginViewController`.
3. Xcode renombra la clase, el archivo **y** la referencia en el Storyboard.
4. **Verifica:** abre `Main.storyboard`, selecciona el View Controller → *Identity Inspector* (⌥⌘4) → **Class = `LoginViewController`**.
   Si no cambió, escríbelo a mano. Si queda mal, la app **crashea** con `Unknown class ViewController in Interface Builder file`: un error clásico de Storyboard 🟤.

---

## 💻 Paso 2: Diseñar el Login en `Main.storyboard`

### 2.1 Embed en Navigation Controller
Selecciona el View Controller → menú **Editor → Embed In → Navigation Controller**.
(Ahora el *Initial View Controller* es el Navigation Controller: la flecha apunta a él.)

### 2.2 Componentes (usa la Library con ⇧⌘L)
Arrastra, **en este orden**, dentro de un **Vertical Stack View**:

| # | Componente | Propiedades (Attributes Inspector ⌥⌘5) |
|---|---|---|
| 1 | `UILabel` "Nexo" | Font: **System Bold 40**, Alignment: Center |
| 2 | `UILabel` "Conecta con tu gente" | Font: Subheadline, Color: Secondary Label, Center |
| 3 | `UITextField` email | Placeholder: `Correo electrónico` · Border: Rounded · Content Type: **Email Address** · Keyboard: **Email Address** · Capitalization: **None** · Correction: **No** · Return Key: **Next** |
| 4 | `UITextField` password | Placeholder: `Contraseña` · Border: Rounded · Content Type: **Password** · ✅ **Secure Text Entry** · Return Key: **Go** |
| 5 | `UILabel` error | Text: `Error`, Color: **System Red**, Font: Footnote, Lines: **0**, ✅ **Hidden** |
| 6 | `UIButton` "Iniciar sesión" | Style: **Filled** · Title: `Iniciar sesión` · Size: Large |
| 7 | `UIButton` "Crear cuenta" | Style: **Plain** · Title: `¿No tienes cuenta? Crear cuenta` |

**Tip:** arrastra primero el *Vertical Stack View* y después suelta los componentes **dentro** de él.

**Stack View** → Axis: Vertical · Alignment: **Fill** · Distribution: **Fill** · Spacing: **16**.

> 🟤 vs 🟢 **Botones:** los *Styles* "Filled/Plain/Tinted/Gray" usan `UIButton.Configuration` (iOS 15+) 🟢. El estilo "Default" 🟤 se configura con `setTitle(_:for:)` y `setTitleColor(_:for:)`. En código legacy verás mucho del segundo.

### 2.3 Auto Layout (constraints del Stack View)
Selecciona el Stack View → botón **Add New Constraints** (el ícono ⊢⊣ abajo a la derecha):
- Leading: **24** · Trailing: **24** (respecto a Safe Area)
- Luego **Align** (el ícono al lado) → ✅ **Vertically in Container** = 0

Para los text fields y el botón principal: selecciona cada uno → Add New Constraints → ✅ **Height = 48**.

> ⚠️ Si ves líneas **rojas o naranjas**, hay constraints ambiguas o en conflicto. Abre el *Document Outline* (el ícono de la barra lateral) y toca la flecha roja para ver qué falta.

> 💡 Si quieres más espacio solo entre el subtítulo y los campos, eso se hace con `stackView.setCustomSpacing(32, after: subtitleLabel)` en código. Lo veremos cuando hagamos layout por código (nivel Mid).

---

## 💻 Paso 3: Crear el `EmailValidator` (lógica pura, sin UI)

📁 Crea el archivo: clic derecho en `Core/Validation` → **New File from Template… → Swift File** → `EmailValidator.swift`

```swift
import Foundation

/// Errores posibles al validar un email.
/// `Equatable` nos permite compararlos en los tests con `XCTAssertEqual`.
nonisolated enum EmailValidationError: Error, Equatable {
    case empty
    case invalidFormat

    /// Mensaje listo para mostrar al usuario.
    /// 🟢 Swift 5.9+: `switch` como expresión (sin `return` en cada case).
    var message: String {
        switch self {
        case .empty: "El correo es obligatorio"
        case .invalidFormat: "El formato del correo no es válido"
        }
    }
}

/// Valida emails. Es un `struct` (tipo valor): no tiene estado compartido,
/// así que es fácil de testear y seguro de usar desde cualquier hilo.
nonisolated struct EmailValidator {

    /// Devuelve el email normalizado (sin espacios, en minúsculas) o un error.
    func validate(_ email: String) -> Result<String, EmailValidationError> {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }

        // 🟢 Swift Regex (iOS 16+): la expresión se valida al COMPILAR.
        let pattern = #/[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}/#

        guard trimmed.wholeMatch(of: pattern) != nil else {
            return .failure(.invalidFormat)
        }

        return .success(trimmed.lowercased())
    }
}
```

### 🟤 vs 🟢: la misma validación "a la antigua"
Esto lo vas a encontrar en código legacy (**no lo escribas en el proyecto**, solo léelo):
```swift
// 🟤 NSPredicate + regex en String: si el patrón está mal, falla en RUNTIME.
let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
let isValid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
```

### ❓ ¿Qué es ese `nonisolated`?
Tu proyecto (Xcode 26) tiene activado **Default Actor Isolation = MainActor** 🟢 (Swift 6.2). Eso quiere decir que *todo* tu código corre en el hilo principal, salvo que digas lo contrario.
Un validador no toca la UI, así que lo marcamos `nonisolated` para usarlo desde cualquier contexto, incluidos los tests. Esto lo veremos a fondo en el nivel Senior (concurrencia). Por ahora: **lógica pura → `nonisolated`**.

---

## 💻 Paso 4: Escribir `LoginViewController`

Reemplaza **todo** el contenido de `LoginViewController.swift`:

```swift
import UIKit

final class LoginViewController: UIViewController {

    // MARK: - Outlets
    // `weak` porque la vista ya los retiene; `!` porque existen después de viewDidLoad.
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var loginButton: UIButton!

    // MARK: - Dependencias
    private let emailValidator = EmailValidator()

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🟢 viewDidLoad")
        configureUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🔵 viewWillAppear")
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        print("🟡 viewIsAppearing")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🟣 viewDidAppear")
    }

    // MARK: - Configuración
    private func configureUI() {
        title = "Iniciar sesión"
        navigationController?.navigationBar.prefersLargeTitles = false
        hideError()

        // Patrón DELEGATE: el text field le "delega" a este VC decidir qué pasa al presionar Return.
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }

    // MARK: - Acciones (patrón TARGET-ACTION)
    @IBAction private func loginButtonTapped(_ sender: UIButton) {
        view.endEditing(true)   // oculta el teclado

        // `text` es String? (Optional). `guard let` lo desenvuelve o sale.
        guard let email = emailTextField.text,
              let password = passwordTextField.text else { return }

        switch emailValidator.validate(email) {
        case .failure(let error):
            showError(error.message)

        case .success(let validEmail):
            guard !password.isEmpty else {
                showError("La contraseña es obligatoria")
                return
            }
            hideError()
            print("✅ Login válido con: \(validEmail)")
            // Día 5: navegar al Feed
        }
    }

    @IBAction private func createAccountTapped(_ sender: UIButton) {
        print("➡️ Crear cuenta (lo haremos en el Día 3)")
    }

    // MARK: - Helpers
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    private func hideError() {
        errorLabel.text = nil
        errorLabel.isHidden = true
    }
}

// MARK: - UITextFieldDelegate
// Separar cada conformance en su propia extension es una convención muy usada.
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailTextField {          // === compara IDENTIDAD (misma instancia)
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginButtonTapped(loginButton)
        }
        return true
    }
}
```

---

## 💻 Paso 5: Conectar Outlets y Actions
1. Abre `Main.storyboard` y activa el **Assistant Editor** (⌃⌥⌘↩). A la derecha debe aparecer `LoginViewController.swift`.
2. Junto a cada `@IBOutlet` hay un **círculo vacío** ○. Arrástralo al componente correcto del Storyboard:
   - `emailTextField` → text field de correo
   - `passwordTextField` → text field de contraseña
   - `errorLabel` → label rojo
   - `loginButton` → botón "Iniciar sesión"
3. Haz lo mismo con los `@IBAction`:
   - `loginButtonTapped` → botón "Iniciar sesión" (evento **Primary Action Triggered**)
   - `createAccountTapped` → botón "Crear cuenta"
4. Cuando están conectados, los círculos quedan **rellenos** ●.
5. **Verifica:** selecciona el View Controller → *Connections Inspector* (⌥⌘7). No debe haber conexiones con ⚠️.

> 💥 **Crash clásico 🟤:** `this class is not key value coding-compliant for the key xyz`. Pasa cuando renombras un outlet en código pero el Storyboard sigue apuntando al nombre viejo. Solución: bórralo en el Connections Inspector y vuelve a conectarlo.

---

## 🧪 Paso 6: Crear el target de tests y el primer test

### 6.1 Crear el target
**File → New → Target… → iOS → Unit Testing Bundle**
- Product Name: **`NexoTests`**
- Testing System: **XCTest** 🟤 (en el Día ~40 usaremos **Swift Testing** 🟢 y compararemos)
- Target to be Tested: **RoadmapSwift**

Borra el archivo de ejemplo que genera Xcode y crea `NexoTests/Core/Validation/EmailValidatorTests.swift`:

```swift
import XCTest
@testable import RoadmapSwift   // @testable permite acceder a lo `internal` de la app

final class EmailValidatorTests: XCTestCase {

    // SUT = "System Under Test" (convención de nombre para lo que se prueba)
    private let sut = EmailValidator()

    // Convención de nombre: test_<método>_<escenario>_<resultadoEsperado>

    func test_validate_emptyString_returnsEmptyError() {
        XCTAssertEqual(sut.validate(""), .failure(.empty))
    }

    func test_validate_onlyWhitespaces_returnsEmptyError() {
        XCTAssertEqual(sut.validate("   \n "), .failure(.empty))
    }

    func test_validate_withoutAt_returnsInvalidFormat() {
        XCTAssertEqual(sut.validate("mario.nexo.com"), .failure(.invalidFormat))
    }

    func test_validate_withoutDomain_returnsInvalidFormat() {
        XCTAssertEqual(sut.validate("mario@"), .failure(.invalidFormat))
    }

    func test_validate_withoutTLD_returnsInvalidFormat() {
        XCTAssertEqual(sut.validate("mario@nexo"), .failure(.invalidFormat))
    }

    func test_validate_validEmail_returnsSuccess() {
        XCTAssertEqual(sut.validate("mario@nexo.com"), .success("mario@nexo.com"))
    }

    func test_validate_emailWithSpacesAndUppercase_returnsNormalizedEmail() {
        XCTAssertEqual(sut.validate("  Mario@Nexo.COM  "), .success("mario@nexo.com"))
    }
}
```

> Estructura de cada test (**AAA**): **Arrange** (preparar el `sut`), **Act** (llamar a `validate`), **Assert** (`XCTAssertEqual`). Aquí son de una sola línea, pero ese es el patrón.

---

## ▶️ Paso 7: Correr, probar y hacer commit
1. **⌘R**: corre la app en el simulador (iPhone 17 o el que tengas).
   - Mira en la consola el orden de los `print` del ciclo de vida.
   - Prueba: sin email → error; `mario` → error de formato; email válido sin contraseña → error; todo válido → `✅` en la consola.
   - En el campo de email presiona Return: debe pasar a la contraseña.
2. **⌘U**: corre los tests. Los 7 deben quedar en ✅ verde (Test Navigator ⌘6).
3. Commit:
```bash
git add .
git commit -m "feat(auth): pantalla de login en storyboard con validación de email"
git checkout main
git merge feature/dia-01-login
```

---

## ✅ Checklist del día
- [ ] Repo con Git y rama `feature/dia-01-login`
- [ ] `LoginViewController` conectado al Storyboard (sin crash)
- [ ] Login con Auto Layout: se ve bien en iPhone SE y en iPhone Pro Max (cámbialo en la barra de Xcode y vuelve a correr)
- [ ] Rotaste el simulador (⌘←) y el layout no se rompe
- [ ] 7 tests en verde
- [ ] Entiendes la diferencia entre `AppDelegate` y `SceneDelegate`

## 🔥 Reto extra (opcional)
1. Crea un `PasswordValidator` en `Core/Validation` con estas reglas: mínimo 8 caracteres, al menos 1 número y al menos 1 mayúscula. Usa un `enum PasswordValidationError` con **3 casos** y escribe sus tests. Pista: `password.contains(where: \.isNumber)`.
2. Pon un **breakpoint** en `loginButtonTapped`, presiona el botón y en la consola LLDB escribe `po email` y `v password`. ¿Qué diferencia ves entre `po` y `v`?

## 🧠 Preguntas de repaso (respóndelas antes del Día 2)
1. ¿Por qué los `IBOutlet` son `weak`? ¿Qué pasaría si fueran `strong`? - Por que la vista ya los retiene, existen despues del viewDidload
2. ¿Qué diferencia hay entre `==` y `===`? Ambos comparar, pero es mas preciso los diferentes tipos de datos ===
3. ¿Por qué `EmailValidator` es `struct` y no `class`? Ya que no usa referencia, y se puede usar fuera del hilo
4. ¿Qué ventaja tiene devolver `Result<String, EmailValidationError>` en vez de `Bool`?, Saber exactamente, el correo validado, y que tipo de error te regresa si en dado caso existe
5. ¿En qué método del ciclo de vida harías una petición de red para refrescar datos cada vez que se muestra la pantalla? - viewWillAppear de la vista

---
**Próximo (Día 2):** fundamentos de Swift aplicados a Nexo: modelos `User` y `Post` (struct vs class, enums con valores asociados, `Codable`) y un JSON mock del Feed.
