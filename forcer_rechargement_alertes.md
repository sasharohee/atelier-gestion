# Forcer le Rechargement des Alertes de Stock

## Problème Résolu

Les produits avec 0 stock n'apparaissaient pas dans la page "Rupture de stock" car :

1. **La fonction `loadStockAlerts`** ne vérifiait que les pièces détachées (`parts`)
2. **La page OutOfStock** n'affichait que les pièces détachées

## Corrections Appliquées

### 1. Store (`src/store/index.ts`)
- ✅ Modifié `loadStockAlerts` pour vérifier **ET** les pièces **ET** les produits
- ✅ Ajouté la génération d'alertes pour les produits avec stock ≤ 0 ou ≤ seuil minimum

### 2. Page OutOfStock (`src/pages/Catalog/OutOfStock.tsx`)
- ✅ Ajouté `products` dans les imports du store
- ✅ Modifié l'affichage pour montrer les produits ET les pièces
- ✅ Mis à jour le formulaire de création d'alerte pour inclure les produits
- ✅ Changé "Pièce" en "Article" dans l'interface

## Actions à Effectuer

### Étape 1 : Recharger les Alertes
1. Aller sur la page "Rupture de stock"
2. Ouvrir la console du navigateur (F12)
3. Exécuter cette commande pour forcer le rechargement :

```javascript
// Forcer le rechargement des alertes de stock
window.store.getState().loadStockAlerts();
```

### Étape 2 : Vérifier les Résultats
Après le rechargement, vous devriez voir :
- ✅ Les produits avec 0 stock apparaissent dans la liste
- ✅ Les produits avec stock faible (≤ seuil minimum) apparaissent aussi
- ✅ Les pièces détachées continuent d'apparaître normalement

### Étape 3 : Alternative - Recharger la Page
Si la commande console ne fonctionne pas :
1. Recharger complètement la page (Ctrl+F5 ou Cmd+Shift+R)
2. Les alertes se rechargeront automatiquement au montage du composant

## Vérification

Après ces corrections :
- ✅ Les produits avec 0 stock apparaissent dans "Rupture de stock"
- ✅ Les produits avec stock faible apparaissent aussi
- ✅ Le formulaire de création d'alerte inclut les produits
- ✅ L'interface affiche correctement "Article" au lieu de "Pièce"

## Fonctionnement

Maintenant, la fonction `loadStockAlerts` :
1. Vérifie **toutes les pièces détachées** avec stock ≤ 0 ou ≤ seuil minimum
2. Vérifie **tous les produits** avec stock ≤ 0 ou ≤ seuil minimum (défaut: 5)
3. Génère des alertes pour tous les articles concernés
4. Les affiche dans la page "Rupture de stock"
