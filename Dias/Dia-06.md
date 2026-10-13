# 📅 Día 6: Red con `URLSession` y completion handlers, hilos con GCD y el bug de la imagen equivocada

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** `URLSession.dataTask` con **completion handlers** 🟤, `resume()`, validar `HTTPURLResponse`, **hilo principal** y `DispatchQueue.main.async` 🟤 (vs `@MainActor` / `async-await` 🟢), `[weak …]` en closures **asíncronas**, el bug clásico de la **imagen equivocada en una celda reciclada**, cancelar tareas, `NSCache`, `nonisolated`, y testing de red **sin internet**: *spy*, `URLProtocol` stub 🟤 y un adelanto de `withCheckedContinuation` 🟢.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Cada post del Feed muestra el **avatar** de su autor, descargado de internet, redondo y con un *placeholder* mientras carga (o si el autor no tiene foto).
2. Un `RemoteImageLoader` que descarga, **valida** la respuesta y guarda las imágenes en **caché**.
3. Las celdas **cancelan** su descarga al reciclarse y **nunca** muestran la imagen de otro post.
4. **8 tests nuevos**, para un total de **58**, que corren **sin internet**. Uno de ellos **falla** si quitas la protección contra la imagen equivocada.

---

## 📚 Concepto 1: El hilo principal

Una app tiene varios **hilos** (threads) trabajando a la vez. Uno es especial: el **hilo principal** (*main thread*).
- **Toda la UI se toca SOLO en el hilo principal**: `label.text`, `imageView.image`, `reloadData()`… UIKit no es *thread-safe*.
- **Nada lento en el hilo principal**: si descargas una imagen ahí, la app se congela (no hace scroll, no responde toques).

Por eso el trabajo lento (red, disco, decodificar) va a **otro hilo**, y el resultado **regresa** al principal para pintarse:
```
Hilo principal:  cellForRowAt ──▶ pide la imagen ─────────── (sigue haciendo scroll) ────────── ▶ cell.setAvatar(img) ✅
                                       │                                                    ▲
Hilo de fondo:                         └──▶ URLSession descarga… valida… UIImage(data:) ────┘ DispatchQueue.main.async
```

### 🟤 Viejo vs 🟢 nuevo: "regresar al hilo principal"
| | 🟤 GCD (Grand Central Dispatch) — **hoy** | 🟢 Swift Concurrency (nivel Mid/Senior) |
|---|---|---|
| Ir al principal | `DispatchQueue.main.async { … }` | Código marcado `@MainActor` (o `await MainActor.run { … }`) |
| Trabajo en fondo | `DispatchQueue.global().async { … }` | `async` func, `Task { }`, actors |
| ¿Quién detecta el error de hilo? | **En runtime**: el *Main Thread Checker* pinta un aviso morado 🟣 (si tienes suerte) | **El compilador**, antes de correr (tu proyecto ya usa `MainActor` por defecto: lo verás en el experimento 7.3) |
| Resultado | Completion handler `(Result<T, Error>) -> Void` | `let img = try await loader.loadImage(from: url)` |

> 💡 GCD sigue en millones de líneas de código (y en entrevistas). Hoy lo usas para **entender el problema**; cuando migremos a `async/await` vas a apreciar lo que el compilador hace por ti.

---

