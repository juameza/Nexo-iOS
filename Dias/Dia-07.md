# 📅 Día 7: Carga asíncrona, estados de pantalla con `enum`, pull to refresh y el límite de MVC

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** pasar un `FeedLoader` **síncrono** (`throws`) a **asíncrono** con completion handler 🟤, retraso simulado con `DispatchQueue.global().asyncAfter`, **estados de pantalla con un `enum`** (cargando / contenido / vacío / error) vs un montón de `Bool`, `UIRefreshControl` + `#selector` (Target-Action por código), evitar **peticiones duplicadas**, `[weak self]` cuando el loader **guarda** la closure, un **spy** para el `FeedLoader`, y **MVC**: ¿cuánto sabe ya `FeedViewController`?

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Al abrir **Inicio** se ve un **spinner** ~1.5 s (simulando la red) y luego los posts.
2. Si falla, un mensaje de error; si no hay posts, un mensaje de "vacío".
3. **Pull to refresh**: deslizas hacia abajo y el feed se recarga, sin pedirlo dos veces si ya estaba cargando.
4. **8 tests nuevos**, para un total de **66**.

---

## 📚 Concepto 1: De síncrono a asíncrono

Hasta hoy:
```swift
posts = try loader.load()      // la línea siguiente ya tiene los posts
```
Eso solo funciona porque `feed.json` está **dentro de la app** y se lee en milisegundos. Con un servidor real (NexoServer, nivel Mid) la respuesta tarda **segundos**: si esperas en el hilo principal, la app se congela (Día 6, Concepto 1).

| | Síncrono (hasta ayer) | 🟤 Asíncrono con completion (hoy) | 🟢 `async/await` (nivel Mid) |
|---|---|---|---|
| Firma | `func load() throws -> [Post]` | `func load(completion: @escaping (Result<[Post], Error>) -> Void)` | `func load() async throws -> [Post]` |
| ¿Cuándo llegan los posts? | En la línea siguiente | **Después**, en la closure | En la línea siguiente… pero **sin bloquear** el hilo |
| ¿En qué hilo? | El tuyo | **Cualquiera** (hoy: fondo) | El que diga el actor |
| Errores | `try` / `catch` | `switch result` | `try` / `catch` |

> 💡 Fíjate en la columna 🟢: `async/await` se **lee** como el código síncrono, pero **se comporta** como el asíncrono. Por eso, cuando migremos, vas a valorar no tener que escribir closures.

Hoy el contrato `FeedLoader` cambia a la versión 🟤. `MockFeedLoader` conserva su `load() throws` (lo usan tus tests del Día 2) y **además** cumple el contrato nuevo, con un **retraso** para que veas el spinner.

---

## 📚 Concepto 2: Estados de pantalla con un `enum`

Con carga asíncrona, la pantalla puede estar en **4 situaciones**: cargando, con contenido, vacía o con error. La forma 🟤 "ingenua":
```swift
var isLoading = false
var posts: [Post] = []
var errorMessage: String?
```
¿Qué significa `isLoading == true` **y** `errorMessage != nil` **y** `posts` con 3 elementos? Nada. Con 3 variables hay **2 × 2 × 2 = 8** combinaciones, y solo 4 tienen sentido. Las otras 4 son **estados imposibles** que igual puedes crear por error.

La forma ✅: un `enum` con valores asociados (como `PostContent`, Día 2):
```swift
enum State: Equatable {
    case loading
    case loaded([Post])          // los posts SOLO existen cuando hay contenido
    case empty
    case failed(message: String) // el mensaje SOLO existe cuando hay error
}
```
Ahora es **imposible** tener "error con posts" o "cargando con mensaje de error": el compilador no te deja. Esta idea se llama **"make impossible states impossible"**, y la verás en todos los niveles (SwiftUI, TCA, el servidor…).

