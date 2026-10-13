# 🧭 Roadmap Swift: de Junior a Fellow, construyendo una app real

> Todo el aprendizaje se hace construyendo **una sola app real**, que va creciendo nivel por nivel.
> Se combina **lo viejo (legacy)** y **lo nuevo (moderno)**, porque en un nivel Staff+ tienes que conocer y migrar ambos.
> Se usan **Storyboard/UIKit y SwiftUI** en el mismo proyecto (así pasa en empresas reales).

---

## 📱 La app: **"Nexo"**: red social + mensajería + video corto

**¿Por qué una sola app?** Porque en la vida real un Staff/Principal trabaja en **una app grande, modular y con años de historia**, donde conviven código viejo y nuevo. Una red social con chat y video cubre todo:

| Módulo | Qué practicamos | Tecnología principal |
|---|---|---|
| **Auth / Onboarding** | Formularios, validación, Keychain, Sign in with Apple, Passkeys | **Storyboard** + UIKit (legacy) → migración a SwiftUI |
| **Feed** | Listas grandes, paginación, caché de imágenes, rendimiento | UIKit `UICollectionView` (DataSource → Diffable → Compositional) |
| **Perfil** | Edición, fotos, formularios | **SwiftUI** + `UIViewControllerRepresentable` |
| **Chat (mensajería)** | WebSockets, tiempo real, persistencia offline, sincronización | SwiftUI + actors + SwiftData/Core Data |
| **Stories / Video corto** | AVFoundation, cámara, filtros, reproducción | UIKit + AVKit + Metal/Core Image |
| **Notificaciones** | APNs, Rich Notifications, extensiones | Notification Service Extension |
| **Widgets / Live Activities** | WidgetKit, ActivityKit, App Intents | SwiftUI |
| **Backend propio (NexoServer)** | REST, auth JWT, WebSockets, base de datos, push; **corre en tu Mac** | **Vapor** + Fluent + SwiftNIO (Swift on Server) |
| **Design System** | Componentes reutilizables UIKit + SwiftUI | Swift Package local |

**Targets del proyecto al final:**
1. `Nexo` (app iOS: Storyboard + SwiftUI)
2. `NexoKit` (Swift Packages modulares: Core, Networking, Persistence, DesignSystem, Features…)
3. `NexoWidgets` (WidgetKit + Live Activities)
4. `NexoNotificationService` (extensión)
5. `NexoServer` (backend en Vapor que corre en tu Mac; empieza en el nivel Mid)
6. `NexoShared` (Swift Package con los modelos compartidos entre la app y el servidor)
7. `NexoMacros` (macros propias de Swift, nivel Principal+)

> ✅ **Es una sola app iOS (Nexo)**. Además hay un proyecto **backend** aparte, **NexoServer** (Vapor), que **no es una app**: es el servidor en Swift que **corre en tu Mac** (y después en Linux o Docker). Nexo le pide los datos (API REST y WebSockets del chat). En el nivel Junior usamos JSON mock. **Desde el nivel Mid la app consume NexoServer corriendo en `localhost`.**

### 📁 Estructura del repositorio
```
RoadmapSwift/                 ← repositorio (git)
├── RoadmapSwift/             ← app iOS Nexo (Storyboard + SwiftUI)
├── RoadmapSwift.xcodeproj
├── NexoKit/                  ← Swift Packages de la app (Core, Networking, DesignSystem…)
├── NexoShared/               ← Swift Package: DTOs/modelos compartidos app ↔ servidor
├── NexoServer/               ← Swift Package ejecutable con Vapor (backend)
│   ├── Package.swift
│   ├── Sources/NexoServer/   (configure.swift, routes.swift, Controllers/, Models/, Migrations/)
│   └── Tests/NexoServerTests/
└── ROADMAP.md
```

---

