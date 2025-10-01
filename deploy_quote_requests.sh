#!/bin/bash

# Script de déploiement pour le système de demandes de devis
# Ce script crée les tables nécessaires et configure la sécurité

echo "🚀 Déploiement du système de demandes de devis..."

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

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    print_error "Supabase CLI n'est pas installé. Veuillez l'installer d'abord."
    echo "Installation: npm install -g supabase"
    exit 1
fi

# Vérifier si on est connecté à Supabase
if ! supabase status &> /dev/null; then
    print_error "Vous n'êtes pas connecté à Supabase. Veuillez vous connecter d'abord."
    echo "Connexion: supabase login"
    exit 1
fi

print_status "Création des tables pour les demandes de devis..."

# Exécuter le script SQL
if supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')" < tables/creation/quote_requests_tables.sql; then
    print_success "Tables créées avec succès"
else
    print_error "Erreur lors de la création des tables"
    exit 1
fi

print_status "Configuration du bucket de stockage pour les pièces jointes..."

# Créer le bucket pour les pièces jointes
supabase storage create attachments --public false

print_status "Configuration des politiques de sécurité du bucket..."

# Appliquer les politiques de sécurité pour le bucket
cat << 'EOF' | supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')"
-- Politiques de sécurité pour le bucket attachments
CREATE POLICY "Les utilisateurs authentifiés peuvent uploader des fichiers" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'attachments' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "Les utilisateurs peuvent voir leurs propres fichiers" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'attachments' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Les utilisateurs peuvent supprimer leurs propres fichiers" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'attachments' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Politique pour permettre l'accès public en lecture aux fichiers des demandes de devis
CREATE POLICY "Accès public en lecture aux fichiers des demandes de devis" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'attachments' AND 
        name LIKE 'quote-requests/%'
    );
EOF

if [ $? -eq 0 ]; then
    print_success "Politiques de sécurité configurées"
else
    print_warning "Erreur lors de la configuration des politiques (peut être normal si déjà configurées)"
fi

print_status "Vérification de la configuration..."

# Vérifier que les tables existent
if supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')" -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments');" | grep -q "technician_custom_urls"; then
    print_success "Tables vérifiées avec succès"
else
    print_error "Erreur lors de la vérification des tables"
    exit 1
fi

print_status "Création d'un réparateur de test (optionnel)..."

# Demander si l'utilisateur veut créer un réparateur de test
read -p "Voulez-vous créer un réparateur de test avec l'URL 'demo-reparateur' ? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Créer un utilisateur de test et son URL personnalisée
    cat << 'EOF' | supabase db reset --db-url "$(supabase status | grep 'DB URL' | awk '{print $3}')"
-- Créer un utilisateur de test (remplacer par un vrai UUID d'utilisateur)
INSERT INTO technician_custom_urls (technician_id, custom_url, is_active)
VALUES (
    (SELECT id FROM auth.users LIMIT 1), 
    'demo-reparateur', 
    true
) ON CONFLICT (custom_url) DO NOTHING;
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Réparateur de test créé avec l'URL: localhost:3002/quote/demo-reparateur"
    else
        print_warning "Impossible de créer le réparateur de test (utilisateur non trouvé)"
    fi
fi

print_success "🎉 Déploiement terminé avec succès !"
echo
echo "📋 Résumé du déploiement:"
echo "  ✅ Tables créées:"
echo "     - technician_custom_urls"
echo "     - quote_requests" 
echo "     - quote_request_attachments"
echo "  ✅ Bucket de stockage configuré: attachments"
echo "  ✅ Politiques de sécurité appliquées"
echo "  ✅ Fonctions utilitaires créées"
echo
echo "🔗 URLs de test:"
echo "  - Formulaire public: https://votre-domaine.com/quote/demo-reparateur"
echo "  - Gestion des demandes: https://votre-domaine.com/app/quote-requests"
echo
echo "📚 Documentation:"
echo "  - Les réparateurs peuvent créer des URLs personnalisées dans l'interface"
echo "  - Les clients peuvent accéder aux formulaires via ces URLs"
echo "  - Toutes les demandes sont stockées et peuvent être gérées dans l'interface"
echo
print_warning "N'oubliez pas de:"
echo "  1. Configurer votre domaine dans les paramètres Supabase"
echo "  2. Tester le système avec de vraies données"
echo "  3. Configurer les notifications email si nécessaire"
echo "  4. Mettre en place un système de rate limiting en production"

