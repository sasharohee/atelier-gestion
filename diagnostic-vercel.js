#!/usr/bin/env node

/**
 * Script de diagnostic pour le déploiement Vercel
 * Vérifie la configuration et les prérequis
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Diagnostic Vercel - Atelier Gestion');
console.log('=====================================');

let hasErrors = false;

// Vérifier les fichiers essentiels
const requiredFiles = [
  'package.json',
  'vite.config.ts',
  'vercel.json',
  'src/App.tsx',
  'src/index.tsx'
];

console.log('\n📁 Vérification des fichiers essentiels...');
requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} - MANQUANT`);
    hasErrors = true;
  }
});

// Vérifier package.json
console.log('\n📦 Vérification de package.json...');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (!packageJson.scripts || !packageJson.scripts.build) {
    console.log('❌ Script "build" manquant dans package.json');
    hasErrors = true;
  } else {
    console.log('✅ Script build trouvé');
  }
  
  if (!packageJson.dependencies) {
    console.log('❌ Aucune dépendance trouvée');
    hasErrors = true;
  } else {
    console.log(`✅ ${Object.keys(packageJson.dependencies).length} dépendances trouvées`);
  }
} catch (error) {
  console.log('❌ Erreur lors de la lecture de package.json:', error.message);
  hasErrors = true;
}

// Vérifier vercel.json
console.log('\n⚙️ Vérification de vercel.json...');
try {
  const vercelConfig = JSON.parse(fs.readFileSync('vercel.json', 'utf8'));
  
  if (!vercelConfig.buildCommand) {
    console.log('⚠️ buildCommand non spécifié dans vercel.json');
  } else {
    console.log('✅ buildCommand configuré');
  }
  
  if (!vercelConfig.outputDirectory) {
    console.log('⚠️ outputDirectory non spécifié dans vercel.json');
  } else {
    console.log('✅ outputDirectory configuré');
  }
} catch (error) {
  console.log('❌ Erreur lors de la lecture de vercel.json:', error.message);
  hasErrors = true;
}

// Vérifier les variables d'environnement
console.log('\n🔐 Vérification des variables d\'environnement...');
const envFile = '.env';
if (fs.existsSync(envFile)) {
  console.log('✅ Fichier .env trouvé');
} else {
  console.log('⚠️ Fichier .env non trouvé (peut être configuré sur Vercel)');
}

// Vérifier le répertoire src
console.log('\n📂 Vérification de la structure src...');
if (fs.existsSync('src')) {
  const srcFiles = fs.readdirSync('src', { recursive: true });
  console.log(`✅ Répertoire src trouvé avec ${srcFiles.length} fichiers`);
} else {
  console.log('❌ Répertoire src manquant');
  hasErrors = true;
}

// Résumé
console.log('\n📊 Résumé du diagnostic:');
if (hasErrors) {
  console.log('❌ Des erreurs ont été détectées. Veuillez les corriger avant le déploiement.');
  process.exit(1);
} else {
  console.log('✅ Tous les tests sont passés. Prêt pour le déploiement !');
  process.exit(0);
}
