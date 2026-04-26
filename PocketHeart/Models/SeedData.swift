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
