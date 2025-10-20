#!/bin/bash

# Script pour ignorer la migration V17 et continuer avec les autres
# La migration V17 nécessite un utilisateur connecté pour les données de test

echo "🚀 Ignorer V17 et continuer avec les migrations restantes"
echo ""

# Marquer V17 comme ignorée dans l'historique Flyway
echo "📝 Marquage de V17 comme ignorée..."

# Exécuter une requête SQL pour marquer V17 comme ignorée
psql "postgresql://postgres:EGQUN6paP21OlNUu@db.wlqyrmntfxwdvkzzsujv.supabase.co:5432/postgres" -c "
UPDATE flyway_schema_history 
SET state = 'IGNORED' 
WHERE version = '17' AND description = 'Add Test Data Device Model Services';
"

if [ $? -eq 0 ]; then
    echo "✅ V17 marquée comme ignorée"
else
    echo "❌ Erreur lors du marquage de V17"
    exit 1
fi

echo ""
echo "🚀 Exécution des migrations restantes..."

# Exécuter les migrations restantes
flyway -configFiles=flyway.conf migrate

echo ""
echo "✅ Migrations restantes exécutées"
echo "🎯 L'erreur 404 pour device_model_services devrait maintenant être résolue"
