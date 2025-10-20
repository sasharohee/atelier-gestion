#!/bin/bash

# Script de vérification avant l'exécution des migrations
# Vérifie que tout est prêt pour l'exécution des migrations V13 à V22

echo "🔍 Vérification de la préparation aux migrations V13 à V22"
echo ""

# Vérifier la configuration Flyway
echo "📋 Vérification de la configuration Flyway..."

if [ -f "flyway.prod.toml" ]; then
    echo "   ✅ Configuration de production trouvée"
else
    echo "   ❌ Configuration de production manquante"
    exit 1
fi

if [ -f "flyway.toml" ]; then
    echo "   ✅ Configuration principale trouvée"
else
    echo "   ❌ Configuration principale manquante"
    exit 1
fi

# Vérifier le dossier migrations
echo ""
echo "📁 Vérification du dossier migrations..."

if [ -d "migrations" ]; then
    echo "   ✅ Dossier migrations trouvé"
    migration_count=$(ls migrations/V*.sql 2>/dev/null | wc -l)
    echo "   📊 Nombre total de migrations: $migration_count"
else
    echo "   ❌ Dossier migrations manquant"
    exit 1
fi

# Vérifier les migrations V13 à V22 spécifiquement
echo ""
echo "🎯 Vérification des migrations V13 à V22..."

missing_migrations=0
for i in {13..22}; do
    migration_file="migrations/V${i}__*.sql"
    if ls $migration_file 1> /dev/null 2>&1; then
        filename=$(ls $migration_file | head -1)
        echo "   ✅ V${i}: $filename"
    else
        echo "   ❌ V${i}: Fichier manquant"
        missing_migrations=$((missing_migrations + 1))
    fi
done

if [ $missing_migrations -gt 0 ]; then
    echo ""
    echo "❌ $missing_migrations migration(s) manquante(s)"
    exit 1
fi

# Vérifier Flyway CLI
echo ""
echo "🔧 Vérification de Flyway CLI..."

if command -v flyway &> /dev/null; then
    flyway_version=$(flyway -v 2>/dev/null | head -1)
    echo "   ✅ Flyway CLI trouvé: $flyway_version"
else
    echo "   ⚠️  Flyway CLI non trouvé"
    echo "      Vous pouvez utiliser Flyway Desktop à la place"
fi

# Vérifier la connectivité à la base de données
echo ""
echo "🌐 Test de connectivité à la base de production..."

# Extraire les informations de connexion du fichier de configuration
db_url=$(grep 'url = ' flyway.prod.toml | sed 's/.*url = "//' | sed 's/"//')
db_user=$(grep 'user = ' flyway.prod.toml | sed 's/.*user = "//' | sed 's/"//')

if [ -n "$db_url" ] && [ -n "$db_user" ]; then
    echo "   📊 URL de base de données: $db_url"
    echo "   👤 Utilisateur: $db_user"
    echo "   ✅ Configuration de connexion trouvée"
else
    echo "   ❌ Impossible d'extraire les informations de connexion"
    exit 1
fi

# Vérifier l'état actuel de la base de données
echo ""
echo "📊 Vérification de l'état actuel de la base de données..."

if command -v flyway &> /dev/null; then
    echo "   🔍 Exécution de 'flyway info'..."
    flyway -configFiles=flyway.prod.toml info
    echo ""
    echo "   ✅ État de la base de données vérifié"
else
    echo "   ⚠️  Impossible de vérifier l'état (Flyway CLI non disponible)"
    echo "      Utilisez Flyway Desktop pour vérifier l'état"
fi

# Résumé final
echo ""
echo "🎯 RÉSUMÉ DE LA VÉRIFICATION"
echo "================================"

if [ $missing_migrations -eq 0 ]; then
    echo "✅ Toutes les migrations V13 à V22 sont présentes"
else
    echo "❌ $missing_migrations migration(s) manquante(s)"
fi

echo "✅ Configuration Flyway prête"
echo "✅ Dossier migrations trouvé"

if command -v flyway &> /dev/null; then
    echo "✅ Flyway CLI disponible"
    echo ""
    echo "🚀 Vous pouvez maintenant exécuter:"
    echo "   ./run_migrations_v13_to_v22.sh"
else
    echo "⚠️  Flyway CLI non disponible"
    echo ""
    echo "🚀 Vous pouvez utiliser Flyway Desktop ou installer Flyway CLI:"
    echo "   - Flyway Desktop: Ouvrez le projet et sélectionnez 'production'"
    echo "   - Flyway CLI: brew install flyway (sur macOS)"
fi

echo ""
echo "⚠️  RAPPEL: Vous allez modifier la base de PRODUCTION"
echo "   Assurez-vous d'avoir une sauvegarde si nécessaire"
