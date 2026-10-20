# 📅 Día 8: MVVM con binding por closures: sacar la lógica del Feed a un `FeedViewModel`

**Nivel:** 🐣 Junior (puente a Mid) · **Duración:** 1.5–2 h
**Temas:** **MVC 🟤 vs MVVM**, qué va en el ViewModel y qué se queda en la vista, **entradas y salidas** de un ViewModel, **binding con closures** 🟤 (y qué viene después: Combine, `@Observable` 🟢), un **segundo retain cycle** (vista ↔ ViewModel), helpers de test compartidos y **medir** la mejora con números (líneas, tests, tiempo).

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Un `FeedViewModel` con **toda la lógica** del Feed y **sin `import UIKit`**.
2. `FeedViewController` reducido a **dibujar** y **reenviar eventos** (de ~206 a ~110 líneas).
3. **13 tests del ViewModel** que corren **sin storyboard** y varias veces más rápido.
4. **77 tests** en total, y dos tests de memoria que vigilan dos ciclos distintos.

La app **se ve y se comporta igual** que ayer. Eso es un **refactor**: cambias la estructura, no el comportamiento. (Con una excepción pequeña a propósito, en el Concepto 4.)

---

## 📚 Concepto 1: El problema que dejamos ayer

En el experimento 6.5 mediste `FeedViewController`: ~206 líneas y 8 responsabilidades. Para probar **lógica** (¿con 0 posts se muestra vacío?, ¿se evita la petición doble?) necesitabas:
- cargar `Feed.storyboard`,
- crear una tabla real,
- leer `backgroundView` o `numberOfRows` para adivinar el estado.

Eso es lento, frágil (un cambio de diseño rompe tests de lógica) y mezcla dos preguntas: **"¿qué hay que mostrar?"** y **"¿cómo se dibuja?"**.

---

## 📚 Concepto 2: MVC 🟤 vs MVVM

| | MVC (Apple) 🟤 | MVVM |
|---|---|---|
| ¿Quién decide **qué** mostrar? | El ViewController | El **ViewModel** |
| ¿Quién **dibuja**? | El ViewController | El ViewController (que en MVVM es parte de la **View**) |
| ¿Conoce UIKit la lógica? | Sí, están en la misma clase | **No**: el ViewModel no importa UIKit |
| ¿Cómo se prueba la lógica? | Cargando storyboard y tabla | Creando un objeto normal: `FeedViewModel(loader: spy)` |
| ¿Cómo se entera la vista de los cambios? | No hace falta, es la misma clase | **Binding** (Concepto 3) |

> 💡 En UIKit, el `UIViewController` **es parte de la View** en MVVM. Suena raro por el nombre, pero su trabajo ahora es: recibir eventos del usuario → pasárselos al ViewModel, y recibir estados del ViewModel → dibujarlos.

### Las reglas del ViewModel
1. **No importa UIKit** (ni `UIImage`, ni `UITableView`, ni `IndexPath`). Habla en tipos del dominio: `Post`, `State`, `Int`.
2. Tiene **entradas** (métodos que la vista llama: `load()`, `toggleLike(postID:)`) y **salidas** (cómo avisa: closures).
3. Es **dueño del estado**. La vista no guarda una copia: lo lee del ViewModel.
4. **No sabe quién lo escucha**: puede ser un `UITableViewController`, una vista de SwiftUI o un test.

### Qué se mueve y qué se queda
| Responsabilidad (Día 7, 6.5) | Hoy va a… | ¿Por qué? |
|---|---|---|
| Pedir los posts | ViewModel | Lógica |
| Regresar al hilo principal | ViewModel | El estado se cambia siempre en el principal |
| Decidir el estado (cargando/vacío/error/contenido) | ViewModel | Lógica |
| Texto del error | ViewModel | Es **qué** decir (el texto de vacío lo dejamos en la vista; reto 1) |
| Evitar peticiones duplicadas | ViewModel | Lógica |
| Likes | ViewModel | Lógica |
| DataSource de la tabla | ViewController | Es UIKit |
| Spinner, labels, `refreshControl` | ViewController | Es UIKit |
| Avatares (`ImageLoader` y la celda) | ViewController (**por ahora**) | Depende de `PostCell` y `UIImage`. En Mid lo sacamos a un `PostCellController`/ViewModel de celda |

