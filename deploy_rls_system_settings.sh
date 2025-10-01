#!/bin/bash

# =====================================================
# SCRIPT DE RÉACTIVATION RLS SYSTEM_SETTINGS
# =====================================================

echo "🔧 Réactivation des politiques RLS de la table system_settings..."

# Vérifier si le fichier SQL existe
if [ ! -f "reactiver_rls_system_settings.sql" ]; then
    echo "❌ Erreur: Le fichier reactiver_rls_system_settings.sql n'existe pas"
    exit 1
fi

echo "✅ Fichier SQL trouvé"

# Afficher les instructions
echo ""
echo "📋 INSTRUCTIONS D'EXÉCUTION:"
echo ""
echo "1️⃣  Copiez le contenu du fichier reactiver_rls_system_settings.sql"
echo "2️⃣  Allez dans le dashboard Supabase"
echo "3️⃣  Section SQL Editor"
echo "4️⃣  Collez le script et exécutez-le"
echo ""
echo "OU"
echo ""
echo "🚀 Exécutez directement:"
echo "   supabase db push --linked"
echo ""

# Afficher le contenu du fichier
echo "📄 CONTENU DU SCRIPT:"
echo "=========================================="
cat reactiver_rls_system_settings.sql
echo "=========================================="

echo ""
echo "🎯 RÉSULTAT ATTENDU:"
echo "   • RLS activé sur la table system_settings"
echo "   • 5 politiques créées:"
echo "     - Admins can insert system_settings"
echo "     - Admins can update system_settings"
echo "     - Authenticated users can view system_settings"
echo "     - system_settings_select_policy"
echo "     - system_settings_update_policy"
echo "   • Vérification dans Authentication > Policies"
echo ""
echo "✅ Script prêt à être exécuté !"

