# 📅 Día 5: Pantalla raíz, `UITabBarController`, sesión con `UserDefaults` y tu primera pantalla en SwiftUI

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** cambiar el `rootViewController` desde el `SceneDelegate` (ventana creada por código 🟢 vs storyboard en el Info.plist 🟤), un **router** que decide la pantalla raíz (el antecesor del patrón Coordinator), `UITabBarController` por código, **`UserDefaults`** 🟤 vs **`@AppStorage`** 🟢, **SwiftUI**: `View`, `@State`, `@Binding`, `Form`, `NavigationStack` 🟢 vs `NavigationView` 🟤, `#Preview`, y **`UIHostingController`** para meter SwiftUI dentro de UIKit. Más ARC: **quién es dueño de quién**.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Después de iniciar sesión, la app muestra **dos tabs**: **Inicio** (el Feed, UIKit + Storyboard) y **Cuenta** (SwiftUI). Ya **no** hay botón "atrás" hacia el Login.
2. Si cierras la app y la vuelves a abrir, **sigues con la sesión iniciada** (va directo a los tabs).
3. La pantalla **Cuenta** en SwiftUI: tu correo, un switch de preferencias que **se guarda solo**, la versión de la app y **Cerrar sesión** con confirmación.
4. Al cerrar sesión regresas al Login y en la consola ves `♻️ FeedViewController liberado`.
5. **10 tests nuevos**, para un total de **50**. Dos de ellos **fallan si falta un `[weak self]`**.

---

## 📚 Concepto 1: La pantalla raíz (`rootViewController`)

Hoy tu app es una sola pila de navegación:
```
UIWindow
 └─ UINavigationController
     ├─ LoginViewController
     └─ FeedViewController      ← push: tiene botón "atrás" hacia el Login ❌
```
En una app real, después de iniciar sesión **se cambia la raíz de la ventana**. El Login desaparece de memoria y no hay forma de "regresar" a él:
```
UIWindow                                   UIWindow
 └─ UINavigationController (Login)   ──▶    └─ UITabBarController
                                                 ├─ UINavigationController ─ FeedViewController   (tab "Inicio")
                                                 └─ UIHostingController ─ AccountView (SwiftUI)  (tab "Cuenta")
```

### 🟤 Viejo vs 🟢 nuevo: ¿quién crea la ventana?
| | 🟤 Viejo | 🟢 Hoy |
|---|---|---|
| Dueño de la ventana | `AppDelegate.window` (antes de iOS 13) | `SceneDelegate.window` (iOS 13+, una ventana **por escena**; en iPad puede haber varias) |
| Quién la crea | El sistema, leyendo `UISceneStoryboardFile = Main` del Info.plist | **Tú, por código**, en `scene(_:willConnectTo:options:)` |
| Cambiar la raíz desde cualquier lado | `UIApplication.shared.keyWindow?.rootViewController = …` (**deprecado** desde iOS 13) | Un objeto (el **router**) que es dueño de la ventana y es el único que cambia la raíz |
| SwiftUI puro | – | `@main struct NexoApp: App` con `WindowGroup` (lo veremos al migrar, nivel Staff) |

> 💡 El `Main.storyboard` **no se borra**: el Login y el Registro siguen viviendo ahí. Lo único que cambia es **quién lo carga**: antes el sistema, ahora tu código.

---

## 📚 Concepto 2: El router (y por qué el Login ya no conoce al Feed)

Ayer el Login hacía `push` del Feed. Eso significa que el Login **sabe** que existe un Feed, un `MockFeedLoader` y un `Feed.storyboard`. Si mañana después del login hay que mostrar un onboarding, hay que tocar el Login.

Hoy aplicamos lo mismo que en la **pregunta 4 del Día 3** (*"quien abre la pantalla es quien la cierra"*): el Login solo **avisa** "alguien inició sesión con este correo", con una closure:
```swift
var onLogin: ((String) -> Void)?
```
Y un objeto nuevo, **`AppRouter`**, decide qué pasa después. Es el antecesor del **patrón Coordinator** (nivel Mid): un objeto que se encarga de la navegación para que los view controllers no se conozcan entre sí.

> ⚠️ `onLogin` tiene que ser `var` opcional por lo mismo que `prefilledEmail` en el Día 3: el storyboard crea el Login con `init?(coder:)`, así que el valor solo se puede asignar **después**.