## 📚 Concepto 2: `URLSession` con completion handler 🟤

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    // ⚠️ Esto corre en un hilo de FONDO, y MÁS TARDE (cuando llega la respuesta).
}
task.resume()   // ⚠️ Sin resume() la descarga NUNCA empieza (bug clásico: no hay error, solo silencio).
```
El completion recibe **tres opcionales**, y hay que revisarlos en orden:
| Parámetro | Qué es | Cuándo viene |
|---|---|---|
| `error` | Falló el **transporte**: sin internet, timeout, cancelado | Si no hubo respuesta |
| `response` | La respuesta HTTP (`as? HTTPURLResponse` → `statusCode`) | Si el servidor contestó |
| `data` | El cuerpo (los bytes de la imagen) | Si el servidor contestó |

> ⚠️ **Un 404 o un 500 NO es `error`.** Para `URLSession` el servidor *sí contestó*, así que `error` es `nil`. Por eso **tú** validas `statusCode` en `200..<300`. Olvidarlo es otro bug clásico: intentas convertir una página de error HTML en imagen.

### `Result` en lugar de 3 opcionales
Nuestro loader convierte esos tres opcionales en algo imposible de malinterpretar: **`Result<UIImage, Error>`** (lo viste en el Día 1). O hay imagen, o hay error; nunca los dos, nunca ninguno.

---

## 📚 Concepto 3: `[weak …]` en closures asíncronas

En el Día 4 usaste `[weak self]` para romper un **ciclo** (Feed → tabla → celda → closure → Feed).
En una closure **asíncrona** normalmente **no hay ciclo**: `URLSession` guarda la closure solo hasta que termina la descarga y luego la suelta. Entonces, ¿para qué `weak`?

**Para no alargar la vida de algo que ya no se necesita.** Si la closure captura la celda con `strong`:
- La celda (y todo lo que retiene) sigue viva hasta que termine la descarga, aunque el usuario ya se haya ido del Feed.
- Y cuando llega la imagen, la pintas en una celda que **ya nadie ve**.

Con `[weak cell]`, si la celda ya no existe, `guard let cell else { return }` y listo.

| | Ciclo (Día 4) | Closure asíncrona (hoy) |
|---|---|---|
| ¿Hay leak permanente? | **Sí**, nunca se libera | No, se libera al terminar la descarga |
| Problema sin `weak` | Memoria perdida | Objetos que viven **de más** y trabajo inútil |
| Solución | `[weak self]` | `[weak cell]` / `[weak self]` + `guard let` |

---

## 📚 Concepto 4: 🐛 El bug de la imagen equivocada

Recuerda el Día 4: hay unas 8–10 celdas que se **reciclan**. Ahora imagina red lenta:
```
t=0s   La celda #3 muestra el post de ANA  → pide avatar de Ana (tarda 2 s)
t=1s   Haces scroll: la celda #3 se recicla y ahora muestra el post de LUIS → pide avatar de Luis
t=1.2s Llega el avatar de Luis → celda #3 = Luis ✅
t=2s   Llega TARDE el avatar de Ana → celda #3 = Ana ❌  (el post dice "Luis" con la foto de Ana)
```
Es uno de los bugs más famosos de iOS. Dos defensas, y hoy usas **las dos**:
1. **Cancelar** la descarga vieja en `prepareForReuse()` → ahorra datos y batería. Pero no basta: la respuesta puede **ya venir en camino** cuando cancelas.
2. **Verificar la identidad** antes de pintar: la celda recuerda a qué post representa (`representedPostID`); si cuando llega la imagen ya representa a **otro**, se ignora. **Esta** es la que garantiza que nunca se vea la foto equivocada.

> 💡 ¿Por qué comparar el **id del post** y no la **URL**? Mira `feed.json`: el post 1 y el post 4 son del mismo autor, con la **misma** URL de avatar. Comparar por URL funcionaría en este caso, pero el `id` es la identidad real de lo que muestra la celda (la misma idea de `toggleLike` en el Día 4, P5).

---

## 📚 Concepto 5: Caché y testing de red

### `NSCache` 🟤
Un diccionario `[NSURL: UIImage]` que **se vacía solo** si el sistema necesita memoria, y que es **seguro de usar desde varios hilos**. Si el avatar de Mario ya se descargó, no se vuelve a pedir.
| | 🟤 Hoy | 🟢 / más adelante |
|---|---|---|
| Caché en memoria | `NSCache` | Un `actor` propio con política LRU (nivel Senior) |
| Caché en disco | `URLCache` (HTTP) | Igual, o librerías como Kingfisher/Nuke (y por qué no las usamos aún) |
| SwiftUI | – | `AsyncImage(url:)` (sin caché propia; lo verás al migrar) |

### Tests que **no** usan internet
Un test que usa internet es lento, falla sin wifi y depende de un servidor ajeno. Dos técnicas:
| Técnica | Qué reemplaza | Para probar |
|---|---|---|
| **Spy** (`ImageLoaderSpy`) | Todo el loader (gracias al **protocolo** `ImageLoader`, igual que el stub del Día 4) | El **Feed**: qué URLs pidió, qué canceló, qué pasa cuando "llega" la imagen **cuando el test decide** |
| **`URLProtocol` stub** 🟤 | Solo la **red**: `URLSession` es real, pero las respuestas las inventa el test | El **`RemoteImageLoader`**: que valide 404, datos corruptos, sin internet… |

> 💡 **Stub vs Spy:** un *stub* (Día 4) **devuelve** lo que el test quiere. Un *spy* además **anota** lo que le pidieron, para que el test lo revise. Ambos son *test doubles*.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout main
git status            # solo deben aparecer Dias/Dia-06.md y ROADMAP.md (los agregué yo)
git checkout -b feature/dia-06-avatars
```

