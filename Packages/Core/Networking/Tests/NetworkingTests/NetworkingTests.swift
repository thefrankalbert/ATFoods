import Testing
import Foundation
@testable import Networking

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
    // Empty gallery stays empty (storefront falls back to image_url).
    #expect(SupabaseNetworking.gallery([], replacing: "a", with: "n") == [])
}

@Test func errorsAreShownInFrench() {
    #expect(UserMessage.from(URLError(.notConnectedToInternet)).hasPrefix("Pas de connexion internet"))
    #expect(UserMessage.from(SupabaseNetworkingError.notAllowed).hasPrefix("Modification refusée"))
    struct Raw: Error {}
    #expect(UserMessage.from(Raw()) == "Une erreur est survenue. Réessayez.")
}
