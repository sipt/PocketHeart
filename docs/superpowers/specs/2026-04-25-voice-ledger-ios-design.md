# Voice Ledger iOS MVP Design

Date: 2026-04-25
Status: Approved for implementation planning

## Context

This project is a lightweight iOS bookkeeping app built around fast voice and text input. The MVP should prioritize accurate capture and low-friction correction over traditional accounting depth.

The current workspace is greenfield: there is no existing source project or Git history. This spec defines the first implementation target.

## Goals

- Let the user record multiple transactions from one voice or text input.
- Automatically identify amount, time, category, subcategory, tags, payment method, transaction type, and optional merchant or counterparty.
- Use a chat-style recording surface where each user input produces a grouped set of ledger cards.
- Save and sync ledger data through iCloud.
- Let users configure their own AI providers and switch between them.
- Keep the app lightweight: no account system, no custom backend, no tab-heavy navigation.

## Non-Goals

- No custom backend or hosted proxy.
- No account system.
- No family or shared ledgers.
- No transfer or asset-account tracking.
- No budgets, reminders, or AI monthly reports.
- No natural-language analytics queries in MVP.
- No image recognition in MVP, though the input model should leave room for images later.
- No confirmation-before-save flow. MVP saves automatically and supports correction afterward.

## Product Scope

The app has one main screen: the record stream. It behaves like a chat:

- The user sends text or voice.
- Voice is transcribed by iOS Speech.
- The resulting text is sent to the selected AI provider for structured parsing.
- The app saves valid transactions automatically.
- The app displays a grouped result card for that input.

The main screen toolbar has two secondary entries:

- Stats: today and month totals, category share, recent trend.
- Settings: provider configuration, category/tag/payment method management, iCloud status, speech and microphone permissions.

There are no bottom tabs in MVP.

## Main Interaction

### Input

The bottom input area supports:

- Text entry.
- Send button when text is non-empty.
- Voice button with two modes:
  - Tap to start or stop recording.
  - Press and hold for push-to-talk.
- Recording state with timer and clear cancel affordance.

Text input and voice input share the same parsing pipeline after transcription.

### Record Stream

The record stream shows messages in chat order, with the newest content near the bottom. For each user input, the app shows:

- The original user text or transcribed speech.
- A grouped AI result card.

Each grouped result card includes:

- Original input reference.
- Input source: text or voice.
- Parse timestamp.
- Summary such as "3 expenses, total CNY 325".
- Compact rows for each transaction.
- Failed parse items, if any.

Each transaction row shows:

- Amount.
- Title or item.
- Time.
- Category and subcategory.
- Tags.
- Payment method.
- Income or expense type.
- Optional merchant or counterparty.

Tapping a transaction opens the edit screen.

### Edit Screen

The edit screen supports editing:

- Amount.
- Currency.
- Income or expense type.
- Title or item.
- Optional merchant or counterparty.
- Occurrence time.
- Category and subcategory.
- Tags.
- Payment method.
- Notes.

Changes are saved back to the ledger and reflected in the grouped card and stats.

## Data Model

Use SwiftData models with CloudKit sync for ledger data. Sensitive AI credentials are stored in Keychain and are not synced through SwiftData.

### Transaction

Represents one ledger entry.

Fields:

- Stable ID.
- Amount as Decimal.
- Currency.
- Type: income or expense.
- Title or item.
- Optional merchant or counterparty.
- Occurred at Date.
- Category ID.
- Optional subcategory ID.
- Tag IDs.
- Payment method ID.
- Notes.
- Source input ID.
- AI-created flag.
- Created at Date.
- Updated at Date.

Rules:

- Amount must be positive.
- Currency defaults to the user's default currency.
- Time is stored as an absolute Date.
- Historical transactions reference stable category, tag, and payment method IDs.

### InputEntry

Represents one user input and its parse outcome.

Fields:

- Stable ID.
- Raw text.
- Source type: text or voice.
- Created at Date.
- Parse status: pending, success, partial failure, failure.
- AI provider ID used for parsing.
- Error message, if any.
- Linked transaction IDs.

### Category

Represents a category and optional child categories.

Fields:

- Stable ID.
- Name.
- Parent category ID, if it is a subcategory.
- Applicable type: expense, income, or both.
- Built-in flag.
- AI-created flag.
- Archived flag.

Rules:

- MVP ships with a built-in default category set.
- If AI returns a missing category or subcategory, the app may create it with `isAICreated = true`.
- Deleting should prefer archive or merge rather than breaking historical data.

### Tag

Fields:

- Stable ID.
- Name.
- Built-in flag.
- AI-created flag.
- Usage count.
- Archived flag.

AI may create new tags when the existing list is insufficient.

### PaymentMethod

Fields:

- Stable ID.
- Name.
- Type: WeChat Pay, Alipay, bank card, cash, Apple Pay, credit card, or other.
- Built-in flag.
- AI-created flag.
- Archived flag.

The app ships with common built-in payment methods. AI may create specific methods such as "CMB Credit Card" or "Company Meal Card".

### AIProvider

Stores non-sensitive provider configuration.

Fields:

- Stable ID.
- Display name.
- Template type.
- Base URL.
- Model name.
- Interface format.
- Default flag.
- Created at Date.
- Updated at Date.

API keys are stored in Keychain using the provider ID as the lookup key.

## AI Provider Design

MVP supports direct user-configured API calls from the app. The app does not provide a hosted backend or proxy.

Provider behavior:

