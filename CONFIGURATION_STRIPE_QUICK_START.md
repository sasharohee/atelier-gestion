# Configuration Stripe - Démarrage Rapide

## ⚡ Configuration Rapide

### Étape 1 : Exécuter la Migration SQL

1. Ouvrez **Supabase Dashboard** > **SQL Editor**
2. Copiez le contenu de `supabase/migrations/add_stripe_columns.sql`
3. Collez et exécutez le script

### Étape 2 : Configurer les Secrets Supabase

1. Allez dans **Supabase Dashboard** > **Settings** > **Edge Functions** > **Secrets**
2. Ajoutez ces 4 secrets :

```
STRIPE_SECRET_KEY
sk_live_VOTRE_CLE_SECRETE_ICI

STRIPE_WEBHOOK_SECRET
whsec_VOTRE_WEBHOOK_SECRET_ICI

STRIPE_PRICE_ID_MONTHLY
price_VOTRE_PRICE_ID_MONTHLY_ICI

STRIPE_PRICE_ID_YEARLY
price_VOTRE_PRICE_ID_YEARLY_ICI
```

### Étape 3 : Créer le fichier .env

1. Récupérez votre clé publique Stripe :
   - Allez sur https://dashboard.stripe.com/apikeys
   - Trouvez la clé qui correspond à votre clé secrète (même compte)
   - Elle commence par `pk_live_` (pour la production)

2. Créez un fichier `.env` à la racine du projet :

```env
# Clé publique Stripe (récupérée depuis https://dashboard.stripe.com/apikeys)
# Remplacez par votre clé publique qui commence par pk_live_
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PUBLIQUE_ICI

VITE_STRIPE_PRICE_ID_MONTHLY=price_VOTRE_PRICE_ID_MONTHLY_ICI
VITE_STRIPE_PRICE_ID_YEARLY=price_VOTRE_PRICE_ID_YEARLY_ICI
```

### Étape 4 : Déployer les Edge Functions

```bash
# Installer Supabase CLI
npm install -g supabase

# Se connecter
supabase login

# Lier le projet (remplacez par votre project-ref)
supabase link --project-ref votre-project-ref

# Déployer
supabase functions deploy stripe-checkout
supabase functions deploy stripe-webhook
```

### Étape 5 : Configurer le Webhook Stripe

1. Allez sur https://dashboard.stripe.com/webhooks
2. Cliquez sur **"Add endpoint"**
3. URL : `https://[votre-project-ref].supabase.co/functions/v1/stripe-webhook`
4. Sélectionnez ces événements :
   - ✅ `checkout.session.completed`
   - ✅ `customer.subscription.updated`
   - ✅ `customer.subscription.deleted`
   - ✅ `invoice.payment_succeeded`
   - ✅ `invoice.payment_failed`
5. Copiez le secret du webhook (commence par `whsec_`) et configurez-le dans Supabase

## ✅ Test

1. Redémarrez votre application
2. Connectez-vous
3. Allez sur la page de blocage d'abonnement
4. Cliquez sur "S'abonner"
5. Vous devriez être redirigé vers Stripe Checkout

## 🔍 Vérification

- Vérifiez que les Edge Functions sont déployées dans Supabase Dashboard
- Vérifiez les logs des webhooks dans Stripe Dashboard après un paiement
- Vérifiez que `subscription_status` est mis à jour dans Supabase après un paiement réussi

