# 📅 Día 3: Pantalla de Registro, segues, pasar datos entre pantallas y `PasswordValidator`

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** segues (`show`, `prepare(for:sender:)`, identificadores) 🟤 vs navegación por código 🟢, pasar datos **hacia adelante** (propiedades) y **hacia atrás** (delegate propio, closures, *unwind segues*), `weak` + protocolos `AnyObject`, `CaseIterable`, `filter`/`map`/`joined`, key paths como closures, `String.count` vs UTF-16, el evento **Editing Changed** y un test de humo del storyboard.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Un **`PasswordValidator`** con reglas (mínimo 8 caracteres, una mayúscula y un número).
2. Un **`RegistrationForm`** que valida todo el formulario **sin UI** y reutiliza `EmailValidator`.
3. La pantalla **Crear cuenta** en el Storyboard, abierta desde el Login con un **segue**.
4. El Login le **pasa** el email a Registro, y Registro **avisa** al Login cuando se creó la cuenta.
5. **13 tests nuevos**, para un total de **32**.

Y quitamos el código temporal del feed que pusimos en el Día 2.

---

## 📚 Concepto 1: Cómo se navega entre pantallas (viejo vs nuevo)

| Forma | Cómo se ve | Época |
|---|---|---|
| **Segue desde un botón** | Ctrl-arrastras del botón a la otra pantalla. Cero código. | 🟤 iOS 5+ |
| **Segue manual** | Ctrl-arrastras del *view controller* y llamas `performSegue(withIdentifier:sender:)` cuando quieres (por ejemplo, después de validar). | 🟤 |
| **Por código** | `storyboard.instantiateViewController(identifier:)` + `navigationController?.pushViewController(_:animated:)` | 🟤/🟢 |
| **Por código con `creator:`** | `instantiateViewController(identifier:creator:)`: el storyboard crea la pantalla **usando tu propio `init`** | 🟢 iOS 13+ |
| **Coordinator** | Un objeto aparte decide la navegación; las pantallas no se conocen entre sí | 🟢 patrón (lo haremos en Mid) |
| **SwiftUI** | `NavigationStack` + `navigationDestination` | 🟢 iOS 16+ |

Los tipos de segue que más verás:
- **Show:** dentro de un `UINavigationController` hace *push* (entra por la derecha con botón "atrás"). **Por eso en el Día 1 era importante el Navigation Controller**: sin él, `Show` se comporta como un modal.
- **Present Modally:** la pantalla sube desde abajo (*sheet*).
- **Unwind:** regresa a una pantalla anterior (ver Concepto 2).

---

## 📚 Concepto 2: Pasar datos entre pantallas

### ➡️ Hacia adelante (Login → Registro)
🟤 **Con segues:** el storyboard crea la pantalla destino con `init?(coder:)`, así que **no puedes pedirle datos en un `init` propio**. Por eso se usa una propiedad `var` opcional que se llena en `prepare(for:sender:)`, justo antes de mostrarla:
```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let register = segue.destination as? RegisterViewController {
        register.prefilledEmail = emailTextField.text   // se llena DESPUÉS del init
    }
}
```
Problema: nada te obliga a llenarla. Si se te olvida, la pantalla abre con `nil` y nadie se entera.

🟢 **Con `creator:` (iOS 13+):** la dependencia entra por el `init`, puede ser `let` y **el compilador te obliga** a pasarla:
```swift
let register = storyboard!.instantiateViewController(identifier: "RegisterViewController") { coder in
    RegisterViewController(coder: coder, prefilledEmail: email)
}
navigationController?.pushViewController(register, animated: true)
```
(Esto es el **reto extra 1** de hoy.)

### ⬅️ Hacia atrás (Registro → Login)
| Forma | Cuándo usarla |
|---|---|
| **Delegate** (protocolo + `weak var delegate`) 🟤 | El patrón clásico de UIKit (como `UITextFieldDelegate`). Ideal cuando hay **varios** eventos. **Es la que usamos hoy.** |
| **Closure** (`var onRegister: ((NewAccount) -> Void)?`) 🟢 | Más corto para **un solo** evento. Cuidado: necesitas `[weak self]` (reto extra 2). |
| **Unwind segue** 🟤 | Solo con storyboards. Regresa a una pantalla anterior aunque esté varios niveles atrás (reto extra 3). |
| `NotificationCenter` 🟤 | Para avisar a **muchos** a la vez. Para 1 a 1 es mala idea: nadie sabe quién escucha. |
| Estado compartido observable (`@Observable`) 🟢 | SwiftUI / Mid. |

