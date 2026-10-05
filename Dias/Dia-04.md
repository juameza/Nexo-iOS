# 📅 Día 4: El Feed con `UITableView`, reciclaje de celdas y ARC (retain cycles)

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** `UITableViewController`, `UITableViewDataSource`/`Delegate` 🟤, celdas prototipo en un **storyboard propio**, `UITableViewCell` personalizada con outlets, `dequeueReusableCell` y **por qué las celdas se reciclan**, `prepareForReuse`, celdas de alto automático, un protocolo para inyectar el loader (**stub** en los tests), **ARC**: `strong`/`weak`/`unowned`, retain cycles con closures, `deinit` y el **Memory Graph Debugger**, y un test que detecta *memory leaks*.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Al iniciar sesión, la app abre el **Feed** con los 4 posts de `feed.json`.
2. Una celda propia (`PostCell`) con nombre, `@usuario · hace 9 días`, el contenido y un botón ❤️ que funciona.
3. El post `"poll"` muestra *"Actualiza Nexo para ver esta publicación"* (el `.unsupported` del Día 2 por fin se ve).
4. Comprobarás **con tus propios ojos** un retain cycle: lo creas, lo ves en el Memory Graph y lo arreglas.
5. **8 tests nuevos**, para un total de **40**. Uno de ellos **falla si hay un memory leak**.

---

## 📚 Concepto 1: Cómo funciona `UITableView` (y por qué recicla celdas)

La tabla **no** crea una celda por cada fila. Si tienes 10,000 posts, crea solo las que caben en pantalla (~8) y **las reutiliza** al hacer scroll:

```
 ┌──────────────┐
 │ celda A  #1  │   ← al salir por arriba, la celda A va a la "cola de reciclaje"...
 │ celda B  #2  │
 │ celda C  #3  │
 │ ...          │
 │ celda H  #8  │
 └──────────────┘
   celda A  #9      ← ...y regresa por abajo con los datos del post #9
```

Por eso:
- **Nunca** guardes datos importantes dentro de la celda: es "prestada".
- En `cellForRowAt` tienes que **configurar todo** cada vez. Si al post #1 le pusiste el corazón rojo y al #9 no se lo quitas, el #9 sale rojo. Es el **bug clásico de celdas recicladas**.
- `prepareForReuse()` se llama justo antes de reutilizar la celda: ahí limpias lo que no se reconfigura (closures, descargas de imágenes en curso, etc.).

### DataSource vs Delegate
| Protocolo | Pregunta que responde | Métodos típicos |
|---|---|---|
| `UITableViewDataSource` | **¿Qué** muestro? | `numberOfRowsInSection`, `cellForRowAt` |
| `UITableViewDelegate` | **¿Qué pasa** cuando el usuario interactúa? ¿Cómo se ve? | `didSelectRowAt`, `heightForRowAt`, swipe actions |

`UITableViewController` ya es el `dataSource` y el `delegate` de su tabla: por eso hoy **sobrescribes** (`override`) esos métodos en lugar de declarar la conformance.

### 🟤 Viejo vs 🟢 nuevo en listas
| Tema | 🟤 Viejo (lo verás en apps existentes) | 🟢 Nuevo |
|---|---|---|
| Fuente de datos | `UITableViewDataSource` + `reloadData()` (**hoy**) | `UITableViewDiffableDataSource` / `UICollectionViewDiffableDataSource` (iOS 13+, **Mid**) |
| Contenido de la celda | `cell.textLabel?.text` (deprecado) o celda propia con outlets (**hoy**) | `UIListContentConfiguration` (iOS 14+) y `UIHostingConfiguration` con SwiftUI dentro de la celda (iOS 16+) |
| Alto de la celda | `heightForRowAt` calculado a mano | **Self-sizing**: Auto Layout calcula el alto (`automaticDimension`, **hoy**) |
| Tipo de lista | `UITableView` | `UICollectionView` con *list layout* / Compositional Layout (iOS 14+) |
| SwiftUI | – | `List` / `LazyVStack` |