### 🧠 ARC: ¿quién es dueño de quién?
```
SceneDelegate ──strong──▶ AppRouter ──strong──▶ UIWindow ──strong──▶ rootViewController
                                ▲                                            │
                                └──────── weak (closure onLogin / onLogout) ─┘
```
- El **SceneDelegate** es el dueño del router (`private var router`). Si el router fuera una variable **local** dentro de `scene(_:willConnectTo:)`, ARC lo liberaría al terminar el método y las closures con `[weak self]` encontrarían `nil`: el botón de login **no haría nada**. (Lo comprobarás en el experimento 7.4.)
- El router guarda la ventana, la ventana guarda la pantalla, la pantalla guarda la closure… y si la closure guardara al router con `strong`, se cierra el círculo. Por eso `[weak self]` otra vez.

---

## 📚 Concepto 3: Guardar datos pequeños — `UserDefaults` 🟤 vs `@AppStorage` 🟢

`UserDefaults` es un diccionario que **se guarda en disco** y sobrevive a cerrar la app.

| | 🟤 `UserDefaults` directo | 🟢 `@AppStorage` (SwiftUI) |
|---|---|---|
| Leer | `defaults.string(forKey: "k")` | `@AppStorage("k") var valor = "x"` y lo usas como variable |
| Escribir | `defaults.set(valor, forKey: "k")` | `valor = "y"` |
| ¿Redibuja la vista al cambiar? | No, lo haces tú | **Sí**, automáticamente |
| Dónde se usa | Cualquier lado (UIKit, lógica, tests) | Solo dentro de vistas SwiftUI |

Hoy usas **los dos**: `SessionStore` (UserDefaults, testeable) para la sesión y `@AppStorage` para el switch de preferencias de la pantalla Cuenta.

> 🔐 **Regla de seguridad:** `UserDefaults` es un archivo `.plist` **sin cifrar**. Ahí van preferencias y datos no sensibles (como el correo con el que entraste). **Contraseñas y tokens van al Keychain** (nivel Mid, cuando NexoServer te devuelva un token JWT). Por eso hoy **no** guardamos la contraseña.

### Claves como constantes
`"settings.autoplayVideos"` es otro String que el compilador no revisa (como `"howRegister"` del Día 3). Si lo escribes distinto en dos lugares, cada uno lee una clave diferente y nadie se entera. Por eso cada clave vive **en un solo lugar** (`AppSettingsKey`, `SessionStore.Key`).

---

## 📚 Concepto 4: SwiftUI en 5 minutos

UIKit es **imperativo**: tú le dices *cómo* cambiar la pantalla (`label.text = …`, `button.isHidden = true`).
SwiftUI es **declarativo**: describes *cómo se ve la pantalla para un estado dado*, y cuando el estado cambia, SwiftUI vuelve a calcular `body` y actualiza solo lo necesario.

```swift
struct Contador: View {                 // una vista es un STRUCT (barato de crear)
    @State private var cuenta = 0       // @State: estado PRIVADO de la vista; SwiftUI lo guarda por ti

    var body: some View {               // `some View`: "devuelvo UNA vista concreta, no te digo cuál"
        Button("Tocado \(cuenta) veces") {
            cuenta += 1                 // cambia el estado → SwiftUI redibuja → el texto se actualiza solo
        }
    }
}
```

| Property wrapper | ¿Quién es dueño del valor? | Ejemplo de hoy |
|---|---|---|
| `@State` | **La vista** (privado) | `isConfirmingLogout` |
| `@Binding` | **Otro** (la vista lo lee y lo escribe, pero no es suyo) | `SettingToggleRow(isOn: $autoplayVideos)` |
| `@AppStorage` | **UserDefaults** | `autoplayVideos` |

El `$` delante (`$autoplayVideos`) crea un **`Binding`**: una "referencia" de lectura y escritura al valor, para pasársela a otra vista (un `Toggle`, o tu propia `SettingToggleRow`).

### 🟤 Viejo vs 🟢 nuevo en SwiftUI (lo de hoy)
| | 🟤 Viejo | 🟢 Nuevo |
|---|---|---|
| Navegación | `NavigationView` (deprecado en iOS 16) | `NavigationStack` / `NavigationSplitView` |
| Vista previa | `struct X_Previews: PreviewProvider { static var previews: some View { … } }` | `#Preview { … }` (macro, Xcode 15+) |
| Fila etiqueta-valor | `HStack { Text("Correo"); Spacer(); Text(email) }` | `LabeledContent("Correo", value: email)` (iOS 16+) |
| Alertas con opciones | `.actionSheet(isPresented:)` | `.confirmationDialog(_:isPresented:)` (iOS 15+) |

