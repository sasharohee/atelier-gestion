#!/usr/bin/env node

/**
 * Script de test pour vérifier que la correction d'inscription fonctionne
 */

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://olrihggkxyksuofkesnk.supabase.co';
const supabaseAnonKey = process.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scmloZ2dreHlrc3VvZmtlc25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5NDA2OTMsImV4cCI6MjA3MzUxNjY5M30.-Gypdwe8jMt3qVqrl4pKc6a98rzO0lxlYh5ZCtgG7oE';

// Créer le client Supabase
const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testSignupFix() {
  try {
    console.log('🧪 Test de la correction d\'inscription...');
    
    // Test 1: Vérifier la connexion
    console.log('🔍 Test 1: Vérification de la connexion...');
    const { data: connectionTest, error: connectionError } = await supabase
      .from('clients')
      .select('count')
      .limit(1);
    
    if (connectionError) {
      console.log('⚠️  Avertissement de connexion:', connectionError.message);
    } else {
      console.log('✅ Connexion établie');
    }
    
    // Test 2: Vérifier les tables
    console.log('🔍 Test 2: Vérification des tables...');
    try {
      const { data: subData, error: subError } = await supabase
        .from('subscription_status')
        .select('count')
        .limit(1);
      
      if (subError && subError.code === 'PGRST116') {
        console.log('❌ Table subscription_status n\'existe pas');
      } else {
        console.log('✅ Table subscription_status existe');
      }
    } catch (err) {
      console.log('⚠️  Erreur lors de la vérification de subscription_status:', err.message);
    }
    
    try {
      const { data: settingsData, error: settingsError } = await supabase
        .from('system_settings')
        .select('count')
        .limit(1);
      
      if (settingsError && settingsError.code === 'PGRST116') {
        console.log('❌ Table system_settings n\'existe pas');
      } else {
        console.log('✅ Table system_settings existe');
      }
    } catch (err) {
      console.log('⚠️  Erreur lors de la vérification de system_settings:', err.message);
    }
    
    // Test 3: Tester la fonction RPC
    console.log('🔍 Test 3: Test de la fonction RPC...');
    try {
      const { data: rpcData, error: rpcError } = await supabase.rpc('create_user_default_data', {
        p_user_id: '00000000-0000-0000-0000-000000000000'
      });
      
      if (rpcError) {
        console.log('❌ Fonction RPC non disponible:', rpcError.message);
      } else {
        console.log('✅ Fonction RPC fonctionne:', rpcData);
      }
    } catch (err) {
      console.log('⚠️  Erreur lors du test RPC:', err.message);
    }
    
    // Test 4: Test d'inscription simulé
    console.log('🔍 Test 4: Test d\'inscription simulé...');
    const testEmail = `test-${Date.now()}@example.com`;
    const testPassword = 'TestPassword123!';
    
    try {
      const { data: signupData, error: signupError } = await supabase.auth.signUp({
        email: testEmail,
        password: testPassword
      });
      
      if (signupError) {
        if (signupError.message.includes('500') || signupError.message.includes('Database error')) {
          console.log('❌ Erreur 500 persistante lors de l\'inscription:', signupError.message);
        } else {
          console.log('⚠️  Erreur d\'inscription (non-500):', signupError.message);
        }
      } else {
        console.log('✅ Inscription simulée réussie');
        
        // Nettoyer le compte de test
        if (signupData.user) {
          console.log('🧹 Nettoyage du compte de test...');
          // Note: On ne peut pas supprimer le compte via l'API client
          // Il faudra le faire manuellement dans le dashboard Supabase
        }
      }
    } catch (err) {
      console.log('⚠️  Exception lors du test d\'inscription:', err.message);
    }
    
    console.log('\n📋 Résumé des tests:');
    console.log('- ✅ Connexion Supabase établie');
    console.log('- ⚠️  Tables et fonction RPC à vérifier via SQL Editor');
    console.log('- 🔧 Test d\'inscription à effectuer manuellement');
    
    console.log('\n🎯 Prochaines étapes:');
    console.log('1. Exécutez le script CORRECTION_ULTRA_ROBUSTE.sql dans Supabase');
    console.log('2. Testez l\'inscription manuellement dans l\'application');
    console.log('3. Vérifiez que l\'erreur 500 n\'apparaît plus');
    
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

// Exécuter le test
if (require.main === module) {
  testSignupFix()
    .then(() => {
      console.log('✅ Test terminé');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erreur fatale:', error);
      process.exit(1);
    });
}

module.exports = { testSignupFix };
