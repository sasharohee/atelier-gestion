const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuration Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('❌ Variables d\'environnement manquantes');
  console.log('VITE_SUPABASE_URL:', supabaseUrl ? '✅' : '❌');
  console.log('VITE_SUPABASE_ANON_KEY:', supabaseKey ? '✅' : '❌');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function testRepairTracking() {
  console.log('🔍 Test de la fonctionnalité de suivi des réparations\n');

  try {
    // 1. Vérifier que les fonctions SQL existent
    console.log('1️⃣ Vérification des fonctions SQL...');
    
    const { data: functions, error: functionsError } = await supabase
      .from('information_schema.routines')
      .select('routine_name')
      .in('routine_name', ['get_repair_tracking_info', 'get_client_repair_history', 'generate_repair_number']);

    if (functionsError) {
      console.error('❌ Erreur lors de la vérification des fonctions:', functionsError);
    } else {
      console.log('✅ Fonctions trouvées:', functions.map(f => f.routine_name));
    }

    // 2. Vérifier que la colonne repair_number existe
    console.log('\n2️⃣ Vérification de la colonne repair_number...');
    
    const { data: columns, error: columnsError } = await supabase
      .from('information_schema.columns')
      .select('column_name, data_type')
      .eq('table_name', 'repairs')
      .eq('column_name', 'repair_number');

    if (columnsError) {
      console.error('❌ Erreur lors de la vérification des colonnes:', columnsError);
    } else if (columns.length === 0) {
      console.error('❌ Colonne repair_number non trouvée !');
    } else {
      console.log('✅ Colonne repair_number trouvée:', columns[0]);
    }

    // 3. Créer des données de test
    console.log('\n3️⃣ Création de données de test...');
    
    // Créer un client de test
    const { data: client, error: clientError } = await supabase
      .from('clients')
      .upsert({
        first_name: 'Jean',
        last_name: 'Dupont',
        email: 'jean.dupont@test.com',
        phone: '0123456789'
      }, { onConflict: 'email' })
      .select()
      .single();

    if (clientError) {
      console.error('❌ Erreur lors de la création du client:', clientError);
      return;
    }
    console.log('✅ Client créé/récupéré:', client.email);

    // Créer un appareil de test
    const { data: device, error: deviceError } = await supabase
      .from('devices')
      .upsert({
        brand: 'Apple',
        model: 'iPhone 12',
        serial_number: 'TEST123456',
        type: 'smartphone'
      }, { onConflict: 'serial_number' })
      .select()
      .single();

    if (deviceError) {
      console.error('❌ Erreur lors de la création de l\'appareil:', deviceError);
      return;
    }
    console.log('✅ Appareil créé/récupéré:', device.brand, device.model);

    // Créer une réparation de test
    const { data: repair, error: repairError } = await supabase
      .from('repairs')
      .insert({
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
      })
      .select()
      .single();

    if (repairError) {
      console.error('❌ Erreur lors de la création de la réparation:', repairError);
      return;
    }
    console.log('✅ Réparation créée:', repair.id);
    console.log('📋 Numéro de réparation:', repair.repair_number);

    // 4. Tester la fonction get_repair_tracking_info
    console.log('\n4️⃣ Test de la fonction get_repair_tracking_info...');
    
    const { data: trackingData, error: trackingError } = await supabase
      .rpc('get_repair_tracking_info', {
        p_repair_id_or_number: repair.repair_number,
        p_client_email: client.email
      });

    if (trackingError) {
      console.error('❌ Erreur lors du test de get_repair_tracking_info:', trackingError);
    } else if (!trackingData || trackingData.length === 0) {
      console.error('❌ Aucune donnée retournée par get_repair_tracking_info');
    } else {
      console.log('✅ Données de suivi récupérées:', trackingData[0]);
    }

    // 5. Tester la fonction get_client_repair_history
    console.log('\n5️⃣ Test de la fonction get_client_repair_history...');
    
    const { data: historyData, error: historyError } = await supabase
      .rpc('get_client_repair_history', {
        p_client_email: client.email
      });

    if (historyError) {
      console.error('❌ Erreur lors du test de get_client_repair_history:', historyError);
    } else if (!historyData || historyData.length === 0) {
      console.error('❌ Aucune donnée retournée par get_client_repair_history');
    } else {
      console.log('✅ Historique récupéré:', historyData.length, 'réparations');
      console.log('📋 Première réparation:', historyData[0]);
    }

    // 6. Test avec l'UUID
    console.log('\n6️⃣ Test avec l\'UUID de la réparation...');
    
    const { data: trackingDataUUID, error: trackingErrorUUID } = await supabase
      .rpc('get_repair_tracking_info', {
        p_repair_id_or_number: repair.id,
        p_client_email: client.email
      });

    if (trackingErrorUUID) {
      console.error('❌ Erreur lors du test avec UUID:', trackingErrorUUID);
    } else if (!trackingDataUUID || trackingDataUUID.length === 0) {
      console.error('❌ Aucune donnée retournée avec UUID');
    } else {
      console.log('✅ Données récupérées avec UUID:', trackingDataUUID[0]);
    }

    // 7. Test avec un email incorrect
    console.log('\n7️⃣ Test avec un email incorrect...');
    
    const { data: wrongEmailData, error: wrongEmailError } = await supabase
      .rpc('get_repair_tracking_info', {
        p_repair_id_or_number: repair.repair_number,
        p_client_email: 'wrong.email@test.com'
      });

    if (wrongEmailError) {
      console.error('❌ Erreur lors du test avec email incorrect:', wrongEmailError);
    } else if (wrongEmailData && wrongEmailData.length > 0) {
      console.error('❌ Données retournées avec email incorrect (problème de sécurité)');
    } else {
      console.log('✅ Aucune donnée retournée avec email incorrect (sécurité OK)');
    }

    console.log('\n🎉 Tests terminés !');

  } catch (error) {
    console.error('💥 Erreur générale:', error);
  }
}

// Exécuter les tests
testRepairTracking();