> ⚠️ Excepción honesta: hoy dejamos **una** variable aparte, `isLoading`. ¿Por qué? Durante un *pull to refresh* la pantalla **sigue mostrando los posts** (`.loaded`) mientras carga. "Hay contenido" y "hay una petición en curso" son dos cosas **independientes**. Lo resolveremos de forma más elegante con MVVM.

---

## 📚 Concepto 3: `UIRefreshControl` y Target-Action por código

`UITableViewController` ya tiene una propiedad `refreshControl`. Solo hay que crear uno y decirle **a quién avisar** cuando el usuario desliza:
```swift
let refresh = UIRefreshControl()
refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
refreshControl = refresh
```
Es **el mismo patrón** que tu `@IBAction` del Día 1 (Target-Action), pero escrito a mano en lugar de arrastrar en el storyboard:
| | Storyboard (Día 1) | Código (hoy) |
|---|---|---|
| Método | `@IBAction func …(_ sender:)` | `@objc func …()` |
| Conexión | Arrastrar con Ctrl | `addTarget(_:action:for:)` |
| Si el nombre está mal | Crash en runtime (`unrecognized selector`, Día 3 P5) | **Error de compilación**: `#selector` revisa que el método exista |

> 💡 `@objc`: `#selector` es tecnología de Objective-C 🟤. El método debe ser visible para ese runtime. En SwiftUI 🟢 esto será solo `.refreshable { await … }`.

### Peticiones duplicadas
Si el usuario desliza **mientras** la carga anterior no termina, pedirías el feed dos veces, y la respuesta más vieja podría llegar **después** y pisar a la nueva (parecido al bug de la imagen equivocada del Día 6). Hoy lo evitamos con un `guard !isLoading`.

---

## 📚 Concepto 4: ¿`[weak self]` otra vez? Depende de quién guarde la closure

```swift
loader.load { [weak self] result in
    DispatchQueue.main.async { self?.handle(result) }
}
```
- Con `MockFeedLoader` **no hay ciclo**: es un `struct` que **no guarda** la closure; solo se la pasa a GCD, que la suelta al terminar. Sin `weak`, el Feed simplemente viviría **de más** (Día 6, P4).
- Pero el Feed **es dueño** de su `loader` (`private let loader`). Si un loader **guarda** las closures (un spy, o un loader real que junta peticiones repetidas), entonces:
  ```
  Feed ──(let loader)──▶ loader ──(array de closures)──▶ closure ──(self strong)──▶ Feed   🔁
  ```
  ¡Ciclo! Y el Feed **no sabe** cómo es su loader por dentro (solo conoce el protocolo). Por eso, **ante la duda, `[weak self]`**. Lo comprobarás en el experimento 6.4.

---

## 📚 Concepto 5: MVC y el "Massive View Controller"

En MVC de Apple 🟤:
- **Model:** `Post`, `User`, `PostContent` (Día 2).
- **View:** `PostCell`, el storyboard.
- **Controller:** `FeedViewController`… que **cada día sabe más cosas**.

Al terminar hoy, `FeedViewController`:
1. Pide los posts al loader.
2. Regresa al hilo principal.
3. Decide el estado (cargando / vacío / error / contenido).
4. Elige textos de error y de vacío.
5. Maneja el pull to refresh y evita peticiones duplicadas.
6. Hace de DataSource de la tabla.
7. Pide los avatares y protege las celdas recicladas.
8. Maneja los likes.

