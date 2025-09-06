# Guide de Correction - Suppression d'Utilisateurs

## 🚨 Problème Identifié

L'erreur `Failed to delete user: Database error deleting user` est causée par plusieurs facteurs :

1. **Contraintes de clés étrangères** : Les tables ont des contraintes `ON DELETE RESTRICT` ou `ON DELETE NO ACTION` qui empêchent la suppression
2. **Politiques RLS** : Les politiques RLS peuvent bloquer les opérations DELETE
3. **Triggers** : Des triggers sur `auth.users` peuvent interférer avec la suppression
4. **Données liées** : Des enregistrements dans d'autres tables référencent l'utilisateur

## 🔧 Solution Appliquée

### 1. Script de Diagnostic
- **Fichier créé** : `diagnostic_suppression_utilisateurs.sql`
- **Fonctionnalité** : Identifie tous les problèmes qui empêchent la suppression

### 2. Script de Correction
- **Fichier créé** : `correction_suppression_utilisateurs.sql`
- **Fonctionnalités** :
  - ✅ Supprime les triggers problématiques
  - ✅ Corrige les contraintes de clés étrangères (RESTRICT → CASCADE)
  - ✅ Corrige les politiques RLS pour permettre la suppression par les admins
  - ✅ Crée une fonction RPC `delete_user_safely` avec `SECURITY DEFINER`
  - ✅ Crée une fonction de suppression en masse
  - ✅ Crée une fonction de nettoyage des données orphelines

## 📋 Instructions de Déploiement

### Étape 1: Diagnostic
1. **Exécuter le diagnostic** :
   ```sql
   -- Copiez le contenu de diagnostic_suppression_utilisateurs.sql
   -- Exécutez-le dans l'éditeur SQL de Supabase
   ```

2. **Analyser les résultats** :
   - Vérifiez les contraintes `RESTRICT` ou `NO ACTION`
   - Vérifiez les politiques RLS DELETE
   - Vérifiez les triggers sur `auth.users`

### Étape 2: Correction
1. **Exécuter la correction** :
   ```sql
   -- Copiez le contenu de correction_suppression_utilisateurs.sql
   -- Exécutez-le dans l'éditeur SQL de Supabase
   ```

2. **Vérifier la configuration** :
   - Les contraintes doivent être en `CASCADE`
   - Les politiques RLS doivent permettre la suppression par les admins
   - Les fonctions RPC doivent être créées

## 🔍 Vérification de la Correction

### 1. Vérifier les Contraintes
```sql
-- Vérifier que les contraintes sont en CASCADE
SELECT 
    tc.table_name,
    tc.constraint_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND ccu.table_name = 'users'
    AND ccu.table_schema = 'auth';
```

### 2. Vérifier les Politiques RLS
```sql
-- Vérifier les politiques DELETE
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
    AND (cmd = 'DELETE' OR cmd = 'ALL');
```

### 3. Vérifier les Fonctions RPC
```sql
-- Vérifier que les fonctions existent
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name IN ('delete_user_safely', 'delete_multiple_users_safely', 'cleanup_orphaned_data')
    AND routine_schema = 'public';
```

## 🛠️ Utilisation des Nouvelles Fonctions

### 1. Suppression d'un Utilisateur
```sql
-- Supprimer un utilisateur spécifique
SELECT delete_user_safely('user-uuid-here');
```

### 2. Suppression en Masse
```sql
-- Supprimer plusieurs utilisateurs
SELECT delete_multiple_users_safely(ARRAY['uuid1', 'uuid2', 'uuid3']);
```

### 3. Nettoyage des Données Orphelines
```sql
-- Nettoyer les données orphelines
SELECT cleanup_orphaned_data();
```

## 🔒 Sécurité Maintenue

Cette solution maintient la sécurité :

- ✅ Seuls les administrateurs peuvent supprimer des utilisateurs
- ✅ Impossible de supprimer son propre compte
- ✅ Impossible de supprimer les comptes admin principaux
- ✅ Les données liées sont supprimées en cascade
- ✅ Les fonctions utilisent `SECURITY DEFINER` pour contourner RLS

## 🚨 Points d'Attention

### Avant la Suppression
1. **Sauvegarder les données importantes** : Les données liées seront supprimées en cascade
2. **Vérifier les dépendances** : S'assurer qu'aucune donnée critique n'est liée
3. **Tester sur un utilisateur de test** : Vérifier que la suppression fonctionne

### Après la Suppression
1. **Vérifier l'intégrité** : S'assurer qu'aucune donnée orpheline n'est restée
2. **Nettoyer si nécessaire** : Utiliser `cleanup_orphaned_data()` si besoin
3. **Vérifier les logs** : Contrôler que la suppression s'est bien passée

## 🔄 Processus de Suppression

1. **Vérification des permissions** : L'utilisateur doit être admin
2. **Vérification de l'existence** : L'utilisateur à supprimer doit exister
3. **Vérification des restrictions** : Empêcher la suppression de comptes protégés
4. **Suppression des données liées** : CASCADE supprime automatiquement les données liées
5. **Suppression de l'utilisateur** : Suppression de `auth.users` et `public.users`

## 📞 Support

Si vous rencontrez des problèmes :

1. **Exécuter le diagnostic** : Utiliser `diagnostic_suppression_utilisateurs.sql`
2. **Vérifier les logs** : Contrôler les erreurs dans Supabase
3. **Tester les fonctions** : Vérifier que les fonctions RPC fonctionnent
4. **Nettoyer les données orphelines** : Utiliser `cleanup_orphaned_data()`

## ✅ Résultat Attendu

Après application de cette correction :
- ✅ La suppression d'utilisateurs fonctionne sans erreur
- ✅ Les données liées sont supprimées en cascade
- ✅ Seuls les admins peuvent supprimer des utilisateurs
- ✅ Les comptes protégés ne peuvent pas être supprimés
- ✅ Les données orphelines peuvent être nettoyées
