#!/bin/bash

# Script de test de connexion à la base de données

echo "🔍 TEST DE CONNEXION À LA BASE DE DONNÉES"
echo "=========================================="

# Variables de connexion
DB_HOST="db.gggoqnxrspviuxadvkbh.supabase.co"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="postgres"
DB_PASSWORD="EGQUN6paP21OlNUu"

echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo ""

# Test de ping
echo "1. Test de ping vers l'host..."
if ping -c 1 $DB_HOST > /dev/null 2>&1; then
    echo "✅ Ping réussi vers $DB_HOST"
else
    echo "❌ Ping échoué vers $DB_HOST"
    echo "Vérifiez que l'URL de la base de données est correcte"
fi

# Test de connexion avec telnet
echo ""
echo "2. Test de connexion sur le port $DB_PORT..."
if timeout 5 bash -c "</dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    echo "✅ Port $DB_PORT accessible"
else
    echo "❌ Port $DB_PORT non accessible"
    echo "Vérifiez que le port est ouvert"
fi

# Test avec psql si disponible
echo ""
echo "3. Test de connexion avec psql..."
if command -v psql &> /dev/null; then
    export PGPASSWORD=$DB_PASSWORD
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
        echo "✅ Connexion PostgreSQL réussie"
        echo "Base de données accessible et fonctionnelle"
    else
        echo "❌ Connexion PostgreSQL échouée"
        echo "Vérifiez les identifiants de connexion"
    fi
    unset PGPASSWORD
else
    echo "⚠️  psql non installé, impossible de tester la connexion PostgreSQL"
fi

echo ""
echo "4. Test de l'URL JDBC..."
JDBC_URL="jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_NAME"
echo "URL JDBC: $JDBC_URL"

echo ""
echo "=========================================="
echo "Si tous les tests passent, la base de données est accessible"
echo "Si des tests échouent, vérifiez la configuration"
