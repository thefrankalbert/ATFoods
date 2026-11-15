# App Review notes (paste into "App Review Information > Notes")

Atfood is a companion app for restaurant owners and staff who already use Attabl (https://attabl.com), a B2B SaaS
that hosts a restaurant's online menu and QR menu. The app has one job: take a photo of a dish and publish it on
the restaurant's menu, and keep that menu up to date (price, availability, description, allergens).

**Sign-in.** There is no sign-up in the app: accounts are created by the restaurant from its Attabl web dashboard,
as part of a business subscription sold outside the app to businesses. The app sells nothing and shows no prices.

**Demo account** (enter in the Sign-in fields above):
- User name: review@attabl.com
- Password: the one set when running docs/app-store/demo-account.sql

The demo account is an administrator of "Restaurant Démo Atfood", a test restaurant with four dishes.

**How to test the main flow**
1. Skip the three intro screens and sign in.
2. Home lists the dishes. The switch on each row marks a dish available or sold out.
3. Tap "Prendre une photo" (Take a photo). Allow the camera, shoot any plate, tap "Utiliser" (Use).
4. Tap "Créer un nouveau plat" (Create a new dish), enter a name and a price, pick a category, tap "Enregistrer" (Save).
5. The dish appears on Home and on the public menu of the demo restaurant.

**Account deletion.** Profile (person icon, top right) > "Supprimer mon compte". Deletion is real and immediate for
this account. An owner who is the only owner of a restaurant is asked to confirm that the restaurant closes too;
the request is recorded in the app and completed within 30 days.

**Language.** The interface is in French only: the product is sold in French-speaking countries.

**Camera.** Used only to photograph dishes. Photos can also be picked from the library with the system picker.
