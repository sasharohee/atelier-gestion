// =====================================================
// TEST ISOLATION CODE VS RLS
// =====================================================
// Script pour tester si le problème d'isolation vient
// du code ou de la configuration RLS
// Date: 2025-01-23
// =====================================================

import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (même que dans l'app)
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testIsolationCodeVsRLS() {
  console.log('🔍 TEST ISOLATION CODE VS RLS');
  console.log('==============================\n');

  try {
    // 1. Test sans authentification (simulation d'un utilisateur non connecté)
    console.log('1️⃣ Test sans authentification...');
    
    const { data: clientsWithoutAuth, error: errorWithoutAuth } = await supabase
      .from('clients')
      .select('*')
      .limit(10);
    
    if (errorWithoutAuth) {
      console.log('✅ RLS fonctionne: Erreur sans authentification:', errorWithoutAuth.message);
    } else {
      console.log('❌ PROBLÈME RLS: Données visibles sans authentification');
      console.log(`   Nombre de clients visibles: ${clientsWithoutAuth.length}`);
      if (clientsWithoutAuth.length > 0) {
        console.log('   Premiers clients:');
        clientsWithoutAuth.slice(0, 3).forEach((client, index) => {
          console.log(`     ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
        });
      }
    }
    console.log('');

    // 2. Test avec authentification (simulation du code de l'application)
    console.log('2️⃣ Test avec authentification...');
    
    // Simuler la récupération de l'utilisateur comme dans le code
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté pour le test');
      console.log('💡 Connectez-vous à l\'application pour tester l\'authentification');
    } else {
      console.log('✅ Utilisateur connecté:', user.email);
      
      // Test avec filtrage par user_id (comme dans le code)
      const { data: clientsWithAuth, error: errorWithAuth } = await supabase
        .from('clients')
        .select('*')
        .eq('user_id', user.id)
        .limit(10);
      
      if (errorWithAuth) {
        console.log('❌ Erreur avec authentification:', errorWithAuth.message);
      } else {
        console.log(`✅ Clients récupérés avec authentification: ${clientsWithAuth.length}`);
        clientsWithAuth.forEach((client, index) => {
          console.log(`  ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
        });
      }
      
      // Test sans filtrage par user_id (pour voir si RLS fonctionne)
      const { data: allClientsWithAuth, error: errorAllClients } = await supabase
        .from('clients')
        .select('*')
        .limit(10);
      
      if (errorAllClients) {
        console.log('✅ RLS fonctionne: Erreur sans filtrage:', errorAllClients.message);
      } else {
        console.log(`⚠️ RLS ne filtre pas: ${allClientsWithAuth.length} clients visibles sans filtrage`);
        const otherUsersClients = allClientsWithAuth.filter(client => client.user_id !== user.id);
        if (otherUsersClients.length > 0) {
          console.log('❌ PROBLÈME: Vous pouvez voir des clients d\'autres utilisateurs');
          otherUsersClients.forEach((client, index) => {
            console.log(`  ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
          });
        } else {
          console.log('✅ RLS fonctionne: Seuls vos clients sont visibles');
        }
      }
    }
    console.log('');

    // 3. Test de création d'un client
    console.log('3️⃣ Test de création d\'un client...');
    
    if (user) {
      try {
        const testClient = {
          first_name: 'Test',
          last_name: 'Isolation',
          email: `test.isolation.${Date.now()}@example.com`,
          phone: '0123456789',
          address: '123 Test Street',
          user_id: user.id
        };
        
        const { data: createdClient, error: createError } = await supabase
          .from('clients')
          .insert([testClient])
          .select()
          .single();
        
        if (createError) {
          console.log('❌ Erreur lors de la création:', createError.message);
        } else {
          console.log('✅ Client créé avec succès:', createdClient.id);
          
          // Vérifier que le client est visible
          const { data: retrievedClient, error: retrieveError } = await supabase
            .from('clients')
            .select('*')
            .eq('id', createdClient.id)
            .single();
          
          if (retrieveError) {
            console.log('❌ Client non visible après création:', retrieveError.message);
          } else {
            console.log('✅ Client visible après création');
          }
          
          // Nettoyer le test
          await supabase
            .from('clients')
            .delete()
            .eq('id', createdClient.id);
          console.log('✅ Test nettoyé');
        }
      } catch (error) {
        console.log('❌ Erreur lors du test de création:', error.message);
      }
    }
    console.log('');

    // 4. Recommandations
    console.log('4️⃣ Recommandations...');
    console.log('');
    
    if (clientsWithoutAuth && clientsWithoutAuth.length > 0) {
      console.log('🚨 PROBLÈME CRITIQUE: RLS ne fonctionne pas');
      console.log('🔧 Actions à effectuer:');
      console.log('   1. Exécuter le script de correction RLS ultra-strict');
      console.log('   2. Vérifier que RLS est activé sur la table clients');
      console.log('   3. Vérifier que les politiques RLS sont correctes');
    } else if (user && allClientsWithAuth && allClientsWithAuth.length > 0) {
      const otherUsersClients = allClientsWithAuth.filter(client => client.user_id !== user.id);
      if (otherUsersClients.length > 0) {
        console.log('🚨 PROBLÈME: RLS ne filtre pas correctement');
        console.log('🔧 Actions à effectuer:');
        console.log('   1. Vérifier les politiques RLS');
        console.log('   2. S\'assurer que les politiques utilisent user_id = auth.uid()');
      } else {
        console.log('✅ RLS fonctionne correctement');
        console.log('💡 Le problème pourrait venir du code de l\'application');
        console.log('🔧 Vérifiez:');
        console.log('   1. Que l\'application utilise bien supabase.auth.getUser()');
        console.log('   2. Que les requêtes incluent .eq(\'user_id\', user.id)');
        console.log('   3. Que l\'utilisateur est bien authentifié');
      }
    } else {
      console.log('✅ Configuration semble correcte');
      console.log('💡 Testez l\'application avec différents utilisateurs');
    }

  } catch (error) {
    console.error('💥 Erreur lors du test:', error);
  }
}

// Exécuter le test
testIsolationCodeVsRLS().then(() => {
  console.log('\n🏁 Test terminé');
  process.exit(0);
}).catch(error => {
  console.error('💥 Erreur fatale:', error);
  process.exit(1);
});
