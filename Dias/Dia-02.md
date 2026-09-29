# 📅 Día 2: Modelos de Nexo (`User`, `Post`), enums con valores asociados, `Codable` y JSON mock

**Nivel:** 🐣 Junior · **Duración:** 1.5–2 h
**Temas:** `struct` vs `class` (valor vs referencia), `let`/`var`, `mutating`, optionals (`?`, `??`, `if let`), computed properties, protocolos (`Codable`, `Identifiable`, `Hashable`, `Sendable`), enums con **valores asociados**, `switch` exhaustivo, `CodingKeys`, `init(from:)` manual, `throws`/`do-catch`, `Bundle`, extensions y *fixtures* para tests.

---

## 🎯 Objetivo del día
Al terminar tendrás:
1. Los modelos centrales de la red social: **`User`**, **`Post`** y **`PostContent`** (texto, imagen, video…).
2. Un archivo **`feed.json`** que simula la respuesta del servidor (hasta que exista NexoServer, en el Día ~60).
3. Un **`MockFeedLoader`** que lee y decodifica ese JSON.
4. **11 tests nuevos** (18 en total) para la decodificación y la lógica de los modelos.

---

## 📚 Concepto 1: `struct` (valor) vs `class` (referencia)

```swift
// 🔹 STRUCT: al asignar se COPIA
struct PostS { var likes = 0 }
let a = PostS()
var b = a          // b es una copia
b.likes = 99
print(a.likes)     // 0  ← a no cambió

// 🔸 CLASS: al asignar se comparte la MISMA instancia
final class PostC { var likes = 0 }
let c = PostC()
let d = c          // d apunta al mismo objeto
d.likes = 99
print(c.likes)     // 99 ← ¡c también cambió!
print(c === d)     // true (misma instancia, ¿recuerdas el Día 1?)
```

| | `struct` | `class` |
|---|---|---|
| Semántica | Valor (copia) | Referencia (compartida) |
| Herencia | ❌ (solo protocolos) | ✅ |
| Identidad (`===`) | ❌ | ✅ |
| Mutar una propiedad | Necesita `var` + métodos `mutating` | Aunque sea `let` |
| Memoria | Normalmente en el stack; sin ARC (salvo lo que contenga) | Heap + ARC (conteo de referencias, posibles *retain cycles*) |
| Concurrencia | Fácil de hacer `Sendable` | Difícil (estado compartido) |

**Regla práctica 🟢 (la de Apple):** usa `struct` por defecto. Usa `class` cuando necesites **identidad**, **herencia** (por ejemplo `UIViewController`) o **estado compartido** (un caché, un servicio).
🟤 En Objective-C todo era `NSObject` (clases), así que el código legacy convertido a Swift está lleno de clases para modelos.

> 💡 **Copy-on-Write:** `Array`, `String` y `Dictionary` son structs, pero no copian su contenido en cada asignación. Solo lo copian **cuando alguien lo modifica**. Por eso usar structs no es "lento".

---

## 📚 Concepto 2: enums con valores asociados

Un post puede ser texto, imagen o video, y cada tipo tiene **datos distintos**.

🟤 **Forma vieja** (un solo struct con muchos opcionales):
```swift
struct OldPost {
    let type: String        // "text", "image"… ¿y si llega "imgae"? 💥
    let text: String?
    let imageURL: URL?      // ¿puede haber imagen Y video a la vez? El tipo no lo impide
    let videoURL: URL?
    let duration: Double?
}
```
🟢 **Forma moderna** (los estados imposibles no se pueden representar):
```swift
enum PostContent {
    case text(String)
    case image(url: URL, caption: String?)
    case video(url: URL, duration: TimeInterval)
}
```
Y con `switch` el compilador **te obliga** a manejar todos los casos:
```swift
switch post.content {
case .text(let text):             print(text)
case .image(let url, let caption): print(url, caption ?? "sin descripción")
case .video(_, let duration):     print("\(duration)s")
}
```
Si mañana agregas `case poll(...)`, **cada `switch` que no lo maneje deja de compilar**. Eso es una red de seguridad enorme en apps grandes.

---

## 📚 Concepto 3: JSON, `Codable` y los choques de nombres

| Época | Cómo se parseaba JSON |
|---|---|
| 🟤 Swift 1–3 / Obj-C | `JSONSerialization` → `[String: Any]` → `json["name"] as? String` en cada campo (cualquier error de dedo daba `nil` en silencio) |
| 🟤 Librerías | SwiftyJSON, ObjectMapper (verás estas en proyectos viejos) |
| 🟢 Swift 4+ | `Codable` (`Decodable` + `Encodable`): el compilador genera el código de parseo |