> 💡 Apple sigue manteniendo `UITableView`, y la mayoría de apps grandes la tienen en alguna pantalla. Un Staff tiene que saber migrarla, y para migrarla primero hay que entenderla.

---

## 📚 Concepto 2: ARC y retain cycles (la pregunta 1 del Día 3)

**ARC** (*Automatic Reference Counting*): cada objeto de una **clase** lleva la cuenta de cuántas referencias **strong** apuntan a él. Cuando la cuenta llega a **0**, se libera y se llama a su `deinit`.

```swift
var a: FeedViewController? = FeedViewController(...)  // cuenta = 1
var b = a                                             // cuenta = 2
a = nil                                               // cuenta = 1
b = nil                                               // cuenta = 0 → deinit → memoria liberada ✅
```

| Referencia | ¿Suma a la cuenta? | Si el objeto se libera… | Úsala cuando… |
|---|---|---|---|
| `strong` (por defecto) | ✅ Sí | – | Eres "dueño" del objeto |
| `weak` | ❌ No | se vuelve `nil` sola (por eso siempre es `var` y opcional) | El otro objeto **puede** morir antes que tú: delegates, `[weak self]` |
| `unowned` | ❌ No | 💥 **crash** si la usas | Estás **seguro** de que el otro vive al menos lo mismo que tú. Mal usada crashea. |

### El retain cycle de hoy (con una closure)
```
FeedViewController ──strong──▶ tableView ──strong──▶ PostCell ──strong──▶ onLikeTapped (closure)
        ▲                                                                      │
        └──────────────────────── strong (captura `self`) ─────────────────────┘
```
Una closure **captura** (retiene) lo que usa dentro. Si usa `self` y `self` retiene (indirectamente) a la closure, nadie llega nunca a 0: **memory leak**. El Feed se queda en memoria aunque salgas de él, y cada vez que entres se crea otro.

La solución es la *capture list* `[weak self]`:
```swift
cell.onLikeTapped = { [weak self] in
    self?.toggleLike(postID: post.id)   // si el Feed ya no existe, no hace nada
}
```

> ⚠️ En el **Paso 7** vas a quitar el `[weak self]` a propósito para **ver** el leak. Es la mejor forma de que se te quede.

---

## 📚 Concepto 3: Inyectar el loader con un protocolo
Hoy el Feed **no crea** su `MockFeedLoader`: lo recibe en el `init`, pero como **protocolo**:
```swift
protocol FeedLoader { func load() throws -> [Post] }
```
- La app le pasa `MockFeedLoader()` (y en el Día ~60 un `RemoteFeedLoader` que habla con NexoServer, **sin tocar el Feed**).
- Los tests le pasan un **stub**: un loader falso que devuelve exactamente lo que el test necesita (3 posts, o un error).

🟤 Lo que verás en código viejo: `FeedService.shared.load()` (un *singleton*) **dentro** del view controller. Funciona, pero no puedes probar el caso de error sin romper el JSON real.

Y como el Feed necesita el loader **desde que nace**, usamos lo del **reto 1 del Día 3**: `instantiateInitialViewController(creator:)` con un `init` propio. Así `loader` puede ser `let`.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # solo deben aparecer Dias/Dia-04.md y ROADMAP.md (los agregué yo)
git checkout -b feature/dia-04-feed
```

---

## 💻 Paso 1: El protocolo `FeedLoader`

📁 `Features/Feed/Data/FeedLoader.swift`
```swift
import Foundation

