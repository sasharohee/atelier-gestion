#!/bin/bash

# Script de migration simple pour le système des marques
# Ce script remplace les fichiers sans nécessiter d'authentification SQL

echo "🚀 Migration simple vers le nouveau système des marques..."

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "fix_brands_final.sql" ]; then
    echo "❌ Erreur: Le fichier fix_brands_final.sql n'est pas trouvé"
    echo "Assurez-vous d'être dans le répertoire du projet"
    exit 1
fi

echo "📋 Étapes de la migration:"
echo "1. Remplacement des fichiers de l'application"
echo "2. Instructions pour le script SQL"
echo ""

# Étape 1: Sauvegarder et remplacer les fichiers
echo "🔧 Étape 1: Remplacement des fichiers de l'application..."

# Sauvegarder les anciens fichiers
echo "📁 Sauvegarde des anciens fichiers..."
if [ -f "src/services/deviceManagementService.ts" ]; then
    cp src/services/deviceManagementService.ts src/services/deviceManagementService_backup_$(date +%Y%m%d_%H%M%S).ts
    echo "✅ deviceManagementService.ts sauvegardé"
fi

if [ -f "src/pages/Catalog/DeviceManagement.tsx" ]; then
    cp src/pages/Catalog/DeviceManagement.tsx src/pages/Catalog/DeviceManagement_backup_$(date +%Y%m%d_%H%M%S).tsx
    echo "✅ DeviceManagement.tsx sauvegardé"
fi

# Remplacer par les nouveaux fichiers
echo "📁 Installation des nouveaux fichiers..."

if [ -f "src/services/brandService_new.ts" ]; then
    cp src/services/brandService_new.ts src/services/brandService.ts
    echo "✅ Nouveau brandService.ts installé"
else
    echo "❌ Erreur: brandService_new.ts non trouvé"
    exit 1
fi

if [ -f "src/pages/Catalog/DeviceManagement_new.tsx" ]; then
    cp src/pages/Catalog/DeviceManagement_new.tsx src/pages/Catalog/DeviceManagement.tsx
    echo "✅ Nouveau DeviceManagement.tsx installé"
else
    echo "❌ Erreur: DeviceManagement_new.tsx non trouvé"
    exit 1
fi

# Mettre à jour les imports dans DeviceManagement.tsx
echo "🔧 Mise à jour des imports..."
if [ -f "src/pages/Catalog/DeviceManagement.tsx" ]; then
    # Remplacer l'import du service
    sed -i '' 's/import { brandService } from '\''..\/..\/services\/deviceManagementService'\'';/import { brandService } from '\''..\/..\/services\/brandService'\'';/' src/pages/Catalog/DeviceManagement.tsx
    
    # Vérifier que le remplacement a fonctionné
    if grep -q "import { brandService } from '../../services/brandService'" src/pages/Catalog/DeviceManagement.tsx; then
        echo "✅ Imports mis à jour avec succès"
    else
        echo "⚠️  Import non trouvé, vérifiez manuellement"
    fi
fi

echo ""
echo "🔧 Étape 2: Script SQL à exécuter"
echo ""
echo "⚠️  IMPORTANT: Vous devez maintenant exécuter le script SQL dans Supabase"
echo ""
echo "📋 Instructions:"
echo "1. Allez sur https://supabase.com/dashboard"
echo "2. Ouvrez votre projet"
echo "3. Allez dans SQL Editor"
echo "4. Copiez le contenu du fichier: fix_brands_final.sql"
echo "5. Collez-le dans l'éditeur SQL"
echo "6. Cliquez sur 'Run' pour exécuter"
echo ""
echo "📄 Contenu du fichier SQL:"
echo "----------------------------------------"
cat fix_brands_final.sql
echo "----------------------------------------"
echo ""

echo "✅ Migration des fichiers terminée !"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Exécutez le script SQL dans Supabase (voir instructions ci-dessus)"
echo "2. Redémarrez votre serveur de développement: npm run dev"
echo "3. Allez dans 'Gestion des Appareils' > 'Marques'"
echo "4. Cliquez sur 'Modifier' pour Apple"
echo "5. Vérifiez que vous pouvez modifier le nom, description et catégories"
echo ""
echo "🎉 Après le script SQL, vous pourrez modifier TOUTES les marques !"
echo ""
echo "🔧 Si vous rencontrez des problèmes:"
echo "- Vérifiez que le script SQL a été exécuté correctement"
echo "- Vérifiez les logs de la console du navigateur"
echo "- Les anciens fichiers sont sauvegardés avec timestamp"
echo ""
echo "✅ Migration terminée avec succès !"
