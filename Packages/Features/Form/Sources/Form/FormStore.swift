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
    }

    public var isEditing: Bool { editing != nil }

    /// Edit mode: unsaved changes (Back asks before discarding them).
    public var hasUnsavedChanges: Bool {
        guard let item = editing else { return false }
        return name.trimmingCharacters(in: .whitespaces) != item.name
            || price != item.price.roundedForCurrency(restaurant.currency)
            || isAvailable != item.isAvailable
            || selectedCategoryID != item.categoryID
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
                item = try await networking.createMenuItem(MenuItem(
                    name: trimmedName,
                    price: price,
                    category: categoryName,
                    categoryID: categoryID,
                    isAvailable: isAvailable
                ), categoryID: categoryID, restaurantID: restaurant.id)
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
