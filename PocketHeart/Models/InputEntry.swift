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