- Users can create multiple providers.
- Users can switch the active default provider.
- The app supports an OpenAI-compatible generic provider.
- The app provides common templates to reduce setup friction, such as OpenAI, DeepSeek, Gemini, and Anthropic.
- Provider templates prefill known fields where possible, but calls go through a unified adapter interface.
- API keys live in Keychain.

Provider setup should make the responsibility clear: users bring their own API credentials and are responsible for provider cost, quota, and data handling.

## Parsing Pipeline

All inputs are normalized to text before parsing.

1. User submits text or voice.
2. If voice, iOS Speech transcribes audio to text.
3. The app creates an InputEntry with pending state.
4. The AI Parsing Service builds a structured request with:
   - Original text.
   - Current date and time zone.
   - Locale and default currency.
   - Existing categories and subcategories.
   - Existing tags.
   - Existing payment methods.
   - Expected JSON schema.
5. The selected provider returns structured JSON.
6. The app decodes and validates the JSON.
7. The Ledger Repository saves valid transactions and dynamically creates missing categories, tags, or payment methods.
8. The record stream displays the grouped result card.

The AI service does not write the database directly. Only the repository persists data.

## Parsing Rules

Required per transaction:

- Amount.
- Income or expense type.
- Title or item.
- Occurred-at time.
- Category.
- Payment method.

Optional:

- Subcategory.
- Tags.
- Merchant or counterparty.
- Notes.

Fallbacks:

- Missing amount: do not save that transaction; show it as a failed item in the group.
- Missing time: use current time.
- Relative time such as "yesterday", "last night", "this morning", "breakfast", "lunch", "dinner", or commute context should be resolved to an absolute Date.
- Missing or unknown category, tag, or payment method may create a new AI-created entry.

Normalization:

- Trim category, tag, and payment method names.
- Reuse existing names where possible.
- Avoid duplicate creations within one AI response.
- Keep amount positive and encode direction through income or expense type.

## Architecture

Use native SwiftUI with small feature and service boundaries.

### App Shell

Responsibilities:

- App entry.
- SwiftData container setup.
- CloudKit-backed persistence configuration.
- Environment injection.

### Recording Feature

Responsibilities:

- Record stream UI.
- Text input.
- Voice button state.
- Grouped result cards.
- Navigation to edit.
- Submission state and visible errors.

The feature talks to service protocols and repositories; it does not build prompts or decode provider JSON.

### Speech Service

Responsibilities:

- Microphone permission.
- Speech recognition permission.
- Start, stop, cancel recording.
- Transcription result delivery.
- Recording errors.

### AI Parsing Service

Responsibilities:

- Read active provider configuration.
- Build request payloads.
- Call provider adapters.
- Decode provider responses.
- Validate schema shape.
- Return `ParsedInputResult`.

It does not persist data.

### Ledger Repository

Responsibilities:

- Create InputEntry records.
- Save transactions.
- Reuse or create categories, tags, and payment methods.
- Edit transactions.
- Query record stream data.
- Produce stats aggregations.

### Settings Feature

Responsibilities:

- Provider list, create, edit, delete, and default selection.
- Keychain API key storage.
- Category, tag, and payment method management.
- iCloud and permission status.

### Stats Feature

Responsibilities:

- Today and month totals.
- Category share.
- Recent trend.
- Income and expense filters.

Stats uses local persisted ledger data and does not depend on AI.

### Provider Adapter

Responsibilities:

- Encapsulate provider-specific request and response details.
- Support OpenAI-compatible calls as the default generic path.
- Support templates through configuration, not duplicated parsing flows.

## Error Handling

- No active provider: block submission and show a settings call to action.
- Missing API key: block submission and show provider edit.
- Speech permission denied: allow text input and show permission guidance.
- Speech transcription failure: keep recording result out of ledger and show retry.
- API request failure: mark InputEntry failed and allow retry.
- Invalid JSON: mark InputEntry failed and keep raw input.
- Partial parse failure: save valid transactions and show failed items in the same group.
- iCloud unavailable: continue local operation and surface sync status in settings.

## Stats Scope

MVP stats include:

- Today's total spending.
- Current month total spending.
- Current month income total.
- Category share for the month.
- Recent 7-day or 30-day trend.

Budgets, reminders, AI summaries, and natural-language analytics are deferred.

## Testing Strategy

### Unit Tests

- Decimal amount validation.
- AI JSON decoding success and failure.
- One input creating multiple transactions.
- Reuse of existing categories, tags, and payment methods.
- AI-created category, tag, and payment method creation.
- Missing amount failure.
- Missing time fallback.
- Transaction edit updates persisted data.
- Stats update after creation and edit.

### Service Tests

- Provider configuration validation.
- Missing API key handling.
- Invalid Base URL handling.
- OpenAI-compatible request construction.
- Mock provider returns valid JSON.
- Mock provider returns invalid JSON.
- Mock provider returns partial success.
- Speech service protocol can be replaced with fake transcription in tests.

### UI and Flow Tests

- Text input creates grouped result card.
- Voice transcription enters the same parsing path as text.
- Tapping a transaction opens edit.
- Editing and saving updates the record stream.
- Provider missing state blocks submission.
- Stats view displays seeded ledger data.
- Settings can add and switch providers.

## Implementation Notes

- Prefer SwiftData + CloudKit sync for persisted app data.
- Keep API keys only in Keychain.
- Define service protocols early so UI can be tested with fakes.
- Keep prompt construction outside Views.
- Keep repository persistence outside AI parsing.
- Use stable IDs for all taxonomy entities.
- Archive or merge taxonomy entities instead of hard deleting when historical data references them.

