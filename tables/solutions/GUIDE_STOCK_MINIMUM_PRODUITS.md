# Guide - Stock Minimum pour les Produits

## 🎯 Nouvelle Fonctionnalité

**Stock Minimum** : Possibilité de définir un seuil d'alerte pour chaque produit afin d'être notifié quand le stock devient faible.

## ✅ Fonctionnalités Ajoutées

### 1. **Champ de Saisie**
- ✅ **Champ "Stock minimum (alerte)"** dans le formulaire de création/édition
- ✅ **Valeur par défaut** : 5 unités
- ✅ **Validation** : Nombre positif uniquement
- ✅ **Aide contextuelle** : "Seuil d'alerte quand le stock devient faible"

### 2. **Affichage dans le Tableau**
- ✅ **Nouvelle colonne "Stock Min."** dans le tableau des produits
- ✅ **Affichage du seuil** pour chaque produit
- ✅ **Indicateurs visuels** selon le niveau de stock

### 3. **Indicateurs Visuels**
- 🟢 **Vert** : Stock suffisant (au-dessus du seuil)
- 🟡 **Orange** : Stock faible (égal ou inférieur au seuil)
- 🔴 **Rouge** : Stock épuisé (0 unité)

### 4. **Alerte Visuelle**
- ✅ **Message d'alerte** : "Seuil: X" quand le stock est faible
- ✅ **Couleur d'alerte** : Orange pour attirer l'attention
- ✅ **Affichage conditionnel** : Seulement quand nécessaire

## 🔧 Implémentation Technique

### 1. **État du Formulaire**
```typescript
const [formData, setFormData] = useState({
  name: '',
  description: '',
  category: 'accessoire',
  price: 0,
  stockQuantity: 0,
  minStockLevel: 5,  // Nouveau champ
  isActive: true,
});
```

### 2. **Champ de Saisie**
```typescript
<TextField
  fullWidth
  label="Stock minimum (alerte)"
  type="number"
  value={formData.minStockLevel}
  onChange={(e) => handleInputChange('minStockLevel', parseInt(e.target.value) || 0)}
  inputProps={{ min: 0 }}
  helperText="Seuil d'alerte quand le stock devient faible"
/>
```

### 3. **Logique d'Alerte**
```typescript
color={product.stockQuantity === 0 ? 'error' : 
       product.stockQuantity <= (product.minStockLevel || 5) ? 'warning' : 'success'}
```

### 4. **Affichage Conditionnel**
```typescript
{product.stockQuantity <= (product.minStockLevel || 5) && product.stockQuantity > 0 && (
  <Typography variant="caption" color="warning.main" sx={{ fontSize: '0.7rem' }}>
    Seuil: {product.minStockLevel || 5}
  </Typography>
)}
```

## 📊 Interface Utilisateur

### Tableau des Produits
| Colonne | Description |
|---------|-------------|
| **Produit** | Nom et description |
| **Catégorie** | Type de produit |
| **Stock** | Quantité actuelle avec indicateur couleur |
| **Stock Min.** | Seuil d'alerte défini |
| **Prix** | Prix du produit |
| **Statut** | Actif/Inactif |
| **Actions** | Modifier/Supprimer |

### Indicateurs de Couleur
- 🟢 **Vert** : `stockQuantity > minStockLevel`
- 🟡 **Orange** : `stockQuantity <= minStockLevel` (avec alerte)
- 🔴 **Rouge** : `stockQuantity === 0`

## 🎯 Utilisation

### 1. **Créer un Produit**
1. Cliquer sur "Nouveau produit"
2. Remplir les informations
3. **Définir le stock minimum** (ex: 10)
4. Sauvegarder

### 2. **Modifier un Produit**
1. Cliquer sur l'icône "Modifier"
2. Ajuster le stock minimum si nécessaire
3. Sauvegarder

### 3. **Surveiller les Stocks**
- **Produits en vert** : Stock suffisant
- **Produits en orange** : Stock faible (commander)
- **Produits en rouge** : Stock épuisé (commander d'urgence)

## 🔄 Base de Données

### Colonne Ajoutée
- **`min_stock_level`** : INTEGER DEFAULT 5
- **Stockée** dans la table `products`
- **Indexée** pour les performances
- **RLS** activé pour la sécurité

### Requêtes Utilisées
```sql
-- Mise à jour lors de la création/modification
UPDATE products SET 
  min_stock_level = $1 
WHERE id = $2;

-- Affichage avec alerte
SELECT 
  *,
  CASE 
    WHEN stock_quantity <= min_stock_level THEN 'warning'
    WHEN stock_quantity = 0 THEN 'error'
    ELSE 'success'
  END as stock_status
FROM products;
```

## 🧪 Tests de Validation

### Test 1 : Création de Produit
1. **Créer** un nouveau produit
2. **Définir** un stock minimum de 10
3. **Vérifier** que la valeur est sauvegardée
4. **Vérifier** l'affichage dans le tableau

### Test 2 : Modification de Produit
1. **Modifier** un produit existant
2. **Changer** le stock minimum
3. **Vérifier** que la modification est sauvegardée

### Test 3 : Indicateurs Visuels
1. **Produit avec stock > seuil** : Vérifier couleur verte
2. **Produit avec stock = seuil** : Vérifier couleur orange + alerte
3. **Produit avec stock = 0** : Vérifier couleur rouge

### Test 4 : Valeurs Limites
1. **Stock minimum = 0** : Vérifier validation
2. **Stock minimum négatif** : Vérifier rejet
3. **Stock minimum très élevé** : Vérifier acceptation

## 🎯 Avantages

### Pour l'Utilisateur
- ✅ **Alerte proactive** avant rupture de stock
- ✅ **Gestion optimisée** des commandes
- ✅ **Visibilité claire** de l'état des stocks
- ✅ **Interface intuitive** avec codes couleur

### Pour l'Entreprise
- ✅ **Réduction** des ruptures de stock
- ✅ **Optimisation** des commandes
- ✅ **Amélioration** du service client
- ✅ **Gestion préventive** des stocks

## 🔧 Maintenance

### Ajouts Futurs Possibles
- **Notifications automatiques** par email
- **Rapports** de produits en alerte
- **Historique** des seuils
- **Seuils par catégorie** de produits

### Monitoring
- **Surveiller** les produits en alerte
- **Analyser** les tendances de consommation
- **Ajuster** les seuils selon l'usage
- **Optimiser** les niveaux de stock

---

## 🎉 Résultat Final

La fonctionnalité **Stock Minimum** est maintenant disponible :

- ✅ **Champ de saisie** dans les formulaires
- ✅ **Affichage** dans le tableau des produits
- ✅ **Indicateurs visuels** avec codes couleur
- ✅ **Alertes** quand le stock devient faible
- ✅ **Interface intuitive** et réactive

Cette fonctionnalité améliore significativement la gestion des stocks et aide à prévenir les ruptures !