Los servidores suelen usar **snake_case** (`display_name`) y Swift usa **camelCase** (`displayName`). Hay dos herramientas:
1. `decoder.keyDecodingStrategy = .convertFromSnakeCase` → convierte **todas** las llaves.
2. `CodingKeys` → renombra llaves **una por una**.

⚠️ Trampa real: con `.convertFromSnakeCase`, `avatar_url` se convierte en `avatarUrl`, **no** en `avatarURL`. Por eso `User` tiene un `CodingKeys` que mapea `avatarURL = "avatarUrl"`. Este bug aparece en muchos proyectos.

---

## 💻 Paso 0: Rama nueva
```bash
cd ~/Documents/GitHubCopilot/RoadmapSwift
git checkout -b feature/dia-02-models
```

---

## 💻 Paso 1: `User`

📁 Crea la carpeta `Core/Models` (clic derecho en `Core` → **New Folder**) y dentro el archivo `User.swift`:

```swift
import Foundation

/// Usuario de Nexo.
/// - `Codable`: se puede leer y escribir como JSON.
/// - `Identifiable`: tiene un `id` único (lo usarán SwiftUI y las listas diffable).
/// - `Hashable`: se puede usar en `Set`, como llave de `Dictionary` y en Diffable Data Sources.
/// - `Sendable`: es seguro pasarlo entre hilos/actores (concurrencia, nivel Senior).
nonisolated struct User: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let username: String
    var displayName: String      // `var`: el usuario puede cambiar su nombre visible
    let avatarURL: URL?          // Optional: no todos tienen foto
    let isVerified: Bool
    var bio: String?

    /// Computed property: no se guarda, se calcula cada vez.
    var handle: String { "@\(username)" }

    /// Solo hace falta porque `avatarURL` no coincide con lo que genera `.convertFromSnakeCase`
    /// ("avatar_url" → "avatarUrl"). Si declaras CodingKeys, debes listar TODAS las propiedades guardadas.
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName
        case avatarURL = "avatarUrl"
        case isVerified
        case bio
    }
}
```

> ❓ `bio` es `String?` y en el JSON puede **no existir** la llave. `Codable` usa `decodeIfPresent` automáticamente para los opcionales, así que no falla. Si `bio` fuera `String` (no opcional) y faltara, la decodificación **lanzaría un error**.

---

## 💻 Paso 2: `PostContent` (enum con valores asociados + `Codable` manual)

📁 `Core/Models/PostContent.swift`

El JSON de un contenido se ve así:
```json
{ "type": "image", "url": "https://…", "caption": "Atardecer" }
```
Swift puede generar `Codable` para enums con valores asociados, pero el formato que genera **no coincide** con este JSON. Por eso escribimos el `init(from:)` a mano. Esto es muy común en apps reales.

```swift
import Foundation

/// Contenido de un post. Cada caso tiene sus propios datos (valores asociados).
nonisolated enum PostContent: Hashable, Sendable {
    case text(String)
    case image(url: URL, caption: String?)
    case video(url: URL, duration: TimeInterval)
    /// Tipo que esta versión de la app todavía no conoce.
    /// Así una app vieja NO crashea cuando el servidor agrega un tipo nuevo (por ejemplo "poll").
    case unsupported(type: String)
}

// Separar la conformance en una extension (como hiciste con el delegate en el Día 1).
nonisolated extension PostContent: Codable {

    /// Las llaves posibles dentro del objeto JSON "content".
    private enum CodingKeys: String, CodingKey {
        case type, text, url, caption, duration
    }

    /// Enum con raw value: convierte "text"/"image"/"video" en un caso con `ContentType(rawValue:)`.
    private enum ContentType: String {
        case text, image, video
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawType = try container.decode(String.self, forKey: .type)

        // `ContentType(rawValue:)` devuelve un Optional: nil si el tipo es desconocido.
        switch ContentType(rawValue: rawType) {
        case .text:
            self = .text(try container.decode(String.self, forKey: .text))
        case .image:
            self = .image(
                url: try container.decode(URL.self, forKey: .url),
                caption: try container.decodeIfPresent(String.self, forKey: .caption)
            )
        case .video:
            self = .video(
                url: try container.decode(URL.self, forKey: .url),
                duration: try container.decode(TimeInterval.self, forKey: .duration)
            )
        case nil:
            self = .unsupported(type: rawType)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text):
            try container.encode(ContentType.text.rawValue, forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let url, let caption):
            try container.encode(ContentType.image.rawValue, forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(caption, forKey: .caption)
        case .video(let url, let duration):
            try container.encode(ContentType.video.rawValue, forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encode(duration, forKey: .duration)
        case .unsupported(let type):
            try container.encode(type, forKey: .type)
        }
    }
}
```