## 🗺️ Leyenda
- 🟤 **Viejo / Legacy**: todavía está en millones de apps y tienes que dominarlo.
- 🟢 **Nuevo / Moderno**: hacia dónde migra la industria.
- 🔁 **Migración**: tarea de pasar de lo viejo a lo nuevo **en la misma app**.

---

# NIVEL 1: 🐣 JUNIOR
**Objetivo:** Dominar el lenguaje y construir pantallas funcionales.
**En Nexo:** Login, Registro y Feed básico con Storyboard.

### Lenguaje Swift
- Variables, constantes, tipos, inferencia, optionals (`?`, `!`, `if let`, `guard let`, `??`)
  - Ej: `guard let email = emailTextField.text, !email.isEmpty else { return }`
- Colecciones: `Array`, `Dictionary`, `Set`; `map`, `filter`, `reduce`, `compactMap`
- Control de flujo, `switch` con pattern matching
- Funciones, closures, `@escaping`, capture lists `[weak self]`
- `struct` vs `class` (valor vs referencia), `enum` con valores asociados
- Protocolos básicos, extensiones
- Manejo de errores: `throws`, `do/catch`, `Result`
- Access control: `private`, `fileprivate`, `internal`, `public`, `open`
- Swift 5.9+: `if/switch` como expresiones 🟢

### UIKit + Storyboard 🟤
- Ciclo de vida de `UIViewController` (`viewDidLoad`, `viewWillAppear`…)
- `AppDelegate` 🟤 vs `SceneDelegate` 🟢 (iOS 13+)
- Storyboard, Segues, `IBOutlet`, `IBAction`, `prepare(for:sender:)`
- Auto Layout en Interface Builder, `UIStackView`
- `UITableView` con `UITableViewDataSource/Delegate` 🟤
- `UINavigationController`, `UITabBarController`
- Patrón **Delegate** y **Target-Action**

### SwiftUI (introducción) 🟢
- `View`, `@State`, `@Binding`, `VStack/HStack/ZStack`, `List`, modificadores
- `UIHostingController` para meter SwiftUI dentro del Storyboard

### Datos y red
- `Codable` (JSON)
- `URLSession` con **completion handlers** 🟤
- `UserDefaults`

### Herramientas
- Xcode, breakpoints, LLDB básico (`po`, `v`)
- Git (branches, commits, PRs)

### Testing
- **XCTest** 🟤: primeras pruebas unitarias de validadores (email, password)

### 🎯 Entregables en Nexo
- Pantalla Login/Registro en **Storyboard**
- Feed con `UITableView` y datos mock desde JSON local
- Pantalla "Acerca de" en **SwiftUI** vía `UIHostingController`
- Tests unitarios de validación

---

# NIVEL 2: 🧑‍💻 MID
**Objetivo:** Escribir código mantenible, con arquitectura y tests.
**En Nexo:** Red real, caché de imágenes, perfil en SwiftUI, persistencia.

### Lenguaje
- Protocolos con `associatedtype`, extensiones de protocolo, POP (Protocol-Oriented Programming)
- Genéricos, `where` clauses
- `some` (opaque types) 🟢 vs `any` (existentials) 🟢
- Property wrappers (`@propertyWrapper`)
- ARC a fondo: `strong`, `weak`, `unowned`, retain cycles
- `Equatable`, `Hashable`, `Comparable`, `Identifiable`

### Concurrencia (lo viejo primero)
- **GCD** 🟤: `DispatchQueue.main.async`, `global()`, `DispatchGroup`, `DispatchSemaphore`, barreras
- **OperationQueue / Operation** 🟤: dependencias, cancelación
- Introducción a **async/await** 🟢 y `Task`
- 🔁 Migrar `NetworkClient` de completion handlers → `async/await` con `withCheckedThrowingContinuation`

