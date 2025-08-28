#!/bin/bash

# Script pour mettre à jour la base de données avec les nouveaux champs clients
# Assurez-vous d'avoir configuré vos variables d'environnement Supabase

echo "🔧 Mise à jour de la table clients avec les nouveaux champs..."

# Vérifier si les variables d'environnement sont définies
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Erreur: Variables d'environnement Supabase non définies"
    echo "Veuillez définir SUPABASE_URL et SUPABASE_ANON_KEY"
    exit 1
fi

# Exécuter le script SQL
echo "📝 Exécution du script SQL..."
psql "$SUPABASE_URL" -f tables/extend_clients_table.sql

if [ $? -eq 0 ]; then
    echo "✅ Table clients mise à jour avec succès!"
    echo "📊 Nouveaux champs ajoutés:"
    echo "   - Informations personnelles: category, title, company_name, vat_number, siren_number, country_code"
    echo "   - Adresse détaillée: address_complement, region, postal_code, city"
    echo "   - Adresse de facturation: billing_address_same, billing_address, billing_address_complement, billing_region, billing_postal_code, billing_city"
    echo "   - Informations complémentaires: accounting_code, cni_identifier, attached_file_path, internal_note"
    echo "   - Préférences: status, sms_notification, email_notification, sms_marketing, email_marketing"
else
    echo "❌ Erreur lors de la mise à jour de la table"
    exit 1
fi

echo "🎉 Mise à jour terminée! Vous pouvez maintenant utiliser le nouveau formulaire de création de client."