Ocho responsabilidades en una clase. Eso es el famoso **Massive View Controller** (la broma: MVC = *Massive* View Controller). Y lo peor: los puntos 1–5 y 8 son **lógica**, pero para probarlos necesitas **cargar el storyboard** (`makeSUT`). En el experimento 6.5 lo vas a medir, y en los próximos días lo partimos con **MVVM**.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # solo deben aparecer Dias/Dia-07.md y ROADMAP.md (los agregué yo)
git checkout -b feature/dia-07-feed-states
```

---

## 💻 Paso 1: El contrato asíncrono

📁 `Features/Feed/Data/FeedLoader.swift`, cambia la firma del protocolo:
```swift
nonisolated protocol FeedLoader {
    /// 🟤 Completion handler. ⚠️ Como en `ImageLoader`, NO promete el hilo:
    /// quien llama regresa al principal si va a tocar la UI.
    func load(completion: @escaping @Sendable (Result<[Post], Error>) -> Void)
}
```
Si compilas ahora, verás errores en `MockFeedLoader` (ya no cumple el protocolo), en `FeedViewController` y en los tests. Los arreglas en los pasos siguientes.

---

## 💻 Paso 2: `MockFeedLoader` asíncrono y con retraso

📁 `Features/Feed/Data/MockFeedLoader.swift`. Agrega la propiedad `delay` y cambia el `init`:
```swift
    private let bundle: Bundle
    private let fileName: String
    /// Segundos de espera, para simular la red. 0 por defecto: los tests no esperan.
    private let delay: TimeInterval

    init(bundle: Bundle = .main, fileName: String = "feed", delay: TimeInterval = 0) {
        self.bundle = bundle
        self.fileName = fileName
        self.delay = delay
    }
```
Y **debajo** del `init`, el método que cumple el contrato nuevo (el `load() throws` de abajo **no se toca**):
```swift
    /// Cumple `FeedLoader`: hace el trabajo en un hilo de FONDO, después de `delay` segundos.
    func load(completion: @escaping @Sendable (Result<[Post], Error>) -> Void) {
        let loader = self   // copia del struct: la closure no captura nada mutable
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            // Result { try … }: convierte "devuelve o lanza" en .success / .failure
            completion(Result { try loader.load() })
        }
    }
```
> 💡 Dos métodos se llaman `load`, pero Swift los distingue por sus **parámetros**: `load()` y `load(completion:)`. Esto se llama **sobrecarga** (*overloading*).

---

## 💻 Paso 3: El estado en `FeedViewController`

📁 `Features/Feed/UI/FeedViewController.swift`.

### 3.1 Reemplaza `private(set) var posts: [Post] = []` por:
```swift
    // MARK: - Estado
    /// Make impossible states impossible (Concepto 2).
    enum State: Equatable {
        case loading
        case loaded([Post])
        case empty
        case failed(message: String)
    }

    /// private(set): los tests lo LEEN, pero solo el Feed lo cambia (en render y toggleLike).
    private(set) var state: State = .loading
    /// Independiente del estado: durante un refresh se ven los posts Y hay una petición en curso.
    private var isLoading = false

    /// Atajo para el DataSource: los posts solo existen en `.loaded`.
    private var posts: [Post] {
        if case .loaded(let posts) = state { return posts }
        return []
    }
```
> 💡 `posts` ahora es una **propiedad calculada** (como `handle` en `User`, Día 2): no guarda nada, se deriva de `state`. Así **no pueden desincronizarse**. `numberOfRowsInSection` y `cellForRowAt` siguen usando `posts` sin cambios.

### 3.2 En `viewDidLoad`, antes de `loadFeed()`:
```swift
        configureRefreshControl()