/// Contrato: "algo que sabe cargar posts".
/// El Feed depende de ESTO, no de una clase concreta. Hoy lo cumple `MockFeedLoader`;
/// en el nivel Mid lo cumplirá un loader que llama a NexoServer, y en los tests, un stub.
nonisolated protocol FeedLoader {
    func load() throws -> [Post]
}
```

Y en `MockFeedLoader.swift` agrega la conformance en la declaración (ya tiene el método `load()`, así que no hay que escribir nada más):
```swift
nonisolated struct MockFeedLoader: FeedLoader {
```

---

## 💻 Paso 2: Texto para cada tipo de contenido

📁 Crea la carpeta `Features/Feed/UI` y dentro `PostContent+Preview.swift`:
```swift
import Foundation

/// Cómo se ve cada tipo de contenido en el Feed (por ahora solo texto; las imágenes llegan en Mid).
/// Va en una extension dentro de Feed/UI porque es un detalle de PRESENTACIÓN, no del modelo.
nonisolated extension PostContent {
    var previewText: String {
        // 🟢 Swift 5.9+: `switch` como expresión, sin `return` en cada case.
        switch self {
        case .text(let text):
            text
        case .image(_, let caption):
            "🖼️ " + (caption ?? "Foto")
        case .video(_, let duration):
            // 🟢 iOS 16+: Duration + FormatStyle → "0:42". 🟤 Antes: DateComponentsFormatter.
            "🎬 Video · " + Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
        case .unsupported:
            // Forward compatibility (Día 2): la app vieja no crashea, avisa.
            "Actualiza Nexo para ver esta publicación"
        }
    }
}
```
> 💡 El `_` en `.image(_, let caption)` significa "no me importa la URL". Si agregas un caso nuevo a `PostContent`, este `switch` deja de compilar: el compilador te avisa de **todos** los lugares que tienes que actualizar.

---

## 💻 Paso 3: La celda `PostCell`

📁 `Features/Feed/UI/PostCell.swift`
```swift
import UIKit

final class PostCell: UITableViewCell {
    /// Debe ser IGUAL al "Identifier" de la celda prototipo en el storyboard.
    static let reuseIdentifier = "PostCell"

    // MARK: - Outlets
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var metaLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var likeButton: UIButton!

    /// La celda NO sabe dar like: solo avisa "me tocaron" (igual que el delegate del Día 3, pero con closure).
    var onLikeTapped: (() -> Void)?

    // MARK: - Configuración
    /// Se llama en CADA `cellForRowAt`: hay que poner TODO, porque la celda puede venir reciclada.
    func configure(with post: Post) {
        nameLabel.text = post.author.isVerified ? "\(post.author.displayName) ✓" : post.author.displayName
        metaLabel.text = "\(post.author.handle) · \(post.relativeCreatedAt)"
        bodyLabel.text = post.content.previewText

        // 🟢 iOS 15+: UIButton.Configuration (como en el Día 1). El if/else cubre AMBOS estados:
        // si solo pintaras el corazón rojo cuando hay like, una celda reciclada se quedaría roja.
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: post.isLikedByMe ? "heart.fill" : "heart")
        config.title = "\(post.likeCount)"
        config.imagePadding = 6
        config.baseForegroundColor = post.isLikedByMe ? .systemPink : .secondaryLabel
        likeButton.configuration = config
    }

    /// Justo antes de reutilizar la celda: soltamos la closure del post anterior.
    override func prepareForReuse() {
        super.prepareForReuse()
        onLikeTapped = nil
    }

    // MARK: - Acciones
    @IBAction private func likeButtonTapped(_ sender: UIButton) {
        onLikeTapped?()
    }
}
```

---

## 💻 Paso 4: `FeedViewController`

📁 `Features/Feed/UI/FeedViewController.swift`
```swift
import UIKit

/// 🟤 UITableViewController: ya trae su `tableView` y ya es su dataSource y delegate.
final class FeedViewController: UITableViewController {

    // MARK: - Dependencias
    /// `let` + protocolo: el Feed no sabe (ni le importa) de dónde vienen los posts.
    private let loader: FeedLoader

    // MARK: - Estado
    /// `private(set)`: desde fuera se puede LEER (útil en tests), pero solo el Feed la cambia.
    private(set) var posts: [Post] = []

