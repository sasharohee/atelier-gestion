# 🔧 Correction de l'erreur "Database error saving new user"

## ❌ Problème identifié
L'erreur `AuthApiError: Database error saving new user` indique un problème avec le trigger de création d'utilisateur dans Supabase.

## 🎯 Cause probable
Le trigger `handle_new_user` qui s'exécute après l'inscription d'un nouvel utilisateur dans `auth.users` rencontre une erreur lors de la création des enregistrements dans les tables `public.users`, `public.user_profiles`, et `public.user_preferences`.

## ✅ Solution

### 1. Exécuter le script de diagnostic
```sql
-- Exécuter le fichier: diagnostic_erreur_creation_utilisateur.sql
-- Ce script va identifier la cause exacte du problème
```

### 2. Appliquer la correction
```sql
-- Exécuter le fichier: correction_trigger_creation_utilisateur.sql
-- Ce script va:
-- - Supprimer le trigger problématique
-- - Créer une nouvelle fonction plus robuste
-- - Recréer le trigger avec gestion d'erreur
-- - Tester la correction
```

## 📋 Étapes détaillées

### Étape 1: Accéder au SQL Editor Supabase
1. Aller sur https://supabase.com/dashboard
2. Sélectionner le projet **atelier-gestion**
3. Cliquer sur **SQL Editor** dans le menu de gauche

### Étape 2: Exécuter le diagnostic
1. Copier le contenu de `diagnostic_erreur_creation_utilisateur.sql`
2. Coller dans l'éditeur SQL
3. Cliquer sur **Run** pour exécuter
4. Analyser les résultats pour identifier le problème

### Étape 3: Appliquer la correction
1. Copier le contenu de `correction_trigger_creation_utilisateur.sql`
2. Coller dans l'éditeur SQL
3. Cliquer sur **Run** pour exécuter
4. Vérifier que le test de fin s'exécute correctement

## 🧪 Test de la correction

### Test 1: Création d'un nouveau compte
1. Aller sur https://atelier-gestion-app.vercel.app
2. Créer un nouveau compte utilisateur
3. Vérifier que l'inscription se termine sans erreur

### Test 2: Vérification des données
```sql
-- Vérifier que l'utilisateur a été créé dans toutes les tables
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    up.user_id as profile_exists,
    upref.user_id as preferences_exist
FROM public.users u
LEFT JOIN public.user_profiles up ON u.id = up.user_id
LEFT JOIN public.user_preferences upref ON u.id = upref.user_id
ORDER BY u.created_at DESC
LIMIT 5;
```

## 🔍 Améliorations apportées

### Nouvelle fonction `handle_new_user`
- ✅ Gestion d'erreur robuste avec `EXCEPTION`
- ✅ Vérification de l'existence avant insertion
- ✅ Logs d'erreur détaillés
- ✅ Ne fait pas échouer l'inscription en cas d'erreur

### Fonctionnalités
- ✅ Création automatique dans `public.users`
- ✅ Création automatique dans `public.user_profiles`
- ✅ Création automatique dans `public.user_preferences`
- ✅ Gestion des doublons
- ✅ Timestamps automatiques

## 🚨 En cas de problème persistant

### Vérifier les logs
```sql
-- Vérifier les erreurs récentes
SELECT 
    log_time,
    message
FROM pg_stat_activity 
WHERE state = 'active' 
AND query LIKE '%users%'
ORDER BY log_time DESC
LIMIT 10;
```

### Vérifier les permissions
```sql
-- Vérifier les permissions sur les tables
SELECT 
    grantee,
    privilege_type,
    table_name
FROM information_schema.role_table_grants 
WHERE table_name IN ('users', 'user_profiles', 'user_preferences')
AND table_schema = 'public';
```

## 📞 Support
Si le problème persiste après l'application de cette correction :
1. Vérifier les logs d'erreur dans Supabase
2. Tester avec un nouvel email
3. Vérifier la configuration RLS
4. Contacter le support si nécessaire

---
**Note** : Cette correction garantit que l'inscription d'utilisateur fonctionne correctement même en cas d'erreur dans les triggers.
