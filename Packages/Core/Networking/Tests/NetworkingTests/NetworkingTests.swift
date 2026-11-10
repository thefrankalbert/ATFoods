import Testing
import Foundation
@testable import Networking
import Models

private let base = "https://x.supabase.co/storage/v1/object/public/menu-items/"
private let newPath = "tenant/dish-2.jpg"

@Test func oldPhotoInOurBucketIsResolvedToItsPath() {
    let path = SupabaseNetworking.storagePath(fromPublicURL: base + "tenant/dish-1.jpg", newURL: base + newPath, newPath: newPath)
    #expect(path == "tenant/dish-1.jpg")
}

@Test func externalOrForeignPhotosAreNeverDeleted() {
    #expect(SupabaseNetworking.storagePath(fromPublicURL: "https://images.unsplash.com/p.jpg", newURL: base + newPath, newPath: newPath) == nil)
    let otherBucket = "https://x.supabase.co/storage/v1/object/public/logos/tenant/logo.png"
    #expect(SupabaseNetworking.storagePath(fromPublicURL: otherBucket, newURL: base + newPath, newPath: newPath) == nil)
    #expect(SupabaseNetworking.storagePath(fromPublicURL: base, newURL: base + newPath, newPath: newPath) == nil)
}

@Test func percentEncodedPathsAreDecoded() {
    let path = SupabaseNetworking.storagePath(fromPublicURL: base + "tenant/mon%20plat.jpg", newURL: base + newPath, newPath: newPath)
    #expect(path == "tenant/mon plat.jpg")
}

@Test func galleryKeepsStorefrontInSync() {
    // Previous primary replaced in place: the storefront detail sheet shows the new photo, extras kept.
    #expect(SupabaseNetworking.gallery(["a", "b"], replacing: "a", with: "n") == ["n", "b"])
    // Previous photo not in the gallery: the new one goes first.
    #expect(SupabaseNetworking.gallery(["b"], replacing: "a", with: "n") == ["n", "b"])
    // Web rule: the main photo is always first in images, even with no extra photo.
    #expect(SupabaseNetworking.gallery([], replacing: "a", with: "n") == ["n"])
    #expect(SupabaseNetworking.gallery(["a", "b", "b"], replacing: "a", with: "n") == ["n", "b"])
}

@Test func thumbnailsUseTheResizeEndpointOnlyForOurStorage() {
    let ours = URL(string: base + "tenant/mon%20plat.jpg")!
    let thumb = Thumbnail.url(ours, points: 56)!.absoluteString
    #expect(thumb.hasPrefix("https://x.supabase.co/storage/v1/render/image/public/menu-items/tenant/mon%20plat.jpg?"))
    #expect(thumb.contains("width=168") && thumb.contains("height=168") && thumb.contains("resize=cover"))
    let external = URL(string: "https://images.unsplash.com/p.jpg?w=400")!
    #expect(Thumbnail.url(external, points: 56) == external)
    #expect(Thumbnail.url(nil, points: 56) == nil)
}

@Test func errorsAreShownInFrench() {
    #expect(UserMessage.from(URLError(.notConnectedToInternet)).hasPrefix("Pas de connexion internet"))
    #expect(UserMessage.from(SupabaseNetworkingError.notAllowed).hasPrefix("Modification refusée"))
    struct Raw: Error {}
    #expect(UserMessage.from(Raw()) == "Une erreur est survenue. Réessayez.")
}

@Test func dishFieldsMatchTheWebSheet() throws {
    var item = MenuItem(name: "Ndolé", price: 4500, description: "  ", createdAt: Date())
    item.allergens = ["fish", "peanuts"]
    item.isFeatured = true
    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(DishFields(item, categoryID: UUID()))) as! [String: Any]
    // Cleared on the phone = cleared on the web (null, like attabl-saas useItemForm.ts), never left as before.
    #expect(json["description"] is NSNull)
    #expect(json["name_en"] is NSNull)
    #expect(json["calories"] is NSNull)
    #expect(json["allergens"] as? [String] == ["fish", "peanuts"])
    #expect(json["is_featured"] as? Bool == true)
    #expect(json["id"] == nil && json["tenant_id"] == nil)   // update never rewrites ownership
}
