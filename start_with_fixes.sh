#!/bin/bash

# Script de démarrage avec corrections automatiques
# Atelier Gestion - Mode développement local avec corrections

echo "🚀 Démarrage de l'application avec corrections automatiques..."
echo "============================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si npm est installé
if ! command -v npm &> /dev/null; then
    print_error "npm n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

print_status "Vérification de l'environnement..."

# Vérifier la version de Node.js
NODE_VERSION=$(node --version)
print_status "Version Node.js: $NODE_VERSION"

# Vérifier la version de npm
NPM_VERSION=$(npm --version)
print_status "Version npm: $NPM_VERSION"

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    print_warning "Supabase CLI n'est pas installé. Installation..."
    npm install -g supabase
fi

# Vérifier si Supabase est en cours d'exécution
print_status "Vérification de Supabase local..."
if ! curl -s http://127.0.0.1:54321/health > /dev/null; then
    print_warning "Supabase local n'est pas en cours d'exécution. Démarrage..."
    npx supabase start
else
    print_success "Supabase local est en cours d'exécution"
fi

# Afficher les informations de connexion Supabase
print_status "Informations de connexion Supabase:"
echo "  API URL: http://127.0.0.1:54321"
echo "  Studio URL: http://127.0.0.1:54323"
echo "  DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres"

# Nettoyer le cache npm
print_status "Nettoyage du cache npm..."
npm cache clean --force

# Installer les dépendances
print_status "Installation des dépendances..."
npm install

# Nettoyer le cache de build
print_status "Nettoyage du cache de build..."
rm -rf dist/
rm -rf build/
rm -rf node_modules/.vite/

# Créer un fichier HTML de test avec les corrections
print_status "Création de la page de test avec corrections..."
cat > test_with_fixes.html << 'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test avec Corrections - Atelier Gestion</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        .test-section {
            margin: 20px 0;
            padding: 20px;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 10px;
            border-left: 4px solid #4CAF50;
        }
        button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px 5px;
            transition: all 0.3s ease;
        }
        button:hover {
            background: #45a049;
            transform: translateY(-2px);
        }
        .log {
            background: rgba(0, 0, 0, 0.3);
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
            max-height: 300px;
            overflow-y: auto;
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Test avec Corrections - Atelier Gestion</h1>
        <p>Cette page applique automatiquement toutes les corrections nécessaires.</p>

        <div class="test-section">
            <h2>📋 Actions de Correction</h2>
            <button onclick="applyAllFixes()">🚀 Appliquer toutes les corrections</button>
            <button onclick="openMainApp()">🌐 Ouvrir l'application principale</button>
            <button onclick="clearLogs()">🧹 Effacer les logs</button>
        </div>

        <div class="test-section">
            <h2>📝 Logs de Correction</h2>
            <div id="fix-logs" class="log">
                Prêt pour les corrections...<br>
            </div>
        </div>
    </div>

    <script>
        let fixLogs = [];

        function addLog(message, type = 'info') {
            const timestamp = new Date().toLocaleTimeString();
            const logEntry = `[${timestamp}] ${message}`;
            fixLogs.push({ message: logEntry, type });
            
            const logElement = document.getElementById('fix-logs');
            logElement.innerHTML += `<span style="color: ${type === 'error' ? '#f44336' : type === 'success' ? '#4CAF50' : type === 'warning' ? '#ff9800' : '#2196F3'}">${logEntry}</span><br>`;
            logElement.scrollTop = logElement.scrollHeight;
        }

        function clearLogs() {
            fixLogs = [];
            document.getElementById('fix-logs').innerHTML = 'Logs effacés...<br>';
        }

        function openMainApp() {
            addLog('🌐 Ouverture de l\'application principale...', 'info');
            window.open('/', '_blank');
        }

        async function applyAllFixes() {
            addLog('🚀 Début de l\'application des corrections...', 'info');
            
            try {
                // Charger le script de correction
                const script = document.createElement('script');
                script.src = '/fix_all_auth_issues.js';
                document.head.appendChild(script);
                
                addLog('✅ Script de correction chargé', 'success');
                addLog('🔄 Les corrections sont en cours d\'application...', 'info');
                addLog('💡 Vérifiez la console pour plus de détails', 'info');
                
            } catch (error) {
                addLog(`❌ Erreur lors de l'application des corrections: ${error.message}`, 'error');
            }
        }

        // Appliquer automatiquement les corrections au chargement
        window.addEventListener('load', () => {
            addLog('🔧 Page de test chargée', 'info');
            addLog('💡 Cliquez sur "Appliquer toutes les corrections" pour commencer', 'info');
        });
    </script>
</body>
</html>
EOF

print_success "Page de test créée: test_with_fixes.html"

# Démarrer le serveur de développement
print_status "Démarrage du serveur de développement..."
print_success "Application disponible sur: http://localhost:5173"
print_success "Page de test disponible sur: http://localhost:5173/test_with_fixes.html"
print_success "Supabase Studio disponible sur: http://127.0.0.1:54323"
print_warning "Appuyez sur Ctrl+C pour arrêter le serveur"

# Démarrer Vite avec les options de développement
npm run dev -- --host --port 5173

print_status "Serveur arrêté."

