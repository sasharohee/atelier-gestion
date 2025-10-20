#!/bin/bash

# Script pour exécuter les migrations avec Flyway Desktop
# Alternative au CLI Flyway

echo "🚀 Exécution des migrations V13 à V22 avec Flyway Desktop"
echo ""

# Vérifier que Flyway Desktop est disponible
if ! command -v flyway &> /dev/null && [ ! -f "flyway.toml" ]; then
    echo "❌ Flyway Desktop n'est pas configuré"
    echo "   Assurez-vous d'avoir Flyway Desktop installé et configuré"
    exit 1
fi

echo "✅ Configuration Flyway Desktop trouvée"

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
echo "🚀 Instructions pour Flyway Desktop:"
echo ""
echo "1. Ouvrez Flyway Desktop"
echo "2. Sélectionnez l'environnement 'production'"
echo "3. Cliquez sur 'Migrate'"
echo "4. Vérifiez que les migrations V13 à V22 sont sélectionnées"
echo "5. Cliquez sur 'Run' pour exécuter"
echo ""
echo "📊 Migrations à exécuter:"
echo "   - V13: Create Device Model Services"
echo "   - V14: Fix Device Model Services Structure"
echo "   - V15: Fix Device Model Services RLS"
echo "   - V16: Fix Device Model Services View Simple"
echo "   - V17: Add Test Data Device Model Services"
echo "   - V18: Debug Device Model Services Data"
echo "   - V19: Fix Device Model Services View Final"
echo "   - V20: Fix Device Models Category Type"
echo "   - V21: Production Ready Fixes"
echo "   - V22: SAV Tables And Features"
echo ""
echo "🎯 Après l'exécution, l'erreur 404 pour device_model_services devrait être résolue"
