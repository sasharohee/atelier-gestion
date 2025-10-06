# Guide de Correction - Erreur upsert_brand

## Problème Identifié

L'erreur `POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/rpc/upsert_brand 404 (Not Found)` indique que la fonction RPC `upsert_brand` n'existe pas dans la base de données ou n'est pas accessible.

L'erreur `operator does not exist: uuid = text` indique un problème de type entre UUID et TEXT dans les paramètres de la fonction.

## Solution

### 1. Exécuter le Script de Correction

Exécutez le fichier `fix_upsert_brand_final.sql` dans votre base de données Supabase pour :

- Créer la fonction `upsert_brand` avec les bons types
- Créer la fonction `upsert_brand_simple` comme fallback
- Créer la fonction `create_brand_basic` comme dernier recours
- Accorder les permissions nécessaires

### 2. Vérifier les Types de Données

Assurez-vous que les colonnes suivantes ont les bons types :

```sql
-- device_brands.id doit être de type TEXT
-- brand_categories.brand_id doit être de type TEXT
-- brand_categories.category_id doit être de type UUID
```

### 3. Tester les Fonctions

Utilisez le fichier `test_upsert_brand_fix.sql` pour vérifier que les fonctions existent et sont accessibles.

### 4. Tester depuis le Frontend

Utilisez le fichier `test_brand_service_fix.js` pour tester les appels RPC depuis le frontend.

## Fonctions Créées

### upsert_brand
- **Paramètres**: `p_id TEXT, p_name TEXT, p_description TEXT, p_logo TEXT, p_category_ids TEXT[]`
- **Retour**: Table avec les informations de la marque et ses catégories
- **Usage**: Création et mise à jour complète des marques

### upsert_brand_simple
- **Paramètres**: `p_id TEXT, p_name TEXT, p_description TEXT, p_logo TEXT`
- **Retour**: JSON avec les informations de la marque
- **Usage**: Création simple sans gestion des catégories

### create_brand_basic
- **Paramètres**: `p_id TEXT, p_name TEXT, p_description TEXT, p_logo TEXT`
- **Retour**: JSON avec les informations de la marque
- **Usage**: Création basique sans mise à jour

### update_brand_categories
- **Paramètres**: `p_brand_id TEXT, p_category_ids TEXT[]`
- **Retour**: JSON avec le statut de l'opération
- **Usage**: Mise à jour des catégories d'une marque

## Ordre de Fallback dans brandService.ts

Le service utilise un système de fallback :

1. **upsert_brand** (fonction complète)
2. **upsert_brand_simple** (si la première échoue)
3. **create_brand_basic** (dernier recours)

## Vérifications Post-Correction

1. Vérifiez que les fonctions existent dans la base de données
2. Testez la création d'une marque depuis l'interface
3. Testez l'ajout de catégories à une marque
4. Vérifiez que les données sont correctement sauvegardées

## Commandes de Vérification

```sql
-- Vérifier que les fonctions existent
SELECT routine_name FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
AND routine_schema = 'public';

-- Vérifier les types des colonnes
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories')
AND column_name IN ('id', 'brand_id', 'category_id')
AND table_schema = 'public';
```

## Résolution des Erreurs Courantes

### Erreur 404 (Not Found)
- La fonction n'existe pas → Exécuter le script de correction
- Permissions insuffisantes → Vérifier les permissions GRANT

### Erreur de Type (uuid = text)
- Types de colonnes incorrects → Vérifier et corriger les types
- Paramètres incorrects → Utiliser TEXT[] au lieu de UUID[]

### Erreur d'Authentification
- Utilisateur non connecté → Vérifier la session Supabase
- Fonction non accessible → Vérifier les permissions SECURITY DEFINER