### `UIHostingController`: SwiftUI dentro de UIKit
```swift
let hosting = UIHostingController(rootView: AccountView(...))   // ← es un UIViewController normal
```
Lo puedes meter en un tab, hacerle `push`, presentarlo como modal… UIKit no nota la diferencia. **Así migran las apps grandes a SwiftUI: pantalla por pantalla.** (Al revés, UIKit dentro de SwiftUI, es `UIViewControllerRepresentable`: nivel Mid.)

---

## 📚 Concepto 5: `UITabBarController`
| | 🟤 Viejo | 🟢 Nuevo |
|---|---|---|
| Crear tabs | Arrastrar un **Tab Bar Controller** en el storyboard y conectar *relationship segues* | Por código: `tabBar.viewControllers = [...]` (**hoy**) |
| Cada tab | `UITabBarItem(title:image:selectedImage:)` (**hoy**) | iOS 18+: `UITab(title:image:identifier:)` y `tabBar.tabs = [...]`, con sidebar en iPad (reto extra) |

Regla importante: **cada tab tiene su propio `UINavigationController`**. Si en el futuro haces push del detalle de un post en "Inicio", "Cuenta" no se entera, y al regresar a "Inicio" sigues donde te quedaste.

---

## 💻 Paso 0: Rama nueva y pendientes del Día 4
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # solo deben aparecer Dias/Dia-05.md y ROADMAP.md (los agregué yo)
git checkout -b feature/dia-05-tabs-swiftui
```

### 0.1 Pendientes del Día 4 (no entraron en tu commit de correcciones)
1. **`PostCell.swift`, `configure(with:)`:**
   - `" *"` → `" ✓"` (verificado)
   - `" . "` → `" · "` (punto medio, **⌥ + Shift + 9** en teclado inglés, o cópialo de aquí)
2. **Typos en comentarios:**
   - `FeedViewController.swift`: `"Usam init(coder:loader:)"` → `"Usa init(coder:loader:)"` y `// Mid: abrir el detall del post` → `detalle`.
   - El de `LoginViewController` (`Initiañ ViewContoller`) desaparece hoy solo, porque borras `showFeed()` en el Paso 5.

---

## 💻 Paso 1: `SessionStore` (UserDefaults 🟤)

📁 Crea la carpeta `Core/Session` y dentro `SessionStore.swift`:
```swift
import Foundation

/// Guarda QUIÉN inició sesión, para que al reabrir la app no se pida login otra vez.
/// 🟤 UserDefaults: solo datos pequeños y NO sensibles. El token JWT irá al Keychain (nivel Mid).
struct SessionStore {
    /// Las claves en UN solo lugar: un typo en un String no lo detecta el compilador.
    private enum Key {
        static let currentEmail = "session.currentEmail"
    }

    /// Inyectado por `init`: la app usa `.standard` y los tests un UserDefaults aislado.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var currentEmail: String? {
        defaults.string(forKey: Key.currentEmail)
    }

    var isLoggedIn: Bool {
        currentEmail != nil
    }

    /// No es `mutating` aunque "cambia algo": lo que cambia es el UserDefaults (una CLASE,
    /// o sea una referencia), no las propiedades de este struct.
    func logIn(email: String) {
        defaults.set(email, forKey: Key.currentEmail)
    }

    func logOut() {
        defaults.removeObject(forKey: Key.currentEmail)
    }
}
```

---

## 💻 Paso 2: Claves de preferencias y versión de la app

📁 `Core/Settings/AppSettingsKey.swift` (carpeta nueva)
```swift
import Foundation

/// Claves de UserDefaults para las preferencias del usuario (las usa `@AppStorage`).
enum AppSettingsKey {
    static let autoplayVideos = "settings.autoplayVideos"
}
```

📁 `App/AppInfo.swift`
```swift
import Foundation

/// Versión y build de la app, para la sección "Acerca de".
struct AppInfo: Equatable {
    let version: String
    let build: String

    var versionText: String {
        "\(version) (\(build))"
    }
}

// El init extra va en una EXTENSIÓN a propósito: si lo pusieras dentro del struct,
// Swift dejaría de generar el init "memberwise" AppInfo(version:build:) que usan el #Preview y los tests.
extension AppInfo {
    /// Recibe el diccionario en lugar de leer `Bundle.main` adentro → se puede probar con datos falsos.
    init(infoDictionary: [String: Any]?) {
        self.init(
            version: infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            build: infoDictionary?["CFBundleVersion"] as? String ?? "?"
        )
    }

    /// La de la app real: Version y Build de la pestaña General del target.
    static var current: AppInfo {
        AppInfo(infoDictionary: Bundle.main.infoDictionary)
    }
}
```
> 💡 `as? String ?? "?"`: el diccionario es `[String: Any]`, así que primero se intenta convertir a `String` (`as?` devuelve opcional) y, si no se puede o la clave no existe, se usa `"?"`.

