# 🚨 Résolution Erreur RLS - Création de Commandes

## ❌ Erreur Identifiée

```
new row violates row-level security policy for table "orders"
```

## 🔍 Cause du Problème

Les politiques RLS (Row Level Security) bloquent l'insertion car :
1. Le `workshop_id` n'est pas automatiquement défini
2. Les triggers d'isolation ne fonctionnent pas correctement
3. Les politiques RLS sont mal configurées

## ⚡ Solution Immédiate

### **Étape 1 : Exécuter le Script de Correction**

1. **Aller sur Supabase Dashboard**
   - [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Sélectionner votre projet

2. **Ouvrir SQL Editor**
   - Cliquer sur "SQL Editor" dans le menu
   - Créer une nouvelle requête

3. **Exécuter le Script de Correction**
   ```sql
   -- Copier le contenu de tables/correction_rls_orders.sql
   -- Cliquer sur "Run"
   ```

### **Étape 2 : Vérifier le Résultat**

Le script va :
- ✅ **Nettoyer** les anciennes politiques RLS
- ✅ **Créer** de nouvelles politiques correctes
- ✅ **Recréer** la fonction d'isolation
- ✅ **Recréer** le trigger automatique
- ✅ **Tester** l'insertion

## 🧪 Test de Validation

### **Test 1 : Création de Commande**
1. Aller sur http://localhost:3001/
2. Se connecter avec test27@yopmail.com
3. Aller dans "Transaction" > "Suivi Commandes"
4. Cliquer sur "Nouvelle Commande"
5. Remplir les champs :
   - **Numéro de commande** : CMD-001
   - **Nom du fournisseur** : Fournisseur Test
   - **Date de commande** : Aujourd'hui
6. Cliquer sur "Sauvegarder"
7. ✅ Vérifier que la commande se crée sans erreur

### **Test 2 : Vérification Console**
1. Ouvrir les outils de développement (F12)
2. Aller dans l'onglet "Console"
3. ✅ Vérifier qu'il n'y a plus d'erreur RLS
4. ✅ Vérifier que les logs de création s'affichent

## 📋 Checklist de Validation

- [ ] **Script SQL exécuté** (correction_rls_orders.sql)
- [ ] **Test d'insertion réussi** dans le script
- [ ] **Création de commande** fonctionne dans l'application
- [ ] **Pas d'erreur RLS** dans la console
- [ ] **Données isolées** par atelier

## 🎯 Résultat Attendu

Après application des corrections :
- ✅ **Création de commandes** sans erreur RLS
- ✅ **Modification de commandes** sans erreur
- ✅ **Isolation automatique** par workshop_id
- ✅ **Console propre** sans erreurs de sécurité

## 🔧 Détails Techniques

### **Problème Avant**
```sql
-- Politiques RLS mal configurées
-- Triggers d'isolation manquants
-- workshop_id non défini automatiquement
```

### **Solution Après**
```sql
-- Politiques RLS correctes avec workshop_id
-- Trigger automatique pour définir workshop_id
-- Fonction d'isolation robuste
```

### **Fonction d'Isolation**
```sql
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
BEGIN
    -- Définir automatiquement workshop_id et created_by
    NEW.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id');
    NEW.created_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 🆘 Si le Problème Persiste

### **Vérification Supplémentaire**

1. **Vérifier le workshop_id**
   ```sql
   SELECT * FROM system_settings WHERE key = 'workshop_id';
   ```

2. **Vérifier les politiques RLS**
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'orders';
   ```

3. **Vérifier les triggers**
   ```sql
   SELECT * FROM information_schema.triggers WHERE event_object_table = 'orders';
   ```

### **Solutions Avancées**

1. **Recréer complètement les tables**
   - Exécuter `tables/creation_tables_commandes_isolation.sql`
   - Puis `tables/correction_rls_orders.sql`

2. **Vérifier l'authentification**
   - S'assurer que l'utilisateur est connecté
   - Vérifier que `auth.uid()` retourne une valeur

## 📞 Support

Si le problème persiste après ces étapes :
1. **Résultat du script de correction**
2. **Logs de la console** après correction
3. **Screenshot de l'erreur** si elle persiste

---

**⏱️ Temps estimé de résolution : 5 minutes**

**🎯 Problème résolu : Politiques RLS et isolation**