    // MARK: - Init
    /// 🟢 iOS 13+: el storyboard nos crea con ESTE init gracias a `instantiateInitialViewController(creator:)`.
    init?(coder: NSCoder, loader: FeedLoader) {
        self.loader = loader
        super.init(coder: coder)
    }

    /// Obligatorio por heredar de UIViewController. Si alguien crea el Feed sin loader, crash claro.
    required init?(coder: NSCoder) {
        fatalError("Usa init(coder:loader:)")
    }

    /// Se llama cuando la cuenta de ARC llega a 0. Si NUNCA lo ves al salir del Feed: hay leak.
    deinit {
        print("♻️ FeedViewController liberado")
    }

    // MARK: - Ciclo de vida
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inicio"
        loadFeed()
    }

    // MARK: - Datos
    private func loadFeed() {
        do {
            posts = try loader.load()
            tableView.backgroundView = nil
        } catch {
            posts = []
            tableView.backgroundView = makeMessageLabel("No pudimos cargar el feed 😕")
            print("❌ Feed:", error)
        }
        tableView.reloadData()   // 🟤 "vuelve a preguntarme TODO". En Mid: diffable (solo lo que cambió).
    }

    /// Buscamos por `id` y NO usamos el indexPath que tenía la celda: si la lista cambió
    /// (o la celda se recicló), ese indexPath podría apuntar a OTRO post.
    private func toggleLike(postID: Post.ID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].toggleLike()   // `mutating` del Día 2: funciona porque `posts` es `var`
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }

    private func makeMessageLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // dequeue: "dame una celda reciclada, o crea una nueva si no hay".
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PostCell.reuseIdentifier, for: indexPath
        ) as? PostCell else {
            fatalError("La celda prototipo no es PostCell: revisa Class e Identifier en Feed.storyboard")
        }
        let post = posts[indexPath.row]
        cell.configure(with: post)

        // ⚠️ [weak self]: la celda (que vive dentro de NUESTRA tabla) guarda esta closure.
        // Sin `weak`, la closure retendría al Feed → retain cycle (Concepto 2).
        cell.onLikeTapped = { [weak self] in
            self?.toggleLike(postID: post.id)
        }
        return cell
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Mid: abrir el detalle del post.
    }
}
```

---

## 🎨 Paso 5: `Feed.storyboard` (un storyboard propio)

**¿Por qué no en `Main.storyboard`?** En equipos, si 3 personas editan el mismo storyboard, los *merge conflicts* en el XML son una pesadilla. La práctica 🟤 profesional es **un storyboard por feature**. (Y en 🟢 SwiftUI el problema desaparece.)

### 5.1 Crear el archivo
1. Clic derecho en la carpeta `Features/Feed/UI` → **New File from Template…** → **Storyboard** → nombre **`Feed`** (el archivo queda `Feed.storyboard`). Verifica que el target **RoadmapSwift** esté marcado.

### 5.2 La escena
2. **Library** (⇧⌘L) → arrastra un **Table View Controller** (¡no un View Controller normal!).
3. **Attributes Inspector** (⌥⌘5) del view controller → ✅ **Is Initial View Controller** (aparece una flecha a la izquierda). Sin esto, `instantiateInitialViewController` devuelve `nil`.
4. **Identity Inspector** (⌥⌘4) → **Class:** `FeedViewController`.

### 5.3 La celda prototipo
5. Selecciona la **Table View Cell** (dentro de la tabla, en el *Document Outline*):
   - **Identity Inspector** → **Class:** `PostCell`.
   - **Attributes Inspector** → **Identifier:** `PostCell` (igual a `reuseIdentifier`). Selection: **Default**.
6. Selecciona la **Table View** → **Size Inspector** (⌥⌘6) → **Row Height:** ✅ **Automatic**. Estimate: `110`.
7. Dentro del **Content View** de la celda, arrastra un **Vertical Stack View**. Spacing **4**, Alignment **Fill**, Distribution **Fill**.
   Constraints: **Top, Bottom, Leading y Trailing = 0** respecto a los **márgenes** del Content View (en el popup ⊢⊣ deja marcado *Constrain to margins*).
8. Dentro del stack, en este orden:

| # | Elemento | Configuración |
|---|---|---|
| 1 | Label "Nombre" | Font **Headline** |
| 2 | Label "meta" | Font **Footnote**, Color **Secondary Label** |
| 3 | Label "contenido" | Font **Body**, Lines **0** (para que el texto largo baje de línea) |
| 4 | Button | Style **Plain**, Title `0`. En **Control → Alignment Horizontal**: **leading** (izquierda) |

> 💡 **Self-sizing:** el alto de la celda = la suma de lo que hay en el stack, porque el stack está pegado arriba **y** abajo. Si te falta la constraint de abajo, todas las celdas salen del mismo alto (o aplastadas) y Xcode avisa en la consola con `Unable to simultaneously satisfy constraints` o un alto 44 por defecto.

### 5.4 Conexiones
9. Abre el **Assistant** con `PostCell.swift` y conecta los 4 outlets **a la celda** (no al view controller).
10. Action: desde el botón → evento **Primary Action Triggered** → `likeButtonTapped:`.
11. Verifica en el **Connections Inspector** de la celda que no hay ⚠️ amarillos.

> ⚠️ **Error típico:** conectar los outlets de la celda al `FeedViewController`. Un view controller **no** puede tener outlets a elementos de una celda prototipo (porque hay N celdas, no una): Xcode da error de compilación *"The xxx outlet from the FeedViewController to the UILabel is invalid. Outlets cannot be connected to repeating content."*

---

## 💻 Paso 6: Del Login al Feed

En `LoginViewController.swift`:

### 6.1 Limpia el experimento del Día 3
Borra los `print` de `viewDidLoad` y los métodos `viewWillAppear`, `viewIsAppearing` y `viewDidAppear` completos (solo tenían el `print`). `configureUI()` se queda.

### 6.2 Navegar al Feed
Reemplaza el comentario `// Dia 5: navegar al Feed` por:
```swift
            showFeed()
```
Y agrega este método en la sección de navegación (después de `prepare(for:sender:)`):
```swift
    /// 🟢 Navegación por código con `creator:` (lo que viste en el reto 1 del Día 3):
    /// el storyboard crea el Feed usando NUESTRO init, así que el loader no se puede olvidar.
    private func showFeed() {
        let storyboard = UIStoryboard(name: "Feed", bundle: nil)
        guard let feed = storyboard.instantiateInitialViewController(creator: { coder in
            FeedViewController(coder: coder, loader: MockFeedLoader())
        }) else {
            // Solo truena en Debug: te avisa que olvidaste "Is Initial View Controller".
            assertionFailure("Feed.storyboard no tiene Initial View Controller")
            return
        }
        navigationController?.pushViewController(feed, animated: true)
    }
```
> ⚠️ **Tu patrón a vigilar:** `"Feed"` es otro String que el compilador no revisa (como `"howRegister"`). Si escribes `"Fed"`, la app crashea con *"Could not find a storyboard named 'Fed'"*. El test del Paso 8 usa el mismo nombre, así que lo detecta.
>
> 📌 Por ahora el Feed se abre con **push** y tiene botón "atrás" hacia el Login. No es lo correcto en una app real (después de iniciar sesión no deberías poder "regresar" al Login): lo arreglamos en el **Día 5** cambiando la pantalla raíz.