---

## 💻 Paso 1: El contrato `ImageLoader`

📁 Crea la carpeta `Core/Networking` y dentro `ImageLoader.swift`:
```swift
import UIKit

/// Algo que se puede cancelar: una descarga en curso.
/// `nonisolated`: tu proyecto pone TODO en el MainActor por defecto; la red NO debe vivir ahí.
nonisolated protocol ImageLoadTask {
    func cancel()
}

/// Contrato "algo que sabe traer una imagen". El Feed depende de ESTO (como `FeedLoader`, Día 4):
/// la app usa `RemoteImageLoader` y los tests un spy.
nonisolated protocol ImageLoader {
    /// 🟤 Completion handler. ⚠️ NO promete en qué hilo se llama `completion`: quien llama
    /// debe regresar al hilo principal si va a tocar la UI.
    /// `@escaping`: la closure se guarda y se llama DESPUÉS de que este método ya terminó.
    /// `@Sendable`: se puede llamar desde otro hilo (Swift lo revisa por ti).
    @discardableResult
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask
}

/// `URLSessionDataTask` ya tiene `cancel()`, así que cumple el contrato sin escribir nada.
nonisolated extension URLSessionDataTask: ImageLoadTask {}

nonisolated enum ImageLoaderError: Error, Equatable {
    /// El servidor contestó, pero con un código que no es 2xx (404, 500…).
    case invalidResponse(statusCode: Int)
    /// Llegaron bytes, pero no son una imagen.
    case invalidImageData
}
```
> 💡 `@discardableResult`: quien llama puede ignorar la tarea devuelta sin que Xcode muestre el warning *"Result of call is unused"*.

---

## 💻 Paso 2: `RemoteImageLoader`

📁 `Core/Networking/RemoteImageLoader.swift`
```swift
import UIKit

/// Descarga imágenes con URLSession 🟤 (completion handlers) y las guarda en NSCache.
nonisolated final class RemoteImageLoader: ImageLoader {
    /// Inyectada: la app usa `.shared` y los tests una sesión con URLProtocolStub (Paso 8.4).
    private let session: URLSession
    /// 🟤 NSCache: se vacía sola si falta memoria y se puede usar desde varios hilos.
    private let cache = NSCache<NSURL, UIImage>()

    init(session: URLSession = .shared) {
        self.session = session
    }

    @discardableResult
    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask {
        // 1. ¿Ya la teníamos? Respuesta inmediata, sin red.
        //    ⚠️ Aquí `completion` se llama YA (síncrono) y en la descarga se llama DESPUÉS (asíncrono).
        //    Por eso quien llama siempre debe usar DispatchQueue.main.async: así funciona en ambos casos.
        if let cached = cache.object(forKey: url as NSURL) {
            completion(.success(cached))
            return CompletedTask()
        }

        // Copiamos la caché a una constante local para no capturar `self` en la closure.
        let cache = self.cache
        let task = session.dataTask(with: url) { data, response, error in
            // ⚠️ Esto corre en un hilo de FONDO.
            // 2. Error de transporte: sin internet, timeout o CANCELADA (prepareForReuse).
            if let error {
                completion(.failure(error))
                return
            }
            // 3. Un 404/500 NO llega como `error`: hay que revisar el statusCode a mano.
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ImageLoaderError.invalidResponse(statusCode: -1)))
                return
            }
            guard (200..<300).contains(http.statusCode) else {
                completion(.failure(ImageLoaderError.invalidResponse(statusCode: http.statusCode)))
                return
            }
            // 4. Los bytes tienen que ser una imagen de verdad.
            guard let data, let image = UIImage(data: data) else {
                completion(.failure(ImageLoaderError.invalidImageData))
                return
            }
            cache.setObject(image, forKey: url as NSURL)
            completion(.success(image))
        }
        task.resume()   // ⚠️ Sin esto la descarga nunca empieza (experimento 7.4).
        return task
    }
}

/// Para el caso de la caché: no hay nada que cancelar.
private nonisolated struct CompletedTask: ImageLoadTask {
    func cancel() {}
}
```

---

## 🎨 Paso 3: El avatar en `Feed.storyboard`