> 🧠 `decode` vs `decodeIfPresent`: `decode` **lanza un error** si la llave no existe. `decodeIfPresent` devuelve `nil`. Úsalo solo para los campos que de verdad son opcionales.

---

## 💻 Paso 3: `Post`

📁 `Core/Models/Post.swift`

```swift
import Foundation

nonisolated struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let author: User             // Composición: un Post CONTIENE un User
    let content: PostContent
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var isLikedByMe: Bool

    /// `mutating`: en un struct, un método que cambia propiedades debe marcarse así.
    /// Solo se puede llamar sobre un `var`, nunca sobre un `let`.
    mutating func toggleLike() {
        isLikedByMe.toggle()
        likeCount += isLikedByMe ? 1 : -1
    }

    /// 🟢 iOS 15+: FormatStyle ("hace 2 días").
    /// 🟤 Antes: `DateFormatter`/`RelativeDateTimeFormatter` (costosos de crear, había que cachearlos).
    var relativeCreatedAt: String {
        createdAt.formatted(.relative(presentation: .named))
    }
}

/// La forma de la respuesta del "servidor": { "posts": [ ... ] }
nonisolated struct FeedResponse: Decodable, Sendable {
    let posts: [Post]
}
```

---

## 💻 Paso 4: Decoder y encoder configurados para Nexo

📁 Crea la carpeta `Core/Decoding` y el archivo `JSONDecoder+Nexo.swift`.
(Convención de nombre: `Tipo+Algo.swift` = una extension de `Tipo`.)

```swift
import Foundation

/// Una sola configuración para toda la app: si el servidor cambia el formato de fechas,
/// se corrige en UN lugar.
nonisolated extension JSONDecoder {
    static var nexo: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase   // display_name → displayName
        decoder.dateDecodingStrategy = .iso8601               // "2026-09-27T10:00:00Z" → Date
        return decoder
    }
}

nonisolated extension JSONEncoder {
    static var nexo: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
```

> ❓ ¿Por qué `static var` y no `static let`? `JSONDecoder` es una **clase** con estado mutable. Si fuera un `let` compartido, alguien podría cambiarle la configuración y afectar a toda la app. Con `var` computada, cada llamada crea uno nuevo. (Un `static let` de una clase no-`Sendable` además da error en Swift 6: lo veremos en Senior.)

---

## 💻 Paso 5: El JSON mock del Feed

📁 Crea la carpeta `Resources/Mocks` y dentro un archivo vacío llamado `feed.json`
(**New File from Template… → Other → Empty** → nombre `feed.json`).

> Como tu proyecto usa carpetas sincronizadas 🟢, el `.json` se agrega solo al target **RoadmapSwift** como recurso. Compruébalo: selecciónalo → *File Inspector* (⌥⌘1) → **Target Membership: RoadmapSwift ✅**.

