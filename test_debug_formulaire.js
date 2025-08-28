// SCRIPT DE DEBUG POUR LE FORMULAIRE CLIENT
// Copiez ce code dans la console du navigateur (F12) sur la page du formulaire client

console.log('🔍 DEBUG FORMULAIRE CLIENT - DÉMARRAGE');

// ========================================
// ÉTAPE 1: MONITORER LES APPELS SUPABASE
// ========================================

// Intercepter les appels Supabase
const originalFetch = window.fetch;
window.fetch = function(...args) {
  const url = args[0];
  const options = args[1];
  
  if (url && url.includes('supabase') && url.includes('clients')) {
    console.log('🚀 APPEL SUPABASE DÉTECTÉ:');
    console.log('URL:', url);
    console.log('Méthode:', options?.method);
    console.log('Body:', options?.body);
    
    if (options?.body) {
      try {
        const bodyData = JSON.parse(options.body);
        console.log('📋 DONNÉES ENVOYÉES:', bodyData);
        
        // Vérifier les champs problématiques
        const champsProblematiques = [
          'accounting_code', 'cni_identifier', 'attached_file_path', 'internal_note',
          'region', 'postal_code', 'city', 'company_name', 'vat_number', 'siren_number'
        ];
        
        champsProblematiques.forEach(champ => {
          if (bodyData[champ] === undefined || bodyData[champ] === null || bodyData[champ] === '') {
            console.log(`❌ CHAMP VIDE: ${champ} = "${bodyData[champ]}"`);
          } else {
            console.log(`✅ CHAMP REMPLI: ${champ} = "${bodyData[champ]}"`);
          }
        });
      } catch (e) {
        console.log('❌ Erreur parsing body:', e);
      }
    }
  }
  
  return originalFetch.apply(this, args);
};

// ========================================
// ÉTAPE 2: INSPECTER LE FORMULAIRE ACTUEL
// ========================================

function inspecterFormulaire() {
  console.log('🔍 INSPECTION DU FORMULAIRE:');
  
  // Trouver tous les champs de saisie
  const inputs = document.querySelectorAll('input, textarea, select');
  console.log(`📝 Nombre total de champs: ${inputs.length}`);
  
  inputs.forEach((input, index) => {
    const name = input.name || input.id || `input_${index}`;
    const value = input.value;
    const type = input.type;
    
    console.log(`${index + 1}. ${name} (${type}) = "${value}"`);
    
    // Vérifier les champs problématiques
    const champsProblematiques = [
      'accountingCode', 'cniIdentifier', 'attachedFilePath', 'internalNote',
      'region', 'postalCode', 'city', 'companyName', 'vatNumber', 'sirenNumber'
    ];
    
    champsProblematiques.forEach(champ => {
      if (name.toLowerCase().includes(champ.toLowerCase())) {
        if (!value || value.trim() === '') {
          console.log(`❌ CHAMP VIDE DÉTECTÉ: ${name}`);
        } else {
          console.log(`✅ CHAMP REMPLI: ${name} = "${value}"`);
        }
      }
    });
  });
}

// ========================================
// ÉTAPE 3: TESTER LA SOUMISSION MANUELLE
// ========================================

