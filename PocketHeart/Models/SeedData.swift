import Foundation

enum SeedLanguage {
    case en, zh

    static func from(_ locale: Locale) -> SeedLanguage {
        locale.language.languageCode?.identifier == "zh" ? .zh : .en
    }
}

enum SeedData {
    struct CategorySeed {
        let nameEN: String
        let nameZH: String
        let iconKey: String
        let applicable: ApplicableType
        let children: [CategorySeed]

        func name(for lang: SeedLanguage) -> String {
            lang == .zh ? nameZH : nameEN
        }
    }

    struct TagSeed {
        let nameEN: String
        let nameZH: String
        func name(for lang: SeedLanguage) -> String { lang == .zh ? nameZH : nameEN }
    }

    struct PaymentSeed {
        let nameEN: String
        let nameZH: String
        let kind: PaymentKind
        func name(for lang: SeedLanguage) -> String { lang == .zh ? nameZH : nameEN }
    }

    static let categories: [CategorySeed] = [
        .init(nameEN: "Food", nameZH: "餐饮", iconKey: "food", applicable: .expense, children: [
            .init(nameEN: "Breakfast", nameZH: "早餐", iconKey: "food", applicable: .expense, children: []),
            .init(nameEN: "Lunch",     nameZH: "午餐", iconKey: "food", applicable: .expense, children: []),
            .init(nameEN: "Dinner",    nameZH: "晚餐", iconKey: "food", applicable: .expense, children: []),
            .init(nameEN: "Coffee",    nameZH: "咖啡", iconKey: "coffee", applicable: .expense, children: []),
            .init(nameEN: "Snacks",    nameZH: "零食", iconKey: "food", applicable: .expense, children: []),
            .init(nameEN: "Delivery",  nameZH: "外卖", iconKey: "food", applicable: .expense, children: []),
        ]),
        .init(nameEN: "Transit", nameZH: "交通", iconKey: "transit", applicable: .expense, children: [
            .init(nameEN: "Subway", nameZH: "地铁", iconKey: "transit", applicable: .expense, children: []),
            .init(nameEN: "Taxi",   nameZH: "打车", iconKey: "transit", applicable: .expense, children: []),
            .init(nameEN: "Bus",    nameZH: "公交", iconKey: "transit", applicable: .expense, children: []),
            .init(nameEN: "Fuel",   nameZH: "加油", iconKey: "transit", applicable: .expense, children: []),
        ]),
        .init(nameEN: "Shopping", nameZH: "购物", iconKey: "other", applicable: .expense, children: [
            .init(nameEN: "Grocery",     nameZH: "日用",   iconKey: "grocery", applicable: .expense, children: []),
            .init(nameEN: "Clothing",    nameZH: "服饰",   iconKey: "other", applicable: .expense, children: []),
            .init(nameEN: "Electronics", nameZH: "数码",   iconKey: "other", applicable: .expense, children: []),
        ]),
        .init(nameEN: "Housing", nameZH: "居家", iconKey: "other", applicable: .expense, children: [
            .init(nameEN: "Rent",      nameZH: "房租",   iconKey: "other", applicable: .expense, children: []),
            .init(nameEN: "Utilities", nameZH: "水电",   iconKey: "other", applicable: .expense, children: []),
        ]),
        .init(nameEN: "Income", nameZH: "收入", iconKey: "salary", applicable: .income, children: [
            .init(nameEN: "Salary", nameZH: "工资",  iconKey: "salary", applicable: .income, children: []),
            .init(nameEN: "Bonus",  nameZH: "奖金",  iconKey: "salary", applicable: .income, children: []),
            .init(nameEN: "Refund", nameZH: "退款",  iconKey: "salary", applicable: .income, children: []),
        ]),
        .init(nameEN: "Other", nameZH: "其他", iconKey: "other", applicable: .both, children: []),
    ]

    static let tags: [TagSeed] = [
        .init(nameEN: "work",       nameZH: "工作"),
        .init(nameEN: "lunch",      nameZH: "午餐"),
        .init(nameEN: "team",       nameZH: "团建"),
        .init(nameEN: "late",       nameZH: "晚归"),
        .init(nameEN: "afternoon",  nameZH: "下午茶"),
        .init(nameEN: "groceries",  nameZH: "采买"),
    ]

    static let paymentMethods: [PaymentSeed] = [
        .init(nameEN: "WeChat Pay",  nameZH: "微信支付", kind: .wechat),
        .init(nameEN: "Alipay",      nameZH: "支付宝",   kind: .alipay),
        .init(nameEN: "Cash",        nameZH: "现金",     kind: .cash),
        .init(nameEN: "Apple Pay",   nameZH: "Apple Pay", kind: .applePay),
        .init(nameEN: "Bank Card",   nameZH: "银行卡",   kind: .bank),
        .init(nameEN: "Credit Card", nameZH: "信用卡",   kind: .creditCard),
    ]
}
