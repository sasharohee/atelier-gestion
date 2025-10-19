#!/bin/bash

# =====================================================
# Script de déploiement de la migration V21 en production
# =====================================================
# Date: 2024-12-19
# Description: Déploie la migration V21 avec toutes les corrections
# =====================================================

set -e  # Arrêter le script en cas d'erreur

echo "🚀 DÉPLOIEMENT DE LA MIGRATION V21 EN PRODUCTION"
echo "=================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLYWAY_CONFIG="/Users/sasharohee/Downloads/App atelier/flyway.prod.toml"
MIGRATION_FILE="migrations/V21__Production_Ready_Fixes.sql"

echo -e "${BLUE}📋 VÉRIFICATIONS PRÉALABLES${NC}"
echo "=================================================="

# Vérifier que le fichier de configuration existe
if [ ! -f "$FLYWAY_CONFIG" ]; then
    echo -e "${RED}❌ ERREUR: Fichier de configuration Flyway non trouvé: $FLYWAY_CONFIG${NC}"
    exit 1
fi

# Vérifier que le fichier de migration existe
if [ ! -f "$MIGRATION_FILE" ]; then
    echo -e "${RED}❌ ERREUR: Fichier de migration non trouvé: $MIGRATION_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Fichier de configuration trouvé${NC}"
echo -e "${GREEN}✅ Fichier de migration trouvé${NC}"

# Vérifier que Flyway est installé
if ! command -v flyway &> /dev/null; then
    echo -e "${RED}❌ ERREUR: Flyway n'est pas installé${NC}"
    echo "Installez Flyway avec: brew install flyway"
    exit 1
fi

echo -e "${GREEN}✅ Flyway est installé${NC}"

echo ""
echo -e "${BLUE}🔍 VÉRIFICATION DE L'ÉTAT ACTUEL${NC}"
echo "=================================================="

# Vérifier l'état actuel de la base de données
echo "Vérification de l'état actuel des migrations..."
flyway -configFiles="$FLYWAY_CONFIG" info

echo ""
echo -e "${YELLOW}⚠️  CONFIRMATION REQUISE${NC}"
echo "=================================================="
echo "Vous êtes sur le point de déployer les migrations V21 et V22 en production."
echo "Migration V21 va :"
echo "  - Créer la table system_settings"
echo "  - Ajouter la colonne items à sales"
echo "  - Corriger les politiques RLS"
echo "  - Synchroniser les utilisateurs existants"
echo ""
echo "Migration V22 va :"
echo "  - Créer toutes les tables SAV (repairs, parts, services, etc.)"
echo "  - Ajouter la colonne source à repairs"
echo "  - Créer les tables de liaison et de suivi"
echo "  - Configurer les fonctions et triggers SAV"
echo ""
read -p "Voulez-vous continuer ? (oui/non): " -r
echo

if [[ ! $REPLY =~ ^[Oo]ui$ ]]; then
    echo -e "${YELLOW}❌ Déploiement annulé${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 DÉPLOIEMENT DE LA MIGRATION${NC}"
echo "=================================================="

# Exécuter les migrations
echo "Exécution des migrations V21 et V22..."
if flyway -configFiles="$FLYWAY_CONFIG" migrate; then
    echo -e "${GREEN}✅ Migrations V21 et V22 déployées avec succès !${NC}"
else
    echo -e "${RED}❌ ERREUR: Échec du déploiement des migrations${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 VÉRIFICATION POST-DÉPLOIEMENT${NC}"
echo "=================================================="

# Vérifier l'état après migration
echo "Vérification de l'état après migration..."
flyway -configFiles="$FLYWAY_CONFIG" info

echo ""
echo -e "${BLUE}🧪 TESTS DE VALIDATION${NC}"
echo "=================================================="

# Test de connexion à la base
echo "Test de connexion à la base de données..."
if flyway -configFiles="$FLYWAY_CONFIG" validate; then
    echo -e "${GREEN}✅ Validation réussie${NC}"
else
    echo -e "${RED}❌ ERREUR: Validation échouée${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !${NC}"
echo "=================================================="
echo ""
echo "✅ Migration V21 appliquée avec succès"
echo "✅ Table system_settings créée"
echo "✅ Colonne items ajoutée à sales"
echo "✅ Politiques RLS corrigées"
echo "✅ Utilisateurs synchronisés"
echo "✅ Fonctions d'administration créées"
echo ""
echo "✅ Migration V22 appliquée avec succès"
echo "✅ Tables SAV créées (repairs, parts, services)"
echo "✅ Colonne source ajoutée à repairs"
echo "✅ Tables de liaison et de suivi créées"
echo "✅ Fonctions et triggers SAV configurés"
echo ""
echo -e "${BLUE}📋 PROCHAINES ÉTAPES${NC}"
echo "=================================================="
echo "1. Tester l'application en production"
echo "2. Vérifier que les erreurs 500 sont résolues"
echo "3. Tester la création de ventes"
echo "4. Vérifier les paramètres système"
echo "5. Activer les nouveaux utilisateurs si nécessaire"
echo "6. Tester les fonctionnalités SAV avec test_sav_migration.sql"
echo ""
echo -e "${GREEN}🚀 Votre application est maintenant prête pour la production !${NC}"
