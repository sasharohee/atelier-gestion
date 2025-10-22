# Guide de Correction : Stock Minimum Modifiable

## 🚨 Problème Identifié

**Symptôme :** Le champ "Stock minimum (alerte)" dans le modal de modification des produits reste bloqué à 1 et ne peut pas être modifié.

**Cause :** Le champ `minStockLevel` n'était pas inclus dans les fonctions de mise à jour du service `productService`, ce qui empêchait sa modification dans la base de données.

## ✅ Solution Appliquée

### 1. **Correction du Service ProductService**

#### Fichier `src/services/supabaseService.ts`
- ✅ **Fonction `create`** : Ajout de `min_stock_level: product.minStockLevel`
- ✅ **Fonction `update`** : Ajout de `if (updates.minStockLevel !== undefined) dbUpdates.min_stock_level = updates.minStockLevel;`

### 2. **Correction des Valeurs par Défaut**

#### Fichiers Frontend :
- ✅ `src/pages/Catalog/Products.tsx` : Valeur par défaut `5` → `1`
- ✅ `src/pages/Catalog/Parts.tsx` : Valeur par défaut `5` → `1`
- ✅ `src/pages/Catalog/OutOfStock.tsx` : Valeur de fallback `5` → `1`

#### Fichier Store :
- ✅ `src/store/index.ts` : Toutes les références `|| 5` → `|| 1`

#### Fichiers SQL :
- ✅ Tous les scripts SQL : `DEFAULT 5` → `DEFAULT 1`

### 3. **Correction des Données de Démonstration**

#### Fichier `src/services/demoDataService.ts`
- ✅ Données de démonstration : `minStockLevel: 5` → `minStockLevel: 1`

## 🔧 Détails Techniques

### **Problème Principal Résolu**
```typescript
// AVANT (problématique)
async update(id: string, updates: Partial<Product>) {
  const dbUpdates: any = { updated_at: new Date().toISOString() };
  
  if (updates.name !== undefined) dbUpdates.name = updates.name;
  if (updates.description !== undefined) dbUpdates.description = updates.description;
  if (updates.category !== undefined) dbUpdates.category = updates.category;
  if (updates.price !== undefined) dbUpdates.price = updates.price;
  if (updates.stockQuantity !== undefined) dbUpdates.stock_quantity = updates.stockQuantity;
  // ❌ minStockLevel manquant !
  if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;
}

// APRÈS (corrigé)
async update(id: string, updates: Partial<Product>) {
  const dbUpdates: any = { updated_at: new Date().toISOString() };
  
  if (updates.name !== undefined) dbUpdates.name = updates.name;
  if (updates.description !== undefined) dbUpdates.description = updates.description;
  if (updates.category !== undefined) dbUpdates.category = updates.category;
  if (updates.price !== undefined) dbUpdates.price = updates.price;
  if (updates.stockQuantity !== undefined) dbUpdates.stock_quantity = updates.stockQuantity;
  if (updates.minStockLevel !== undefined) dbUpdates.min_stock_level = updates.minStockLevel; // ✅ Ajouté
  if (updates.isActive !== undefined) dbUpdates.is_active = updates.isActive;
}
```

### **Conversion camelCase → snake_case**
- **Frontend** : `minStockLevel` (camelCase)
- **Base de données** : `min_stock_level` (snake_case)
- **Service** : Conversion automatique entre les deux formats

## 🚀 Instructions de Test

### 1. **Tester la Modification**
1. Ouvrir la page Catalogue → Produits
2. Cliquer sur l'icône de modification d'un produit
3. Modifier la valeur "Stock minimum (alerte)"
4. Cliquer sur "Modifier"
5. Vérifier que la modification est sauvegardée

### 2. **Tester la Création**
1. Cliquer sur "Nouveau produit"
2. Remplir le formulaire avec un stock minimum personnalisé
3. Cliquer sur "Créer"
4. Vérifier que le produit est créé avec le bon stock minimum

### 3. **Vérifier la Persistance**
1. Recharger la page
2. Vérifier que les valeurs de stock minimum sont conservées

## 📊 Vérification

### **Requête SQL de vérification :**
```sql
SELECT 
    name,
    min_stock_level,
    stock_quantity
FROM products 
ORDER BY name;
```

### **Vérifications dans l'interface :**
- ✅ Le champ "Stock minimum (alerte)" est modifiable
- ✅ Les modifications sont sauvegardées
- ✅ Les nouvelles valeurs persistent après rechargement
- ✅ Les alertes de stock utilisent la nouvelle valeur

## 🎯 Résultat Attendu

Après la correction :
- ✅ **Modification possible** : Le champ stock minimum peut être modifié
- ✅ **Sauvegarde fonctionnelle** : Les modifications sont enregistrées en base
- ✅ **Valeur par défaut** : Nouveaux produits avec stock minimum = 1
- ✅ **Cohérence** : Toutes les interfaces utilisent la même logique
- ✅ **Alertes** : Les alertes de stock faible basées sur la valeur personnalisée

## 📝 Notes Techniques

### **Champs concernés :**
- `minStockLevel` (frontend)
- `min_stock_level` (base de données)

### **Fonctions corrigées :**
- `productService.create()`
- `productService.update()`
- `loadProducts()` dans le store
- `addProduct()` dans le store
- `updateProduct()` dans le store

### **Compatibilité :**
- ✅ **Rétrocompatible** : Les produits existants conservent leurs valeurs
- ✅ **Cohérent** : Toutes les interfaces utilisent la même logique
- ✅ **Persistant** : Les modifications sont sauvegardées définitivement
