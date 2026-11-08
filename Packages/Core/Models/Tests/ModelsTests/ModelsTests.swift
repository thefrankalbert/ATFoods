import Testing
@testable import Models

@Test func priceFormattingUsesThousandsSeparator() {
    #expect(MenuItem(name: "a", price: 800).priceFormatted == "800 FCFA")
    #expect(MenuItem(name: "a", price: 3000).priceFormatted == "3 000 FCFA")
    #expect(MenuItem(name: "a", price: 3850).priceFormatted == "3 850 FCFA")
    #expect(MenuItem(name: "a", price: 12050).priceFormatted == "12 050 FCFA")
}

@Test func legacyPlanNamesMapToCurrentPlans() {
    #expect(AppPlan(fromDB: "premium") == .pro)
    #expect(AppPlan(fromDB: "business") == .business)
    #expect(AppPlan(fromDB: "unknown") == .starter)
}
