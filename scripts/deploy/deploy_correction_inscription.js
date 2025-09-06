#!/usr/bin/env node

/**
 * Script de déploiement pour corriger l'erreur 500 lors de l'inscription
 * Date: 2024-01-24
 * 
 * Ce script applique la correction SQL qui maintient RLS activé
 * et corrige les politiques pour permettre l'inscription.
 */

const fs = require('fs');
const path = require('path');

// Configuration Supabase
const SUPABASE_URL = process.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SUPABASE_SERVICE_ROLE_KEY) {
  console.error('❌ SUPABASE_SERVICE_ROLE_KEY est requis pour exécuter ce script');
  console.error('   Ajoutez votre clé service_role dans les variables d\'environnement');
  process.exit(1);
}

async function deployCorrection() {
  try {
    console.log('🚀 Déploiement de la correction d\'inscription...');
    
    // Lire le script SQL
    const sqlPath = path.join(__dirname, 'correction_inscription_rls_secure.sql');
    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('📄 Script SQL chargé:', sqlPath);
    console.log('📊 Taille du script:', sqlContent.length, 'caractères');
    
    // Exécuter le script via l'API Supabase
    const response = await fetch(`${SUPABASE_URL}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY
      },
      body: JSON.stringify({
        sql: sqlContent
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Erreur HTTP ${response.status}: ${errorText}`);
    }
    
    const result = await response.json();
    console.log('✅ Script SQL exécuté avec succès');
    console.log('📋 Résultat:', result);
    
    // Vérifier que les tables et fonctions ont été créées
    console.log('\n🔍 Vérification de la configuration...');
    
    // Vérifier subscription_status
    const subscriptionCheck = await fetch(`${SUPABASE_URL}/rest/v1/subscription_status?select=count`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY
      }
    });
    
    if (subscriptionCheck.ok) {
      console.log('✅ Table subscription_status accessible');
    } else {
      console.log('⚠️ Table subscription_status non accessible:', subscriptionCheck.status);
    }
    
    // Vérifier system_settings
    const settingsCheck = await fetch(`${SUPABASE_URL}/rest/v1/system_settings?select=count`, {
      headers: {
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY
      }
    });
    
    if (settingsCheck.ok) {
      console.log('✅ Table system_settings accessible');
    } else {
      console.log('⚠️ Table system_settings non accessible:', settingsCheck.status);
    }
    
    // Tester la fonction RPC
    console.log('\n🧪 Test de la fonction RPC...');
    const rpcTest = await fetch(`${SUPABASE_URL}/rest/v1/rpc/create_user_default_data`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        'apikey': SUPABASE_SERVICE_ROLE_KEY
      },
      body: JSON.stringify({
        p_user_id: '00000000-0000-0000-0000-000000000000' // UUID de test
      })
    });
    
    if (rpcTest.ok) {
      const rpcResult = await rpcTest.json();
      console.log('✅ Fonction RPC accessible');
      console.log('📋 Résultat du test:', rpcResult);
    } else {
      console.log('⚠️ Fonction RPC non accessible:', rpcTest.status);
    }
    
    console.log('\n🎉 Déploiement terminé avec succès !');
    console.log('📝 Prochaines étapes:');
    console.log('   1. Testez l\'inscription sur votre application');
    console.log('   2. Vérifiez que les données sont créées dans subscription_status');
    console.log('   3. Vérifiez que les paramètres par défaut sont créés dans system_settings');
    
  } catch (error) {
    console.error('❌ Erreur lors du déploiement:', error.message);
    
    if (error.message.includes('exec_sql')) {
      console.log('\n💡 Solution alternative:');
      console.log('   Exécutez manuellement le script SQL dans l\'éditeur SQL de Supabase:');
      console.log('   1. Allez dans votre projet Supabase');
      console.log('   2. Ouvrez l\'éditeur SQL');
      console.log('   3. Copiez le contenu de correction_inscription_rls_secure.sql');
      console.log('   4. Exécutez le script');
    }
    
    process.exit(1);
  }
}

// Exécuter le déploiement
deployCorrection();