Queremos esto en la celda:
```
┌──────────────────────────────────────┐
│ (👤)  Mario ✓                        │  ← Stack HORIZONTAL: avatar + stack vertical (nombre, meta)
│       @mario · hace 2 h              │
│ Hola Nexo…                           │  ← el contenido y el ❤️ siguen como estaban
│ ♡ 12                                 │
└──────────────────────────────────────┘
```
1. Abre `Feed.storyboard`. En la celda `PostCell`, selecciona **Nombre** y **meta** (⌘ + clic en el Document Outline) → botón **Embed In** (abajo a la derecha) → **Stack View**. Ponle **Axis: Vertical**, **Spacing: 2**.
2. Arrastra un **Image View** de la Library (⇧⌘L) y suéltalo **dentro** del stack principal, justo **arriba** del stack que acabas de crear.
3. Selecciona el Image View y el stack nuevo (nombre + meta) → **Embed In → Stack View**. Ponle **Axis: Horizontal**, **Alignment: Center**, **Spacing: 12**.
4. Al Image View dale **Add New Constraints** (el botón ⊢◻⊣): **Width 40** y **Height 40**. En el Attributes Inspector: **Content Mode: Aspect Fill**. Y en **Image** escribe `person.crop.circle.fill` (así se ve algo en el storyboard).
5. Conecta el outlet (Paso 4.1) arrastrando desde el círculo del outlet hasta el Image View.

> ⚠️ Si el Image View queda en el stack **vertical** principal, el stack lo estira a todo el ancho y la constraint de 40 choca: en la consola verás *"Unable to simultaneously satisfy constraints"*. Por eso va en un stack **horizontal**.

---

## 💻 Paso 4: `PostCell` sabe mostrar (y olvidar) un avatar

En `PostCell.swift`:

### 4.1 Outlet y estado (debajo de `likeButton`)
```swift
    @IBOutlet private weak var avatarImageView: UIImageView!

    /// Se muestra mientras carga, si falla, o si el autor no tiene foto.
    private static let avatarPlaceholder = UIImage(systemName: "person.crop.circle.fill")

    /// A qué post representa la celda AHORA. Defensa #2 contra la imagen equivocada (Concepto 4).
    /// private(set): el Feed lo LEE, pero solo la celda lo cambia (en configure y prepareForReuse).
    private(set) var representedPostID: Post.ID?

    /// La descarga en curso de esta celda, para cancelarla al reciclarla. Defensa #1.
    var avatarTask: ImageLoadTask?

    /// Solo lectura, para los tests: el outlet es private.
    var displayedAvatar: UIImage? { avatarImageView.image }

    /// Una sola vez, cuando el storyboard termina de crear la celda (no en cada configure).
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 20   // la mitad de 40 → círculo
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = .systemGray3  // color del placeholder (es un SF Symbol)
    }
```

### 4.2 Al inicio de `configure(with:)`
```swift
        representedPostID = post.id
        avatarImageView.image = Self.avatarPlaceholder   // ⚠️ si no, se vería el avatar del post ANTERIOR mientras carga
```

### 4.3 `prepareForReuse()` completo
```swift
    override func prepareForReuse() {
        super.prepareForReuse()
        onLikeTapped = nil
        avatarTask?.cancel()          // defensa #1: ya no necesitamos esa imagen
        avatarTask = nil
        representedPostID = nil       // defensa #2: ya no represento a ese post
        avatarImageView.image = Self.avatarPlaceholder
    }
```

### 4.4 Un método para poner la imagen (debajo de `prepareForReuse`)
```swift
    /// `nil` (falló la descarga) → placeholder.
    func setAvatar(_ image: UIImage?) {
        avatarImageView.image = image ?? Self.avatarPlaceholder
    }
```

---

## 💻 Paso 5: El Feed pide los avatares

En `FeedViewController.swift`:

### 5.1 Nueva dependencia
Debajo de `private let loader: FeedLoader`:
```swift
    private let imageLoader: ImageLoader
```
Y el init queda así:
```swift
    init?(coder: NSCoder, loader: FeedLoader, imageLoader: ImageLoader) {
        self.loader = loader
        self.imageLoader = imageLoader
        super.init(coder: coder)
    }
```

### 5.2 En `cellForRowAt`, justo después de `cell.configure(with: post)`
```swift
        loadAvatar(for: post, in: cell)
```

