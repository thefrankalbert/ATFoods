import Testing
import Foundation
@testable import Models

@Test func pricesFollowTheRestaurantCurrency() {
    #expect(Money.format(3800, currency: "XAF") == "3\u{202F}800\u{00A0}FCFA")
    #expect(Money.format(1_000_000, currency: "XAF") == "1\u{202F}000\u{202F}000\u{00A0}FCFA")
    #expect(Money.format(Decimal(string: "12.5")!, currency: "EUR") == "12,50\u{00A0}€")
    #expect(Money.format(15, currency: "EUR") == "15\u{00A0}€")
}

@Test func priceInputIsParsedPerCurrency() {
    #expect(Money.parse("3 800", currency: "XAF") == 3800)
    #expect(Money.parse("12,50", currency: "EUR") == Decimal(string: "12.5"))
    #expect(Money.parse("12.5", currency: "EUR") == Decimal(string: "12.5"))
    #expect(Money.parse("12,50", currency: "XAF") == nil)   // FCFA has no cents
    #expect(Money.parse("0", currency: "XAF") == nil)
    #expect(Money.parse("", currency: "XAF") == nil)
    #expect(Money.parse("12,5,0", currency: "EUR") == nil)
    #expect(Money.parse("abc", currency: "EUR") == nil)
}

@Test func priceFieldIsPrefilledCleanly() {
    // iOS 17 decodes JSON numbers via Double: 12.15 can arrive as 12.1499999999999999.
    let lossy = Decimal(string: "12.1499999999999999")!
    #expect(Money.inputText(lossy, currency: "EUR") == "12,15")
    #expect(Money.parse(Money.inputText(lossy, currency: "EUR"), currency: "EUR") == Decimal(string: "12.15"))
    #expect(Money.inputText(3800, currency: "XAF") == "3800")
    #expect(Money.inputText(Decimal(string: "3800.4")!, currency: "XAF") == "3800")
}

@Test func legacyPlanNamesMapToCurrentPlans() {
    #expect(AppPlan(fromDB: "premium") == .pro)
    #expect(AppPlan(fromDB: "business") == .business)
    #expect(AppPlan(fromDB: "unknown") == .starter)
}

@Test func menuOrderMatchesTheWebStorefront() {
    let (midi, soir, desserts, boissons) = (UUID(), UUID(), UUID(), UUID())
    // Soir first on the web (display_order 0), Desserts is a sub-carte of Soir, Boissons is transversal.
    let menus = [
        MenuOrder.MenuNode(id: midi, parentID: nil, displayOrder: 1, isTransversal: false),
        MenuOrder.MenuNode(id: boissons, parentID: nil, displayOrder: 0, isTransversal: true),
        MenuOrder.MenuNode(id: desserts, parentID: soir, displayOrder: 2, isTransversal: false),
        MenuOrder.MenuNode(id: soir, parentID: nil, displayOrder: 0, isTransversal: false),
    ]
    #expect(MenuOrder.menuIDs(menus) == [soir, desserts, midi, boissons])

    // Input is categories by display_order, as fetched.
    let jus = MenuCategory(name: "Jus", menuID: boissons)
    let entrees = MenuCategory(name: "Entrées", menuID: midi)
    let gateaux = MenuCategory(name: "Gâteaux", menuID: desserts)
    let grillades = MenuCategory(name: "Grillades", menuID: soir)
    let orpheline = MenuCategory(name: "Sans carte", menuID: nil)
    let sorted = MenuOrder.categories([jus, orpheline, entrees, gateaux, grillades], menus: menus)
    #expect(sorted.map(\.name) == ["Grillades", "Gâteaux", "Entrées", "Jus", "Sans carte"])

    // One carte only: the web keeps plain display_order.
    let single = [MenuOrder.MenuNode(id: midi, parentID: nil, displayOrder: 0, isTransversal: false)]
    #expect(MenuOrder.categories([orpheline, entrees], menus: single).map(\.name) == ["Sans carte", "Entrées"])

    // Dishes follow the category order, creation order kept inside a category.
    let a = MenuItem(name: "A", price: 1, category: "", categoryID: jus.id)
    let b = MenuItem(name: "B", price: 1, category: "", categoryID: grillades.id)
    let c = MenuItem(name: "C", price: 1, category: "", categoryID: grillades.id)
    #expect(MenuOrder.items([a, b, c], categories: sorted).map(\.name) == ["B", "C", "A"])
}
