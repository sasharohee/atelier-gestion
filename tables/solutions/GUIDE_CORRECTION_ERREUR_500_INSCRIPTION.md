# Guide de Correction de l'Erreur 500 lors de l'Inscription

## Problème
L'erreur 500 "Database error saving new user" se produit lors de la création de compte. Cette erreur est causée par des problèmes dans la base de données Supabase lors de l'inscription.

## Causes Identifiées
1. **Triggers problématiques** sur la table `users`
2. **Fonctions RPC défaillantes** lors de la création des données par défaut
3. **Tables manquantes** (`subscription_status`, `system_settings`)
4. **Politiques RLS mal configurées**

## Solution Immédiate

### Étape 1: Exécuter le Script de Correction
1. Ouvrez votre dashboard Supabase
2. Allez dans l'éditeur SQL
3. Exécutez le script `tables/correction_immediate_inscription_500.sql`

### Étape 2: Vérifier la Configuration
Après l'exécution du script, vérifiez que tous les éléments sont en place :

```sql
-- Vérifier les tables
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('subscription_status', 'system_settings');

-- Vérifier la fonction RPC
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'create_user_default_data';

-- Vérifier les permissions
SELECT grantee FROM information_schema.routine_privileges 
WHERE routine_name = 'create_user_default_data';
```

### Étape 3: Tester l'Inscription
1. Essayez de créer un nouveau compte
2. Vérifiez que l'inscription fonctionne sans erreur 500
3. Vérifiez que l'utilisateur est créé dans `auth.users`

## Modifications Apportées au Code

### 1. Service d'Authentification Simplifié
Le service `supabaseService.ts` a été modifié pour :
- Éviter les appels RPC lors de l'inscription
- Créer les données par défaut de manière asynchrone
- Améliorer la gestion d'erreurs

### 2. Fonction RPC Améliorée
La fonction `create_user_default_data` a été :
- Simplifiée avec une meilleure gestion d'erreurs
- Configurée avec les bonnes permissions
- Testée pour éviter les erreurs 500

## Vérifications Post-Correction

### 1. Vérifier les Logs
Dans la console du navigateur, vérifiez que :
- L'inscription se termine sans erreur
- Les messages de succès s'affichent
- Aucune erreur RPC n'apparaît

### 2. Vérifier la Base de Données
```sql
-- Vérifier que l'utilisateur est créé
SELECT * FROM auth.users WHERE email = 'email_test@example.com';

-- Vérifier les données par défaut
SELECT * FROM subscription_status WHERE user_id = 'user_id';
SELECT * FROM system_settings WHERE user_id = 'user_id';
```

### 3. Tester la Connexion
1. Confirmez l'email reçu
2. Connectez-vous avec le nouveau compte
3. Vérifiez que l'utilisateur peut accéder à l'application

## Dépannage

### Si l'erreur persiste :

#### 1. Vérifier les Triggers
```sql
-- Lister tous les triggers sur la table users
SELECT trigger_name FROM information_schema.triggers 
WHERE event_object_table = 'users';

-- Supprimer les triggers problématiques
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
```

#### 2. Vérifier les Contraintes
```sql
-- Lister les contraintes sur la table users
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'users';
```

#### 3. Vérifier les Politiques RLS
```sql
-- Lister les politiques sur auth.users
SELECT policyname FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'auth';
```

### Si les tables sont manquantes :
Exécutez les commandes de création des tables dans le script de correction.

## Prévention

### 1. Tests Réguliers
- Testez régulièrement l'inscription de nouveaux utilisateurs
- Surveillez les logs d'erreur dans Supabase
- Vérifiez les performances des fonctions RPC

### 2. Monitoring
- Configurez des alertes pour les erreurs 500
- Surveillez les temps de réponse des fonctions RPC
- Vérifiez régulièrement l'état des tables

### 3. Sauvegarde
- Sauvegardez régulièrement la configuration de la base de données
- Documentez les modifications apportées
- Gardez des copies des scripts de correction

## Support

Si le problème persiste après avoir suivi ce guide :
1. Vérifiez les logs Supabase dans le dashboard
2. Consultez la documentation Supabase sur l'authentification
3. Contactez le support Supabase si nécessaire

## Notes Importantes

- Les modifications apportées sont non-destructives
- Les données existantes sont préservées
- La fonctionnalité d'inscription est simplifiée mais fonctionnelle
- Les données par défaut sont créées de manière asynchrone pour éviter les blocages
