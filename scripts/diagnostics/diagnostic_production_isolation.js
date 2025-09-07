// =====================================================
// DIAGNOSTIC ISOLATION PRODUCTION - VERCEL
// =====================================================
// Script pour diagnostiquer pourquoi l'isolation ne fonctionne pas
// en production sur Vercel
// Date: 2025-01-23
// =====================================================

import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (même que dans l'app)
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function diagnosticProductionIsolation() {
  console.log('🔍 DIAGNOSTIC ISOLATION PRODUCTION - VERCEL');
  console.log('==========================================\n');

  try {
    // 1. Vérifier la configuration Supabase
    console.log('1️⃣ Vérification de la configuration Supabase...');
    console.log('📡 URL Supabase:', supabaseUrl);
    console.log('🔑 Clé anonyme utilisée:', supabaseAnonKey.substring(0, 20) + '...');
    console.log('');

    // 2. Tester la connexion
    console.log('2️⃣ Test de connexion à Supabase...');
    const { data: connectionTest, error: connectionError } = await supabase
      .from('clients')
      .select('count')
      .limit(1);
    
    if (connectionError) {
      console.log('❌ Erreur de connexion:', connectionError.message);
      return;
    }
    console.log('✅ Connexion à Supabase réussie');
    console.log('');

    // 3. Vérifier l'état RLS des tables critiques
    console.log('3️⃣ Vérification de l\'état RLS des tables...');
    
    const tablesToCheck = ['clients', 'repairs', 'product_categories', 'device_categories'];
    
    for (const tableName of tablesToCheck) {
      try {
        // Tenter de récupérer des données sans authentification
        const { data, error } = await supabase
          .from(tableName)
          .select('*')
          .limit(5);
        
        if (error) {
          console.log(`❌ Table ${tableName}: Erreur - ${error.message}`);
        } else {
          console.log(`⚠️ Table ${tableName}: ${data.length} enregistrements visibles SANS authentification`);
          if (data.length > 0) {
            console.log(`   🚨 PROBLÈME DE SÉCURITÉ: Données visibles sans RLS`);
            data.forEach((record, index) => {
              console.log(`   ${index + 1}. ID: ${record.id}, user_id: ${record.user_id || 'NULL'}`);
            });
          }
        }
      } catch (err) {
        console.log(`❌ Table ${tableName}: Exception - ${err.message}`);
      }
    }
    console.log('');

    // 4. Vérifier les politiques RLS
    console.log('4️⃣ Vérification des politiques RLS...');
    
    // Note: Cette requête nécessite des privilèges admin
    try {
      const { data: policies, error: policiesError } = await supabase
        .rpc('get_table_policies', { table_name: 'clients' });
      
      if (policiesError) {
        console.log('⚠️ Impossible de vérifier les politiques (privilèges insuffisants)');
        console.log('💡 Vérifiez manuellement dans le dashboard Supabase');
      } else {
        console.log('📋 Politiques trouvées:', policies);
      }
    } catch (err) {
      console.log('⚠️ Impossible de vérifier les politiques:', err.message);
    }
    console.log('');

    // 5. Test d'authentification
    console.log('5️⃣ Test d\'authentification...');
    
    // Tenter de s'authentifier avec un utilisateur de test
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'test@example.com',
      password: 'testpassword'
    });
    
    if (authError) {
      console.log('ℹ️ Authentification de test échouée (normal si utilisateur n\'existe pas)');
    } else {
      console.log('✅ Authentification réussie:', authData.user?.email);
      
      // Tester l'isolation avec un utilisateur authentifié
      const { data: userClients, error: userClientsError } = await supabase
        .from('clients')
        .select('*')
        .limit(10);
      
      if (userClientsError) {
        console.log('❌ Erreur lors de la récupération des clients:', userClientsError.message);
      } else {
        console.log(`📊 Clients visibles pour l'utilisateur authentifié: ${userClients.length}`);
        userClients.forEach((client, index) => {
          console.log(`  ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
        });
      }
      
      // Déconnexion
      await supabase.auth.signOut();
    }
    console.log('');

    // 6. Recommandations
    console.log('6️⃣ Recommandations pour corriger l\'isolation...');
    console.log('');
    console.log('🔧 Actions à effectuer:');
    console.log('');
    console.log('1. Vérifier que RLS est activé sur toutes les tables:');
    console.log('   - Allez dans le dashboard Supabase');
    console.log('   - Table Editor > Sélectionnez chaque table');
    console.log('   - Vérifiez que "Row Level Security" est activé');
    console.log('');
    console.log('2. Vérifier les politiques RLS:');
    console.log('   - Authentication > Policies');
    console.log('   - Assurez-vous que chaque table a des politiques basées sur user_id');
    console.log('');
    console.log('3. Exécuter les scripts de correction:');
    console.log('   - correction_isolation_clients_finale_v2.sql');
    console.log('   - correction_isolation_product_categories_finale_v2.sql');
    console.log('   - correction_isolation_categories_finale.sql');
    console.log('');
    console.log('4. Vérifier les variables d\'environnement Vercel:');
    console.log('   - VITE_SUPABASE_URL');
    console.log('   - VITE_SUPABASE_ANON_KEY');
    console.log('');
    console.log('5. Tester l\'isolation après correction:');
    console.log('   - Connectez-vous avec différents utilisateurs');
    console.log('   - Vérifiez que chaque utilisateur ne voit que ses données');

  } catch (error) {
    console.error('💥 Erreur lors du diagnostic:', error);
  }
}

// Exécuter le diagnostic
diagnosticProductionIsolation().then(() => {
  console.log('\n🏁 Diagnostic terminé');
  console.log('💡 Consultez les recommandations ci-dessus pour corriger l\'isolation');
  process.exit(0);
}).catch(error => {
  console.error('💥 Erreur fatale:', error);
  process.exit(1);
});
