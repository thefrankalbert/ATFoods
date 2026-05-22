import Foundation
import Models
import Networking

@MainActor @Observable public final class FormStore {
    public var name: String = ""
    public var priceText: String = ""
    public var category: MenuCategory = .plat
    public var isAvailable: Bool = true
    public var isLoading: Bool = false
    public var error: String? = nil
    public let restaurant: Restaurant
    public var photoURL: URL? = nil

    public init(restaurant: Restaurant, photoURL: URL? = nil) {
        self.restaurant = restaurant
        self.photoURL = photoURL
    }

    public var priceInCents: Int? {
        let digits = priceText.filter { $0.isNumber }
        return Int(digits)
    }

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && priceInCents != nil
    }

    public func submit(networking: any ATFNetworking) async {
        guard isValid, let price = priceInCents else { return }
        isLoading = true
        error = nil
        let item = MenuItem(
            name: name.trimmingCharacters(in: .whitespaces),
            price: price,
            category: category,
            photoURL: photoURL,
            isAvailable: isAvailable
        )
        do {
            _ = try await networking.createMenuItem(item, restaurantID: restaurant.id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
