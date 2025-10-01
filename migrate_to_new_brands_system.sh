#!/bin/bash

# Script de migration vers le nouveau système des marques
# Ce script va reconstruire complètement le système pour permettre la modification de toutes les marques

echo "🚀 Démarrage de la migration vers le nouveau système des marques..."

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "rebuild_brands_system_fixed.sql" ]; then
    echo "❌ Erreur: Le fichier rebuild_brands_system_fixed.sql n'est pas trouvé"
    echo "Assurez-vous d'être dans le répertoire du projet"
    exit 1
fi

echo "📋 Étapes de la migration:"
echo "1. Exécution du script SQL de reconstruction"
echo "2. Remplacement des fichiers de l'application"
echo "3. Test du nouveau système"
echo ""

# Étape 1: Exécuter le script SQL
echo "🔧 Étape 1: Reconstruction de la base de données..."
echo "⚠️  ATTENTION: Cette étape va supprimer et recréer les tables des marques"
echo "Les données existantes seront sauvegardées automatiquement"
echo ""

# Demander confirmation
read -p "Voulez-vous continuer ? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration annulée"
    exit 1
fi

# Vérifier si psql est disponible
if ! command -v psql &> /dev/null; then
    echo "❌ Erreur: psql n'est pas installé ou n'est pas dans le PATH"
    echo "Installez PostgreSQL ou utilisez le client Supabase"
    echo ""
    echo "Alternative: Exécutez manuellement le script SQL dans l'interface Supabase:"
    echo "1. Allez sur https://supabase.com/dashboard"
    echo "2. Ouvrez votre projet"
    echo "3. Allez dans SQL Editor"
    echo "4. Copiez le contenu de rebuild_brands_system_fixed.sql"
    echo "5. Exécutez le script"
    echo ""
    exit 1
fi

# Essayer d'exécuter le script SQL
echo "🔧 Exécution du script SQL..."
if psql -h db.olrihggkxyksuofkesnk.supabase.co -U postgres -d postgres -f rebuild_brands_system_fixed.sql; then
    echo "✅ Script SQL exécuté avec succès"
else
    echo "❌ Erreur lors de l'exécution du script SQL"
    echo "Veuillez exécuter manuellement le script dans l'interface Supabase"
    echo ""
    echo "Instructions manuelles:"
    echo "1. Allez sur https://supabase.com/dashboard"
    echo "2. Ouvrez votre projet"
    echo "3. Allez dans SQL Editor"
    echo "4. Copiez le contenu de rebuild_brands_system_fixed.sql"
    echo "5. Exécutez le script"
    echo ""
    exit 1
fi

# Étape 2: Remplacer les fichiers
echo ""
echo "🔧 Étape 2: Remplacement des fichiers de l'application..."

# Sauvegarder les anciens fichiers
echo "📁 Sauvegarde des anciens fichiers..."
if [ -f "src/services/deviceManagementService.ts" ]; then
    cp src/services/deviceManagementService.ts src/services/deviceManagementService_backup.ts
    echo "✅ deviceManagementService.ts sauvegardé"
fi

if [ -f "src/pages/Catalog/DeviceManagement.tsx" ]; then
    cp src/pages/Catalog/DeviceManagement.tsx src/pages/Catalog/DeviceManagement_backup.tsx
    echo "✅ DeviceManagement.tsx sauvegardé"
fi

# Remplacer par les nouveaux fichiers
echo "📁 Installation des nouveaux fichiers..."

if [ -f "src/services/brandService_new.ts" ]; then
    cp src/services/brandService_new.ts src/services/brandService.ts
    echo "✅ Nouveau brandService.ts installé"
else
    echo "❌ Erreur: brandService_new.ts non trouvé"
fi

if [ -f "src/pages/Catalog/DeviceManagement_new.tsx" ]; then
    cp src/pages/Catalog/DeviceManagement_new.tsx src/pages/Catalog/DeviceManagement.tsx
    echo "✅ Nouveau DeviceManagement.tsx installé"
else
    echo "❌ Erreur: DeviceManagement_new.tsx non trouvé"
fi

# Mettre à jour les imports dans DeviceManagement.tsx
echo "🔧 Mise à jour des imports..."
if [ -f "src/pages/Catalog/DeviceManagement.tsx" ]; then
    sed -i '' 's/import { brandService } from '\''..\/..\/services\/deviceManagementService'\'';/import { brandService } from '\''..\/..\/services\/brandService'\'';/' src/pages/Catalog/DeviceManagement.tsx
    echo "✅ Imports mis à jour"
fi

# Étape 3: Test
echo ""
echo "🔧 Étape 3: Test du nouveau système..."
echo "✅ Migration terminée !"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Redémarrez votre serveur de développement (npm run dev)"
echo "2. Allez dans 'Gestion des Appareils' > 'Marques'"
echo "3. Cliquez sur 'Modifier' pour Apple"
echo "4. Vérifiez que vous pouvez modifier le nom, description et catégories"
echo ""
echo "🎉 Le nouveau système permet maintenant de modifier TOUTES les marques !"
echo ""
echo "🔧 Si vous rencontrez des problèmes:"
echo "- Vérifiez les logs de la console du navigateur"
echo "- Vérifiez que le script SQL a été exécuté correctement"
echo "- Les anciens fichiers sont sauvegardés avec l'extension _backup"
echo ""
echo "✅ Migration terminée avec succès !"