---

## 📚 Concepto 3: Binding, cómo se entera la vista

El ViewModel cambia su estado **más tarde** (cuando llega la respuesta). La vista necesita **enterarse**. Eso se llama **binding**. Hay muchas formas, de la más vieja a la más nueva:

| Forma | Ejemplo | Época |
|---|---|---|
| **Delegate** | `viewModel.delegate = self` + protocolo | 🟤 |
| **Closures** (hoy) | `viewModel.onStateChange = { [weak self] in … }` | 🟤 sencillo y explícito |
| `NotificationCenter` / KVO | `observe(\.state)` | 🟤 (KVO requiere `NSObject` y `@objc dynamic`) |
| **Combine** | `@Published var state` + `sink` | Intermedio (iOS 13) |
| **Observation** | `@Observable final class FeedViewModel` | 🟢 iOS 17; SwiftUI se redibuja solo |

Hoy usamos **closures** porque no esconden nada: ves exactamente quién llama a quién, y el ciclo de memoria se ve a simple vista (Concepto 5). En el nivel Mid migramos el mismo ViewModel a Combine y luego a `@Observable` 🔁.

⚠️ **Limitación de las closures:** cada salida tiene **un solo** oyente. Si dos objetos asignan `onStateChange`, el segundo **reemplaza** al primero sin avisar. (Pregunta 5.)

---

## 📚 Concepto 4: Tres salidas, no una

```swift
var onStateChange: ((State) -> Void)?   // cambió TODA la pantalla → reloadData
var onLoadingChange: ((Bool) -> Void)?  // empezó/terminó una petición → endRefreshing
var onPostUpdated: ((Int) -> Void)?     // cambió UN post → reloadRows de esa fila
```
¿Por qué separar? Porque son **eventos distintos** con **reacciones distintas**. Un like no debe recargar toda la tabla (Día 7: `toggleLike` no llamaba a `render`), y el spinner de arriba depende de *si hay una petición*, no del estado.

> ⚠️ **El único cambio de comportamiento de hoy:** ayer, el spinner grande dependía de `refreshControl?.isRefreshing` (un dato de UIKit). El ViewModel **no puede** preguntar eso. Ahora la regla es: *"si ya hay posts, se quedan visibles mientras carga; si no, spinner grande"*. Es una regla de **lógica**, y por eso ahora sí tiene su test (`test_refresh_keepsPostsVisibleWhileLoading`). Consecuencia visible: en el estado de **error**, al deslizar verás el spinner de arriba **y** el grande. Es aceptable; lo pulimos en Mid.

---

## 📚 Concepto 5: Un ciclo nuevo: vista ↔ ViewModel

```
FeedViewController ──(let viewModel)──▶ FeedViewModel ──(onStateChange)──▶ closure ──(self)──▶ FeedViewController  🔁
```
La vista es **dueña** del ViewModel (`let`). El ViewModel **guarda** las closures de la vista. Si la closure captura `self` fuerte, **ninguno** llega a 0. Es el mismo dibujo del Día 4 (celda ↔ Feed) y del Día 7 (spy ↔ Feed). Por eso **las tres** closures de `bind()` llevan `[weak self]`.

Y hay un **segundo** ciclo posible, dentro del ViewModel:
```
FeedViewModel ──(let loader)──▶ FeedLoaderSpy ──(completions)──▶ closure ──(self)──▶ FeedViewModel  🔁
```
Lo vigilan dos tests distintos (experimento 6.3).

> 💡 Regla práctica que ya puedes generalizar: **"si alguien que yo retengo guarda una closure mía, la closure lleva `[weak self]`"**.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # deben aparecer ROADMAP.md (entrevistas) y Dias/Dia-08.md
git checkout -b feature/dia-08-mvvm
```
Antes de tocar nada, **mide** (lo usarás en la pregunta 4):
```bash
wc -l RoadmapSwift/Features/Feed/UI/FeedViewController.swift
grep -c "func " RoadmapSwift/Features/Feed/UI/FeedViewController.swift
```

---

## 💻 Paso 1: `FeedViewModel`

📁 Crea la carpeta `Features/Feed/Presentation/` y dentro **`FeedViewModel.swift`** (target: RoadmapSwift):
```swift
import Foundation   // ⚠️ NO UIKit: el ViewModel no sabe que existe una tabla

