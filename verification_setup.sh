#!/bin/bash

echo "🔍 Vérification de la configuration de l'application..."

# Vérifier que @hello-pangea/dnd est installé
if npm list @hello-pangea/dnd > /dev/null 2>&1; then
    echo "✅ @hello-pangea/dnd est installé"
else
    echo "❌ @hello-pangea/dnd n'est pas installé"
fi

# Vérifier que react-beautiful-dnd n'est plus installé
if npm list react-beautiful-dnd > /dev/null 2>&1; then
    echo "❌ react-beautiful-dnd est encore installé (à désinstaller)"
else
    echo "✅ react-beautiful-dnd a été correctement désinstallé"
fi

# Vérifier les dépendances principales
echo ""
echo "📦 Vérification des dépendances principales :"

dependencies=("react" "react-dom" "@mui/material" "@emotion/react" "@emotion/styled" "supabase")

for dep in "${dependencies[@]}"; do
    if npm list $dep > /dev/null 2>&1; then
        version=$(npm list $dep --depth=0 | grep $dep | awk '{print $2}')
        echo "✅ $dep: $version"
    else
        echo "❌ $dep: non installé"
    fi
done

# Vérifier les fichiers de configuration
echo ""
echo "📁 Vérification des fichiers de configuration :"

config_files=("package.json" "tsconfig.json" "vite.config.ts" "src/lib/supabase.ts")

for file in "${config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
    else
        echo "❌ $file manquant"
    fi
done

# Vérifier les fichiers de correction
echo ""
echo "🔧 Fichiers de correction créés :"

correction_files=("update_database.sql" "ERREURS_RESOLUTION.md" "MISE_A_JOUR_REACT_BEAUTIFUL_DND.md")

for file in "${correction_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file existe"
    else
        echo "❌ $file manquant"
    fi
done

echo ""
echo "🎯 Prochaines étapes :"
echo "1. Exécuter le script SQL dans Supabase (update_database.sql)"
echo "2. Redémarrer l'application : npm run dev"
echo "3. Tester les fonctionnalités : Kanban, Ventes, etc."
echo "4. Vérifier qu'il n'y a plus d'erreurs dans la console"

echo ""
echo "✨ Vérification terminée !"
