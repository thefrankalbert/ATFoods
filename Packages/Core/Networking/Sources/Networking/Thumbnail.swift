import Foundation

/// Small, server-resized copy of a Supabase Storage photo (image transformation endpoint).
/// A 56 pt list thumbnail weighs ~8 KB instead of ~250 KB for the full photo.
public enum Thumbnail {
    /// `points` is the on-screen side; pixels are requested at 3x. URLs outside Supabase Storage are returned unchanged.
    public static func url(_ url: URL?, points: Int) -> URL? {
        guard let url else { return nil }
        let full = url.absoluteString
        // Only real Storage objects: the marker must start the path, not merely appear in a query string.
        guard url.path.hasPrefix(objectPath), let range = full.range(of: objectPath),
              var parts = URLComponents(string: full.replacingCharacters(in: range, with: renderPath)) else {
            return url
        }
        let px = String(points * 3)
        parts.queryItems = (parts.queryItems ?? []) + [
            URLQueryItem(name: "width", value: px),
            URLQueryItem(name: "height", value: px),
            URLQueryItem(name: "resize", value: "cover"),
            URLQueryItem(name: "quality", value: "70"),
        ]
        return parts.url ?? url
    }

    private static let objectPath = "/storage/v1/object/public/"
    private static let renderPath = "/storage/v1/render/image/public/"
}
