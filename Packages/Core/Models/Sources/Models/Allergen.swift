import Foundation

/// The 14 EU allergens, same ids and French labels as the web (attabl-saas src/lib/config/allergens.ts).
public enum Allergen {
    public static let all: [(id: String, label: String)] = [
        ("gluten", "Gluten"), ("crustaceans", "Crustacés"), ("eggs", "Œufs"), ("fish", "Poisson"),
        ("peanuts", "Arachides"), ("soybeans", "Soja"), ("milk", "Lait"), ("tree_nuts", "Fruits à coque"),
        ("celery", "Céleri"), ("mustard", "Moutarde"), ("sesame", "Sésame"), ("sulphites", "Sulfites"),
        ("lupin", "Lupin"), ("molluscs", "Mollusques"),
    ]
}