---

## ▶️ Paso 7: Pruébalo y haz los experimentos (⌘R)

### 7.1 Funcionalidad
1. Inicia sesión con `ana@nexo.app` / cualquier contraseña → se abre **Inicio** con 4 posts.
2. Mario aparece con **✓** (verificado), Carlos sin avatar (por ahora no mostramos avatares), el video dice `🎬 Video · 0:42` y la encuesta dice *"Actualiza Nexo…"*.
3. Toca ❤️ en el post de Mario: pasa a rojo y `12 → 13`. Vuelve a tocar: `13 → 12`.

### 7.2 🧪 Experimento: ver el reciclaje
1. En `PostCell` agrega temporalmente:
   ```swift
   override func awakeFromNib() {
       super.awakeFromNib()
       print("🧱 Celda NUEVA creada")
   }
   ```
2. En `loadFeed()`, cambia temporalmente `posts = try loader.load()` por:
   ```swift
   let loaded = try loader.load()
   posts = (1...25).flatMap { _ in loaded }   // 100 posts (ids repetidos: NO toques ❤️ aquí)
   ```
3. Corre la app, entra al Feed y haz **scroll hasta abajo**. Cuenta los `🧱`: ¿son 100? (Anota el número para la pregunta 1.)
4. **Regresa todo como estaba** (borra `awakeFromNib` y el `flatMap`).

