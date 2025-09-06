// Script de test pour le système de fidélité automatique
// À exécuter dans la console du navigateur ou dans Node.js

console.log('🧪 Test du Système de Fidélité Automatique');
console.log('==========================================');

// Configuration de test
const TEST_CONFIG = {
  clientId: 'client_id_a_remplacer', // Remplacez par un vrai ID de client
  testAmounts: [25, 75, 150, 300], // Montants de test en euros
  supabaseUrl: 'VOTRE_URL_SUPABASE',
  supabaseKey: 'VOTRE_CLE_SUPABASE'
};

// Fonction de test principale
async function testLoyaltySystem() {
  try {
    console.log('🚀 Démarrage des tests...');
    
    // Test 1: Vérifier la configuration
    await testConfiguration();
    
    // Test 2: Tester le calcul des points
    await testPointCalculation();
    
    // Test 3: Tester l'attribution automatique
    await testAutomaticPoints();
    
    // Test 4: Vérifier les statistiques
    await testStatistics();
    
    console.log('✅ Tous les tests sont terminés !');
    
  } catch (error) {
    console.error('❌ Erreur lors des tests:', error);
  }
}

// Test 1: Vérifier la configuration
async function testConfiguration() {
  console.log('\n📋 Test 1: Vérification de la configuration...');
  
  try {
    const { data, error } = await supabase
      .from('loyalty_config')
      .select('*')
      .order('key');
    
    if (error) throw error;
    
    console.log('✅ Configuration chargée:', data.length, 'paramètres');
    
    // Vérifier les paramètres essentiels
    const requiredKeys = [
      'points_per_euro',
      'minimum_purchase_for_points',
      'bonus_threshold_50',
      'bonus_threshold_100',
      'bonus_threshold_200'
    ];
    
    const missingKeys = requiredKeys.filter(key => 
      !data.find(item => item.key === key)
    );
    
    if (missingKeys.length > 0) {
      console.warn('⚠️ Paramètres manquants:', missingKeys);
    } else {
      console.log('✅ Tous les paramètres requis sont présents');
    }
    
    // Afficher la configuration
    data.forEach(item => {
      console.log(`   ${item.key}: ${item.value} (${item.description})`);
    });
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification de la configuration:', error);
    throw error;
  }
}

