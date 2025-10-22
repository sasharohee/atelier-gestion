# Guide de Création de la Vue brand_with_categories

## 🚨 Problème
L'erreur `404 (Not Found)` pour `brand_with_categories` indique que cette vue n'existe pas dans la base de données de production.

## ✅ Solution

### Étape 1: Accéder au Dashboard Supabase
1. Aller sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Se connecter avec votre compte
3. Sélectionner le projet **atelier-gestion** (production)

### Étape 2: Ouvrir l'Éditeur SQL
1. Dans le menu de gauche, cliquer sur **SQL Editor**
2. Cliquer sur **New query**

### Étape 3: Exécuter le Script SQL
Copier et coller le script suivant dans l'éditeur SQL :

```sql
-- Script pour créer la vue brand_with_categories manquante
-- Supprimer la vue si elle existe déjà
DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

-- Créer la vue brand_with_categories
CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.user_id,
    db.created_by,
    db.updated_by,
    db.created_at,
    db.updated_at,
    COALESCE(
        JSON_AGG(
            JSON_BUILD_OBJECT(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands db
LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.updated_by, db.created_at, db.updated_at;

-- Configurer la sécurité de la vue
ALTER VIEW public.brand_with_categories SET (security_invoker = true);

-- Tester la vue
SELECT 'Vue créée avec succès' as status;
SELECT COUNT(*) as total_brands FROM public.brand_with_categories;
```

### Étape 4: Exécuter le Script
1. Cliquer sur **Run** pour exécuter le script
2. Vérifier que le message "Vue créée avec succès" apparaît
3. Vérifier que le nombre de marques est affiché

### Étape 5: Vérifier la Création
Exécuter cette requête pour vérifier que la vue existe :

```sql
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE viewname = 'brand_with_categories'
AND schemaname = 'public';
```

## 🧪 Test de la Vue

### Test 1: Vérifier l'existence
```sql
SELECT * FROM public.brand_with_categories LIMIT 5;
```

### Test 2: Vérifier les politiques RLS
```sql
SELECT * FROM pg_policies WHERE tablename = 'brand_with_categories';
```

## 🔧 Configuration RLS (si nécessaire)

Si les politiques RLS ne sont pas automatiquement appliquées, exécuter :

```sql
-- Activer RLS sur les tables sous-jacentes
ALTER TABLE public.device_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_categories ENABLE ROW LEVEL SECURITY;

-- Créer les politiques pour device_brands
CREATE POLICY "Users can view their own brands" ON public.device_brands
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own brands" ON public.device_brands
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own brands" ON public.device_brands
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own brands" ON public.device_brands
    FOR DELETE USING (auth.uid() = user_id);
```

## ✅ Vérification Finale

Après avoir créé la vue :

1. **Redémarrer l'application** : `npm run dev`
2. **Ouvrir la console du navigateur** (F12)
3. **Vérifier qu'il n'y a plus d'erreur 404** pour `brand_with_categories`
4. **Tester la fonctionnalité** de gestion des marques

## 📊 Résultat Attendu

- ✅ Plus d'erreur 404 dans la console
- ✅ La vue `brand_with_categories` est accessible
- ✅ Les marques s'affichent correctement
- ✅ L'isolation par utilisateur fonctionne

## 🆘 En Cas de Problème

Si la vue ne se crée pas :

1. **Vérifier les permissions** : S'assurer d'être connecté avec un compte admin
2. **Vérifier les tables** : S'assurer que `device_brands`, `brand_categories`, et `device_categories` existent
3. **Vérifier les contraintes** : S'assurer que les clés étrangères sont correctement définies

## 📝 Notes Importantes

- Cette vue est essentielle pour la fonctionnalité de gestion des marques
- Elle permet de récupérer les marques avec leurs catégories associées
- Elle respecte l'isolation par utilisateur (RLS)
- Elle est utilisée par plusieurs services de l'application
