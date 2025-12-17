# Système d'Abonnement Automatique - Documentation Complète

## 🎯 Objectif

Système automatique qui :
1. ✅ Met à jour `subscription_status` automatiquement à chaque événement Stripe
2. ✅ Bloque automatiquement les comptes si l'abonnement est annulé ou non actif
3. ✅ Vérifie l'expiration des abonnements en temps réel
4. ✅ Débloque automatiquement quand un nouvel abonnement est pris

## 🔄 Flux Automatique

### 1. Nouvel Abonnement (checkout.session.completed)

**Quand** : Utilisateur complète un paiement Stripe Checkout

**Action automatique** :
- Webhook reçoit l'événement
- Met à jour `subscription_status` avec :
  - `is_active = true`
  - `stripe_customer_id`
  - `stripe_subscription_id`
  - `stripe_current_period_end`
  - `subscription_type = 'premium_monthly'` ou `'premium_yearly'`

**Résultat** : Utilisateur a immédiatement accès à l'application

### 2. Renouvellement (invoice.payment_succeeded)

**Quand** : Stripe facture automatiquement l'abonnement

**Action automatique** :
- Webhook met à jour `stripe_current_period_end`
- Vérifie que la période n'est pas expirée
- Maintient `is_active = true` si période valide

**Résultat** : Utilisateur garde l'accès

### 3. Annulation (customer.subscription.deleted)

**Quand** : Utilisateur annule son abonnement dans Stripe Portal

**Action automatique** :
- Webhook met à jour `subscription_status` avec :
  - `is_active = false`
  - `stripe_subscription_id = null`
  - `subscription_type = 'free'`

**Résultat** : Utilisateur est immédiatement bloqué → voit `SubscriptionBlocked`

### 4. Échec de Paiement (invoice.payment_failed)

**Quand** : Le paiement automatique échoue

**Action automatique** :
- Webhook met à jour `is_active = false`
- Met `subscription_type = 'free'`

**Résultat** : Utilisateur est immédiatement bloqué → voit `SubscriptionBlocked`

### 5. Mise à Jour d'Abonnement (customer.subscription.updated)

**Quand** : Statut de l'abonnement change dans Stripe

**Action automatique** :
- Webhook vérifie le statut Stripe (`active`, `canceled`, `past_due`, etc.)
- Met à jour `is_active` selon le statut :
  - `active` ou `trialing` → `is_active = true`
  - Autres → `is_active = false`
- Vérifie aussi que `stripe_current_period_end` n'est pas expiré

**Résultat** : Statut toujours synchronisé avec Stripe

### 6. Vérification d'Expiration (Côté Client)

**Quand** : Utilisateur accède à l'application

**Action automatique** :
- `useUltraFastAccess` vérifie `is_active` ET `stripe_current_period_end`
- Si période expirée → met à jour `is_active = false` automatiquement
- `AuthGuard` bloque l'accès si `is_active = false`

**Résultat** : Blocage immédiat même si le webhook n'a pas encore été reçu

## 🛡️ Protection des Routes

### AuthGuard (Protection Principale)

Le composant `AuthGuard` dans `App.tsx` :

```tsx
// Si l'utilisateur est connecté mais que l'abonnement n'est pas actif
if (user && !isAccessActive) {
  return <SubscriptionBlocked />;
}
```

**Fonctionnement** :
- ✅ Vérifie `isAccessActive` (basé sur `is_active` + expiration)
- ✅ Bloque automatiquement si `isAccessActive = false`
- ✅ Redirige vers `SubscriptionBlocked`

### SubscriptionGuard (Protection Secondaire)

Le composant `SubscriptionGuard` peut être utilisé pour des routes spécifiques si nécessaire.

## 📊 Vérifications Automatiques

### 1. Webhook Stripe (Temps Réel)

Les webhooks Stripe mettent à jour la base de données en temps réel :
- ✅ Délai : Quelques secondes après l'événement Stripe
- ✅ Source de vérité : Stripe
- ✅ Couvre tous les cas : création, renouvellement, annulation, échec

### 2. Vérification Côté Client (Temps Réel)

`useUltraFastAccess` vérifie à chaque accès :
- ✅ Vérifie `is_active`
- ✅ Vérifie `stripe_current_period_end`
- ✅ Met à jour automatiquement si expiré
- ✅ Cache de 15 secondes pour performance

### 3. Fonction SQL Périodique (Optionnel)

La fonction `check_and_deactivate_expired_subscriptions()` peut être exécutée périodiquement :
- ✅ Vérifie tous les abonnements expirés
- ✅ Désactive ceux qui sont expirés
- ✅ Recommandé : Exécuter toutes les heures via cron job

## 🔧 Configuration Requise

### 1. Webhook Stripe

Dans Stripe Dashboard > Webhooks, configurez l'endpoint :
- **URL** : `https://[votre-project-ref].supabase.co/functions/v1/stripe-webhook`
- **Événements** :
  - ✅ `checkout.session.completed`
  - ✅ `customer.subscription.updated`
  - ✅ `customer.subscription.deleted`
  - ✅ `invoice.payment_succeeded`
  - ✅ `invoice.payment_failed`

### 2. Fonction SQL (Optionnel)

Exécutez `create_subscription_expiry_check_function.sql` pour créer la fonction de vérification périodique.

### 3. Cron Job (Optionnel)

Configurez un cron job pour exécuter la fonction SQL périodiquement (toutes les heures recommandé).

## ✅ Garanties du Système

1. **Synchronisation Automatique** : Les données sont toujours à jour grâce aux webhooks
2. **Blocage Automatique** : Les comptes sont bloqués immédiatement si :
   - Abonnement annulé
   - Paiement échoué
   - Période expirée
3. **Déblocage Automatique** : Les comptes sont débloqués immédiatement quand :
   - Nouvel abonnement pris
   - Paiement réussi
   - Abonnement renouvelé

## 🔍 Vérification

Pour vérifier que tout fonctionne :

1. **Test d'abonnement** :
   - Créez un abonnement test
   - Vérifiez que `is_active = true` dans `subscription_status`
   - Vérifiez que l'utilisateur a accès

2. **Test d'annulation** :
   - Annulez un abonnement dans Stripe Portal
   - Vérifiez que `is_active = false` dans `subscription_status`
   - Vérifiez que l'utilisateur est bloqué

3. **Test d'expiration** :
   - Modifiez `stripe_current_period_end` à une date passée
   - Rechargez l'application
   - Vérifiez que l'utilisateur est bloqué

## 📝 Notes Importantes

- ⚠️ Les webhooks Stripe sont la source de vérité principale
- ⚠️ La vérification côté client est un complément pour les cas où le webhook n'a pas encore été reçu
- ⚠️ Le cache de 15 secondes peut causer un léger délai, mais garantit la performance
- ⚠️ Les admins (srohee32@gmail.com, repphonereparation@gmail.com) ont toujours accès même sans abonnement

