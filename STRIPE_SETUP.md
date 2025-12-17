# Guide de Configuration Stripe

## 🔐 Configuration des Secrets Stripe

### 1. Configuration Supabase Edge Functions (Backend)

Allez dans **Supabase Dashboard** > **Settings** > **Edge Functions** > **Secrets** et ajoutez les secrets suivants :

```
STRIPE_SECRET_KEY=sk_live_VOTRE_CLE_SECRETE_ICI
STRIPE_WEBHOOK_SECRET=whsec_VOTRE_WEBHOOK_SECRET_ICI
STRIPE_PRICE_ID_MONTHLY=price_VOTRE_PRICE_ID_MONTHLY_ICI
STRIPE_PRICE_ID_YEARLY=price_VOTRE_PRICE_ID_YEARLY_ICI
```

### 2. Configuration Frontend (.env)

Créez ou modifiez votre fichier `.env` à la racine du projet avec :

```env
# Configuration Stripe (Frontend)
VITE_STRIPE_PUBLISHABLE_KEY=pk_live_VOTRE_CLE_PUBLIQUE_ICI
VITE_STRIPE_PRICE_ID_MONTHLY=price_VOTRE_PRICE_ID_MONTHLY_ICI
VITE_STRIPE_PRICE_ID_YEARLY=price_VOTRE_PRICE_ID_YEARLY_ICI
```

**Note** : La clé publique (publishable key) commence par `pk_live_` et peut être trouvée dans votre [Stripe Dashboard](https://dashboard.stripe.com/apikeys).

### 3. Déploiement des Edge Functions

Déployez les Edge Functions dans Supabase :

```bash
# Installer Supabase CLI si ce n'est pas déjà fait
npm install -g supabase

# Se connecter à Supabase
supabase login

# Lier votre projet
supabase link --project-ref votre-project-ref

# Déployer les fonctions
supabase functions deploy stripe-checkout
supabase functions deploy stripe-webhook
```

### 4. Configuration du Webhook Stripe

1. Allez dans votre [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
2. Cliquez sur **"Add endpoint"**
3. Configurez l'endpoint :
   - **URL** : `https://[votre-project-ref].supabase.co/functions/v1/stripe-webhook`
   - **Events to send** : Sélectionnez les événements suivants :
     - `checkout.session.completed`
     - `customer.subscription.updated`
     - `customer.subscription.deleted`
     - `invoice.payment_succeeded`
     - `invoice.payment_failed`
4. Copiez le **Signing secret** (commence par `whsec_`) et utilisez-le comme `STRIPE_WEBHOOK_SECRET` dans Supabase

### 5. Exécution de la Migration SQL

Exécutez la migration dans **Supabase Dashboard** > **SQL Editor** :

```sql
-- Le fichier se trouve dans : supabase/migrations/add_stripe_columns.sql
```

Ou copiez-collez le contenu du fichier `supabase/migrations/add_stripe_columns.sql` dans l'éditeur SQL et exécutez-le.

## ✅ Vérification

### Test 1 : Vérifier les Edge Functions
- Les fonctions `stripe-checkout` et `stripe-webhook` doivent être déployées
- Vérifiez dans Supabase Dashboard > Edge Functions

### Test 2 : Tester le Checkout
1. Connectez-vous à l'application
2. Allez sur la page de blocage d'abonnement
3. Cliquez sur "S'abonner"
4. Vous devriez être redirigé vers Stripe Checkout

### Test 3 : Vérifier le Webhook
- Dans Stripe Dashboard > Webhooks, vous devriez voir les événements reçus
- Après un paiement réussi, l'abonnement devrait être activé automatiquement

## 🔒 Sécurité

⚠️ **IMPORTANT** :
- Ne commitez JAMAIS les clés secrètes dans Git
- Utilisez `.env` pour le développement local (déjà dans `.gitignore`)
- Les secrets Supabase sont stockés de manière sécurisée dans Supabase
- La clé publique (publishable key) peut être exposée côté client, mais la clé secrète (secret key) doit rester sur le serveur uniquement

## 📝 Notes

- Les prix sont configurés pour la production (mode `live`)
- Pour tester en mode test, utilisez les clés de test (commençant par `sk_test_` et `pk_test_`)
- Les IDs de prix sont spécifiques à votre compte Stripe