```

### 3.3 Reemplaza `loadFeed()` y `toggleLike(postID:)` completos por:
```swift
    // MARK: - Datos
    private func configureRefreshControl() {
        let refresh = UIRefreshControl()
        // Target-Action por código (Concepto 3). #selector revisa EN COMPILACIÓN que el método exista.
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        refreshControl = refresh   // UITableViewController ya sabe dónde ponerlo
    }

    @objc private func refreshPulled() {
        loadFeed()
    }

    private func loadFeed() {
        guard !isLoading else { return }   // ya hay una petición en curso: no pedir dos veces
        isLoading = true
        // En la primera carga: spinner grande. En un refresh: ya se ve el spinner del refreshControl.
        if refreshControl?.isRefreshing != true {
            render(.loading)
        }
        // [weak self] (Concepto 4): no sabemos si el loader guarda la closure.
        loader.load { [weak self] result in
            // 🟤 Llega en un hilo de fondo → al principal para tocar la UI (Día 6).
            DispatchQueue.main.async {
                self?.handle(result)
            }
        }
    }

    private func handle(_ result: Result<[Post], Error>) {
        isLoading = false
        refreshControl?.endRefreshing()   // ⚠️ si lo olvidas, el spinner del refresh gira para siempre
        switch result {
        case .success(let posts):
            render(posts.isEmpty ? .empty : .loaded(posts))
        case .failure(let error):
            print("❌ Feed:", error)
            render(.failed(message: "No pudimos cargar el feed 🙁\nDesliza hacia abajo para reintentar."))
        }
    }

    /// El ÚNICO lugar que traduce un estado a pantalla.
    private func render(_ newState: State) {
        state = newState
        switch newState {   // sin `default`: si mañana agregas un caso, el compilador te avisa aquí
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
        tableView.reloadData()   // 🟤 Vuelve a preguntar TODO. En Mid: diffable (solo lo que cambió)
    }

    // Buscamos por id y NO por indexPath (Día 4, P5).
    private func toggleLike(postID: Post.ID) {
        // `guard case`: solo hay likes si hay contenido. `var posts`: una COPIA que sí podemos mutar.
        guard case .loaded(var posts) = state,
              let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].toggleLike()
        state = .loaded(posts)   // structs: modificamos la copia y la guardamos de vuelta
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
```
> 💡 `toggleLike` no llama a `render`: solo cambia **una fila**, no toda la pantalla. `render` es para cambios de **estado**.

---

## 💻 Paso 4: El router simula la red
En `AppRouter.makeFeedTab()`:
```swift
            FeedViewController(coder: coder, loader: MockFeedLoader(delay: 1.5), imageLoader: RemoteImageLoader())
```

---

## ▶️ Paso 5: Compila la app (⌘B)
La **app** debe compilar sin errores. Los **tests** todavía no (usan el contrato viejo): los arreglas en el Paso 7.

---

## ▶️ Paso 6: Pruébalo y haz los experimentos (⌘R)

### 6.1 Funcionalidad
1. Inicia sesión → **Inicio**: spinner ~1.5 s, luego los 4 posts.
2. Desliza hacia abajo: aparece el spinner de arriba, ~1.5 s, y se oculta solo.

3. Dale ❤️ a un post y haz pull to refresh. ¿El like se conserva? Anótalo para la pregunta 4.
si hago refresh NO se mantiene, 

### 6.2 🧪 El estado de error
En el router, cambia temporalmente a `MockFeedLoader(fileName: "no_existe", delay: 1.5)`. Corre: spinner → mensaje de error. Desliza hacia abajo: ¿qué pasa? **Regrésalo.**
NO pasa nada, sigue mandando el mensaje de error.

### 6.3 🧪 Peticiones duplicadas
1. En `loadFeed`, **después** del `guard`, agrega temporalmente `print("📥 pidiendo el feed")`.
2. Corre, y haz pull to refresh **dos veces muy rápido** (antes de que pasen 1.5 s). ¿Cuántas veces se imprime?
Se imprime una sola vez
3. Comenta el `guard !isLoading else { return }` y repítelo. ¿Cuántas ahora? **Regrésalo y borra el `print`.**
Solo una vez

### 6.4 🧪 ¿Ciclo o no ciclo?
Este se hace **después** del Paso 7 (necesita los tests).
1. En `loadFeed`, quita temporalmente el `[weak self]` y cambia `self?.handle` por `self.handle`.
2. Corre la app y cierra sesión: ¿sale `♻️ FeedViewController liberado` en la consola?
3. Corre **⌘U**: ¿qué test falla?
4. Con el Concepto 4 en mente: ¿por qué la app libera el Feed pero el test detecta un leak? (pregunta 3). **Regrésalo.**

### 6.5 🧪 Mide el Massive View Controller
En Terminal:
```bash
wc -l RoadmapSwift/Features/Feed/UI/FeedViewController.swift
grep -c "func " RoadmapSwift/Features/Feed/UI/FeedViewController.swift
```
Anota ambos números. Luego, al lado de cada método de `FeedViewController`, piensa: ¿es **UI** (tocar vistas) o **lógica** (decidir qué mostrar)? Lo usarás en la pregunta 5 y en el Día 8.

---

## 🧪 Paso 7: Tests

### 7.1 📁 `NexoTests/Helpers/FeedLoaderSpy.swift` (nuevo)
```swift
import Foundation
@testable import RoadmapSwift

/// SPY del FeedLoader: no carga nada. Guarda cada petición y el TEST decide
/// cuándo y con qué "contesta" (igual que ImageLoaderSpy, Día 6).
final class FeedLoaderSpy: FeedLoader {
    private var completions: [@Sendable (Result<[Post], Error>) -> Void] = []

    /// Cuántas veces nos pidieron el feed.
    var requestCount: Int { completions.count }

    func load(completion: @escaping @Sendable (Result<[Post], Error>) -> Void) {
        completions.append(completion)
    }

    /// Simula que llegó la respuesta de la petición número `index`.
    func complete(with result: Result<[Post], Error>, at index: Int = 0) {
        completions[index](result)
    }
}
```
> ⚠️ Fíjate: este spy **guarda** las closures. Eso es justo lo que crea el ciclo del Concepto 4.

### 7.2 `FeedViewControllerTests.swift`: reemplaza el archivo **completo**
Los tests de ayer asumían que los posts estaban listos al terminar `viewDidLoad`. Ya no: ahora llegan **después**. Por eso cambia el helper y se reorganiza todo. Borra el `FeedLoaderStub` del final (ya no cumple el protocolo; lo reemplaza el spy).
```swift
import XCTest
@testable import RoadmapSwift

@MainActor
final class FeedViewControllerTests: XCTestCase {

    // MARK: - Carga y estados
    func test_viewDidLoad_requestsFeedOnce() throws {
        let (_, loader) = try makeSUT()
        XCTAssertEqual(loader.requestCount, 1)
    }

    func test_viewDidLoad_showsLoadingUntilLoaderCompletes() throws {
        let (sut, _) = try makeSUT()
        XCTAssertEqual(sut.state, .loading)
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

    func test_loadCompletesWithNoPosts_showsEmptyState() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([]))
        flushMainQueue()
        XCTAssertEqual(sut.state, .empty)
        XCTAssertTrue(sut.tableView.backgroundView is UILabel)
    }

    func test_loadFails_showsErrorAndNoRows() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .failure(FeedLoaderError.fileNotFound("x")))
        flushMainQueue()
        // `guard case`: no nos importa el texto exacto, solo que sea .failed
        guard case .failed = sut.state else { return XCTFail("Se esperaba .failed, llegó \(sut.state)") }
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 0)
    }

    func test_loadCompletes_rendersOnlyAfterMainQueueRuns() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        XCTAssertEqual(sut.state, .loading)   // todavía no: DispatchQueue.main.async es "más tarde"
        flushMainQueue()
        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 1)
    }

    // MARK: - Pull to refresh
    func test_pullToRefresh_requestsFeedAgain() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]))
        flushMainQueue()

        sut.simulatePullToRefresh()

        XCTAssertEqual(loader.requestCount, 2)
    }

    func test_pullToRefresh_whileLoading_doesNotRequestAgain() throws {
        let (sut, loader) = try makeSUT()   // la primera carga NO ha terminado

        sut.simulatePullToRefresh()

        XCTAssertEqual(loader.requestCount, 1)
    }

    func test_refreshCompletes_replacesPosts() throws {
        let (sut, loader) = try makeSUT()
        loader.complete(with: .success([.fixture()]), at: 0)
        flushMainQueue()

        sut.simulatePullToRefresh()
        loader.complete(with: .success([.fixture(), .fixture()]), at: 1)
        flushMainQueue()

        XCTAssertEqual(sut.tableView.numberOfRows(inSection: 0), 2)
    }

    // MARK: - Celdas y memoria
    func test_cellForRow_returnsPostCell() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture(content: .text("Hola Nexo"))])
        XCTAssertNotNil(renderedCell(at: 0, in: sut))
    }

    func test_feed_isReleasedFromMemory() throws {
        let (sut, _) = try makeLoadedSUT(posts: [.fixture()])
        // Tamaño + layout: la TABLA crea y guarda sus celdas (cadena tabla → celda → closure, Día 4)
        sut.tableView.frame = CGRect(x: 0, y: 0, width: 390, height: 800)
        sut.tableView.layoutIfNeeded()
        XCTAssertEqual(sut.tableView.visibleCells.count, 1)
        assertNoMemoryLeak(sut)
    }

    // MARK: - Avatares
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

    /// 🐛 El bug de la imagen equivocada (Día 6, Concepto 4).
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

        XCTAssertEqual(imageLoader.cancelledURLs, [urlA])   // defensa #1
        XCTAssertFalse(cell.displayedAvatar === imageOfA)   // defensa #2
    }

    // MARK: - Helpers
    /// El Feed recién cargado: la petición está HECHA pero NO contestada.
    private func makeSUT(imageLoader: ImageLoader = ImageLoaderSpy()) throws -> (FeedViewController, FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { coder in
            FeedViewController(coder: coder, loader: loader, imageLoader: imageLoader)
        })
        sut.loadViewIfNeeded()
        return (sut, loader)
    }

    /// El Feed ya mostrando `posts`: para los tests de celdas y avatares.
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

    /// Espera a que corra lo que ya estaba encolado en el hilo principal (Día 6).
    private func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
}