---

## 🎨 Paso 3: La pantalla **Cuenta** en SwiftUI

📁 Crea la carpeta `Features/Account` y dentro un archivo **SwiftUI View** (New File from Template → **SwiftUI View**) llamado `AccountView.swift`. Reemplaza su contenido por:
```swift
import SwiftUI

/// 🟢 Tu primera pantalla en SwiftUI. Vive dentro de UIKit gracias a UIHostingController (Paso 4).
struct AccountView: View {
    // Datos que recibe de afuera (como los parámetros de un init).
    let email: String
    let appInfo: AppInfo
    /// La vista NO sabe cerrar sesión: solo avisa (igual que `onLikeTapped` de la celda).
    let onLogout: () -> Void

    /// 🟢 @AppStorage: lee y escribe UserDefaults, y REDIBUJA la vista cuando cambia.
    /// `= true` es el valor por defecto mientras el usuario no lo haya cambiado.
    @AppStorage(AppSettingsKey.autoplayVideos) private var autoplayVideos = true

    /// @State: estado privado de la vista. ¿Se está mostrando la confirmación?
    @State private var isConfirmingLogout = false

    var body: some View {
        // 🟢 NavigationStack (iOS 16+). 🟤 Antes: NavigationView (deprecado).
        NavigationStack {
            Form {
                Section("Sesión") {
                    LabeledContent("Correo", value: email)
                }

                Section("Preferencias") {
                    // `$autoplayVideos` es un Binding: la fila puede LEER y ESCRIBIR el valor del padre.
                    SettingToggleRow(
                        title: "Reproducir videos automáticamente",
                        systemImage: "play.circle",
                        isOn: $autoplayVideos
                    )
                }

                Section("Acerca de") {
                    LabeledContent("Versión", value: appInfo.versionText)
                    // `if let` en lugar de `!`: aunque sabemos que la URL es válida, no forzamos.
                    if let website = URL(string: "https://nexo.app") {
                        Link("Sitio web de Nexo", destination: website)
                    }
                }

                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        isConfirmingLogout = true   // cambia el estado → SwiftUI muestra el diálogo
                    }
                }
            }
            .navigationTitle("Cuenta")
            // El diálogo se muestra mientras `isConfirmingLogout` sea true; SwiftUI lo regresa a false al cerrarlo.
            .confirmationDialog("¿Cerrar sesión?", isPresented: $isConfirmingLogout, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive, action: onLogout)
            }
        }
    }
}

/// Una fila reutilizable. @Binding: NO es dueña del valor, lo es quien se lo pasa.
private struct SettingToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
        }
    }
}

// 🟢 Xcode 15+: macro #Preview. 🟤 Antes: struct AccountView_Previews: PreviewProvider.
#Preview {
    AccountView(email: "ana@nexo.app", appInfo: AppInfo(version: "1.0", build: "1"), onLogout: {})
}
```

### 3.1 🖼️ Usa el Canvas
Con `AccountView.swift` abierto, muestra el **Canvas** (**⌥⌘↩**, o Editor → Canvas). Si dice "Preview paused", dale **Resume** (⌥⌘P).
- Cambia `"Cuenta"` por `"Mi cuenta"` y mira cómo se actualiza **sin correr la app**. Regrésalo.
- Toca el switch en el Canvas: funciona, porque `@AppStorage` y `@State` también corren en el preview.

> 💡 **Errores típicos en SwiftUI:** si escribes `isOn: autoplayVideos` (sin `$`), el error es *"Cannot convert value of type 'Bool' to expected argument type 'Binding<Bool>'"*. Si olvidas el `@` en `@State`, el error es *"Cannot assign to property: 'self' is immutable"*, porque una vista es un `struct` y `body` no es `mutating` (lo mismo del Día 2).

---

## 💻 Paso 4: `AppRouter`