/// MVVM 🟤 con binding por closures.
/// Toda la LÓGICA del Feed: pedir posts, decidir el estado, evitar peticiones duplicadas y los likes.
/// Por no depender de UIKit se prueba SIN storyboard.
final class FeedViewModel {

    // MARK: - Estado (el mismo enum del Día 7, ahora vive aquí)
    enum State: Equatable {
        case loading
        case loaded([Post])
        case empty
        case failed(message: String)
    }

    // MARK: - Salidas (binding): la vista se suscribe a estas closures
    /// Cambió el estado completo → la vista se vuelve a dibujar.
    var onStateChange: ((State) -> Void)?
    /// Empezó o terminó una petición → la vista muestra u oculta el spinner del refresh.
    var onLoadingChange: ((Bool) -> Void)?
    /// Cambió UN post (like) → la vista recarga solo esa fila.
    var onPostUpdated: ((Int) -> Void)?

    // MARK: - Estado interno
    /// private(set): la vista y los tests lo LEEN; solo el ViewModel lo cambia.
    private(set) var state: State = .loading
    private(set) var isLoading = false

    private let loader: FeedLoader

    init(loader: FeedLoader) {
        self.loader = loader
    }

    // MARK: - Lectura para el DataSource
    var posts: [Post] {
        if case .loaded(let posts) = state { return posts }
        return []
    }

    // MARK: - Entradas (lo que la vista le pide)
    func load() {
        guard !isLoading else { return }   // ya hay una petición en curso
        setLoading(true)
        // Concepto 4: si ya hay posts (refresh), se quedan visibles. Si no, spinner grande.
        if case .loaded = state {} else {
            setState(.loading)
        }
        // [weak self] (Concepto 5): el loader podría GUARDAR esta closure (como el spy).
        loader.load { [weak self] result in
            // 🟤 Llega en un hilo de fondo → el estado SIEMPRE se cambia en el principal.
            DispatchQueue.main.async {
                self?.handle(result)
            }
        }
    }

    func toggleLike(postID: Post.ID) {
        guard case .loaded(var posts) = state,
              let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].toggleLike()
        state = .loaded(posts)    // ⚠️ SIN setState: no es un cambio de pantalla completa
        onPostUpdated?(index)     // solo avisamos qué fila cambió
    }

    // MARK: - Privado
    private func handle(_ result: Result<[Post], Error>) {
        setLoading(false)
        switch result {
        case .success(let posts):
            setState(posts.isEmpty ? .empty : .loaded(posts))
        case .failure(let error):
            print("❌ Feed:", error)
            setState(.failed(message: "No pudimos cargar el feed 🙁\nDesliza hacia abajo para reintentar."))
        }
    }

    /// Un solo lugar que cambia el estado Y avisa. Así nunca se te olvida avisar.
    private func setState(_ newState: State) {
        state = newState
        onStateChange?(newState)
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        onLoadingChange?(loading)
    }
}
```
> 💡 **¿Y el `@MainActor`?** Tu proyecto tiene **MainActor por defecto** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, Día 1), así que `FeedViewModel` ya está aislado al hilo principal sin escribirlo. Por eso sus tests llevan `@MainActor`. En Senior veremos cuándo un ViewModel **no** debería serlo.

Compara con tu `FeedViewController` del Día 7: `load`, `handle` y `toggleLike` son **casi idénticos**. Eso es buena señal: un refactor **mueve** código, no lo reinventa.

---

## 💻 Paso 2: `FeedViewController` adelgaza

📁 `Features/Feed/UI/FeedViewController.swift`. Son varios cambios; ve **en orden** y compila (⌘B) al final.

### 2.1 Dependencias y estado
**Borra**: `private let loader: FeedLoader`, el `enum State` completo, `private(set) var state`, `private var isLoading` y la propiedad calculada `posts`.
**Agrega** en su lugar:
```swift
    // MARK: - Dependencias
    /// La vista es DUEÑA del ViewModel (let). Sin `private`: los tests leen su estado.
    let viewModel: FeedViewModel
    private let imageLoader: ImageLoader
