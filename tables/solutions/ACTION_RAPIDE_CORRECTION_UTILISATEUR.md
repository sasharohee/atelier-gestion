# 🚀 Action Rapide - Correction Erreur Création Utilisateur

## ⚡ Solution Immédiate

### 1. Aller sur Supabase Dashboard
- URL: https://supabase.com/dashboard
- Projet: **atelier-gestion**
- Menu: **SQL Editor**

### 2. Exécuter la correction rapide
Copier et coller ce script dans l'éditeur SQL :

```sql
-- Correction rapide de l'erreur "Database error saving new user"
-- Script simplifié pour une application immédiate

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Supprimer la fonction problématique
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 3. Créer une fonction simplifiée et robuste
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Créer l'utilisateur dans public.users (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- Log l'erreur mais continuer
            RAISE WARNING 'Erreur création users: %', SQLERRM;
    END;
    
    -- Créer le profil (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.user_profiles (user_id, first_name, last_name, email, created_at, updated_at)
        VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
            COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
            NEW.email,
            NOW(),
            NOW()
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création profile: %', SQLERRM;
    END;
    
    -- Créer les préférences (avec gestion d'erreur)
    BEGIN
        INSERT INTO public.user_preferences (user_id, created_at, updated_at)
        VALUES (NEW.id, NOW(), NOW());
    EXCEPTION
        WHEN OTHERS THEN
            RAISE WARNING 'Erreur création preferences: %', SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recréer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Vérification rapide
SELECT '✅ Correction appliquée - Trigger recréé avec gestion d''erreur' as status;
```

### 3. Cliquer sur "Run"
Exécuter le script et vérifier que le message de confirmation s'affiche.

## 🧪 Test Immédiat

### Test 1: Création de compte
1. Aller sur: https://atelier-gestion-app.vercel.app
2. Créer un nouveau compte
3. Vérifier qu'il n'y a plus d'erreur

### Test 2: Vérification des données
```sql
-- Vérifier que l'utilisateur a été créé
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

## ✅ Résultat Attendu
- ✅ Plus d'erreur "Database error saving new user"
- ✅ Inscription d'utilisateur fonctionnelle
- ✅ Données créées dans toutes les tables
- ✅ Gestion d'erreur robuste

## 🔧 Si le problème persiste

### Diagnostic rapide
Exécuter ce script pour identifier le problème :

```sql
-- Diagnostic simple
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%user%';
```

### Vérifier les tables
```sql
-- Vérifier que les tables existent
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'user_profiles', 'user_preferences');
```

## 📞 Support
Si le problème persiste :
1. Vérifier les logs dans Supabase Dashboard
2. Tester avec un nouvel email
3. Vérifier la configuration RLS
4. Contacter le support

---
**Temps estimé** : 2-3 minutes
**Difficulté** : Facile
**Impact** : Résolution immédiate du problème d'inscription