### Reactividad / comunicación
- `NotificationCenter` 🟤, KVO 🟤
- **Combine** (`Publisher`, `@Published`, `sink`, `debounce`), el punto intermedio
- SwiftUI: `ObservableObject` / `@StateObject` / `@EnvironmentObject` 🟤 (sí, ya es "viejo")
- **Observation** `@Observable`, `@Bindable`, `@Environment` 🟢 (iOS 17+)
- 🔁 Migrar ViewModels de `ObservableObject` → `@Observable`

### UIKit intermedio
- XIBs y celdas personalizadas
- Auto Layout **por código** (`NSLayoutConstraint`, anchors)
- `UICollectionView` con `UICollectionViewFlowLayout` 🟤
- **Diffable Data Source** 🟢 + **Compositional Layout** 🟢
- 🔁 Migrar Feed de `UITableView` clásico → `UICollectionView` + Diffable + Compositional

### SwiftUI intermedio
- `NavigationView` 🟤 → `NavigationStack` / `NavigationSplitView` 🟢
- `List`, `LazyVStack`, `Grid`, `.task`, `.refreshable`, `.searchable`
- `UIViewRepresentable` / `UIViewControllerRepresentable`

### Persistencia
- **Core Data** 🟤 (`NSPersistentContainer`, `NSFetchedResultsController`)
- **SwiftData** 🟢 (`@Model`, `@Query`)
- Keychain para tokens
- `FileManager`, caché en disco

### Arquitectura
- **MVC** 🟤 (el de Apple, "Massive View Controller")
- **MVVM** (con Combine y con `@Observable`)
- **Coordinator** pattern para navegación en UIKit
- Inyección de dependencias (por init, por protocolo)
- SOLID

### Patrones de diseño
- Singleton (y por qué evitarlo), Delegate, Observer, Factory, Builder, Adapter, Repository, Strategy

### Testing
- XCTest con **mocks/stubs/spies** basados en protocolos
- Tests async (`XCTestExpectation` 🟤 vs `async` test 🟢)
- **Swift Testing** 🟢 (`@Test`, `#expect`, `@Suite`, tests parametrizados)
- UI Tests con `XCUITest`

### Dependencias
- **CocoaPods** 🟤, **Carthage** 🟤 → **Swift Package Manager** 🟢

### 🖥️ NexoServer (inicio, corriendo en tu Mac)
- Instalar Vapor, crear el proyecto y correrlo con `swift run` en `http://127.0.0.1:8080`
- Rutas REST básicas: `GET /posts`, `GET /users/:id`, `POST /auth/login`
- `Content` (el `Codable` de Vapor), controladores con `RouteCollection`
- Datos en memoria primero, luego **Fluent + SQLite** (ORM y migraciones)
- `EventLoopFuture` 🟤 (Vapor 4 original) vs **async/await** 🟢 en las rutas
- Paquete `NexoShared` con los DTOs usados por la app y por el servidor
- Tests del servidor con `XCTVapor` 🟤 / `VaporTesting` + Swift Testing 🟢
- La app deja los JSON mock y consume `localhost:8080` (ATS: `NSAllowsLocalNetworking`)

### 🎯 Entregables en Nexo
- `NetworkClient` genérico (primero callbacks, luego async/await)
- Caché de imágenes propia (NSCache + disco)
- Perfil de usuario en **SwiftUI** con `@Observable`
- Feed migrado a Diffable + Compositional Layout
- Persistencia offline (Core Data → luego SwiftData)
- Coordinators para navegación
- ~60% de cobertura con XCTest + Swift Testing
- **NexoServer v0.1** corriendo en tu Mac: posts, usuarios y login con SQLite, más `NexoShared`

---

# NIVEL 3: 🧠 SENIOR
**Objetivo:** Dominar concurrencia moderna, rendimiento, módulos y features complejas.
**En Nexo:** Chat en tiempo real, stories/video, notificaciones, modularización.

