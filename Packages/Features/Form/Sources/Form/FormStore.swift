import Foundation
import Models
import Networking
import UIKit

/// Where the new dish's photo comes from.
public enum DishPhotoSource {
    case captured(UIImage)
    case draft(Draft)
}

/// Create a dish (from a photo) or edit an existing one (name, price, availability, category).
@MainActor @Observable public final class FormStore {
    public var name: String = ""
    public var priceText: String = ""
    public var categories: [MenuCategory] = []
    public var menus: [MenuRef] = []
    public var selectedCategoryID: UUID? = nil
    public var isAvailable: Bool = true
    // Rest of the web dish sheet (attabl-saas useItemForm.ts).
    public var descriptionText: String = ""
    public var nameEn: String = ""
    public var descriptionEn: String = ""
    public var isFeatured: Bool = false
    public var allergens: Set<String> = []
    public var caloriesText: String = ""
    public private(set) var gallery: [URL] = []
    public private(set) var isUpdatingGallery = false
    public var isLoading: Bool = false
    public var isLoadingCategories: Bool = false
    public var error: String? = nil
    public let restaurant: Restaurant
    public var photo: DishPhotoSource?
    /// Set in edit mode: the dish being modified (its photo is shown and can be replaced).
    public private(set) var editing: MenuItem?
    /// Menus must be known before creating a category (multi-menu tenants need a menu_id).
    public private(set) var menusLoaded: Bool = false
    /// Set once the dish row exists, so a retry after a failed photo upload doesn't create a duplicate.
    private var createdItem: MenuItem? = nil

    public init(restaurant: Restaurant, photo: DishPhotoSource? = nil) {
        self.restaurant = restaurant
        self.photo = photo
    }

    public init(restaurant: Restaurant, editing item: MenuItem) {
        self.restaurant = restaurant
        self.editing = item
        name = item.name
        priceText = Money.inputText(item.price, currency: restaurant.currency)
        isAvailable = item.isAvailable
        selectedCategoryID = item.categoryID
        descriptionText = item.description
        nameEn = item.nameEn
        descriptionEn = item.descriptionEn
        isFeatured = item.isFeatured
        allergens = Set(item.allergens)
        caloriesText = item.calories.map(String.init) ?? ""
        gallery = item.gallery
    }

    /// Calories: empty = none; otherwise a whole number of kcal.
    public var calories: Int? { Int(caloriesText.trimmingCharacters(in: .whitespaces)) }
    public var caloriesError: String? {
        let t = caloriesText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        guard let n = Int(t), n >= 0 else { return "Nombre entier de kcal (ex. 450)." }
        return n > 10_000 ? "Valeur trop élevée." : nil
    }

    /// Same order as the web list, so saving never reshuffles what the web stored.
    private var orderedAllergens: [String] { Allergen.all.map(\.id).filter(allergens.contains) }

    private func applyDetails(to item: inout MenuItem) {
        let trim = { (t: String) in t.trimmingCharacters(in: .whitespacesAndNewlines) }
        item.description = trim(descriptionText)
        item.nameEn = trim(nameEn)
        item.descriptionEn = trim(descriptionEn)
        item.isFeatured = isFeatured
        item.allergens = orderedAllergens
        item.calories = calories
    }

    public var isEditing: Bool { editing != nil }

    /// Edit mode: unsaved changes (Back asks before discarding them).
    public var hasUnsavedChanges: Bool {
        guard let item = editing else { return false }
        return name.trimmingCharacters(in: .whitespaces) != item.name
            || price != item.price.roundedForCurrency(restaurant.currency)
            || isAvailable != item.isAvailable
            || selectedCategoryID != item.categoryID
            || descriptionText.trimmingCharacters(in: .whitespacesAndNewlines) != item.description
            || nameEn.trimmingCharacters(in: .whitespacesAndNewlines) != item.nameEn
            || descriptionEn.trimmingCharacters(in: .whitespacesAndNewlines) != item.descriptionEn
            || isFeatured != item.isFeatured
            || allergens != Set(item.allergens)
            || calories != item.calories
    }
    /// Extra photos (edit mode only: the dish must exist). Saved immediately, like the main photo.
    public func addGalleryPhoto(_ data: Data, networking: any ATFNetworking) async {
        guard let item = editing, !isUpdatingGallery else { return }
        isUpdatingGallery = true
        defer { isUpdatingGallery = false }
        do {
            gallery = try await networking.addGalleryPhoto(imageData: data, toDishID: item.id, restaurantID: restaurant.id)
            editing?.gallery = gallery
            error = nil
        } catch {
            self.error = "Photo non ajoutée. \(UserMessage.from(error))"
        }
    }

