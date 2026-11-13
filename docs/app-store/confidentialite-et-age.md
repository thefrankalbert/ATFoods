# Questionnaires App Store Connect : confidentialité et âge

## Confidentialité de l'app (« App Privacy »)

Suivi publicitaire : **Non**. Aucune donnée n'est utilisée pour suivre l'utilisateur.

| Type de donnée | Collectée | Liée à l'identité | Finalité |
| --- | --- | --- | --- |
| Adresse e-mail | Oui | Oui | Fonctionnement de l'app (connexion) |
| Identifiant utilisateur | Oui | Oui | Fonctionnement de l'app |
| Photos ou vidéos | Oui | Oui | Fonctionnement de l'app (photos des plats) |
| Autre contenu utilisateur (noms, prix, descriptions des plats) | Oui | Oui | Fonctionnement de l'app |
| Données de plantage | Oui | Non | Fonctionnement de l'app |
| Données de performance | Oui | Non | Fonctionnement de l'app |
| Autres données de diagnostic | Oui | Non | Fonctionnement de l'app |

Tout le reste (localisation, contacts, données financières, santé, historique de navigation, achats) : **non collecté**.

Ces réponses correspondent au fichier `App/Resources/PrivacyInfo.xcprivacy`. Prestataires : Supabase (données et
photos), Sentry (plantages et performance, sans e-mail ni adresse IP).

## Classification par âge

Répondre **Non** ou **Aucun** à toutes les questions (violence, contenu sexuel, jeux d'argent, alcool, contenu
généré par les utilisateurs visible par d'autres, navigation web libre). Résultat attendu : **4+**.

## Conformité à l'exportation

L'app n'utilise que le chiffrement standard (HTTPS). `ITSAppUsesNonExemptEncryption` est à `false` : aucune
déclaration supplémentaire.

## Droits sur le contenu

Les trois photos de l'écran de présentation viennent d'Unsplash (licence Unsplash, usage commercial autorisé).
Références : b4Ht8TQ1JGo (Keesha's Kitchen), al9eh9QkdPA (VK bro), UC0HZdUitWY (Victoria Shes).
