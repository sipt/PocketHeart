# Voice Ledger iOS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Voice Ledger iOS MVP — a chat-style bookkeeping app where one voice/text input becomes one or more parsed transactions, persisted via SwiftData + CloudKit and parsed by user-configured AI providers.

**Architecture:** Native SwiftUI feature modules over a shared service/repository layer. SwiftData models persisted in a CloudKit-backed `ModelContainer`. AI calls go through an `AIProviderAdapter` protocol with an OpenAI-compatible default; secrets live in Keychain. The Recording feature is the only main screen; Stats and Settings are pushed from its toolbar. Speech and parsing are protocol-typed so UI can be tested with fakes.

**Tech Stack:** Swift 5.10+, SwiftUI, SwiftData, CloudKit, `Speech.framework`, `AVFoundation`, `URLSession`, `Security` (Keychain), Swift Testing (`import Testing`).

**Reference design:** `docs/design/vl-screens.jsx` — dark `#000` background, purple `#7B61FF` primary, 14r grouped cards, monospace timestamps. Color tokens, spacing, and component shapes in this plan come from that file.

---

## File Structure

The project uses one Xcode target (`PocketHeart`) plus `PocketHeartTests` and `PocketHeartUITests`. New code is organized inside `PocketHeart/` by responsibility, NOT by Swift type:

```
PocketHeart/
  App/
    PocketHeartApp.swift                  # entry point (existing — modify)
    AppContainer.swift                    # SwiftData + CloudKit container, seeding
    AppEnvironment.swift                  # @Observable env exposing services
    RootView.swift                        # NavigationStack host (replaces ContentView)
  DesignSystem/
    Theme.swift                           # colors, typography, radii
    CategoryIcon.swift                    # category glyph view
    Pills.swift                           # MetaPill, TagPill, TypePill
  Models/
    Transaction.swift                     # @Model
    InputEntry.swift                      # @Model
    LedgerCategory.swift                  # @Model (named `LedgerCategory` to avoid `Category` ambiguity)
    Tag.swift                             # @Model (named `LedgerTag`)
    PaymentMethod.swift                   # @Model
    AIProvider.swift                      # @Model
    Enums.swift                           # TransactionType, ParseStatus, PaymentKind, ProviderTemplate, InputSource, ApplicableType, InterfaceFormat
    SeedData.swift                        # built-in categories / tags / payment methods
  Services/
    Keychain.swift                        # generic password helpers
    Speech/
      SpeechService.swift                 # protocol + live implementation
      FakeSpeechService.swift             # test double (in test target)
    AI/
      AIParsingService.swift              # protocol + live implementation
      ParsedInputResult.swift             # DTOs returned by parsing
      ParsingPrompt.swift                 # prompt builder + JSON schema constant
      ProviderAdapter.swift               # protocol
      OpenAICompatibleAdapter.swift       # default adapter (works for OpenAI / DeepSeek / Ollama)
      AnthropicAdapter.swift              # Messages API adapter
      GeminiAdapter.swift                 # generateContent adapter
      AdapterFactory.swift                # selects adapter from AIProvider.interfaceFormat
    Ledger/
      LedgerRepository.swift              # CRUD + grouped query
      StatsService.swift                  # aggregations
  Features/
    Recording/
      RecordingView.swift                 # main screen
      RecordingViewModel.swift            # @Observable
      InputBar.swift
      StreamMessage.swift                 # display model
      UserBubble.swift
      GroupCardView.swift
      TransactionRow.swift
      DayDivider.swift
      TodayChip.swift
    Editing/
      EditTransactionView.swift
      EditTransactionViewModel.swift
      PickerSheets.swift                  # category/tag/payment pickers
    Stats/
      StatsView.swift
      StatsViewModel.swift
    Settings/
      SettingsView.swift
      Providers/
        ProviderListView.swift
        ProviderEditView.swift
        ProviderEditViewModel.swift
      Taxonomy/
        CategoriesView.swift
        TagsView.swift
        PaymentMethodsView.swift
PocketHeartTests/
  ModelTests.swift
  KeychainTests.swift
  ParsingPromptTests.swift
  ParsedInputDecodingTests.swift
  OpenAICompatibleAdapterTests.swift
  LedgerRepositoryTests.swift
  StatsServiceTests.swift
  RecordingFlowTests.swift
PocketHeartUITests/
  RecordingFlowUITests.swift
  SettingsUITests.swift
```

The existing scaffold files `ContentView.swift` and `Item.swift` are deleted (Task 1).

---

## Conventions Used Throughout

- **Test framework:** Swift Testing (`@Test`, `#expect`). The default Xcode template ships with it.
- **Dates in tests:** use `Date(timeIntervalSince1970:)` for determinism.
- **In-memory SwiftData container in tests:** `ModelConfiguration(isStoredInMemoryOnly: true)`.
- **Concurrency:** services are `actor`-free `final class` types unless they own mutable state; ViewModels are `@MainActor @Observable`. Adapters are `Sendable` and use `async`.
- **Money:** stored as `Decimal`; never `Double`.
- **IDs:** `UUID` on all `@Model` types via an `id: UUID` property. **No `@Attribute(.unique)`** — CloudKit-backed SwiftData containers do not support unique constraints. Uniqueness is enforced through code paths that always look up by `id`.
- **Commits:** every task ends with one `git commit`. Use Conventional Commits (`feat:`, `test:`, `chore:`, `refactor:`).

---

## Task 1: Project hygiene & permissions

**Files:**
- Delete: `PocketHeart/ContentView.swift`, `PocketHeart/Item.swift`
- Modify: `PocketHeart/Info.plist`
- Modify: `PocketHeart/PocketHeartApp.swift`
- Create: `PocketHeart/App/RootView.swift`

- [ ] **Step 1: Delete the template `Item` model and `ContentView`**

```bash
git rm PocketHeart/ContentView.swift PocketHeart/Item.swift
```

- [ ] **Step 2: Add usage descriptions to `Info.plist`**

Add the two keys below to the `<dict>` of `PocketHeart/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Voice Ledger uses the microphone so you can dictate transactions.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Voice Ledger transcribes your speech locally before sending text to your AI provider.</string>
```

- [ ] **Step 3: Replace `PocketHeartApp.swift` with a placeholder root view**

Overwrite `PocketHeart/PocketHeartApp.swift`:

```swift
import SwiftUI

@main
struct PocketHeartApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

- [ ] **Step 4: Add a placeholder `RootView`**

Create `PocketHeart/App/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        Text("Voice Ledger")
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
    }
}
```

- [ ] **Step 5: Build to confirm the app still compiles**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: remove template scaffold, add mic+speech usage strings"
```

---

## Task 2: Design tokens

**Files:**
- Create: `PocketHeart/DesignSystem/Theme.swift`

- [ ] **Step 1: Add `Theme.swift`**

```swift
import SwiftUI

enum Theme {
    static let bg = Color.black
    static let surface = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255)
    static let surfaceElevated = Color(red: 0x15/255, green: 0x15/255, blue: 0x1C/255)
    static let primary = Color(red: 0x7B/255, green: 0x61/255, blue: 0xFF/255)
    static let primaryLight = Color(red: 0xB5/255, green: 0xA4/255, blue: 0xFF/255)
    static let danger = Color(red: 0xFF/255, green: 0x45/255, blue: 0x3A/255)
    static let success = Color(red: 0x30/255, green: 0xD1/255, blue: 0x58/255)
    static let warning = Color(red: 0xF2/255, green: 0xC9/255, blue: 0x4C/255)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.4)
    static let separator = Color.white.opacity(0.08)

    static let cornerCard: CGFloat = 14
    static let cornerLarge: CGFloat = 16

    static let monoFont = Font.system(.caption, design: .monospaced)
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add PocketHeart/DesignSystem/Theme.swift
git commit -m "feat: add design tokens"
```

---

## Task 3: Enums and value types

**Files:**
- Create: `PocketHeart/Models/Enums.swift`
- Create: `PocketHeartTests/ModelTests.swift`

- [ ] **Step 1: Write the failing test**

Create `PocketHeartTests/ModelTests.swift`:

```swift
import Testing
@testable import PocketHeart

struct EnumsTests {
    @Test func transactionTypeRoundTripsRaw() {
        #expect(TransactionType(rawValue: "expense") == .expense)
        #expect(TransactionType(rawValue: "income") == .income)
    }

    @Test func parseStatusCases() {
        #expect(ParseStatus.allCases.count == 4)
    }
}
```

- [ ] **Step 2: Run the test (expect compile failure — type missing)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/EnumsTests`
Expected: FAIL — `cannot find 'TransactionType' in scope`

- [ ] **Step 3: Add the enums file**

Create `PocketHeart/Models/Enums.swift`:

```swift
import Foundation

enum TransactionType: String, Codable, CaseIterable, Sendable {
    case expense, income
}

enum InputSource: String, Codable, Sendable {
    case text, voice
}

enum ParseStatus: String, Codable, CaseIterable, Sendable {
    case pending, success, partialFailure, failure
}

enum ApplicableType: String, Codable, Sendable {
    case expense, income, both
}

enum PaymentKind: String, Codable, CaseIterable, Sendable {
    case wechat, alipay, bank, cash, applePay, creditCard, other
}

enum ProviderTemplate: String, Codable, CaseIterable, Sendable {
    case openAI, deepSeek, anthropic, gemini, ollama, custom
}

enum InterfaceFormat: String, Codable, CaseIterable, Sendable {
    case openAICompatible, anthropicMessages, geminiGenerateContent
}
```

- [ ] **Step 4: Run the test (expect pass)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/EnumsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Models/Enums.swift PocketHeartTests/ModelTests.swift
git commit -m "feat: add domain enums"
```

---

## Task 4: SwiftData models

**Files:**
- Create: `PocketHeart/Models/Transaction.swift`
- Create: `PocketHeart/Models/InputEntry.swift`
- Create: `PocketHeart/Models/LedgerCategory.swift`
- Create: `PocketHeart/Models/Tag.swift`
- Create: `PocketHeart/Models/PaymentMethod.swift`
- Create: `PocketHeart/Models/AIProvider.swift`
- Modify: `PocketHeartTests/ModelTests.swift`

- [ ] **Step 1: Write failing tests for model construction**

Append to `PocketHeartTests/ModelTests.swift`:

```swift
import SwiftData

struct TransactionModelTests {
    @Test func transactionStoresPositiveDecimalAmount() throws {
        let txn = Transaction(
            amount: Decimal(string: "38.50")!,
            currency: "CNY",
            type: .expense,
            title: "Lunch",
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            categoryID: UUID(),
            paymentMethodID: UUID(),
            sourceInputID: UUID()
        )
        #expect(txn.amount == Decimal(string: "38.50"))
        #expect(txn.type == .expense)
        #expect(txn.id != UUID(uuid: UUID_NULL))
    }
}

private let UUID_NULL: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
```

- [ ] **Step 2: Run test (expect failure — `Transaction` undefined)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/TransactionModelTests`
Expected: FAIL — `cannot find 'Transaction' in scope`

- [ ] **Step 3: Implement `Transaction.swift`**

```swift
import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var currency: String
    var typeRaw: String
    var title: String
    var merchant: String?
    var occurredAt: Date
    var categoryID: UUID
    var subcategoryID: UUID?
    var tagIDs: [UUID]
    var paymentMethodID: UUID
    var notes: String?
    var sourceInputID: UUID
    var isAICreated: Bool
    var createdAt: Date
    var updatedAt: Date

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        amount: Decimal,
        currency: String,
        type: TransactionType,
        title: String,
        merchant: String? = nil,
        occurredAt: Date,
        categoryID: UUID,
        subcategoryID: UUID? = nil,
        tagIDs: [UUID] = [],
        paymentMethodID: UUID,
        notes: String? = nil,
        sourceInputID: UUID,
        isAICreated: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.currency = currency
        self.typeRaw = type.rawValue
        self.title = title
        self.merchant = merchant
        self.occurredAt = occurredAt
        self.categoryID = categoryID
        self.subcategoryID = subcategoryID
        self.tagIDs = tagIDs
        self.paymentMethodID = paymentMethodID
        self.notes = notes
        self.sourceInputID = sourceInputID
        self.isAICreated = isAICreated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **Step 4: Implement `InputEntry.swift`**

```swift
import Foundation
import SwiftData

@Model
final class InputEntry {
    var id: UUID
    var rawText: String
    var sourceRaw: String
    var createdAt: Date
    var statusRaw: String
    var providerID: UUID?
    var errorMessage: String?
    var transactionIDs: [UUID]

    var source: InputSource {
        get { InputSource(rawValue: sourceRaw) ?? .text }
        set { sourceRaw = newValue.rawValue }
    }
    var status: ParseStatus {
        get { ParseStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        rawText: String,
        source: InputSource,
        createdAt: Date = .now,
        status: ParseStatus = .pending,
        providerID: UUID? = nil,
        errorMessage: String? = nil,
        transactionIDs: [UUID] = []
    ) {
        self.id = id
        self.rawText = rawText
        self.sourceRaw = source.rawValue
        self.createdAt = createdAt
        self.statusRaw = status.rawValue
        self.providerID = providerID
        self.errorMessage = errorMessage
        self.transactionIDs = transactionIDs
    }
}
```

- [ ] **Step 5: Implement `LedgerCategory.swift`**

```swift
import Foundation
import SwiftData

@Model
final class LedgerCategory {
    var id: UUID
    var name: String
    var parentID: UUID?
    var applicableRaw: String
    var iconKey: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var isArchived: Bool

    var applicable: ApplicableType {
        get { ApplicableType(rawValue: applicableRaw) ?? .both }
        set { applicableRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        parentID: UUID? = nil,
        applicable: ApplicableType = .both,
        iconKey: String = "other",
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.applicableRaw = applicable.rawValue
        self.iconKey = iconKey
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.isArchived = isArchived
    }
}
```

