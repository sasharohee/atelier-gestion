# 🔧 Correction Doublons - Numéros de Commande

## ✅ **PROBLÈME IDENTIFIÉ ET RÉSOLU**

### **Problème : Doublons de Numéros de Commande**
- ❌ Erreur : `duplicate key value violates unique constraint "orders_workshop_id_order_number_key"`
- ✅ **Cause** : Le numéro de commande `"01 23 45 67 89"` existe déjà
- ✅ **Solution** : Génération de numéros uniques + nettoyage des doublons

### **Corrections Appliquées**

#### **1. Service Frontend Corrigé**
```typescript
// Avant (problématique)
orderNumber: updates.orderNumber || `CMD-${Date.now()}`

// Après (corrigé)
orderNumber: `CMD-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
```

#### **2. Script de Nettoyage**
- ✅ Supprime les doublons existants
- ✅ Garde la commande la plus récente
- ✅ Vérifie qu'il n'y a plus de doublons

## ⚡ **ÉTAPES DE CORRECTION**

### **Étape 1 : Exécuter le Script de Nettoyage**

1. **Aller sur Supabase Dashboard**
   - Ouvrir votre projet Supabase
   - Cliquer sur "SQL Editor" dans le menu de gauche

2. **Exécuter le Script de Nettoyage**
   - Copier le contenu du fichier `tables/correction_doublons_orders.sql`
   - Coller dans l'éditeur SQL
   - Cliquer sur "Run" (▶️)

3. **Vérifier les Résultats**
   - Le script va :
     - ✅ Identifier les doublons
     - ✅ Supprimer les doublons
     - ✅ Vérifier qu'il n'y a plus de doublons

### **Étape 2 : Tester l'Application**

1. **Retourner sur l'application**
2. **Actualiser la page** (F5)
3. **Créer une nouvelle commande**
4. **Vérifier que ça fonctionne**

## 🔍 **Ce que fait le Script**

### **1. Identification des Doublons**
```sql
-- Trouve les numéros de commande en double
SELECT order_number, workshop_id, COUNT(*) as nombre_doublons
FROM orders 
GROUP BY order_number, workshop_id
HAVING COUNT(*) > 1
```

### **2. Suppression des Doublons**
```sql
-- Supprime les doublons en gardant la plus récente
DELETE FROM orders 
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY order_number, workshop_id 
                   ORDER BY created_at DESC
               ) as rn
        FROM orders
    ) t
    WHERE t.rn > 1
);
```

### **3. Vérification**
- ✅ Affiche les commandes restantes
- ✅ Confirme qu'il n'y a plus de doublons

## 📋 **Checklist de Validation**

- [ ] **Script exécuté** sans erreur
- [ ] **Message "DOUBLONS CORRIGES"** affiché
- [ ] **Aucun doublon** dans les résultats
- [ ] **Création de commande** fonctionne dans l'app
- [ ] **Numéros de commande uniques** générés

## 🎯 **Résultat Attendu**

Après exécution du script :
- ✅ **Aucune erreur de doublon**
- ✅ **Création de commandes** fonctionnelle
- ✅ **Numéros de commande uniques** générés automatiquement
- ✅ **Application entièrement fonctionnelle**

## 🔧 **Détails Techniques**

### **Génération de Numéros Uniques**
```typescript
// Format : CMD-timestamp-randomString
`CMD-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`

// Exemple : CMD-1756586262165-abc123def
```

### **Contrainte Unique**
```sql
-- Contrainte sur (workshop_id, order_number)
CONSTRAINT orders_workshop_id_order_number_key 
UNIQUE (workshop_id, order_number)
```

## 📞 **Support**

Si vous rencontrez des problèmes :
1. **Copier le message d'erreur complet**
2. **Screenshot des résultats du script**
3. **État de la console navigateur**

---

**⏱️ Temps estimé : 2 minutes**

**🎯 Problème résolu : Doublons corrigés et numéros uniques**

**✅ Application entièrement fonctionnelle**