📁 `App/AppRouter.swift`
```swift
import UIKit
import SwiftUI

/// Decide cuál es la pantalla RAÍZ de la ventana: el Login o la app principal (tabs).
/// Es el ÚNICO que cambia `window.rootViewController`. Antecesor del patrón Coordinator (nivel Mid).
final class AppRouter {
    private let window: UIWindow
    private let session: SessionStore

    init(window: UIWindow, session: SessionStore = SessionStore()) {
        self.window = window
        self.session = session
    }

    /// Al abrir la app: si hay sesión guardada, directo a los tabs; si no, al Login.
    func start() {
        if session.isLoggedIn {
            showMain(animated: false)
        } else {
            showLogin(animated: false)
        }
    }

    func logOut(animated: Bool = true) {
        session.logOut()
        showLogin(animated: animated)
    }

    // MARK: - Pantallas raíz
    private func showLogin(animated: Bool) {
        // El Login sigue en Main.storyboard 🟤, pero ahora lo carga NUESTRO código, no el Info.plist.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navigation = storyboard.instantiateInitialViewController() as? UINavigationController,
              let login = navigation.viewControllers.first as? LoginViewController else {
            assertionFailure("Main.storyboard: el Initial View Controller debe ser un Navigation Controller con el Login")
            return
        }
        // [weak self]: la ventana → Login → esta closure. Si la closure retuviera al router
        // (que retiene la ventana), se cerraría el círculo. Concepto 2.
        login.onLogin = { [weak self] email in
            self?.session.logIn(email: email)
            self?.showMain(animated: true)
        }
        setRoot(navigation, animated: animated)
    }

    private func showMain(animated: Bool) {
        let tabBar = UITabBarController()
        tabBar.viewControllers = [makeFeedTab(), makeAccountTab()]
        setRoot(tabBar, animated: animated)
    }

    // MARK: - Tabs
    private func makeFeedTab() -> UIViewController {
        // Lo mismo que hacía `showFeed()` del Login ayer, pero ahora aquí.
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        guard let feed = storyboard.instantiateInitialViewController(creator: { coder in
            FeedViewController(coder: coder, loader: MockFeedLoader())
        }) else {
            assertionFailure("Feed.storyboard no tiene Initial View Controller")
            return UIViewController()
        }
        // Cada tab tiene SU PROPIA pila de navegación.
        let navigation = UINavigationController(rootViewController: feed)
        navigation.tabBarItem = UITabBarItem(
            title: "Inicio",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        return navigation
    }

    private func makeAccountTab() -> UIViewController {
        let accountView = AccountView(
            email: session.currentEmail ?? "",
            appInfo: .current,
            onLogout: { [weak self] in self?.logOut() }
        )
        // 🟢 SwiftUI dentro de UIKit: para el tab bar es un UIViewController más.
        let hosting = UIHostingController(rootView: accountView)
        hosting.tabBarItem = UITabBarItem(
            title: "Cuenta",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        return hosting
    }

    // MARK: - Helpers
    private func setRoot(_ viewController: UIViewController, animated: Bool) {
        // Al reemplazar la raíz, la ventana suelta la pantalla anterior → ARC la libera (♻️).
        window.rootViewController = viewController
        guard animated else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
```

---

## 💻 Paso 5: El Login solo avisa

En `LoginViewController.swift`:

### 5.1 La closure
Debajo de `private let emailValidator = EmailValidator()` agrega:
```swift
    /// Quien ME crea (el AppRouter) decide qué pasa al iniciar sesión. El Login ya NO conoce al Feed.
    /// `var` opcional: el storyboard me crea con init?(coder:), así que se asigna DESPUÉS (Día 3, P2).
    var onLogin: ((String) -> Void)?
```

### 5.2 Llamarla
En `loginButtonTapped`, dentro de `case .success(let validEmail):`, reemplaza
```swift
            print("✅ Login valido con \(validEmail)")
            showFeed()
```
por
```swift
            onLogin?(validEmail)
```

### 5.3 Borra `showFeed()` completo
Ahora vive en `AppRouter.makeFeedTab()`. (Con esto también desaparece el typo `Initiañ ViewContoller`.)

> ✅ Comprueba con **⌘⇧F** que no quedó ningún `showFeed` en el proyecto.

---

## 💻 Paso 6: La ventana por código (`SceneDelegate` + Info.plist)

### 6.1 `App/SceneDelegate.swift`
Reemplaza la propiedad `window` y el método `scene(_:willConnectTo:options:)` (con sus comentarios en inglés) por:
```swift
    var window: UIWindow?

    /// strong: el SceneDelegate es el DUEÑO del router. Si fuera una variable local dentro
    /// del método, ARC lo liberaría al terminar y el login no haría nada (experimento 7.4).
    private var router: AppRouter?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // 🟢 Creamos la ventana por código (🟤 antes la creaba el sistema con el storyboard del Info.plist).
        let window = UIWindow(windowScene: windowScene)
        let router = AppRouter(window: window)
        router.start()               // pone la raíz: Login o tabs
        window.makeKeyAndVisible()   // sin esto, pantalla negra

        self.window = window
        self.router = router
    }
```
Los demás métodos (`sceneDidDisconnect`, etc.) se quedan como están.

