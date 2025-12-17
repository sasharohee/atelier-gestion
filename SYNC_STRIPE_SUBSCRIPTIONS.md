# Synchronisation des Abonnements Stripe Existants

## 📋 Description

Ce script SQL synchronise les abonnements Stripe existants dans la table `subscription_status` de votre base de données Supabase.

## 🚀 Utilisation

### Étape 1 : Exécuter le Script

1. Ouvrez **Supabase Dashboard** > **SQL Editor**
2. Copiez le contenu du fichier `supabase/migrations/sync_existing_stripe_subscriptions.sql`
3. Collez et exécutez le script

### Étape 2 : Vérifier les Résultats

Le script affichera :
- ✅ Les abonnements qui ont été synchronisés avec succès
- ⚠️ Les emails d'utilisateurs qui n'ont pas été trouvés dans `auth.users`

## 📊 Abonnements Synchronisés

Le script synchronise les 6 abonnements suivants :

| Email | Customer ID | Subscription ID | Plan |
|-------|-------------|-----------------|------|
| mickaphone13@gmail.com | cus_TReWmx6LBkfJQe | sub_1SUIEABSVpTT3lohLqFtwl6L | Mensuel |
| youssefkharchi467@gmail.com | cus_TQF0jpSGxR8uq9 | sub_1STOWMBsVpTT3lohQ7qzAipN | Mensuel |
| mickael.gonzalez33700@gmail.com | cus_TIJfaBdEnnxFhQ | sub_1SLj2SBsVpTT3loh2VSEY81u | Mensuel |
| contact@alexisleglise.fr | cus_TGkLwfD1gIOFjA | sub_1SKCrhBsVpTT3lohWCBb3ohi | Mensuel |
| JasonIg56100@hotmail.com | cus_TBiQYjrvWKnc87 | sub_1SFKzUBsVpTT3lohECsf4mpD | Mensuel |
| dylan.mauret16@gmail.com | cus_T0kcdZUiOOffWL | sub_1S4j7JBsVpTT3lohdbThpchK | Mensuel |

## 🔧 Ce que fait le Script

Pour chaque abonnement, le script :

1. **Recherche l'utilisateur** par email dans `auth.users`
2. **Calcule la date de fin de période** (1 mois après le début de période)
3. **Crée ou met à jour** l'entrée dans `subscription_status` avec :
   - `stripe_customer_id` : ID du client Stripe
   - `stripe_subscription_id` : ID de l'abonnement Stripe
   - `stripe_price_id_monthly` : ID du prix mensuel
   - `is_active` : `true` (abonnement actif)
   - `subscription_type` : `premium_monthly`
   - `stripe_current_period_end` : Date de fin de période actuelle
   - Informations utilisateur (email, prénom, nom)

## ⚠️ Notes Importantes

- Les utilisateurs doivent exister dans `auth.users` pour être synchronisés
- Si un utilisateur n'existe pas, un avertissement sera affiché mais le script continuera
- Les entrées existantes seront mises à jour si elles existent déjà
- Les dates sont calculées en ajoutant 1 mois à la date de début de période

## ✅ Après la Synchronisation

Une fois le script exécuté, les utilisateurs pourront :
- Voir leur statut d'abonnement sur la page "Abonnement"
- Accéder au portail client Stripe pour gérer leur abonnement
- Leur abonnement sera automatiquement synchronisé via les webhooks Stripe à l'avenir

