#!/bin/bash

# Script de déploiement pour la table device_model_services
# Ce script applique la migration nécessaire pour corriger l'erreur 404

echo "🚀 Déploiement de la migration device_model_services..."

# Vérifier que le fichier SQL existe
if [ ! -f "create_device_model_services_table.sql" ]; then
    echo "❌ Erreur: Le fichier create_device_model_services_table.sql n'existe pas"
    exit 1
fi

echo "📋 Instructions pour appliquer la migration:"
echo ""
echo "1. Connectez-vous à votre dashboard Supabase:"
echo "   https://supabase.com/dashboard"
echo ""
echo "2. Sélectionnez votre projet"
echo ""
echo "3. Allez dans l'éditeur SQL (SQL Editor)"
echo ""
echo "4. Copiez le contenu du fichier 'create_device_model_services_table.sql'"
echo ""
echo "5. Collez-le dans l'éditeur SQL"
echo ""
echo "6. Cliquez sur 'Run' pour exécuter le script"
echo ""
echo "7. Vérifiez que vous voyez le message de confirmation:"
echo "   'Table device_model_services créée avec succès !'"
echo ""
echo "✅ Après l'exécution, l'erreur 404 devrait être résolue"
echo ""
echo "📁 Fichier SQL à utiliser: create_device_model_services_table.sql"
echo ""
echo "🔧 Cette migration crée:"
echo "   - Table device_model_services"
echo "   - Vue device_model_services_detailed"
echo "   - Fonctions RPC get_services_for_model et get_services_for_brand_category"
echo "   - Politiques RLS pour la sécurité"
echo "   - Index pour les performances"
echo "   - Trigger pour updated_at"
echo ""
echo "⚠️  Assurez-vous que les tables suivantes existent déjà:"
echo "   - device_models"
echo "   - services"
echo "   - device_brands"
echo "   - device_categories"
echo "   - workshops (optionnel)"
echo ""
echo "🎯 Une fois la migration appliquée, l'application devrait fonctionner sans erreur 404"
echo ""
echo "🧪 Pour tester la migration :"
echo "   1. Exécutez le script 'test_device_model_services_migration.sql'"
echo "   2. Vérifiez que tous les tests passent"
echo "   3. Testez l'application pour confirmer que l'erreur 404 a disparu"
