import Foundation
import Models

/// Dish columns written by the app, same rules as the web admin (attabl-saas useItemForm.ts):
/// empty texts and no calories are stored as null, so clearing a field on the phone clears it on the web.
struct DishFields: Encodable {
    let item: MenuItem
    let categoryID: UUID
    var id: UUID? = nil
    var tenantID: UUID? = nil
    /// Update only: the dish as loaded. Unchanged fields are left out of the payload.
    var original: MenuItem? = nil

    init(_ item: MenuItem, categoryID: UUID, id: UUID? = nil, tenantID: UUID? = nil) {
        self.item = item; self.categoryID = categoryID; self.id = id; self.tenantID = tenantID
    }

    private enum Key: String, CodingKey {
        case id, tenant_id, name, name_en, description, description_en, price
        case is_available, is_featured, allergens, calories, category_id
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        let o = original
        try c.encodeIfPresent(id?.uuidString, forKey: .id)
        try c.encodeIfPresent(tenantID?.uuidString, forKey: .tenant_id)
        if o?.name != item.name { try c.encode(item.name, forKey: .name) }
        if o.map({ Self.nullIfEmpty($0.nameEn) }) != .some(Self.nullIfEmpty(item.nameEn)) { try c.encode(Self.nullIfEmpty(item.nameEn), forKey: .name_en) }
        if o.map({ Self.nullIfEmpty($0.description) }) != .some(Self.nullIfEmpty(item.description)) { try c.encode(Self.nullIfEmpty(item.description), forKey: .description) }
        if o.map({ Self.nullIfEmpty($0.descriptionEn) }) != .some(Self.nullIfEmpty(item.descriptionEn)) { try c.encode(Self.nullIfEmpty(item.descriptionEn), forKey: .description_en) }
        if o?.price != item.price { try c.encode(item.price, forKey: .price) }
        if o?.isAvailable != item.isAvailable { try c.encode(item.isAvailable, forKey: .is_available) }
        if o?.isFeatured != item.isFeatured { try c.encode(item.isFeatured, forKey: .is_featured) }
        if o?.allergens != item.allergens { try c.encode(item.allergens, forKey: .allergens) }
        if o.map(\.calories) != .some(item.calories) { try c.encode(item.calories, forKey: .calories) }   // Optional encodes as null
        if o?.categoryID != categoryID { try c.encode(categoryID.uuidString, forKey: .category_id) }
    }

    /// Nothing differs from `original`: no request needed.
    var isEmpty: Bool {
        guard original != nil, let data = try? JSONEncoder().encode(self) else { return false }
        return ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?.isEmpty ?? false
    }

    static func nullIfEmpty(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
