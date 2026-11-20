import Testing
import Networking
@testable import ATFAuth

@MainActor @Test func wrongCredentialsShowFriendlyMessage() async {
    let store = AuthStore()
    store.email = "pas-un-email"
    store.password = ""
    await store.signIn(networking: MockNetworking())
    #expect(store.currentUser == nil)
    #expect(store.error == "Email ou mot de passe incorrect.")
}

@MainActor @Test func validLoginLoadsRestaurants() async {
    let store = AuthStore()
    store.email = "chef@resto.cm"
    store.password = String(repeating: "a", count: 8)   // any non-empty value passes the mock
    await store.signIn(networking: MockNetworking())
    #expect(store.currentUser != nil)
    #expect(!store.restaurants.isEmpty)
}

@MainActor @Test func googleLoginLoadsRestaurants() async {
    let store = AuthStore()
    await store.signInWithGoogle(networking: MockNetworking())
    #expect(store.currentUser != nil)
    #expect(!store.restaurants.isEmpty)
    #expect(store.pending == nil)
}
