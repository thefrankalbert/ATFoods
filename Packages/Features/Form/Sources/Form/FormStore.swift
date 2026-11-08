import Foundation
import Models
import Networking
import UIKit

/// Where the new dish's photo comes from.
public enum DishPhotoSource {
    case captured(UIImage)
    case draft(Draft)
}

@MainActor @Observable public final class FormStore {
    public var name: String = ""
    public var priceText: String = ""
    public var categories: [MenuCategory] = []
    public var menus: [MenuRef] = []
    public var selectedCategoryID: UUID? = nil
    public var isAvailable: Bool = true
    public var isLoading: Bool = false
    public var isLoadingCategories: Bool = false
    /// Menus must be known before creating a category (multi-menu tenants need a menu_id).
    public private(set) var menusLoaded: Bool = false
    public var error: String? = nil
    public let restaurant: Restaurant
    public let photo: DishPhotoSource?
    /// Set once the dish row exists, so a retry after a failed photo upload doesn't create a duplicate.
    private var createdItem: MenuItem? = nil

    public init(restaurant: Restaurant, photo: DishPhotoSource? = nil) {
        self.restaurant = restaurant
        self.photo = photo
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
            self.error = "Catégories : \(error.localizedDescription)"
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

    public var price: Int? {
        let digits = priceText.filter { $0.isNumber }
        return Int(digits)
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && price != nil && selectedCategoryID != nil
    }

    public func submit(networking: any ATFNetworking) async {
        guard isValid, let price, let categoryID = selectedCategoryID else { return }
        isLoading = true
        defer { isLoading = false }
        error = nil

        let item: MenuItem
        if let createdItem {
            item = createdItem
        } else {
            do {
                item = try await networking.createMenuItem(MenuItem(
                    name: name.trimmingCharacters(in: .whitespaces),
                    price: price,
                    category: categories.first { $0.id == categoryID }?.name ?? "",
                    categoryID: categoryID,
                    isAvailable: isAvailable
                ), categoryID: categoryID, restaurantID: restaurant.id)
                createdItem = item
            } catch {
                self.error = "Création plat : \(error.localizedDescription)"
                return
            }
        }

        do {
            switch photo {
            case .captured(let image):
                guard let data = image.uploadJPEG() else {
                    self.error = "Photo invalide. Le plat est créé, reprends la photo."
                    return
                }
                _ = try await networking.attachPhoto(imageData: data, toDishID: item.id, restaurantID: restaurant.id)
            case .draft(let draft):
                _ = try await networking.attachDraft(draft, toDishID: item.id, restaurantID: restaurant.id)
            case nil:
                break
            }
        } catch {
            self.error = "Plat créé, mais la photo n'a pas pu être envoyée : \(error.localizedDescription). Réessaie."
        }
    }
}
