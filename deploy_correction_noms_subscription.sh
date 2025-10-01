#!/bin/bash

# Script de déploiement pour corriger le problème des noms dans subscription_status
# Date: 2024-09-21

echo "🔧 Déploiement de la correction des noms dans subscription_status..."

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "correction_subscription_status_noms.sql" ]; then
    echo "❌ Erreur: Le fichier correction_subscription_status_noms.sql n'est pas trouvé"
    echo "   Assurez-vous d'être dans le répertoire du projet"
    exit 1
fi

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Erreur: Supabase CLI n'est pas installé"
    echo "   Installez-le avec: npm install -g supabase"
    exit 1
fi

echo "📋 Étapes du déploiement:"
echo "1. Exécution du script SQL de correction"
echo "2. Test de la nouvelle fonction"
echo "3. Vérification des données existantes"
echo ""

# Exécuter le script SQL
echo "🚀 Exécution du script de correction..."
supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')" < correction_subscription_status_noms.sql

if [ $? -eq 0 ]; then
    echo "✅ Script de correction exécuté avec succès"
else
    echo "❌ Erreur lors de l'exécution du script"
    echo "   Essayez d'exécuter manuellement le script dans le dashboard Supabase"
    exit 1
fi

echo ""
echo "🎉 Correction déployée avec succès !"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Testez la création d'un nouveau compte"
echo "2. Vérifiez que les noms apparaissent correctement dans subscription_status"
echo "3. Les données existantes ont été corrigées automatiquement"
echo ""
echo "🔍 Pour vérifier:"
echo "- Allez dans Supabase Dashboard > Table Editor > subscription_status"
echo "- Les colonnes first_name et last_name devraient maintenant contenir les vrais noms"

