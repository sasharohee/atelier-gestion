# 🧪 GUIDE DE TEST - RUPTURE DE STOCK

## 🎯 OBJECTIF
Tester que la fonctionnalité de rupture de stock fonctionne correctement avec création automatique d'alertes.

## 📋 ÉTAPES DE TEST

### 1. EXÉCUTION DU SCRIPT SQL

**Fichier à utiliser :** `create_stock_alerts_table.sql`

**Actions du script :**
- ✅ Crée la table `stock_alerts` avec isolation des utilisateurs
- ✅ Active RLS avec politiques strictes
- ✅ Crée des triggers pour génération automatique d'alertes
- ✅ Crée des fonctions pour résolution automatique

**Exécution :**
```sql
-- Dans l'interface SQL de Supabase
-- Copier et exécuter le contenu de create_stock_alerts_table.sql
```

### 2. TEST DE CRÉATION MANUELLE D'ALERTE

1. **Connectez-vous avec le compte A**
2. **Allez dans Catalogue > Rupture de stock**
3. **Cliquez sur "Nouvelle alerte"**
4. **Remplissez le formulaire :**
   - Pièce : Sélectionnez une pièce existante
   - Type d'alerte : `Stock faible` ou `Rupture de stock`
   - Message : `Test d'alerte manuelle`
5. **Cliquez sur "Créer l'alerte"**
6. **Vérifiez que l'alerte apparaît** dans la liste

### 3. TEST DE CRÉATION AUTOMATIQUE D'ALERTE

1. **Allez dans Catalogue > Pièces**
2. **Créez une nouvelle pièce** avec :
   - Nom : `Écran iPhone 14`
   - Référence : `ECR-IP14-001`
   - Marque : `Apple`
   - Stock : `0` (pour tester la rupture)
   - Seuil minimum : `5`
3. **Sauvegardez la pièce**
4. **Allez dans Catalogue > Rupture de stock**
5. **Vérifiez qu'une alerte automatique** a été créée

### 4. TEST DE STOCK FAIBLE

1. **Retournez dans Catalogue > Pièces**
2. **Modifiez la pièce créée** :
   - Stock : `3` (inférieur au seuil de 5)
3. **Sauvegardez**
4. **Allez dans Catalogue > Rupture de stock**
5. **Vérifiez qu'une alerte "Stock faible"** a été créée

### 5. TEST DE RÉSOLUTION AUTOMATIQUE

1. **Retournez dans Catalogue > Pièces**
2. **Modifiez la pièce** :
   - Stock : `10` (supérieur au seuil de 5)
3. **Sauvegardez**
4. **Allez dans Catalogue > Rupture de stock**
5. **Vérifiez que l'alerte a été résolue** automatiquement

### 6. TEST DE RÉSOLUTION MANUELLE

1. **Créez une nouvelle pièce** avec stock faible
2. **Allez dans Catalogue > Rupture de stock**
3. **Cliquez sur l'icône verte** (✓) pour résoudre manuellement
4. **Vérifiez que l'alerte** est marquée comme résolue

### 7. TEST DE SUPPRESSION D'ALERTE

1. **Créez une nouvelle alerte manuelle**
2. **Cliquez sur l'icône rouge** (🗑️) pour supprimer
3. **Vérifiez que l'alerte** a été supprimée

### 8. TEST D'ISOLATION ENTRE COMPTES

1. **Connectez-vous avec le compte A**
2. **Créez une alerte de stock**
3. **Déconnectez-vous**
4. **Connectez-vous avec le compte B**
5. **Allez dans Catalogue > Rupture de stock**
6. **Vérifiez que l'alerte du compte A n'est PAS visible**

## ✅ RÉSULTATS ATTENDUS

### Création d'alertes :
- ✅ **Manuelle** : Bouton "Nouvelle alerte" fonctionne
- ✅ **Automatique** : Alertes créées lors de la gestion des pièces
- ✅ **Stock faible** : Quand stock ≤ seuil minimum
- ✅ **Rupture** : Quand stock = 0

### Gestion des alertes :
- ✅ **Résolution automatique** : Quand stock > seuil minimum
- ✅ **Résolution manuelle** : Bouton ✓ fonctionne
- ✅ **Suppression** : Bouton 🗑️ fonctionne
- ✅ **Isolation** : Chaque utilisateur ne voit que ses alertes

### Interface utilisateur :
- ✅ **Modal de création** : Formulaire complet et fonctionnel
- ✅ **Tableau des alertes** : Affichage correct des données
- ✅ **Messages de succès/erreur** : Feedback utilisateur
- ✅ **États visuels** : Chips colorés selon le type d'alerte

## 🚨 SIGNAUX D'ALERTE

### Si les alertes ne se créent pas automatiquement :

1. **Vérifiez que la table `stock_alerts`** a été créée
2. **Vérifiez que les triggers** sont actifs
3. **Vérifiez les logs** pour identifier les erreurs
4. **Vérifiez que RLS** est activé

### Si l'isolation ne fonctionne pas :

1. **Vérifiez les politiques RLS** sur la table `stock_alerts`
2. **Vérifiez que `user_id`** est correctement assigné
3. **Vérifiez que l'utilisateur** est connecté

### Si les alertes ne se résolvent pas automatiquement :

1. **Vérifiez le trigger** `trigger_resolve_stock_alerts`
2. **Vérifiez la fonction** `resolve_stock_alerts_automatically`
3. **Vérifiez que le stock** est bien mis à jour

## 🔧 DÉPANNAGE

### Problème : Alertes non créées automatiquement

**Solution :**
1. Vérifiez que les triggers sont créés
2. Vérifiez les logs d'erreur PostgreSQL
3. Testez manuellement la fonction de création

### Problème : Interface ne fonctionne pas

**Solution :**
1. Vérifiez que le store a été mis à jour
2. Vérifiez les erreurs dans la console du navigateur
3. Vérifiez que les fonctions `addStockAlert`, etc. existent

### Problème : Isolation défaillante

**Solution :**
1. Exécutez le script de correction d'isolation
2. Vérifiez les politiques RLS
3. Vérifiez que `user_id` est assigné correctement

## 📊 VÉRIFICATION FINALE

Après avoir effectué tous les tests, vérifiez que :

1. **Création manuelle** : Bouton "Nouvelle alerte" fonctionne
2. **Création automatique** : Alertes créées lors de la gestion des pièces
3. **Résolution automatique** : Alertes résolues quand stock suffisant
4. **Résolution manuelle** : Bouton de résolution fonctionne
5. **Suppression** : Bouton de suppression fonctionne
6. **Isolation** : Chaque utilisateur ne voit que ses alertes
7. **Interface** : Tous les éléments visuels sont corrects

## 🎉 SUCCÈS

Si tous les tests sont réussis, la fonctionnalité de rupture de stock fonctionne parfaitement !

---

**💡 CONSEIL** : Testez régulièrement la création automatique d'alertes en modifiant les stocks des pièces.

**📱 TYPES D'ALERTES :**
- **Stock faible** : Quand stock ≤ seuil minimum
- **Rupture de stock** : Quand stock = 0
