import Foundation
import Supabase

/// Errors whose `errorDescription` is already a French, user-facing sentence.
public protocol UserFacingError: LocalizedError {}

/// Turns any error into a short French sentence for the UI. Raw (often English) SDK messages never reach the user.
public enum UserMessage {
    public static func from(_ error: Error) -> String {
        if let error = error as? UserFacingError, let text = error.errorDescription { return text }
        if isOffline(error) {
            return "Pas de connexion internet. Vérifiez votre réseau et réessayez."
        }
        if let auth = error as? AuthError {
            switch auth.errorCode {
            case .invalidCredentials: return "Email ou mot de passe incorrect."
            case .sessionNotFound, .sessionExpired, .refreshTokenNotFound:
                return "Votre session a expiré. Reconnectez-vous."
            default: return "Connexion impossible. Réessayez."
            }
        }
        if let pg = error as? PostgrestError {
            switch pg.code {
            case "42501": return "Action refusée : vos droits sur ce restaurant ne le permettent pas."
            case "23505": return "Cet élément existe déjà."
            case "23503": return "Élément introuvable : il a peut-être été supprimé depuis le site."
            default: break
            }
        }
        if let storage = error as? StorageError {
            switch storage.statusCode {
            case "403": return "Envoi refusé : vos droits sur ce restaurant ne le permettent pas."
            case "413": return "Photo trop lourde."
            default: break
            }
        }
        return "Une erreur est survenue. Réessayez."
    }

    public static func isOffline(_ error: Error) -> Bool {
        guard let url = error as? URLError else { return false }
        return [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
                .cannotConnectToHost, .dataNotAllowed, .internationalRoamingOff].contains(url.code)
    }
}
