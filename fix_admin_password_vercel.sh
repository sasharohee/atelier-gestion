#!/bin/bash

# Script de Correction du Mot de Passe Admin Vercel
# Atelier Gestion - Correction Vercel

echo "🔐 Correction du Mot de Passe Admin Vercel"
echo "=========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Étapes de Correction${NC}"
echo ""

echo -e "${YELLOW}1. Configuration des Variables d'Environnement Vercel${NC}"
echo ""
echo "   a) Aller sur https://vercel.com"
echo "   b) Sélectionner votre projet 'App atelier'"
echo "   c) Cliquer sur 'Settings' > 'Environment Variables'"
echo "   d) Ajouter/Modifier la variable :"
echo ""
echo -e "${GREEN}      Nom: VITE_ADMIN_PASSWORD${NC}"
echo -e "${GREEN}      Valeur: At3l13r@dm1n#2024\$ecur3!${NC}"
echo -e "${GREEN}      Environnements: Production, Preview, Development${NC}"
echo ""

echo -e "${YELLOW}2. Redéploiement de l'Application${NC}"
echo ""
echo "   Option A - Redéploiement Automatique:"
echo "   - Faire un petit changement dans le code"
echo "   - Pousser sur GitHub"
echo "   - Vercel se redéploiera automatiquement"
echo ""
echo "   Option B - Redéploiement Manuel:"
echo "   - vercel --prod"
echo ""

echo -e "${YELLOW}3. Test de l'Accès Admin${NC}"
echo ""
echo "   - Aller sur https://votre-projet.vercel.app/admin"
echo "   - Saisir le mot de passe: At3l13r@dm1n#2024\$ecur3!"
echo "   - Vérifier que l'accès fonctionne"
echo ""

echo -e "${BLUE}🔧 Variables d'Environnement Requises${NC}"
echo ""
echo "VITE_SUPABASE_URL = https://wlqyrmntfxwdvkzzsujv.supabase.co"
echo "VITE_SUPABASE_ANON_KEY = [votre-clé-anon]"
echo "VITE_ADMIN_PASSWORD = At3l13r@dm1n#2024\$ecur3!"
echo ""

echo -e "${BLUE}🔍 Diagnostic${NC}"
echo ""

# Vérifier si Vercel CLI est installé
if command -v vercel &> /dev/null; then
    echo -e "${GREEN}✅ Vercel CLI installé${NC}"
    
    echo ""
    echo "Vérification des logs Vercel..."
    echo "vercel logs"
    echo ""
    
    echo "Redéploiement si nécessaire..."
    echo "vercel --prod"
    echo ""
else
    echo -e "${YELLOW}⚠️  Vercel CLI non installé${NC}"
    echo ""
    echo "Installation:"
    echo "npm i -g vercel"
    echo ""
fi

echo -e "${BLUE}📝 Configuration du Code${NC}"
echo ""
echo "Le mot de passe est géré dans src/components/AdminPasswordGuard.tsx:"
echo ""
echo "const ADMIN_PASSWORD = import.meta.env.VITE_ADMIN_PASSWORD || 'At3l13r@dm1n#2024\$ecur3!';"
echo ""
echo "Logique:"
echo "1. Utilise VITE_ADMIN_PASSWORD si définie"
echo "2. Sinon, utilise le fallback At3l13r@dm1n#2024\$ecur3!"
echo ""

echo -e "${BLUE}✅ Checklist de Validation${NC}"
echo ""
echo "□ Variable VITE_ADMIN_PASSWORD ajoutée sur Vercel"
echo "□ Valeur correcte: At3l13r@dm1n#2024\$ecur3!"
echo "□ Configuration pour tous les environnements"
echo "□ Application redéployée"
echo "□ Test d'accès admin réussi"
echo "□ Ancien mot de passe ne fonctionne plus"
echo ""

echo -e "${GREEN}🎯 Résultat Attendu${NC}"
echo ""
echo "✅ Nouveau mot de passe: At3l13r@dm1n#2024\$ecur3! fonctionne"
echo "❌ Ancien mot de passe ne fonctionne plus"
echo "✅ Accès admin sécurisé sur Vercel"
echo ""

echo -e "${BLUE}📞 Support${NC}"
echo ""
echo "Si le problème persiste:"
echo "1. Vérifier les logs Vercel"
echo "2. Vérifier la configuration des variables"
echo "3. Redéployer l'application"
echo "4. Tester en local d'abord"
echo ""

echo -e "${GREEN}✨ Correction Terminée!${NC}"
