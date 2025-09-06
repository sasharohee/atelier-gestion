// Test de mise à jour des réparations
// Ce script vérifie que les mises à jour des réparations fonctionnent correctement

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase (à adapter selon votre configuration)
const supabaseUrl = process.env.SUPABASE_URL || 'your-supabase-url';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'your-supabase-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testRepairUpdate() {
  console.log('🧪 Test de mise à jour des réparations...');
  
  try {
    // 1. Se connecter
    const { data: { user }, error: authError } = await supabase.auth.signInWithPassword({
      email: 'test@example.com', // Remplacer par un email de test
      password: 'password123'     // Remplacer par le mot de passe de test
    });
    
    if (authError) {
      console.error('❌ Erreur d\'authentification:', authError);
      return;
    }
    
    console.log('✅ Authentification réussie');
    
    // 2. Récupérer une réparation existante
    const { data: repairs, error: fetchError } = await supabase
      .from('repairs')
      .select('*')
      .eq('user_id', user.id)
      .limit(1);
    
    if (fetchError) {
      console.error('❌ Erreur lors de la récupération des réparations:', fetchError);
      return;
    }
    
    if (!repairs || repairs.length === 0) {
      console.log('⚠️ Aucune réparation trouvée pour les tests');
      return;
    }
    
    const repair = repairs[0];
    console.log('📋 Réparation trouvée:', {
      id: repair.id,
      status: repair.status,
      description: repair.description
    });
    
    // 3. Tester la mise à jour du statut
    const newStatus = repair.status === 'new' ? 'in_progress' : 'new';
    console.log(`🔄 Mise à jour du statut de "${repair.status}" vers "${newStatus}"...`);
    
    const { data: updatedRepair, error: updateError } = await supabase
      .from('repairs')
      .update({ 
        status: newStatus,
        updated_at: new Date().toISOString()
      })
      .eq('id', repair.id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (updateError) {
      console.error('❌ Erreur lors de la mise à jour:', updateError);
      return;
    }
    
    console.log('✅ Mise à jour réussie:', {
      id: updatedRepair.id,
      status: updatedRepair.status,
      updated_at: updatedRepair.updated_at
    });
    
    // 4. Vérifier que la mise à jour a bien été appliquée
    const { data: verificationRepair, error: verifyError } = await supabase
      .from('repairs')
      .select('*')
      .eq('id', repair.id)
      .single();
    
    if (verifyError) {
      console.error('❌ Erreur lors de la vérification:', verifyError);
      return;
    }
    
    if (verificationRepair.status === newStatus) {
      console.log('✅ Vérification réussie: le statut a bien été mis à jour');
    } else {
      console.error('❌ Échec de la vérification: le statut n\'a pas été mis à jour');
      console.log('Statut attendu:', newStatus);
      console.log('Statut actuel:', verificationRepair.status);
    }
    
    // 5. Tester la mise à jour d'autres champs
    console.log('🔄 Test de mise à jour d\'autres champs...');
    
    const { data: multiUpdateRepair, error: multiUpdateError } = await supabase
      .from('repairs')
      .update({
        description: 'Description mise à jour par le test',
        notes: 'Notes ajoutées par le test',
        is_urgent: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', repair.id)
      .eq('user_id', user.id)
      .select()
      .single();
    
    if (multiUpdateError) {
      console.error('❌ Erreur lors de la mise à jour multiple:', multiUpdateError);
      return;
    }
    
    console.log('✅ Mise à jour multiple réussie:', {
      description: multiUpdateRepair.description,
      notes: multiUpdateRepair.notes,
      is_urgent: multiUpdateRepair.is_urgent
    });
    
    console.log('🎉 Tous les tests de mise à jour sont passés avec succès !');
    
  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

// Fonction pour tester la conversion des données
async function testDataConversion() {
  console.log('\n🧪 Test de conversion des données...');
  
  // Données en camelCase (format TypeScript)
  const repairDataCamelCase = {
    clientId: '123e4567-e89b-12d3-a456-426614174000',
    deviceId: '123e4567-e89b-12d3-a456-426614174001',
    status: 'in_progress',
    assignedTechnicianId: '123e4567-e89b-12d3-a456-426614174002',
    description: 'Test de conversion',
    estimatedDuration: 120,
    isUrgent: true,
    totalPrice: 150.50,
    dueDate: new Date(),
    isPaid: false
  };
  
  // Conversion vers snake_case (format base de données)
  const repairDataSnakeCase = {
    client_id: repairDataCamelCase.clientId,
    device_id: repairDataCamelCase.deviceId,
    status: repairDataCamelCase.status,
    assigned_technician_id: repairDataCamelCase.assignedTechnicianId,
    description: repairDataCamelCase.description,
    estimated_duration: repairDataCamelCase.estimatedDuration,
    is_urgent: repairDataCamelCase.isUrgent,
    total_price: repairDataCamelCase.totalPrice,
    due_date: repairDataCamelCase.dueDate,
    is_paid: repairDataCamelCase.isPaid
  };
  
  console.log('✅ Conversion camelCase → snake_case réussie');
  console.log('Données camelCase:', Object.keys(repairDataCamelCase));
  console.log('Données snake_case:', Object.keys(repairDataSnakeCase));
}

// Exécuter les tests
async function runTests() {
  console.log('🚀 Démarrage des tests de mise à jour des réparations...\n');
  
  await testDataConversion();
  await testRepairUpdate();
  
  console.log('\n🏁 Tests terminés');
}

// Exécuter si le script est appelé directement
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = {
  testRepairUpdate,
  testDataConversion,
  runTests
};
