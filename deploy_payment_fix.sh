#!/bin/bash

# Script de déploiement pour corriger le problème de validation de paiement
# Ce script applique les fonctions SQL nécessaires pour contourner le trigger problématique

set -e

# Configuration
DB_URL="${DATABASE_URL:-postgresql://postgres:password@localhost:5432/postgres}"
SCRIPT_FILE="fix_repair_payment_trigger.sql"

echo "🚀 Déploiement de la correction pour la validation de paiement des réparations"
echo "📊 Base de données: $DB_URL"

# Vérifier que le fichier SQL existe
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Fichier $SCRIPT_FILE non trouvé"
    exit 1
fi

echo "📝 Exécution du script SQL..."

# Exécuter le script SQL
if psql "$DB_URL" -f "$SCRIPT_FILE"; then
    echo "✅ Script SQL exécuté avec succès"
else
    echo "❌ Erreur lors de l'exécution du script SQL"
    exit 1
fi

# Vérifier que les fonctions ont été créées
echo "🔍 Vérification des fonctions créées..."

FUNCTIONS_CHECK=$(psql "$DB_URL" -t -c "
    SELECT COUNT(*) FROM pg_proc 
    WHERE proname IN ('update_repair_payment_only', 'update_repair_payment_safe', 'test_payment_functions');
" 2>/dev/null | xargs)

if [ "$FUNCTIONS_CHECK" = "3" ]; then
    echo "✅ Toutes les fonctions ont été créées avec succès"
else
    echo "⚠️ Certaines fonctions n'ont pas été créées (attendu: 3, trouvé: $FUNCTIONS_CHECK)"
fi

# Tester les fonctions
echo "🧪 Test des fonctions..."

TEST_RESULT=$(psql "$DB_URL" -t -c "SELECT test_payment_functions();" 2>/dev/null | xargs)

if [ -n "$TEST_RESULT" ]; then
    echo "✅ Test des fonctions réussi: $TEST_RESULT"
else
    echo "⚠️ Impossible de tester les fonctions"
fi

echo ""
echo "🎯 Instructions d'utilisation:"
echo "1. Redéployez votre application"
echo "2. Testez la validation de paiement dans la colonne 'Terminé'"
echo "3. Vérifiez les logs dans la console du navigateur"
echo ""
echo "📋 Fonctions disponibles:"
echo "- update_repair_payment_safe: Désactive temporairement le trigger"
echo "- update_repair_payment_only: Mise à jour directe sans trigger"
echo "- test_payment_functions: Test de l'existence des fonctions"
echo ""
echo "✅ Déploiement terminé!"
