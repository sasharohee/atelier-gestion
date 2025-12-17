# Synchronisation des Abonnements Stripe - Version Améliorée

## 🔧 Améliorations de cette version

Cette version améliorée du script :

1. **Recherche dans plusieurs tables** : Cherche d'abord dans `auth.users`, puis dans `public.users` si non trouvé
2. **Comparaison insensible à la casse** : Utilise `LOWER()` pour comparer les emails
3. **Diagnostic complet** : Affiche d'abord quels utilisateurs existent avant de synchroniser
4. **Meilleure gestion des erreurs** : Gère les cas où les champs sont NULL ou vides
5. **Vérification étendue** : Vérifie par `stripe_subscription_id` ET `stripe_customer_id`
6. **Statistiques** : Affiche des statistiques après la synchronisation

## 🚀 Utilisation

### Étape 1 : Exécuter le Script

1. Ouvrez **Supabase Dashboard** > **SQL Editor**
2. Copiez le contenu du fichier `supabase/migrations/sync_existing_stripe_subscriptions_v2.sql`
3. Collez et exécutez le script

### Étape 2 : Vérifier les Résultats

Le script affichera :
1. **Diagnostic** : Liste des utilisateurs trouvés dans `auth.users`
2. **Synchronisation** : Messages de succès ou d'avertissement pour chaque abonnement
3. **Vérification** : Liste des abonnements synchronisés avec leurs détails
4. **Statistiques** : Nombre total d'abonnements avec Stripe

## 📊 Ce que fait le script

Pour chaque abonnement :

1. **Recherche l'utilisateur** :
   - D'abord dans `auth.users` (insensible à la casse)
   - Si non trouvé, dans `public.users`
   
2. **Si l'utilisateur existe** :
   - Calcule la date de fin de période (1 mois après le début)
   - Crée ou met à jour l'entrée dans `subscription_status`
   - Met à jour tous les champs Stripe même si l'entrée existe déjà

3. **Si l'utilisateur n'existe pas** :
   - Affiche un avertissement mais continue avec les autres

## ⚠️ Si les données ne sont toujours pas à jour

Si après exécution les données ne sont pas à jour, vérifiez :

1. **Les emails correspondent-ils exactement ?**
   - Le script utilise `LOWER()` pour ignorer la casse
   - Vérifiez dans le diagnostic quels emails sont trouvés

2. **Les utilisateurs existent-ils dans auth.users ou public.users ?**
   - Le script affiche un avertissement si un utilisateur n'est pas trouvé
   - Vous devrez peut-être créer ces utilisateurs d'abord

3. **Y a-t-il des erreurs dans les logs ?**
   - Vérifiez les messages `RAISE NOTICE` et `RAISE WARNING` dans les résultats

4. **Les contraintes de clé unique sont-elles respectées ?**
   - Si `user_id` existe déjà, l'`ON CONFLICT` devrait mettre à jour
   - Vérifiez que la contrainte `user_id` unique existe bien

## 🔍 Vérification manuelle

Pour vérifier manuellement si un utilisateur a été synchronisé :

```sql
SELECT 
  ss.*,
  au.email as auth_email,
  pu.email as public_email
FROM subscription_status ss
LEFT JOIN auth.users au ON ss.user_id = au.id
LEFT JOIN public.users pu ON ss.user_id = pu.id
WHERE ss.stripe_customer_id = 'cus_TReWmx6LBkfJQe'  -- Remplacez par le customer_id
   OR ss.email = 'mickaphone13@gmail.com';  -- Remplacez par l'email
```