Pega esto:
```json
{
  "posts": [
    {
      "id": "B0000000-0000-0000-0000-000000000001",
      "author": {
        "id": "A0000000-0000-0000-0000-000000000001",
        "username": "mario",
        "display_name": "Mario MJ",
        "avatar_url": "https://i.pravatar.cc/150?img=12",
        "is_verified": true,
        "bio": "iOS dev en camino a Fellow 🚀"
      },
      "content": {
        "type": "text",
        "text": "¡Hola Nexo! 👋 Primer post desde la app."
      },
      "created_at": "2026-09-27T10:00:00Z",
      "like_count": 12,
      "comment_count": 3,
      "is_liked_by_me": false
    },
    {
      "id": "B0000000-0000-0000-0000-000000000002",
      "author": {
        "id": "A0000000-0000-0000-0000-000000000002",
        "username": "lucia",
        "display_name": "Lucía Pérez",
        "avatar_url": "https://i.pravatar.cc/150?img=47",
        "is_verified": false,
        "bio": null
      },
      "content": {
        "type": "image",
        "url": "https://picsum.photos/id/1015/800/600",
        "caption": "Atardecer en la montaña 🏔️"
      },
      "created_at": "2026-09-26T18:30:00Z",
      "like_count": 87,
      "comment_count": 14,
      "is_liked_by_me": true
    },
    {
      "id": "B0000000-0000-0000-0000-000000000003",
      "author": {
        "id": "A0000000-0000-0000-0000-000000000003",
        "username": "dev_carlos",
        "display_name": "Carlos Ruiz",
        "avatar_url": null,
        "is_verified": false
      },
      "content": {
        "type": "video",
        "url": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
        "duration": 42.5
      },
      "created_at": "2026-09-25T09:15:00Z",
      "like_count": 230,
      "comment_count": 41,
      "is_liked_by_me": false
    },
    {
      "id": "B0000000-0000-0000-0000-000000000004",
      "author": {
        "id": "A0000000-0000-0000-0000-000000000001",
        "username": "mario",
        "display_name": "Mario MJ",
        "avatar_url": "https://i.pravatar.cc/150?img=12",
        "is_verified": true,
        "bio": "iOS dev en camino a Fellow 🚀"
      },
      "content": {
        "type": "poll",
        "question": "¿UIKit o SwiftUI?",
        "options": ["UIKit", "SwiftUI", "Ambos"]
      },
      "created_at": "2026-09-24T21:00:00Z",
      "like_count": 5,
      "comment_count": 9,
      "is_liked_by_me": false
    }
  ]
}
```
Fíjate en los casos "difíciles" que incluye a propósito:
- Lucía tiene `"bio": null` y Carlos **no tiene** la llave `bio` → ambos deben dar `nil`.
- Carlos tiene `"avatar_url": null`.
- El post 4 es de tipo `"poll"`, que la app no conoce todavía → debe quedar como `.unsupported`.

---

## 💻 Paso 6: `MockFeedLoader`

📁 Crea `Features/Feed/Data/MockFeedLoader.swift` (carpetas `Feed` y `Data` nuevas).

```swift
import Foundation

/// Errores propios del loader: más claros que los errores genéricos del sistema.
nonisolated enum FeedLoaderError: Error, Equatable {
    case fileNotFound(String)
    case decodingFailed(String)
}

/// Lee el feed desde un JSON dentro de la app.
/// Recibe `bundle` y `fileName` en el `init` (inyección de dependencias por init):
/// así en los tests podemos pedirle un archivo que NO existe y probar el error.
nonisolated struct MockFeedLoader {
    private let bundle: Bundle
    private let fileName: String

    init(bundle: Bundle = .main, fileName: String = "feed") {
        self.bundle = bundle
        self.fileName = fileName
    }

    /// `throws`: esta función puede fallar, y quien la llame DEBE usar `try`.
    func load() throws -> [Post] {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw FeedLoaderError.fileNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder.nexo.decode(FeedResponse.self, from: data).posts
        } catch {
            // `String(describing:)` conserva el detalle: QUÉ llave faltó y en QUÉ posición.
            throw FeedLoaderError.decodingFailed(String(describing: error))
        }
    }
}
```

> 🟤 vs 🟢 **Manejo de errores:**
> - 🟤 Obj-C: `NSError **` como parámetro de salida (`[data writeToFile:… error:&error]`).
> - 🟡 Swift 2+: `throws` + `do/try/catch` (lo que usamos hoy). `Result` (Día 1) es útil cuando el error se **guarda o se pasa** a otro lado, por ejemplo en un callback.
> - 🟢 Swift 6: **typed throws**, `func load() throws(FeedLoaderError)`. Lo usaremos más adelante.

---

## 💻 Paso 7: Verlo funcionar en la app
Temporalmente, en `LoginViewController.createAccountTapped`, reemplaza el `print` por:

```swift
@IBAction private func createAccountTapped(_ sender: UIButton) {
    // ⚠️ TEMPORAL (Día 2): solo para ver el feed en consola. Lo quitamos en el Día 3.
    do {
        let posts = try MockFeedLoader().load()
        for post in posts {
            // 🟢 Swift 5.9+: `switch` como expresión, asignado directo a una constante.
            let summary: String = switch post.content {
            case .text(let text): "📝 \(text)"
            case .image(_, let caption): "🖼️ \(caption ?? "(sin descripción)")"
            case .video(_, let duration): "🎬 video de \(Int(duration))s"
            case .unsupported(let type): "❔ tipo no soportado: \(type)"
            }
            let verified = post.author.isVerified ? " ✔︎" : ""
            print("\(post.author.handle)\(verified) · \(post.relativeCreatedAt) · ❤️ \(post.likeCount)\n   \(summary)")
        }
    } catch {
        print("❌ \(error)")
    }
}
```
Corre la app (⌘R) y toca **"¿No tienes cuenta? Crear cuenta"**. Deberías ver los 4 posts en la consola.

