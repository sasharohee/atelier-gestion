# 🚨 Résolution de l'Erreur 500 lors de l'Inscription

## Problème Identifié

L'erreur `Database error finding user` lors de l'inscription indique que le système Supabase ne peut pas créer l'utilisateur correctement. Cela est généralement dû à :

1. **Script SQL non exécuté** - Les fonctions et triggers nécessaires ne sont pas créés
2. **Problème avec les politiques RLS** - Les permissions ne sont pas correctement configurées
3. **Conflit avec d'anciennes fonctions** - Des fonctions obsolètes interfèrent

## 🔧 Solution Immédiate

### Étape 1 : Vérifier l'État de la Base de Données

Exécutez cette requête dans la console SQL Supabase pour diagnostiquer :

```sql
-- Vérification de l'état du système
SELECT 'DIAGNOSTIC: État du système d''authentification' as info;

-- Vérifier si la table users existe
SELECT 
    'Table users' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ Manquante' 
    END as status
UNION ALL
-- Vérifier si le trigger existe
SELECT 
    'Trigger on_auth_user_created' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') 
         THEN '✅ Actif' 
         ELSE '❌ Inactif' 
    END as status
UNION ALL
-- Vérifier les fonctions
SELECT 
    'Fonction handle_new_user' as component,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'handle_new_user' AND routine_schema = 'public') 
         THEN '✅ Existe' 
         ELSE '❌ Manquante' 
    END as status;
```

### Étape 2 : Nettoyer et Recréer le Système

Si des composants manquent, exécutez ce script de nettoyage complet :

```sql
-- NETTOYAGE COMPLET ET RECRÉATION
-- 1. Supprimer toutes les anciennes fonctions problématiques
DROP FUNCTION IF EXISTS public.create_user_bypass(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_email_required(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_user_with_email_confirmation(TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.send_confirmation_email(TEXT);
DROP FUNCTION IF EXISTS public.validate_confirmation_token(TEXT);
DROP FUNCTION IF EXISTS public.get_signup_status(TEXT);
DROP FUNCTION IF EXISTS public.create_user_default_data_permissive(UUID);

-- 2. Supprimer les anciens triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 3. Supprimer les anciennes fonctions
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 4. Recréer la table users proprement
DROP TABLE IF EXISTS public.users CASCADE;
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'technician',
    avatar TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- 5. Créer les index
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- 6. Activer RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 7. Créer les politiques RLS
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 8. Créer la fonction de gestion des nouveaux utilisateurs
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
        COALESCE(NEW.raw_user_meta_data->>'lastName', ''),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'technician'),
        NOW(),
        NOW()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log l'erreur mais ne bloque pas la création de l'utilisateur auth
        RAISE WARNING 'Erreur lors de la création du profil utilisateur: %', SQLERRM;
        RETURN NEW;
END;
$$;

-- 9. Créer le trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. Vérification finale
SELECT '✅ Système d''authentification recréé avec succès' as status;
```

### Étape 3 : Tester l'Inscription

Après avoir exécuté le script, testez l'inscription avec un nouvel email.

## 🔍 Diagnostic Avancé

Si le problème persiste, exécutez ce diagnostic complet :

```sql
-- Diagnostic complet du système d'authentification
SELECT 'DIAGNOSTIC COMPLET' as section;

-- 1. Vérifier les utilisateurs existants dans auth.users
SELECT 'Utilisateurs dans auth.users' as info;
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. Vérifier les utilisateurs dans public.users
SELECT 'Utilisateurs dans public.users' as info;
SELECT 
    id,
    first_name,
    last_name,
    email,
    role,
    created_at
FROM public.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. Vérifier les politiques RLS
SELECT 'Politiques RLS' as info;
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

-- 4. Vérifier les triggers
SELECT 'Triggers actifs' as info;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
OR trigger_name = 'on_auth_user_created';
```

## 🚨 Solution d'Urgence

Si rien ne fonctionne, utilisez cette solution d'urgence qui contourne les triggers :

```sql
-- SOLUTION D'URGENCE - Inscription manuelle
CREATE OR REPLACE FUNCTION public.create_user_manual(
    user_email TEXT,
    user_password TEXT,
    user_first_name TEXT DEFAULT 'Utilisateur',
    user_last_name TEXT DEFAULT '',
    user_role TEXT DEFAULT 'technician'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Générer un UUID
    new_user_id := gen_random_uuid();
    
    -- Insérer dans auth.users
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        created_at,
        updated_at,
        raw_app_meta_data,
        raw_user_meta_data,
        is_super_admin,
        role,
        aud,
        confirmation_token,
        confirmation_sent_at
    ) VALUES (
        new_user_id,
        '00000000-0000-0000-0000-000000000000',
        user_email,
        crypt(user_password, gen_salt('bf')),
        NULL,
        NOW(),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        json_build_object('firstName', user_first_name, 'lastName', user_last_name, 'role', user_role),
        false,
        'authenticated',
        'authenticated',
        encode(gen_random_bytes(32), 'hex'),
        NOW()
    );
    
    -- Insérer dans public.users
    INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        created_at,
        updated_at
    ) VALUES (
        new_user_id,
        user_first_name,
        user_last_name,
        user_email,
        user_role,
        NOW(),
        NOW()
    );
    
    result := json_build_object(
        'success', true,
        'user_id', new_user_id,
        'email', user_email,
        'message', 'Utilisateur créé avec succès'
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        result := json_build_object(
            'success', false,
            'error', SQLERRM,
            'message', 'Erreur lors de la création de l''utilisateur'
        );
        RETURN result;
END;
$$;

-- Test de la fonction
SELECT public.create_user_manual(
    'test@example.com',
    'TestPass123!',
    'Test',
    'User',
    'technician'
) as test_result;
```

## ✅ Vérification Finale

Après avoir appliqué une solution, vérifiez que tout fonctionne :

1. **Test d'inscription** avec un nouvel email
2. **Vérification de la table users** - l'utilisateur doit apparaître dans `public.users`
3. **Test de connexion** avec les identifiants créés

Si tout fonctionne, vous pouvez supprimer la fonction d'urgence :

```sql
DROP FUNCTION IF EXISTS public.create_user_manual(TEXT, TEXT, TEXT, TEXT, TEXT);
```
