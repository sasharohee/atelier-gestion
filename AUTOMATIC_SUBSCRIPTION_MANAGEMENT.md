# Gestion Automatique des Abonnements

## 🎯 Objectif

S'assurer que les abonnements sont automatiquement synchronisés et que les comptes sont bloqués/débloqués selon le statut de l'abonnement Stripe.

## ✅ Ce qui est en place

### 1. Webhook Stripe (Automatique)

Le webhook `stripe-webhook` gère automatiquement :

- ✅ **checkout.session.completed** : Active l'abonnement quand un paiement est complété
- ✅ **customer.subscription.updated** : Met à jour le statut (actif/inactif) selon Stripe
- ✅ **customer.subscription.deleted** : Désactive et bloque l'accès quand l'abonnement est annulé
- ✅ **invoice.payment_succeeded** : Renouvelle l'abonnement et met à jour la date de fin
- ✅ **invoice.payment_failed** : Désactive et bloque l'accès en cas d'échec de paiement

### 2. Vérification côté client (useSubscription)

Le hook `useSubscription` :

- ✅ Vérifie automatiquement si l'abonnement a expiré
- ✅ Met à jour `is_active = false` si la période est expirée
- ✅ Bloque l'accès si `is_active = false`

### 3. Protection des routes (SubscriptionGuard)

Le composant `SubscriptionGuard` :

- ✅ Bloque automatiquement l'accès si `is_active = false`
- ✅ Redirige vers la page `SubscriptionBlocked`
- ✅ Permet l'accès uniquement si `is_active = true`

## 🔧 Configuration requise

### 1. Exécuter la fonction SQL de vérification

Exécutez `create_subscription_expiry_check_function.sql` pour créer une fonction qui vérifie périodiquement les abonnements expirés.

### 2. Configurer un cron job (Recommandé)

Pour vérifier automatiquement les abonnements expirés, configurez un cron job dans Supabase :

```sql
-- Option 1: Utiliser pg_cron (si disponible)
SELECT cron.schedule(
  'check-expired-subscriptions',
  '0 * * * *', -- Toutes les heures
  $$SELECT check_and_deactivate_expired_subscriptions()$$
);
```

Ou utilisez un service externe (Vercel Cron, GitHub Actions, etc.) pour appeler cette fonction périodiquement.

### 3. Vérifier que le webhook Stripe est configuré

Dans Stripe Dashboard > Webhooks, assurez-vous que ces événements sont sélectionnés :

- ✅ `checkout.session.completed`
- ✅ `customer.subscription.updated`
- ✅ `customer.subscription.deleted`
- ✅ `invoice.payment_succeeded`
- ✅ `invoice.payment_failed`

## 📋 Flux de synchronisation

### Nouvel abonnement
1. Utilisateur clique sur "S'abonner" → Stripe Checkout
2. Paiement réussi → `checkout.session.completed`
3. Webhook met à jour `subscription_status` avec `is_active = true`
4. Utilisateur a accès à l'application

### Renouvellement
1. Stripe facture automatiquement → `invoice.payment_succeeded`
2. Webhook met à jour `stripe_current_period_end`
3. `is_active` reste `true`
4. Utilisateur garde l'accès

### Annulation
1. Utilisateur annule dans Stripe Portal → `customer.subscription.deleted`
2. Webhook met à jour `is_active = false`
3. `SubscriptionGuard` bloque l'accès
4. Utilisateur voit `SubscriptionBlocked`

### Échec de paiement
1. Paiement échoue → `invoice.payment_failed`
2. Webhook met à jour `is_active = false`
3. `SubscriptionGuard` bloque l'accès
4. Utilisateur voit `SubscriptionBlocked`

### Expiration
1. `stripe_current_period_end` < maintenant
2. `useSubscription` détecte l'expiration
3. Met à jour `is_active = false` automatiquement
4. `SubscriptionGuard` bloque l'accès

## 🔍 Vérification

Pour vérifier que tout fonctionne :

1. **Test d'abonnement** : Créez un abonnement test et vérifiez que `is_active = true`
2. **Test d'annulation** : Annulez un abonnement dans Stripe et vérifiez que `is_active = false`
3. **Test d'expiration** : Vérifiez qu'un abonnement expiré bloque bien l'accès

## ⚠️ Important

- Les webhooks Stripe sont la source de vérité principale
- La vérification côté client est un complément pour les cas où le webhook n'a pas encore été reçu
- La fonction SQL `check_and_deactivate_expired_subscriptions()` peut être exécutée périodiquement pour s'assurer qu'aucun abonnement expiré n'est oublié

