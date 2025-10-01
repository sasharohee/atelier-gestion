#!/bin/bash

# =====================================================
# SCRIPT DE RÉACTIVATION RLS SUBSCRIPTION_STATUS
# =====================================================

echo "🔧 Réactivation des politiques RLS de la table subscription_status..."

# Vérifier si le fichier SQL existe
if [ ! -f "reactiver_rls_subscription_status.sql" ]; then
    echo "❌ Erreur: Le fichier reactiver_rls_subscription_status.sql n'existe pas"
    exit 1
fi

echo "✅ Fichier SQL trouvé"

# Afficher les instructions
echo ""
echo "📋 INSTRUCTIONS D'EXÉCUTION:"
echo ""
echo "1️⃣  Copiez le contenu du fichier reactiver_rls_subscription_status.sql"
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
cat reactiver_rls_subscription_status.sql
echo "=========================================="

echo ""
echo "🎯 RÉSULTAT ATTENDU:"
echo "   • RLS activé sur la table subscription_status"
echo "   • 7 politiques créées:"
echo "     - admins_can_manage_subscriptions"
echo "     - service_role_full_access_subscription"
echo "     - subscription_status_select_policy"
echo "     - subscription_status_update_policy"
echo "     - users_can_insert_own_subscription"
echo "     - users_can_update_own_subscription"
echo "     - users_can_view_own_subscription"
echo "   • Vérification dans Authentication > Policies"
echo ""
echo "✅ Script prêt à être exécuté !"

