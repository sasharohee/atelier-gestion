# Guide de Correction : Seuils Minimum dans les Ruptures

## 🚨 Problème Identifié

**Symptôme :** Dans la page "Ruptures de stock", la colonne "Seuil minimum" affiche toujours 1 pour tous les produits, même si les vrais seuils minimum sont différents.

**Cause :** Dans le fichier `src/pages/Catalog/OutOfStock.tsx`, la logique d'affichage utilisait une valeur fixe de 1 au lieu de récupérer la vraie valeur `product.minStockLevel`.

## ✅ Solution Appliquée

### **Correction du Code Frontend**

#### Fichier `src/pages/Catalog/OutOfStock.tsx`
- ✅ **Ligne 210** : Correction de la logique d'affichage du seuil minimum

```typescript
// AVANT (problématique)
{part ? part.minStockLevel : product ? 1 : 0}

// APRÈS (corrigé)
{part ? part.minStockLevel : product ? product.minStockLevel : 0}
```

### **Script de Vérification SQL**

#### Fichier `tables/verification_seuils_ruptures.sql`
- ✅ Vérification des données actuelles dans la base
- ✅ Identification des produits et pièces en alerte
- ✅ Correction des seuils minimum incorrects
- ✅ Statistiques finales

## 🔧 Détails Techniques

### **Problème Principal**
La page des ruptures de stock affichait une valeur fixe de 1 pour tous les produits au lieu d'utiliser la vraie valeur du seuil minimum stockée en base de données.

### **Logique d'Affichage Corrigée**
```typescript
// Logique pour afficher le seuil minimum
{part ? part.minStockLevel : product ? product.minStockLevel : 0}
```

Cette logique :
- Affiche `part.minStockLevel` pour les pièces détachées
- Affiche `product.minStockLevel` pour les produits (au lieu de 1)
- Affiche 0 si aucun des deux n'est trouvé

## 🚀 Instructions de Test

### 1. **Vérifier l'Affichage**
1. Aller sur la page "Catalogue → Ruptures de stock"
2. Vérifier que la colonne "Seuil minimum" affiche les vraies valeurs
3. Comparer avec les valeurs dans la page "Produits" ou "Pièces détachées"

### 2. **Tester avec Différents Seuils**
1. Modifier le seuil minimum d'un produit (dans Catalogue → Produits)
2. Aller sur la page "Ruptures de stock"
3. Vérifier que le nouveau seuil s'affiche correctement

### 3. **Vérifier la Cohérence**
1. Créer un produit avec un seuil minimum de 5
2. Mettre le stock à 3
3. Vérifier qu'une alerte "Stock faible" apparaît
4. Vérifier que le seuil affiché est bien 5

## 📊 Vérification

### **Requête SQL de vérification :**
```sql
SELECT 
    name,
    stock_quantity,
    min_stock_level,
    CASE 
        WHEN stock_quantity <= 0 THEN 'RUPTURE'
        WHEN stock_quantity <= min_stock_level THEN 'STOCK FAIBLE'
        ELSE 'STOCK OK'
    END as statut_stock
FROM products 
ORDER BY name;
```

### **Vérifications dans l'interface :**
- ✅ La colonne "Seuil minimum" affiche les vraies valeurs
- ✅ Les seuils correspondent aux valeurs définies dans les produits
- ✅ Les alertes sont cohérentes avec les seuils affichés
- ✅ Les modifications de seuils se reflètent dans les ruptures

## 🎯 Résultat Attendu

Après la correction :
- ✅ **Affichage correct** : Les vrais seuils minimum s'affichent
- ✅ **Cohérence** : Les valeurs correspondent à celles définies dans les produits
- ✅ **Fiabilité** : Les alertes sont basées sur les bonnes valeurs
- ✅ **Maintenabilité** : Les modifications de seuils se reflètent immédiatement

## 📝 Notes Techniques

### **Fichiers concernés :**
- `src/pages/Catalog/OutOfStock.tsx` : Affichage des seuils
- `src/store/index.ts` : Génération des alertes de stock
- `tables/verification_seuils_ruptures.sql` : Vérification des données

### **Logique de génération des alertes :**
Les alertes sont générées dans le store avec la logique :
```typescript
if (product.stockQuantity <= (product.minStockLevel || 1)) {
  // Créer une alerte de stock faible
}
```

### **Compatibilité :**
- ✅ **Rétrocompatible** : Les alertes existantes continuent de fonctionner
- ✅ **Cohérent** : L'affichage correspond aux données réelles
- ✅ **Persistant** : Les modifications sont sauvegardées en base
