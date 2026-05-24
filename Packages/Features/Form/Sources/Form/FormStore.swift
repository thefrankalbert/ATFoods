import Foundation
import Models
import Networking
import UIKit

@MainActor @Observable public final class FormStore {
    public var name: String = ""
    public var priceText: String = ""
    public var category: String = "Plat"
    public var categories: [String] = []
    public var isAvailable: Bool = true
    public var isLoading: Bool = false
    public var error: String? = nil
    public let restaurant: Restaurant
    public var capturedImage: UIImage? = nil
    public var photoURL: URL? = nil

    public init(restaurant: Restaurant, capturedImage: UIImage? = nil) {
        self.restaurant = restaurant
        self.capturedImage = capturedImage
    }

    public func loadCategories(networking: any ATFNetworking) async {
        guard categories.isEmpty else { return }
        categories = (try? await networking.fetchCategories(restaurantID: restaurant.id)) ?? []
        if categories.isEmpty {
            categories = ["Plat", "Entrée", "Grillades", "Spécialité", "Boisson", "Dessert"]
        }
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
        var item = MenuItem(
            name: name.trimmingCharacters(in: .whitespaces),
            price: price,
            category: category,
            photoURL: photoURL,
            isAvailable: isAvailable
        )
        do {
            item = try await networking.createMenuItem(item, restaurantID: restaurant.id)
            if let image = capturedImage,
               let data = image.jpegData(compressionQuality: 0.85) {
                let url = try await networking.attachPhoto(
                    imageData: data,
                    toDishID: item.id,
                    restaurantID: restaurant.id
                )
                photoURL = url
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
