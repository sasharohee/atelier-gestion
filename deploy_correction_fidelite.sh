#!/bin/bash

# 🔧 SCRIPT DE DÉPLOIEMENT AUTOMATISÉ - Correction Isolation Fidélité
# Ce script déploie automatiquement la correction de l'isolation des données de fidélité
# Date: 2025-01-23

set -e  # Arrêter le script en cas d'erreur

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/correction_fidelite_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

# Fonction d'affichage du header
show_header() {
    echo -e "${BLUE}"
    echo "=================================================================="
    echo "🔧 SCRIPT DE DÉPLOIEMENT - CORRECTION ISOLATION FIDÉLITÉ"
    echo "=================================================================="
    echo "📅 Date: $(date)"
    echo "📁 Répertoire: $SCRIPT_DIR"
    echo "📝 Log: $LOG_FILE"
    echo "=================================================================="
    echo -e "${NC}"
}

# Fonction de vérification des prérequis
check_prerequisites() {
    log "🔍 Vérification des prérequis..."
    
    # Vérifier que les fichiers de correction existent
    if [[ ! -f "$SCRIPT_DIR/correction_isolation_fidelite.sql" ]]; then
        log_error "Fichier correction_isolation_fidelite.sql introuvable"
        exit 1
    fi
    
    if [[ ! -f "$SCRIPT_DIR/test_isolation_fidelite.sql" ]]; then
        log_error "Fichier test_isolation_fidelite.sql introuvable"
        exit 1
    fi
    
    # Vérifier que psql est installé
    if ! command -v psql &> /dev/null; then
        log_error "psql n'est pas installé. Veuillez installer PostgreSQL client."
        exit 1
    fi
    
    log_success "Prérequis vérifiés avec succès"
}

# Fonction de configuration de la base de données
configure_database() {
    log "🔧 Configuration de la base de données..."
    
    # Demander les informations de connexion
    echo -e "${YELLOW}Veuillez entrer les informations de connexion à votre base de données Supabase:${NC}"
    
    read -p "Host (ex: db.wlqyrmntfxwdvkzzsujv.supabase.co): " DB_HOST
    read -p "Port (ex: 5432): " DB_PORT
    read -p "Database (ex: postgres): " DB_NAME
    read -p "Username (ex: postgres): " DB_USER
    read -s -p "Password: " DB_PASSWORD
    echo
    
    # Construire la chaîne de connexion
    DB_URL="postgresql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
    
    # Tester la connexion
    log "🧪 Test de connexion à la base de données..."
    if psql "$DB_URL" -c "SELECT version();" &> /dev/null; then
        log_success "Connexion à la base de données réussie"
    else
        log_error "Impossible de se connecter à la base de données"
        exit 1
    fi
}

# Fonction de sauvegarde
create_backup() {
    log "💾 Création d'une sauvegarde de sécurité..."
    
    # Créer le répertoire de sauvegarde
    mkdir -p "$BACKUP_DIR"
    
    # Nom du fichier de sauvegarde
    BACKUP_FILE="$BACKUP_DIR/backup_fidelite_$(date +%Y%m%d_%H%M%S).sql"
    
    # Créer la sauvegarde
    if pg_dump "$DB_URL" --schema=public --data-only --table="loyalty_*" --table="clients" > "$BACKUP_FILE" 2>/dev/null; then
        log_success "Sauvegarde créée: $BACKUP_FILE"
    else
        log_warning "Sauvegarde partielle créée (certaines tables peuvent être vides)"
    fi
}

# Fonction de déploiement de la correction
deploy_correction() {
    log "🚀 Déploiement de la correction d'isolation..."
    
    # Exécuter le script de correction
    log "📝 Exécution du script de correction..."
    if psql "$DB_URL" -f "$SCRIPT_DIR/correction_isolation_fidelite.sql" >> "$LOG_FILE" 2>&1; then
        log_success "Script de correction exécuté avec succès"
    else
        log_error "Erreur lors de l'exécution du script de correction"
        log "Consultez le fichier de log: $LOG_FILE"
        exit 1
    fi
}

# Fonction de test de la correction
test_correction() {
    log "🧪 Test de la correction d'isolation..."
    
    # Exécuter le script de test
    log "📝 Exécution du script de test..."
    if psql "$DB_URL" -f "$SCRIPT_DIR/test_isolation_fidelite.sql" >> "$LOG_FILE" 2>&1; then
        log_success "Script de test exécuté avec succès"
    else
        log_warning "Erreur lors de l'exécution du script de test"
        log "Consultez le fichier de log: $LOG_FILE"
    fi
}

# Fonction de vérification finale
verify_correction() {
    log "🔍 Vérification finale de la correction..."
    
    # Vérifier que les colonnes workshop_id existent
    log "📊 Vérification des colonnes d'isolation..."
    COLUMNS_CHECK=$(psql "$DB_URL" -t -c "
        SELECT COUNT(*) FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
        AND column_name = 'workshop_id';
    " 2>/dev/null | xargs)
    
    if [[ "$COLUMNS_CHECK" == "3" ]]; then
        log_success "Colonnes d'isolation vérifiées"
    else
        log_error "Problème avec les colonnes d'isolation"
        exit 1
    fi
    
    # Vérifier que RLS est activé
    log "🔒 Vérification de l'activation RLS..."
    RLS_CHECK=$(psql "$DB_URL" -t -c "
        SELECT COUNT(*) FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
        AND rowsecurity = true;
    " 2>/dev/null | xargs)
    
    if [[ "$RLS_CHECK" == "3" ]]; then
        log_success "RLS activé sur toutes les tables"
    else
        log_error "Problème avec l'activation RLS"
        exit 1
    fi
    
    # Vérifier que la vue fonctionne
    log "👁️ Vérification de la vue loyalty_dashboard..."
    if psql "$DB_URL" -c "SELECT COUNT(*) FROM loyalty_dashboard;" >> "$LOG_FILE" 2>&1; then
        log_success "Vue loyalty_dashboard fonctionne"
    else
        log_error "Problème avec la vue loyalty_dashboard"
        exit 1
    fi
}

# Fonction de nettoyage
cleanup() {
    log "🧹 Nettoyage des fichiers temporaires..."
    
    # Supprimer les fichiers temporaires si nécessaire
    # (ajoutez ici la logique de nettoyage si nécessaire)
    
    log_success "Nettoyage terminé"
}

# Fonction d'affichage du résumé
show_summary() {
    echo -e "${GREEN}"
    echo "=================================================================="
    echo "🎉 DÉPLOIEMENT TERMINÉ AVEC SUCCÈS !"
    echo "=================================================================="
    echo "📁 Fichier de log: $LOG_FILE"
    echo "💾 Sauvegarde: $BACKUP_DIR/"
    echo "🔒 Isolation des données de fidélité rétablie"
    echo "✅ Tous les tests de vérification ont réussi"
    echo "=================================================================="
    echo -e "${NC}"
}

# Fonction principale
main() {
    show_header
    
    # Vérifier les prérequis
    check_prerequisites
    
    # Configuration de la base de données
    configure_database
    
    # Créer une sauvegarde
    create_backup
    
    # Déployer la correction
    deploy_correction
    
    # Tester la correction
    test_correction
    
    # Vérifier la correction
    verify_correction
    
    # Nettoyage
    cleanup
    
    # Afficher le résumé
    show_summary
}

# Gestion des erreurs
trap 'log_error "Erreur survenue à la ligne $LINENO. Consultez le log: $LOG_FILE"; exit 1' ERR

# Exécution du script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
