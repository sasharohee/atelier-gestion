# 🧪 GUIDE DE TEST - RÉDUCTION SUR FACTURES DE RÉPARATION

## 🎯 Objectif

Vérifier que la réduction de fidélité s'affiche correctement sur les factures de réparation, comme elle le fait déjà sur les factures de vente.

## ✅ Corrections apportées

### 1. **Correction du service repairService.getById()**
- **Problème** : Les données n'étaient pas converties de snake_case vers camelCase
- **Solution** : Ajout de la conversion complète des données, incluant les champs de réduction

### 2. **Amélioration de l'ouverture des factures**
- **Problème** : Les factures utilisaient les données locales qui pouvaient être obsolètes
- **Solution** : Récupération des données fraîches depuis la base de données lors de l'ouverture

### 3. **Debug ajouté**
- **Ajout** : Console.log pour vérifier les données de réduction dans le composant Invoice

## 🚀 Instructions de test

### **Étape 1 : Vérifier les données dans la base**

1. **Ouvrir la console du navigateur** (F12)
2. **Copier et coller** le contenu de `test_verification_reduction_reparations.js`
3. **Exécuter** le script
4. **Vérifier** que les réparations avec réduction sont bien listées

### **Étape 2 : Tester l'affichage de la facture**

1. **Aller sur la page Kanban** ou Archive
2. **Trouver une réparation avec réduction** (statut "terminé" ou "restitué")
3. **Cliquer sur l'icône facture** (📄)
4. **Vérifier dans la console** le message "🔍 Données de réparation pour facture:"
5. **Vérifier sur la facture** que la réduction s'affiche en vert

### **Étape 3 : Vérifier l'affichage attendu**

#### **Sur la facture de réparation, vous devriez voir :**

```
Prix de la réparation (TTC) : 90,00 € (Prix original: 100,00 €)

Sous-total HT : 75,00 €
TVA (20%) : 15,00 €
Réduction fidélité (10%) : -10,00 €
─────────────────────────
TOTAL TTC : 90,00 €
```

## 🔍 Points de vérification

### **Dans la console du navigateur :**

1. **Message de debug** lors de l'ouverture de la facture :
```
🔍 Données de réparation pour facture: {
  id: "...",
  totalPrice: 90,
  discountPercentage: 10,
  discountAmount: 10,
  originalPrice: 100
}
```

2. **Script de test** :
```
✅ repairService disponible
📊 Nombre total de réparations: X
🎯 Réparations avec réduction: Y
🔧 Réparation 1:
   ID: ...
   Prix total: 90 €
   Prix original: 100 €
   Réduction: 10%
   Montant réduction: 10 €
```

### **Sur la facture :**

- ✅ **Réduction visible** en vert
- ✅ **Pourcentage affiché** : "Réduction fidélité (10%)"
- ✅ **Montant affiché** : "-10,00 €"
- ✅ **Prix original** affiché entre parenthèses pour les réparations

## 🐛 Diagnostic des problèmes

### **Si la réduction ne s'affiche pas :**

1. **Vérifier la console** pour les messages de debug
2. **Vérifier que les données** contiennent bien `discountPercentage > 0`
3. **Vérifier que `discountAmount`** n'est pas null ou undefined
4. **Vérifier que la réparation** a bien le statut "terminé" ou "restitué"

### **Si les données sont manquantes :**

1. **Exécuter le script de correction** `tables/correction_triggers_reduction.sql`
2. **Vérifier que les colonnes** `original_price` et `discount_amount` existent
3. **Vérifier que les triggers** sont bien créés

### **Si la facture ne s'ouvre pas :**

1. **Vérifier les erreurs** dans la console
2. **Vérifier que repairService** est disponible
3. **Vérifier la connexion** à la base de données

## 📋 Checklist de validation

- [ ] **Script de test** s'exécute sans erreur
- [ ] **Réparations avec réduction** sont listées
- [ ] **Données de réduction** sont présentes dans la console
- [ ] **Facture s'ouvre** correctement
- [ ] **Réduction s'affiche** en vert sur la facture
- [ ] **Prix original** est affiché pour les réparations
- [ ] **Calculs** sont corrects

## 🔧 Commandes utiles

### **Vérifier les colonnes dans la base :**
```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'repairs' 
AND column_name LIKE '%discount%' OR column_name LIKE '%original%';
```

### **Vérifier les triggers :**
```sql
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%discount%';
```

### **Vérifier les données :**
```sql
SELECT id, total_price, original_price, discount_percentage, discount_amount 
FROM repairs 
WHERE discount_percentage > 0 
LIMIT 5;
```

## 📞 Support

Si les tests échouent :
1. **Vérifier la console** pour les erreurs
2. **Exécuter le script de correction** si nécessaire
3. **Vérifier la connexion** à la base de données
4. **Contacter le support** avec les logs d'erreur