🧪 **Experimento:** en `feed.json`, cambia `"like_count": 12` por `"like_count": "doce"` y toca el botón otra vez. Lee el mensaje de `decodingFailed`: te dice **qué llave** y **en qué post** falló. Después **devuélvelo a `12`**.

---

## 🧪 Paso 8: Tests

📁 `NexoTests/Core/Models/PostDecodingTests.swift`

```swift
import XCTest
@testable import RoadmapSwift

final class PostDecodingTests: XCTestCase {

    private let decoder = JSONDecoder.nexo

    // `throws` en el test: si algo lanza un error, el test falla mostrando ese error.
    func test_decode_textContent_returnsTextCase() throws {
        // #"…"# = raw string: no hace falta escapar las comillas.
        let json = #"{ "type": "text", "text": "Hola" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .text("Hola"))
    }

    func test_decode_imageWithoutCaption_returnsImageWithNilCaption() throws {
        let json = #"{ "type": "image", "url": "https://nexo.app/a.jpg" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .image(url: URL(string: "https://nexo.app/a.jpg")!, caption: nil))
    }

    func test_decode_unknownType_returnsUnsupported() throws {
        let json = #"{ "type": "poll", "question": "¿?" }"#
        let content = try decoder.decode(PostContent.self, from: Data(json.utf8))
        XCTAssertEqual(content, .unsupported(type: "poll"))
    }

    func test_decode_videoWithoutDuration_throwsError() {
        let json = #"{ "type": "video", "url": "https://nexo.app/v.mp4" }"#
        XCTAssertThrowsError(try decoder.decode(PostContent.self, from: Data(json.utf8)))
    }

    func test_decode_userWithSnakeCaseAndMissingBio_mapsFields() throws {
        // Raw string multilínea: #""" … """#
        let json = #"""
        {
          "id": "A0000000-0000-0000-0000-000000000009",
          "username": "ana",
          "display_name": "Ana",
          "avatar_url": null,
          "is_verified": true
        }
        """#
        let user = try decoder.decode(User.self, from: Data(json.utf8))
        XCTAssertEqual(user.displayName, "Ana")
        XCTAssertEqual(user.handle, "@ana")
        XCTAssertNil(user.avatarURL)
        XCTAssertNil(user.bio)
        XCTAssertTrue(user.isVerified)
    }

    /// "Round trip": codificar y volver a decodificar debe dar exactamente lo mismo.
    func test_encodeThenDecode_post_returnsEqualPost() throws {
        let original = Post.fixture(content: .video(url: URL(string: "https://nexo.app/v.mp4")!, duration: 10))
        let data = try JSONEncoder.nexo.encode(original)
        let decoded = try decoder.decode(Post.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_mockFeedLoader_loadsBundledFeed() throws {
        let posts = try MockFeedLoader().load()
        XCTAssertEqual(posts.count, 4)
        XCTAssertEqual(posts.last?.content, .unsupported(type: "poll"))
    }

    func test_mockFeedLoader_missingFile_throwsFileNotFound() {
        let sut = MockFeedLoader(fileName: "no_existe")
        XCTAssertThrowsError(try sut.load()) { error in
            XCTAssertEqual(error as? FeedLoaderError, .fileNotFound("no_existe"))
        }
    }
}

final class PostTests: XCTestCase {

    func test_toggleLike_whenNotLiked_incrementsCount() {
        var post = Post.fixture(likeCount: 10, isLikedByMe: false)
        post.toggleLike()
        XCTAssertTrue(post.isLikedByMe)
        XCTAssertEqual(post.likeCount, 11)
    }

    func test_toggleLike_whenLiked_decrementsCount() {
        var post = Post.fixture(likeCount: 10, isLikedByMe: true)
        post.toggleLike()
        XCTAssertFalse(post.isLikedByMe)
        XCTAssertEqual(post.likeCount, 9)
    }

    /// Demuestra la semántica de VALOR: la copia no afecta al original.
    func test_struct_copyIsIndependent() {
        let original = Post.fixture(likeCount: 0, isLikedByMe: false)
        var copy = original
        copy.toggleLike()
        XCTAssertEqual(original.likeCount, 0)
        XCTAssertEqual(copy.likeCount, 1)
    }
}

// MARK: - Fixtures
// Un "fixture" es un objeto de prueba con valores por defecto.
// Cada test cambia SOLO lo que le importa y el resto queda con valores válidos.
extension User {
    static func fixture(username: String = "mario") -> User {
        User(id: UUID(), username: username, displayName: "Mario", avatarURL: nil, isVerified: false, bio: nil)
    }
}

extension Post {
    static func fixture(
        content: PostContent = .text("Hola"),
        likeCount: Int = 0,
        isLikedByMe: Bool = false
    ) -> Post {
        Post(
            id: UUID(),
            author: .fixture(),
            content: content,
            // Fecha FIJA: los tests no deben depender del reloj. Y un número entero de
            // segundos, porque ISO 8601 no guarda milisegundos y el round trip fallaría.
            createdAt: Date(timeIntervalSince1970: 1_790_000_000),
            likeCount: likeCount,
            commentCount: 0,
            isLikedByMe: isLikedByMe
        )
    }
}
```