### 🔐 ¿Por qué el delegate es `weak`?
El Login abre al Registro y el Registro guarda una referencia a su `delegate` (el Login). Si esa referencia fuera `strong` y el Login también guardara al Registro, se retendrían **mutuamente** y ninguno se liberaría (*retain cycle*). Como `weak` solo funciona con clases, el protocolo se declara `: AnyObject`.

---

## 📚 Concepto 3: Colecciones y closures (`CaseIterable`, `filter`, `map`)
```swift
enum PasswordRule: CaseIterable { case minLength, uppercase, number }
PasswordRule.allCases                                  // [.minLength, .uppercase, .number]

PasswordRule.allCases.filter { !$0.isSatisfied(by: "abc") }   // las que FALLAN
rules.map(\.message)                                   // [String]: un key path usado como closure
     .joined(separator: " · ")                         // un solo String
```
🟤 Antes (y en mucho código que heredarás): un `for` con un arreglo `var` que se va llenando. Funciona, pero es más largo y más fácil de equivocarse.

### ⚠️ `String.count` no es lo que crees
```swift
"Ab1👍".count            // 4  ← caracteres que ve el usuario (Swift 🟢)
"Ab1👍".utf16.count      // 5  ← lo que devuelve NSString.length (Obj-C 🟤)
```
Si validas la longitud con `NSString`/`NSRange` (código viejo), un emoji cuenta como 2 y una contraseña de 7 caracteres "pasa" como si tuviera 8. Hoy lo cubrimos con un test.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # solo deben aparecer Dias/Dia-03.md y ROADMAP.md (los agregué yo)
git checkout -b feature/dia-03-register
```
> 💡 Los cambios sin commit **viajan contigo** a la rama nueva al hacer `checkout -b`. Así esta guía y tus respuestas entran en el commit del día (y no vuelve a "desaparecer" como en el Día 2).

---

## 💻 Paso 1: `PasswordValidator`

📁 `Core/Validation/PasswordValidator.swift`

```swift
import Foundation

/// Reglas de contraseña de Nexo.
/// `CaseIterable`: Swift genera `PasswordRule.allCases` con todos los casos, en orden.
nonisolated enum PasswordRule: CaseIterable, Equatable, Sendable {
    case minLength
    case uppercase
    case number

    static let minimumLength = 8

    /// Texto para mostrar al usuario.
    var message: String {
        switch self {
        case .minLength: "Mínimo \(Self.minimumLength) caracteres"
        case .uppercase: "Al menos una mayúscula"
        case .number: "Al menos un número"
        }
    }

    /// Cada regla sabe validarse a sí misma.
    func isSatisfied(by password: String) -> Bool {
        switch self {
        // `count` cuenta CARACTERES que ve el usuario (👍 = 1), no bytes.
        case .minLength: password.count >= Self.minimumLength
        // `\.isUppercase` es un key path usado como closure: igual que `{ $0.isUppercase }`.
        case .uppercase: password.contains(where: \.isUppercase)
        case .number: password.contains(where: \.isNumber)
        }
    }
}

/// Valida contraseñas. Igual que `EmailValidator`: struct, sin estado, `nonisolated`.
nonisolated struct PasswordValidator {
    /// Devuelve las reglas que NO se cumplen. Un arreglo vacío significa contraseña válida.
    func failedRules(for password: String) -> [PasswordRule] {
        PasswordRule.allCases.filter { rule in !rule.isSatisfied(by: password) }
    }
}
```

> ❓ ¿Por qué devuelve `[PasswordRule]` y no `Bool`? Por lo mismo que la pregunta 4 del Día 1: la pantalla necesita saber **qué** falta para mostrarlo. Y agregar una regla nueva (por ejemplo `.symbol`) es solo agregar un `case`: el `switch` exhaustivo te dirá qué más actualizar.

---

## 💻 Paso 2: `RegistrationForm` (la lógica, sin UI)

📁 Crea la carpeta `Features/Auth/Register` y dentro `RegistrationForm.swift`:

```swift
import Foundation

/// Datos ya validados y normalizados, listos para mandarse al servidor (Día ~60).
nonisolated struct NewAccount: Equatable, Sendable {
    let displayName: String
    let email: String
}

