# 🔧 GUIDE DE CORRECTION DES RÉDUCTIONS SUR FACTURES

## 🚨 Problèmes identifiés

1. **Réduction appliquée plusieurs fois** quand on change le statut d'une réparation
2. **Prix incorrect** affiché sur la facture
3. **Réduction non visible** sur la facture
4. **Triggers problématiques** qui recalculent automatiquement la réduction

## ✅ Solutions mises en place

### 1. **Correction des triggers de réduction**

Le fichier `tables/correction_triggers_reduction.sql` contient les corrections suivantes :

#### **Problème des anciens triggers :**
- Les triggers appliquaient la réduction à chaque mise à jour
- Le prix de base était modifié, causant des calculs multiples
- Pas de sauvegarde du prix original

#### **Solution des nouveaux triggers :**
- **Sauvegarde du prix original** dans `original_price` (réparations) et `original_total` (ventes)
- **Calcul unique** : la réduction ne s'applique qu'une seule fois
- **Condition** : seulement lors de l'insertion ou changement du pourcentage

### 2. **Nouvelles colonnes ajoutées**

#### **Table `repairs` :**
```sql
ALTER TABLE repairs ADD COLUMN original_price DECIMAL(10,2);
```

#### **Table `sales` :**
```sql
ALTER TABLE sales ADD COLUMN original_total DECIMAL(10,2);
```

### 3. **Mise à jour des types TypeScript**

#### **Interface `Repair` :**
```typescript
export interface Repair {
  // ... autres propriétés
  originalPrice?: number;
}
```

#### **Interface `Sale` :**
```typescript
export interface Sale {
  // ... autres propriétés
  originalTotal?: number;
}
```

### 4. **Mise à jour du service Supabase**

Le service gère maintenant les nouvelles colonnes :
- `original_price` pour les réparations
- `original_total` pour les ventes
- `discount_percentage` et `discount_amount` correctement

### 5. **Affichage sur les factures**

Le composant `Invoice.tsx` affiche maintenant :
- **Réduction de fidélité** en vert
- **Pourcentage et montant** de la réduction
- **Prix original** pour les réparations

## 🚀 Instructions d'exécution

### **Étape 1 : Exécuter le script de correction**

```bash
# Se connecter à votre base de données Supabase
psql "postgresql://postgres:[VOTRE_MOT_DE_PASSE]@[VOTRE_HOST]:5432/[VOTRE_DB]" -f tables/correction_triggers_reduction.sql
```

### **Étape 2 : Vérifier les corrections**

Le script affichera :
- Les réparations avec réduction
- Les ventes avec réduction
- Confirmation que les triggers sont corrigés

### **Étape 3 : Tester les fonctionnalités**

1. **Créer une réparation** avec réduction
2. **Changer le statut** (en cours → terminé → en cours)
3. **Vérifier que la réduction** ne s'applique qu'une fois
4. **Générer la facture** et vérifier l'affichage

## 📋 Fonctionnement des nouveaux triggers

### **Pour les réparations :**
```sql
-- Se déclenche seulement si :
-- 1. Nouvelle réparation (INSERT)
-- 2. Changement du pourcentage de réduction
IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
    -- Sauvegarder le prix original
    NEW.original_price = NEW.total_price;
    
    -- Calculer la réduction sur le prix original
    NEW.discount_amount = (NEW.original_price * NEW.discount_percentage) / 100;
    
    -- Calculer le prix final
    NEW.total_price = NEW.original_price - NEW.discount_amount;
END IF;
```

### **Pour les ventes :**
```sql
-- Même logique mais sur le total TTC
IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
    -- Sauvegarder le total original
    NEW.original_total = NEW.subtotal + NEW.tax;
    
    -- Calculer la réduction sur le total TTC
    NEW.discount_amount = (NEW.original_total * NEW.discount_percentage) / 100;
    
    -- Calculer le total final
    NEW.total = NEW.original_total - NEW.discount_amount;
END IF;
```

## 🎯 Résultats attendus

### **Avant la correction :**
- ❌ Réduction appliquée plusieurs fois
- ❌ Prix incorrect sur facture
- ❌ Réduction non visible

### **Après la correction :**
- ✅ Réduction appliquée une seule fois
- ✅ Prix correct sur facture
- ✅ Réduction visible en vert
- ✅ Prix original affiché pour les réparations

## 🔍 Vérification

Après exécution du script, vérifiez que :

1. **Les colonnes existent :**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name IN ('repairs', 'sales') 
AND column_name LIKE '%original%';
```

2. **Les triggers sont créés :**
```sql
SELECT trigger_name FROM information_schema.triggers 
WHERE trigger_name LIKE '%discount%';
```

3. **Les données sont correctes :**
```sql
SELECT id, total_price, original_price, discount_percentage, discount_amount 
FROM repairs WHERE discount_percentage > 0 LIMIT 5;
```

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez la connexion à la base de données
2. Assurez-vous d'avoir les droits d'administration
3. Vérifiez les logs d'erreur PostgreSQL
