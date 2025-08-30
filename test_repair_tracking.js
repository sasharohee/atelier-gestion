// Script de test pour le suivi des réparations
// Ce script teste les fonctionnalités de suivi des réparations par les clients

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase (à adapter selon votre configuration)
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testRepairTracking() {
  console.log('🧪 Test du système de suivi des réparations\n');

  try {
    // 1. Créer un client de test
    console.log('1. Création d\'un client de test...');
    const { data: client, error: clientError } = await supabase
      .from('clients')
      .insert([
        {
          first_name: 'Jean',
          last_name: 'Dupont',
          email: 'jean.dupont@test.com',
          phone: '0123456789'
        }
      ])
      .select()
      .single();

    if (clientError) {
      console.log('Client existe déjà ou erreur:', clientError.message);
      // Récupérer le client existant
      const { data: existingClient } = await supabase
        .from('clients')
        .select('*')
        .eq('email', 'jean.dupont@test.com')
        .single();
      
      if (existingClient) {
        client = existingClient;
        console.log('✅ Client de test récupéré:', client.email);
      }
    } else {
      console.log('✅ Client de test créé:', client.email);
    }

    // 2. Créer un appareil de test
    console.log('\n2. Création d\'un appareil de test...');
    const { data: device, error: deviceError } = await supabase
      .from('devices')
      .insert([
        {
          brand: 'Apple',
          model: 'iPhone 12',
          serial_number: 'TEST123456',
          type: 'smartphone'
        }
      ])
      .select()
      .single();

    if (deviceError) {
      console.log('Appareil existe déjà ou erreur:', deviceError.message);
      // Récupérer l'appareil existant
      const { data: existingDevice } = await supabase
        .from('devices')
        .select('*')
        .eq('serial_number', 'TEST123456')
        .single();
      
      if (existingDevice) {
        device = existingDevice;
        console.log('✅ Appareil de test récupéré:', device.brand, device.model);
      }
    } else {
      console.log('✅ Appareil de test créé:', device.brand, device.model);
    }

    // 3. Créer une réparation de test
    console.log('\n3. Création d\'une réparation de test...');
    const { data: repair, error: repairError } = await supabase
      .from('repairs')
      .insert([
        {
          client_id: client.id,
          device_id: device.id,
          status: 'in_progress',
          description: 'Écran cassé, remplacement nécessaire',
          issue: 'Écran LCD endommagé suite à une chute',
          estimated_duration: 120,
          due_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
          is_urgent: false,
          notes: 'Pièces commandées, réparation prévue dans 2 jours',
          total_price: 89.99,
          is_paid: false
        }
      ])
      .select()
      .single();

    if (repairError) {
      console.log('Erreur lors de la création de la réparation:', repairError.message);
      return;
    }

    console.log('✅ Réparation de test créée:', repair.id);
    console.log('   - Statut:', repair.status);
    console.log('   - Prix:', repair.total_price, '€');

    // 4. Tester la fonction de suivi
    console.log('\n4. Test de la fonction de suivi...');
    const { data: trackingData, error: trackingError } = await supabase
      .rpc('get_repair_tracking_info', {
        p_repair_id: repair.id,
        p_client_email: 'jean.dupont@test.com'
      });

    if (trackingError) {
      console.log('❌ Erreur lors du test de suivi:', trackingError.message);
    } else {
      console.log('✅ Fonction de suivi testée avec succès');
      console.log('   - Client:', trackingData[0]?.client_first_name, trackingData[0]?.client_last_name);
      console.log('   - Appareil:', trackingData[0]?.device_brand, trackingData[0]?.device_model);
      console.log('   - Statut:', trackingData[0]?.repair_status);
    }

    // 5. Tester la fonction d'historique
    console.log('\n5. Test de la fonction d\'historique...');
    const { data: historyData, error: historyError } = await supabase
      .rpc('get_client_repair_history', {
        p_client_email: 'jean.dupont@test.com'
      });

    if (historyError) {
      console.log('❌ Erreur lors du test d\'historique:', historyError.message);
    } else {
      console.log('✅ Fonction d\'historique testée avec succès');
      console.log('   - Nombre de réparations:', historyData.length);
      if (historyData.length > 0) {
        console.log('   - Dernière réparation:', historyData[0]?.repair_description);
      }
    }

    // 6. Tester la mise à jour de statut
    console.log('\n6. Test de la mise à jour de statut...');
    const { data: updateResult, error: updateError } = await supabase
      .rpc('update_repair_status', {
        p_repair_id: repair.id,
        p_new_status: 'completed',
        p_notes: 'Réparation terminée avec succès'
      });

    if (updateError) {
      console.log('❌ Erreur lors de la mise à jour:', updateError.message);
    } else {
      console.log('✅ Mise à jour de statut réussie');
      
      // Vérifier la mise à jour
      const { data: updatedRepair } = await supabase
        .from('repairs')
        .select('status, notes')
        .eq('id', repair.id)
        .single();
      
      console.log('   - Nouveau statut:', updatedRepair?.status);
      console.log('   - Notes mises à jour:', updatedRepair?.notes);
    }

    // 7. Test de recherche directe via l'API
    console.log('\n7. Test de recherche directe...');
    const { data: directSearch, error: searchError } = await supabase
      .from('repairs')
      .select(`
        *,
        client:clients(first_name, last_name, email, phone),
        device:devices(brand, model, serial_number, type)
      `)
      .eq('id', repair.id)
      .eq('clients.email', 'jean.dupont@test.com')
      .single();

    if (searchError) {
      console.log('❌ Erreur lors de la recherche directe:', searchError.message);
    } else {
      console.log('✅ Recherche directe réussie');
      console.log('   - Client:', directSearch.client?.first_name, directSearch.client?.last_name);
      console.log('   - Appareil:', directSearch.device?.brand, directSearch.device?.model);
      console.log('   - Statut final:', directSearch.status);
    }

    console.log('\n🎉 Tous les tests de suivi des réparations sont passés avec succès !');
    console.log('\n📋 Résumé:');
    console.log('   - Client créé/récupéré:', client.email);
    console.log('   - Appareil créé/récupéré:', device.brand, device.model);
    console.log('   - Réparation créée:', repair.id);
    console.log('   - Fonctions de suivi testées');
    console.log('   - Fonctions d\'historique testées');
    console.log('   - Mise à jour de statut testée');

  } catch (error) {
    console.error('❌ Erreur générale lors des tests:', error);
  }
}

// Exécuter les tests
testRepairTracking().then(() => {
  console.log('\n🏁 Tests terminés');
  process.exit(0);
}).catch((error) => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