### 5.3 El método (debajo de `toggleLike`)
```swift
    private func loadAvatar(for post: Post, in cell: PostCell) {
        guard let url = post.author.avatarURL else { return }   // sin foto: se queda el placeholder
        // Copiamos el id: la closure no debe depender de `post` ni de `self`.
        let postID = post.id

        // [weak cell] (Concepto 3): si la celda desaparece antes de que llegue la imagen, no la retenemos.
        cell.avatarTask = imageLoader.loadImage(from: url) { [weak cell] result in
            // 🟤 Aquí podemos estar en un hilo de FONDO → regresamos al principal para tocar la UI.
            DispatchQueue.main.async {
                // Defensa #2 (Concepto 4): ¿la celda sigue mostrando ESTE post?
                guard let cell, cell.representedPostID == postID else { return }
                cell.setAvatar(try? result.get())   // error → nil → placeholder
            }
        }
    }
```
> 💡 `try? result.get()`: `.success(img)` → `img`; `.failure` → `nil`. Una forma corta de "si falló, no me importa por qué".

---

## 💻 Paso 6: El router le pasa el loader real
En `AppRouter.makeFeedTab()`:
```swift
            FeedViewController(coder: coder, loader: MockFeedLoader(), imageLoader: RemoteImageLoader())
```
> ✅ Los **posts** siguen saliendo del JSON mock, pero los **avatares** ya vienen de internet (`i.pravatar.cc`, que es `https`: ATS no se queja). En el nivel Mid los posts vendrán de NexoServer.

Si compilas ahora, **los tests no compilan**: `FeedViewControllerTests` usa el init viejo. Lo arreglas en el Paso 8.3.

---

## ▶️ Paso 7: Pruébalo y haz los experimentos (⌘R)

### 7.1 Funcionalidad
Inicia sesión → **Inicio**: los posts de Mario muestran su foto, el de Luis (`avatar_url: null`) el placeholder gris. Las imágenes son redondas.

### 7.2 🧪 ¿En qué hilo llega la respuesta?
En `RemoteImageLoader`, como **primera línea** dentro de la closure de `dataTask`, agrega temporalmente:
```swift
            print("📡 completion en main thread:", Thread.isMainThread)
```
Y en `FeedViewController.loadAvatar`, como primera línea dentro de `DispatchQueue.main.async`:
```swift
                print("🎨 pintando en main thread:", Thread.isMainThread)
                
                completion en main thread true
completion en main thread true
completion en main thread true
pintando main thread true
pintando main thread true
pintando main thread tru
```
Corre la app. ¿Qué imprime cada uno? Anótalo para la pregunta 1. **Bórralos.**

### 7.3 🧪 ¿Qué pasa sin `DispatchQueue.main.async`?
En `loadAvatar`, quita temporalmente el `DispatchQueue.main.async { … }` (deja solo el `guard` y el `setAvatar`). Compila (⌘B) y lee los **warnings**: Swift te dice que `representedPostID` y `setAvatar` son **main actor-isolated** y los estás usando desde una closure `Sendable`.
- En proyectos viejos (sin estos chequeos) esto **compilaba sin avisar** y solo el *Main Thread Checker* lo detectaba al correr, con un aviso morado 🟣… o la app fallaba de forma aleatoria.
- Con el modo **Swift 6** estos warnings son **errores**: no compila. Esa es la gran ventaja de 🟢.

**Regrésalo.**

### 7.4 🧪 El bug silencioso de `resume()`
Comenta `task.resume()` en `RemoteImageLoader` y corre la app. ¿Hay crash? ¿Error en consola? ¿Qué ves? Anótalo. **Regrésalo.**
> ⚠️ No corras los tests de `RemoteImageLoaderTests` con `resume()` comentado: se quedarían esperando para siempre (el completion nunca llega).

### 7.5 🧪 La caché
Pon un breakpoint en la línea `completion(.success(cached))`. Haz scroll hasta abajo y regresa arriba (o cierra sesión y vuelve a entrar). ¿Se detiene? ¿Para qué autor? Quita el breakpoint.

---

## 🧪 Paso 8: Tests

### 8.1 Fixtures con avatar
En `NexoTests/Core/Models/PostDecodingTests.swift`, al final, cambia los fixtures:
```swift
extension User {
    static func fixture(username: String = "mario", avatarURL: URL? = nil) -> User {
        User(id: UUID(), username: username, displayName: "Mario", avatarURL: avatarURL, isVerified: false, bio: nil)
    }
}
```
Y en `Post.fixture`, agrega un **primer** parámetro `author` y úsalo:
```swift
    static func fixture(
        author: User = .fixture(),
        content: PostContent = .text("Hola"),
        // ...lo demás igual...
    ) -> Post {
        Post(
            id: UUID(),
            author: author,          // ← antes: .fixture()
            // ...lo demás igual...
```
> 💡 Con valores por defecto, **ningún test viejo cambia**: `Post.fixture()` sigue funcionando.

