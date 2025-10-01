#!/bin/bash

# Script pour basculer vers la base de production
echo "🔄 Basculement vers la base de production..."

# Créer le fichier .env.local avec la configuration de production
cat > .env.local << 'EOF'
# Configuration Supabase - PRODUCTION
VITE_SUPABASE_URL=https://wlqyrmntfxwdvkzzsujv.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8

# Configuration PostgreSQL - PRODUCTION
VITE_POSTGRES_HOST=db.wlqyrmntfxwdvkzzsujv.supabase.co
VITE_POSTGRES_PORT=5432
VITE_POSTGRES_DB=postgres
VITE_POSTGRES_USER=postgres
VITE_POSTGRES_PASSWORD=EGQUN6paP21OlNUu

# Force l'utilisation de la base de production
VITE_FORCE_LOCAL_DB=false
EOF

echo "✅ Fichier .env.local créé avec la configuration de production"
echo "🔧 Configuration Supabase mise à jour:"
echo "   URL: https://wlqyrmntfxwdvkzzsujv.supabase.co"
echo "   Host: db.wlqyrmntfxwdvkzzsujv.supabase.co"
echo ""
echo "🚀 Redémarrez votre application pour appliquer les changements:"
echo "   npm run dev"
echo ""
echo "📊 Pour vérifier la connexion, ouvrez la console du navigateur"
echo "   et cherchez le message: '🔧 Configuration Supabase'"
