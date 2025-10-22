# Guide de Correction - Erreur d'Ambiguïté de Colonne

## Problème Identifié

L'erreur `column reference "id" is ambiguous` indique qu'il y a une ambiguïté dans la fonction SQL `upsert_brand` entre :
- Une variable PL/pgSQL `v_brand_id`
- Une colonne de table `id`

## Cause du Problème

Dans la fonction `upsert_brand`, nous avons :
```sql
DECLARE
    v_brand_id TEXT;  -- Variable PL/pgSQL
BEGIN
    -- ...
    RETURN QUERY
    SELECT 
        b.id,  -- Colonne de table
        -- ...
    FROM public.device_brands b
    WHERE b.id = v_brand_id;  -- Ambiguïté ici
```

PostgreSQL ne peut pas déterminer si `id` fait référence à la variable ou à la colonne.

## Solution

### 1. Exécuter le Script de Correction

Exécutez le fichier `fix_upsert_brand_ambiguous_column.sql` dans votre base de données Supabase.

Ce script :
- ✅ Supprime la fonction `upsert_brand` existante
- ✅ Recrée la fonction avec des alias explicites pour éviter l'ambiguïté
- ✅ Utilise des alias comme `brand_id`, `brand_name`, etc.
- ✅ Accorde les permissions nécessaires

### 2. Vérifier la Correction

Exécutez le fichier `test_upsert_brand_ambiguous_fix.sql` pour vérifier que :
- La fonction existe et est accessible
- Les alias explicites sont présents
- Les permissions sont correctes
- La fonction peut être testée

### 3. Tester la Fonctionnalité

1. **Testez la mise à jour d'une marque** depuis l'interface
2. **Testez l'ajout de catégories** à une marque
3. **Vérifiez que l'erreur d'ambiguïté a disparu** dans la console

## Changements Apportés

### Avant (Problématique)
```sql
RETURN QUERY
SELECT 
    b.id,           -- Ambiguïté possible
    b.name,         -- Ambiguïté possible
    b.description,  -- Ambiguïté possible
    -- ...
FROM public.device_brands b
WHERE b.id = v_brand_id;  -- Ambiguïté ici
```

### Après (Corrigé)
```sql
RETURN QUERY
SELECT 
    b.id as brand_id,           -- Alias explicite
    b.name as brand_name,       -- Alias explicite
    b.description as brand_description,  -- Alias explicite
    -- ...
FROM public.device_brands b
WHERE b.id = v_brand_id;  -- Plus d'ambiguïté
```

## Vérifications Post-Correction

### 1. Vérifier que la Fonction Existe
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';
```

### 2. Vérifier les Alias Explicites
```sql
SELECT routine_definition 
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';
```

### 3. Vérifier les Permissions
```sql
SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';
```

## Test de la Fonction

### Test Simple
```sql
-- Test avec des paramètres simples (nécessite une authentification)
SELECT * FROM public.upsert_brand(
    'test_brand_' || extract(epoch from now()), 
    'Test Brand', 
    'Description test', 
    '', 
    NULL
);
```

### Test avec Catégories
```sql
-- Test avec catégories (si des catégories existent)
SELECT * FROM public.upsert_brand(
    'test_brand_cat_' || extract(epoch from now()), 
    'Test Brand avec Catégories', 
    'Description test', 
    '', 
    ARRAY['category_id_1', 'category_id_2']
);
```

## Résolution des Erreurs Courantes

### Erreur d'Ambiguïté de Colonne
- **Cause**: Conflit entre variable PL/pgSQL et colonne de table
- **Solution**: Utiliser des alias explicites dans la requête

### Erreur de Permissions
- **Cause**: Permissions insuffisantes sur la fonction
- **Solution**: Vérifier que les permissions GRANT sont accordées

### Erreur d'Authentification
- **Cause**: Utilisateur non connecté
- **Solution**: Vérifier la session Supabase

## Résultat Attendu

Après l'exécution du script de correction :

1. ✅ L'erreur d'ambiguïté de colonne disparaît
2. ✅ La fonction `upsert_brand` fonctionne correctement
3. ✅ Les marques peuvent être mises à jour
4. ✅ Les catégories peuvent être ajoutées aux marques
5. ✅ Toutes les opérations de marque fonctionnent

## Fichiers de Correction

- **`fix_upsert_brand_ambiguous_column.sql`** - Script principal de correction
- **`test_upsert_brand_ambiguous_fix.sql`** - Script de vérification
- **`GUIDE_CORRECTION_AMBIGUITE_COLONNE.md`** - Ce guide de résolution

## Notes Importantes

- Le script supprime et recrée la fonction pour éviter les conflits
- Les alias explicites éliminent toute ambiguïté
- Les permissions sont automatiquement accordées
- La fonction conserve toutes ses fonctionnalités originales
- Aucune donnée n'est perdue lors de la correction
