/// Errores del formulario de registro.
nonisolated enum RegistrationError: Error, Equatable {
    case emptyName
    /// Envuelve el error de OTRO validador: reutilizamos `EmailValidator` sin duplicar sus reglas.
    case invalidEmail(EmailValidationError)
    /// Lleva la lista de reglas que fallaron.
    case weakPassword([PasswordRule])
    case passwordsDoNotMatch

    var message: String {
        switch self {
        case .emptyName: "El nombre es obligatorio"
        case .invalidEmail(let error): error.message
        case .weakPassword(let rules): "La contraseña necesita: " + rules.map(\.message).joined(separator: " · ")
        case .passwordsDoNotMatch: "Las contraseñas no coinciden"
        }
    }
}

/// Lo que el usuario escribió en el formulario, todavía SIN validar.
/// La lógica vive aquí y no en el view controller: así se prueba sin abrir ninguna pantalla.
nonisolated struct RegistrationForm {
    var displayName = ""
    var email = ""
    var password = ""
    var passwordConfirmation = ""

    /// Valida en orden y devuelve el PRIMER error, que es el que mostrará la pantalla.
    /// Los validadores llegan como parámetros con valor por defecto (inyección de dependencias).
    func validate(
        emailValidator: EmailValidator = EmailValidator(),
        passwordValidator: PasswordValidator = PasswordValidator()
    ) -> Result<NewAccount, RegistrationError> {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .failure(.emptyName) }

        let validEmail: String
        switch emailValidator.validate(email) {
        case .success(let normalized): validEmail = normalized
        case .failure(let error): return .failure(.invalidEmail(error))
        }

        let failedRules = passwordValidator.failedRules(for: password)
        guard failedRules.isEmpty else { return .failure(.weakPassword(failedRules)) }

        guard password == passwordConfirmation else { return .failure(.passwordsDoNotMatch) }

        return .success(NewAccount(displayName: name, email: validEmail))
    }
}
```

> 💡 **Por qué separar esto:** el error típico Junior es meter toda la validación dentro del `IBAction`. Funciona, pero para probarla tendrías que abrir la pantalla, escribir en los campos y tocar el botón. Así, un test de 3 líneas basta. Este es el primer paso hacia MVVM (Mid).
>
> 💡 `validEmail` es un `let` **sin valor inicial**: Swift te deja asignarlo después, siempre que sea **exactamente una vez** en cada camino. Si en algún `case` se te olvida, no compila.

---

## 💻 Paso 3: `RegisterViewController`

📁 `Features/Auth/Register/RegisterViewController.swift`

```swift
import UIKit

/// Delegate PROPIO: la pantalla de Registro avisa "ya se creó la cuenta" sin saber quién la abrió.
/// `AnyObject`: solo las clases pueden adoptarlo, y eso permite que la referencia sea `weak`.
protocol RegisterViewControllerDelegate: AnyObject {
    func registerViewController(_ controller: RegisterViewController, didRegister account: NewAccount)
}

final class RegisterViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!
    @IBOutlet private weak var rulesLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var registerButton: UIButton!

    // MARK: - Entrada (la llena el Login en `prepare(for:sender:)`)
    /// 🟤 Con segues el storyboard crea esta pantalla con `init(coder:)`, así que no podemos
    /// pedir el email en un init propio: por eso es `var` y opcional.
    var prefilledEmail: String?

    /// `weak`: evita un retain cycle. Quien nos abrió (el Login) ya tiene su propia vida.
    weak var delegate: RegisterViewControllerDelegate?

    // MARK: - Dependencias
    private let passwordValidator = PasswordValidator()

    /// Orden de los campos para avanzar con la tecla Return.
    private var orderedFields: [UITextField] {
        [nameTextField, emailTextField, passwordTextField, confirmPasswordTextField]
    }

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Crear cuenta"
        emailTextField.text = prefilledEmail
        errorLabel.isHidden = true
        orderedFields.forEach { $0.delegate = self }
        updateRules(for: "")
    }

    // MARK: - Acciones
    /// Conectada al evento **Editing Changed** del campo de contraseña: se llama en cada tecla.
    @IBAction private func passwordChanged(_ sender: UITextField) {
        updateRules(for: sender.text ?? "")
    }

    @IBAction private func registerButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        let form = RegistrationForm(
            displayName: nameTextField.text ?? "",
            email: emailTextField.text ?? "",
            password: passwordTextField.text ?? "",
            passwordConfirmation: confirmPasswordTextField.text ?? ""
        )

        switch form.validate() {
        case .failure(let error):
            errorLabel.text = error.message
            errorLabel.isHidden = false
        case .success(let account):
            errorLabel.isHidden = true
            // Avisamos y NADA más: cerrar la pantalla le toca a quien la abrió.
            delegate?.registerViewController(self, didRegister: account)
        }
    }

    // MARK: - Helpers
    private func updateRules(for password: String) {
        let failedRules = passwordValidator.failedRules(for: password)
        // map + joined: convierte cada regla en una línea de texto.
        rulesLabel.text = PasswordRule.allCases
            .map { rule in (failedRules.contains(rule) ? "○ " : "✅ ") + rule.message }
            .joined(separator: "\n")
    }
}

