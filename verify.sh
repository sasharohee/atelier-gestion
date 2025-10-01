#!/bin/bash

echo "🔍 Vérification de l'état des bases de données"

echo "📊 État de la base de développement :"
flyway -configFiles=flyway.dev.toml info

echo ""
echo "📊 État de la base de production :"
flyway -configFiles=flyway.prod.toml info
