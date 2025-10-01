#!/bin/bash

echo "🔐 Démarrage du nouveau système d'authentification"
echo "=================================================="

# Vérifier que Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Veuillez installer Node.js d'abord."
    exit 1
fi

# Vérifier que npm est installé
if ! command -v npm &> /dev/null; then
    echo "❌ npm n'est pas installé. Veuillez installer npm d'abord."
    exit 1
fi

echo "✅ Node.js et npm sont installés"

# Installer les dépendances si nécessaire
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
else
    echo "✅ Dépendances déjà installées"
fi

# Vérifier la configuration Supabase
echo "🔧 Vérification de la configuration Supabase..."

if [ ! -f ".env" ]; then
    echo "⚠️  Fichier .env manquant. Création d'un fichier .env basé sur env.example..."
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "✅ Fichier .env créé. Veuillez vérifier les variables d'environnement."
    else
        echo "❌ Fichier env.example manquant. Veuillez créer un fichier .env avec vos variables Supabase."
        exit 1
    fi
else
    echo "✅ Fichier .env trouvé"
fi

# Afficher les instructions
echo ""
echo "📋 INSTRUCTIONS IMPORTANTES :"
echo "=============================="
echo ""
echo "1. 🗄️  CONFIGURATION DE LA BASE DE DONNÉES :"
echo "   - Ouvrez votre console Supabase"
echo "   - Allez dans l'éditeur SQL"
echo "   - Exécutez le script : CREATE_AUTH_SYSTEM_CLEAN.sql"
echo ""
echo "2. 🔧 CONFIGURATION SUPABASE :"
echo "   - Vérifiez que VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY sont corrects dans .env"
echo "   - Dans la console Supabase, allez dans Authentication > Settings"
echo "   - Configurez les URLs de redirection :"
echo "     * Site URL: http://localhost:5173"
echo "     * Redirect URLs: http://localhost:5173/auth/confirm, http://localhost:5173/auth/reset-password"
echo ""
echo "3. 🚀 DÉMARRAGE DE L'APPLICATION :"
echo "   - L'application va démarrer sur http://localhost:5173"
echo "   - Testez l'inscription et la connexion"
echo ""
echo "4. 🧪 TESTS :"
echo "   - Ouvrez test_auth_system.html dans votre navigateur pour des tests avancés"
echo ""

# Demander confirmation
read -p "Avez-vous configuré la base de données et Supabase ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⚠️  Veuillez d'abord configurer la base de données et Supabase selon les instructions ci-dessus."
    echo "   Puis relancez ce script."
    exit 1
fi

echo ""
echo "🚀 Démarrage de l'application..."
echo "================================="

# Démarrer l'application
npm run dev
