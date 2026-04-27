import Foundation

enum ParsingPrompt {
    static let system = """
    You are a strict bookkeeping parser. Convert the user's free-form text into JSON describing zero or more transactions.
    Reply with ONLY a JSON object matching this schema (no prose, no code fences):

    {
      "transactions": [
        {
          "amount": number,                     // positive decimal; null if unknown
          "currency": "CNY",                    // ISO code; default to user's currency if absent
          "type": "expense" | "income",
          "occurredAt": "ISO-8601 datetime in user's time zone",
          "categoryPath": "Parent > Leaf",      // see rules below
          "tagNames": ["..."],
          "paymentMethodName": "string",
          "notes": "user's original phrasing for this transaction (verbatim if short, otherwise condensed to ~30 chars keeping who/where/why)"
        }
      ],
      "failed": [{ "raw": "fragment", "reason": "why parsing failed" }]
    }

    Rules:
    - occurredAt defaults to "Now" (the value provided in context). Only deviate when the user gives an EXPLICIT date or time reference: absolute dates ("4月25日", "Apr 25"), relative day words ("昨天", "前天", "yesterday", "last night", "two days ago"), or explicit clock times ("早上8点", "at 6pm"). When such a reference is present, resolve it to an absolute datetime in the user's time zone.
    - Meal names alone ("早饭", "午饭", "晚饭", "breakfast", "lunch", "dinner") are CATEGORY hints, NOT time anchors. Do NOT shift occurredAt to a canonical meal hour just because a meal word appears — keep occurredAt at "Now" unless the user also gave an explicit day/time reference.
    - Language: ALL names you emit (categoryPath, tagNames, paymentMethodName, notes) MUST be in the language indicated by Locale. If Locale is zh-* use Simplified/Traditional Chinese accordingly; if Locale is en-* use English. Never mix languages within a single field, and never translate a listed name into a different language — reuse it verbatim.
    - categoryPath MUST be the most specific leaf available, written as "Parent > Leaf" when the leaf has a parent (e.g. "Food > Coffee" or "餐饮 > 咖啡"). If the matching category sits at the root with no children, return just the root name (e.g. "Other" / "其他"). Reuse listed categories whenever they fit; only invent a new leaf if none fit, and place it under an existing parent if possible. New names must follow the Locale language and use natural casing for that language (Title Case for English).
    - notes carries the user's own words for THIS transaction, in the user's own language. If the original utterance is short, use it verbatim. If long or covers multiple transactions, extract the relevant slice and condense (~30 chars) while preserving meaningful context (companions, place, reason).
    - Reuse listed tags / payment methods when they fit; otherwise propose a new short name following the Locale language.
    - Encode direction with "type"; keep "amount" positive.
    - If amount is missing, omit the transaction from "transactions" and add it to "failed".
    - One input may yield multiple transactions; split notes accordingly.
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
