import Foundation

/// Pages of the web SaaS the app links to (all verified to exist in attabl-saas).
/// No marketing / pricing pages: App Store rule 3.1.1 forbids steering to outside purchases.
public enum AttablWeb {
    public static let forgotPassword = URL(string: "https://attabl.com/forgot-password")!
    public static let dashboard = URL(string: "https://attabl.com/login")!
    public static let support = URL(string: "https://attabl.com/support")!
    public static let legal = URL(string: "https://attabl.com/legal")!
    public static let privacy = URL(string: "https://attabl.com/privacy")!
    public static let supportEmail = "support@attabl.com"

    public static func mail(subject: String, body: String = "") -> URL {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = supportEmail
        c.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return c.url!
    }
}