function testerSoumission() {
  console.log('🧪 TEST DE SOUMISSION MANUELLE:');
  
  // Créer des données de test
  const donneesTest = {
    firstName: 'Test',
    lastName: 'Debug',
    email: 'test.debug@example.com',
    phone: '0123456789',
    address: '123 Rue Test',
    
    // Champs problématiques
    accountingCode: 'TEST001',
    cniIdentifier: '123456789',
    attachedFilePath: '/test/file.pdf',
    internalNote: 'Note de test debug',
    region: 'Île-de-France',
    postalCode: '75001',
    city: 'Paris',
    companyName: 'Test SARL',
    vatNumber: 'FR12345678901',
    sirenNumber: '123456789',
    
    // Autres champs
    category: 'particulier',
    title: 'mr',
    countryCode: '33',
    addressComplement: 'Bâtiment A',
    billingAddressSame: true,
    status: 'displayed',
    smsNotification: true,
    emailNotification: true,
    smsMarketing: true,
    emailMarketing: true
  };
  
  console.log('📋 DONNÉES DE TEST:', donneesTest);
  
  // Simuler l'appel au service
  if (window.supabase) {
    console.log('✅ Supabase disponible, test d\'insertion...');
    
    const clientData = {
      first_name: donneesTest.firstName,
      last_name: donneesTest.lastName,
      email: donneesTest.email,
      phone: donneesTest.phone,
      address: donneesTest.address,
      accounting_code: donneesTest.accountingCode,
      cni_identifier: donneesTest.cniIdentifier,
      attached_file_path: donneesTest.attachedFilePath,
      internal_note: donneesTest.internalNote,
      region: donneesTest.region,
      postal_code: donneesTest.postalCode,
      city: donneesTest.city,
      company_name: donneesTest.companyName,
      vat_number: donneesTest.vatNumber,
      siren_number: donneesTest.sirenNumber,
      category: donneesTest.category,
      title: donneesTest.title,
      country_code: donneesTest.countryCode,
      address_complement: donneesTest.addressComplement,
      billing_address_same: donneesTest.billingAddressSame,
      status: donneesTest.status,
      sms_notification: donneesTest.smsNotification,
      email_notification: donneesTest.emailNotification,
      sms_marketing: donneesTest.smsMarketing,
      email_marketing: donneesTest.emailMarketing,
      user_id: '00000000-0000-0000-0000-000000000000',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    console.log('📤 DONNÉES À ENVOYER:', clientData);
    
    // Test d'insertion directe
    window.supabase
      .from('clients')
      .insert([clientData])
      .select()
      .then(({ data, error }) => {
        if (error) {
          console.log('❌ ERREUR INSERTION:', error);
        } else {
          console.log('✅ INSERTION RÉUSSIE:', data);
        }
      });
  } else {
    console.log('❌ Supabase non disponible');
  }
}

// ========================================
// ÉTAPE 4: VÉRIFIER LE STORE ZUSTAND
// ========================================

function verifierStore() {
  console.log('🏪 VÉRIFICATION DU STORE ZUSTAND:');
  
  // Vérifier si le store est disponible
  if (window.useAppStore) {
    const store = window.useAppStore.getState();
    console.log('📊 ÉTAT DU STORE:', store);
    
    if (store.clients) {
      console.log('👥 CLIENTS DANS LE STORE:', store.clients.length);
      store.clients.forEach((client, index) => {
        console.log(`Client ${index + 1}:`, {
          id: client.id,
          name: `${client.firstName} ${client.lastName}`,
          accountingCode: client.accountingCode,
          cniIdentifier: client.cniIdentifier,
          region: client.region,
          city: client.city
        });
      });
    }
    
    if (store.createClient) {
      console.log('✅ Fonction createClient disponible');
    }
    
    if (store.updateClient) {
      console.log('✅ Fonction updateClient disponible');
    }
  } else {
    console.log('❌ Store Zustand non disponible');
  }
}

// ========================================
// ÉTAPE 5: FONCTIONS UTILITAIRES
// ========================================

function remplirFormulaireTest() {
  console.log('🖊️ REMPLISSAGE AUTOMATIQUE DU FORMULAIRE:');
  
  const champs = {
    'firstName': 'Test',
    'lastName': 'Debug',
    'email': 'test.debug@example.com',
    'phone': '0123456789',
    'address': '123 Rue Test',
    'accountingCode': 'TEST001',
    'cniIdentifier': '123456789',
    'internalNote': 'Note de test automatique',
    'region': 'Île-de-France',
    'postalCode': '75001',
    'city': 'Paris',
    'companyName': 'Test SARL',
    'vatNumber': 'FR12345678901',
    'sirenNumber': '123456789'
  };
  
  Object.entries(champs).forEach(([name, value]) => {
    const input = document.querySelector(`[name="${name}"], [id="${name}"]`);
    if (input) {
      input.value = value;
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));
      console.log(`✅ Rempli: ${name} = "${value}"`);
    } else {
      console.log(`❌ Champ non trouvé: ${name}`);
    }
  });
}

// ========================================
// EXÉCUTION AUTOMATIQUE
// ========================================

console.log('🚀 DÉMARRAGE DU DEBUG...');

// Attendre que la page soit chargée
setTimeout(() => {
  console.log('📋 === RAPPORT DE DEBUG ===');
  inspecterFormulaire();
  verifierStore();
  
  console.log('💡 COMMANDES DISPONIBLES:');
  console.log('- inspecterFormulaire() : Inspecter le formulaire');
  console.log('- verifierStore() : Vérifier le store Zustand');
  console.log('- testerSoumission() : Tester la soumission manuelle');
  console.log('- remplirFormulaireTest() : Remplir le formulaire automatiquement');
  
  console.log('🔍 DEBUG TERMINÉ - Surveillez les appels Supabase ci-dessus');
}, 1000);
