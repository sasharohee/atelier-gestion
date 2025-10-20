# Correction de l'erreur 404 - Table device_model_services manquante

## 🚨 Problème Identifié

L'application génère une erreur 404 lors de l'accès à la table `device_model_services` :

```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/device_model_services?select=id&device_model_id=eq.7297bc5e-216a-4e1b-8c94-d038d018d98d&service_id=eq.e186305c-1f7f-4c13-893b-1ee225d09c32 404 (Not Found)
```

**Cause :** La table `device_model_services` n'existe pas dans la base de données de production.

**Problème de type corrigé :** Les colonnes `brand_id` et `category_id` utilisent le type `TEXT` (pas `UUID`) pour être compatibles avec les tables existantes.

## ✅ Solution

### 1. Fichiers Créés

- **`check_and_create_device_model_services.sql`** - Script complet avec vérification et création
- **`deploy_fix_device_model_services.sh`** - Script de déploiement simplifié
- **`create_device_model_services_table.sql`** - Migration SQL complète (corrigée pour les types)
- **`test_device_model_services_migration.sql`** - Script de test pour vérifier la migration

### 2. Étapes de Correction

#### Étape 1 : Accéder au Dashboard Supabase
1. Allez sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Connectez-vous à votre compte
3. Sélectionnez votre projet

#### Étape 2 : Exécuter la Migration
1. Dans le dashboard Supabase, cliquez sur **"SQL Editor"** dans le menu de gauche
2. Cliquez sur **"New query"** pour créer une nouvelle requête
3. Copiez tout le contenu du fichier `check_and_create_device_model_services.sql`
4. Collez-le dans l'éditeur SQL
5. Cliquez sur **"Run"** pour exécuter le script

#### Étape 3 : Vérifier l'Installation
1. Vérifiez que vous voyez les messages de succès dans l'éditeur SQL :
   - ✅ Table device_model_services existe
   - ✅ Vue device_model_services_detailed existe
   - ✅ Politiques RLS configurées
2. Retournez sur votre application
3. L'erreur 404 devrait disparaître
4. Les fonctionnalités de gestion des services par modèle devraient fonctionner

## 🔧 Ce que fait la Migration

### Table `device_model_services`
- **Structure complète** avec toutes les colonnes nécessaires
- **Relations** avec device_models, services, device_brands, device_categories
- **Contraintes d'unicité** pour éviter les doublons
- **Index** pour optimiser les performances

### Vue `device_model_services_detailed`
- **Vue enrichie** avec toutes les informations pour l'affichage
- **Prix et durée effectifs** (personnalisés ou par défaut)
- **Informations complètes** des modèles, services, marques et catégories

### Fonctions RPC
- **`get_services_for_model`** - Obtenir les services d'un modèle
- **`get_services_for_brand_category`** - Obtenir les services par marque/catégorie

### Sécurité
- **RLS activé** avec politiques pour utilisateurs authentifiés
- **Permissions** de lecture, écriture, mise à jour et suppression

### Performance
- **Index** sur toutes les colonnes importantes
- **Trigger** pour mise à jour automatique de `updated_at`

## 📋 Prérequis

Assurez-vous que ces tables existent déjà :
- ✅ `device_models`
- ✅ `services`
- ✅ `device_brands`
- ✅ `device_categories`
- ✅ `workshops` (optionnel)

## 🎯 Résultat Attendu

Après l'application de la migration :
- ✅ L'erreur 404 disparaît
- ✅ Les associations modèle-service fonctionnent
- ✅ Les prix et durées personnalisés sont supportés
- ✅ L'interface de gestion des services est opérationnelle

## 🔍 Vérification

Pour vérifier que la migration a fonctionné :

1. **Dans Supabase SQL Editor :**
```sql
SELECT COUNT(*) FROM public.device_model_services;
```

2. **Dans l'application :**
- Aller dans la section "Modèles"
- Essayer de créer une association service-modèle
- Vérifier qu'il n'y a plus d'erreur 404

## 🚨 En cas de Problème

Si l'erreur persiste :

1. **Vérifier les dépendances :**
```sql
-- Vérifier que les tables existent
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('device_models', 'services', 'device_brands', 'device_categories');
```

2. **Vérifier les permissions :**
```sql
-- Vérifier les politiques RLS
SELECT * FROM pg_policies WHERE tablename = 'device_model_services';
```

3. **Vérifier la vue :**
```sql
-- Tester la vue
SELECT * FROM public.device_model_services_detailed LIMIT 5;
```

## 📞 Support

Si le problème persiste après l'application de la migration, vérifiez :
- Les logs de l'application dans la console du navigateur
- Les logs Supabase dans le dashboard
- La structure des tables dépendantes
