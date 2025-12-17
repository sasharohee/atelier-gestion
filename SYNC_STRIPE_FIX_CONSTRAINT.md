# Correction de la Contrainte subscription_type

## 🚨 Problème

L'erreur indique que la contrainte `subscription_status_subscription_type_check` ne permet pas la valeur `premium_monthly`.

## ✅ Solution

### Étape 1 : Corriger la contrainte (OBLIGATOIRE)

**Exécutez d'abord** le script `fix_subscription_type_constraint.sql` :

1. Ouvrez **Supabase Dashboard** > **SQL Editor**
2. Copiez le contenu de `supabase/migrations/fix_subscription_type_constraint.sql`
3. Exécutez le script

Ce script va :
- ✅ Vérifier la contrainte actuelle
- ✅ Supprimer l'ancienne contrainte
- ✅ Créer une nouvelle contrainte qui autorise :
  - `free`
  - `premium`
  - `enterprise`
  - `premium_monthly` (nouveau)
  - `premium_yearly` (nouveau)

### Étape 2 : Synchroniser les abonnements

**Après avoir corrigé la contrainte**, exécutez le script de synchronisation :

1. Utilisez `sync_existing_stripe_subscriptions_v2.sql` OU
2. Utilisez `sync_stripe_by_customer_id.sql` (version corrigée)

## 📋 Ordre d'exécution

1. **D'abord** : `fix_subscription_type_constraint.sql`
2. **Ensuite** : `sync_existing_stripe_subscriptions_v2.sql` ou `sync_stripe_by_customer_id.sql`

## ⚠️ Important

Ne pas exécuter les scripts de synchronisation avant d'avoir corrigé la contrainte, sinon vous obtiendrez la même erreur.

