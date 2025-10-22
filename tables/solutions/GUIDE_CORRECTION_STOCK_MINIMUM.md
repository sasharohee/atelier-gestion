# Guide de Correction : Stock Minimum à 1

## 🚨 Problème Identifié

**Symptôme :** Le stock minimum par défaut est défini à 5 dans l'interface de modification des produits, mais l'utilisateur souhaite qu'il soit à 1.

**Cause :** La valeur par défaut du stock minimum était définie à 5 dans plusieurs endroits du code et de la base de données.

## ✅ Solution Appliquée

### 1. **Modifications dans le Code Frontend**

#### Fichier `src/pages/Catalog/Products.tsx`
- ✅ Valeur par défaut du formulaire : `minStockLevel: 5` → `minStockLevel: 1`
- ✅ Valeur de fallback dans l'affichage : `|| 5` → `|| 1`
- ✅ Logique de comparaison pour les alertes de stock

#### Fichier `src/pages/Catalog/Parts.tsx`
- ✅ Valeur par défaut du formulaire : `minStockLevel: 5` → `minStockLevel: 1`
- ✅ Valeur de fallback dans l'affichage

#### Fichier `src/pages/Catalog/OutOfStock.tsx`
- ✅ Valeur de fallback : `product ? 5 : 0` → `product ? 1 : 0`

#### Fichier `src/services/demoDataService.ts`
- ✅ Données de démonstration : `minStockLevel: 5` → `minStockLevel: 1`

### 2. **Modifications dans la Base de Données**

#### Scripts SQL mis à jour :
- ✅ `tables/add_stock_to_products.sql` : `DEFAULT 5` → `DEFAULT 1`
- ✅ `tables/fix_products_table_quick.sql` : `DEFAULT 5` → `DEFAULT 1`
- ✅ `tables/correction_urgence_products.sql` : `DEFAULT 5` → `DEFAULT 1`
- ✅ `tables/correction_force_products.sql` : `DEFAULT 5` → `DEFAULT 1`

### 3. **Scripts de Correction Créés**

#### `tables/correction_stock_minimum_1.sql`
Script complet pour :
- Vérifier les produits actuels avec stock minimum = 5
- Mettre à jour tous les produits existants
- Modifier la valeur par défaut de la colonne
- Vérifier les résultats

#### `tables/correction_rapide_stock_minimum.sql`
Script rapide pour :
- Mettre à jour les produits avec stock minimum = 5
- Modifier la valeur par défaut
- Vérification rapide

## 🔧 Instructions d'Exécution

### Option 1 : Correction Rapide
1. **Ouvrir l'interface SQL de Supabase**
2. **Exécuter le script :**
   ```sql
   -- Copier et exécuter le contenu de tables/correction_rapide_stock_minimum.sql
   ```

### Option 2 : Correction Complète
1. **Ouvrir l'interface SQL de Supabase**
2. **Exécuter le script :**
   ```sql
   -- Copier et exécuter le contenu de tables/correction_stock_minimum_1.sql
   ```

## 📊 Vérification

Après l'exécution du script, vérifiez que :

1. **Nouveaux produits créés ont un stock minimum de 1**
2. **Produits existants mis à jour**
3. **Interface affiche correctement la valeur 1**

### Requête de vérification :
```sql
SELECT 
    name,
    min_stock_level,
    stock_quantity
FROM products 
ORDER BY name;
```

## 🎯 Résultat Attendu

Après la correction :
- ✅ **Nouveaux produits** : Stock minimum par défaut = 1
- ✅ **Produits existants** : Stock minimum mis à jour à 1
- ✅ **Interface** : Affichage correct du stock minimum
- ✅ **Alertes** : Seuils d'alerte basés sur la nouvelle valeur

## 📝 Notes Techniques

### Valeurs par défaut modifiées :
- **Frontend** : `minStockLevel: 1` (au lieu de 5)
- **Base de données** : `DEFAULT 1` (au lieu de 5)
- **Fallback** : `|| 1` (au lieu de `|| 5`)

### Impact sur les fonctionnalités :
- **Alertes de stock faible** : Déclenchées quand stock ≤ 1
- **Indicateurs visuels** : Rouge quand stock = 0, Orange quand stock ≤ 1
- **Nouveaux produits** : Stock minimum automatiquement à 1

### Compatibilité :
- ✅ **Rétrocompatible** : Les produits existants sont mis à jour
- ✅ **Cohérent** : Toutes les interfaces utilisent la même valeur
- ✅ **Persistant** : Changement permanent dans la base de données
