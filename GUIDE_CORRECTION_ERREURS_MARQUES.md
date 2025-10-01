# Guide de Correction des Erreurs de Marques

## Problèmes Identifiés

D'après les logs d'erreur, deux problèmes principaux ont été identifiés :

1. **Erreur 404 - Vue `brand_with_categories` manquante**
   ```
   Could not find the table 'public.brand_with_categories' in the schema cache
   ```

2. **Erreur 404 - Fonction `upsert_brand` manquante**
   ```
   Could not find the function public.upsert_brand(p_…iption, p_id, p_logo, p_name) in the schema cache
   ```

## Solution

### 1. Exécuter le Script de Correction des Types (Si nécessaire)

Si vous obtenez l'erreur `operator does not exist: uuid = text`, exécutez d'abord ce script :

```sql
-- Copiez et collez le contenu de FIX_TYPE_MISMATCH.sql dans l'éditeur SQL de Supabase
```

### 2. Exécuter le Script Rapide (Si nécessaire)

Si vous obtenez l'erreur `relation "public.brand_categories" does not exist`, exécutez ce script :

```sql
-- Copiez et collez le contenu de CREATE_MISSING_TABLES.sql dans l'éditeur SQL de Supabase
```

### 3. Exécuter le Script Complet de Correction

Ensuite, exécutez le script SQL `FIX_BRAND_ERRORS.sql` dans votre base de données Supabase :

```sql
-- Copiez et collez le contenu de FIX_BRAND_ERRORS.sql dans l'éditeur SQL de Supabase
```

### 4. Vérifier les Corrections

Exécutez le script de vérification `VERIFY_BRAND_FIXES.sql` pour confirmer que tout a été créé correctement :

```sql
-- Copiez et collez le contenu de VERIFY_BRAND_FIXES.sql dans l'éditeur SQL de Supabase
```

## Ce que le Script Fait

### 1. Création de la Vue `brand_with_categories`

La vue combine les données des tables :
- `device_brands` : Informations sur les marques
- `brand_categories` : Associations marques-catégories  
- `device_categories` : Informations sur les catégories

```sql
CREATE VIEW public.brand_with_categories AS
SELECT 
    b.id,
    b.name,
    b.description,
    b.logo,
    b.is_active,
    b.user_id,
    b.created_at,
    b.updated_at,
    COALESCE(
        json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon,
                'is_active', dc.is_active,
                'created_at', dc.created_at,
                'updated_at', dc.updated_at
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands b
LEFT JOIN public.brand_categories bc ON b.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY b.id, b.name, b.description, b.logo, b.is_active, b.user_id, b.created_at, b.updated_at;
```

### 2. Création de la Fonction `upsert_brand`

Cette fonction permet de créer ou mettre à jour une marque avec ses catégories associées :

```sql
CREATE OR REPLACE FUNCTION public.upsert_brand(
    p_id TEXT,
    p_name TEXT,
    p_description TEXT DEFAULT '',
    p_logo TEXT DEFAULT '',
    p_category_ids TEXT[] DEFAULT NULL
)
```

### 3. Création de la Fonction `update_brand_categories`

Cette fonction permet de mettre à jour uniquement les catégories d'une marque :

```sql
CREATE OR REPLACE FUNCTION public.update_brand_categories(
    p_brand_id TEXT,
    p_category_ids TEXT[]
)
```

### 4. Configuration de la Sécurité

- Activation de RLS (Row Level Security) sur les tables
- Création des politiques de sécurité
- Attribution des permissions appropriées

## Résultat Attendu

Après l'exécution des scripts, les erreurs suivantes devraient être résolues :

✅ **Avant** : `Could not find the table 'public.brand_with_categories'`
✅ **Après** : La vue est accessible et retourne les données correctement

✅ **Avant** : `Could not find the function public.upsert_brand`
✅ **Après** : La fonction est disponible et permet la création/mise à jour des marques

## Test de Fonctionnement

1. **Test de la vue** : Vérifiez que `brandService.getAll()` ne génère plus d'erreur 404
2. **Test de création** : Créez une nouvelle marque dans l'interface
3. **Test de mise à jour** : Modifiez une marque existante

## En Cas de Problème

Si des erreurs persistent après l'exécution des scripts :

1. Vérifiez que vous êtes connecté en tant qu'utilisateur authentifié
2. Vérifiez que les tables `device_brands`, `brand_categories`, et `device_categories` existent
3. Exécutez le script de vérification pour identifier les éléments manquants
4. Vérifiez les logs de la console pour d'autres erreurs

## Fichiers Fournis

- `FIX_TYPE_MISMATCH.sql` : Script pour corriger les incompatibilités de types
- `CREATE_MISSING_TABLES.sql` : Script rapide pour créer les tables manquantes
- `FIX_BRAND_ERRORS.sql` : Script principal de correction (inclut maintenant la création des tables)
- `VERIFY_BRAND_FIXES.sql` : Script de vérification
- `GUIDE_CORRECTION_ERREURS_MARQUES.md` : Ce guide d'utilisation

## Ordre d'Exécution Recommandé

1. **Si erreur de types** : `FIX_TYPE_MISMATCH.sql` (corrige uuid = text)
2. **Si tables manquantes** : `CREATE_MISSING_TABLES.sql` (crée les tables)
3. **Ensuite** : `FIX_BRAND_ERRORS.sql` (script complet)
4. **Enfin** : `VERIFY_BRAND_FIXES.sql` (vérification)

## Erreurs Communes et Solutions

- **`operator does not exist: uuid = text`** → Exécutez `FIX_TYPE_MISMATCH.sql`
- **`relation "public.brand_categories" does not exist`** → Exécutez `CREATE_MISSING_TABLES.sql`
- **`Could not find the table 'public.brand_with_categories'`** → Exécutez `FIX_BRAND_ERRORS.sql`
- **`Could not find the function public.upsert_brand`** → Exécutez `FIX_BRAND_ERRORS.sql`

## Support

Si vous rencontrez des difficultés, vérifiez :
1. Les permissions de votre utilisateur Supabase
2. La structure existante de votre base de données
3. Les logs d'erreur dans la console du navigateur