### 8.2 📁 `NexoTests/Helpers/ImageLoaderSpy.swift`
```swift
import UIKit
@testable import RoadmapSwift

/// SPY: no descarga nada. Anota qué le pidieron y qué le cancelaron,
/// y el TEST decide cuándo "llega" la imagen con `complete(...)`.
final class ImageLoaderSpy: ImageLoader {
    private(set) var requests: [(url: URL, completion: @Sendable (Result<UIImage, Error>) -> Void)] = []
    private(set) var cancelledURLs: [URL] = []

    var requestedURLs: [URL] { requests.map(\.url) }

    func loadImage(from url: URL, completion: @escaping @Sendable (Result<UIImage, Error>) -> Void) -> ImageLoadTask {
        requests.append((url, completion))
        return TaskSpy { [weak self] in self?.cancelledURLs.append(url) }
    }

    /// Simula que llegó la respuesta de la petición número `index`.
    func complete(with image: UIImage, at index: Int = 0) {
        requests[index].completion(.success(image))
    }

    func complete(with error: Error, at index: Int = 0) {
        requests[index].completion(.failure(error))
    }

    private struct TaskSpy: ImageLoadTask {
        let onCancel: () -> Void
        func cancel() { onCancel() }
    }
}
```

### 8.3 `FeedViewControllerTests.swift`
1. Cambia el helper `makeSUT` para que reciba el loader de imágenes (con un spy por defecto, así los 4 tests viejos no cambian):
```swift
    private func makeSUT(result: Result<[Post], Error>, imageLoader: ImageLoader = ImageLoaderSpy()) throws -> FeedViewController {
        let storyboard = UIStoryboard(name: "Feed", bundle: Bundle(for: FeedViewController.self))
        let sut = try XCTUnwrap(storyboard.instantiateInitialViewController { coder in
            FeedViewController(coder: coder, loader: FeedLoaderStub(result: result), imageLoader: imageLoader)
        })
        sut.loadViewIfNeeded()
        return sut
    }
```
2. Agrega los tests nuevos **arriba** de `// MARK: - Helpers`:
```swift
    // MARK: - Avatares
    func test_cellForRow_requestsAuthorAvatar() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: url))])

        _ = renderedCell(at: 0, in: sut)

        XCTAssertEqual(imageLoader.requestedURLs, [url])
    }

    func test_cellForRow_withoutAvatarURL_doesNotRequestAndShowsPlaceholder() throws {
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: nil))])

        let cell = renderedCell(at: 0, in: sut)

        XCTAssertTrue(imageLoader.requestedURLs.isEmpty)
        XCTAssertNotNil(cell?.displayedAvatar)
    }

    func test_avatarLoaded_showsImageOnlyAfterMainQueueRuns() throws {
        let url = try XCTUnwrap(URL(string: "https://nexo.app/ana.png"))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [.fixture(author: .fixture(avatarURL: url))])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))
        let image = UIImage()

        imageLoader.complete(with: image)
        // Todavía NO: el Feed la mandó con DispatchQueue.main.async ("más tarde").
        XCTAssertFalse(cell.displayedAvatar === image)

        flushMainQueue()
        XCTAssertTrue(cell.displayedAvatar === image)   // === : la MISMA instancia (Día 1, P2)
    }

    /// 🐛 El bug del Concepto 4, reproducido sin red lenta y sin hacer scroll.
    func test_avatarLoaded_afterCellWasReused_isIgnored() throws {
        let urlA = try XCTUnwrap(URL(string: "https://nexo.app/a.png"))
        let postA = Post.fixture(author: .fixture(avatarURL: urlA))
        let postB = Post.fixture(author: .fixture(avatarURL: nil))
        let (sut, imageLoader) = try makeSUTWithSpy(posts: [postA])
        let cell = try XCTUnwrap(renderedCell(at: 0, in: sut))   // pide el avatar de A
        let imageOfA = UIImage()

        // La tabla recicla la celda para el post B (lo mismo que hace al hacer scroll).
        cell.prepareForReuse()
        cell.configure(with: postB)
        // …y llega TARDE la imagen de A.
        imageLoader.complete(with: imageOfA, at: 0)
        flushMainQueue()

        XCTAssertEqual(imageLoader.cancelledURLs, [urlA])          // defensa #1
        XCTAssertFalse(cell.displayedAvatar === imageOfA)          // defensa #2
    }
```
3. Y estos helpers **dentro** de `// MARK: - Helpers`:
```swift
    private func makeSUTWithSpy(posts: [Post]) throws -> (FeedViewController, ImageLoaderSpy) {
        let imageLoader = ImageLoaderSpy()
        let sut = try makeSUT(result: .success(posts), imageLoader: imageLoader)
        return (sut, imageLoader)
    }

    private func renderedCell(at row: Int, in sut: FeedViewController) -> PostCell? {
        sut.tableView(sut.tableView, cellForRowAt: IndexPath(row: row, section: 0)) as? PostCell
    }

    /// Espera a que se ejecute lo que ya estaba encolado en el hilo principal.
    /// La cola es FIFO: cuando corre NUESTRO bloque, el `DispatchQueue.main.async` del Feed ya corrió.
    private func flushMainQueue() {
        let exp = expectation(description: "main queue")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1)
    }
```

