# Guide de Correction - Utilisateur Manquant et Boucles Infinies

## Problème Identifié

L'erreur principale est que l'utilisateur avec l'ID `14577c87-1336-476b-9747-aa16f8413bfe` existe dans l'authentification Supabase (`auth.users`) mais pas dans votre table `users` (`public.users`). Cela cause :

1. **Boucles infinies de requêtes** : Chaque appel à `getCurrentUser()` retourne `null`
2. **Messages d'erreur répétitifs** : "Utilisateur non trouvé dans la table users"
3. **Fonctionnalités bloquées** : Impossible d'accéder aux données

## Solutions

### Solution 1 : Correction SQL Immédiate

Exécutez le script `correction_utilisateur_manquant.sql` dans votre base de données Supabase :

1. Allez dans votre dashboard Supabase
2. Ouvrez l'éditeur SQL
3. Copiez et exécutez le contenu de `correction_utilisateur_manquant.sql`

Ce script va :
- Vérifier l'existence de l'utilisateur dans `auth.users`
- Insérer l'utilisateur manquant dans `public.users`
- Vérifier que l'insertion a fonctionné

### Solution 2 : Correction Côté Application

J'ai modifié le fichier `src/services/supabaseService.ts` pour ajouter une **création automatique** de l'utilisateur. Maintenant, si un utilisateur existe dans l'authentification mais pas dans la table `users`, le système tentera de le créer automatiquement.

### Solution 3 : Prévention Future

Pour éviter ce problème à l'avenir, vous pouvez :

1. **Créer un trigger** qui synchronise automatiquement les utilisateurs
2. **Utiliser une fonction RPC** pour la création d'utilisateurs
3. **Améliorer la gestion d'erreurs** côté application

## Étapes de Résolution

### Étape 1 : Appliquer la Correction SQL

```sql
-- Exécuter dans l'éditeur SQL Supabase
INSERT INTO public.users (id, email, role, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  'user' as role,
  au.created_at,
  au.updated_at
FROM auth.users au
WHERE au.id = '14577c87-1336-476b-9747-aa16f8413bfe'
AND NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);
```

### Étape 2 : Vérifier la Correction

```sql
-- Vérifier que l'utilisateur existe maintenant
SELECT 
  id,
  email,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';
```

### Étape 3 : Tester l'Application

1. Rechargez votre application
2. Vérifiez que les boucles infinies ont disparu
3. Testez l'accès aux différentes fonctionnalités

## Vérification

Après avoir appliqué les corrections, vous devriez voir :

✅ **Console propre** : Plus de messages "Utilisateur non trouvé"
✅ **Fonctionnalités opérationnelles** : Accès aux clients, appareils, etc.
✅ **Performance normale** : Plus de boucles infinies de requêtes

## Erreurs Possibles

### Si l'insertion échoue

```sql
-- Vérifier les contraintes
SELECT 
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users';
```

### Si les politiques RLS bloquent l'accès

```sql
-- Vérifier les politiques RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'users';
```

## Maintenance

Pour éviter ce problème à l'avenir :

1. **Surveillez les logs** : Vérifiez régulièrement les erreurs d'authentification
2. **Testez les nouveaux utilisateurs** : Assurez-vous qu'ils sont créés dans les deux tables
3. **Utilisez des triggers** : Automatisez la synchronisation entre `auth.users` et `public.users`

## Support

Si le problème persiste après avoir appliqué ces corrections :

1. Vérifiez les logs de la console du navigateur
2. Contrôlez les politiques RLS dans Supabase
3. Testez avec un nouvel utilisateur pour isoler le problème
