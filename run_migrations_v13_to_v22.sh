#!/bin/bash

# Script pour exécuter les migrations V13 à V22 vers la base de production
# Utilise Flyway pour appliquer les migrations de manière sécurisée

echo "🚀 Exécution des migrations V13 à V22 vers la base de production"
echo ""

# Vérifier que Flyway est installé
if ! command -v flyway &> /dev/null; then
    echo "❌ Flyway n'est pas installé. Veuillez l'installer d'abord."
    echo "   Téléchargez depuis: https://flywaydb.org/download"
    echo "   Ou installez avec: brew install flyway (sur macOS)"
    exit 1
fi

echo "✅ Flyway détecté"

# Vérifier que la configuration existe
if [ ! -f "flyway.prod.toml" ]; then
    echo "❌ Fichier de configuration flyway.prod.toml manquant"
    exit 1
fi

echo "✅ Configuration Flyway trouvée"

# Vérifier que le dossier migrations existe
if [ ! -d "migrations" ]; then
    echo "❌ Dossier migrations manquant"
    exit 1
fi

echo "✅ Dossier migrations trouvé"

# Lister les migrations V13 à V22
echo ""
echo "📋 Migrations à exécuter (V13 à V22):"
echo ""

for i in {13..22}; do
    migration_file="migrations/V${i}__*.sql"
    if ls $migration_file 1> /dev/null 2>&1; then
        echo "   ✅ V${i}: $(ls $migration_file | head -1 | sed 's/.*V[0-9]*__//' | sed 's/\.sql$//')"
    else
        echo "   ❌ V${i}: Fichier manquant"
    fi
done

echo ""
echo "🔍 Vérification de l'état actuel de la base de données..."

# Vérifier l'état actuel avec Flyway
flyway -configFiles=flyway.prod.toml info

echo ""
echo "⚠️  ATTENTION: Vous êtes sur le point d'exécuter des migrations sur la base de PRODUCTION"
echo "   Base de données: db.wlqyrmntfxwdvkzzsujv.supabase.co"
echo ""

# Demander confirmation
read -p "Voulez-vous continuer ? (oui/non): " confirmation

if [ "$confirmation" != "oui" ]; then
    echo "❌ Opération annulée par l'utilisateur"
    exit 0
fi

echo ""
echo "🚀 Début de l'exécution des migrations..."

# Exécuter les migrations
echo ""
echo "📊 Exécution des migrations V13 à V22..."
flyway -configFiles=flyway.prod.toml migrate

# Vérifier le résultat
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migrations exécutées avec succès !"
    echo ""
    echo "📊 État final de la base de données:"
    flyway -configFiles=flyway.prod.toml info
    echo ""
    echo "🎯 Les migrations V13 à V22 ont été appliquées à la base de production"
    echo "   L'erreur 404 pour device_model_services devrait maintenant être résolue"
else
    echo ""
    echo "❌ Erreur lors de l'exécution des migrations"
    echo "   Vérifiez les logs ci-dessus pour plus de détails"
    exit 1
fi

echo ""
echo "🧪 Pour tester:"
echo "   1. Rechargez votre application"
echo "   2. Essayez de créer une association service-modèle"
echo "   3. Vérifiez qu'il n'y a plus d'erreur 404 dans la console"