### 7.3 🧪 Experimento: crear un retain cycle a propósito
1. Entra al Feed y regresa al Login con **"atrás"** → en la consola debe salir `♻️ FeedViewController liberado`. ✅
2. Ahora en `cellForRowAt` **quita** `[weak self]` y cambia `self?.` por `self.`:
   ```swift
   cell.onLikeTapped = {
       self.toggleLike(postID: post.id)
   }
   ```
3. Corre, entra al Feed y regresa. ¿Sale `♻️`? **No**. Entra y regresa 3 veces.
4. Con la app corriendo, pulsa el botón **Debug Memory Graph** (el ícono de 3 circulitos conectados en la barra de debug, abajo). En el panel izquierdo busca `FeedViewController`: verás **3 instancias vivas** (una por cada vez que entraste) aunque ya no están en pantalla. Selecciona una y sigue las flechas: `FeedViewController → UITableView → PostCell → closure → FeedViewController`. Ese es el ciclo del Concepto 2.
5. **Regresa el `[weak self]`** y `self?.`, repite el paso 1 y confirma que sale `♻️`.

> 💡 Si en el paso 3 ves `♻️` aunque quitaste el `weak`, toca **❤️ una vez** antes de regresar (o haz scroll) para asegurarte de que la tabla creó y guardó las celdas.

---

## 🧪 Paso 8: Tests

### 8.1 📁 `NexoTests/Helpers/XCTestCase+MemoryLeak.swift` (carpeta nueva)
```swift
import XCTest

extension XCTestCase {
    /// Falla si `instance` sigue viva cuando el test ya terminó → hay un retain cycle.
    /// `addTeardownBlock` se ejecuta DESPUÉS del test, cuando todas sus variables locales ya se soltaron.
    /// `[weak instance]`: si el bloque la capturara strong, ¡el propio test causaría el leak!
    /// `file:`/`line:`: el error se marca en la línea del test que llamó al helper, no aquí.
    func assertNoMemoryLeak(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "⚠️ Memory leak: la instancia sigue viva. ¿Falta un [weak self]?", file: file, line: line)
        }
    }
}
```

