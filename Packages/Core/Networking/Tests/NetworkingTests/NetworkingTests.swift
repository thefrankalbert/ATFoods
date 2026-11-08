import Testing
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
