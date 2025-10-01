#!/bin/bash

# =====================================================
# SCRIPT SIMPLE DE RÉACTIVATION RLS USERS
# =====================================================

echo "🔧 Réactivation simple des politiques RLS de la table users..."

# Vérifier si le fichier SQL existe
if [ ! -f "reactiver_rls_users_simple.sql" ]; then
    echo "❌ Erreur: Le fichier reactiver_rls_users_simple.sql n'existe pas"
    exit 1
fi

echo "✅ Fichier SQL trouvé"

# Afficher les instructions
echo ""
echo "📋 INSTRUCTIONS D'EXÉCUTION:"
echo ""
echo "1️⃣  Copiez le contenu du fichier reactiver_rls_users_simple.sql"
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
cat reactiver_rls_users_simple.sql
echo "=========================================="

echo ""
echo "🎯 RÉSULTAT ATTENDU:"
echo "   • RLS activé sur la table users"
echo "   • 8 politiques créées"
echo "   • Vérification dans Authentication > Policies"
echo ""
echo "✅ Script prêt à être exécuté !"

