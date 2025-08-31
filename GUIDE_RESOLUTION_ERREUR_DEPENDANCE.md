# 🚨 Résolution Erreur Dépendance - Fonction SQL

## ❌ Erreur Identifiée

```
ERROR: 2BP01: cannot drop function set_order_isolation() because other objects depend on it
DETAIL: trigger set_order_isolation_trigger on table orders depends on function set_order_isolation()
trigger set_order_item_isolation_trigger on table order_items depends on function set_order_isolation()
trigger set_supplier_isolation_trigger on table suppliers depends on function set_order_isolation()
```

## 🔍 Cause du Problème

La fonction `set_order_isolation()` est utilisée par plusieurs triggers :
- `set_order_isolation_trigger` sur la table `orders`
- `set_order_item_isolation_trigger` sur la table `order_items`
- `set_supplier_isolation_trigger` sur la table `suppliers`

PostgreSQL ne peut pas supprimer une fonction tant que des objets en dépendent.

## ⚡ Solution Appliquée

### **Script Corrigé**

Le script a été mis à jour pour :
1. **Supprimer d'abord les triggers** qui dépendent de la fonction
2. **Supprimer ensuite la fonction**
3. **Recréer la fonction** avec la nouvelle logique
4. **Recréer tous les triggers** avec la fonction mise à jour

### **Ordre des Opérations**
```sql
-- 1. Supprimer les triggers dépendants
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- 2. Supprimer la fonction
DROP FUNCTION IF EXISTS set_order_isolation();

-- 3. Recréer la fonction
CREATE OR REPLACE FUNCTION set_order_isolation() ...

-- 4. Recréer tous les triggers
CREATE TRIGGER set_order_isolation_trigger ...
CREATE TRIGGER set_order_item_isolation_trigger ...
CREATE TRIGGER set_supplier_isolation_trigger ...
```

## 🧪 Test de Validation

### **Test 1 : Exécution du Script**
1. Aller sur Supabase Dashboard
2. Ouvrir SQL Editor
3. Exécuter le script `tables/correction_rls_orders.sql` (version corrigée)
4. ✅ Vérifier qu'il n'y a plus d'erreur de dépendance

### **Test 2 : Vérification des Triggers**
1. Après exécution du script
2. ✅ Vérifier que tous les triggers sont recréés
3. ✅ Vérifier que la fonction fonctionne

### **Test 3 : Test d'Insertion**
1. Dans l'application, créer une nouvelle commande
2. ✅ Vérifier que l'insertion fonctionne
3. ✅ Vérifier que le workshop_id est automatiquement défini

## 📋 Checklist de Validation

- [ ] **Script exécuté** sans erreur de dépendance
- [ ] **Tous les triggers** recréés correctement
- [ ] **Fonction d'isolation** mise à jour
- [ ] **Test d'insertion** réussi
- [ ] **Isolation automatique** fonctionnelle

## 🎯 Résultat Attendu

Après application des corrections :
- ✅ **Script exécuté** sans erreur de dépendance
- ✅ **Tous les triggers** fonctionnels
- ✅ **Isolation automatique** pour toutes les tables
- ✅ **Création de commandes** opérationnelle

## 🔧 Détails Techniques

### **Problème Avant**
```sql
-- Tentative de suppression directe de la fonction
DROP FUNCTION IF EXISTS set_order_isolation();
-- ❌ Erreur : dépendances non supprimées
```

### **Solution Après**
```sql
-- Suppression des dépendances d'abord
DROP TRIGGER IF EXISTS ... ON orders;
DROP TRIGGER IF EXISTS ... ON order_items;
DROP TRIGGER IF EXISTS ... ON suppliers;

-- Puis suppression de la fonction
DROP FUNCTION IF EXISTS set_order_isolation();
-- ✅ Succès : plus de dépendances
```

## 🆘 Si le Problème Persiste

### **Solution Alternative**

Si l'erreur persiste, utiliser `DROP CASCADE` :
```sql
DROP FUNCTION IF EXISTS set_order_isolation() CASCADE;
```

### **Vérification Manuelle**

1. **Vérifier les dépendances**
   ```sql
   SELECT * FROM pg_depend 
   WHERE objid = (SELECT oid FROM pg_proc WHERE proname = 'set_order_isolation');
   ```

2. **Vérifier les triggers**
   ```sql
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name LIKE '%isolation%';
   ```

## 📞 Support

Si le problème persiste après ces étapes :
1. **Message d'erreur complet**
2. **Résultat de la vérification des dépendances**
3. **État des triggers** avant et après

---

**⏱️ Temps estimé de résolution : 2 minutes**

**🎯 Problème résolu : Gestion des dépendances de fonction**

