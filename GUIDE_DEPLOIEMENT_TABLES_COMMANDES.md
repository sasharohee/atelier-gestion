# 🗄️ Guide de Déploiement - Tables de Commandes

## 📋 Vue d'ensemble

Ce guide explique comment déployer les tables SQL pour le suivi des commandes avec isolation des données par atelier. Les tables garantissent que chaque atelier ne voit que ses propres commandes.

## 🏗️ Architecture des Tables

### Tables créées :
1. **`orders`** - Commandes principales
2. **`order_items`** - Articles de commande
3. **`suppliers`** - Fournisseurs (optionnel)

### Isolation des données :
- ✅ **`workshop_id`** - Identifie l'atelier propriétaire
- ✅ **`created_by`** - Identifie l'utilisateur créateur
- ✅ **Politiques RLS** - Contrôle d'accès par atelier
- ✅ **Triggers automatiques** - Définition automatique des valeurs d'isolation

## 🚀 Étapes de Déploiement

### Étape 1 : Accéder à Supabase
1. Allez sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Connectez-vous à votre compte
3. Sélectionnez votre projet : `wlqyrmntfxwdvkzzsujv`

### Étape 2 : Ouvrir SQL Editor
1. Dans le menu de gauche, cliquez sur **"SQL Editor"**
2. Cliquez sur **"New query"** pour créer un nouveau script

### Étape 3 : Exécuter le script de création
1. Copiez le contenu du fichier `tables/creation_tables_commandes_isolation.sql`
2. Collez-le dans l'éditeur SQL
3. Cliquez sur **"Run"** pour exécuter le script

### Étape 4 : Vérifier le déploiement
1. Créez un nouveau script SQL
2. Copiez le contenu du fichier `tables/verification_isolation_commandes.sql`
3. Exécutez le script pour vérifier que tout fonctionne

## 🔍 Vérification du Déploiement

### Résultats attendus :

#### 1. **Tables créées** ✅
```sql
-- Vérifier que les tables existent
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('orders', 'order_items', 'suppliers');
```

#### 2. **Colonnes d'isolation** ✅
```sql
-- Vérifier les colonnes workshop_id et created_by
SELECT table_name, column_name 
FROM information_schema.columns 
WHERE column_name IN ('workshop_id', 'created_by')
AND table_name IN ('orders', 'order_items', 'suppliers');
```

#### 3. **Politiques RLS** ✅
```sql
-- Vérifier les politiques d'isolation
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('orders', 'order_items', 'suppliers');
```

#### 4. **Triggers automatiques** ✅
```sql
-- Vérifier les triggers d'isolation
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%isolation%';
```

## 🔐 Sécurité et Isolation

### Principe d'isolation :
- **Chaque atelier** a un `workshop_id` unique
- **Chaque commande** est associée à un `workshop_id`
- **Les politiques RLS** filtrent les données par `workshop_id`
- **Les triggers** définissent automatiquement le `workshop_id` lors de l'insertion

### Politiques de sécurité :
- **SELECT** : Seules les commandes de l'atelier actuel sont visibles
- **INSERT** : Les nouvelles commandes sont automatiquement associées à l'atelier
- **UPDATE** : Seules les commandes de l'atelier peuvent être modifiées
- **DELETE** : Seules les commandes de l'atelier peuvent être supprimées

## 📊 Fonctionnalités Incluses

### 1. **Gestion des commandes**
- Création, modification, suppression
- Statuts : En attente, Confirmée, Expédiée, Livrée, Annulée
- Numéros de suivi
- Dates de livraison

### 2. **Gestion des articles**
- Ajout, modification, suppression d'articles
- Calcul automatique des totaux
- Quantités et prix unitaires

### 3. **Gestion des fournisseurs**
- Informations complètes des fournisseurs
- Réutilisation pour les futures commandes
- Évaluation et notes

### 4. **Statistiques et recherche**
- Fonction `get_order_stats()` pour les statistiques
- Fonction `search_orders()` pour la recherche
- Filtrage par statut et recherche textuelle

## 🛠️ Fonctions Utilitaires

### Statistiques des commandes :
```sql
SELECT * FROM get_order_stats();
```

### Recherche de commandes :
```sql
SELECT * FROM search_orders('terme de recherche', 'status');
```

### Test d'isolation :
```sql
SELECT * FROM test_order_isolation();
```

## 🔧 Configuration Avancée

### Modification des politiques RLS :
Si vous devez modifier les politiques de sécurité, utilisez :

```sql
-- Exemple : Politique plus permissive pour les admins
CREATE POLICY orders_admin_policy ON orders
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id')
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'admin'
        )
    );
```

### Ajout d'index personnalisés :
```sql
-- Exemple : Index pour recherche rapide
CREATE INDEX idx_orders_supplier_search ON orders 
USING gin(to_tsvector('french', supplier_name));
```

## 🚨 Dépannage

### Problème : Erreur 403 lors de l'insertion
**Solution** : Vérifiez que le `workshop_id` est configuré dans `system_settings`

### Problème : Les commandes ne s'affichent pas
**Solution** : Vérifiez les politiques RLS et le `workshop_id` actuel

### Problème : Erreur de contrainte unique
**Solution** : Vérifiez que le numéro de commande est unique pour l'atelier

## 📈 Performance

### Index créés automatiquement :
- `idx_orders_workshop_id` - Isolation par atelier
- `idx_orders_status` - Filtrage par statut
- `idx_orders_order_date` - Tri par date
- `idx_order_items_order_id` - Relation commande-articles

### Optimisations recommandées :
- Les requêtes sont optimisées pour l'isolation par `workshop_id`
- Les index composites améliorent les performances des requêtes fréquentes
- Les triggers sont optimisés pour les opérations en lot

## ✅ Checklist de Déploiement

- [ ] Script de création exécuté avec succès
- [ ] Tables `orders`, `order_items`, `suppliers` créées
- [ ] Colonnes `workshop_id` et `created_by` présentes
- [ ] Politiques RLS activées et configurées
- [ ] Triggers d'isolation créés
- [ ] Fonctions utilitaires disponibles
- [ ] Test d'isolation passé
- [ ] Index de performance créés
- [ ] Contraintes et vérifications configurées

## 🎯 Prochaines Étapes

Après le déploiement des tables :
1. **Tester l'isolation** avec plusieurs comptes
2. **Intégrer avec l'application** en modifiant le service
3. **Configurer les permissions** utilisateur si nécessaire
4. **Documenter les procédures** de maintenance

## 📞 Support

En cas de problème :
1. Vérifiez les logs SQL dans Supabase
2. Exécutez le script de vérification
3. Consultez la documentation Supabase sur RLS
4. Contactez l'équipe de développement

