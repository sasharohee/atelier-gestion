# 🚨 Guide de Dépannage - Isolation des Niveaux de Fidélité

## 🔍 Diagnostic du Problème

Si l'isolation des niveaux de fidélité ne fonctionne pas, suivez ce guide étape par étape.

## 📋 Étapes de Diagnostic

### Étape 1 : Exécuter le Diagnostic
1. **Ouvrir Supabase Dashboard**
2. **Aller dans SQL Editor**
3. **Exécuter le script :** `diagnostic_isolation_loyalty_levels.sql`

Ce script va vérifier :
- ✅ État des tables (RLS activé/désactivé)
- ✅ Présence des colonnes `workshop_id`
- ✅ Politiques RLS actuelles
- ✅ Triggers existants
- ✅ Fonctions utilitaires
- ✅ Données existantes
- ✅ Test d'isolation

### Étape 2 : Analyser les Résultats

#### ❌ **Problème 1 : RLS Désactivé**
```
❌ RLS Désactivé
```
**Solution :** Exécuter le script de correction d'urgence

#### ❌ **Problème 2 : Colonne workshop_id Manquante**
```
❌ workshop_id manquant
```
**Solution :** Exécuter le script de correction d'urgence

#### ❌ **Problème 3 : Politiques RLS Manquantes**
```
Aucune politique trouvée
```
**Solution :** Exécuter le script de correction d'urgence

#### ❌ **Problème 4 : Données Sans workshop_id**
```
Niveaux d'autres utilisateurs: 5
```
**Solution :** Exécuter le script de correction d'urgence

## 🛠️ Solution : Script de Correction d'Urgence

### Étape 1 : Exécuter le Script de Correction
1. **Ouvrir Supabase Dashboard**
2. **Aller dans SQL Editor**
3. **Exécuter le script :** `fix_loyalty_isolation_urgence.sql`

Ce script va :
- ✅ **Forcer l'ajout** des colonnes `workshop_id`
- ✅ **Migrer toutes les données** vers l'utilisateur actuel
- ✅ **Activer RLS** sur les tables
- ✅ **Supprimer les anciennes politiques** défaillantes
- ✅ **Créer des politiques ultra-strictes**
- ✅ **Créer des triggers ultra-stricts**
- ✅ **Recréer les fonctions utilitaires**
- ✅ **Tester l'isolation**

### Étape 2 : Vérifier la Correction
Après l'exécution, vous devriez voir :
```
✅ RLS Activé
✅ workshop_id présent
✅ Ultra-strict (pour les politiques)
✅ Fonction get_workshop_loyalty_tiers() fonctionne
✅ ISOLATION PARFAITE: Aucune donnée d'autre utilisateur visible
```

## 🔧 Dépannage Avancé

### Problème : "Erreur 403 Forbidden"
**Causes possibles :**
1. Politiques RLS trop strictes
2. Utilisateur non authentifié
3. Colonne workshop_id NULL

**Solutions :**
```sql
-- Vérifier l'utilisateur actuel
SELECT auth.uid() as current_user_id;

-- Vérifier les données sans workshop_id
SELECT COUNT(*) FROM loyalty_tiers_advanced WHERE workshop_id IS NULL;
```

### Problème : "Fonctions non trouvées"
**Solution :**
```sql
-- Recréer les fonctions
CREATE OR REPLACE FUNCTION get_workshop_loyalty_tiers()
RETURNS TABLE(...) AS $$
-- Voir le script de correction pour le code complet
$$;
```

### Problème : "Données partagées entre ateliers"
**Solution :**
```sql
-- Forcer la migration vers l'utilisateur actuel
UPDATE loyalty_tiers_advanced 
SET workshop_id = auth.uid() 
WHERE workshop_id IS NULL OR workshop_id != auth.uid();
```

## 🧪 Tests de Validation

### Test 1 : Vérifier l'Isolation
```sql
-- Ce test doit retourner 0
SELECT COUNT(*) FROM loyalty_tiers_advanced 
WHERE workshop_id != auth.uid();
```

### Test 2 : Vérifier les Fonctions
```sql
-- Ce test doit retourner vos niveaux
SELECT * FROM get_workshop_loyalty_tiers();
```

### Test 3 : Test de Création
```sql
-- Ce test doit réussir
INSERT INTO loyalty_tiers_advanced (
    name, points_required, discount_percentage, color, description, is_active
) VALUES (
    'Test', 50, 2.5, '#FF0000', 'Test d''isolation', true
);
```

## 🚨 Solutions d'Urgence

### Si Rien Ne Fonctionne

#### Solution 1 : Reset Complet
```sql
-- ATTENTION : Ceci supprime TOUTES les données de fidélité
DROP TABLE IF EXISTS loyalty_tiers_advanced CASCADE;
DROP TABLE IF EXISTS loyalty_config CASCADE;

-- Puis exécuter le script de création complet
```

#### Solution 2 : Désactiver Temporairement RLS
```sql
-- ATTENTION : Ceci désactive la sécurité
ALTER TABLE loyalty_tiers_advanced DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_config DISABLE ROW LEVEL SECURITY;

-- Filtrer côté application uniquement
```

#### Solution 3 : Isolation Manuelle
```sql
-- Forcer l'isolation en supprimant les données d'autres utilisateurs
DELETE FROM loyalty_tiers_advanced 
WHERE workshop_id IS NULL OR workshop_id != auth.uid();

DELETE FROM loyalty_config 
WHERE workshop_id IS NULL OR workshop_id != auth.uid();
```

## 📞 Support

### Logs à Vérifier
1. **Console du navigateur** : Erreurs JavaScript
2. **Logs Supabase** : Erreurs de base de données
3. **Réseau** : Requêtes qui échouent

### Informations à Fournir
1. **Résultats du diagnostic** : Copier-coller complet
2. **Messages d'erreur** : Exactement ce qui s'affiche
3. **Comportement attendu** : Ce qui devrait se passer
4. **Comportement actuel** : Ce qui se passe réellement

## ✅ Checklist de Validation

Après la correction, vérifiez que :

- [ ] **RLS est activé** sur les tables
- [ ] **Colonnes workshop_id** sont présentes
- [ ] **Politiques ultra-strictes** sont créées
- [ ] **Triggers** sont actifs
- [ ] **Fonctions utilitaires** fonctionnent
- [ ] **Données migrées** vers l'utilisateur actuel
- [ ] **Test d'isolation** passe
- [ ] **Interface utilisateur** charge les niveaux
- [ ] **Création de niveaux** fonctionne
- [ ] **Modification de niveaux** fonctionne

## 🎯 Résultat Attendu

Après la correction :
- ✅ **Chaque atelier ne voit que ses propres niveaux**
- ✅ **Modifications isolées** entre ateliers
- ✅ **Interface fonctionnelle** et réactive
- ✅ **Sécurité renforcée** avec RLS ultra-strict

---

**🚨 Si le problème persiste après avoir suivi ce guide, contactez le support avec les résultats du diagnostic.**