### 8.2 📁 `NexoTests/Features/Feed/FeedViewControllerTests.swift`
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewControllerTests: XCTestCase {

    func test_viewDidLoad_rendersOneRowPerPost() throws {
        let sut = try makeSUT(result: .success([.fixture(), .fixture(), .fixture()]))
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 3)
        XCTAssertNil(sut.tableView.backgroundView)
    }

    func test_viewDidLoad_loaderFails_showsErrorAndNoRows() throws {
        let sut = try makeSUT(result: .failure(FeedLoaderError.fileNotFound("x")))
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
        XCTAssertNotNil(sut.tableView.backgroundView)
    }

    /// También es un test de humo: si la celda prototipo no tiene Class/Identifier
    /// correctos, o un outlet está roto, esto truena.
    func test_cellForRow_returnsPostCell() throws {
        let sut = try makeSUT(result: .success([.fixture(content: .text("Hola Nexo"))]))
        let cell = sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell is PostCell)
    }

    func test_feed_isReleasedFromMemory() throws {
        let sut = try makeSUT(result: .success([.fixture()]))
        // Le damos tamaño y forzamos el layout para que la TABLA cree y GUARDE sus celdas.
        // Sin esto no existiría la cadena tabla → celda → closure, y el test no detectaría el ciclo.
        sut.tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
    }

    // MARK: - Helpers
    /// "make System Under Test": un solo lugar para construir el Feed en todos los tests.
    private func makeSUT(result: Result<[Post], Error>) throws -> FeedViewController {
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { coder in
            FeedViewController(coder: coder, loader: FeedLoaderStub(result: result))
        })
        sut.loadViewIfNeeded()   // dispara viewDidLoad → loadFeed()
        return sut
    }
}

/// STUB: un loader falso que devuelve exactamente lo que el test le pida.
/// Gracias al protocolo `FeedLoader`, el Feed no nota la diferencia.
private struct FeedLoaderStub: FeedLoader {
    let result: Result<[Post], Error>
    func load() throws -> [Post] { try result.get() }   // .success → posts, .failure → throw
}
```
> 💡 `.fixture()` es el que escribiste en el Día 2 (`PostDecodingTests.swift`). Como está en el mismo target de tests, se puede usar aquí.

### 8.3 📁 `NexoTests/Features/Feed/PostContentPreviewTests.swift`
```swift
import XCTest
@testable import RoadmapSwift

final class PostContentPreviewTests: XCTestCase {
    private let url = URL(string: "https://nexo.app/a")!

    func test_previewText_text_returnsText() {
        XCTAssertEqual(PostContent.text("Hola").previewText, "Hola")
    }

    func test_previewText_imageWithoutCaption_returnsFoto() {
        XCTAssertEqual(PostContent.image(url: url, caption: nil).previewText, "🖼️ Foto")
    }

    func test_previewText_video_formatsMinutesAndSeconds() {
        XCTAssertEqual(PostContent.video(url: url, duration: 42.5).previewText, "🎬 Video · 0:42")
    }