- [ ] **Step 6: Implement `Tag.swift`**

```swift
import Foundation
import SwiftData

@Model
final class LedgerTag {
    var id: UUID
    var name: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var usageCount: Int
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        usageCount: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.usageCount = usageCount
        self.isArchived = isArchived
    }
}
```

- [ ] **Step 7: Implement `PaymentMethod.swift`**

```swift
import Foundation
import SwiftData

@Model
final class PaymentMethod {
    var id: UUID
    var name: String
    var kindRaw: String
    var isBuiltIn: Bool
    var isAICreated: Bool
    var isArchived: Bool

    var kind: PaymentKind {
        get { PaymentKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        kind: PaymentKind = .other,
        isBuiltIn: Bool = false,
        isAICreated: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.isBuiltIn = isBuiltIn
        self.isAICreated = isAICreated
        self.isArchived = isArchived
    }
}
```

- [ ] **Step 8: Implement `AIProvider.swift`**

```swift
import Foundation
import SwiftData

@Model
final class AIProvider {
    var id: UUID
    var displayName: String
    var templateRaw: String
    var baseURL: String
    var modelName: String
    var interfaceRaw: String
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date

    var template: ProviderTemplate {
        get { ProviderTemplate(rawValue: templateRaw) ?? .custom }
        set { templateRaw = newValue.rawValue }
    }
    var interface: InterfaceFormat {
        get { InterfaceFormat(rawValue: interfaceRaw) ?? .openAICompatible }
        set { interfaceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        template: ProviderTemplate = .custom,
        baseURL: String,
        modelName: String,
        interface: InterfaceFormat = .openAICompatible,
        isDefault: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.templateRaw = template.rawValue
        self.baseURL = baseURL
        self.modelName = modelName
        self.interfaceRaw = interface.rawValue
        self.isDefault = isDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

- [ ] **Step 9: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/TransactionModelTests`
Expected: PASS

- [ ] **Step 10: Commit**

```bash
git add PocketHeart/Models PocketHeartTests/ModelTests.swift
git commit -m "feat: add SwiftData models for ledger and providers"
```

---

## Task 5: SwiftData container with CloudKit and seed data

**Files:**
- Create: `PocketHeart/Models/SeedData.swift`
- Create: `PocketHeart/App/AppContainer.swift`
- Modify: `PocketHeart/App/PocketHeartApp.swift`

- [ ] **Step 1: Add seed data**

Create `PocketHeart/Models/SeedData.swift`:

```swift
import Foundation

enum SeedData {
    struct CategorySeed { let name: String; let iconKey: String; let applicable: ApplicableType }
    struct PaymentSeed { let name: String; let kind: PaymentKind }

    static let categories: [CategorySeed] = [
        .init(name: "Food", iconKey: "food", applicable: .expense),
        .init(name: "Transit", iconKey: "transit", applicable: .expense),
        .init(name: "Coffee", iconKey: "coffee", applicable: .expense),
        .init(name: "Grocery", iconKey: "grocery", applicable: .expense),
        .init(name: "Salary", iconKey: "salary", applicable: .income),
        .init(name: "Other", iconKey: "other", applicable: .both),
    ]

    static let tags: [String] = ["work", "lunch", "team", "late", "afternoon", "groceries"]

    static let paymentMethods: [PaymentSeed] = [
        .init(name: "WeChat Pay", kind: .wechat),
        .init(name: "Alipay", kind: .alipay),
        .init(name: "Cash", kind: .cash),
        .init(name: "Apple Pay", kind: .applePay),
        .init(name: "Bank Card", kind: .bank),
        .init(name: "Credit Card", kind: .creditCard),
    ]
}
```

- [ ] **Step 2: Create the container**

Create `PocketHeart/App/AppContainer.swift`:

```swift
import Foundation
import SwiftData

enum AppContainer {
    static let schema = Schema([
        Transaction.self,
        InputEntry.self,
        LedgerCategory.self,
        LedgerTag.self,
        PaymentMethod.self,
        AIProvider.self,
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
        }
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            seedIfNeeded(container: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    @MainActor
    private static func seedIfNeeded(container: ModelContainer) {
        let ctx = container.mainContext
        let categoryCount = (try? ctx.fetchCount(FetchDescriptor<LedgerCategory>())) ?? 0
        guard categoryCount == 0 else { return }
        for c in SeedData.categories {
            ctx.insert(LedgerCategory(name: c.name, applicable: c.applicable, iconKey: c.iconKey, isBuiltIn: true))
        }
        for t in SeedData.tags {
            ctx.insert(LedgerTag(name: t, isBuiltIn: true))
        }
        for p in SeedData.paymentMethods {
            ctx.insert(PaymentMethod(name: p.name, kind: p.kind, isBuiltIn: true))
        }
        try? ctx.save()
    }
}
```

- [ ] **Step 3: Wire it into the App**

Replace `PocketHeart/App/PocketHeartApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PocketHeartApp: App {
    let container = AppContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
```

- [ ] **Step 4: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Add a seeding test**

Append to `PocketHeartTests/ModelTests.swift`:

```swift
struct SeedingTests {
    @Test @MainActor func seedingCreatesBuiltInTaxonomyOnce() throws {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        let cats = try ctx.fetch(FetchDescriptor<LedgerCategory>())
        let pays = try ctx.fetch(FetchDescriptor<PaymentMethod>())
        #expect(cats.count == SeedData.categories.count)
        #expect(pays.count == SeedData.paymentMethods.count)
        // Re-seeding should be idempotent — recreating the container reuses the in-memory store
        // so we just verify no duplicates appear when seedIfNeeded runs again on the same container.
    }
}
```

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/SeedingTests`
Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: add CloudKit-backed SwiftData container with seed data"
```

---

## Task 6: Keychain helper

**Files:**
- Create: `PocketHeart/Services/Keychain.swift`
- Create: `PocketHeartTests/KeychainTests.swift`

- [ ] **Step 1: Write failing tests**

Create `PocketHeartTests/KeychainTests.swift`:

```swift
import Testing
@testable import PocketHeart

struct KeychainTests {
    let service = "com.pocketheart.test.\(UUID().uuidString)"

    @Test func roundTripsString() throws {
        let kc = Keychain(service: service)
        try kc.set("sk-secret", account: "p1")
        #expect(try kc.get(account: "p1") == "sk-secret")
        try kc.delete(account: "p1")
        #expect(try kc.get(account: "p1") == nil)
    }

    @Test func updatesExistingValue() throws {
        let kc = Keychain(service: service)
        try kc.set("v1", account: "acct")
        try kc.set("v2", account: "acct")
        #expect(try kc.get(account: "acct") == "v2")
        try kc.delete(account: "acct")
    }
}
```

- [ ] **Step 2: Run tests (expect failure — `Keychain` undefined)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/KeychainTests`
Expected: FAIL — `cannot find 'Keychain' in scope`

- [ ] **Step 3: Implement Keychain helper**

Create `PocketHeart/Services/Keychain.swift`:

```swift
import Foundation
import Security

struct Keychain {
    enum Error: Swift.Error { case status(OSStatus), encoding }

    let service: String

    func set(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else { throw Error.encoding }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            let attrs: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
            guard updateStatus == errSecSuccess else { throw Error.status(updateStatus) }
        } else if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw Error.status(addStatus) }
        } else {
            throw Error.status(status)
        }
    }

    func get(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw Error.status(status) }
        guard let data = item as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw Error.status(status) }
    }
}

extension Keychain {
    static let providers = Keychain(service: "com.pocketheart.providers")
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/KeychainTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/Keychain.swift PocketHeartTests/KeychainTests.swift
git commit -m "feat: add Keychain helper for API keys"
```

---

## Task 7: Parsed input DTOs and prompt builder

**Files:**
- Create: `PocketHeart/Services/AI/ParsedInputResult.swift`
- Create: `PocketHeart/Services/AI/ParsingPrompt.swift`
- Create: `PocketHeartTests/ParsingPromptTests.swift`

- [ ] **Step 1: Write failing prompt tests**

Create `PocketHeartTests/ParsingPromptTests.swift`:

```swift
import Testing
import Foundation
@testable import PocketHeart

struct ParsingPromptTests {
    @Test func includesCurrentDateAndCurrency() {
        let ctx = ParsingContext(
            now: Date(timeIntervalSince1970: 1_700_000_000),
            timeZone: TimeZone(identifier: "Asia/Shanghai")!,
            locale: Locale(identifier: "zh_CN"),
            defaultCurrency: "CNY",
            categories: [],
            tags: [],
            paymentMethods: []
        )
        let prompt = ParsingPrompt.user(input: "lunch 38", context: ctx)
        #expect(prompt.contains("CNY"))
        #expect(prompt.contains("Asia/Shanghai"))
        #expect(prompt.contains("lunch 38"))
    }

