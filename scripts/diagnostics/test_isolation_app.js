// =====================================================
// TEST ISOLATION DANS L'APPLICATION
// =====================================================
// Script pour tester l'isolation des clients directement
// dans le contexte de l'application
// Date: 2025-01-23
// =====================================================

import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (même que dans l'app)
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Simuler le clientService.getAll() exactement comme dans l'app
async function testClientServiceGetAll() {
  console.log('🔍 TEST CLIENT SERVICE GET ALL');
  console.log('==============================\n');

  try {
    // Utiliser directement l'authentification Supabase pour l'isolation
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté, retourner une liste vide');
      console.log('💡 Connectez-vous à l\'application pour tester l\'authentification');
      return [];
    }
    
    console.log('🔒 Récupération des clients pour l\'utilisateur:', user.id);
    
    // Récupérer les clients de l'utilisateur connecté avec filtrage par user_id
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (error) {
      console.log('❌ Erreur lors de la récupération des clients:', error.message);
      return [];
    }
    
    console.log(`✅ ${data.length} clients récupérés pour l'utilisateur ${user.email}`);
    
    // Afficher les détails des clients
    data.forEach((client, index) => {
      console.log(`  ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
    });
    
    return data;
    
  } catch (error) {
    console.error('💥 Erreur lors du test:', error);
    return [];
  }
}

// Test de l'isolation RLS directe
async function testRLSIsolation() {
  console.log('\n🔍 TEST ISOLATION RLS DIRECTE');
  console.log('==============================\n');

  try {
    // Test 1: Récupérer TOUS les clients (devrait être limité par RLS)
    console.log('1️⃣ Test: Récupération de TOUS les clients...');
    
    const { data: allClients, error: allError } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (allError) {
      console.log('✅ RLS fonctionne: Erreur lors de la récupération de tous les clients:', allError.message);
    } else {
      console.log(`⚠️ RLS ne filtre pas: ${allClients.length} clients visibles sans filtrage`);
      
      // Analyser les clients visibles
      const userCounts = {};
      allClients.forEach(client => {
        const userId = client.user_id || 'NULL';
        userCounts[userId] = (userCounts[userId] || 0) + 1;
      });
      
      console.log('📊 Répartition des clients par utilisateur:');
      Object.entries(userCounts).forEach(([userId, count]) => {
        console.log(`  - ${userId}: ${count} clients`);
      });
    }
    
    // Test 2: Récupérer les clients avec filtrage par user_id
    console.log('\n2️⃣ Test: Récupération avec filtrage par user_id...');
    
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté pour le test de filtrage');
    } else {
      const { data: filteredClients, error: filteredError } = await supabase
        .from('clients')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
      
      if (filteredError) {
        console.log('❌ Erreur lors du filtrage:', filteredError.message);
      } else {
        console.log(`✅ ${filteredClients.length} clients récupérés avec filtrage pour ${user.email}`);
      }
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test RLS:', error);
  }
}

// Test de création d'un client
async function testClientCreation() {
  console.log('\n🔍 TEST CRÉATION CLIENT');
  console.log('========================\n');

  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('⚠️ Aucun utilisateur connecté pour le test de création');
      return;
    }
    
    console.log('✅ Utilisateur connecté:', user.email);
    
    // Créer un client de test
    const testClient = {
      first_name: 'Test',
      last_name: 'Isolation',
      email: `test.isolation.${Date.now()}@example.com`,
      phone: '0123456789',
      address: '123 Test Street',
      user_id: user.id
    };
    
    console.log('📝 Création du client de test...');
    
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
        console.log(`   - Nom: ${retrievedClient.first_name} ${retrievedClient.last_name}`);
        console.log(`   - Email: ${retrievedClient.email}`);
        console.log(`   - User ID: ${retrievedClient.user_id}`);
      }
      
      // Nettoyer le test
      await supabase
        .from('clients')
        .delete()
        .eq('id', createdClient.id);
      console.log('✅ Test nettoyé');
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test de création:', error);
  }
}

// Test de l'isolation avec différents utilisateurs
async function testMultiUserIsolation() {
  console.log('\n🔍 TEST ISOLATION MULTI-UTILISATEUR');
  console.log('====================================\n');

  try {
    // Récupérer tous les clients (devrait être limité par RLS)
    const { data: allClients, error: allError } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (allError) {
      console.log('✅ RLS fonctionne: Erreur lors de la récupération:', allError.message);
      return;
    }
    
    // Analyser l'isolation
    const userCounts = {};
    const userEmails = {};
    
    allClients.forEach(client => {
      const userId = client.user_id || 'NULL';
      userCounts[userId] = (userCounts[userId] || 0) + 1;
      
      // Essayer de récupérer l'email de l'utilisateur
      if (userId !== 'NULL' && !userEmails[userId]) {
        userEmails[userId] = 'Utilisateur inconnu';
      }
    });
    
    console.log('📊 Analyse de l\'isolation:');
    console.log(`   - Total clients visibles: ${allClients.length}`);
    console.log(`   - Nombre d'utilisateurs différents: ${Object.keys(userCounts).length}`);
    
    Object.entries(userCounts).forEach(([userId, count]) => {
      console.log(`   - ${userId}: ${count} clients`);
    });
    
    // Vérifier si l'utilisateur actuel peut voir ses propres clients
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (user && !userError) {
      const myClients = allClients.filter(client => client.user_id === user.id);
      console.log(`\n✅ Mes clients visibles: ${myClients.length}`);
      
      const otherClients = allClients.filter(client => client.user_id !== user.id);
      if (otherClients.length > 0) {
        console.log(`❌ PROBLÈME: ${otherClients.length} clients d'autres utilisateurs visibles`);
        otherClients.slice(0, 3).forEach((client, index) => {
          console.log(`   ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
        });
      } else {
        console.log('✅ Isolation parfaite: aucun client d\'autre utilisateur visible');
      }
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test multi-utilisateur:', error);
  }
}

// Fonction principale
async function runAllTests() {
  console.log('🚀 DÉMARRAGE DES TESTS D\'ISOLATION');
  console.log('===================================\n');
  
  try {
    // Test 1: Client Service
    await testClientServiceGetAll();
    
    // Test 2: RLS Isolation
    await testRLSIsolation();
    
    // Test 3: Création de client
    await testClientCreation();
    
    // Test 4: Isolation multi-utilisateur
    await testMultiUserIsolation();
    
    console.log('\n🏁 TOUS LES TESTS TERMINÉS');
    console.log('==========================');
    
  } catch (error) {
    console.error('💥 Erreur fatale lors des tests:', error);
  }
}

// Exécuter les tests
runAllTests().then(() => {
  process.exit(0);
}).catch(error => {
  console.error('💥 Erreur fatale:', error);
  process.exit(1);
});