/// Simula el gesto: el refreshControl "dispara" su evento como si el usuario deslizara.
private extension FeedViewController {
    func simulatePullToRefresh() {
        refreshControl?.sendActions(for: .valueChanged)
    }
}
```
> 💡 Los 8 tests de ayer **siguen** (con nombres y helpers actualizados); los nuevos son 7: `requestsFeedOnce`, `showsLoadingUntilLoaderCompletes`, `showsEmptyState`, `rendersOnlyAfterMainQueueRuns` y los 3 de pull to refresh.

### 7.3 `MockFeedLoader` asíncrono
En `NexoTests/Core/Models/PostDecodingTests.swift`, debajo de `test_mockFeedLoader_missingFile_throwsFileNotFound`:
```swift
    func test_mockFeedLoader_loadWithCompletion_deliversPostsOffMainThread() {
        let exp = expectation(description: "completion")

        MockFeedLoader().load { result in
            XCTAssertFalse(Thread.isMainThread)   // por eso el Feed usa DispatchQueue.main.async
            XCTAssertEqual((try? result.get())?.count, 4)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)   // sin esto, el test terminaría ANTES de que llegue la respuesta
    }
```
> 💡 `expectation` + `wait`: la forma 🟤 de XCTest para probar código asíncrono. En el Día 6 viste la 🟢 (`async` + `withCheckedContinuation`).

### 7.4 🧪 Comprueba que los tests sirven
1. Comenta `guard !isLoading else { return }`. Corre ⌘U: ¿qué test falla? Regrésalo.
2. Haz el experimento 6.4.

---

## ▶️ Paso 8: Correr, revisar y hacer commit
1. **⌘U** → deben pasar **66 tests**. Si no te da 66: `grep -rc "func test" NexoTests` y compara con la guía (lección del Día 6). ⚠️ **Si hay uno en rojo, no hagas commit.**
2. **⌘R** → repite el Paso 6.1.
3. Revisión:
   ```bash
   git status                        # nuevo: NexoTests/Helpers/FeedLoaderSpy.swift
   git add .
   git --no-pager diff --staged      # busca: el print del 6.3, un guard comentado, "no_existe" en el router, [weak self] faltante
   ```
4. Commit y merge:
   ```bash
   git commit -m "feat(feed): carga asíncrona, estados con enum y pull to refresh"
   git checkout main
   git merge feature/dia-07-feed-states
   ```

---

## ✅ Checklist del día
- [✅] Spinner al abrir Inicio y luego los posts
- [✅] Pull to refresh recarga y el spinner de arriba se oculta solo
- [✅] Con `"no_existe"` se ve el mensaje de error (6.2)
- [✅] Con el `guard`, dos refresh rápidos piden el feed **una** vez (6.3)
- [✅] Sin `[weak self]` falla el test de memoria (6.4)
- [✅] Anotaste líneas y número de funciones de `FeedViewController` (6.5)
- [✅] 66 tests en verde **antes** del commit
- [✅] `git --no-pager diff --staged` sin `print`, sin código comentado y con `delay: 1.5` en el router

## 🔥 Reto extra (opcional, +5 puntos)
1. **Estado vacío de verdad.** Crea `Resources/Mocks/feed_empty.json` con `{ "posts": [] }`, úsalo en el router y comprueba el mensaje de vacío. Escribe un test con `MockFeedLoader(fileName: "feed_empty")` + `expectation`.
2. **No pierdas el contenido.** Hoy, si un *refresh* falla, desaparecen los posts que ya se veían. Cámbialo: si ya había posts, consérvalos y muestra el error con un `UIAlertController` (o un banner). Test incluido.
3. **Botón "Reintentar".** En el estado de error, en lugar de solo un `UILabel`, muestra un `UIStackView` con el mensaje y un `UIButton` (con `UIAction` 🟢, sin `#selector`) que llame a `loadFeed()`.
4. **🟢 Adelanto.** Escribe `extension FeedLoader { func load() async throws -> [Post] }` con `withCheckedThrowingContinuation` y úsalo en un test `async`.