### 8.4 📁 `NexoTests/Core/Networking/RemoteImageLoaderTests.swift` (carpeta nueva)
```swift
import XCTest
@testable import RoadmapSwift

/// Prueba el loader REAL con un URLSession REAL… pero la red la inventa `URLProtocolStub`.
final class RemoteImageLoaderTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.stub = nil   // que un test no contamine al siguiente
        super.tearDown()
    }

    func test_load_validImage_returnsImage() async throws {
        URLProtocolStub.stub = .init(data: makeImageData(), statusCode: 200, error: nil)
        let image = try await load().get()
        XCTAssertEqual(image.size, CGSize(width: 1, height: 1))
    }

    func test_load_non2xxStatus_failsWithInvalidResponse() async {
        URLProtocolStub.stub = .init(data: makeImageData(), statusCode: 404, error: nil)
        let result = await load()
        XCTAssertEqual(result.failure as? ImageLoaderError, .invalidResponse(statusCode: 404))
    }

    func test_load_invalidData_failsWithInvalidImageData() async {
        URLProtocolStub.stub = .init(data: Data("no soy una imagen".utf8), statusCode: 200, error: nil)
        let result = await load()
        XCTAssertEqual(result.failure as? ImageLoaderError, .invalidImageData)
    }

    func test_load_networkError_failsWithThatError() async {
        URLProtocolStub.stub = .init(data: nil, statusCode: 200, error: URLError(.notConnectedToInternet))
        let result = await load()
        XCTAssertEqual((result.failure as? URLError)?.code, .notConnectedToInternet)
    }

    // MARK: - Helpers
    private func load(url: URL = URL(string: "https://nexo.app/avatar.png")!) async -> Result<UIImage, Error> {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]   // ← aquí "secuestramos" la red
        let sut = RemoteImageLoader(session: URLSession(configuration: configuration))

        // 🟢 Adelanto del nivel Mid: convertir un completion handler en `await`.
        // ⚠️ `resume` se debe llamar EXACTAMENTE una vez (si nunca se llama, el test espera para siempre).
        return await withCheckedContinuation { continuation in
            sut.loadImage(from: url) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Un PNG real de 1×1 px. `scale = 1`: si no, usa la escala de la pantalla (3x) y saldría de 3×3.
    private func makeImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).pngData { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}

private extension Result {
    /// El error, si lo hay. Para poder escribir `XCTAssertEqual(result.failure as? …, …)`.
    var failure: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

/// 🟤 URLProtocol: URLSession le pregunta "¿tú atiendes esta petición?" (`canInit`).
/// Decimos que sí a TODAS, y contestamos con lo que el test puso en `stub`.
final class URLProtocolStub: URLProtocol {
    struct Stub {
        let data: Data?
        let statusCode: Int
        let error: Error?
    }

    /// `nonisolated(unsafe)`: una variable global mutable; le prometemos a Swift que los tests
    /// no la tocan desde dos hilos a la vez. (En el nivel Senior lo haremos sin `unsafe`.)
    nonisolated(unsafe) static var stub: Stub?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let stub = Self.stub, let url = request.url else { return }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: stub.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
```
> 💡 Estos tests son `async` y **no** llevan `@MainActor`: el loader no toca la UI. Fíjate que el 404 **sí** trae datos de imagen válidos, y aun así debe fallar: prueba que validas el `statusCode` **antes** de mirar los datos.