### 6.2 Quitar el storyboard inicial (2 lugares)
Si no lo quitas, el sistema **también** carga el Login del storyboard y luego tu código lo reemplaza: el Login se crea dos veces.

1. **Info.plist** (ábrelo en Xcode): `Application Scene Manifest` → `Scene Configuration` → `Application Session Role` → `Item 0` → selecciona **`Storyboard Name`** y bórralo con la tecla ⌫ (o el botón **−**). Deja `Configuration Name` y `Delegate Class Name`.
2. **Target RoadmapSwift → General → Deployment Info → Main Interface**: borra `Main` y deja el campo **vacío**. (Es el build setting *UIKit Main Storyboard File Base Name*.)

| Síntoma | Causa |
|---|---|
| Pantalla **negra** al abrir | Falta `window.makeKeyAndVisible()` o no guardaste `self.window = window` |
| Funciona pero el Login se crea 2 veces | No quitaste `Storyboard Name` del Info.plist |
| El botón "Iniciar sesión" no hace nada | `router` es local (no lo guardaste en `self.router`) o no asignaste `login.onLogin` |
| Crash `Could not find a storyboard named 'Mian'` | Typo en el nombre del storyboard |

---

## ▶️ Paso 7: Pruébalo y haz los experimentos (⌘R)

### 7.1 Funcionalidad
1. Inicia sesión con `ana@nexo.app` → aparecen los tabs **Inicio** y **Cuenta**. En Inicio **no** hay botón "atrás".
2. Ve a **Cuenta**: tu correo, el switch y la versión `1.0 (1)`.
3. Apaga el switch. **Detén la app (⌘.) y vuelve a correrla (⌘R)**: entra directo a los tabs (la sesión se guardó) y el switch sigue apagado (`@AppStorage`).
4. **Cerrar sesión** → confirma → regresas al Login.

### 7.2 🧪 Experimento: ver la liberación
Con la app en los tabs, toca **Cerrar sesión**. En la consola debe salir `♻️ FeedViewController liberado`: al cambiar la raíz, la ventana soltó los tabs y ARC liberó todo. Compáralo con el Día 4: allí el Feed se liberaba al hacer "atrás"; hoy, al cambiar la raíz.

### 7.3 🧪 Experimento: dónde vive UserDefaults
1. Pon un breakpoint en `SessionStore.logIn(email:)` e inicia sesión.
2. En la consola de LLDB escribe:
   ```
   po NSHomeDirectory()
   ```
3. Continúa la ejecución (**⌃⌘Y**) y espera unos segundos: UserDefaults escribe en disco un poco después.
4. Copia la ruta, y en Terminal:
   ```bash
   open "<la ruta>/Library/Preferences"
   ```
5. Abre el `.plist` que está ahí (doble clic, o `plutil -p archivo.plist` en Terminal). Verás `session.currentEmail` y `settings.autoplayVideos` **en texto plano**. Por eso las contraseñas **nunca** van aquí.

### 7.4 🧪 Experimento: ¿quién es dueño del router?
1. En `SceneDelegate`, comenta temporalmente la línea `self.router = router`.
2. Corre, cierra sesión si estabas dentro, y toca **Iniciar sesión** con un correo válido. ¿Qué pasa? **Nada.** El router se liberó al terminar `scene(_:willConnectTo:)`, y `self?` en la closure de `onLogin` es `nil`.
3. **Regrésalo.**

> 💡 Este es el bug contrario al del Día 4: allá algo vivía **de más** (leak); aquí algo muere **antes de tiempo**. Los dos son problemas de "quién es dueño".

---

## 🧪 Paso 8: Tests

### 8.1 📁 `NexoTests/Helpers/XCTestCase+UserDefaults.swift`
```swift
import XCTest

extension XCTestCase {
    /// Un UserDefaults NUEVO y vacío para cada test, que se borra al terminar.
    /// Si los tests usaran `.standard`, se mezclarían con los datos de la app (y entre ellos).
    func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "NexoTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!   // solo devuelve nil con nombres reservados
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}
```

