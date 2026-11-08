import Foundation

enum Env {
    // À Table SaaS — même Supabase que le dashboard web
    static let supabaseURL = URL(string: "https://nqufpobuozrzwpeijkxt.supabase.co")!
    static let supabaseAnonKey = "sb_publishable_fQdI_8_7tppUUK0wiiIspQ_fj1M7Iux"
    static var isUITesting: Bool { ProcessInfo.processInfo.arguments.contains("UI_TESTING") }
}
