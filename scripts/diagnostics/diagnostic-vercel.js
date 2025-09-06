#!/usr/bin/env node

/**
 * Script de diagnostic pour Vercel
 * Vérifie la configuration avant déploiement
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Diagnostic de configuration Vercel...\n');

// Vérifier les fichiers essentiels
const requiredFiles = [
  'package.json',
  'vite.config.ts',
  'vercel.json',
  'src/lib/supabase.ts',
  'src/App.tsx'
];

console.log('📁 Vérification des fichiers essentiels:');
requiredFiles.forEach(file => {
  if (fs.existsSync(file)) {
    console.log(`✅ ${file}`);
  } else {
    console.log(`❌ ${file} - MANQUANT`);
  }
});

// Vérifier package.json
console.log('\n📦 Vérification package.json:');
try {
  const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  
  if (packageJson.scripts.build) {
    console.log('✅ Script build trouvé');
  } else {
    console.log('❌ Script build manquant');
  }
  
  if (packageJson.dependencies['@supabase/supabase-js']) {
    console.log('✅ Supabase JS trouvé');
  } else {
    console.log('❌ Supabase JS manquant');
  }
  
  if (packageJson.dependencies.vite) {
    console.log('✅ Vite trouvé');
  } else {
    console.log('❌ Vite manquant');
  }
} catch (error) {
  console.log('❌ Erreur lecture package.json:', error.message);
}

// Vérifier vercel.json
console.log('\n⚙️ Vérification vercel.json:');
try {
  const vercelConfig = JSON.parse(fs.readFileSync('vercel.json', 'utf8'));
  
  if (vercelConfig.rewrites) {
    console.log('✅ Rewrites configurés');
  } else {
    console.log('❌ Rewrites manquants');
  }
  
  if (vercelConfig.buildCommand) {
    console.log('✅ Build command configuré');
  } else {
    console.log('❌ Build command manquant');
  }
  
  if (vercelConfig.outputDirectory) {
    console.log('✅ Output directory configuré');
  } else {
    console.log('❌ Output directory manquant');
  }
} catch (error) {
  console.log('❌ Erreur lecture vercel.json:', error.message);
}

// Vérifier les variables d'environnement
console.log('\n🔐 Vérification des variables d\'environnement:');
const envVars = [
  'VITE_SUPABASE_URL',
  'VITE_SUPABASE_ANON_KEY'
];

envVars.forEach(varName => {
  if (process.env[varName]) {
    console.log(`✅ ${varName} configurée`);
  } else {
    console.log(`❌ ${varName} non configurée`);
  }
});

// Test de build
console.log('\n🔨 Test de build:');
console.log('Exécutez: npm run build');
console.log('Puis: npm run preview');

// Recommandations
console.log('\n📋 Recommandations:');
console.log('1. Vérifiez les variables d\'environnement sur Vercel Dashboard');
console.log('2. Assurez-vous que votre domaine est autorisé dans Supabase');
console.log('3. Testez le build localement avant déploiement');
console.log('4. Vérifiez les logs Vercel en cas d\'erreur');

console.log('\n✅ Diagnostic terminé!');
