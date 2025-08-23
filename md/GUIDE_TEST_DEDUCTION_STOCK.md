# 🧪 GUIDE DE TEST - DÉDUCTION AUTOMATIQUE DU STOCK

## 🎯 OBJECTIF
Tester que le stock des produits et pièces diminue automatiquement lors des ventes et génère des alertes de rupture.

## 📋 ÉTAPES DE TEST

### 1. EXÉCUTION DES SCRIPTS SQL

**Fichiers à utiliser :**
1. `create_stock_alerts_table.sql` - Pour les alertes de stock
2. `add_stock_to_products.sql` - Pour ajouter le stock aux produits

**Exécution :**
```sql
-- Dans l'interface SQL de Supabase
-- 1. Copier et exécuter create_stock_alerts_table.sql
-- 2. Copier et exécuter add_stock_to_products.sql
```

### 2. PRÉPARATION DES DONNÉES DE TEST

#### **Créer des pièces avec stock faible :**
1. **Allez dans Catalogue > Pièces**
2. **Créez une pièce** avec :
   - Nom : `Écran iPhone 14 Test`
   - Référence : `ECR-TEST-001`
   - Marque : `Apple`
   - Stock : `3` (inférieur au seuil de 5)
   - Seuil minimum : `5`
   - Prix : `150`

#### **Créer un produit avec stock faible :**
1. **Allez dans Catalogue > Produits**
2. **Créez un produit** avec :
   - Nom : `Chargeur USB-C Test`
   - Description : `Chargeur rapide pour test`
   - Stock : `2` (inférieur au seuil de 5)
   - Seuil minimum : `5`
   - Prix : `25`

### 3. TEST DE DÉDUCTION DU STOCK

#### **Test avec une pièce :**
1. **Allez dans Ventes**
2. **Créez une nouvelle vente**
3. **Ajoutez la pièce "Écran iPhone 14 Test"** avec quantité `2`
4. **Finalisez la vente**
5. **Vérifiez que :**
   - ✅ Le stock de la pièce est passé de `3` à `1`
   - ✅ Une alerte "Stock faible" apparaît dans **Catalogue > Rupture de stock**

#### **Test avec un produit :**
1. **Créez une nouvelle vente**
2. **Ajoutez le produit "Chargeur USB-C Test"** avec quantité `2`
3. **Finalisez la vente**
4. **Vérifiez que :**
   - ✅ Le stock du produit est passé de `2` à `0`
   - ✅ Une alerte "Rupture de stock" apparaît dans **Catalogue > Rupture de stock**

### 4. TEST DE RUPTURE COMPLÈTE

#### **Créer une rupture de stock :**
1. **Créez une nouvelle vente**
2. **Ajoutez la pièce "Écran iPhone 14 Test"** avec quantité `1` (stock restant)
3. **Finalisez la vente**
4. **Vérifiez que :**
   - ✅ Le stock de la pièce est passé à `0`
   - ✅ L'alerte "Stock faible" est remplacée par "Rupture de stock"

### 5. TEST DE RESTAURATION DU STOCK

#### **Supprimer une vente :**
1. **Allez dans Ventes**
2. **Trouvez la dernière vente créée**
3. **Supprimez cette vente**
4. **Vérifiez que :**
   - ✅ Le stock des produits/pièces est restauré
   - ✅ Les alertes de stock sont résolues automatiquement

### 6. TEST DE RÉSOLUTION AUTOMATIQUE

#### **Réapprovisionner le stock :**
1. **Allez dans Catalogue > Pièces**
2. **Modifiez la pièce "Écran iPhone 14 Test"**
3. **Augmentez le stock à `10`**
4. **Sauvegardez**
5. **Vérifiez que :**
   - ✅ L'alerte de stock est résolue automatiquement
   - ✅ L'alerte n'apparaît plus dans **Catalogue > Rupture de stock**

### 7. TEST D'ISOLATION ENTRE COMPTES