### Concurrencia moderna 🟢
- Structured concurrency: `async let`, `TaskGroup`, `withThrowingDiscardingTaskGroup`
- Cancelación cooperativa, `Task.checkCancellation()`
- **Actors**, `@MainActor`, global actors, reentrancia de actors
- `Sendable`, `@Sendable`, `sending`
- `AsyncSequence`, `AsyncStream`, `AsyncThrowingStream`
- **Swift 6 strict concurrency** (data-race safety en compilación)
- Swift 6.2: *approachable concurrency*, `@concurrent`, aislamiento por defecto en `MainActor`
- 🔁 Migrar el proyecto de Swift 5 mode → **Swift 6 language mode**
- 🔁 Reemplazar `DispatchQueue` + locks por actors; `Combine` → `AsyncSequence` donde aplique

### Lenguaje avanzado
- Result builders (cómo funciona `@ViewBuilder`)
- `@dynamicMemberLookup`, `@dynamicCallable`, `KeyPath`s
- Typed throws `throws(MyError)` 🟢
- Copy-on-Write, implementar un tipo propio con CoW
- Interoperabilidad con **Objective-C** 🟤 (`@objc`, bridging header, `NS_SWIFT_NAME`)

### Features complejas
- **WebSockets** (`URLSessionWebSocketTask`) para el chat
- Sincronización offline-first, resolución de conflictos
- **AVFoundation**: cámara, grabación, reproducción, `AVPlayer`
- Core Image / filtros
- **APNs** + Notification Service Extension
- **WidgetKit**, **Live Activities**, **App Intents**
- Deep links y Universal Links
- Accesibilidad (VoiceOver, Dynamic Type), localización (String Catalogs 🟢)

### Arquitectura
- **Clean Architecture** (Domain / Data / Presentation)
- **VIPER** 🟤 (tienes que conocerla, sigue en apps grandes)
- **TCA** (The Composable Architecture): unidireccional 🟢
- Redux/unidireccional propio
- **Modularización con SPM** (feature modules, módulos de interfaz)
- Design System compartido UIKit + SwiftUI

### Rendimiento
- **Instruments**: Time Profiler, Allocations, Leaks, Hangs, SwiftUI instrument
- Memory Graph Debugger
- Optimizar scroll (prefetching, reuso de celdas, decoding de imágenes en background)
- Tiempo de arranque (launch time), tamaño del binario
- Rendimiento de SwiftUI: identidad, `Equatable` views, evitar invalidaciones

### Testing
- Pirámide de testing, TDD
- Snapshot testing (swift-snapshot-testing)
- Tests de integración con `URLProtocol` mock
- Tests de concurrencia deterministas
- Test Plans, code coverage

### DevOps
- CI/CD: **Xcode Cloud**, GitHub Actions, **Fastlane** 🟤/🟢
- Firma de código, provisioning, TestFlight
- Feature flags, analytics, crash reporting

### 🖥️ NexoServer (intermedio)
- **Autenticación JWT** (access y refresh tokens), hash de contraseñas con `Bcrypt`
- **WebSockets** en Vapor para el chat (salas y broadcast), gestionando las conexiones con un `actor`
- Migrar de SQLite a **PostgreSQL** (Homebrew o Docker), relaciones en Fluent y paginación
- Subida de archivos (fotos y videos de stories) con streaming del body
- Envío de **push notifications** desde el servidor (paquete APNSwift / `VaporAPNS`)
- Middleware: logging, CORS, rate limiting y manejo de errores (`AbortError`)
- Swift 6 strict concurrency también en el servidor
- CI: tests del servidor en GitHub Actions (macOS y Linux)

### 🎯 Entregables en Nexo
- **NexoServer v0.5**: auth JWT, chat por WebSocket, Postgres y push notifications
- Chat en tiempo real (actors + AsyncStream + WebSocket + SwiftData)
- Stories con cámara y filtros
- Push notifications + widget + Live Activity
- App dividida en ~8 Swift Packages
- Proyecto compilando en **Swift 6 mode** sin warnings
- CI con tests, snapshots y deploy a TestFlight

---

