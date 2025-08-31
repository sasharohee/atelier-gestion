# 🔧 Guide - Correction Contrainte Unique

## 🎯 **Problème Identifié**

L'erreur `duplicate key value violates unique constraint "product_categories_name_key"` indique que :

✅ **L'isolation RLS fonctionne** - vous pouvez créer des catégories  
❌ **Problème** : La contrainte d'unicité globale empêche des noms identiques pour des utilisateurs différents

## 🔍 **Explication du Problème**

La table `product_categories` a une contrainte `UNIQUE` sur la colonne `name`, ce qui signifie :
- ❌ Deux utilisateurs ne peuvent pas avoir de catégories avec le même nom
- ❌ Cela empêche l'isolation complète des données

## 🛠️ **Solution**

### **Étape 1 : Corriger la Contrainte Unique**

Exécutez le script `correction_contrainte_unique.sql` dans le SQL Editor de Supabase :

```sql
-- Ce script va :
-- 1. Supprimer l'ancienne contrainte unique globale
-- 2. Créer une contrainte unique composite (name + user_id)
-- 3. Permettre des noms identiques pour des utilisateurs différents
```

### **Étape 2 : Vérification**

Après l'exécution, vérifiez que :

```sql
-- Vérifier les nouvelles contraintes
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'product_categories' 
AND indexname LIKE '%unique%';
```

Vous devriez voir :
- `product_categories_name_user_unique` - Contrainte composite
- `product_categories_name_global_unique` - Contrainte pour catégories globales

## ✅ **Résultat Attendu**

Après la correction :

### **Avant la Correction**
- ❌ Utilisateur A crée "Smartphones" → Succès
- ❌ Utilisateur B crée "Smartphones" → Erreur (nom déjà pris)

### **Après la Correction**
- ✅ Utilisateur A crée "Smartphones" → Succès
- ✅ Utilisateur B crée "Smartphones" → Succès
- ✅ Chaque utilisateur a ses propres catégories isolées

## 🧪 **Test de l'Isolation**

### **Test 1 : Création avec Même Nom**
1. **Compte A** : Créez une catégorie "Test Catégorie"
2. **Compte B** : Créez aussi une catégorie "Test Catégorie"
3. **Vérifiez** : Les deux créations doivent réussir

### **Test 2 : Vérification Isolation**
1. **Compte A** : Vérifiez que vous voyez seulement votre "Test Catégorie"
2. **Compte B** : Vérifiez que vous voyez seulement votre "Test Catégorie"
3. **Confirmez** : Chaque compte ne voit que ses propres catégories

## 🔧 **Service Amélioré**

Le service `categoryService.ts` a été amélioré pour :
- ✅ Gérer les erreurs de contrainte unique
- ✅ Afficher des messages d'erreur clairs
- ✅ Permettre la création de catégories avec isolation

## 📋 **Instructions d'Exécution**

### **Étape 1 : Base de Données**
1. Copiez le contenu de `correction_contrainte_unique.sql`
2. Exécutez-le dans le SQL Editor de Supabase
3. Vérifiez que les nouvelles contraintes sont créées

### **Étape 2 : Test**
1. Essayez de créer des catégories avec le même nom sur différents comptes
2. Vérifiez que l'isolation fonctionne
3. Confirmez que chaque utilisateur ne voit que ses propres catégories

## 🎉 **Résultat Final**

Après cette correction :
- ✅ **Isolation complète** : Chaque utilisateur a ses propres catégories
- ✅ **Noms identiques autorisés** : Différents utilisateurs peuvent avoir des catégories avec le même nom
- ✅ **Pas de conflits** : Plus d'erreurs de contrainte unique
- ✅ **Sécurité maintenue** : L'isolation RLS fonctionne parfaitement

---

**🎯 Cette correction résout définitivement le problème de contrainte unique et permet l'isolation complète !**


