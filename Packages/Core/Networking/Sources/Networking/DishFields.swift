import Foundation
import Models

/// Dish columns written by the app, same rules as the web admin (attabl-saas useItemForm.ts):
/// empty texts and no calories are stored as null, so clearing a field on the phone clears it on the web.
struct DishFields: Encodable {
    let item: MenuItem
    let categoryID: UUID
    var id: UUID? = nil
    var tenantID: UUID? = nil

    init(_ item: MenuItem, categoryID: UUID, id: UUID? = nil, tenantID: UUID? = nil) {
        self.item = item; self.categoryID = categoryID; self.id = id; self.tenantID = tenantID
    }

    private enum Key: String, CodingKey {
        case id, tenant_id, name, name_en, description, description_en, price
        case is_available, is_featured, allergens, calories, category_id
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encodeIfPresent(id?.uuidString, forKey: .id)
        try c.encodeIfPresent(tenantID?.uuidString, forKey: .tenant_id)
        try c.encode(item.name, forKey: .name)
        try c.encode(Self.nullIfEmpty(item.nameEn), forKey: .name_en)
        try c.encode(Self.nullIfEmpty(item.description), forKey: .description)
        try c.encode(Self.nullIfEmpty(item.descriptionEn), forKey: .description_en)
        try c.encode(item.price, forKey: .price)
        try c.encode(item.isAvailable, forKey: .is_available)
        try c.encode(item.isFeatured, forKey: .is_featured)
        try c.encode(item.allergens, forKey: .allergens)
        try c.encode(item.calories, forKey: .calories)   // Optional encodes as null
        try c.encode(categoryID.uuidString, forKey: .category_id)
    }

    static func nullIfEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
