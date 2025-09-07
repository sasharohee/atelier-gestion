// =====================================================
// DIAGNOSTIC ISOLATION SIMPLE
// =====================================================
// Script simple pour diagnostiquer l'isolation des clients
// Peut être exécuté dans la console du navigateur
// Date: 2025-01-23
// =====================================================

// Instructions pour utiliser ce script:
// 1. Ouvrir l'application dans le navigateur
// 2. Se connecter avec un utilisateur
// 3. Aller dans la page Clients
// 4. Ouvrir la console du navigateur (F12)
// 5. Coller ce script et l'exécuter

console.log('🔍 DIAGNOSTIC ISOLATION CLIENTS');
console.log('===============================');

// Fonction pour tester l'isolation
async function testIsolation() {
  try {
    // Récupérer l'instance Supabase depuis l'application
    const supabase = window.supabase || window.__supabase;
    
    if (!supabase) {
      console.log('❌ Supabase non trouvé. Assurez-vous d\'être sur la page de l\'application.');
      return;
    }
    
    console.log('✅ Supabase trouvé');
    
    // Test 1: Vérifier l'utilisateur connecté
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('❌ Aucun utilisateur connecté');
      console.log('💡 Connectez-vous à l\'application d\'abord');
      return;
    }
    
    console.log('✅ Utilisateur connecté:', user.email);
    console.log('   - ID:', user.id);
    
    // Test 2: Récupérer TOUS les clients (devrait être limité par RLS)
    console.log('\n🔍 Test 1: Récupération de TOUS les clients...');
    
    const { data: allClients, error: allError } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (allError) {
      console.log('✅ RLS fonctionne: Erreur lors de la récupération:', allError.message);
    } else {
      console.log(`⚠️ RLS ne filtre pas: ${allClients.length} clients visibles sans filtrage`);
      
      // Analyser les clients
      const userCounts = {};
      allClients.forEach(client => {
        const userId = client.user_id || 'NULL';
        userCounts[userId] = (userCounts[userId] || 0) + 1;
      });
      
      console.log('📊 Répartition des clients par utilisateur:');
      Object.entries(userCounts).forEach(([userId, count]) => {
        console.log(`   - ${userId}: ${count} clients`);
      });
      
      // Vérifier l'isolation
      const myClients = allClients.filter(client => client.user_id === user.id);
      const otherClients = allClients.filter(client => client.user_id !== user.id);
      
      console.log(`\n📋 Analyse d'isolation:`);
      console.log(`   - Mes clients: ${myClients.length}`);
      console.log(`   - Clients d'autres utilisateurs: ${otherClients.length}`);
      
      if (otherClients.length > 0) {
        console.log('❌ PROBLÈME: Vous pouvez voir des clients d\'autres utilisateurs');
        console.log('   Premiers clients d\'autres utilisateurs:');
        otherClients.slice(0, 3).forEach((client, index) => {
          console.log(`     ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
        });
      } else {
        console.log('✅ Isolation parfaite: seuls vos clients sont visibles');
      }
    }
    
    // Test 3: Récupérer les clients avec filtrage (comme dans le code)
    console.log('\n🔍 Test 2: Récupération avec filtrage par user_id...');
    
    const { data: filteredClients, error: filterError } = await supabase
      .from('clients')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (filterError) {
      console.log('❌ Erreur lors du filtrage:', filterError.message);
    } else {
      console.log(`✅ ${filteredClients.length} clients récupérés avec filtrage`);
      filteredClients.forEach((client, index) => {
        console.log(`   ${index + 1}. ${client.first_name} ${client.last_name} (user_id: ${client.user_id})`);
      });
    }
    
    // Test 4: Vérifier le store de l'application
    console.log('\n🔍 Test 3: Vérification du store de l\'application...');
    
    if (window.store) {
      const state = window.store.getState();
      console.log(`✅ Store trouvé: ${state.clients.length} clients dans le store`);
      
      // Vérifier si les clients du store correspondent à l'utilisateur
      const storeClients = state.clients || [];
      const storeUserClients = storeClients.filter(client => client.userId === user.id);
      const storeOtherClients = storeClients.filter(client => client.userId !== user.id);
      
      console.log(`   - Mes clients dans le store: ${storeUserClients.length}`);
      console.log(`   - Clients d'autres utilisateurs dans le store: ${storeOtherClients.length}`);
      
      if (storeOtherClients.length > 0) {
        console.log('❌ PROBLÈME: Le store contient des clients d\'autres utilisateurs');
        storeOtherClients.slice(0, 3).forEach((client, index) => {
          console.log(`     ${index + 1}. ${client.firstName} ${client.lastName} (userId: ${client.userId})`);
        });
      } else {
        console.log('✅ Store correct: seuls vos clients sont présents');
      }
    } else {
      console.log('⚠️ Store non trouvé. Essayez d\'accéder au store via React DevTools.');
    }
    
    // Recommandations
    console.log('\n🔧 RECOMMANDATIONS:');
    
    if (allClients && allClients.length > 0) {
      const otherClients = allClients.filter(client => client.user_id !== user.id);
      if (otherClients.length > 0) {
        console.log('🚨 PROBLÈME CRITIQUE: RLS ne fonctionne pas');
        console.log('   1. Exécuter le script de correction RLS ultra-strict');
        console.log('   2. Vérifier que RLS est activé sur la table clients');
        console.log('   3. Vérifier que les politiques RLS sont correctes');
      } else {
        console.log('✅ RLS fonctionne correctement');
        console.log('💡 Le problème pourrait venir du code de l\'application');
        console.log('   1. Vérifier que l\'application utilise bien supabase.auth.getUser()');
        console.log('   2. Vérifier que les requêtes incluent .eq(\'user_id\', user.id)');
        console.log('   3. Vérifier que l\'utilisateur est bien authentifié');
      }
    } else {
      console.log('ℹ️ Aucun client trouvé. Créez des clients pour tester l\'isolation.');
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du diagnostic:', error);
  }
}

// Exécuter le diagnostic
testIsolation();

console.log('\n📋 INSTRUCTIONS:');
console.log('1. Connectez-vous à l\'application');
console.log('2. Allez dans la page Clients');
console.log('3. Ouvrez la console (F12)');
console.log('4. Collez ce script et exécutez-le');
console.log('5. Analysez les résultats ci-dessus');