#### **Test avec différents utilisateurs :**
1. **Connectez-vous avec le compte A**
2. **Créez une vente avec des pièces**
3. **Vérifiez les alertes de stock**
4. **Déconnectez-vous**
5. **Connectez-vous avec le compte B**
6. **Allez dans Catalogue > Rupture de stock**
7. **Vérifiez que les alertes du compte A ne sont PAS visibles**

## ✅ RÉSULTATS ATTENDUS

### Déduction automatique :
- ✅ **Stock diminue** lors de la création d'une vente
- ✅ **Mise à jour immédiate** dans l'interface
- ✅ **Synchronisation** avec la base de données
- ✅ **Gestion des quantités** multiples

### Génération d'alertes :
- ✅ **Alerte "Stock faible"** quand stock ≤ seuil minimum
- ✅ **Alerte "Rupture"** quand stock = 0
- ✅ **Messages descriptifs** avec contexte de la vente
- ✅ **Isolation par utilisateur**

### Restauration du stock :
- ✅ **Stock restauré** lors de la suppression d'une vente
- ✅ **Résolution automatique** des alertes
- ✅ **Mise à jour immédiate** de l'interface

### Interface utilisateur :
- ✅ **Affichage du stock** en temps réel
- ✅ **Indicateurs visuels** (chips colorés)
- ✅ **Messages de confirmation** lors des actions
- ✅ **Gestion des erreurs** (stock insuffisant)

## 🚨 SIGNAUX D'ALERTE

### Si le stock ne diminue pas :

1. **Vérifiez que les scripts SQL** ont été exécutés
2. **Vérifiez les erreurs** dans la console du navigateur
3. **Vérifiez que les services** de mise à jour fonctionnent
4. **Vérifiez la connexion** à la base de données

### Si les alertes ne se créent pas :

1. **Vérifiez que la table `stock_alerts`** existe
2. **Vérifiez les triggers** de création automatique
3. **Vérifiez les politiques RLS** sur les alertes
4. **Vérifiez que l'utilisateur** est connecté

### Si la restauration ne fonctionne pas :

1. **Vérifiez la fonction `deleteSale`** dans le store
2. **Vérifiez les services** de mise à jour des produits/pièces
3. **Vérifiez les logs** d'erreur
4. **Vérifiez la synchronisation** avec la base de données

## 🔧 DÉPANNAGE

### Problème : Stock ne diminue pas lors des ventes

**Solution :**
1. Vérifiez que la fonction `addSale` a été mise à jour
2. Vérifiez les erreurs dans la console
3. Vérifiez que les services `partService` et `productService` fonctionnent

### Problème : Alertes non créées automatiquement

**Solution :**
1. Vérifiez que la table `stock_alerts` existe
2. Vérifiez les triggers de création automatique
3. Vérifiez les politiques RLS

### Problème : Restauration du stock défaillante

**Solution :**
1. Vérifiez la fonction `deleteSale` mise à jour
2. Vérifiez les services de mise à jour
3. Vérifiez la logique de restauration

## 📊 VÉRIFICATION FINALE

Après avoir effectué tous les tests, vérifiez que :

1. **Déduction automatique** : Le stock diminue lors des ventes
2. **Génération d'alertes** : Les alertes se créent automatiquement
3. **Restauration** : Le stock se restaure lors de la suppression
4. **Résolution automatique** : Les alertes se résolvent automatiquement
5. **Isolation** : Chaque utilisateur ne voit que ses alertes
6. **Interface** : Tous les éléments visuels sont corrects
7. **Synchronisation** : Les données sont cohérentes entre interface et base

## 🎉 SUCCÈS

Si tous les tests sont réussis, la déduction automatique du stock fonctionne parfaitement !

---

**💡 CONSEIL** : Testez régulièrement avec différents scénarios de vente pour vous assurer que le système fonctionne correctement.

**📱 TYPES DE DÉDUCTION :**
- **Pièces** : Stock déduit automatiquement
- **Produits** : Stock déduit automatiquement
- **Services** : Pas de déduction (pas de stock)