# NIVEL 4: 🏗️ STAFF
**Objetivo:** Decisiones técnicas que afectan a varios equipos. Plataforma, escalabilidad, migraciones grandes.
**En Nexo:** Pensamos como si 10 equipos trabajaran en la app.

- **Estrategia de migración** UIKit/Storyboard → SwiftUI incremental (qué migrar, qué no, y por qué)
- **Arquitectura de plataforma**: módulos de interfaz vs implementación, *dependency container*, *service locator* vs DI en compilación
- **Server-Driven UI** (el feed renderizado desde JSON del servidor)
- Networking avanzado: HTTP/2, HTTP/3, retry/backoff, certificate pinning, GraphQL vs REST
- **Swift on Server con Vapor**: construir `NexoServer`, compartir modelos entre app y servidor
- Seguridad: Keychain avanzado, CryptoKit, **Passkeys**, App Attest, jailbreak detection
- Observabilidad: `os.Logger`, `OSSignposter`, MetricKit
- Build system: tiempos de compilación, `-Xfrontend -warn-long-function-bodies`, caché de builds, XCFrameworks, binarios vs fuente
- Tuist / XcodeGen 🟢 vs `.pbxproj` manual 🟤
- RFCs / ADRs (Architecture Decision Records) documentados en el repo
- Guías de código, linters (SwiftLint, swift-format)

### 🖥️ NexoServer (plataforma)
- Endpoints de **Server-Driven UI** (el servidor define el layout del feed)
- Versionado de API (`/v1`, `/v2`) y compatibilidad con versiones viejas de la app
- **Docker** y `docker compose` (NexoServer, Postgres y Redis) corriendo en tu Mac
- Redis para caché, sesiones y colas (jobs en background con `Queues`)
- Observabilidad: `swift-log`, `swift-metrics`, `swift-distributed-tracing`
- OpenAPI: **swift-openapi-generator** 🟢 genera el cliente de la app y el servidor desde un solo `openapi.yaml`
- Alternativa moderna a Vapor: **Hummingbird** 🟢 (compararlos y documentar un ADR)

### 🎯 Entregables en Nexo
- Documento de estrategia de migración + ADRs
- Feed con Server-Driven UI
- **NexoServer v1.0** en Docker con Postgres, Redis, OpenAPI y métricas
- Modelos compartidos app ↔ servidor (`NexoShared` y el cliente generado por OpenAPI)
- Dashboard de tiempos de build y métricas

---

# NIVEL 5: 🧩 SENIOR STAFF
**Objetivo:** Profundidad en el lenguaje y runtime; resolver los problemas más difíciles.

- **Memory layout**: `MemoryLayout`, stride/alignment, existential containers, witness tables, vtables
- Dispatch: estático vs dinámico, `final`, `@inlinable`, `@usableFromInline`, Whole Module Optimization
- **Unsafe Swift**: `UnsafePointer`, `UnsafeRawBufferPointer`, `withUnsafeBytes`
- Nuevos tipos seguros de memoria 🟢: `Span`, `RawSpan`, `InlineArray`
- **Noncopyable types** (`~Copyable`), `consuming`, `borrowing` 🟢
- Parameter packs (variadic generics) 🟢
- ABI stability, library evolution (`@frozen`, `BUILD_LIBRARY_FOR_DISTRIBUTION`)
- Interoperabilidad **C / C++** 🟢 con Swift
- Metal básico para filtros de video en tiempo real
- Rendimiento extremo: análisis de ensamblador en Compiler Explorer, benchmarks (package-benchmark)
- 🖥️ **SwiftNIO** directo: `Channel`, `ChannelHandler`, `ByteBuffer`, event loops (lo que Vapor usa por debajo)
- 🖥️ Protocolo binario propio para el chat sobre NIO y pruebas de carga (miles de conexiones en tu Mac)

