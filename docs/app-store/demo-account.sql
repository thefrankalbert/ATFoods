-- App Review demo account for Atfood (created in production on 2026-11-09). Safe to rerun before each review round:
-- it recreates the sign-in and keeps the demo restaurant.
-- Creates: an auth user, an "active" demo restaurant (no Stripe), an ADMIN membership (not owner, so the
-- reviewer can test in-app account deletion), 2 categories and 4 dishes. Replace the password below before running.
-- Undo: delete from tenants where slug = 'atfood-demo-apple'; delete from auth.users where email = 'review@attabl.com';
DO $$
DECLARE
  v_user uuid := gen_random_uuid();
  v_tenant uuid := gen_random_uuid();
  v_menu uuid := gen_random_uuid();
  v_cat_plats uuid := gen_random_uuid();
  v_cat_boissons uuid := gen_random_uuid();
  v_email text := 'review@attabl.com';
  v_existing uuid;
  v_password text := 'CHANGE-ME-before-running';
BEGIN
  -- Rerunnable: the reviewer may delete the account from the app (it is an admin, deletion is real).
  -- The demo restaurant is kept; only the sign-in is recreated.
  SELECT id INTO v_existing FROM tenants WHERE slug = 'atfood-demo-apple';
  DELETE FROM admin_users WHERE email = v_email AND tenant_id = v_existing;
  DELETE FROM auth.users WHERE email = v_email;
  INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                          confirmation_token, recovery_token, email_change_token_new, email_change)
  VALUES ('00000000-0000-0000-0000-000000000000', v_user, 'authenticated', 'authenticated', v_email,
          extensions.crypt(v_password, extensions.gen_salt('bf')), now(),
          '{"provider":"email","providers":["email"]}', '{"full_name":"Apple Review"}', now(), now(),
          '', '', '', '');
  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_user, v_user::text,
          jsonb_build_object('sub', v_user::text, 'email', v_email, 'email_verified', true),
          'email', now(), now(), now());

  IF v_existing IS NOT NULL THEN
    v_tenant := v_existing;
  ELSE
    INSERT INTO tenants (id, slug, name, city, country, currency, subscription_plan, subscription_status,
                         is_active, onboarding_completed, at_food_enabled)
    VALUES (v_tenant, 'atfood-demo-apple', 'Restaurant Démo Atfood', 'Douala', 'CM', 'XAF', 'pro', 'active',
            true, true, true);
    INSERT INTO menus (id, tenant_id, name, slug, is_active, display_order)
    VALUES (v_menu, v_tenant, 'Carte', 'carte', true, 0);
    INSERT INTO categories (id, tenant_id, menu_id, name, display_order, is_active) VALUES
      (v_cat_plats, v_tenant, v_menu, 'Plats', 0, true),
      (v_cat_boissons, v_tenant, v_menu, 'Boissons', 1, true);
    INSERT INTO menu_items (tenant_id, category_id, name, price, is_available) VALUES
      (v_tenant, v_cat_plats, 'Poulet DG', 6500, true),
      (v_tenant, v_cat_plats, 'Ndolé', 4500, true),
      (v_tenant, v_cat_plats, 'Poisson braisé', 7000, true),
      (v_tenant, v_cat_boissons, 'Jus de bissap', 1000, true);
  END IF;

  INSERT INTO admin_users (user_id, tenant_id, email, full_name, role, is_active)
  VALUES (v_user, v_tenant, v_email, 'Apple Review', 'admin', true);
END $$;
