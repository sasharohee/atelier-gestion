# 🏪 Guide - Isolation des Niveaux de Fidélité par Atelier

## 🎯 Objectif

Ce guide explique comment les niveaux de fidélité sont maintenant **uniques pour chaque atelier**. Chaque réparateur peut personnaliser ses propres niveaux de fidélité selon ses préférences et sa stratégie commerciale.

## ✅ Problème Résolu

**Avant :** Tous les ateliers partageaient les mêmes niveaux de fidélité
**Maintenant :** Chaque atelier a ses propres niveaux personnalisables

## 🔧 Fonctionnalités Implémentées

### 1. **Isolation Complète par Atelier**
- ✅ Chaque atelier ne voit que ses propres niveaux
- ✅ Modifications isolées (un atelier ne peut pas affecter un autre)
- ✅ Configuration personnalisable par atelier

### 2. **Sécurité Renforcée**
- ✅ Politiques RLS (Row Level Security) strictes
- ✅ Triggers automatiques pour `workshop_id`
- ✅ Fonctions utilitaires sécurisées

### 3. **Interface Utilisateur Mise à Jour**
- ✅ Chargement automatique des niveaux de l'atelier
- ✅ Création de niveaux par défaut pour chaque atelier
- ✅ Messages informatifs sur l'isolation

## 📋 Étapes d'Installation

### Étape 1 : Exécuter le Script SQL
1. **Ouvrir Supabase Dashboard**
2. **Aller dans SQL Editor**
3. **Exécuter le script :** `fix_loyalty_levels_workshop_isolation.sql`

```sql
-- Le script va :
-- ✅ Ajouter workshop_id aux tables
-- ✅ Migrer les données existantes
-- ✅ Créer les politiques RLS
-- ✅ Créer les fonctions utilitaires
-- ✅ Tester l'isolation
```

### Étape 2 : Redéployer l'Application
```bash
# Redéployer l'application pour prendre en compte les changements
npm run build
# ou
yarn build
```

### Étape 3 : Tester l'Isolation
```bash
# Exécuter le script de test
node test_loyalty_isolation.js
```

## 🎮 Utilisation

### Pour les Réparateurs

#### 1. **Accéder aux Paramètres de Fidélité**
- Aller dans **Points de Fidélité** → **Paramètres**
- Cliquer sur l'onglet **"Niveaux de Fidélité"**

#### 2. **Personnaliser les Niveaux**
- **Modifier les points requis** pour chaque niveau
- **Ajuster les pourcentages de réduction**
- **Changer les descriptions** selon votre stratégie
- **Activer/désactiver** des niveaux

#### 3. **Sauvegarder les Modifications**
- Cliquer sur **"Sauvegarder Niveaux"**
- Les modifications sont automatiquement isolées à votre atelier

### Exemple de Personnalisation

**Atelier A (Réparateur iPhone) :**
- Bronze : 0 pts (0% réduction)
- Argent : 50 pts (3% réduction)
- Or : 200 pts (8% réduction)
- Platine : 500 pts (12% réduction)
- Diamant : 1000 pts (18% réduction)

**Atelier B (Réparateur Android) :**
- Bronze : 0 pts (0% réduction)
- Argent : 100 pts (5% réduction)
- Or : 300 pts (10% réduction)
- Platine : 600 pts (15% réduction)
- Diamant : 1200 pts (20% réduction)

## 🔍 Vérification de l'Isolation

### Test 1 : Vérifier les Niveaux Visibles
```sql
-- Dans Supabase SQL Editor
SELECT * FROM get_workshop_loyalty_tiers();
-- Devrait retourner seulement les niveaux de votre atelier
```

### Test 2 : Vérifier la Configuration
```sql
-- Dans Supabase SQL Editor
SELECT * FROM get_workshop_loyalty_config();
-- Devrait retourner seulement la configuration de votre atelier
```

### Test 3 : Test de Création
1. **Créer un nouveau niveau** dans l'interface
2. **Vérifier** qu'il n'apparaît que pour votre atelier
3. **Demander à un autre atelier** de vérifier qu'il ne le voit pas

## 🛠️ Fonctions Utilitaires Disponibles

### 1. **get_workshop_loyalty_tiers()**
```sql
-- Retourne les niveaux de l'atelier actuel
SELECT * FROM get_workshop_loyalty_tiers();
```

### 2. **get_workshop_loyalty_config()**
```sql
-- Retourne la configuration de l'atelier actuel
SELECT * FROM get_workshop_loyalty_config();
```

### 3. **create_default_loyalty_tiers_for_workshop(workshop_id)**
```sql
-- Crée les niveaux par défaut pour un atelier spécifique
SELECT create_default_loyalty_tiers_for_workshop('your-workshop-id');
```

## 🔒 Sécurité

### Politiques RLS Appliquées
- **SELECT** : Seuls les niveaux de l'atelier actuel sont visibles
- **INSERT** : Les nouveaux niveaux sont automatiquement assignés à l'atelier
- **UPDATE** : Seuls les niveaux de l'atelier peuvent être modifiés
- **DELETE** : Seuls les niveaux de l'atelier peuvent être supprimés

### Triggers Automatiques
- **workshop_id** est automatiquement défini lors de l'insertion
- **created_at** et **updated_at** sont automatiquement gérés
- **Validation** de l'authentification utilisateur

## 🚨 Dépannage

### Problème : "Aucun niveau trouvé"
**Solution :**
1. Cliquer sur **"Créer les Niveaux"** dans l'interface
2. Ou exécuter : `SELECT create_default_loyalty_tiers_for_workshop(auth.uid());`

### Problème : "Erreur 403 Forbidden"
**Solution :**
1. Vérifier que l'utilisateur est bien connecté
2. Vérifier que les politiques RLS sont actives
3. Redéployer l'application

### Problème : "Niveaux partagés entre ateliers"
**Solution :**
1. Vérifier que le script d'isolation a été exécuté
2. Vérifier que les colonnes `workshop_id` existent
3. Vérifier que les politiques RLS sont correctes

## 📊 Monitoring

### Vérifier l'État de l'Isolation
```sql
-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '✅ Isolation OK'
        ELSE '❌ Isolation manquante'
    END as isolation_status
FROM pg_policies 
WHERE tablename IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY tablename, policyname;
```

### Vérifier les Triggers
```sql
-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_tiers_advanced', 'loyalty_config')
ORDER BY event_object_table, trigger_name;
```

## 🎉 Résultat Final

Après l'implémentation :

✅ **Chaque atelier a ses propres niveaux de fidélité**
✅ **Personnalisation complète selon les préférences du réparateur**
✅ **Isolation sécurisée entre ateliers**
✅ **Interface utilisateur intuitive**
✅ **Fonctions utilitaires pour la gestion**

## 📞 Support

Si vous rencontrez des problèmes :

1. **Vérifier les logs** dans la console du navigateur
2. **Exécuter les scripts de test** fournis
3. **Vérifier l'état de l'isolation** avec les requêtes SQL
4. **Contacter le support** si nécessaire

---

**🎯 Objectif atteint :** Les niveaux de fidélité sont maintenant uniques pour chaque atelier selon les préférences du réparateur !