// MARK: - UITextFieldDelegate
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let fields = orderedFields
        // `===` (identidad, Día 1): buscamos ESTE campo, no uno "igual".
        if let index = fields.firstIndex(where: { $0 === textField }), index + 1 < fields.count {
            fields[index + 1].becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            registerButtonTapped(registerButton)
        }
        return true
    }
}
```

> 💡 `RegistrationForm(displayName:email:password:passwordConfirmation:)` no lo escribiste: es el *memberwise initializer* gratis del struct (Día 2).

---

## 🎨 Paso 4: La pantalla en el Storyboard

Abre `Main.storyboard`.

### 4.1 La escena
1. **Library** (⇧⌘L) → arrastra un **View Controller** a la derecha del Login.
2. **Identity Inspector** (⌥⌘4):
   - **Class:** `RegisterViewController` (debe autocompletar el módulo `RoadmapSwift`).
   - **Storyboard ID:** `RegisterViewController` (lo usa el test del Paso 7 y el reto 1).

### 4.2 El formulario
3. Arrastra un **Vertical Stack View**. **Spacing: 12**, Alignment: Fill, Distribution: Fill.
4. Constraints del stack (botón **Add New Constraints** ⊢⊣): **Top 24, Leading 24, Trailing 24** respecto al *Safe Area*. Esta vez **no** lo centres verticalmente: con 4 campos, el teclado taparía el botón.
5. Dentro del stack, en este orden:

| # | Elemento | Configuración (Attributes Inspector ⌥⌘5) |
|---|---|---|
| 1 | Text Field "Nombre" | Placeholder `Nombre`, Content Type **Name**, Capitalization **Words**, Return Key **Next**. Height = 48 |
| 2 | Text Field "Correo" | Placeholder `Correo electrónico`, Content Type **Email Address**, Keyboard **E-mail Address**, Capitalization **None**, Correction **No**, Return Key **Next**. Height = 48 |
| 3 | Text Field "Contraseña" | Placeholder `Contraseña`, ✅ **Secure Text Entry**, Content Type **New Password**, Return Key **Next**. Height = 48 |
| 4 | Text Field "Confirmar" | Placeholder `Confirmar contraseña`, ✅ **Secure Text Entry**, Content Type **New Password**, Return Key **Go**. Height = 48 |
| 5 | Label "reglas" | Lines **0**, Font **Footnote**, Color **Secondary Label** |
| 6 | Label "error" | Lines **0**, Font **Footnote**, Color **System Red**, ✅ **Hidden** |
| 7 | Button | Style **Filled**, Title `Crear cuenta`. Height = 48 |

> 💡 Content Type **New Password** (no "Password") le dice a iOS que es un **registro**: con el llavero de iCloud ofrece una contraseña segura. En el simulador puede no aparecer; si aparece el campo amarillo "Contraseña segura", toca **Otras opciones → Elegir mi propia contraseña**.

### 4.3 El segue (🟤 sin código)
6. **⚠️ Primero desconecta la action vieja.** Selecciona en el Login el botón **"¿No tienes cuenta? Crear cuenta"** → **Connections Inspector** (⌥⌘7) → en *Sent Events* verás `Touch Up Inside → createAccountTapped:` → clic en la **×** para quitarla.
7. Con el botón seleccionado, **Ctrl-arrastra** del botón a la escena de Registro → elige **Show**.
8. Clic en la flecha del segue (entre las dos escenas) → **Attributes Inspector** → **Identifier:** `showRegister`.

### 4.4 Conexiones
9. Abre el **Assistant** (⌃⌥⌘↩) con `RegisterViewController.swift`. Como el código ya existe, arrastra desde el **circulito** de cada `@IBOutlet` hasta su elemento.
10. Actions:
    - `registerButtonTapped:` → desde el botón, evento **Primary Action Triggered** (en el Día 1 usaste *Touch Up Inside*; hoy usa el moderno 🟢).
    - `passwordChanged:` → desde el campo **Contraseña**, evento **Editing Changed**. Sin esto, las reglas no se actualizan mientras escribes.
11. Verifica en el Connections Inspector de la escena (selecciona el *View Controller*) que **no haya ningún ⚠️ amarillo**.

---

## 💻 Paso 5: Cambios en `LoginViewController`

### 5.1 Borra el código temporal del Día 2
Borra **todo** el método `createAccountTapped(_:)` (el que imprimía el feed). Ya no hace falta: el segue abre la pantalla solo.

> ⚠️ **Por eso hiciste primero el paso 4.3.6.** Si borras la action del código pero sigue conectada en el storyboard, la app crashea al tocar el botón con `unrecognized selector sent to instance` (lo mismo que vimos con el rename del Día 1).

### 5.2 Pasar el email hacia adelante
Agrega después de las acciones:
```swift
    // MARK: - Navegación (🟤 segues)
    /// Los identificadores en un solo lugar: un typo en un String no lo detecta el compilador.
    private enum SegueID {
        static let showRegister = "showRegister"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard segue.identifier == SegueID.showRegister,
              let register = segue.destination as? RegisterViewController else { return }
        register.prefilledEmail = emailTextField.text
        register.delegate = self   // "avísame a MÍ cuando se cree la cuenta"
    }