> 💡 Fíjate que **no tuviste que escribir** el `init` de `User` ni el de `Post`: los structs reciben gratis un **memberwise initializer**. Las clases no.

---

## ▶️ Paso 9: Correr, probar y hacer commit
1. **⌘U** → deben pasar **18 tests** (7 del Día 1 + 11 nuevos).
2. **⌘R** → toca "Crear cuenta" y mira el feed en la consola.
3. Commit y merge:
```bash
git add .
git commit -m "feat(feed): modelos User/Post/PostContent con Codable y feed mock"
git checkout main
git merge feature/dia-02-models
```

---

## ✅ Checklist del día
- [ ] `User`, `Post` y `PostContent` compilan
- [ ] `feed.json` tiene Target Membership en **RoadmapSwift**
- [ ] Ves los 4 posts en la consola (el 4.º como "tipo no soportado")
- [ ] Hiciste el experimento de `"doce"` y entendiste el error
- [ ] 18 tests en verde
- [ ] Puedes explicar con tus palabras por qué `Post` es `struct`

## 🔥 Reto extra (opcional)
1. **Nuevo tipo de contenido:** agrega `case link(url: URL, title: String)` a `PostContent` y compila **antes** de tocar nada más. ¿Cuántos errores aparecen y dónde? (Esa es la ventaja del `switch` exhaustivo.) Luego impleméntalo en `init(from:)` y `encode(to:)`, agrega un post de tipo `"link"` al JSON y escribe su test.
2. **Class vs struct en vivo:** en un test, crea `final class Counter { var value = 0 }`, asígnalo a dos variables, cambia una y comprueba con `XCTAssertEqual` que la otra **también** cambió. Agrega `XCTAssertTrue(a === b)`.
3. **Formato de números:** agrega a `Post` una computed property `formattedLikes` que muestre `1.2 K` para 1200, usando `likeCount.formatted(.number.notation(.compactName))` 🟢.

## 🧠 Preguntas de repaso (respóndelas antes del Día 3)
1. ¿Qué pasa si declaras `let post = Post.fixture()` y llamas a `post.toggleLike()`? ¿Por qué? No se.
2. ¿Cuál es la diferencia entre `decode` y `decodeIfPresent`? ¿Cuándo usarías cada uno? Decode es cuando estas seguro que trae un dato el servidor, y decodeIfPresente es cuando no sabes, asi que esa variable es opcional
3. ¿Por qué existe el caso `.unsupported` en lugar de lanzar un error cuando llega un tipo desconocido? Piensa en una app que ya está en la App Store. En caso que esl servidor envie un caso que no tengamos sensado en nuestro modelo y asi no crashea la app
4. Si `User` fuera una `class`, ¿qué problema podría aparecer al pasarlo a varias pantallas que lo modifican?, que haria varias refencias, y por lo tanto si esa referencia cambia, en las demas referencias se veria ese cambio.
5. ¿Por qué los fixtures usan una fecha fija en lugar de `Date()`? ya que los test no deberiasn de depender del reloj, ademas el round trip fallaria, ya que ISO 8601 no guarda milisegundos.

---
**Próximo (Día 3):** pantalla de **Registro** en Storyboard con **segues** (`show`, `present`, `prepare(for:sender:)`, *unwind segues*) 🟤 vs navegación por código 🟢, validación del formulario (reutilizando `EmailValidator`) y un `PasswordValidator`.