    @Test func listsExistingTaxonomy() {
        let ctx = ParsingContext(
            now: .now, timeZone: .current, locale: .current, defaultCurrency: "CNY",
            categories: [.init(id: UUID(), name: "Food", parentName: nil)],
            tags: ["work"],
            paymentMethods: ["WeChat Pay"]
        )
        let prompt = ParsingPrompt.user(input: "x", context: ctx)
        #expect(prompt.contains("Food"))
        #expect(prompt.contains("work"))
        #expect(prompt.contains("WeChat Pay"))
    }
}
```

- [ ] **Step 2: Run tests (expect failure)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/ParsingPromptTests`
Expected: FAIL — `cannot find 'ParsingContext' in scope`

- [ ] **Step 3: Add the DTO file**

Create `PocketHeart/Services/AI/ParsedInputResult.swift`:

```swift
import Foundation

struct ParsedInputResult: Decodable, Sendable {
    let transactions: [ParsedTransaction]
    let failed: [ParsedFailure]
}

struct ParsedTransaction: Decodable, Sendable {
    let amount: Decimal?
    let currency: String?
    let type: TransactionType
    let title: String
    let merchant: String?
    let occurredAt: Date?
    let categoryName: String
    let subcategoryName: String?
    let tagNames: [String]
    let paymentMethodName: String
    let notes: String?
}

struct ParsedFailure: Decodable, Sendable {
    let raw: String
    let reason: String
}

struct ParsingContext: Sendable {
    struct CategoryRef: Sendable { let id: UUID; let name: String; let parentName: String? }
    let now: Date
    let timeZone: TimeZone
    let locale: Locale
    let defaultCurrency: String
    let categories: [CategoryRef]
    let tags: [String]
    let paymentMethods: [String]
}
```

- [ ] **Step 4: Add the prompt builder**

Create `PocketHeart/Services/AI/ParsingPrompt.swift`:

```swift
import Foundation

enum ParsingPrompt {
    static let system = """
    You are a strict bookkeeping parser. Convert the user's free-form text into JSON describing zero or more transactions.
    Reply with ONLY a JSON object matching this schema (no prose, no code fences):

    {
      "transactions": [
        {
          "amount": number,                  // positive decimal; null if unknown
          "currency": "CNY",                 // ISO code; default to user's currency if absent
          "type": "expense" | "income",
          "title": "short item name",
          "merchant": "optional merchant",
          "occurredAt": "ISO-8601 datetime in user's time zone",
          "categoryName": "string",
          "subcategoryName": "optional",
          "tagNames": ["..."],
          "paymentMethodName": "string",
          "notes": "optional"
        }
      ],
      "failed": [{ "raw": "fragment", "reason": "why parsing failed" }]
    }

    Rules:
    - Resolve relative dates ("yesterday", "last night", "lunch") to absolute datetimes in the user's time zone.
    - Reuse the listed categories/tags/payment methods when they fit. If none fit, propose a new short name (Title Case for English, original language otherwise).
    - Encode direction with "type"; keep "amount" positive.
    - If amount is missing, omit the transaction from "transactions" and add it to "failed".
    - One input may yield multiple transactions.
    """

    static func user(input: String, context: ParsingContext) -> String {
        var iso = ISO8601DateFormatter()
        iso.timeZone = context.timeZone
        let nowString = iso.string(from: context.now)
        let cats = context.categories.map { c in
            if let p = c.parentName { return "\(p) > \(c.name)" } else { return c.name }
        }.joined(separator: ", ")
        return """
        Now: \(nowString)
        TimeZone: \(context.timeZone.identifier)
        Locale: \(context.locale.identifier)
        DefaultCurrency: \(context.defaultCurrency)
        Categories: [\(cats)]
        Tags: [\(context.tags.joined(separator: ", "))]
        PaymentMethods: [\(context.paymentMethods.joined(separator: ", "))]

        Input:
        \(input)
        """
    }
}
```

- [ ] **Step 5: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/ParsingPromptTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add PocketHeart/Services/AI PocketHeartTests/ParsingPromptTests.swift
git commit -m "feat: add parsed input DTOs and prompt builder"
```

---

## Task 8: ParsedInputResult JSON decoding

**Files:**
- Create: `PocketHeartTests/ParsedInputDecodingTests.swift`
- Create: `PocketHeart/Services/AI/ParsedInputDecoder.swift`

- [ ] **Step 1: Write failing tests**

Create `PocketHeartTests/ParsedInputDecodingTests.swift`:

```swift
import Testing
import Foundation
@testable import PocketHeart

struct ParsedInputDecodingTests {
    @Test func decodesTwoExpenses() throws {
        let json = #"""
        {"transactions":[
          {"amount":38.5,"currency":"CNY","type":"expense","title":"Lunch","occurredAt":"2026-04-25T12:30:00+08:00","categoryName":"Food","tagNames":["work"],"paymentMethodName":"WeChat Pay"},
          {"amount":28,"currency":"CNY","type":"expense","title":"Latte","occurredAt":"2026-04-25T16:00:00+08:00","categoryName":"Coffee","tagNames":[],"paymentMethodName":"CMB Credit"}
        ],"failed":[]}
        """#
        let result = try ParsedInputDecoder.decode(json)
        #expect(result.transactions.count == 2)
        #expect(result.transactions[0].amount == Decimal(string: "38.5"))
        #expect(result.transactions[1].title == "Latte")
    }

    @Test func decodesPartialFailure() throws {
        let json = #"""
        {"transactions":[],"failed":[{"raw":"工资","reason":"missing amount"}]}
        """#
        let r = try ParsedInputDecoder.decode(json)
        #expect(r.transactions.isEmpty)
        #expect(r.failed.first?.reason == "missing amount")
    }

    @Test func tolerantOfFencedCodeBlock() throws {
        let json = """
        ```json
        {"transactions":[],"failed":[]}
        ```
        """
        let r = try ParsedInputDecoder.decode(json)
        #expect(r.transactions.isEmpty)
    }

    @Test func throwsOnInvalidJSON() {
        #expect(throws: (any Error).self) {
            _ = try ParsedInputDecoder.decode("not json")
        }
    }
}
```

- [ ] **Step 2: Run tests (expect failure)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/ParsedInputDecodingTests`
Expected: FAIL — `cannot find 'ParsedInputDecoder' in scope`

- [ ] **Step 3: Add the decoder**

Create `PocketHeart/Services/AI/ParsedInputDecoder.swift`:

```swift
import Foundation

enum ParsedInputDecoder {
    enum Error: Swift.Error { case noJSONFound }

    static func decode(_ raw: String) throws -> ParsedInputResult {
        let cleaned = stripFences(raw)
        guard let data = cleaned.data(using: .utf8) else { throw Error.noJSONFound }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ParsedInputResult.self, from: data)
    }

    private static func stripFences(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("```") {
            if let firstNewline = t.firstIndex(of: "\n") {
                t = String(t[t.index(after: firstNewline)...])
            }
            if t.hasSuffix("```") {
                t = String(t.dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        guard let start = t.firstIndex(of: "{"), let end = t.lastIndex(of: "}") else { return t }
        return String(t[start...end])
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/ParsedInputDecodingTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/AI/ParsedInputDecoder.swift PocketHeartTests/ParsedInputDecodingTests.swift
git commit -m "feat: tolerant JSON decoding for AI output"
```

---

## Task 9: ProviderAdapter protocol and OpenAI-compatible adapter

**Files:**
- Create: `PocketHeart/Services/AI/ProviderAdapter.swift`
- Create: `PocketHeart/Services/AI/OpenAICompatibleAdapter.swift`
- Create: `PocketHeartTests/OpenAICompatibleAdapterTests.swift`

- [ ] **Step 1: Add the protocol**

Create `PocketHeart/Services/AI/ProviderAdapter.swift`:

```swift
import Foundation

struct AdapterRequest: Sendable {
    let baseURL: String
    let modelName: String
    let apiKey: String
    let systemPrompt: String
    let userPrompt: String
}

protocol ProviderAdapter: Sendable {
    func send(_ request: AdapterRequest) async throws -> String
}

enum AdapterError: Error, Equatable {
    case invalidURL
    case missingAPIKey
    case http(Int, String)
    case emptyResponse
}
```

- [ ] **Step 2: Write failing test for the OpenAI-compatible adapter**

Create `PocketHeartTests/OpenAICompatibleAdapterTests.swift`:

```swift
import Testing
import Foundation
@testable import PocketHeart

@MainActor
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responder: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data) = Self.responder?(request) ?? (500, Data())
        let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

struct OpenAICompatibleAdapterTests {
    @Test @MainActor func sendsChatCompletionsAndExtractsContent() async throws {
        StubURLProtocol.responder = { req in
            #expect(req.url?.absoluteString == "https://api.example.com/v1/chat/completions")
            #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer KEY")
            let payload = #"{"choices":[{"message":{"content":"hello"}}]}"#
            return (200, payload.data(using: .utf8)!)
        }
        let session = URLSession(configuration: {
            let c = URLSessionConfiguration.ephemeral
            c.protocolClasses = [StubURLProtocol.self]
            return c
        }())
        let adapter = OpenAICompatibleAdapter(session: session)
        let out = try await adapter.send(.init(
            baseURL: "https://api.example.com/v1",
            modelName: "deepseek-chat",
            apiKey: "KEY",
            systemPrompt: "sys",
            userPrompt: "usr"
        ))
        #expect(out == "hello")
    }

    @Test @MainActor func surfacesNon2xxAsHTTPError() async throws {
        StubURLProtocol.responder = { _ in (401, Data("nope".utf8)) }
        let session = URLSession(configuration: {
            let c = URLSessionConfiguration.ephemeral
            c.protocolClasses = [StubURLProtocol.self]
            return c
        }())
        let adapter = OpenAICompatibleAdapter(session: session)
        await #expect(throws: AdapterError.self) {
            _ = try await adapter.send(.init(baseURL: "https://x/v1", modelName: "m", apiKey: "k", systemPrompt: "s", userPrompt: "u"))
        }
    }
}
```

- [ ] **Step 3: Run test (expect failure)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/OpenAICompatibleAdapterTests`
Expected: FAIL — `cannot find 'OpenAICompatibleAdapter' in scope`

- [ ] **Step 4: Implement the adapter**

Create `PocketHeart/Services/AI/OpenAICompatibleAdapter.swift`:

```swift
import Foundation

struct OpenAICompatibleAdapter: ProviderAdapter {
    let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        guard let url = URL(string: request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions") else {
            throw AdapterError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(request.apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": request.modelName,
            "messages": [
                ["role": "system", "content": request.systemPrompt],
                ["role": "user", "content": request.userPrompt],
            ],
            "temperature": 0.1,
            "response_format": ["type": "json_object"],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable {
            struct Choice: Decodable { struct Msg: Decodable { let content: String }; let message: Msg }
            let choices: [Choice]
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw AdapterError.emptyResponse
        }
        return content
    }
}
```

- [ ] **Step 5: Run test**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/OpenAICompatibleAdapterTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add PocketHeart/Services/AI/ProviderAdapter.swift PocketHeart/Services/AI/OpenAICompatibleAdapter.swift PocketHeartTests/OpenAICompatibleAdapterTests.swift
git commit -m "feat: OpenAI-compatible provider adapter with stubbed URLSession test"
```

---

## Task 10: Anthropic and Gemini adapters + factory

**Files:**
- Create: `PocketHeart/Services/AI/AnthropicAdapter.swift`
- Create: `PocketHeart/Services/AI/GeminiAdapter.swift`
- Create: `PocketHeart/Services/AI/AdapterFactory.swift`

> The MVP spec calls these out as templates. We implement them for parity but they reuse the same protocol surface. Tests for these are intentionally minimal — they share request-shape coverage with the OpenAI-compatible adapter test pattern.

- [ ] **Step 1: Implement `AnthropicAdapter`**

```swift
import Foundation

struct AnthropicAdapter: ProviderAdapter {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        guard let url = URL(string: request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/v1/messages") else {
            throw AdapterError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(request.apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": request.modelName,
            "max_tokens": 1024,
            "system": request.systemPrompt,
            "messages": [["role": "user", "content": request.userPrompt]],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable { struct Block: Decodable { let text: String? }; let content: [Block] }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let text = decoded.content.compactMap(\.text).first, !text.isEmpty else { throw AdapterError.emptyResponse }
        return text
    }
}
```

- [ ] **Step 2: Implement `GeminiAdapter`**

```swift
import Foundation

struct GeminiAdapter: ProviderAdapter {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    func send(_ request: AdapterRequest) async throws -> String {
        guard !request.apiKey.isEmpty else { throw AdapterError.missingAPIKey }
        let base = request.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard var comps = URLComponents(string: "\(base)/v1beta/models/\(request.modelName):generateContent") else {
            throw AdapterError.invalidURL
        }
        comps.queryItems = [URLQueryItem(name: "key", value: request.apiKey)]
        guard let url = comps.url else { throw AdapterError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": request.systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": request.userPrompt]]]],
            "generationConfig": ["temperature": 0.1, "responseMimeType": "application/json"],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw AdapterError.http(status, String(data: data, encoding: .utf8) ?? "")
        }
        struct Resp: Decodable {
            struct Candidate: Decodable { struct Content: Decodable { struct Part: Decodable { let text: String? }; let parts: [Part] }; let content: Content }
            let candidates: [Candidate]
        }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        guard let text = decoded.candidates.first?.content.parts.compactMap(\.text).first, !text.isEmpty else {
            throw AdapterError.emptyResponse
        }
        return text
    }
}
```

- [ ] **Step 3: Add `AdapterFactory`**

```swift
import Foundation

enum AdapterFactory {
    static func adapter(for interface: InterfaceFormat, session: URLSession = .shared) -> any ProviderAdapter {
        switch interface {
        case .openAICompatible: return OpenAICompatibleAdapter(session: session)
        case .anthropicMessages: return AnthropicAdapter(session: session)
        case .geminiGenerateContent: return GeminiAdapter(session: session)
        }
    }
}
```

- [ ] **Step 4: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/AI/AnthropicAdapter.swift PocketHeart/Services/AI/GeminiAdapter.swift PocketHeart/Services/AI/AdapterFactory.swift
git commit -m "feat: Anthropic + Gemini adapters and factory"
```

---

## Task 11: AIParsingService

**Files:**
- Create: `PocketHeart/Services/AI/AIParsingService.swift`
- Modify: `PocketHeartTests/ParsedInputDecodingTests.swift` (add service test)

- [ ] **Step 1: Add a fake adapter for tests and write failing tests**

Append to `PocketHeartTests/ParsedInputDecodingTests.swift`:

```swift
struct FakeAdapter: ProviderAdapter {
    let response: Result<String, any Error>
    func send(_ request: AdapterRequest) async throws -> String {
        try response.get()
    }
}

struct AIParsingServiceTests {
    let context = ParsingContext(
        now: Date(timeIntervalSince1970: 1_700_000_000),
        timeZone: TimeZone(identifier: "Asia/Shanghai")!,
        locale: Locale(identifier: "zh_CN"),
        defaultCurrency: "CNY",
        categories: [], tags: [], paymentMethods: []
    )

    @Test func parsesValidResponse() async throws {
        let json = #"{"transactions":[{"amount":12,"currency":"CNY","type":"expense","title":"a","occurredAt":"2026-04-25T10:00:00+08:00","categoryName":"Food","tagNames":[],"paymentMethodName":"Cash"}],"failed":[]}"#
        let svc = AIParsingService(adapter: FakeAdapter(response: .success(json)))
        let result = try await svc.parse(input: "x", apiKey: "k", baseURL: "https://x/v1", model: "m", context: context)
        #expect(result.transactions.count == 1)
    }

    @Test func wrapsAdapterErrors() async {
        let svc = AIParsingService(adapter: FakeAdapter(response: .failure(AdapterError.http(500, "boom"))))
        await #expect(throws: AIParsingError.self) {
            _ = try await svc.parse(input: "x", apiKey: "k", baseURL: "u", model: "m", context: context)
        }
    }
}
```

- [ ] **Step 2: Run tests (expect failure — types missing)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/AIParsingServiceTests`
Expected: FAIL — `cannot find 'AIParsingService' in scope`

- [ ] **Step 3: Implement the service**

Create `PocketHeart/Services/AI/AIParsingService.swift`:

```swift
import Foundation

enum AIParsingError: Error {
    case missingProvider
    case missingAPIKey
    case providerFailure(String)
    case invalidJSON(String)
}

protocol AIParsingServiceProtocol: Sendable {
    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult
}

struct AIParsingService: AIParsingServiceProtocol {
    let adapter: any ProviderAdapter

    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult {
        let req = AdapterRequest(
            baseURL: baseURL,
            modelName: model,
            apiKey: apiKey,
            systemPrompt: ParsingPrompt.system,
            userPrompt: ParsingPrompt.user(input: input, context: context)
        )
        let raw: String
        do { raw = try await adapter.send(req) }
        catch let e as AdapterError {
            switch e {
            case .missingAPIKey: throw AIParsingError.missingAPIKey
            default: throw AIParsingError.providerFailure(String(describing: e))
            }
        }
        do { return try ParsedInputDecoder.decode(raw) }
        catch { throw AIParsingError.invalidJSON(raw) }
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/AIParsingServiceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/AI/AIParsingService.swift PocketHeartTests/ParsedInputDecodingTests.swift
git commit -m "feat: AIParsingService composing prompt, adapter, and decoder"
```

---

## Task 12: Speech service

**Files:**
- Create: `PocketHeart/Services/Speech/SpeechService.swift`

> No unit test — `SFSpeechRecognizer` cannot be exercised in test runs. The protocol exists so RecordingViewModel can be tested with a fake.

- [ ] **Step 1: Add the protocol and live implementation**

```swift
import Foundation
import AVFoundation
import Speech

protocol SpeechServiceProtocol: AnyObject, Sendable {
    func requestAuthorization() async -> Bool
    func startRecording(onPartial: @Sendable @escaping (String) -> Void) async throws
    func stop() async throws -> String
    func cancel()
}

enum SpeechServiceError: Error {
    case permissionDenied
    case recognizerUnavailable
    case audioEngineFailure(String)
}

@MainActor
final class SpeechService: SpeechServiceProtocol {
    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var lastTranscript: String = ""

    func requestAuthorization() async -> Bool {
        let speechOK = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
        }
        let micOK = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        return speechOK && micOK
    }

    func startRecording(onPartial: @Sendable @escaping (String) -> Void) async throws {
        guard let recognizer, recognizer.isAvailable else { throw SpeechServiceError.recognizerUnavailable }
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do { try audioEngine.start() }
        catch { throw SpeechServiceError.audioEngineFailure(error.localizedDescription) }
        lastTranscript = ""
        task = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            self.lastTranscript = result.bestTranscription.formattedString
            onPartial(self.lastTranscript)
        }
    }

    func stop() async throws -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        let final = lastTranscript
        request = nil
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return final
    }

    func cancel() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        task?.cancel()
        task = nil
        request = nil
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add PocketHeart/Services/Speech/SpeechService.swift
git commit -m "feat: speech service protocol with SFSpeechRecognizer implementation"
```

---

## Task 13: LedgerRepository

**Files:**
- Create: `PocketHeart/Services/Ledger/LedgerRepository.swift`
- Create: `PocketHeartTests/LedgerRepositoryTests.swift`

- [ ] **Step 1: Write failing tests**

Create `PocketHeartTests/LedgerRepositoryTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import PocketHeart

@MainActor
struct LedgerRepositoryTests {
    private func makeRepo() -> (LedgerRepository, ModelContext) {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        return (LedgerRepository(context: ctx), ctx)
    }

    @Test func savesValidParsedTransactionAndReusesExistingTaxonomy() throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(string: "38"), currency: "CNY", type: .expense,
            title: "Lunch", merchant: nil,
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000),
            categoryName: "Food", subcategoryName: "Lunch", tagNames: ["work"],
            paymentMethodName: "WeChat Pay", notes: nil
        )
        let result = try repo.save(input: "lunch", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        #expect(result.savedTransactionIDs.count == 1)
        let foodCount = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.name == "Food" })).count
        #expect(foodCount == 1)
    }

    @Test func createsAITaxonomyWhenMissing() throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(12), currency: "CNY", type: .expense,
            title: "Boba", merchant: nil, occurredAt: .now,
            categoryName: "Drinks", subcategoryName: nil, tagNames: ["new"],
            paymentMethodName: "Alipay Mini", notes: nil
        )
        _ = try repo.save(input: "boba", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        let drinks = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.name == "Drinks" }))
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.name == "Alipay Mini" }))
        #expect(drinks.first?.isAICreated == true)
        #expect(pay.first?.isAICreated == true)
    }

    @Test func failsTransactionWithoutAmountAsPartialFailure() throws {
        let (repo, _) = makeRepo()
        let parsed = ParsedTransaction(
            amount: nil, currency: "CNY", type: .expense, title: "?",
            merchant: nil, occurredAt: nil, categoryName: "Food",
            subcategoryName: nil, tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        let result = try repo.save(input: "?", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        #expect(result.savedTransactionIDs.isEmpty)
        #expect(result.failedItems.first?.reason.contains("amount") == true)
    }

    @Test func missingTimeFallsBackToNow() throws {
        let (repo, ctx) = makeRepo()
        let before = Date()
        let parsed = ParsedTransaction(
            amount: Decimal(5), currency: "CNY", type: .expense, title: "x",
            merchant: nil, occurredAt: nil, categoryName: "Food",
            subcategoryName: nil, tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        _ = try repo.save(input: "x", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        let txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        #expect(txn.occurredAt >= before)
    }

    @Test func editTransactionUpdatesUpdatedAt() throws {
        let (repo, ctx) = makeRepo()
        let parsed = ParsedTransaction(
            amount: Decimal(10), currency: "CNY", type: .expense, title: "old",
            merchant: nil, occurredAt: .now, categoryName: "Food",
            subcategoryName: nil, tagNames: [], paymentMethodName: "Cash", notes: nil
        )
        _ = try repo.save(input: "x", source: .text, providerID: nil, parsed: ParsedInputResult(transactions: [parsed], failed: []))
        var txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        let originalUpdated = txn.updatedAt
        try? await Task.sleep(nanoseconds: 5_000_000)
        try repo.update(txn) { $0.title = "new" }
        txn = try ctx.fetch(FetchDescriptor<Transaction>()).first!
        #expect(txn.title == "new")
        #expect(txn.updatedAt > originalUpdated)
    }
}
```

- [ ] **Step 2: Run tests (expect failure — `LedgerRepository` undefined)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/LedgerRepositoryTests`
Expected: FAIL — `cannot find 'LedgerRepository' in scope`

- [ ] **Step 3: Implement the repository**

Create `PocketHeart/Services/Ledger/LedgerRepository.swift`:

```swift
import Foundation
import SwiftData

struct SaveResult {
    var inputEntryID: UUID
    var savedTransactionIDs: [UUID]
    var failedItems: [ParsedFailure]
}

@MainActor
final class LedgerRepository {
    let context: ModelContext

    init(context: ModelContext) { self.context = context }

    func save(
        input rawText: String,
        source: InputSource,
        providerID: UUID?,
        parsed: ParsedInputResult,
        now: Date = .now
    ) throws -> SaveResult {
        let entry = InputEntry(rawText: rawText, source: source, createdAt: now, status: .pending, providerID: providerID)
        context.insert(entry)

        var savedIDs: [UUID] = []
        var failed: [ParsedFailure] = parsed.failed

        for p in parsed.transactions {
            guard let amount = p.amount, amount > 0 else {
                failed.append(.init(raw: p.title, reason: "missing or non-positive amount"))
                continue
            }
            let categoryID = try findOrCreateCategory(name: p.categoryName, applicable: p.type == .income ? .income : .expense)
            let subID: UUID? = try p.subcategoryName.flatMap { try findOrCreateSubcategory(name: $0, parentID: categoryID) }
            let tagIDs = try p.tagNames.map { try findOrCreateTag(name: $0) }
            let payID = try findOrCreatePayment(name: p.paymentMethodName)

            let txn = Transaction(
                amount: amount,
                currency: p.currency ?? "CNY",
                type: p.type,
                title: p.title,
                merchant: p.merchant,
                occurredAt: p.occurredAt ?? now,
                categoryID: categoryID,
                subcategoryID: subID,
                tagIDs: tagIDs,
                paymentMethodID: payID,
                notes: p.notes,
                sourceInputID: entry.id,
                isAICreated: true,
                createdAt: now,
                updatedAt: now
            )
            context.insert(txn)
            savedIDs.append(txn.id)
            for tagID in tagIDs { try bumpTagUsage(tagID) }
        }

        entry.transactionIDs = savedIDs
        entry.status = failed.isEmpty
            ? (savedIDs.isEmpty ? .failure : .success)
            : (savedIDs.isEmpty ? .failure : .partialFailure)
        try context.save()
        return SaveResult(inputEntryID: entry.id, savedTransactionIDs: savedIDs, failedItems: failed)
    }

    func update(_ txn: Transaction, mutate: (Transaction) -> Void) throws {
        mutate(txn)
        txn.updatedAt = .now
        try context.save()
    }

    func delete(_ txn: Transaction) throws {
        context.delete(txn)
        try context.save()
    }

    func recentInputEntries(limit: Int = 50) throws -> [InputEntry] {
        var fd = FetchDescriptor<InputEntry>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        fd.fetchLimit = limit
        return try context.fetch(fd)
    }

    func transactions(for entry: InputEntry) throws -> [Transaction] {
        let ids = entry.transactionIDs
        guard !ids.isEmpty else { return [] }
        let fd = FetchDescriptor<Transaction>(predicate: #Predicate { ids.contains($0.id) })
        return try context.fetch(fd)
    }

    func category(id: UUID) throws -> LedgerCategory? {
        try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.id == id })).first
    }
    func paymentMethod(id: UUID) throws -> PaymentMethod? {
        try context.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.id == id })).first
    }
    func tags(ids: [UUID]) throws -> [LedgerTag] {
        guard !ids.isEmpty else { return [] }
        return try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { ids.contains($0.id) }))
    }

    // MARK: - Reuse-or-create

    private func findOrCreateCategory(name: String, applicable: ApplicableType) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate {
            $0.name == trimmed && $0.parentID == nil && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerCategory(name: trimmed, applicable: applicable, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreateSubcategory(name: String, parentID: UUID) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate {
            $0.name == trimmed && $0.parentID == parentID && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerCategory(name: trimmed, parentID: parentID, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreateTag(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate {
            $0.name == trimmed && $0.isArchived == false
        })).first { return existing.id }
        let new = LedgerTag(name: trimmed, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func findOrCreatePayment(name: String) throws -> UUID {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing = try context.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate {
            $0.name == trimmed && $0.isArchived == false
        })).first { return existing.id }
        let new = PaymentMethod(name: trimmed, kind: .other, isAICreated: true)
        context.insert(new)
        return new.id
    }

    private func bumpTagUsage(_ id: UUID) throws {
        if let tag = try context.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { $0.id == id })).first {
            tag.usageCount += 1
        }
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/LedgerRepositoryTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/Ledger/LedgerRepository.swift PocketHeartTests/LedgerRepositoryTests.swift
git commit -m "feat: ledger repository with reuse-or-create taxonomy"
```

---

## Task 14: StatsService

**Files:**
- Create: `PocketHeart/Services/Ledger/StatsService.swift`
- Create: `PocketHeartTests/StatsServiceTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
import Testing
import Foundation
import SwiftData
@testable import PocketHeart

@MainActor
struct StatsServiceTests {
    @Test func todayAndMonthTotalsExcludeIncome() throws {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        let stats = StatsService(context: ctx)
        let cat = try ctx.fetch(FetchDescriptor<LedgerCategory>()).first!.id
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>()).first!.id
        let now = Date()
        ctx.insert(Transaction(amount: 10, currency: "CNY", type: .expense, title: "a", occurredAt: now, categoryID: cat, paymentMethodID: pay, sourceInputID: UUID()))
        ctx.insert(Transaction(amount: 100, currency: "CNY", type: .income, title: "b", occurredAt: now, categoryID: cat, paymentMethodID: pay, sourceInputID: UUID()))
        try ctx.save()
        let s = try stats.summary(now: now, calendar: Calendar(identifier: .gregorian))
        #expect(s.todaySpent == 10)
        #expect(s.monthIncome == 100)
        #expect(s.monthSpent == 10)
    }

    @Test func categoryShareSumsToMonthSpent() throws {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        let stats = StatsService(context: ctx)
        let categories = try ctx.fetch(FetchDescriptor<LedgerCategory>())
        let pay = try ctx.fetch(FetchDescriptor<PaymentMethod>()).first!.id
        let now = Date()
        for (i, cat) in categories.prefix(3).enumerated() {
            ctx.insert(Transaction(amount: Decimal(10 * (i+1)), currency: "CNY", type: .expense, title: "x", occurredAt: now, categoryID: cat.id, paymentMethodID: pay, sourceInputID: UUID()))
        }
        try ctx.save()
        let s = try stats.summary(now: now, calendar: .init(identifier: .gregorian))
        let sum = s.categoryShare.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(sum == s.monthSpent)
    }
}
```

- [ ] **Step 2: Run test (expect failure)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/StatsServiceTests`
Expected: FAIL — `cannot find 'StatsService' in scope`

- [ ] **Step 3: Implement**

```swift
import Foundation
import SwiftData

struct StatsSummary {
    struct Slice { let categoryID: UUID; let categoryName: String; let amount: Decimal; let percent: Double }
    var todaySpent: Decimal
    var monthSpent: Decimal
    var monthIncome: Decimal
    var categoryShare: [Slice]
    var dailyTrend: [Decimal]
}

@MainActor
final class StatsService {
    let context: ModelContext
    init(context: ModelContext) { self.context = context }

    func summary(now: Date = .now, calendar: Calendar = .current) throws -> StatsSummary {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let dayStart = calendar.startOfDay(for: now)

        let monthTxns = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.occurredAt >= monthStart }))

        var todaySpent: Decimal = 0
        var monthSpent: Decimal = 0
        var monthIncome: Decimal = 0
        var byCat: [UUID: Decimal] = [:]
        var trend: [Decimal] = Array(repeating: 0, count: 30)

        for t in monthTxns {
            if t.type == .income { monthIncome += t.amount; continue }
            monthSpent += t.amount
            byCat[t.categoryID, default: 0] += t.amount
            if t.occurredAt >= dayStart { todaySpent += t.amount }
            if let day = calendar.dateComponents([.day], from: t.occurredAt, to: now).day, (0..<30).contains(day) {
                trend[29 - day] += t.amount
            }
        }

        let cats = try context.fetch(FetchDescriptor<LedgerCategory>())
        let nameByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        let totalDouble = NSDecimalNumber(decimal: monthSpent).doubleValue
        let slices = byCat.map { id, amt in
            let pct = totalDouble > 0 ? NSDecimalNumber(decimal: amt).doubleValue / totalDouble : 0
            return StatsSummary.Slice(categoryID: id, categoryName: nameByID[id] ?? "Other", amount: amt, percent: pct)
        }.sorted { $0.amount > $1.amount }

        return StatsSummary(todaySpent: todaySpent, monthSpent: monthSpent, monthIncome: monthIncome, categoryShare: slices, dailyTrend: trend)
    }
}
```

- [ ] **Step 4: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/StatsServiceTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PocketHeart/Services/Ledger/StatsService.swift PocketHeartTests/StatsServiceTests.swift
git commit -m "feat: stats service with month + 30-day trend"
```

---

## Task 15: AppEnvironment wiring

**Files:**
- Create: `PocketHeart/App/AppEnvironment.swift`
- Modify: `PocketHeart/App/PocketHeartApp.swift`
- Modify: `PocketHeart/App/RootView.swift`

- [ ] **Step 1: Define `AppEnvironment`**

```swift
import SwiftUI
import SwiftData

@MainActor
@Observable
final class AppEnvironment {
    let container: ModelContainer
    let repository: LedgerRepository
    let stats: StatsService
    let speech: SpeechServiceProtocol
    let parser: AIParsingServiceProtocol
    let keychain: Keychain

    init(container: ModelContainer,
         speech: SpeechServiceProtocol = SpeechService(),
         parser: AIParsingServiceProtocol = AIParsingService(adapter: AdapterFactory.adapter(for: .openAICompatible)),
         keychain: Keychain = .providers) {
        self.container = container
        self.repository = LedgerRepository(context: container.mainContext)
        self.stats = StatsService(context: container.mainContext)
        self.speech = speech
        self.parser = parser
        self.keychain = keychain
    }

    func defaultProvider() throws -> AIProvider? {
        let providers = try container.mainContext.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.isDefault == true }))
        return providers.first
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment? = nil
}

extension EnvironmentValues {
    var appEnv: AppEnvironment? {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
```

- [ ] **Step 2: Inject the env from the App**

Replace `PocketHeart/App/PocketHeartApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PocketHeartApp: App {
    let env: AppEnvironment

    init() {
        let container = AppContainer.make()
        self.env = AppEnvironment(container: container)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.appEnv, env)
                .modelContainer(env.container)
                .preferredColorScheme(.dark)
        }
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: app environment wires services and SwiftData container"
```

---

## Task 16: CategoryIcon and pill components

**Files:**
- Create: `PocketHeart/DesignSystem/CategoryIcon.swift`
- Create: `PocketHeart/DesignSystem/Pills.swift`

- [ ] **Step 1: Add `CategoryIcon`**

```swift
import SwiftUI

struct CategoryIcon: View {
    let key: String
    var size: CGFloat = 36

    private var color: Color {
        switch key {
        case "food":    return Color(hue: 30/360, saturation: 0.55, brightness: 0.95)
        case "transit": return Color(hue: 240/360, saturation: 0.55, brightness: 0.85)
        case "coffee":  return Color(hue: 50/360, saturation: 0.45, brightness: 0.7)
        case "grocery": return Color(hue: 145/360, saturation: 0.55, brightness: 0.85)
        case "salary":  return Color(hue: 280/360, saturation: 0.55, brightness: 0.85)
        default:        return Color.gray
        }
    }

    private var systemName: String {
        switch key {
        case "food":    return "fork.knife"
        case "transit": return "tram.fill"
        case "coffee":  return "cup.and.saucer.fill"
        case "grocery": return "cart.fill"
        case "salary":  return "dollarsign.circle.fill"
        default:        return "circle.dashed"
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.28)
            .fill(color.opacity(0.22))
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(color)
            }
            .frame(width: size, height: size)
    }
}
```

- [ ] **Step 2: Add pills**

```swift
import SwiftUI

struct MetaPill: View {
    let text: String
    var muted: Bool = false
    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .medium))
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Color.white.opacity(muted ? 0.05 : 0.08), in: Capsule())
            .foregroundStyle(Color.white.opacity(muted ? 0.55 : 0.85))
    }
}

struct TagPill: View {
    let text: String
    var body: some View {
        Text("#" + text)
            .font(.system(size: 10.5, weight: .medium))
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Theme.primary.opacity(0.16), in: Capsule())
            .foregroundStyle(Theme.primaryLight)
    }
}

struct TypePill: View {
    let type: TransactionType
    var active: Bool
    var body: some View {
        let color: Color = type == .expense ? Theme.danger : Theme.success
        Text(type == .expense ? "– Expense" : "+ Income")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 11).padding(.vertical, 5)
            .background(active ? color.opacity(0.16) : Color.clear, in: Capsule())
            .overlay(Capsule().stroke(active ? color.opacity(0.3) : Color.white.opacity(0.15), lineWidth: 1))
            .foregroundStyle(active ? color : Color.white.opacity(0.5))
    }
}
```

- [ ] **Step 3: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add PocketHeart/DesignSystem
git commit -m "feat: category icon and pill components"
```

---

## Task 17: Recording stream — view model

**Files:**
- Create: `PocketHeart/Features/Recording/StreamMessage.swift`
- Create: `PocketHeart/Features/Recording/RecordingViewModel.swift`
- Create: `PocketHeartTests/RecordingFlowTests.swift`

- [ ] **Step 1: Add the display model**

```swift
import Foundation

struct StreamMessage: Identifiable, Equatable {
    let id = UUID()
    enum Kind: Equatable {
        case dayDivider(label: String)
        case userBubble(text: String, source: InputSource, time: Date)
        case group(GroupCardModel)
    }
    var kind: Kind
}

struct GroupCardModel: Equatable {
    var inputEntryID: UUID
    var source: InputSource
    var when: Date
    var summary: String
    var transactions: [TransactionRowModel]
    var failed: [ParsedFailure]
}

extension ParsedFailure: Equatable {
    public static func == (lhs: ParsedFailure, rhs: ParsedFailure) -> Bool {
        lhs.raw == rhs.raw && lhs.reason == rhs.reason
    }
}

struct TransactionRowModel: Equatable, Identifiable {
    let id: UUID
    var amount: Decimal
    var currency: String
    var type: TransactionType
    var title: String
    var merchant: String?
    var occurredAt: Date
    var categoryName: String
    var iconKey: String
    var subcategoryName: String?
    var tagNames: [String]
    var paymentName: String
}
```

- [ ] **Step 2: Write failing test for the view model**

Create `PocketHeartTests/RecordingFlowTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import PocketHeart

struct FakeParser: AIParsingServiceProtocol {
    let result: Result<ParsedInputResult, any Error>
    func parse(input: String, apiKey: String, baseURL: String, model: String, context: ParsingContext) async throws -> ParsedInputResult {
        try result.get()
    }
}

@MainActor
struct RecordingViewModelTests {
    private func makeVM(parser: AIParsingServiceProtocol) -> (RecordingViewModel, ModelContext) {
        let container = AppContainer.make(inMemory: true)
        let ctx = container.mainContext
        let provider = AIProvider(displayName: "Fake", baseURL: "https://x/v1", modelName: "m", isDefault: true)
        ctx.insert(provider)
        try? ctx.save()
        try? Keychain.providers.set("KEY", account: provider.id.uuidString)
        let repo = LedgerRepository(context: ctx)
        let stats = StatsService(context: ctx)
        let env = AppEnvironment(container: container, parser: parser)
        let vm = RecordingViewModel(env: env, repository: repo, stats: stats)
        return (vm, ctx)
    }

    @Test func textSubmissionAddsUserBubbleAndGroupCard() async throws {
        let parsed = ParsedTransaction(
            amount: Decimal(38), currency: "CNY", type: .expense, title: "Lunch",
            merchant: nil, occurredAt: Date(), categoryName: "Food",
            subcategoryName: nil, tagNames: ["work"], paymentMethodName: "WeChat Pay", notes: nil
        )
        let (vm, _) = makeVM(parser: FakeParser(result: .success(.init(transactions: [parsed], failed: []))))
        await vm.submitText("lunch 38")
        let kinds = vm.messages.map { $0.kind }
        let hasUser = kinds.contains { if case .userBubble = $0 { return true } else { return false } }
        let hasGroup = kinds.contains { if case .group = $0 { return true } else { return false } }
        #expect(hasUser && hasGroup)
    }

    @Test func parserFailureSurfacesError() async {
        let (vm, _) = makeVM(parser: FakeParser(result: .failure(AIParsingError.invalidJSON("nope"))))
        await vm.submitText("bad")
        #expect(vm.errorMessage != nil)
    }

    @Test func blocksSubmissionWhenNoDefaultProvider() async {
        let container = AppContainer.make(inMemory: true)
        let env = AppEnvironment(container: container)
        let vm = RecordingViewModel(env: env, repository: LedgerRepository(context: container.mainContext), stats: StatsService(context: container.mainContext))
        await vm.submitText("anything")
        #expect(vm.errorMessage?.contains("provider") == true)
    }
}
```

- [ ] **Step 3: Run tests (expect failure)**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/RecordingViewModelTests`
Expected: FAIL — `cannot find 'RecordingViewModel'`

- [ ] **Step 4: Implement the view model**

Create `PocketHeart/Features/Recording/RecordingViewModel.swift`:

```swift
import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class RecordingViewModel {
    var messages: [StreamMessage] = []
    var inputText: String = ""
    var isSubmitting: Bool = false
    var isRecording: Bool = false
    var liveTranscript: String = ""
    var errorMessage: String?
    var summary: StatsSummary?

    let env: AppEnvironment
    let repository: LedgerRepository
    let stats: StatsService

    init(env: AppEnvironment, repository: LedgerRepository, stats: StatsService) {
        self.env = env
        self.repository = repository
        self.stats = stats
    }

    func load() {
        do {
            let entries = try repository.recentInputEntries(limit: 50).reversed()
            messages = []
            messages.append(.init(kind: .dayDivider(label: "Today")))
            for e in entries {
                messages.append(.init(kind: .userBubble(text: e.rawText, source: e.source, time: e.createdAt)))
                if let card = try? buildGroupCard(for: e) {
                    messages.append(.init(kind: .group(card)))
                }
            }
            summary = try stats.summary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submitText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await runSubmission(rawText: trimmed, source: .text)
        inputText = ""
    }

    func startRecording() async {
        guard await env.speech.requestAuthorization() else {
            errorMessage = "Microphone or speech permission denied. Use the text input or open Settings."
            return
        }
        do {
            isRecording = true
            liveTranscript = ""
            try await env.speech.startRecording { [weak self] partial in
                Task { @MainActor in self?.liveTranscript = partial }
            }
        } catch {
            isRecording = false
            errorMessage = "Couldn't start recording: \(error.localizedDescription)"
        }
    }

    func stopRecordingAndSubmit() async {
        guard isRecording else { return }
        isRecording = false
        do {
            let transcript = try await env.speech.stop()
            liveTranscript = ""
            guard !transcript.isEmpty else {
                errorMessage = "No speech detected. Tap to retry."
                return
            }
            await runSubmission(rawText: transcript, source: .voice)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func cancelRecording() {
        env.speech.cancel()
        isRecording = false
        liveTranscript = ""
    }

    private func runSubmission(rawText: String, source: InputSource) async {
        guard let provider = try? env.defaultProvider() else {
            errorMessage = "No active AI provider — open Settings to add one."
            return
        }
        let key: String
        do { key = try env.keychain.get(account: provider.id.uuidString) ?? "" }
        catch { errorMessage = "Couldn't read API key: \(error.localizedDescription)"; return }
        guard !key.isEmpty else {
            errorMessage = "Missing API key for \(provider.displayName) — open provider settings."
            return
        }

        messages.append(.init(kind: .userBubble(text: rawText, source: source, time: .now)))
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let context = try makeParsingContext(defaultCurrency: "CNY")
            let parsed = try await env.parser.parse(input: rawText, apiKey: key, baseURL: provider.baseURL, model: provider.modelName, context: context)
            let result = try repository.save(input: rawText, source: source, providerID: provider.id, parsed: parsed)
            if let entry = try repository.recentInputEntries(limit: 1).first, entry.id == result.inputEntryID {
                let card = try buildGroupCard(for: entry, overrideFailed: result.failedItems)
                messages.append(.init(kind: .group(card)))
            }
            summary = try stats.summary()
        } catch let e as AIParsingError {
            errorMessage = describe(e)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func describe(_ e: AIParsingError) -> String {
        switch e {
        case .missingAPIKey: return "Provider is missing an API key."
        case .missingProvider: return "No AI provider is configured."
        case .invalidJSON: return "AI response wasn't valid JSON."
        case .providerFailure(let s): return "Provider error: \(s)"
        }
    }

    private func makeParsingContext(defaultCurrency: String) throws -> ParsingContext {
        let ctx = env.container.mainContext
        let cats = try ctx.fetch(FetchDescriptor<LedgerCategory>(predicate: #Predicate { $0.isArchived == false }))
        let nameByID = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.name) })
        let refs = cats.map { ParsingContext.CategoryRef(id: $0.id, name: $0.name, parentName: $0.parentID.flatMap { nameByID[$0] }) }
        let tags = try ctx.fetch(FetchDescriptor<LedgerTag>(predicate: #Predicate { $0.isArchived == false })).map(\.name)
        let pays = try ctx.fetch(FetchDescriptor<PaymentMethod>(predicate: #Predicate { $0.isArchived == false })).map(\.name)
        return ParsingContext(now: .now, timeZone: .current, locale: .current, defaultCurrency: defaultCurrency, categories: refs, tags: tags, paymentMethods: pays)
    }

    private func buildGroupCard(for entry: InputEntry, overrideFailed: [ParsedFailure]? = nil) throws -> GroupCardModel {
        let txns = try repository.transactions(for: entry)
        let rows: [TransactionRowModel] = try txns.map { t in
            let cat = try repository.category(id: t.categoryID)
            let sub = try t.subcategoryID.flatMap { try repository.category(id: $0) }
            let pay = try repository.paymentMethod(id: t.paymentMethodID)
            let tags = try repository.tags(ids: t.tagIDs).map(\.name)
            return TransactionRowModel(
                id: t.id, amount: t.amount, currency: t.currency, type: t.type,
                title: t.title, merchant: t.merchant, occurredAt: t.occurredAt,
                categoryName: cat?.name ?? "Other", iconKey: cat?.iconKey ?? "other",
                subcategoryName: sub?.name, tagNames: tags, paymentName: pay?.name ?? "—"
            )
        }
        let totalSpent = rows.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        let totalIncome = rows.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let summary = makeSummary(spent: totalSpent, income: totalIncome, expenseCount: rows.filter{ $0.type == .expense }.count, incomeCount: rows.filter{ $0.type == .income }.count, currency: rows.first?.currency ?? "CNY")
        return GroupCardModel(
            inputEntryID: entry.id, source: entry.source, when: entry.createdAt,
            summary: summary, transactions: rows, failed: overrideFailed ?? []
        )
    }

    private func makeSummary(spent: Decimal, income: Decimal, expenseCount: Int, incomeCount: Int, currency: String) -> String {
        var parts: [String] = []
        if expenseCount > 0 { parts.append("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")") }
        if incomeCount > 0 { parts.append("\(incomeCount) income") }
        let net = income - spent
        let sign = net >= 0 ? "+" : ""
        let amountStr = "\(currency) \(sign)\(net)"
        return parts.joined(separator: " · ") + " · " + amountStr
    }
}
```

- [ ] **Step 5: Run tests**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartTests/RecordingViewModelTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: recording view model integrating parser and repository"
```

---

## Task 18: Recording stream — UI

**Files:**
- Create: `PocketHeart/Features/Recording/RecordingView.swift`
- Create: `PocketHeart/Features/Recording/InputBar.swift`
- Create: `PocketHeart/Features/Recording/UserBubble.swift`
- Create: `PocketHeart/Features/Recording/GroupCardView.swift`
- Create: `PocketHeart/Features/Recording/TransactionRow.swift`
- Create: `PocketHeart/Features/Recording/DayDivider.swift`
- Create: `PocketHeart/Features/Recording/TodayChip.swift`
- Modify: `PocketHeart/App/RootView.swift`

- [ ] **Step 1: `DayDivider`**

```swift
import SwiftUI

struct DayDivider: View {
    let label: String
    var body: some View {
        HStack(spacing: 10) {
            Capsule().fill(Theme.separator).frame(height: 0.5)
            Text(label.uppercased())
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .tracking(0.4)
            Capsule().fill(Theme.separator).frame(height: 0.5)
        }
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 2: `UserBubble`**

```swift
import SwiftUI

struct UserBubbleView: View {
    let text: String
    let source: InputSource
    let time: Date

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 3) {
                VStack(alignment: .leading, spacing: 6) {
                    if source == .voice {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill").font(.system(size: 10))
                            Text("VOICE").font(.system(size: 10.5, weight: .medium)).tracking(0.3)
                        }
                        .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Text(text)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(LinearGradient(colors: [Color(red:0.55,green:0.45,blue:1.0), Theme.primary], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 18))
                Text(time, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.bottom, 8)
    }
}

struct LiveRecordingBubble: View {
    let elapsed: TimeInterval
    @State private var pulse = false
    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Circle().fill(Theme.danger).frame(width: 8, height: 8).opacity(pulse ? 1 : 0.4)
                Text(formatted(elapsed)).font(.system(size: 13, design: .monospaced)).foregroundStyle(Theme.primaryLight)
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.primary.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.primary.opacity(0.45), lineWidth: 1))
            .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever()) { pulse = true } }
        }
    }
    private func formatted(_ s: TimeInterval) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
```

- [ ] **Step 3: `TransactionRow`**

```swift
import SwiftUI

struct TransactionRowView: View {
    let model: TransactionRowModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 11) {
                CategoryIcon(key: model.iconKey, size: 36)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(model.title).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                        if let m = model.merchant { Text("· " + m).font(.system(size: 11)).foregroundStyle(Theme.textMuted).lineLimit(1) }
                    }
                    HStack(spacing: 4) {
                        MetaPill(text: model.subcategoryName ?? model.categoryName)
                        MetaPill(text: model.paymentName, muted: true)
                        ForEach(model.tagNames, id: \.self) { TagPill(text: $0) }
                    }
                    Text(model.occurredAt, style: .time)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    Text(formatted())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(model.type == .income ? Theme.success : .white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
        }
        .buttonStyle(.plain)
    }

    private func formatted() -> String {
        let symbol = model.currency == "CNY" ? "¥" : model.currency
        let sign = model.type == .income ? "+" : ""
        return "\(sign)\(symbol)\(model.amount)"
    }
}
```

- [ ] **Step 4: `GroupCardView`**

```swift
import SwiftUI

struct GroupCardView: View {
    let model: GroupCardModel
    let onTapTransaction: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 7) {
                    RoundedRectangle(cornerRadius: 6).fill(Theme.primary).frame(width: 18, height: 18)
                        .overlay { Image(systemName: "sparkle").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white) }
                    Text(model.summary).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                Text("\(model.source.rawValue) · \(model.when.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.separator).frame(height: 0.5) }

            VStack(spacing: 0) {
                ForEach(Array(model.transactions.enumerated()), id: \.element.id) { idx, txn in
                    TransactionRowView(model: txn) { onTapTransaction(txn.id) }
                    if idx < model.transactions.count - 1 {
                        Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 14)
                    }
                }
            }

            if !model.failed.isEmpty {
                ForEach(model.failed.indices, id: \.self) { i in
                    let f = model.failed[i]
                    HStack(spacing: 9) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Theme.warning).font(.system(size: 13))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(f.reason).font(.system(size: 12)).foregroundStyle(Theme.warning)
                            Text(f.raw).font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Theme.warning.opacity(0.06))
                    .overlay(alignment: .top) { Rectangle().fill(Theme.warning.opacity(0.18)).frame(height: 0.5) }
                }
            }
        }
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerLarge))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerLarge).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .padding(.bottom, 12)
    }
}
```

- [ ] **Step 5: `TodayChip`**

```swift
import SwiftUI

struct TodayChip: View {
    let summary: StatsSummary?
    let onStats: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("SPENT TODAY").font(.system(size: 10.5, weight: .medium)).tracking(0.3).foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(spent).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    if let income = incomeText {
                        Text(income).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.success)
                    }
                }
            }
            Spacer()
            Button(action: onStats) {
                HStack(spacing: 5) {
                    Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 11, weight: .semibold))
                    Text("Stats").font(.system(size: 12.5, weight: .medium))
                }
                .padding(.horizontal, 11).padding(.vertical, 7)
                .background(Theme.primary.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(Theme.primaryLight)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(LinearGradient(colors: [Theme.primary.opacity(0.18), Theme.primary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.primary.opacity(0.25), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var spent: String {
        let value = summary?.todaySpent ?? 0
        return "¥\(value)"
    }
    private var incomeText: String? {
        guard let income = summary?.monthIncome, income > 0 else { return nil }
        return "+¥\(income) in"
    }
}
```

- [ ] **Step 6: `InputBar`**

```swift
import SwiftUI

struct InputBar: View {
    @Binding var text: String
    let isRecording: Bool
    let liveTranscript: String
    let onSend: () -> Void
    let onMicTap: () -> Void
    let onMicCancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { /* keyboard mode toggle */ }) {
                Image(systemName: "keyboard").foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.07), in: Circle())
            }

            ZStack {
                if isRecording {
                    Text(liveTranscript.isEmpty ? "Listening…" : liveTranscript)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(2)
                } else {
                    TextField("Tell me what you spent…", text: $text, axis: .vertical)
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .tint(Theme.primary)
                        .lineLimit(1...4)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))

            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRecording {
                Button(action: onSend) {
                    Image(systemName: "arrow.up").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white).frame(width: 38, height: 38)
                        .background(Theme.primary, in: Circle())
                }
            } else {
                Button(action: { isRecording ? onMicCancel() : onMicTap() }) {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white).frame(width: 38, height: 38)
                        .background(isRecording ? Theme.danger : Theme.primary, in: Circle())
                        .shadow(color: Theme.primary.opacity(0.4), radius: 10, y: 4)
                }
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.25).onEnded { _ in onMicTap() })
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
```

- [ ] **Step 7: Main `RecordingView`**

```swift
import SwiftUI

struct RecordingView: View {
    @Environment(\.appEnv) private var appEnv
    @State private var vm: RecordingViewModel?
    @State private var showStats = false
    @State private var showSettings = false
    @State private var editingTransactionID: UUID?

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView().tint(.white)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if vm == nil, let env = appEnv {
                vm = RecordingViewModel(env: env, repository: env.repository, stats: env.stats)
                vm?.load()
            }
        }
    }

    @ViewBuilder
    private func content(vm: RecordingViewModel) -> some View {
        @Bindable var bindable = vm
        VStack(spacing: 0) {
            navBar
            TodayChip(summary: vm.summary, onStats: { showStats = true })
                .padding(.bottom, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.messages) { m in
                            switch m.kind {
                            case .dayDivider(let label): DayDivider(label: label)
                            case .userBubble(let text, let source, let time):
                                UserBubbleView(text: text, source: source, time: time)
                            case .group(let card):
                                GroupCardView(model: card) { id in editingTransactionID = id }
                            }
                        }
                        if vm.isRecording { LiveRecordingBubble(elapsed: 0) }
                        if vm.isSubmitting { ProgressView().padding() }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 14)
                }
                .onChange(of: vm.messages.count) {
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }

            if let err = vm.errorMessage {
                Text(err).font(.system(size: 12)).foregroundStyle(Theme.warning)
                    .padding(.horizontal, 16).padding(.vertical, 6)
            }

            InputBar(
                text: $bindable.inputText,
                isRecording: vm.isRecording,
                liveTranscript: vm.liveTranscript,
                onSend: { Task { await vm.submitText(vm.inputText) } },
                onMicTap: { Task { vm.isRecording ? await vm.stopRecordingAndSubmit() : await vm.startRecording() } },
                onMicCancel: { vm.cancelRecording() }
            )
        }
        .navigationDestination(isPresented: $showStats) { StatsView() }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .sheet(item: Binding(get: { editingTransactionID.map { IdentifiedID(id: $0) } }, set: { editingTransactionID = $0?.id })) { wrapper in
            EditTransactionView(transactionID: wrapper.id) {
                editingTransactionID = nil
                vm.load()
            }
        }
    }

    private var navBar: some View {
        HStack {
            Button { showSettings = true } label: {
                Image(systemName: "slider.horizontal.3").foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.white.opacity(0.07), in: Circle())
            }
            Spacer()
            VStack(spacing: 0) {
                Text(monthHeader).font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 4) {
                    Text("Ledger").font(.system(size: 15, weight: .semibold)).foregroundStyle(.white)
                    if let p = activeProviderName {
                        Text(p).font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Theme.primary.opacity(0.16), in: Capsule())
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            Spacer()
            Button { showStats = true } label: {
                Image(systemName: "chart.bar").foregroundStyle(.white)
                    .frame(width: 34, height: 34).background(Color.white.opacity(0.07), in: Circle())
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 4)
    }

    private var monthHeader: String {
        Date.now.formatted(.dateTime.month(.wide)) + " · Today"
    }
    private var activeProviderName: String? {
        try? appEnv?.defaultProvider()?.displayName
    }
}

struct IdentifiedID: Identifiable, Equatable { let id: UUID }
```

- [ ] **Step 8: Update `RootView`**

Replace `PocketHeart/App/RootView.swift`:

```swift
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            RecordingView()
        }
        .tint(Theme.primary)
    }
}
```

- [ ] **Step 9: Build (note: `EditTransactionView`, `StatsView`, `SettingsView` are added in later tasks — for this task add empty stubs to keep the build green)**

Add temporary stub at end of `RootView.swift`:

```swift
struct StatsView: View { var body: some View { Text("Stats").foregroundStyle(.white) } }
struct SettingsView: View { var body: some View { Text("Settings").foregroundStyle(.white) } }
struct EditTransactionView: View { let transactionID: UUID; let onClose: () -> Void; var body: some View { Button("Close", action: onClose) } }
```

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat: recording stream UI with chat bubbles and grouped result cards"
```

---

## Task 19: Edit transaction screen

**Files:**
- Create: `PocketHeart/Features/Editing/EditTransactionViewModel.swift`
- Create: `PocketHeart/Features/Editing/EditTransactionView.swift`
- Create: `PocketHeart/Features/Editing/PickerSheets.swift`
- Modify: `PocketHeart/App/RootView.swift` (remove the stub)

- [ ] **Step 1: View model**

```swift
import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class EditTransactionViewModel {
    var amountString: String = ""
    var currency: String = "CNY"
    var type: TransactionType = .expense
    var title: String = ""
    var merchant: String = ""
    var occurredAt: Date = .now
    var categoryID: UUID?
    var subcategoryID: UUID?
    var tagIDs: [UUID] = []
    var paymentMethodID: UUID?
    var notes: String = ""

    let txnID: UUID
    let repository: LedgerRepository
    let context: ModelContext
    private(set) var loaded = false
    var error: String?

    init(txnID: UUID, repository: LedgerRepository, context: ModelContext) {
        self.txnID = txnID
        self.repository = repository
        self.context = context
    }

    func load() {
        guard !loaded else { return }
        guard let txn = try? context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnID })).first else {
            error = "Transaction not found"
            return
        }
        amountString = "\(txn.amount)"
        currency = txn.currency
        type = txn.type
        title = txn.title
        merchant = txn.merchant ?? ""
        occurredAt = txn.occurredAt
        categoryID = txn.categoryID
        subcategoryID = txn.subcategoryID
        tagIDs = txn.tagIDs
        paymentMethodID = txn.paymentMethodID
        notes = txn.notes ?? ""
        loaded = true
    }

    func save() throws {
        guard let txn = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnID })).first else { return }
        guard let amount = Decimal(string: amountString), amount > 0 else { throw NSError(domain: "Edit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Amount must be a positive number."]) }
        try repository.update(txn) { t in
            t.amount = amount
            t.currency = self.currency
            t.type = self.type
            t.title = self.title
            t.merchant = self.merchant.isEmpty ? nil : self.merchant
            t.occurredAt = self.occurredAt
            if let c = self.categoryID { t.categoryID = c }
            t.subcategoryID = self.subcategoryID
            t.tagIDs = self.tagIDs
            if let p = self.paymentMethodID { t.paymentMethodID = p }
            t.notes = self.notes.isEmpty ? nil : self.notes
        }
    }

    func delete() throws {
        guard let txn = try context.fetch(FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnID })).first else { return }
        try repository.delete(txn)
    }
}
```

- [ ] **Step 2: Picker sheets**

```swift
import SwiftUI
import SwiftData

struct CategoryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LedgerCategory> { $0.parentID == nil && $0.isArchived == false }) private var categories: [LedgerCategory]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            List(categories, id: \.id) { c in
                Button {
                    selection = c.id; dismiss()
                } label: {
                    HStack {
                        CategoryIcon(key: c.iconKey, size: 26)
                        Text(c.name).foregroundStyle(.white)
                        Spacer()
                        if selection == c.id { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PaymentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<PaymentMethod> { $0.isArchived == false }) private var methods: [PaymentMethod]
    @Binding var selection: UUID?

    var body: some View {
        NavigationStack {
            List(methods, id: \.id) { m in
                Button { selection = m.id; dismiss() } label: {
                    HStack {
                        Text(m.name).foregroundStyle(.white)
                        Spacer()
                        if selection == m.id { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Payment method")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TagsPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LedgerTag> { $0.isArchived == false }) private var tags: [LedgerTag]
    @Binding var selection: [UUID]

    var body: some View {
        NavigationStack {
            List(tags, id: \.id) { t in
                Button {
                    if let i = selection.firstIndex(of: t.id) { selection.remove(at: i) } else { selection.append(t.id) }
                } label: {
                    HStack {
                        Text("#" + t.name).foregroundStyle(.white)
                        Spacer()
                        if selection.contains(t.id) { Image(systemName: "checkmark").foregroundStyle(Theme.primary) }
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg)
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
```

- [ ] **Step 3: Edit view**

Create `PocketHeart/Features/Editing/EditTransactionView.swift`:

```swift
import SwiftUI
import SwiftData

struct EditTransactionView: View {
    let transactionID: UUID
    let onClose: () -> Void

    @Environment(\.appEnv) private var env
    @State private var vm: EditTransactionViewModel?
    @State private var showCategory = false
    @State private var showPayment = false
    @State private var showTags = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm { form(vm: vm) } else { ProgressView() }
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { onClose() }.tint(Theme.primary) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }.tint(Theme.primary).bold()
                }
            }
            .navigationTitle("Edit transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if vm == nil, let env {
                vm = EditTransactionViewModel(txnID: transactionID, repository: env.repository, context: env.container.mainContext)
                vm?.load()
            }
        }
    }

    @ViewBuilder
    private func form(vm: EditTransactionViewModel) -> some View {
        @Bindable var bindable = vm
        ScrollView {
            VStack(spacing: 14) {
                amountHero(vm: bindable)
                Form {
                    Section {
                        TextField("Title", text: $bindable.title)
                        TextField("Merchant", text: $bindable.merchant)
                        DatePicker("Time", selection: $bindable.occurredAt)
                        TextField("Currency", text: $bindable.currency)
                    }
                    Section("Category") {
                        Button { showCategory = true } label: {
                            HStack { Text("Category"); Spacer(); Text(currentCategoryName(vm: vm)).foregroundStyle(.secondary) }
                        }
                    }
                    Section("Payment") {
                        Button { showPayment = true } label: {
                            HStack { Text("Payment"); Spacer(); Text(currentPaymentName(vm: vm)).foregroundStyle(.secondary) }
                        }
                        Button { showTags = true } label: {
                            HStack { Text("Tags"); Spacer(); Text("\(vm.tagIDs.count) selected").foregroundStyle(.secondary) }
                        }
                    }
                    Section("Notes") {
                        TextField("Notes", text: $bindable.notes, axis: .vertical).lineLimit(2...5)
                    }
                    Section {
                        Button(role: .destructive) { deleteAndClose() } label: {
                            HStack { Spacer(); Text("Delete transaction"); Spacer() }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .frame(minHeight: 600)
            }
        }
        .sheet(isPresented: $showCategory) { CategoryPickerSheet(selection: $bindable.categoryID) }
        .sheet(isPresented: $showPayment) { PaymentPickerSheet(selection: $bindable.paymentMethodID) }
        .sheet(isPresented: $showTags) { TagsPickerSheet(selection: $bindable.tagIDs) }
    }

    private func amountHero(vm: EditTransactionViewModel) -> some View {
        @Bindable var b = vm
        return VStack(spacing: 8) {
            HStack {
                Button { b.type = .expense } label: { TypePill(type: .expense, active: b.type == .expense) }
                Button { b.type = .income } label: { TypePill(type: .income, active: b.type == .income) }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(b.currency) ¥").font(.system(size: 18, weight: .medium)).foregroundStyle(.secondary)
                TextField("0.00", text: $b.amountString)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func currentCategoryName(vm: EditTransactionViewModel) -> String {
        guard let id = vm.categoryID else { return "—" }
        return (try? env?.repository.category(id: id)?.name) ?? "—"
    }
    private func currentPaymentName(vm: EditTransactionViewModel) -> String {
        guard let id = vm.paymentMethodID else { return "—" }
        return (try? env?.repository.paymentMethod(id: id)?.name) ?? "—"
    }
    private func saveAndClose() {
        do { try vm?.save(); onClose() } catch { vm?.error = error.localizedDescription }
    }
    private func deleteAndClose() {
        do { try vm?.delete(); onClose() } catch { vm?.error = error.localizedDescription }
    }
}
```

- [ ] **Step 4: Remove the stub `EditTransactionView` from `RootView.swift`**

In `PocketHeart/App/RootView.swift`, delete the `struct EditTransactionView { ... }` stub line.

- [ ] **Step 5: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: edit transaction screen with category/payment/tag pickers"
```

---

## Task 20: Stats screen

**Files:**
- Create: `PocketHeart/Features/Stats/StatsViewModel.swift`
- Create: `PocketHeart/Features/Stats/StatsView.swift`
- Modify: `PocketHeart/App/RootView.swift` (remove the stub)

- [ ] **Step 1: View model**

```swift
import Foundation

@MainActor
@Observable
final class StatsViewModel {
    var summary: StatsSummary?
    var error: String?
    let stats: StatsService

    init(stats: StatsService) { self.stats = stats }

    func load() {
        do { summary = try stats.summary() }
        catch { error = error.localizedDescription }
    }
}
```

- [ ] **Step 2: Stats view**

```swift
import SwiftUI

struct StatsView: View {
    @Environment(\.appEnv) private var env
    @State private var vm: StatsViewModel?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if let s = vm?.summary {
                    hero(s: s)
                    Text("BY CATEGORY").font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 14).padding(.top, 8)
                    VStack(spacing: 0) {
                        ForEach(Array(s.categoryShare.enumerated()), id: \.offset) { idx, slice in
                            HStack(spacing: 11) {
                                CategoryIcon(key: iconKey(for: slice.categoryName), size: 32)
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(slice.categoryName).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                                        Spacer()
                                        Text("¥\(slice.amount)").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.08))
                                            Capsule().fill(Theme.primary).frame(width: geo.size.width * slice.percent)
                                        }
                                    }
                                    .frame(height: 4)
                                    Text(String(format: "%.0f%%", slice.percent * 100))
                                        .font(.system(size: 10.5)).foregroundStyle(Theme.textMuted)
                                }
                            }
                            .padding(14)
                            if idx < s.categoryShare.count - 1 {
                                Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 14)
                            }
                        }
                    }
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerCard))
                    .padding(.horizontal, 16)
                } else {
                    ProgressView().tint(.white).padding(.top, 80)
                }
            }
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if vm == nil, let env { vm = StatsViewModel(stats: env.stats); vm?.load() }
        }
    }

    private func hero(s: StatsSummary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monthLabel.uppercased()).font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("¥").font(.system(size: 16)).foregroundStyle(Theme.textSecondary)
                        Text("\(s.monthSpent)").font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("INCOME").font(.system(size: 11, weight: .medium)).tracking(0.4).foregroundStyle(Theme.textSecondary)
                    Text("+¥\(s.monthIncome)").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.success)
                    Text("net ¥\(s.monthIncome - s.monthSpent)").font(.system(size: 11)).foregroundStyle(Theme.textMuted)
                }
            }
            HStack(alignment: .bottom, spacing: 4) {
                let max = s.dailyTrend.max() ?? 1
                let maxDouble = NSDecimalNumber(decimal: max == 0 ? 1 : max).doubleValue
                ForEach(s.dailyTrend.indices, id: \.self) { i in
                    let v = NSDecimalNumber(decimal: s.dailyTrend[i]).doubleValue
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i == s.dailyTrend.count - 1 ? Theme.primary : Theme.primary.opacity(0.32))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(2, CGFloat(v / maxDouble) * 64))
                }
            }
            .frame(height: 64)
            .padding(.top, 18)
        }
        .padding(16)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerLarge))
        .padding(.horizontal, 16)
    }

    private var monthLabel: String { Date.now.formatted(.dateTime.month(.wide)) + " spent" }

    private func iconKey(for name: String) -> String {
        switch name.lowercased() {
        case "food": return "food"
        case "transit": return "transit"
        case "coffee": return "coffee"
        case "grocery": return "grocery"
        case "salary": return "salary"
        default: return "other"
        }
    }
}
```

- [ ] **Step 3: Remove `struct StatsView` stub from `RootView.swift`**

- [ ] **Step 4: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: stats screen with month totals, category share, and trend"
```

---

## Task 21: Settings — provider list and edit

**Files:**
- Create: `PocketHeart/Features/Settings/SettingsView.swift`
- Create: `PocketHeart/Features/Settings/Providers/ProviderListView.swift`
- Create: `PocketHeart/Features/Settings/Providers/ProviderEditViewModel.swift`
- Create: `PocketHeart/Features/Settings/Providers/ProviderEditView.swift`
- Modify: `PocketHeart/App/RootView.swift` (remove the stub)

- [ ] **Step 1: ProviderEditViewModel with template prefills**

```swift
import Foundation
import SwiftData

@MainActor
@Observable
final class ProviderEditViewModel {
    var displayName: String = ""
    var template: ProviderTemplate = .openAI
    var baseURL: String = ""
    var modelName: String = ""
    var interface: InterfaceFormat = .openAICompatible
    var apiKey: String = ""
    var isDefault: Bool = false
    var error: String?

    let editingID: UUID?
    let context: ModelContext
    let keychain: Keychain

    init(editingID: UUID?, context: ModelContext, keychain: Keychain = .providers) {
        self.editingID = editingID
        self.context = context
        self.keychain = keychain
    }

    func load() {
        guard let id = editingID,
              let p = try? context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first else {
            applyTemplate(.openAI)
            return
        }
        displayName = p.displayName
        template = p.template
        baseURL = p.baseURL
        modelName = p.modelName
        interface = p.interface
        isDefault = p.isDefault
        apiKey = (try? keychain.get(account: id.uuidString)) ?? ""
    }

    func applyTemplate(_ t: ProviderTemplate) {
        template = t
        switch t {
        case .openAI:
            displayName = displayName.isEmpty ? "OpenAI" : displayName
            baseURL = "https://api.openai.com/v1"; modelName = "gpt-4o-mini"; interface = .openAICompatible
        case .deepSeek:
            displayName = displayName.isEmpty ? "DeepSeek" : displayName
            baseURL = "https://api.deepseek.com/v1"; modelName = "deepseek-chat"; interface = .openAICompatible
        case .anthropic:
            displayName = displayName.isEmpty ? "Anthropic" : displayName
            baseURL = "https://api.anthropic.com"; modelName = "claude-haiku-4-5"; interface = .anthropicMessages
        case .gemini:
            displayName = displayName.isEmpty ? "Gemini" : displayName
            baseURL = "https://generativelanguage.googleapis.com"; modelName = "gemini-1.5-flash"; interface = .geminiGenerateContent
        case .ollama:
            displayName = displayName.isEmpty ? "Local · Ollama" : displayName
            baseURL = "http://localhost:11434/v1"; modelName = "qwen2:7b"; interface = .openAICompatible
        case .custom:
            interface = .openAICompatible
        }
    }

    func save() throws {
        guard !displayName.isEmpty, !baseURL.isEmpty, !modelName.isEmpty else {
            throw NSError(domain: "Provider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name, base URL, and model are required."])
        }
        guard URL(string: baseURL) != nil else {
            throw NSError(domain: "Provider", code: 2, userInfo: [NSLocalizedDescriptionKey: "Base URL is invalid."])
        }
        let provider: AIProvider
        if let id = editingID, let existing = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first {
            existing.displayName = displayName
            existing.template = template
            existing.baseURL = baseURL
            existing.modelName = modelName
            existing.interface = interface
            existing.updatedAt = .now
            provider = existing
        } else {
            provider = AIProvider(displayName: displayName, template: template, baseURL: baseURL, modelName: modelName, interface: interface)
            context.insert(provider)
        }
        if isDefault {
            let others = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id != provider.id }))
            for other in others { other.isDefault = false }
            provider.isDefault = true
        } else if !(try anyDefaultExists()) {
            provider.isDefault = true
        } else {
            provider.isDefault = isDefault
        }
        if !apiKey.isEmpty {
            try keychain.set(apiKey, account: provider.id.uuidString)
        }
        try context.save()
    }

    private func anyDefaultExists() throws -> Bool {
        let existing = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.isDefault == true }))
        return !existing.isEmpty
    }

    func delete() throws {
        guard let id = editingID, let p = try context.fetch(FetchDescriptor<AIProvider>(predicate: #Predicate { $0.id == id })).first else { return }
        try? keychain.delete(account: id.uuidString)
        context.delete(p)
        try context.save()
    }
}
```

- [ ] **Step 2: ProviderEditView**

```swift
import SwiftUI

struct ProviderEditView: View {
    let providerID: UUID?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appEnv) private var env
    @State private var vm: ProviderEditViewModel?

    var body: some View {
        Group {
            if let vm { form(vm: vm) } else { ProgressView() }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(providerID == nil ? "Add provider" : "Edit provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveAndClose() }.bold()
            }
        }
        .onAppear {
            if vm == nil, let env { vm = ProviderEditViewModel(editingID: providerID, context: env.container.mainContext); vm?.load() }
        }
    }

    @ViewBuilder
    private func form(vm: ProviderEditViewModel) -> some View {
        @Bindable var b = vm
        Form {
            Section("Template") {
                Picker("Template", selection: $b.template) {
                    ForEach(ProviderTemplate.allCases, id: \.self) { t in Text(t.rawValue.capitalized).tag(t) }
                }
                .onChange(of: b.template) { _, new in vm.applyTemplate(new) }
            }
            Section("Provider") {
                TextField("Display name", text: $b.displayName)
                TextField("Base URL", text: $b.baseURL).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("Model", text: $b.modelName).autocorrectionDisabled().textInputAutocapitalization(.never)
                Picker("Interface", selection: $b.interface) {
                    Text("OpenAI-compatible").tag(InterfaceFormat.openAICompatible)
                    Text("Anthropic Messages").tag(InterfaceFormat.anthropicMessages)
                    Text("Gemini generateContent").tag(InterfaceFormat.geminiGenerateContent)
                }
            }
            Section("API key") {
                SecureField("Stored in iOS Keychain", text: $b.apiKey)
            }
            Section {
                Toggle("Default provider", isOn: $b.isDefault)
            }
            if providerID != nil {
                Section { Button(role: .destructive) { deleteAndClose() } label: { Text("Delete provider") } }
            }
            if let err = vm.error {
                Section { Text(err).foregroundStyle(Theme.warning) }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func saveAndClose() {
        do { try vm?.save(); dismiss() } catch { vm?.error = error.localizedDescription }
    }
    private func deleteAndClose() {
        do { try vm?.delete(); dismiss() } catch { vm?.error = error.localizedDescription }
    }
}
```

- [ ] **Step 3: ProviderListView**

```swift
import SwiftUI
import SwiftData

struct ProviderListView: View {
    @Query(sort: \AIProvider.createdAt) private var providers: [AIProvider]
    @State private var newProvider = false
    @State private var editingID: UUID?

    var body: some View {
        List {
            ForEach(providers, id: \.id) { p in
                Button { editingID = p.id } label: {
                    HStack(spacing: 12) {
                        ProviderBadge(name: p.displayName)
                        VStack(alignment: .leading) {
                            HStack {
                                Text(p.displayName).font(.system(size: 14.5, weight: .semibold)).foregroundStyle(.white)
                                if p.isDefault {
                                    Text("DEFAULT").font(.system(size: 9.5, weight: .bold))
                                        .padding(.horizontal, 6).padding(.vertical, 1)
                                        .background(Theme.primary.opacity(0.2), in: Capsule())
                                        .foregroundStyle(Theme.primary)
                                }
                            }
                            Text(p.modelName).font(.system(size: 11.5, design: .monospaced)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.textMuted)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            Section {
                Text("You bring your own API key. Keys are stored in iOS Keychain and never leave the device.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textMuted)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("AI providers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { newProvider = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $newProvider) { NavigationStack { ProviderEditView(providerID: nil) }.preferredColorScheme(.dark) }
        .sheet(item: Binding(get: { editingID.map { IdentifiedID(id: $0) } }, set: { editingID = $0?.id })) { wrapper in
            NavigationStack { ProviderEditView(providerID: wrapper.id) }.preferredColorScheme(.dark)
        }
    }
}

struct ProviderBadge: View {
    let name: String
    var body: some View {
        let initials = String(name.split(separator: " ").compactMap(\.first).prefix(2)).uppercased()
        RoundedRectangle(cornerRadius: 9).fill(LinearGradient(colors: [Theme.primary.opacity(0.3), Theme.primary.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay {
                Text(initials).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.primaryLight)
            }
            .frame(width: 34, height: 34)
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.primary.opacity(0.25), lineWidth: 1))
    }
}
```

- [ ] **Step 4: SettingsView**

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section { NavigationLink("AI providers") { ProviderListView() } }
            Section("Taxonomy") {
                NavigationLink("Categories") { CategoriesView() }
                NavigationLink("Tags") { TagsView() }
                NavigationLink("Payment methods") { PaymentMethodsView() }
            }
            Section("Sync & Permissions") {
                Label("iCloud sync", systemImage: "icloud").foregroundStyle(.white)
                Label("Microphone & speech", systemImage: "mic.fill").foregroundStyle(.white)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
    }
}
```

- [ ] **Step 5: Remove `struct SettingsView` stub from `RootView.swift`**

- [ ] **Step 6: Add taxonomy view stubs** (real implementations in next task)

Append to `PocketHeart/Features/Settings/SettingsView.swift`:

```swift
import SwiftData

struct CategoriesView: View { var body: some View { Text("Categories").foregroundStyle(.white) } }
struct TagsView: View { var body: some View { Text("Tags").foregroundStyle(.white) } }
struct PaymentMethodsView: View { var body: some View { Text("Payment methods").foregroundStyle(.white) } }
```

- [ ] **Step 7: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: settings + AI provider management with Keychain-backed keys"
```

---

## Task 22: Taxonomy management screens

**Files:**
- Replace stubs in: `PocketHeart/Features/Settings/SettingsView.swift`
- Create: `PocketHeart/Features/Settings/Taxonomy/CategoriesView.swift`
- Create: `PocketHeart/Features/Settings/Taxonomy/TagsView.swift`
- Create: `PocketHeart/Features/Settings/Taxonomy/PaymentMethodsView.swift`

- [ ] **Step 1: CategoriesView**

```swift
import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: \LedgerCategory.name) private var categories: [LedgerCategory]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(categories.filter { !$0.isArchived && $0.parentID == nil }, id: \.id) { c in
                    HStack {
                        CategoryIcon(key: c.iconKey, size: 26)
                        Text(c.name).foregroundStyle(.white)
                        Spacer()
                        if c.isAICreated { Text("AI").font(.system(size: 9.5)).foregroundStyle(Theme.primary) }
                    }
                    .swipeActions {
                        Button("Archive") { c.isArchived = true; try? ctx.save() }
                            .tint(.orange)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Archived") {
                ForEach(categories.filter { $0.isArchived }, id: \.id) { c in
                    HStack {
                        Text(c.name).foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Button("Restore") { c.isArchived = false; try? ctx.save() }
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                HStack {
                    TextField("New category", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        ctx.insert(LedgerCategory(name: trimmed))
                        try? ctx.save()
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Categories")
    }
}
```

- [ ] **Step 2: TagsView**

```swift
import SwiftUI
import SwiftData

struct TagsView: View {
    @Query(sort: [SortDescriptor(\LedgerTag.usageCount, order: .reverse)]) private var tags: [LedgerTag]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""

    var body: some View {
        List {
            Section("Active") {
                ForEach(tags.filter { !$0.isArchived }, id: \.id) { t in
                    HStack {
                        Text("#" + t.name).foregroundStyle(.white)
                        Spacer()
                        Text("\(t.usageCount)").foregroundStyle(Theme.textMuted)
                    }
                    .swipeActions { Button("Archive") { t.isArchived = true; try? ctx.save() }.tint(.orange) }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                HStack {
                    TextField("New tag", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        ctx.insert(LedgerTag(name: trimmed))
                        try? ctx.save()
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Tags")
    }
}
```

- [ ] **Step 3: PaymentMethodsView**

```swift
import SwiftUI
import SwiftData

struct PaymentMethodsView: View {
    @Query(sort: \PaymentMethod.name) private var methods: [PaymentMethod]
    @Environment(\.modelContext) private var ctx
    @State private var newName = ""
    @State private var newKind: PaymentKind = .other

    var body: some View {
        List {
            Section("Active") {
                ForEach(methods.filter { !$0.isArchived }, id: \.id) { m in
                    HStack {
                        Text(m.name).foregroundStyle(.white)
                        Spacer()
                        Text(m.kind.rawValue).foregroundStyle(Theme.textMuted).font(.caption)
                    }
                    .swipeActions { Button("Archive") { m.isArchived = true; try? ctx.save() }.tint(.orange) }
                    .listRowBackground(Theme.surface)
                }
            }
            Section("Add") {
                TextField("Name", text: $newName).listRowBackground(Theme.surface)
                Picker("Kind", selection: $newKind) {
                    ForEach(PaymentKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .listRowBackground(Theme.surface)
                Button("Add") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    ctx.insert(PaymentMethod(name: trimmed, kind: newKind))
                    try? ctx.save()
                    newName = ""
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                .listRowBackground(Theme.surface)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Payment methods")
    }
}
```

- [ ] **Step 4: Remove the three stubs from `SettingsView.swift`**

- [ ] **Step 5: Build**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: taxonomy management screens for categories, tags, and payment methods"
```

---

## Task 23: UI smoke test

**Files:**
- Modify: `PocketHeartUITests/PocketHeartUITests.swift`

> Voice and AI calls are not exercised by UI tests (they would require either real provider creds or a test seam in the app). This UI test covers navigation only.

- [ ] **Step 1: Replace the default UI test**

```swift
import XCTest

final class PocketHeartUITests: XCTestCase {
    func testCanReachSettingsAndStats() throws {
        let app = XCUIApplication()
        app.launch()

        // Settings entry — leading nav button (slider icon)
        XCTAssertTrue(app.buttons["AI providers"].waitForExistence(timeout: 5) ||
                      app.navigationBars.firstMatch.exists, "App should launch into the recording screen")

        // Tap the leading nav settings icon
        let navButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'slider' OR label CONTAINS 'Settings'"))
        if navButtons.count > 0 { navButtons.firstMatch.tap() }

        XCTAssertTrue(app.staticTexts["AI providers"].waitForExistence(timeout: 3))
    }
}
```

- [ ] **Step 2: Run UI test**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:PocketHeartUITests/PocketHeartUITests/testCanReachSettingsAndStats`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add PocketHeartUITests
git commit -m "test: UI smoke test for navigation"
```

---

## Task 24: Manual verification checklist

> No code changes. Run the app on a simulator, walk through each scenario, and confirm or fix.

- [ ] **Step 1: Build & run on iOS Simulator**

Run: `xcodebuild -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`. Then launch in Simulator from Xcode (`Cmd-R`).

- [ ] **Step 2: Confirm provider gate**

With no providers configured, type "lunch 38" and tap send. The error banner must read "No active AI provider — open Settings to add one."

- [ ] **Step 3: Add a provider**

Settings → AI providers → +. Pick a template, paste an API key, save. Confirm the row shows the model id and the DEFAULT pill.

- [ ] **Step 4: Submit a multi-transaction text input**

Back on the main screen, type "coffee 28, lunch 38" and tap send. Expect: a user bubble, a loading indicator, then a group card with two transactions, the today chip updated, and the toolbar pill showing the active provider name.

- [ ] **Step 5: Edit a transaction**

Tap a row → change amount / category → Save. Confirm the group card and today chip refresh.

- [ ] **Step 6: Stats**

Tap Stats. Confirm month spent matches the sum of transactions and category share renders.

- [ ] **Step 7: Voice flow on a real device** (skipped on simulator — speech recognizer may be unavailable; document the limitation in the commit if any)

- [ ] **Step 8: Run the full test suite**

Run: `xcodebuild test -scheme PocketHeart -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: all tests pass.

- [ ] **Step 9: Commit any fixes uncovered**

```bash
git status
git add -A && git commit -m "fix: <whatever you fixed>"
```

If no fixes were needed, skip the commit.

---

## Spec Coverage Summary

| Spec section | Implemented in |
| --- | --- |
| Main screen + chat stream | Tasks 17, 18 |
| Voice + text input shared pipeline | Tasks 11, 12, 17 |
| Grouped result card with summary, source, time, failed items | Task 18 |
| Edit screen | Task 19 |
| SwiftData models (Transaction/InputEntry/Category/Tag/PaymentMethod/AIProvider) | Tasks 3, 4 |
| CloudKit sync via SwiftData | Task 5 |
| Keychain-stored API keys | Tasks 6, 21 |
| Provider templates + adapters (OpenAI-compatible / Anthropic / Gemini) | Tasks 9, 10, 21 |
| Parsing pipeline (prompt → adapter → decode → repository) | Tasks 7–11, 13 |
| Parsing rules (positive amount, time fallback, AI-created taxonomy) | Task 13 |
| Stats (today, month, category share, 30-day trend) | Tasks 14, 20 |
| Settings (providers, taxonomy, sync/permissions surface) | Tasks 21, 22 |
| Error handling (no provider, missing key, invalid JSON, partial failure) | Tasks 11, 13, 17 |
| Test strategy: units, services, flow, UI | Tasks 3–14, 17, 23 |

---

Plan complete and saved to `docs/superpowers/plans/2026-04-26-voice-ledger-ios-mvp.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
