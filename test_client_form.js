// Script de test pour vérifier l'enregistrement des données client
// À exécuter dans la console du navigateur après avoir créé un client

console.log('🧪 Test d\'enregistrement des données client');

// Fonction pour récupérer le dernier client créé
async function testClientData() {
  try {
    // Récupérer les clients depuis le store
    const store = window.__ZUSTAND_STORE__;
    if (!store) {
      console.log('❌ Store Zustand non trouvé');
      return;
    }

    const clients = store.getState().clients;
    if (clients.length === 0) {
      console.log('❌ Aucun client trouvé');
      return;
    }

    // Prendre le dernier client créé
    const lastClient = clients[clients.length - 1];
    console.log('📋 Dernier client créé:', lastClient);

    // Vérifier les nouveaux champs
    const newFields = {
      // Informations personnelles et entreprise
      category: lastClient.category,
      title: lastClient.title,
      companyName: lastClient.companyName,
      vatNumber: lastClient.vatNumber,
      sirenNumber: lastClient.sirenNumber,
      countryCode: lastClient.countryCode,
      
      // Adresse détaillée
      addressComplement: lastClient.addressComplement,
      region: lastClient.region,
      postalCode: lastClient.postalCode,
      city: lastClient.city,
      
      // Adresse de facturation
      billingAddressSame: lastClient.billingAddressSame,
      billingAddress: lastClient.billingAddress,
      billingAddressComplement: lastClient.billingAddressComplement,
      billingRegion: lastClient.billingRegion,
      billingPostalCode: lastClient.billingPostalCode,
      billingCity: lastClient.billingCity,
      
      // Informations complémentaires
      accountingCode: lastClient.accountingCode,
      cniIdentifier: lastClient.cniIdentifier,
      attachedFilePath: lastClient.attachedFilePath,
      internalNote: lastClient.internalNote,
      
      // Préférences
      status: lastClient.status,
      smsNotification: lastClient.smsNotification,
      emailNotification: lastClient.emailNotification,
      smsMarketing: lastClient.smsMarketing,
      emailMarketing: lastClient.emailMarketing,
    };

    console.log('🔍 Vérification des nouveaux champs:');
    Object.entries(newFields).forEach(([field, value]) => {
      const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
      console.log(`${status} ${field}: ${value}`);
    });

    // Test d'accès direct à Supabase
    console.log('🔗 Test d\'accès direct à Supabase...');
    
    // Note: Cette partie nécessite que vous ayez accès à l'objet supabase
    if (window.supabase) {
      const { data, error } = await window.supabase
        .from('clients')
        .select('*')
        .eq('id', lastClient.id)
        .single();
      
      if (error) {
        console.log('❌ Erreur Supabase:', error);
      } else {
        console.log('✅ Données brutes Supabase:', data);
        
        // Vérifier les champs snake_case
        const snakeCaseFields = {
          category: data.category,
          title: data.title,
          company_name: data.company_name,
          vat_number: data.vat_number,
          siren_number: data.siren_number,
          country_code: data.country_code,
          address_complement: data.address_complement,
          region: data.region,
          postal_code: data.postal_code,
          city: data.city,
          billing_address_same: data.billing_address_same,
          billing_address: data.billing_address,
          billing_address_complement: data.billing_address_complement,
          billing_region: data.billing_region,
          billing_postal_code: data.billing_postal_code,
          billing_city: data.billing_city,
          accounting_code: data.accounting_code,
          cni_identifier: data.cni_identifier,
          attached_file_path: data.attached_file_path,
          internal_note: data.internal_note,
          status: data.status,
          sms_notification: data.sms_notification,
          email_notification: data.email_notification,
          sms_marketing: data.sms_marketing,
          email_marketing: data.email_marketing,
        };

        console.log('🔍 Vérification des champs snake_case dans Supabase:');
        Object.entries(snakeCaseFields).forEach(([field, value]) => {
          const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
          console.log(`${status} ${field}: ${value}`);
        });
      }
    } else {
      console.log('⚠️ Objet Supabase non disponible dans la console');
    }

  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

// Exécuter le test
testClientData();

// Instructions pour l'utilisateur
console.log(`
📝 Instructions pour tester le formulaire client:

1. Créez un nouveau client avec le formulaire étendu
2. Remplissez tous les champs (région, code postal, ville, etc.)
3. Sauvegardez le client
4. Exécutez ce script dans la console du navigateur
5. Vérifiez que tous les champs sont bien enregistrés

Si des champs montrent ❌, cela signifie qu'ils ne sont pas enregistrés correctement.
`);
