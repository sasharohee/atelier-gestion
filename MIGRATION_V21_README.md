# 🚀 Migrations V21 & V22 - Corrections de Production et SAV

## 📋 Résumé

Ces migrations (V21 & V22) contiennent toutes les corrections critiques et fonctionnalités nécessaires pour déployer l'application en production. Elles résolvent les erreurs 500, corrigent les problèmes de base de données, assurent la synchronisation des utilisateurs et ajoutent toutes les fonctionnalités SAV.

## 🎯 Objectifs des Migrations

### Migration V21 - Corrections de Production
- ✅ **Créer la table `system_settings`** manquante
- ✅ **Ajouter la colonne `items`** à la table `sales`
- ✅ **Corriger les politiques RLS** (récursion infinie)
- ✅ **Synchroniser automatiquement** les utilisateurs
- ✅ **Créer les fonctions d'administration**

### Migration V22 - Fonctionnalités SAV
- ✅ **Créer toutes les tables SAV** (repairs, parts, services, etc.)
- ✅ **Ajouter la colonne `source`** à repairs pour distinguer SAV du Kanban
- ✅ **Créer les tables de liaison** (repair_services, repair_parts)
- ✅ **Créer les tables de suivi** (appointments, messages, notifications)
- ✅ **Configurer les fonctions et triggers** SAV
- ✅ **Ajouter les alertes de stock** et gestion des pièces

## 📁 Fichiers Inclus

### Migrations Flyway
- `migrations/V21__Production_Ready_Fixes.sql` - Corrections de production
- `migrations/V22__SAV_Tables_And_Features.sql` - Tables et fonctionnalités SAV

### Scripts de Déploiement
- `deploy_production_migration.sh` - Script automatisé de déploiement

### Configuration
- `flyway.prod.toml` - Configuration Flyway pour la production

## 🔧 Corrections Appliquées

### 1. Table `system_settings`
```sql
CREATE TABLE public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    key VARCHAR(255) NOT NULL,
    value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 2. Colonne `items` dans `sales`
```sql
ALTER TABLE public.sales ADD COLUMN IF NOT EXISTS items JSONB DEFAULT '[]'::jsonb;
```

### 3. Politiques RLS Corrigées
- Suppression des politiques récursives
- Création de nouvelles politiques sans récursion
- Fonction `is_admin()` sécurisée

### 4. Synchronisation Utilisateurs
- Trigger automatique `sync_auth_user_safe()`
- Fonction `repair_all_users()` pour les utilisateurs existants
- Synchronisation vers `users` et `subscription_status`

### 5. Fonctions d'Administration
- `get_all_users_as_admin()`
- `get_all_subscription_status_as_admin()`
- `update_subscription_status_as_admin()`

## 🚀 Déploiement

### Option 1: Script Automatisé (Recommandé)
```bash
chmod +x deploy_production_migration.sh
./deploy_production_migration.sh
```

### Option 2: Manuel avec Flyway
```bash
flyway -configFiles=flyway.prod.toml migrate
```

### Option 3: Directement dans Supabase
1. Ouvrir Supabase SQL Editor
2. Copier le contenu de `V21__Production_Ready_Fixes.sql`
3. Exécuter le script

## 🧪 Tests de Validation

### Après le déploiement, vérifiez :

1. **Table system_settings créée**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_name = 'system_settings';
```

2. **Colonne items ajoutée à sales**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'sales' AND column_name = 'items';
```

3. **Fonctions créées**
```sql
SELECT routine_name FROM information_schema.routines 
WHERE routine_name IN ('is_admin', 'sync_auth_user_safe', 'repair_all_users');
```

4. **Utilisateurs synchronisés**
```sql
SELECT COUNT(*) FROM public.users;
SELECT COUNT(*) FROM public.subscription_status;
```

## ⚠️ Points d'Attention

### Sécurité
- Les nouveaux utilisateurs sont créés avec `is_active = false`
- Les administrateurs doivent activer manuellement les nouveaux utilisateurs
- Les politiques RLS sont strictement appliquées

### Performance
- Index créés sur `system_settings` pour les performances
- Trigger optimisé pour éviter les blocages

### Données Existantes
- Les utilisateurs existants sont automatiquement synchronisés
- Les données existantes sont préservées
- Pas de perte de données

## 🔍 Vérifications Post-Déploiement

### 1. Application Fonctionnelle
- ✅ Plus d'erreurs 500
- ✅ Inscription des nouveaux utilisateurs
- ✅ Création de ventes fonctionnelle
- ✅ Paramètres système accessibles

### 2. Base de Données
- ✅ Toutes les tables créées
- ✅ Toutes les colonnes ajoutées
- ✅ Politiques RLS actives
- ✅ Triggers fonctionnels

### 3. Utilisateurs
- ✅ Synchronisation automatique
- ✅ Isolation des données
- ✅ Permissions correctes

## 🆘 Dépannage

### Erreur de Migration
```bash
# Vérifier l'état des migrations
flyway -configFiles=flyway.prod.toml info

# Valider les migrations
flyway -configFiles=flyway.prod.toml validate
```

### Problème de Connexion
```bash
# Tester la connexion
flyway -configFiles=flyway.prod.toml validate
```

### Utilisateurs Non Synchronisés
```sql
-- Forcer la synchronisation
SELECT * FROM repair_all_users();
```

## 📞 Support

En cas de problème :
1. Vérifier les logs Flyway
2. Consulter les messages d'erreur dans Supabase
3. Exécuter les requêtes de diagnostic
4. Contacter le support technique

## ✅ Statut

- [x] Migration V21 créée
- [x] Script de déploiement créé
- [x] Documentation complète
- [x] Tests de validation inclus
- [x] Prêt pour le déploiement en production

**La migration V21 est prête à être déployée en production ! 🚀**