```

### 5.3 Mensaje de éxito
En los helpers, agrega `showSuccess` y haz que `showError` **regrese el color a rojo** (si no, después de un mensaje verde, los errores también saldrían verdes):
```swift
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.textColor = .systemRed
        errorLabel.isHidden = false
    }

    private func showSuccess(_ message: String) {
        errorLabel.text = message
        errorLabel.textColor = .systemGreen
        errorLabel.isHidden = false
    }
```

### 5.4 Recibir el aviso (hacia atrás)
Al final del archivo, una extension nueva (como hiciste con `UITextFieldDelegate`):
```swift
// MARK: - RegisterViewControllerDelegate
extension LoginViewController: RegisterViewControllerDelegate {
    func registerViewController(_ controller: RegisterViewController, didRegister account: NewAccount) {
        emailTextField.text = account.email
        passwordTextField.text = nil
        showSuccess("¡Cuenta creada, \(account.displayName)! Ahora inicia sesión.")
        // Quien abre la pantalla es quien la cierra.
        navigationController?.popViewController(animated: true)
    }
}
```

---

## ▶️ Paso 6: Pruébalo en el simulador (⌘R)
1. En el Login escribe `ana@nexo.app` y toca **Crear cuenta** → el email ya aparece en Registro.
2. Escribe en **Contraseña** letra por letra y mira cómo cambian las reglas de `○` a `✅`.
3. Prueba errores: nombre vacío, `ana@`, contraseña `nexonexo`, confirmación distinta.
4. Llena todo bien (`Ana`, `Ana@Nexo.app`, `Nexo2026`, `Nexo2026`) → regresas al Login con el email **en minúsculas** y el mensaje verde.
5. Usa **Return** para avanzar entre campos; en el último debe enviar el formulario.
6. 🧪 **Experimento del ciclo de vida:** pon un breakpoint o un `print` en `viewWillAppear` del Login. ¿Se llama cuando regresas de Registro? ¿Y `viewDidLoad`? (Relaciónalo con la pregunta 5 del Día 1.)

---

## 🧪 Paso 7: Tests

### 7.1 📁 `NexoTests/Core/Validation/PasswordValidatorTests.swift`
```swift
import XCTest
@testable import RoadmapSwift

final class PasswordValidatorTests: XCTestCase {
    private let sut = PasswordValidator()

    func test_failedRules_validPassword_returnsEmpty() {
        XCTAssertEqual(sut.failedRules(for: "Nexo2026"), [])
    }

    func test_failedRules_emptyPassword_returnsAllRules() {
        XCTAssertEqual(sut.failedRules(for: ""), PasswordRule.allCases)
    }

