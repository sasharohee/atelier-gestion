#!/bin/bash

echo "🚀 Déploiement Atelier Gestion avec Flyway"

# Vérification des prérequis
if ! command -v flyway &> /dev/null; then
    echo "❌ Flyway CLI n'est pas installé"
    echo "💡 Installez-le avec: brew install flyway"
    exit 1
fi

# Vérification des fichiers de configuration
if [ ! -f "flyway.dev.toml" ] || [ ! -f "flyway.prod.toml" ]; then
    echo "❌ Fichiers de configuration Flyway manquants"
    exit 1
fi

# Sauvegarde de la production
echo "📦 Sauvegarde de la production..."
BACKUP_FILE="backup_prod_$(date +%Y%m%d_%H%M%S).sql"
pg_dump "postgresql://postgres:EGQUN6paP21OlNUu@db.gggoqnxrspviuxadvkbh.supabase.co:5432/postgres" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Sauvegarde créée: $BACKUP_FILE"
else
    echo "❌ Échec de la sauvegarde"
    exit 1
fi

# Test en développement
echo "🧪 Test des migrations en développement..."
flyway -configFiles=flyway.dev.toml migrate

if [ $? -eq 0 ]; then
    echo "✅ Migrations de développement réussies"
else
    echo "❌ Échec des migrations de développement"
    exit 1
fi

# Demande de confirmation pour la production
echo ""
echo "⚠️  Vous êtes sur le point de déployer en PRODUCTION"
echo "📦 Sauvegarde créée: $BACKUP_FILE"
read -p "Continuer le déploiement en production ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Déploiement annulé"
    exit 1
fi

# Déploiement en production
echo "🚀 Déploiement en production..."
flyway -configFiles=flyway.prod.toml migrate

if [ $? -eq 0 ]; then
    echo "✅ Déploiement réussi !"
    echo ""
    echo "📊 État final de la production :"
    flyway -configFiles=flyway.prod.toml info
else
    echo "❌ Échec du déploiement"
    echo "💡 Vérifiez les logs et restaurez depuis la sauvegarde si nécessaire"
    echo "🔄 Pour restaurer: psql -f $BACKUP_FILE"
    exit 1
fi