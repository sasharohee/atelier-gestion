# Guide d'exécution des migrations V13 à V22

## 🎯 Objectif

Exécuter les migrations V13 à V22 vers la base de données de production pour résoudre l'erreur 404 de la table `device_model_services`.

## 📋 Migrations à exécuter

- **V13**: Create Device Model Services
- **V14**: Fix Device Model Services Structure  
- **V15**: Fix Device Model Services RLS
- **V16**: Fix Device Model Services View Simple
- **V17**: Add Test Data Device Model Services
- **V18**: Debug Device Model Services Data
- **V19**: Fix Device Model Services View Final
- **V20**: Fix Device Models Category Type
- **V21**: Production Ready Fixes
- **V22**: SAV Tables And Features

## 🚀 Méthodes d'exécution

### Méthode 1 : Script automatisé (Recommandé)

```bash
# 1. Vérifier que tout est prêt
./check_migration_readiness.sh

# 2. Exécuter les migrations
./run_migrations_v13_to_v22.sh
```

### Méthode 2 : Flyway Desktop

```bash
# 1. Vérifier la préparation
./check_migration_readiness.sh

# 2. Suivre les instructions Flyway Desktop
./run_migrations_flyway_desktop.sh
```

### Méthode 3 : Flyway CLI manuel

```bash
# Vérifier l'état actuel
flyway -configFiles=flyway.prod.toml info

# Exécuter les migrations
flyway -configFiles=flyway.prod.toml migrate
```

## ⚠️ Prérequis

1. **Configuration Flyway** : ✅ Déjà configurée
   - `flyway.prod.toml` - Configuration production
   - `flyway.toml` - Configuration principale

2. **Base de données** : ✅ Accessible
   - URL: `db.wlqyrmntfxwdvkzzsujv.supabase.co:5432`
   - Base: `postgres`
   - Utilisateur: `postgres`

3. **Migrations** : ✅ Présentes
   - Dossier `migrations/` avec tous les fichiers V13 à V22

## 🔍 Vérification préalable

Avant d'exécuter, vérifiez que :

1. **Toutes les migrations existent** :
   ```bash
   ls migrations/V1[3-9]__*.sql migrations/V2[0-2]__*.sql
   ```

2. **La configuration est correcte** :
   ```bash
   cat flyway.prod.toml
   ```

3. **La connectivité fonctionne** :
   ```bash
   flyway -configFiles=flyway.prod.toml info
   ```

## 🎯 Résultat attendu

Après l'exécution des migrations :

- ✅ Table `device_model_services` créée
- ✅ Vue `device_model_services_detailed` créée
- ✅ Politiques RLS configurées
- ✅ Fonctions RPC créées
- ✅ L'erreur 404 disparaît

## 🧪 Test après migration

1. **Rechargez l'application**
2. **Allez dans la section "Modèles"**
3. **Essayez de créer une association service-modèle**
4. **Vérifiez qu'il n'y a plus d'erreur 404 dans la console**

## 🚨 En cas de problème

### Erreur de connectivité
```bash
# Vérifier la configuration
cat flyway.prod.toml

# Tester la connexion
flyway -configFiles=flyway.prod.toml info
```

### Erreur de migration
```bash
# Voir l'état actuel
flyway -configFiles=flyway.prod.toml info

# Réparer si nécessaire
flyway -configFiles=flyway.prod.toml repair
```

### Rollback (si nécessaire)
```bash
# ATTENTION: Rollback peut causer une perte de données
# Utilisez uniquement si absolument nécessaire
flyway -configFiles=flyway.prod.toml undo
```

## 📊 Monitoring

Après l'exécution, vérifiez :

1. **État des migrations** :
   ```bash
   flyway -configFiles=flyway.prod.toml info
   ```

2. **Tables créées** :
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name LIKE '%device_model%';
   ```

3. **Vue fonctionnelle** :
   ```sql
   SELECT * FROM public.device_model_services_detailed LIMIT 5;
   ```

## 🎉 Succès

Une fois les migrations exécutées avec succès :

- ✅ L'erreur 404 sera résolue
- ✅ Les fonctionnalités de gestion des services fonctionneront
- ✅ L'application sera pleinement opérationnelle

## 📞 Support

En cas de problème :

1. Vérifiez les logs de Flyway
2. Consultez l'état de la base de données
3. Vérifiez la connectivité réseau
4. Contactez l'équipe de développement si nécessaire
