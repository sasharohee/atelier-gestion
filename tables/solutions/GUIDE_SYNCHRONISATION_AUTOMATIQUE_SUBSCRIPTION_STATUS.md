# Guide de Synchronisation Automatique Subscription Status

## Problème Résolu

Quand un nouvel utilisateur s'inscrit, il n'apparaissait pas automatiquement dans la table `subscription_status`, causant des erreurs 406 et des boucles infinies dans l'application.

## Solution Implémentée

### 1. Trigger SQL Automatique

Un trigger SQL a été créé pour synchroniser automatiquement les nouveaux utilisateurs vers la table `subscription_status`.

**Fichier créé :** `tables/trigger_synchronisation_automatique_subscription_status.sql`

### 2. Amélioration du Hook useSubscription

Le hook `useSubscription.ts` a été modifié pour :
- Tenter de créer automatiquement l'enregistrement manquant
- Gérer les erreurs 406 et PGRST116
- Éviter les boucles infinies
- Utiliser un système de fallback en cas d'échec

### 3. Amélioration du Service d'Inscription

Le service `supabaseService.ts` a été modifié pour :
- Tenter la synchronisation immédiatement après l'inscription
- Gérer les erreurs de synchronisation gracieusement
- Maintenir la compatibilité avec le trigger SQL

### 4. Correction de l'Erreur React DevTools

L'avertissement React DevTools a été désactivé en production dans `index.html`.

## Étapes d'Application

### Étape 1 : Exécuter le Script SQL

1. Ouvrez votre dashboard Supabase
2. Allez dans l'éditeur SQL
3. Copiez et exécutez le contenu du fichier :
   ```
   tables/trigger_synchronisation_automatique_subscription_status.sql
   ```

### Étape 2 : Vérifier l'Application

1. Testez l'inscription d'un nouvel utilisateur
2. Vérifiez que l'utilisateur apparaît automatiquement dans `subscription_status`
3. Vérifiez que les erreurs 406 ont disparu

### Étape 3 : Tester la Synchronisation

1. Créez un compte avec `test17@yopmail.com`
2. Vérifiez dans Supabase que l'enregistrement est créé dans `subscription_status`
3. Vérifiez que l'utilisateur peut se connecter sans erreur

## Fonctionnalités du Trigger

### Synchronisation Automatique
- Se déclenche à chaque création d'utilisateur dans `auth.users`
- Insère automatiquement l'utilisateur dans `subscription_status`
- Gère les erreurs sans faire échouer l'inscription

### Gestion des Rôles
- **Admin** : `is_active = true`, `subscription_type = 'premium'`, `status = 'ACTIF'`
- **Utilisateur normal** : `is_active = false`, `subscription_type = 'free'`, `status = 'INACTIF'`

### Emails Spéciaux
- `srohee32@gmail.com` et `repphonereparation@gmail.com` : accès admin automatique

## Politiques RLS Corrigées

Les politiques RLS ont été simplifiées pour :
- Permettre les insertions par trigger
- Maintenir la sécurité des données
- Éviter les erreurs 406

## Gestion des Erreurs

### Erreur 406 (Not Acceptable)
- Causée par des politiques RLS trop restrictives
- Corrigée par les nouvelles politiques

### Erreur PGRST116 (0 rows)
- Causée par l'absence d'enregistrement dans `subscription_status`
- Corrigée par la création automatique

### Boucles Infinies
- Causées par des appels répétés en cas d'erreur
- Corrigées par une meilleure gestion des erreurs

## Vérification

### Dans Supabase Dashboard
```sql
-- Vérifier que le trigger existe
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status';

-- Vérifier la synchronisation
SELECT COUNT(*) as auth_users, 
       (SELECT COUNT(*) FROM subscription_status) as subscription_users
FROM auth.users;
```

### Dans l'Application
- Plus d'erreurs 406 dans la console
- Plus de boucles infinies
- Synchronisation automatique des nouveaux utilisateurs

## Maintenance

### Ajout d'Utilisateurs Existants
Si des utilisateurs existent déjà dans `auth.users` mais pas dans `subscription_status`, le script SQL les ajoutera automatiquement.

### Modification du Trigger
Pour modifier la logique de synchronisation, éditez la fonction `sync_user_to_subscription_status()` dans le script SQL.

## Résolution de l'Erreur React DevTools

L'avertissement "Download the React DevTools" a été supprimé en production en ajoutant un script dans `index.html` qui désactive les DevTools en production.

## Test Complet

1. **Inscription** : Créez un nouveau compte
2. **Vérification** : L'utilisateur apparaît dans `subscription_status`
3. **Connexion** : L'utilisateur peut se connecter sans erreur
4. **Accès** : L'utilisateur a accès aux fonctionnalités selon son statut

## Support

Si des problèmes persistent :
1. Vérifiez que le trigger SQL a été exécuté
2. Vérifiez les politiques RLS dans Supabase
3. Consultez les logs de la console pour les erreurs
4. Vérifiez la table `subscription_status` dans Supabase
