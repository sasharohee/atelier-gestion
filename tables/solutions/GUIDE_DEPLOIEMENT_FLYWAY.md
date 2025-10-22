# Guide de Déploiement avec Flyway - Atelier Gestion

## 🎯 Objectif

Ce guide vous permet de migrer votre base de données de développement vers la production en utilisant Flyway pour PostgreSQL/Supabase.

## 📋 Prérequis

1. **Flyway CLI installé** :
   ```bash
   # Installation via Homebrew (macOS)
   brew install flyway
   
   # Ou téléchargement direct
   # https://flywaydb.org/download/
   ```

2. **Accès aux bases de données** :
   - Base de développement : Supabase local ou distant
   - Base de production : Supabase production

## 🔧 Configuration

### 1. Fichiers de Configuration

Vous avez maintenant 3 fichiers de configuration Flyway :

- `flyway.toml` : Configuration générale
- `flyway.dev.toml` : Configuration développement
- `flyway.prod.toml` : Configuration production

### 2. Variables d'Environnement

Créez un fichier `.env` avec vos informations de connexion :

```env
# Développement
DEV_DB_URL=postgresql://postgres:postgres@localhost:54322/postgres
DEV_DB_USER=postgres
DEV_DB_PASSWORD=postgres

# Production
PROD_DB_URL=postgresql://postgres:EGQUN6paP21OlNUu@db.gggoqnxrspviuxadvkbh.supabase.co:5432/postgres
PROD_DB_USER=postgres
PROD_DB_PASSWORD=EGQUN6paP21OlNUu
```

## 🚀 Étapes de Déploiement

### Étape 1 : Vérification de l'Environnement de Développement

```bash
# Vérifier la configuration de développement
flyway -configFiles=flyway.dev.toml info

# Vérifier l'état des migrations
flyway -configFiles=flyway.dev.toml status
```

### Étape 2 : Test des Migrations en Développement

```bash
# Appliquer les migrations en développement
flyway -configFiles=flyway.dev.toml migrate

# Vérifier que tout s'est bien passé
flyway -configFiles=flyway.dev.toml info
```

### Étape 3 : Sauvegarde de la Base de Production

⚠️ **IMPORTANT** : Toujours faire une sauvegarde avant de migrer en production !

```bash
# Sauvegarde de la base de production
pg_dump "postgresql://postgres:EGQUN6paP21OlNUu@db.gggoqnxrspviuxadvkbh.supabase.co:5432/postgres" > backup_prod_$(date +%Y%m%d_%H%M%S).sql
```

### Étape 4 : Migration vers la Production

```bash
# Vérifier l'état de la production
flyway -configFiles=flyway.prod.toml info

# Appliquer les migrations en production
flyway -configFiles=flyway.prod.toml migrate

# Vérifier le résultat
flyway -configFiles=flyway.prod.toml info
```

## 📁 Structure des Migrations

Vos migrations sont organisées comme suit :

```
migrations/
├── V1__Initial_Schema.sql          # Types et tables de base
├── V2__Complete_Schema.sql         # Tables principales
├── V3__Additional_Tables.sql       # Tables supplémentaires
├── V4__Indexes_And_Constraints.sql # Index et contraintes
└── V5__RLS_Policies.sql           # Politiques de sécurité
```

## 🔍 Commandes Utiles

### Vérification de l'État

```bash
# État des migrations
flyway -configFiles=flyway.prod.toml info

# Historique des migrations
flyway -configFiles=flyway.prod.toml history
```

### Gestion des Migrations

```bash
# Nettoyer la base (ATTENTION : supprime toutes les données)
flyway -configFiles=flyway.dev.toml clean

# Valider les migrations sans les appliquer
flyway -configFiles=flyway.prod.toml validate

# Réparer la table flyway_schema_history
flyway -configFiles=flyway.prod.toml repair
```

### Rollback (si nécessaire)

```bash
# Rollback vers une version spécifique
flyway -configFiles=flyway.prod.toml undo -target=4

# Rollback complet (nécessite une sauvegarde)
flyway -configFiles=flyway.prod.toml clean
# Puis restaurer depuis la sauvegarde
```

## 🛠️ Scripts d'Automatisation

### Script de Déploiement Complet

Créez un fichier `deploy.sh` :

```bash
#!/bin/bash

echo "🚀 Déploiement Atelier Gestion avec Flyway"

# Vérification des prérequis
if ! command -v flyway &> /dev/null; then
    echo "❌ Flyway CLI n'est pas installé"
    exit 1
fi

# Sauvegarde de la production
echo "📦 Sauvegarde de la production..."
pg_dump "postgresql://postgres:EGQUN6paP21OlNUu@db.gggoqnxrspviuxadvkbh.supabase.co:5432/postgres" > backup_prod_$(date +%Y%m%d_%H%M%S).sql

# Test en développement
echo "🧪 Test des migrations en développement..."
flyway -configFiles=flyway.dev.toml migrate

if [ $? -eq 0 ]; then
    echo "✅ Migrations de développement réussies"
else
    echo "❌ Échec des migrations de développement"
    exit 1
fi

# Déploiement en production
echo "🚀 Déploiement en production..."
flyway -configFiles=flyway.prod.toml migrate

if [ $? -eq 0 ]; then
    echo "✅ Déploiement réussi !"
    flyway -configFiles=flyway.prod.toml info
else
    echo "❌ Échec du déploiement"
    echo "💡 Vérifiez les logs et restaurez depuis la sauvegarde si nécessaire"
    exit 1
fi
```

### Script de Vérification

Créez un fichier `verify.sh` :

```bash
#!/bin/bash

echo "🔍 Vérification de l'état des bases de données"

echo "📊 État de la base de développement :"
flyway -configFiles=flyway.dev.toml info

echo ""
echo "📊 État de la base de production :"
flyway -configFiles=flyway.prod.toml info
```

## 🚨 Gestion des Erreurs

### Erreurs Courantes

1. **Erreur de connexion** :
   - Vérifiez les URLs de connexion
   - Vérifiez les identifiants
   - Vérifiez que la base est accessible

2. **Erreur de migration** :
   - Vérifiez la syntaxe SQL
   - Vérifiez les dépendances entre tables
   - Vérifiez les contraintes

3. **Erreur de permissions** :
   - Vérifiez les droits d'accès à la base
   - Vérifiez les politiques RLS

### Logs et Debug

```bash
# Activer les logs détaillés
flyway -configFiles=flyway.prod.toml -X migrate

# Vérifier les logs Flyway
flyway -configFiles=flyway.prod.toml info -X
```

## 📞 Support

En cas de problème :

1. Vérifiez les logs Flyway
2. Vérifiez l'état des migrations avec `flyway info`
3. Consultez la documentation Flyway : https://flywaydb.org/documentation/
4. Restaurez depuis la sauvegarde si nécessaire

## ✅ Checklist de Déploiement

- [ ] Flyway CLI installé
- [ ] Configuration des fichiers Flyway
- [ ] Test des migrations en développement
- [ ] Sauvegarde de la production
- [ ] Migration vers la production
- [ ] Vérification du résultat
- [ ] Test de l'application en production

---

**Note** : Ce guide assume que vous utilisez Supabase. Adaptez les URLs de connexion selon votre configuration.
