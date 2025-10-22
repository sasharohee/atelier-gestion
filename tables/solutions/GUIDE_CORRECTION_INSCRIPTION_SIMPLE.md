# 🔧 Guide de Correction - Erreur d'Inscription Supabase Auth

## 🚨 Problème Identifié

L'erreur `Database error saving new user` est causée par un trigger `handle_new_user` qui s'exécute lors de la création d'utilisateur dans Supabase Auth et qui échoue.

## ✅ Solution Simple

### Étape 1: Exécuter le Script de Correction SQL

1. **Ouvrir Supabase Dashboard**
   - Allez sur https://supabase.com/dashboard
   - Sélectionnez votre projet
   - Ouvrez l'onglet "SQL Editor"

2. **Exécuter le Script de Correction**
   - Copiez le contenu du fichier `fix_auth_registration_simple.sql`
   - Collez-le dans l'éditeur SQL
   - Cliquez sur "Run"

### Étape 2: Vérifier la Correction

Le script va :
- ✅ Supprimer le trigger problématique `handle_new_user`
- ✅ Supprimer la fonction problématique
- ✅ Permettre l'inscription normale via Supabase Auth

### Étape 3: Tester l'Inscription

1. Allez sur votre application
2. Essayez de créer un nouveau compte
3. L'inscription devrait maintenant fonctionner sans erreur 500

## 🔧 Modifications du Code

### Service d'Authentification Simplifié

Le fichier `src/services/supabaseService.ts` a été modifié pour :
- ✅ Utiliser uniquement Supabase Auth (pas de RPC)
- ✅ Gestion d'erreur claire
- ✅ Messages d'erreur spécifiques
- ✅ Inscription simple et directe

### Fonctionnement

1. **Inscription** : Utilise `supabase.auth.signUp()` uniquement
2. **Données utilisateur** : Stockées dans `raw_user_meta_data` de Supabase Auth
3. **Confirmation** : Email de confirmation envoyé automatiquement
4. **Connexion** : Utilise `supabase.auth.signInWithPassword()`

## 🧪 Test de Vérification

### Test 1: Inscription
```javascript
// Dans la console du navigateur, vérifiez :
// - Aucune erreur 500
// - Message de succès d'inscription
// - Email de confirmation envoyé
```

### Test 2: Vérification Base de Données
```sql
-- Vérifier que l'utilisateur a été créé dans auth.users
SELECT id, email, created_at, email_confirmed_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;
```

## ✅ Résultat Attendu

- ✅ Plus d'erreur "Database error saving new user"
- ✅ Inscription d'utilisateur fonctionnelle
- ✅ Email de confirmation envoyé
- ✅ Connexion fonctionnelle après confirmation

## 🆘 Si le Problème Persiste

### Diagnostic Rapide
```sql
-- Vérifier les triggers restants
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';
```

### Solution Alternative
Si l'erreur persiste, exécutez ce script de nettoyage complet :

```sql
-- Nettoyage complet des triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.on_auth_user_created();
```

## 📋 Résumé des Changements

1. **Script SQL** : `fix_auth_registration_simple.sql` - Supprime les triggers problématiques
2. **Code Frontend** : `src/services/supabaseService.ts` - Inscription simplifiée
3. **Résultat** : Inscription fonctionnelle avec Supabase Auth uniquement