## 🧠 Preguntas de repaso (respóndelas antes del Día 8)
> 💡 Contesta **cada parte en su propia línea**. Si no sabes, escribe lo que viste en el experimento. **Una respuesta en blanco vale 0.**

1. ¿Por qué el `enum State` es mejor que tener `isLoading`, `posts` y `errorMessage` por separado? Da un ejemplo de un **estado imposible** que el `enum` evita. ¿Por qué aun así dejamos `isLoading` aparte?
Se usan los enum, para que sean tipo constantes globales, los cuales podemos manipular mejor, y no estar poniendo en cada vista variables que no se usan, un ejemplo de estado imposible es que se pueda tener un error y a la vez tener posts, y dejamos isLoading aparte porque es una variable que se puede cambiar en cualquier momento, y no depende del estado de la vista.
2. En el experimento 6.3, ¿cuántas veces se imprimió con el `guard` y cuántas sin él? ¿Qué bug podría aparecer si llegan dos respuestas en desorden?
- en ambos caso se imprimio 1 vez, o no se si me ganaba el proceso
- que se repita informacion o se coloque informacion en diferentes ordenes, y que se pierda informacion
3. En el experimento 6.4, ¿la app liberó el Feed? ¿Qué test falló? ¿Por qué con `MockFeedLoader` **no** hay ciclo y con `FeedLoaderSpy` **sí**? Dibuja la cadena.
4. En el 6.1, ¿se conservó el ❤️ después del refresh? ¿Por qué? (Pista: ¿de dónde vienen los posts en cada carga?) ¿Quién debería guardar el like en una app real?
- No se conservo el like, porque los posts vienen del loader, y el loader no guarda el estado de los likes, 
- en una app real el like lo deberia guardar en la base de datos o en el servidor.
5. Con lo que mediste en 6.5: menciona **tres** responsabilidades de `FeedViewController` que **no** son de UI. ¿Qué problema tienen hoy para probarse?

---
**Próximo (Día 8):** **MVVM** 🟤→🟢: sacamos la lógica del Feed a un `FeedViewModel` que se prueba **sin storyboard**, binding con closures, y la comparación MVC vs MVVM con números (líneas, tests, tiempo de los tests).