// Test 2: Tester le calcul des points
async function testPointCalculation() {
  console.log('\n🧮 Test 2: Test du calcul des points...');
  
  try {
    for (const amount of TEST_CONFIG.testAmounts) {
      const { data, error } = await supabase.rpc('calculate_loyalty_points', {
        p_amount: amount,
        p_client_id: TEST_CONFIG.clientId
      });
      
      if (error) throw error;
      
      console.log(`   Achat de ${amount}€ → ${data} points`);
      
      // Vérifier la logique de bonus
      let expectedPoints = Math.floor(amount); // Points de base
      let bonus = 0;
      
      if (amount >= 200) {
        bonus = Math.floor(expectedPoints * 0.30);
      } else if (amount >= 100) {
        bonus = Math.floor(expectedPoints * 0.20);
      } else if (amount >= 50) {
        bonus = Math.floor(expectedPoints * 0.10);
      }
      
      const totalExpected = expectedPoints + bonus;
      
      if (data === totalExpected) {
        console.log(`   ✅ Calcul correct: ${expectedPoints} + ${bonus} = ${data}`);
      } else {
        console.warn(`   ⚠️ Calcul inattendu: attendu ${totalExpected}, obtenu ${data}`);
      }
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test du calcul des points:', error);
    throw error;
  }
}

// Test 3: Tester l'attribution automatique
async function testAutomaticPoints() {
  console.log('\n🎁 Test 3: Test de l\'attribution automatique...');
  
  try {
    // Récupérer les points actuels du client
    const { data: clientData, error: clientError } = await supabase
      .from('clients')
      .select('loyalty_points, current_tier_id')
      .eq('id', TEST_CONFIG.clientId)
      .single();
    
    if (clientError) throw clientError;
    
    const pointsBefore = clientData.loyalty_points || 0;
    console.log(`   Points actuels du client: ${pointsBefore}`);
    
    // Tester l'attribution pour un achat de 75€
    const testAmount = 75;
    const { data, error } = await supabase.rpc('auto_add_loyalty_points_from_purchase', {
      p_client_id: TEST_CONFIG.clientId,
      p_amount: testAmount,
      p_source_type: 'test',
      p_description: 'Test automatique - Achat 75€'
    });
    
    if (error) throw error;
    
    if (data.success) {
      console.log(`   ✅ Points attribués avec succès pour ${testAmount}€`);
      console.log(`   Points gagnés: ${data.points_earned}`);
      console.log(`   Points avant: ${data.points_before}`);
      console.log(`   Points après: ${data.points_after}`);
      console.log(`   Niveau mis à jour: ${data.tier_upgraded ? 'Oui' : 'Non'}`);
      
      // Vérifier que les points ont bien été ajoutés
      if (data.points_after === data.points_before + data.points_earned) {
        console.log('   ✅ Vérification des points: OK');
      } else {
        console.warn('   ⚠️ Vérification des points: Incohérence détectée');
      }
      
    } else {
      console.warn(`   ⚠️ Échec de l'attribution: ${data.message}`);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors du test de l\'attribution automatique:', error);
    throw error;
  }
}

// Test 4: Vérifier les statistiques
async function testStatistics() {
  console.log('\n📊 Test 4: Vérification des statistiques...');
  
  try {
    const { data, error } = await supabase.rpc('get_loyalty_statistics');
    
    if (error) throw error;
    
    console.log('✅ Statistiques récupérées:');
    console.log(`   Clients avec points: ${data.total_clients_with_points}`);
    console.log(`   Points moyens: ${Math.round(data.average_points)}`);
    console.log(`   Total distribué: ${data.total_points_distributed}`);
    
    // Afficher la distribution par niveau
    console.log('   Distribution par niveau:');
    Object.entries(data.tier_distribution).forEach(([tier, count]) => {
      console.log(`     ${tier}: ${count} clients`);
    });
    
    // Afficher les top clients
    if (data.top_clients && data.top_clients.length > 0) {
      console.log('   Top clients:');
      data.top_clients.slice(0, 3).forEach((client, index) => {
        console.log(`     ${index + 1}. ${client.name}: ${client.points} points (${client.tier})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des statistiques:', error);
    throw error;
  }
}

// Test 5: Vérifier le tableau de bord
async function testDashboard() {
  console.log('\n🎯 Test 5: Vérification du tableau de bord...');
  
  try {
    const { data, error } = await supabase
      .from('loyalty_dashboard')
      .select('*')
      .limit(5);
    
    if (error) throw error;
    
    console.log(`✅ Tableau de bord chargé: ${data.length} clients`);
    
    if (data.length > 0) {
      console.log('   Exemple de client:');
      const client = data[0];
      console.log(`     Nom: ${client.first_name} ${client.last_name}`);
      console.log(`     Points: ${client.current_points}`);
      console.log(`     Niveau: ${client.current_tier || 'Sans niveau'}`);
      console.log(`     Réduction: ${client.discount_percentage || 0}%`);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification du tableau de bord:', error);
    throw error;
  }
}

// Test 6: Vérifier les niveaux de fidélité
async function testLoyaltyTiers() {
  console.log('\n⭐ Test 6: Vérification des niveaux de fidélité...');
  
  try {
    const { data, error } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required');
    
    if (error) throw error;
    
    console.log(`✅ Niveaux de fidélité chargés: ${data.length} niveaux`);
    
    data.forEach(tier => {
      console.log(`   ${tier.name}: ${tier.points_required} points requis, ${tier.discount_percentage}% de réduction`);
      if (tier.benefits && tier.benefits.length > 0) {
        console.log(`     Avantages: ${tier.benefits.join(', ')}`);
      }
    });
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des niveaux:', error);
    throw error;
  }
}

// Fonction de nettoyage (optionnelle)
async function cleanupTestData() {
  console.log('\n🧹 Nettoyage des données de test...');
  
  try {
    // Supprimer l'historique de test
    const { error } = await supabase
      .from('loyalty_points_history')
      .delete()
      .eq('source_type', 'test');
    
    if (error) throw error;
    
    console.log('✅ Données de test nettoyées');
    
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
  }
}

// Instructions d'utilisation
console.log('\n📖 Instructions d\'utilisation:');
console.log('1. Remplacez TEST_CONFIG.clientId par un vrai ID de client');
console.log('2. Assurez-vous que Supabase est configuré');
console.log('3. Exécutez testLoyaltySystem() pour lancer tous les tests');
console.log('4. Exécutez cleanupTestData() pour nettoyer les données de test');

// Exporter les fonctions pour utilisation
window.testLoyaltySystem = testLoyaltySystem;
window.testConfiguration = testConfiguration;
window.testPointCalculation = testPointCalculation;
window.testAutomaticPoints = testAutomaticPoints;
window.testStatistics = testStatistics;
window.testDashboard = testDashboard;
window.testLoyaltyTiers = testLoyaltyTiers;
window.cleanupTestData = cleanupTestData;

console.log('\n🎯 Fonctions de test disponibles:');
console.log('- testLoyaltySystem() : Lance tous les tests');
console.log('- testConfiguration() : Test de la configuration');
console.log('- testPointCalculation() : Test du calcul des points');
console.log('- testAutomaticPoints() : Test de l\'attribution');
console.log('- testStatistics() : Test des statistiques');
console.log('- testDashboard() : Test du tableau de bord');
console.log('- testLoyaltyTiers() : Test des niveaux');
console.log('- cleanupTestData() : Nettoyage des données de test');