### 🎯 Entregables en Nexo
- Servidor de chat en SwiftNIO puro con protocolo binario, medido con benchmarks
- Pipeline de filtros de video en Metal
- Parser binario de mensajes del chat con `Span`/unsafe
- Librería interna distribuida como XCFramework con library evolution
- Módulo en C++ integrado con Swift (ej. compresión)

---

# NIVEL 6: 🏛️ PRINCIPAL ENGINEER
**Objetivo:** Crear herramientas y abstracciones que usa toda la organización.

- **Swift Macros** 🟢 (SwiftSyntax): crear macros propias (`@AutoMockable`, `@DependencyInjected`, `#URL`)
- **Swift Package plugins** (build tool plugins, command plugins)
- SourceKit-LSP, generación de código (Sourcery 🟤 → Macros 🟢)
- DSLs con result builders (ej. DSL para layouts del Server-Driven UI)
- Diseño de APIs públicas (API Design Guidelines de Swift)
- **Distributed actors** 🟢: chat distribuido entre varias instancias de NexoServer (`swift-distributed-actors` / cluster)
- Swift en otras plataformas: Linux, Windows, **Embedded Swift**, WebAssembly
- 🖥️ Macros compartidas entre la app y el servidor (por ejemplo, `@APIModel` genera DTO, validación y mocks)
- Visión técnica multi-año, mentoring, influencia técnica

### 🎯 Entregables en Nexo
- Paquete `NexoMacros` con 3+ macros reales usadas en el proyecto
- Plugin de SPM que valida la arquitectura (ej. prohíbe imports entre features)
- DSL propio para Server-Driven UI

---

# NIVEL 7: 🌟 DISTINGUISHED ENGINEER
**Objetivo:** Impacto a nivel industria.

- **Compilador Swift**: pipeline (Parse → Sema → SILGen → SIL optimizer → IRGen → LLVM)
- Leer y entender **SIL** (`swiftc -emit-sil`) e IR de LLVM
- **Swift Evolution**: leer, discutir y proponer propuestas (SE-XXXX)
- Contribuir a repos open source de Swift (swift, swift-foundation, swift-syntax, swift-testing, swift-nio, vapor)
- Runtime de Swift: metadatos, reflexión (`Mirror`), *type metadata*
- Charlas, papers, liderazgo técnico público

### 🎯 Entregables en Nexo
- Análisis del SIL de código crítico de Nexo y optimizaciones justificadas
- Un PR (aunque sea pequeño) a un repositorio oficial de Swift
- Documento tipo *pitch* de Swift Evolution basado en un problema real de Nexo

---

# NIVEL 8: 🏆 FELLOW
**Objetivo:** Definir el rumbo de la tecnología.

- Diseño de lenguajes y sistemas de tipos (ownership, efectos, concurrencia)
- Investigación: modelos de memoria, compiladores, runtimes
- Crear herramientas o frameworks adoptados por la industria
- En programación esto significa: **entender por qué Swift es como es**, sus trade-offs contra Rust, Kotlin, C++ y otros, y poder diseñar la siguiente generación

### 🎯 Entregable final
- Publicar parte de Nexo como open source (ej. el Design System, las macros o el motor SDUI) con documentación DocC 🟢

---

## 📊 Tabla resumen: Viejo vs Nuevo

