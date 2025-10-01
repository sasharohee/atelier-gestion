#!/bin/bash

echo "🔧 Correction complète des problèmes Supabase en développement..."

# 1. Arrêter Supabase
echo "🛑 Arrêt de Supabase..."
supabase stop

# 2. Redémarrer Supabase local
echo "🔄 Redémarrage de Supabase local..."
supabase start

# 3. Attendre que Supabase soit prêt
echo "⏳ Attente du démarrage de Supabase..."
sleep 5

# 4. Réinitialiser la base de données locale
echo "🗄️ Réinitialisation de la base de données locale..."
supabase db reset --local

# 5. Créer les utilisateurs de test
echo "👤 Création des utilisateurs de test..."
node create_test_user.js

# 6. Tester l'authentification
echo "🧪 Test de l'authentification..."
node test_auth.js

# 7. Vérifier le statut final
echo "✅ Vérification du statut Supabase..."
supabase status

echo ""
echo "🎉 Correction terminée !"
echo ""
echo "📋 Utilisateurs de test créés :"
echo "👤 Utilisateur principal :"
echo "   📧 Email: sasharohee@icloud.com"
echo "   🔑 Mot de passe: password123"
echo ""
echo "👤 Utilisateur admin :"
echo "   📧 Email: admin@atelier.com"
echo "   🔑 Mot de passe: admin123"
echo ""
echo "📋 Actions à effectuer dans le navigateur :"
echo "1. Ouvrez les outils de développement (F12)"
echo "2. Allez dans l'onglet 'Application' ou 'Storage'"
echo "3. Supprimez toutes les données de localStorage et sessionStorage"
echo "4. Rechargez la page (Ctrl+F5 ou Cmd+Shift+R)"
echo "5. Connectez-vous avec les identifiants ci-dessus"
echo ""
echo "🔗 URLs importantes :"
echo "- Application : http://localhost:5173"
echo "- Supabase Studio : http://127.0.0.1:54323"
echo "- API Supabase : http://127.0.0.1:54321"
