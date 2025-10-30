# Migration: Ajout des sous-catégories de produits

## Vue d'ensemble

Cette migration ajoute un système de sous-catégories pour les produits, permettant une organisation à 3 niveaux :
- Type (Produits/Services/Pièces) → Catégorie → Sous-catégorie → Produits

## Fichiers créés/modifiés

### Base de données
- `table/migrations/add_product_subcategory.sql` - Migration SQL pour ajouter la colonne subcategory

### Types TypeScript
- `src/types/index.ts` - Ajout du champ `subcategory?: string` à l'interface Product

### Composants React
- `src/components/ProductCategoryButtons.tsx` - Navigation à 3 niveaux pour les produits
- `src/components/QuickCreateItemDialog.tsx` - Ajout du champ sous-catégorie avec autocomplete
- `src/components/SimplifiedSalesDialog.tsx` - Transmission des données de sous-catégorie
- `src/pages/Catalog/Products.tsx` - Formulaire de création/édition avec sous-catégorie

## Exécution de la migration

Pour exécuter la migration SQL dans Supabase :

```sql
-- Migration pour ajouter la colonne subcategory à la table products
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS subcategory TEXT;

-- Ajouter un commentaire descriptif
COMMENT ON COLUMN public.products.subcategory IS 'Optional subcategory for organizing products within a category';

-- Vérifier que la colonne a été ajoutée
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products' 
AND column_name = 'subcategory';
```

## Fonctionnalités

### Navigation dans les ventes simplifiées
1. Cliquer sur "Produits" affiche la liste des sous-catégories
2. Cliquer sur une sous-catégorie affiche les produits de cette sous-catégorie
3. Les produits sans sous-catégorie sont regroupés dans "Non catégorisé"

### Création de produits
- Autocomplete avec les sous-catégories existantes
- Possibilité de créer une nouvelle sous-catégorie à la volée
- Fonctionne dans le catalogue et dans la vente simplifiée

### Compatibilité
- Champ nullable : les produits existants sans sous-catégorie continuent de fonctionner
- Services et pièces : ne sont pas affectés par cette fonctionnalité
- Navigation existante pour services/pièces : inchangée

## Tests recommandés

1. Créer un produit sans sous-catégorie → doit apparaître dans "Non catégorisé"
2. Créer un produit avec sous-catégorie → doit créer/ajouter la sous-catégorie
3. Modifier un produit existant → doit conserver sa sous-catégorie
4. Navigation dans les ventes → doit afficher correctement les 3 niveaux
5. Recherche de produits → doit fonctionner avec ou sans sous-catégorie