| Área | 🟤 Viejo / Legacy | 🟢 Nuevo / Moderno |
|---|---|---|
| UI | Storyboard, XIB, UIKit | SwiftUI |
| Ciclo de vida | AppDelegate | SceneDelegate → `@main App` SwiftUI |
| Listas | `UITableViewDataSource` | Diffable + Compositional, SwiftUI `List` |
| Navegación SwiftUI | `NavigationView` | `NavigationStack` |
| Concurrencia | GCD, `OperationQueue`, locks | async/await, actors, Swift 6 |
| Reactividad | KVO, NotificationCenter, Delegates | Combine → Observation (`@Observable`), AsyncSequence |
| Estado SwiftUI | `ObservableObject`, `@Published` | `@Observable`, `@Bindable` |
| Persistencia | Core Data, archivos | SwiftData |
| Red | Completion handlers | `async` URLSession |
| Testing | XCTest | Swift Testing |
| Dependencias | CocoaPods, Carthage | Swift Package Manager |
| Generación de código | Sourcery | Swift Macros |
| Proyecto | `.pbxproj` manual | Tuist / SPM |
| Strings | `.strings` / `.stringsdict` | String Catalogs (`.xcstrings`) |
| Memoria | `UnsafePointer` | `Span`, `InlineArray`, `~Copyable` |
| Interop | Objective-C | C++ interop |
| Docs | Comentarios / Jazzy | DocC |
| Servidor (Vapor) | `EventLoopFuture`, `XCTVapor` | async/await, `VaporTesting`, Hummingbird |
| Contratos API | DTOs escritos a mano | `swift-openapi-generator` |

---

## 🖥️ NexoServer en tu Mac: guía rápida

**Requisitos:** macOS con Xcode instalado (ya trae el toolchain de Swift) y Homebrew.

> 💡 **Homebrew es opcional.** Si no lo tienes, instálalo desde https://brew.sh o crea el servidor sin el toolbox: `swift package init --type executable --name NexoServer` y agrega `vapor/vapor` como dependencia en `Package.swift` (lo haremos paso a paso el día que toque).

```bash
# 1. Verificar Swift
swift --version

# 2. Instalar el toolbox de Vapor
brew install vapor

# 3. Crear el servidor dentro del repo (se hará el día que toque en el roadmap)
cd ~/Documents/GitHubCopilot/RoadmapSwift
vapor new NexoServer -n

# 4. Correrlo
cd NexoServer
swift run                      # → http://127.0.0.1:8080

# 5. Probarlo
curl http://127.0.0.1:8080/hello

# 6. Tests
swift test
```

**También se puede abrir en Xcode:** `open Package.swift` (o `xed .`), elegir el esquema `NexoServer` > **My Mac** y darle Run.

**Conectar la app con el servidor:**
- **Simulador iOS:** usa `http://127.0.0.1:8080` directamente.
- **iPhone físico:** corre `swift run NexoServer serve --hostname 0.0.0.0` y usa la IP de tu Mac (`http://192.168.x.x:8080`).
- En el `Info.plist` de la app agrega `NSAppTransportSecurity` > `NSAllowsLocalNetworking = YES` (para HTTP sin TLS en local).

**Más adelante (Senior/Staff):**
```bash
brew install postgresql@16 && brew services start postgresql@16   # o bien:
docker compose up -d db                                            # Postgres en Docker
```

---

## 📅 Cronograma sugerido (a tu ritmo, ~1–2 h/día)

| Fase | Nivel | Duración aprox. | Días |
|---|---|---|---|
| 1 | Junior | 4–6 semanas | Día 1–30 |
| 2 | Mid | 8–10 semanas | Día 31–90 |
| 3 | Senior | 12–16 semanas | Día 91–190 |
| 4 | Staff | 8–10 semanas | Día 191–250 |
| 5 | Senior Staff | ~7 semanas | Día 251–300 |
| 6 | Principal | ~7 semanas | Día 301–350 |
| 7–8 | Distinguished / Fellow | Continuo | Día 351+ |

> 📌 **1 "Día" = 1 sesión de estudio (1–2 h)**. Las semanas del cuadro suponen 7 sesiones por semana. Si estudias 5 días a la semana, multiplica las semanas por 1.4 (por ejemplo, 50 días ≈ 10 semanas).

> 🖥️ **NexoServer dentro del cronograma:** se crea alrededor del **Día 60** (Mid) y desde ahí se alterna con la app (más o menos 1 de cada 4 días). Senior: v0.5 (JWT, WebSockets, Postgres, push). Staff: v1.0 (Docker, Redis, OpenAPI). Senior Staff: SwiftNIO. Principal: distributed actors.

