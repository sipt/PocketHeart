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