```

### 2.2 El init
```swift
    init?(coder: NSCoder, viewModel: FeedViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("Usa init(coder:viewModel:imageLoader:)")
    }
```

### 2.3 `viewDidLoad` y el binding
```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inicio"
        configureRefreshControl()
        bind()               // ⚠️ ANTES de load(): si no, el primer .loading no llega a nadie
        viewModel.load()
    }

    // MARK: - Binding (Concepto 3)
    /// [weak self] en las TRES (Concepto 5): el ViewModel guarda estas closures y nosotros lo guardamos a él.
    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onLoadingChange = { [weak self] isLoading in
            if !isLoading { self?.refreshControl?.endRefreshing() }
        }
        viewModel.onPostUpdated = { [weak self] index in
            self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
```

### 2.4 Refresh, `render` y like
- `refreshPulled()` ahora solo dice: `viewModel.load()`.
- **Borra** `loadFeed()`, `handle(_:)` y `toggleLike(postID:)`: ya viven en el ViewModel.
- `render` ya **no guarda** estado (lo hace el ViewModel). Cambia la firma y quita la línea `state = newState`:
```swift
    /// Traduce un estado a pantalla. Ya NO decide nada: solo dibuja lo que le dan.
    private func render(_ state: FeedViewModel.State) {
        switch state {
        case .loading:
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            tableView.backgroundView = spinner
        case .loaded:
            tableView.backgroundView = nil
        case .empty:
            tableView.backgroundView = makeMessageLabel("Aún no hay posts.\nSé el primero en publicar ✨")
        case .failed(let message):
            tableView.backgroundView = makeMessageLabel(message)
        }
        tableView.reloadData()
    }
```
> ✍️ Aprovecha: tu texto de vacío tenía `"Aun"`, `"Se"` y `"publica"`. Usa el de arriba.

### 2.5 DataSource
En `numberOfRowsInSection` y `cellForRowAt`, cambia `posts` por **`viewModel.posts`**, y el like:
```swift
        let post = viewModel.posts[indexPath.row]
        // …configure y loadAvatar sin cambios…
        cell.onLikeTapped = { [weak self] in
            self?.viewModel.toggleLike(postID: post.id)   // la vista solo REENVÍA el evento
        }
```
`loadAvatar` y `makeMessageLabel` **no cambian**.

---

## 💻 Paso 3: El router crea el ViewModel

📁 `App/AppRouter.swift`, en `makeFeedTab()`:
```swift
            FeedViewController(
                coder: coder,
                viewModel: FeedViewModel(loader: MockFeedLoader(delay: 1.5)),
                imageLoader: RemoteImageLoader()
            )
```
> 💡 El router **arma** las piezas (Día 5). Ni la vista ni el ViewModel saben de dónde vienen los posts: eso es **composición** en un solo lugar (en Mid se llamará *Composition Root*).

---

## ▶️ Paso 4: Compila (⌘B)
La **app** debe compilar. Los tests todavía no (usan el init viejo): los arreglas en el Paso 7.

## ▶️ Paso 5: Corre (⌘R)
Spinner → 4 posts → ❤️ funciona → pull to refresh funciona. **Igual que ayer.**

---

## ▶️ Paso 6: Experimentos (después del Paso 7, necesitan los tests)

### 6.1 📏 Mide otra vez
```bash
wc -l RoadmapSwift/Features/Feed/UI/FeedViewController.swift RoadmapSwift/Features/Feed/Presentation/FeedViewModel.swift
grep -c "func " RoadmapSwift/Features/Feed/UI/FeedViewController.swift
```
Anota antes/después. ¿Hay **menos** código en total? (Spoiler: no necesariamente. Pregunta 4.)

### 6.2 ⏱️ ¿Cuánto más rápidos?
Corre ⌘U, abre el **Report navigator** (⌘9) → el último *Test* → expande `FeedViewModelTests` y `FeedViewControllerTests`. Suma (aproximado) el tiempo de cada clase. Ambas tienen **13 tests**. ¿Cuántas veces más rápido es el ViewModel?

### 6.3 🔁 Dos ciclos, dos tests
1. En `FeedViewModel.load`, quita `[weak self]` y cambia `self?.handle` por `self.handle`. ⌘U: ¿qué tests fallan? (Son **dos**.) **Regrésalo.**
2. En `FeedViewController.bind`, quita `[weak self]` **solo** de `onStateChange` (`self.render`). ⌘U: ¿qué test falla? **Regrésalo.**
3. ¿Por qué en el punto 1 falla también un test **del ViewController**? (Pista: mira las dos últimas líneas de `test_feed_isReleasedFromMemory`.)

### 6.4 🧪 Comportamiento nuevo
En el router, `MockFeedLoader(fileName: "no_existe", delay: 1.5)`. Corre, espera el error y desliza: ¿qué spinners ves? Compáralo con el Concepto 4. **Regrésalo.**

---

## 🧪 Paso 7: Tests

### 7.1 📁 `NexoTests/Helpers/XCTestCase+MainQueue.swift` (nuevo)
Ahora **dos** clases de test necesitan `flushMainQueue()`. En lugar de copiarlo, lo compartimos (como `assertNoMemoryLeak`):
```swift
import XCTest

extension XCTestCase {
    /// Espera a que corra lo que ya estaba encolado en el hilo principal (Día 6).
    func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
}
```

### 7.2 📁 `NexoTests/Features/Feed/FeedViewModelTests.swift` (nuevo, 13 tests)
Fíjate en `makeSUT`: **una línea**, sin storyboard, sin tabla, sin `loadViewIfNeeded`.
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewModelTests: XCTestCase {

    // MARK: - Carga
    func test_init_doesNotRequestFeed() {
        let (_, loader) = makeSUT()
        XCTAssertEqual(loader.requestCount, 0)   // el ViewModel no carga solo: espera a que la vista se lo pida
    }

    func test_load_requestsFeedOnce() {
        let (sut, loader) = makeSUT()
        sut.load()
        XCTAssertEqual(loader.requestCount, 1)
    }

    func test_load_setsLoadingStateAndIsLoading() {
        let (sut, _) = makeSUT()
        sut.load()
        XCTAssertEqual(sut.state, .loading)
        XCTAssertTrue(sut.isLoading)
    }

    func test_loadCompletesWithPosts_setsLoaded() {
        let (sut, loader) = makeSUT()
        let posts = [Post.fixture(), Post.fixture()]
        sut.load()
        loader.complete(with: .success(posts))
        flushMainQueue()
        XCTAssertEqual(sut.state, .loaded(posts))   // ✅ ahora comparamos el estado EXACTO, no una tabla
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadCompletesWithNoPosts_setsEmpty() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertEqual(sut.state, .empty)
    }

    func test_loadFails_setsFailedAndStopsLoading() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        guard case .failed = sut.state else { return XCTFail("Se esperaba .failed, llegó \(sut.state)") }
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadCompletes_appliesOnlyAfterMainQueueRuns() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([.fixture()]))
        XCTAssertEqual(sut.state, .loading)   // todavía no: DispatchQueue.main.async es "más tarde"
        flushMainQueue()
        XCTAssertEqual(sut.posts.count, 1)
    }

    // MARK: - Refresh
    func test_load_whileLoading_doesNotRequestAgain() {
        let (sut, loader) = makeSUT()
        sut.load()
        sut.load()
        XCTAssertEqual(loader.requestCount, 1)
    }

    func test_refresh_keepsPostsVisibleWhileLoading() {
        let (sut, loader) = makeSUT()
        let posts = [Post.fixture()]
        sut.load()
        loader.complete(with: .success(posts), at: 0)
        flushMainQueue()

        sut.load()   // el refresh

        XCTAssertEqual(sut.state, .loaded(posts))   // Concepto 4: los posts NO desaparecen
        XCTAssertTrue(sut.isLoading)
    }

    func test_refreshCompletes_replacesPosts() {
        let (sut, loader) = makeSUT()
        sut.load()
        loader.complete(with: .success([.fixture()]), at: 0)
        flushMainQueue()

        sut.load()
        loader.complete(with: .success([.fixture(), .fixture()]), at: 1)
        flushMainQueue()

        XCTAssertEqual(sut.posts.count, 2)
    }

    // MARK: - Binding
    func test_onStateChange_reportsLoadingThenLoaded() {
        let (sut, loader) = makeSUT()
        let post = Post.fixture()
        var received: [FeedViewModel.State] = []
        sut.onStateChange = { received.append($0) }   // el TEST hace de "vista"

        sut.load()
        loader.complete(with: .success([post]))
        flushMainQueue()

        XCTAssertEqual(received, [.loading, .loaded([post])])
    }

    // MARK: - Likes
    func test_toggleLike_updatesPostAndNotifiesOnlyThatRow() throws {
        let (sut, loader) = makeSUT()
        let other = Post.fixture()
        let target = Post.fixture(likeCount: 3, isLikedByMe: false)
        var updatedRows: [Int] = []
        var stateChanges = 0
        sut.load()
        loader.complete(with: .success([other, target]))
        flushMainQueue()
        sut.onPostUpdated = { updatedRows.append($0) }
        sut.onStateChange = { _ in stateChanges += 1 }

        sut.toggleLike(postID: target.id)

        let updated = try XCTUnwrap(sut.posts.last)
        XCTAssertTrue(updated.isLikedByMe)
        XCTAssertEqual(updated.likeCount, 4)
        XCTAssertEqual(updatedRows, [1])     // solo la fila 1
        XCTAssertEqual(stateChanges, 0)      // y NO un redibujado completo
    }

    // MARK: - Memoria
    func test_load_doesNotRetainViewModel() {
        let (sut, _) = makeSUT()
        sut.load()                 // el spy GUARDA la closure (Concepto 5, segundo ciclo)
        assertNoMemoryLeak(sut)
    }

    // MARK: - Helpers
    private func makeSUT() -> (FeedViewModel, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedViewModel(loader: loader)
        return (sut, loader)
    }
}
```

### 7.3 `FeedViewControllerTests.swift`: reemplaza el archivo **completo** (13 tests)
La lógica ya se prueba en el ViewModel, así que aquí solo queda lo que es de **UIKit**: que la vista **dibuje** cada estado, que **reenvíe** eventos y las celdas/avatares.
- **Salen** (se mudaron al ViewModel): `rendersOnlyAfterMainQueueRuns`, `whileLoading_doesNotRequestAgain`, `refreshCompletes_replacesPosts`.
- **Entra**: `test_likeTapped_togglesLikeInViewModel`.
- **Borra** el `flushMainQueue` privado del final: ahora viene del helper 7.1.
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewControllerTests: XCTestCase {

    // MARK: - La vista dibuja cada estado
    func test_viewDidLoad_asksViewModelToLoad() throws {
        let (_, loader) = try makeSUT()
        XCTAssertEqual(loader.requestCount, 1)
    }

    func test_viewDidLoad_showsSpinner() throws {
        let (sut, _) = try makeSUT()
        XCTAssertTrue(sut.tableView.backgroundView is UIActivityIndicatorView)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
    }

    func test_loadCompletes_rendersOneRowPerPost() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture(), .fixture(), .fixture()]))
        flushMainQueue()
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 3)
        XCTAssertNil(sut.tableView.backgroundView)
    }

    func test_loadCompletesWithNoPosts_showsMessage() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
    }

    func test_loadFails_showsMessageAndNoRows() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
    }

    // MARK: - La vista reenvía eventos
    func test_pullToRefresh_asksViewModelToLoadAgain() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        flushMainQueue()

        sut.simulatePullToRefresh()

        XCTAssertEqual(loader.requestCount, 2)
    }

    func test_likeTapped_togglesLikeInViewModel() throws {
        let post = Post.fixture(isLikedByMe: false)
        let (sut, _) = try makeLoadedSUT(posts: [post])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))

        cell.onLikeTapped?()   // como si tocaran el ❤️

        XCTAssertEqual(sut.viewModel.posts.first?.isLikedByMe, true)
    }

    // MARK: - Celdas y memoria
    func test_cellForRow_returnsPostCell() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture(content: .text("Hola Nexo"))])
        XCTAssertNotNil(renderedCell(at: 0, in: sut))
    }

    func test_feed_isReleasedFromMemory() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture()])
        sut.tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
        assertNoMemoryLeak(sut.viewModel)   // ⚠️ los dos deben morir (Concepto 5)
    }

    // MARK: - Avatares (sin cambios respecto al Día 7)
    func test_cellForRow_requestsAuthorAvatar() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: url))])
        _ = renderedCell(at: 0, in: sut)
        XCTAssertEqual(imageLoader.requestedURLs, [url])
    }

    func test_cellForRow_withoutAvatarURL_doesNotRequestAndShowsPlaceholder() throws {
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: nil))])
        let cell = renderedCell(at: 0, in: sut)
        XCTAssertTrue(imageLoader.requestedURLs.isEmpty)
        XCTAssertNotNil(cell?.displayedAvatar)
    }

    func test_avatarLoaded_showsImageOnlyAfterMainQueueRuns() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [.fixture(author: .fixture(avatarURL: url))])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let image = UIImage()

        imageLoader.complete(with: image)
        XCTAssertFalse(cell.displayedAvatar === image)

        flushMainQueue()
        XCTAssertTrue(cell.displayedAvatar === image)
    }

    func test_avatarLoaded_afterCellWasReused_isIgnored() throws {
        let urlA = try XCTUnwrap(URL(string: "https://nexo.app/a.png"))
        let postA = Post.fixture(author: .fixture(avatarURL: urlA))
        let postB = Post.fixture(author: .fixture(avatarURL: nil))
        let (sut, imageLoader) = try makeLoadedSUT(posts: [postA])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let imageOfA = UIImage()

        cell.prepareForReuse()
        cell.configure(with: postB)
        imageLoader.complete(with: imageOfA, at: 0)
        flushMainQueue()

        XCTAssertEqual(imageLoader.cancelledURLs, [urlA])
        XCTAssertFalse(cell.displayedAvatar === imageOfA)
    }

    // MARK: - Helpers
    private func makeSUT(imageLoader: ImageLoader = ImageLoaderSpy()) throws -> (FeedViewController, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let viewModel = FeedViewModel(loader: loader)
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { coder in
            FeedViewController(coder: coder, viewModel: viewModel, imageLoader: imageLoader)
        })
        sut.loadViewIfNeeded()
        return (sut, loader)
    }

    private func makeLoadedSUT(posts: [Post]) throws -> (FeedViewController, ImageLoaderSpy) {
        let imageLoader = ImageLoaderSpy()
        let (sut, loader) = try makeSUT(imageLoader: imageLoader)
        loader.complete(with: .success(posts))
        flushMainQueue()
        return (sut, imageLoader)
    }

    private func renderedCell(at row: Int, in sut: FeedViewController) -> PostCell? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? PostCell
    }
}