### 8.2 📁 `NexoTests/Core/Session/SessionStoreTests.swift` (carpeta nueva)
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class SessionStoreTests: XCTestCase {

    func test_newStore_isLoggedOut() {
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentEmail)
    }

    func test_logIn_savesEmail() {
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        sut.logIn(email: "ana@nexo.app")
        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertEqual(sut.currentEmail, "ana@nexo.app")
    }

    func test_logOut_removesEmail() {
        let sut = SessionStore(defaults: makeIsolatedDefaults())
        sut.logIn(email: "ana@nexo.app")
        sut.logOut()
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentEmail)
    }

    /// Simula cerrar y volver a abrir la app: otra instancia, mismo almacenamiento.
    func test_session_persistsAcrossInstances() {
        let defaults = makeIsolatedDefaults()
        SessionStore(defaults: defaults).logIn(email: "ana@nexo.app")
        let reopened = SessionStore(defaults: defaults)
        XCTAssertEqual(reopened.currentEmail, "ana@nexo.app")
    }
}
```

### 8.3 📁 `NexoTests/App/AppInfoTests.swift` (carpeta nueva)
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class AppInfoTests: XCTestCase {

    func test_init_readsVersionAndBuild() {
        let sut = AppInfo(infoDictionary: ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "34"])
        XCTAssertEqual(sut.versionText, "1.2 (34)")
    }

    func test_init_missingKeys_usesQuestionMarks() {
        XCTAssertEqual(AppInfo(infoDictionary: nil).versionText, "? (?)")
    }
}
```

### 8.4 📁 `NexoTests/App/AppRouterTests.swift`
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class AppRouterTests: XCTestCase {

    func test_start_withoutSession_showsLogin() throws {
        let (sut, window, _) = makeSUT()
        sut.start()
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        XCTAssertTrue(navigation.viewControllers.first is LoginViewController)
    }

    func test_start_withSession_showsInicioAndCuentaTabs() throws {
        let (sut, window, _) = makeSUT(loggedInAs: "ana@nexo.app")
        sut.start()
        let tabBar = try XCTUnwrap(window.rootViewController as? UITabBarController)
        // `\.tabBarItem.title`: un key path usado como closure (lo viste en el Día 3).
        XCTAssertEqual(tabBar.viewControllers?.map(\.tabBarItem.title), ["Inicio", "Cuenta"])
    }

    func test_login_savesSessionAndShowsTabs() throws {
        let (sut, window, session) = makeSUT()
        sut.start()
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        let login = try XCTUnwrap(navigation.viewControllers.first as? LoginViewController)

        login.onLogin?("ana@nexo.app")   // simulamos que el Login avisó

        XCTAssertEqual(session.currentEmail, "ana@nexo.app")
        XCTAssertTrue(window.rootViewController is UITabBarController)
    }

    func test_logOut_clearsSessionAndShowsLogin() throws {
        let (sut, window, session) = makeSUT(loggedInAs: "ana@nexo.app")
        sut.start()

        sut.logOut(animated: false)

        XCTAssertFalse(session.isLoggedIn)
        let navigation = try XCTUnwrap(window.rootViewController as? UINavigationController)
        XCTAssertTrue(navigation.viewControllers.first is LoginViewController)
    }

    // MARK: - Helpers
    private func makeSUT(loggedInAs email: String? = nil) -> (AppRouter, UIWindow, SessionStore) {
        let session = SessionStore(defaults: makeIsolatedDefaults())
        if let email { session.logIn(email: email) }
        // Una ventana "suelta" (sin escena): suficiente para revisar quién es la raíz.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let sut = AppRouter(window: window, session: session)
        // ⚠️ Si una closure (onLogin / onLogout) retiene al router con strong, esto falla.
        assertNoMemoryLeak(sut)
        return (sut, window, session)
    }
}
```
> 💡 Es una **tupla** con nombres descartables: `let (sut, window, _) = makeSUT()`. El `_` dice "este valor no lo necesito en este test".

### 8.5 🧪 Comprueba que el test de leak sirve (como en el Día 4)
1. En `AppRouter.showLogin`, quita `[weak self]` de `onLogin` y cambia los dos `self?.` por `self.`. Corre **⌘U**: deben **fallar 2 tests** con el mensaje de memory leak. ¿Cuáles? Anótalos para la pregunta 3. Regrésalo.
2. Haz lo mismo con `onLogout` en `makeAccountTab`. ¿Fallan los **mismos** 2 tests o **otros**? Anótalo también. Regrésalo.

---

## ▶️ Paso 9: Correr, revisar y hacer commit
1. **⌘U** → deben pasar **50 tests** (40 anteriores + 10 nuevos).
2. **⌘R** → repite el Paso 7.1.
3. Revisión antes del commit:
   ```bash
   git status                       # nuevos: Session/, Settings/, Account/, AppRouter, AppInfo, tests
   git add .
   git --no-pager diff --staged     # revisa: "Main", "Feed", "Inicio", "Cuenta", las claves y que no quede showFeed
   ```
   En el diff también deben aparecer el `Info.plist` (sin `UISceneStoryboardFile`) y `project.pbxproj` (sin `INFOPLIST_KEY_UIMainStoryboardFile`). Si no salen, el Paso 6.2 no se guardó.
4. Commit y merge:
   ```bash
   git commit -m "feat(app): tabs con raíz por código, sesión en UserDefaults y pantalla Cuenta en SwiftUI"
   git checkout main
   git merge feature/dia-05-tabs-swiftui
   ```

---

## ✅ Checklist del día
- [✅] Pendientes del Día 4 corregidos (`✓`, `·` y typos)
- [✅] Al iniciar sesión aparecen los tabs **Inicio** y **Cuenta**, sin botón "atrás"
- [✅] Al reabrir la app (⌘. y ⌘R) entras directo a los tabs
- [✅] El switch de **Cuenta** conserva su valor al reabrir la app
- [✅] **Cerrar sesión** pide confirmación, regresa al Login y sale `♻️ FeedViewController liberado`
- [✅] Viste el `.plist` de UserDefaults en texto plano (Paso 7.3)
- [✅] Viste que sin `self.router = router` el login no hace nada (Paso 7.4)
- [✅] Los tests de leak del router fallan sin `[weak self]` (Paso 8.5)
- [✅] 50 tests en verde
- [✅] Revisaste `git --no-pager diff --staged` antes del commit

## 🔥 Reto extra (opcional, +5 puntos)
1. **🟢 `UITab` (iOS 18+).** En lugar de `tabBar.viewControllers = [...]`, usa `tabBar.tabs = [UITab(title:image:identifier:) { _ in ... }, ...]`. Ajusta el test de los títulos (pista: `tabBar.tabs.map(\.title)`). Corre en el simulador de **iPad**: ¿qué cambia?
2. **Recordar el correo al cerrar sesión.** Que el Login muestre el último correo usado (sin la contraseña). ¿Dónde lo guardas? ¿Quién se lo pasa al Login: el router o el Login lo lee solo? Justifícalo en un comentario.
3. **Badge.** Pon `tabBarItem.badgeValue = "3"` en el tab Inicio y quítalo cuando el usuario entre a ese tab (pista: `UITabBarControllerDelegate`, `tabBarController(_:didSelect:)`). ¿Quién debería ser el delegate: el router o el Feed?
4. **SwiftUI: `@State` vs `let`.** En el `#Preview`, crea un `struct PreviewWrapper: View` con `@State var email = "ana@nexo.app"` y un `TextField` arriba de `AccountView(email: email, ...)`. Escribe en el TextField dentro del Canvas: ¿se actualiza la fila "Correo"? ¿Por qué sí, si en `AccountView` el email es un `let`?