> ⚠️ En la vida real, llegar a Fellow toma más de 15 años. Este plan te da **el conocimiento técnico y la práctica**. La experiencia, el liderazgo y el impacto se construyen con el tiempo.

---

## 🔄 Dinámica diaria
Cada día pide: **"Día N"** y recibirás:
1. 🎯 Objetivo del día
2. 📚 Concepto (viejo vs nuevo si aplica)
3. 💻 Qué codificar en Nexo (archivos concretos)
4. 🧪 Test a escribir
5. ✅ Checklist / reto extra
6. 📊 Calificación al revisar tu trabajo → ver [`Dias/Progreso.md`](Dias/Progreso.md)

### Día 1 ✅ → ver [`Dias/Dia-01.md`](Dias/Dia-01.md)
- Renombrar/estructurar el proyecto actual `RoadmapSwift` como Nexo (carpetas: `App`, `Features`, `Core`, `Resources`)
- Entender `AppDelegate` vs `SceneDelegate` que ya tienes
- Crear en `Main.storyboard` la pantalla de **Login** con Auto Layout y `UIStackView`
- Conectar `IBOutlet`s/`IBAction`s
- Primer test XCTest: `EmailValidatorTests`

### Día 2 ✅ → ver [`Dias/Dia-02.md`](Dias/Dia-02.md)
- Modelos `User`, `Post` y `PostContent` (struct vs class, enums con valores asociados)
- `Codable` con `CodingKeys`, `init(from:)` manual y snake_case
- `feed.json` mock + `MockFeedLoader` con `throws`
- 11 tests nuevos con fixtures (18 en total)

### Día 3 ✅ → ver [`Dias/Dia-03.md`](Dias/Dia-03.md)
- Pantalla de **Registro** en Storyboard abierta con un segue `Show`
- Pasar datos hacia adelante (`prepare(for:sender:)`) y hacia atrás (delegate propio `weak`)
- `PasswordValidator` (`CaseIterable`, `filter`, `map`) y `RegistrationForm` testeable sin UI
- 13 tests nuevos, incluido un test de humo del storyboard (32 en total)

### Día 4 ✅ → ver [`Dias/Dia-04.md`](Dias/Dia-04.md)
- **Feed** con `UITableViewController` en un storyboard propio (`Feed.storyboard`), `PostCell` con outlets y alto automático
- Reciclaje de celdas (`dequeueReusableCell`, `prepareForReuse`) y navegación con `instantiateInitialViewController(creator:)`
- Protocolo `FeedLoader` para inyectar el loader (stub en tests)
- **ARC**: `strong`/`weak`/`unowned`, retain cycle con closures, `deinit` y Memory Graph Debugger
- 8 tests nuevos, incluido un test que detecta memory leaks (40 en total)

### Día 5 ✅ → ver [`Dias/Dia-05.md`](Dias/Dia-05.md)
- Ventana creada por código en el `SceneDelegate` y `AppRouter` que cambia el `rootViewController` (Login ↔ tabs)
- `UITabBarController` por código: **Inicio** (Feed, UIKit) y **Cuenta** (SwiftUI con `UIHostingController`)
- Sesión con `UserDefaults` 🟤 y preferencias con `@AppStorage` 🟢; SwiftUI: `@State`, `@Binding`, `Form`, `NavigationStack`, `#Preview`
- ARC: quién es dueño del router; 10 tests nuevos, dos detectan leaks (50 en total)

### Día 6 ✅ → ver [`Dias/Dia-06.md`](Dias/Dia-06.md)
- Avatares con `URLSession.dataTask` y completion handlers 🟤, validación de `statusCode` y `NSCache`
- Hilo principal: `DispatchQueue.main.async` 🟤 vs `@MainActor` 🟢; `[weak …]` en closures asíncronas
- El bug de la imagen equivocada en celdas recicladas: cancelar + `representedPostID`
- Tests sin internet: spy y `URLProtocol` stub; 8 tests nuevos (58 en total)