private extension FeedViewController {
    func simulatePullToRefresh() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}
```
> ✍️ Ayer nombraste el helper `simulatedPullToRefresh`. Hoy usa `simulatePullToRefresh` (verbo en imperativo, como `flushMainQueue`).

### 7.4 Cuenta
```bash
grep -rc "func test" NexoTests | grep Feed
```
Debe dar `FeedViewModelTests: 13` y `FeedViewControllerTests: 13`. Total del proyecto: **77**.

---

## ▶️ Paso 8: Correr, revisar y hacer commit
1. **⌘U** → **77 tests** en verde. ⚠️ **Si hay uno en rojo, no hagas commit.**
2. Haz los experimentos del Paso 6 y **regresa** todo lo temporal.
3. Revisión:
   ```bash
   git status    # nuevos: Presentation/FeedViewModel.swift, FeedViewModelTests.swift, XCTestCase+MainQueue.swift
   git add .
   git --no-pager diff --staged
   ```
   Busca: `[weak self]` en las **cuatro** closures (3 en `bind` + 1 en `load`), `"no_existe"` en el router, `import UIKit` en el ViewModel, código comentado.
4. Commit y merge:
   ```bash
   git commit -m "refactor(feed): MVVM con FeedViewModel y binding por closures"
   git checkout main
   git merge feature/dia-08-mvvm
   ```

---

## ✅ Checklist del día
- [ ] `FeedViewModel` **sin** `import UIKit`
- [ ] La app se comporta igual que ayer (spinner, posts, ❤️, refresh)
- [ ] `FeedViewController` ya no tiene `loader`, `State`, `isLoading`, `loadFeed`, `handle` ni `toggleLike`
- [ ] Anotaste líneas antes/después (6.1) y tiempos de las dos clases de test (6.2)
- [ ] 6.3: anotaste qué tests fallan en cada caso
- [ ] 77 tests en verde **antes** del commit
- [ ] `diff --staged` revisado: sin `print` de experimentos, sin código comentado, `delay: 1.5` en el router

## 🔥 Reto extra (opcional, +5 puntos)
1. **Todos los textos al ViewModel.** Cambia `case empty` por `case empty(message: String)` y que el ViewModel ponga el texto. La vista ya no tendrá **ningún** String de contenido. Ajusta los tests.
2. **ViewModel sin `DispatchQueue`.** Que el ViewModel no sepa de hilos: crea `MainQueueFeedLoader: FeedLoader` que **envuelve** a otro loader y entrega el resultado en el principal (patrón **Decorator**). El router lo compone: `MainQueueFeedLoader(MockFeedLoader(delay: 1.5))`. Bonus: los tests del ViewModel ya no necesitan `flushMainQueue()`.
3. **Varios oyentes.** Reemplaza `onStateChange` por `func observe(_ handler: @escaping (State) -> Void)` que guarde **un array** de handlers. Test: dos oyentes reciben el mismo estado. (¿Qué problema de memoria aparece? Pregunta 5.)
4. **🟢 Adelanto de Mid.** Escribe 3 de los tests del ViewModel con **Swift Testing** (`import Testing`, `@Test`, `#expect`) en un archivo aparte y compara la sintaxis.

