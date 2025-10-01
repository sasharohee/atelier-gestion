#!/bin/bash

echo "🔄 Redémarrage forcé du serveur de développement..."

# 1. Arrêter tous les processus de développement
echo "🛑 Arrêt des processus de développement..."
pkill -f "vite"
pkill -f "npm run dev"
pkill -f "node.*vite"

# 2. Attendre un peu
sleep 2

# 3. Vérifier que le fichier .env existe
if [ ! -f ".env" ]; then
    echo "❌ Fichier .env manquant, création..."
    cat > .env << 'EOF'
# Configuration Supabase pour le développement local
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

# Configuration EmailJS pour Atelier Gestion
VITE_EMAILJS_SERVICE_ID=service_lisw5h9
VITE_EMAILJS_TEMPLATE_ID=template_dabl0od
VITE_EMAILJS_PUBLIC_KEY=mh5fruIpuHfRxF7YC

# Configuration PostgreSQL locale
VITE_POSTGRES_HOST=127.0.0.1
VITE_POSTGRES_PORT=54322
VITE_POSTGRES_DB=postgres
VITE_POSTGRES_USER=postgres
VITE_POSTGRES_PASSWORD=postgres

# Mot de passe administrateur (sécurisé)
VITE_ADMIN_PASSWORD=At3l13r@dm1n#2024$ecur3!
EOF
fi

# 4. Vérifier que Supabase est en cours d'exécution
echo "🔍 Vérification de Supabase..."
if ! curl -s http://127.0.0.1:54321/health > /dev/null; then
    echo "⚠️ Supabase n'est pas en cours d'exécution, démarrage..."
    supabase start
    sleep 5
fi

# 5. Redémarrer le serveur de développement
echo "🚀 Redémarrage du serveur de développement..."
npm run dev &

# 6. Attendre que le serveur démarre
echo "⏳ Attente du démarrage du serveur..."
sleep 5

echo ""
echo "✅ Redémarrage terminé !"
echo ""
echo "📋 Actions à effectuer dans le navigateur :"
echo "1. Ouvrez les outils de développement (F12)"
echo "2. Allez dans l'onglet 'Application' ou 'Storage'"
echo "3. Supprimez TOUTES les données de localStorage et sessionStorage"
echo "4. Rechargez la page (Ctrl+F5 ou Cmd+Shift+R)"
echo "5. Connectez-vous avec :"
echo "   📧 Email: sasharohee@icloud.com"
echo "   🔑 Mot de passe: password123"
echo ""
echo "🔗 Application : http://localhost:5173"