    func test_failedRules_shortPassword_returnsMinLength() {
        XCTAssertEqual(sut.failedRules(for: "Ab1"), [.minLength])
    }

    func test_failedRules_withoutUppercase_returnsUppercase() {
        XCTAssertEqual(sut.failedRules(for: "nexo2026"), [.uppercase])
    }

    func test_failedRules_withoutNumber_returnsNumber() {
        XCTAssertEqual(sut.failedRules(for: "NexoNexo"), [.number])
    }

    /// 7 caracteres visibles, pero 11 unidades UTF-16 (cada 👍 ocupa 2).
    /// Si contáramos como NSString (🟤 `length`), esta contraseña pasaría.
    func test_failedRules_emojis_countAsOneCharacterEach() {
        let password = "Ab1👍👍👍👍"
        XCTAssertEqual(password.count, 7)
        XCTAssertEqual(password.utf16.count, 11)
        XCTAssertEqual(sut.failedRules(for: password), [.minLength])
    }
}
```
> 💡 `sut` = *System Under Test*: el objeto que estás probando. Es una convención muy usada.

### 7.2 📁 `NexoTests/Features/Auth/RegistrationFormTests.swift` (carpetas nuevas `Features/Auth`)
```swift
import XCTest
@testable import RoadmapSwift

final class RegistrationFormTests: XCTestCase {

    func test_validate_validForm_returnsNormalizedAccount() {
        var form = RegistrationForm.valid
        form.displayName = "  Ana  "
        form.email = " Ana@Nexo.APP "
        XCTAssertEqual(form.validate(), .success(NewAccount(displayName: "Ana", email: "ana@nexo.app")))
    }

    func test_validate_blankName_returnsEmptyName() {
        var form = RegistrationForm.valid
        form.displayName = "   "
        XCTAssertEqual(form.validate(), .failure(.emptyName))
    }

    func test_validate_invalidEmail_wrapsEmailError() {
        var form = RegistrationForm.valid
        form.email = "ana@"
        XCTAssertEqual(form.validate(), .failure(.invalidEmail(.invalidFormat)))
    }

    func test_validate_weakPassword_returnsFailedRules() {
        var form = RegistrationForm.valid
        form.password = "nexonexo"
        form.passwordConfirmation = "nexonexo"
        XCTAssertEqual(form.validate(), .failure(.weakPassword([.uppercase, .number])))
    }

    func test_validate_differentConfirmation_returnsPasswordsDoNotMatch() {
        var form = RegistrationForm.valid
        form.passwordConfirmation = "Nexo2027"
        XCTAssertEqual(form.validate(), .failure(.passwordsDoNotMatch))
    }

    func test_validate_severalErrors_returnsFirstOne() {
        let form = RegistrationForm()   // todo vacío
        XCTAssertEqual(form.validate(), .failure(.emptyName))
    }
}

// MARK: - Fixtures
extension RegistrationForm {
    /// Un formulario válido. Cada test lo COPIA (es struct) y cambia solo un campo.
    static let valid = RegistrationForm(
        displayName: "Ana",
        email: "ana@nexo.app",
        password: "Nexo2026",
        passwordConfirmation: "Nexo2026"
    )
}
```
> 💡 Fíjate en `var form = RegistrationForm.valid`: como es **struct**, cada test recibe **su propia copia** y modificarla no afecta a los demás tests. Con una `class` compartida, un test podría romper a otro (Día 2, pregunta 4).
>
> 💡 `XCTAssertEqual` puede comparar dos `Result` porque `NewAccount` y `RegistrationError` son `Equatable`.

### 7.3 📁 `NexoTests/Features/Auth/RegisterViewControllerTests.swift`
```swift
import XCTest
@testable import RoadmapSwift

/// Test de humo del storyboard: si un outlet o una action quedan mal conectados,
/// la app crashea al abrir la pantalla. Este test lo detecta ANTES de correr la app.
@MainActor
final class RegisterViewControllerTests: XCTestCase {