### 8.5 🧪 Comprueba que el test del bug sirve
1. En `loadAvatar`, cambia `guard let cell, cell.representedPostID == postID else { return }` por `guard let cell else { return }`. Corre **⌘U**: debe fallar **exactamente 1 test**. ¿Cuál, y en qué línea? Regrésalo.
2. En `prepareForReuse`, comenta `avatarTask?.cancel()`. ¿Qué test falla ahora, y por qué la app **seguiría mostrando la imagen correcta** aunque no canceles? Regrésalo.

---

## ▶️ Paso 9: Correr, revisar y hacer commit
1. **⌘U** → deben pasar **58 tests** (50 + 8). ⚠️ **Si hay uno en rojo, no hagas commit** (lección del Día 5).
2. **⌘R** → repite el Paso 7.1.
3. Revisión:
   ```bash
   git status                        # nuevos: Core/Networking, ImageLoaderSpy, RemoteImageLoaderTests
   git add .
   git --no-pager diff --staged      # busca: los print del 7.2, un resume() comentado, un cancel() comentado
   ```
4. Commit y merge:
   ```bash
   git commit -m "feat(feed): avatares con URLSession, caché y protección contra celdas recicladas"
   git checkout main
   git merge feature/dia-06-avatars
   ```

---

## ✅ Checklist del día
- [✅] Los avatares aparecen redondos; el post sin foto muestra el placeholder
- [✅] Sin warnings de constraints en la consola al abrir el Feed
- [✅] Anotaste en qué hilo llega el completion y en cuál se pinta (7.2)
- [✅] Viste los warnings de *main actor-isolated* sin `DispatchQueue.main.async` (7.3)
- [✅] Viste qué pasa sin `resume()` (7.4)
- [✅] El test del bug falla sin la comprobación de `representedPostID` (8.5)
- [⚠️] 58 tests en verde **antes** del commit
- [ Falta] Revisaste `git --no-pager diff --staged` (sin `print` ni código comentado)

## 🔥 Reto extra (opcional, +5 puntos)
1. **🟢 `async/await`.** Agrega a `ImageLoader` una extensión `func loadImage(from url: URL) async throws -> UIImage` usando `withCheckedThrowingContinuation`. ¿Cómo cancelarías la tarea si se cancela el `Task`? (Pista: `withTaskCancellationHandler`.)
2. **Errores visibles.** Si el avatar falla, muestra un ícono distinto (`person.crop.circle.badge.exclamationmark`) en lugar del placeholder normal. Escribe el test con `imageLoader.complete(with: URLError(.timedOut))`.
3. **Prefetching.** Implementa `UITableViewDataSourcePrefetching` para empezar a descargar avatares **antes** de que la celda aparezca, y cancélalos en `cancelPrefetchingForRowsAt`. ¿Dónde guardas esas tareas si todavía no hay celda?
4. **Prueba la caché.** Un test que pida la misma URL dos veces a un `RemoteImageLoader` con `URLProtocolStub` y compruebe que la red solo se usó **una** vez. (Pista: un contador estático en el stub.)

## 🧠 Preguntas de repaso (respóndelas antes del Día 7)
> 💡 Contesta **cada parte en su propia línea**. Si no sabes, escribe lo que viste en el experimento: eso ya da puntos parciales. **Una respuesta en blanco vale 0.**

1. En el experimento 7.2, ¿en qué hilo llegó el completion de `URLSession` y en cuál se pintó la imagen? ¿Por qué hace falta `DispatchQueue.main.async`?
2. Un servidor responde **404**. ¿`error` viene con valor o en `nil`? ¿Qué pasaría si no revisaras el `statusCode`?
3. Explica el bug de la imagen equivocada con tus palabras. ¿Por qué **cancelar** en `prepareForReuse` no basta y hace falta `representedPostID`?
4. En `loadAvatar` usamos `[weak cell]`. ¿Hay un **retain cycle** si fuera `strong`? ¿Entonces qué problema evita el `weak`?
5. ¿Qué diferencia hay entre un **stub** (Día 4) y un **spy** (hoy)? ¿Por qué `RemoteImageLoaderTests` usa `URLProtocolStub` en lugar de `ImageLoaderSpy`?

---
**Próximo (Día 7):** **Pull to refresh** con `UIRefreshControl`, estados de pantalla (cargando / vacío / error / contenido) con un `enum`, un **`FeedLoader` asíncrono** con completion handler y retraso simulado, y el patrón **MVC** puesto a prueba: ¿cuánto ha crecido `FeedViewController`? (El primer paso hacia MVVM.)