    func test_previewText_unsupported_asksToUpdate() {
        XCTAssertEqual(PostContent.unsupported(type: "poll").previewText, "Actualiza Nexo para ver esta publicación")
    }
}
```

### 8.4 🧪 Comprueba que el test de leak sirve
Un test que nunca falla no sirve de nada. Quita otra vez el `[weak self]` (como en 7.3), corre **⌘U** y confirma que **`test_feed_isReleasedFromMemory` falla** con el mensaje de memory leak. Después regrésalo.

> Así ya no dependes de acordarte de abrir el Memory Graph: si alguien quita el `weak` en el futuro, el test lo atrapa. Esto es lo que se hace en equipos Senior.

---

## ▶️ Paso 9: Correr, revisar y hacer commit
1. **⌘U** → deben pasar **40 tests** (32 anteriores + 8 nuevos).
2. **⌘R** → repite el Paso 7.1.
3. Revisión antes del commit, **en este orden** (lo que aprendiste ayer):
   ```bash
   git status                       # los archivos nuevos salen como "Untracked"
   git add .
   git --no-pager diff --staged     # lee CADA nombre nuevo: reuseIdentifier, "Feed", outlets...
   ```
   Busca en el diff que no hayan quedado el `awakeFromNib`, el `flatMap` del experimento ni un `self.` sin `weak`.
4. Commit y merge:
   ```bash
   git commit -m "feat(feed): feed con UITableView, PostCell, FeedLoader y test de memory leak"
   git checkout main
   git merge feature/dia-04-feed
   ```

---

## ✅ Checklist del día
- [✅ ] Al iniciar sesión se abre **Inicio** con los 4 posts
- [ ✅] Las celdas tienen alto automático (el texto largo baja de línea y no se corta)
- [✅ ] El post `poll` dice "Actualiza Nexo para ver esta publicación"
- [ ✅] ❤️ cambia el color y el contador, y se puede quitar
- [ ✅] Viste cuántas celdas se crean con 100 posts (Paso 7.2)
- [✅ ] Viste el leak en el **Memory Graph** y desapareció con `[weak self]` (Paso 7.3)
- [✅ ] `test_feed_isReleasedFromMemory` **falla** sin `[weak self]` y **pasa** con él (Paso 8.4)
- [✅ ] 40 tests en verde
- [ ✅] Revisaste `git --no-pager diff --staged` antes del commit

## 🔥 Reto extra (opcional, +5 puntos)
1. **Like con swipe.** Implementa `trailingSwipeActionsConfigurationForRowAt` (`UITableViewDelegate`) con una `UIContextualAction` "❤️ Me gusta" / "💔 Quitar" que llame a `toggleLike`. ¿Necesitas `[weak self]` en el handler de la acción? Explica por qué sí o por qué no en un comentario.
2. **Pull to refresh 🟤.** Agrega `refreshControl = UIRefreshControl()` y su target-action para volver a llamar a `loadFeed()` y terminar con `endRefreshing()`.
3. **🟢 `UIListContentConfiguration`.** En una rama aparte, crea una celda **sin storyboard ni outlets** usando `var content = cell.defaultContentConfiguration()` (`text`, `secondaryText`, `image`). Anota qué ganas y qué pierdes frente a `PostCell`.
4. **`unowned` 💥.** Cambia `[weak self]` por `[unowned self]`. ¿Funciona? ¿Pasa el test de leak? Describe un escenario en el que `unowned` crashearía aquí (pista: una closure que se ejecuta **después** de que el Feed se liberó, como un `DispatchQueue.main.asyncAfter`).

## 🧠 Preguntas de repaso (respóndelas antes del Día 5)
1. En el experimento 7.2, ¿cuántas celdas se crearon para 100 posts? ¿Por qué no 100? ¿Qué bug aparecería si en `configure` solo pintaras el corazón cuando `isLikedByMe` es `true`? - Aparecen 25, ya que en el loadFeed, se le puso un rango, 
2. Explica con tus palabras el ciclo del Paso 7.3: ¿quién retiene a quién? ¿Por qué `[weak self]` lo rompe y por qué después hay que usar `self?.`? El FeedViewController es que el retiene la memoria, por eso el que se muestren las instancias al regresar al login, por que weak es una instancia unica que se vuelve nil sola, de los contrario nunca se libera del ciclo
3. ¿Qué diferencia hay entre `weak` y `unowned`? ¿Cuál es más seguro y por qué?  Que Weak se vuelve nil solo, y unowned se crashea, es mas seguro weak
4. ¿Qué ganamos con que `FeedViewController` reciba un `FeedLoader` (protocolo) en el `init`, en lugar de crear `MockFeedLoader()` adentro? Da **dos** ventajas.
5. ¿Por qué `toggleLike` busca el post por `id` en lugar de usar el `indexPath` que tenía la celda cuando se configuró? Por seguridad de que no se crashee la app

> 💡 Tip para las preguntas (lo que hablamos ayer): antes de responder, **busca el concepto en tu propio código** de hoy. Las 5 respuestas están en algo que escribiste o viste en un experimento.

---
**Próximo (Día 5):** después del login, el Feed pasa a ser la **pantalla raíz** (ya no se puede "regresar" al Login) cambiando el `rootViewController` desde el `SceneDelegate`, un `UITabBarController` (Inicio / Perfil) y tu primera pantalla en **SwiftUI** ("Acerca de") dentro de UIKit con `UIHostingController`.