    func test_storyboard_registerScene_loadsWithoutCrashing() throws {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle(for: RegisterViewController.self))
        let sut = try XCTUnwrap(
            storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as? RegisterViewController
        )
        sut.loadViewIfNeeded()   // dispara viewDidLoad: aquí explotaría un outlet roto
        XCTAssertEqual(sut.title, "Crear cuenta")
    }
}
```
> 💡 `@MainActor`: todo lo de UIKit debe correr en el hilo principal. Tu app ya es `MainActor` por defecto, pero el target de tests no, por eso lo marcamos.
>
> 💡 `XCTUnwrap` desenvuelve un opcional o **hace fallar el test** con un mensaje claro. Es mejor que `!`, que crashearía todo el proceso de tests.

---

## ▶️ Paso 8: Correr, probar y hacer commit
1. **⌘U** → deben pasar **32 tests** (19 anteriores + 13 nuevos).
2. **⌘R** → repite el Paso 6.
3. Antes del commit, **revisa tus nombres** (es tu patrón a vigilar):
   ```bash
   git --no-pager diff
   git status
   ```
4. Commit y merge:
   ```bash
   git add .
   git commit -m "feat(auth): pantalla de registro con segue, delegate y PasswordValidator"
   git checkout main
   git merge feature/dia-03-register
   ```

---

## ✅ Checklist del día
- [ ] Al tocar "Crear cuenta" se abre Registro con **push** (botón "atrás" arriba)
- [ ] El email del Login aparece en Registro
- [ ] Las reglas cambian a ✅ mientras escribes la contraseña
- [ ] Cada error del formulario muestra su mensaje
- [ ] Al registrarte regresas al Login con el email en minúsculas y un mensaje verde
- [ ] Ya no existe `createAccountTapped` ni en el código ni en el storyboard
- [ ] 32 tests en verde
- [ ] Revisaste el `git diff` antes del commit

## 🔥 Reto extra (opcional, +5 puntos)
1. **🔁 Migración segue → `creator:` (🟢 iOS 13+).** Cambia `prefilledEmail` a `private let`, agrega a `RegisterViewController`:
   ```swift
   init?(coder: NSCoder, prefilledEmail: String?) {
       self.prefilledEmail = prefilledEmail
       super.init(coder: coder)
   }
   required init?(coder: NSCoder) { fatalError("Usa init(coder:prefilledEmail:)") }
   ```
   Borra el segue del storyboard, vuelve a conectar el botón a una `@IBAction` y abre la pantalla con `storyboard?.instantiateViewController(identifier:creator:)` + `pushViewController`. ¿Qué pasa con `prepare(for:sender:)`? ¿Qué pasa si ahora se te olvida pasar el email? (Ojo: el test del Paso 7.3 usa `instantiateViewController(withIdentifier:)`, que llama a `init(coder:)`… ¿qué le pasará? Arréglalo.)
2. **Closure en vez de delegate.** Reemplaza el delegate por `var onRegister: ((NewAccount) -> Void)?` y en el Login asígnalo con `[weak self]`. Explica en un comentario qué pasaría sin `[weak self]`.
3. **Unwind segue 🟤.** En `LoginViewController` agrega `@IBAction func unwindToLogin(_ segue: UIStoryboardSegue)`, conéctalo arrastrando desde el view controller de Registro al ícono **Exit** de la escena, dale identifier y úsalo con `performSegue(withIdentifier:sender:)` en lugar de `popViewController`.
4. **Nueva regla.** Agrega `case symbol` ("Al menos un símbolo") a `PasswordRule`. ¿Qué tests se rompen y por qué? Arréglalos.

## 🧠 Preguntas de repaso (respóndelas antes del Día 4)
1. ¿Por qué `delegate` es `weak` y el protocolo es `: AnyObject`? ¿Qué pasaría si fuera `strong`?
2. ¿Por qué con segues `prefilledEmail` tiene que ser `var` opcional? ¿Cómo lo resuelve `instantiateViewController(identifier:creator:)`?
3. ¿Qué ganamos al poner la validación en `RegistrationForm` en lugar de dentro de `registerButtonTapped`?
4. ¿Por qué `RegisterViewController` no hace `popViewController` él mismo y se lo deja al Login?
5. ¿Qué pasa si borras una `@IBAction` del código pero sigue conectada en el storyboard? ¿Cuándo te enterarías?

---
**Próximo (Día 4):** el **Feed** con `UITableView` 🟤: `UITableViewDataSource`/`Delegate`, celdas prototipo en el Storyboard, celda personalizada (`UITableViewCell` + outlets), `dequeueReusableCell` y por qué las celdas se **reciclan**, usando los posts de `MockFeedLoader`.