## 🧠 Preguntas de repaso (respóndelas antes del Día 6)
> 💡 Recuerda: si una pregunta tiene varias partes, contesta **cada parte en su propia línea**. Si no sabes una, escribe lo que observaste en el experimento: eso ya da puntos parciales.

1. ¿Por qué después del login cambiamos el `rootViewController` en lugar de hacer `push` del Feed? Da **dos** razones (una de experiencia de usuario y una de memoria).
Cambiamos a root para que cuando se haga login nos mande al tab, y no haya botón de regresar al login., Asi mismo se reusa la vista y se evita desbordar memoria
2. En el experimento 7.4, ¿por qué el login no hacía nada sin `self.router = router`? ¿Quién era el dueño del router antes y quién después?
El dueño del router era la window
3. En el Paso 8.5, ¿qué tests fallaron al quitar el `weak` de `onLogin` y cuáles al quitarlo de `onLogout`? ¿Por qué el test `test_login_savesSessionAndShowsTabs` **pasa** aunque `onLogin` no tenga `weak`? (Pista: ¿qué hace `setRoot` con la pantalla anterior?)
4. ¿Qué diferencia hay entre `@State`, `@Binding` y `@AppStorage`? ¿Quién es el dueño del valor en cada uno?
5. ¿Por qué el correo puede ir en `UserDefaults` pero la contraseña o un token **no**? ¿Dónde irían?
El correo es un dato no sensible por lo tanto puede ir en UserDefaults, mientras que la contraseña o token son datos sensibles y deberían ir en el Keychain

---
**Próximo (Día 6):** red con **`URLSession` y completion handlers** 🟤: descargar los **avatares** de los autores, `DispatchQueue.main.async` (por qué la UI solo se toca en el hilo principal), `[weak self]` en closures **asíncronas** y el bug clásico de la imagen equivocada en una celda reciclada.