    public func removeGalleryPhoto(_ url: URL, networking: any ATFNetworking) async {
        guard let item = editing, !isUpdatingGallery else { return }
        isUpdatingGallery = true
        defer { isUpdatingGallery = false }
        do {
            gallery = try await networking.removeGalleryPhoto(url, fromDishID: item.id, restaurantID: restaurant.id)
            editing?.gallery = gallery
            error = nil
        } catch {
            self.error = "Photo non retirée. \(UserMessage.from(error))"
        }
    }

    public var currencySymbol: String { Money.symbol(restaurant.currency) }
    public var allowsDecimals: Bool { Money.fractionDigits(restaurant.currency) > 0 }

    /// Called after the photo of the edited dish was replaced from the camera.
    public func photoReplaced(with url: URL) {
        editing?.photoURL = url
    }

    public func loadCategories(networking: any ATFNetworking) async {
        guard !menusLoaded, !isLoadingCategories else { return }
        isLoadingCategories = true
        defer { isLoadingCategories = false }
        do {
            async let cats = networking.fetchCategories(restaurantID: restaurant.id)
            async let menuList = networking.fetchMenus(restaurantID: restaurant.id)
            categories = try await cats
            menus = try await menuList
            menusLoaded = true
            error = nil
            if selectedCategoryID == nil { selectedCategoryID = categories.first?.id }
        } catch {
            self.error = UserMessage.from(error)
        }
    }

    /// Chip label; adds the menu name when two categories share a name (e.g. "Entrées" in Midi and Soir).
    public func label(for category: MenuCategory) -> String {
        let duplicated = categories.filter { $0.name == category.name }.count > 1
        guard duplicated, let menu = menus.first(where: { $0.id == category.menuID }) else { return category.name }
        return "\(category.name) · \(menu.name)"
    }

    public func createCategory(name: String, menuID: UUID?, networking: any ATFNetworking) async throws {
        let created = try await networking.createCategory(name: name, menuID: menuID, restaurantID: restaurant.id)
        categories.append(created)
        selectedCategoryID = created.id
    }

    /// After creation only the photo can be retried: edits would be silently lost, so fields lock.
    public var isDishCreated: Bool { createdItem != nil }

    public var price: Decimal? { Money.parse(priceText, currency: restaurant.currency) }

    public var priceError: String? {
        guard !priceText.trimmingCharacters(in: .whitespaces).isEmpty, price == nil else { return nil }
        return allowsDecimals ? "Prix invalide (ex. 12,50)." : "Prix invalide : nombre entier, sans centimes."
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && price != nil && selectedCategoryID != nil
            && caloriesError == nil
    }

    /// Shown above a disabled save button: says exactly what is missing, instead of a grey button with no reason.
    public var missingFieldsHint: String? {
        guard !isValid, !isDishCreated else { return nil }
        var missing: [String] = []
        if name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("un nom") }
        if price == nil { missing.append(priceText.trimmingCharacters(in: .whitespaces).isEmpty ? "un prix" : "un prix valide") }
        if selectedCategoryID == nil { missing.append("une catégorie") }
        if caloriesError != nil { missing.append("des calories valides") }
        guard let last = missing.popLast() else { return nil }
        let list = missing.isEmpty ? last : missing.joined(separator: ", ") + " et " + last
        return "Ajoutez \(list) pour enregistrer."
    }

    public func submit(networking: any ATFNetworking) async {
        guard isValid, let price, let categoryID = selectedCategoryID else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let categoryName = categories.first { $0.id == categoryID }?.name ?? ""

        if var item = editing {
            item.name = trimmedName
            item.price = price
            item.isAvailable = isAvailable
            item.categoryID = categoryID
            item.category = categoryName
            applyDetails(to: &item)
            do {
                editing = try await networking.updateMenuItem(item, restaurantID: restaurant.id)
            } catch {
                self.error = UserMessage.from(error)
            }
            return
        }

        let item: MenuItem
        if let createdItem {
            item = createdItem
        } else {
            do {
                var newItem = MenuItem(
                    name: trimmedName,
                    price: price,
                    category: categoryName,
                    categoryID: categoryID,
                    isAvailable: isAvailable
                )
                applyDetails(to: &newItem)
                item = try await networking.createMenuItem(newItem, categoryID: categoryID, restaurantID: restaurant.id)
                createdItem = item
            } catch {
                self.error = UserMessage.from(error)
                return
            }
        }

        do {
            switch photo {
            case .captured(let image):
                guard let data = await image.uploadJPEG() else {
                    self.error = "Photo illisible. Le plat est créé : reprenez la photo depuis sa fiche."
                    return
                }
                _ = try await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: restaurant.id)
            case .draft(let draft):
                _ = try await networking.attachDraft(draft, toDishID: item.id, restaurantID: restaurant.id)
            case nil:
                break
            }
        } catch {
            self.error = "Plat créé, mais la photo n'a pas pu être envoyée. \(UserMessage.from(error))"
        }
    }
}

private extension Decimal {
    func roundedForCurrency(_ currency: String) -> Decimal? {
        Money.parse(Money.inputText(self, currency: currency), currency: currency)
    }
}