## 🧠 Preguntas de repaso (respóndelas antes del Día 9)
> 💡 **Cada parte en su propia línea.** Si no sabes, escribe lo que viste en el experimento. **Una respuesta en blanco vale 0.** (El Día 7 dejaste 2 en blanco y te costaron 10 puntos.)

1. Menciona **tres** cosas que se movieron al ViewModel y **dos** que se quedaron en el ViewController. ¿Por qué `loadAvatar` se quedó en la vista (por ahora)?
-Post, load y toggle, -Render y loadAvatar,
-Ya que la vista de la imagen esta en el ViewController
2. En el 6.3, ¿qué tests fallaron en cada caso? Dibuja las **dos** cadenas de referencias. ¿Por qué el test del ViewController falla en **ambos** casos?
3. ¿Por qué `toggleLike` cambia `state` **sin** pasar por `setState` y avisa con `onPostUpdated`? ¿Qué test lo comprueba y con qué dos `XCTAssert`?
4. Con tus números de 6.1 y 6.2: ¿cuántas líneas tienen ahora la vista y el ViewModel juntos, comparado con ayer? ¿Cuántas veces más rápidos son los tests del ViewModel? Entonces, ¿qué ganamos con MVVM si el código total no bajó?
5. ¿Qué pasa si **dos** objetos asignan `viewModel.onStateChange`? ¿Qué herramientas 🟤/🟢 resuelven tener varios oyentes? Si guardas un array de closures (reto 3), ¿qué riesgo de memoria aparece?

---
**Próximo (Día 9):** **CI con GitHub Actions**: subir el repo a GitHub, trabajar con **Pull Requests**, correr los 77 tests automáticamente en cada PR y **proteger `main`** para que no se pueda hacer merge con tests en rojo. (El **Coordinator** pasa al Día 10.)
