// Script de test pour vérifier les données du formulaire client
// À exécuter dans la console du navigateur pendant l'édition d'un client

console.log('🧪 Test des données du formulaire client');

// Fonction pour tester la récupération des données client
function testClientDataRetrieval() {
  console.log('📋 Test de récupération des données client...');
  
  // Récupérer le store Zustand
  const store = window.__ZUSTAND_STORE__;
  if (!store) {
    console.log('❌ Store Zustand non trouvé');
    return;
  }

  const clients = store.getState().clients;
  console.log('📊 Clients dans le store:', clients.length);
  
  if (clients.length === 0) {
    console.log('❌ Aucun client trouvé dans le store');
    return;
  }

  // Prendre le premier client pour le test
  const testClient = clients[0];
  console.log('🔍 Client de test:', testClient);

  // Vérifier les champs problématiques
  const problematicFields = {
    // Informations personnelles et entreprise
    category: testClient.category,
    title: testClient.title,
    companyName: testClient.companyName,
    vatNumber: testClient.vatNumber,
    sirenNumber: testClient.sirenNumber,
    countryCode: testClient.countryCode,
    
    // Adresse détaillée
    addressComplement: testClient.addressComplement,
    region: testClient.region,
    postalCode: testClient.postalCode,
    city: testClient.city,
    
    // Adresse de facturation
    billingAddressSame: testClient.billingAddressSame,
    billingAddress: testClient.billingAddress,
    billingAddressComplement: testClient.billingAddressComplement,
    billingRegion: testClient.billingRegion,
    billingPostalCode: testClient.billingPostalCode,
    billingCity: testClient.billingCity,
    
    // Informations complémentaires
    accountingCode: testClient.accountingCode,
    cniIdentifier: testClient.cniIdentifier,
    attachedFilePath: testClient.attachedFilePath,
    internalNote: testClient.internalNote,
    
    // Préférences
    status: testClient.status,
    smsNotification: testClient.smsNotification,
    emailNotification: testClient.emailNotification,
    smsMarketing: testClient.smsMarketing,
    emailMarketing: testClient.emailMarketing,
  };

  console.log('🔍 Vérification des champs problématiques:');
  Object.entries(problematicFields).forEach(([field, value]) => {
    const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
    console.log(`${status} ${field}: ${value}`);
  });

  // Compter les champs vides
  const emptyFields = Object.entries(problematicFields)
    .filter(([field, value]) => value === undefined || value === null || value === '')
    .map(([field]) => field);

  console.log(`📊 Résumé: ${emptyFields.length} champs vides sur ${Object.keys(problematicFields).length}`);
  
  if (emptyFields.length > 0) {
    console.log('❌ Champs vides:', emptyFields.join(', '));
  } else {
    console.log('✅ Tous les champs sont remplis!');
  }
}

// Fonction pour tester la soumission du formulaire
function testFormSubmission() {
  console.log('📝 Test de soumission du formulaire...');
  
  // Vérifier si le formulaire est ouvert
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) {
    console.log('❌ Aucun formulaire client ouvert');
    return;
  }

  console.log('✅ Formulaire client détecté');

  // Récupérer les valeurs des champs du formulaire
  const formFields = {
    // Détails Client
    category: getFieldValue('category'),
    title: getFieldValue('title'),
    firstName: getFieldValue('firstName'),
    lastName: getFieldValue('lastName'),
    companyName: getFieldValue('companyName'),
    vatNumber: getFieldValue('vatNumber'),
    sirenNumber: getFieldValue('sirenNumber'),
    email: getFieldValue('email'),
    countryCode: getFieldValue('countryCode'),
    mobile: getFieldValue('mobile'),
    
    // Détails Adresse
    address: getFieldValue('address'),
    addressComplement: getFieldValue('addressComplement'),
    region: getFieldValue('region'),
    postalCode: getFieldValue('postalCode'),
    city: getFieldValue('city'),
    
    // Autres informations
    accountingCode: getFieldValue('accountingCode'),
    cniIdentifier: getFieldValue('cniIdentifier'),
    internalNote: getFieldValue('internalNote'),
  };

  console.log('📋 Valeurs du formulaire:');
  Object.entries(formFields).forEach(([field, value]) => {
    const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
    console.log(`${status} ${field}: ${value}`);
  });

  // Vérifier le bouton de soumission
  const submitButton = dialog.querySelector('button[type="submit"], button:contains("Modifier"), button:contains("Créer")');
  if (submitButton) {
    const isDisabled = submitButton.disabled;
    console.log(`🔘 Bouton de soumission: ${isDisabled ? '❌ Désactivé' : '✅ Activé'}`);
    
    if (isDisabled) {
      console.log('💡 Le bouton est désactivé - vérifiez la validation du formulaire');
    }
  }
}

// Fonction utilitaire pour récupérer la valeur d'un champ
function getFieldValue(fieldName) {
  // Essayer différents sélecteurs
  const selectors = [
    `input[name="${fieldName}"]`,
    `input[id="${fieldName}"]`,
    `select[name="${fieldName}"]`,
    `select[id="${fieldName}"]`,
    `textarea[name="${fieldName}"]`,
    `textarea[id="${fieldName}"]`,
    `[data-field="${fieldName}"]`
  ];

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      if (element.type === 'checkbox') {
        return element.checked;
      } else if (element.type === 'radio') {
        const checkedRadio = element.closest('div').querySelector('input[type="radio"]:checked');
        return checkedRadio ? checkedRadio.value : null;
      } else {
        return element.value;
      }
    }
  }

  return null;
}

// Fonction pour tester la connexion Supabase
async function testSupabaseConnection() {
  console.log('🔗 Test de connexion Supabase...');
  
  if (window.supabase) {
    try {
      const { data, error } = await window.supabase
        .from('clients')
        .select('*')
        .limit(1);
      
      if (error) {
        console.log('❌ Erreur Supabase:', error);
      } else {
        console.log('✅ Connexion Supabase réussie');
        console.log('📊 Données brutes Supabase:', data);
        
        if (data && data.length > 0) {
          const client = data[0];
          console.log('🔍 Exemple de client depuis Supabase:');
          console.log('- first_name:', client.first_name);
          console.log('- last_name:', client.last_name);
          console.log('- email:', client.email);
          console.log('- region:', client.region);
          console.log('- postal_code:', client.postal_code);
          console.log('- city:', client.city);
          console.log('- company_name:', client.company_name);
          console.log('- accounting_code:', client.accounting_code);
          console.log('- cni_identifier:', client.cni_identifier);
        }
      }
    } catch (error) {
      console.log('❌ Erreur lors du test Supabase:', error);
    }
  } else {
    console.log('❌ Objet Supabase non disponible');
  }
}

// Exécuter tous les tests
console.log('🚀 Démarrage des tests...');

// Test 1: Récupération des données
testClientDataRetrieval();

// Test 2: Formulaire ouvert
setTimeout(() => {
  testFormSubmission();
}, 1000);

// Test 3: Connexion Supabase
setTimeout(() => {
  testSupabaseConnection();
}, 2000);

// Instructions pour l'utilisateur
console.log(`
📝 Instructions pour tester le formulaire client:

1. Ouvrez le formulaire "Modifier le Client" ou "Nouveau Client"
2. Remplissez tous les champs (région, code postal, ville, etc.)
3. Exécutez ce script dans la console
4. Vérifiez les résultats pour identifier les problèmes

Si des champs montrent ❌, cela signifie qu'ils ne sont pas correctement récupérés ou transmis.
`);

// Fonction pour surveiller les changements de données
function watchDataChanges() {
  console.log('👀 Surveillance des changements de données...');
  
  const store = window.__ZUSTAND_STORE__;
  if (store) {
    let previousClients = store.getState().clients;
    
    setInterval(() => {
      const currentClients = store.getState().clients;
      if (currentClients.length !== previousClients.length) {
        console.log('🔄 Changement détecté dans les clients:', currentClients.length);
        previousClients = currentClients;
      }
    }, 2000);
  }
}

// Démarrer la surveillance
setTimeout(watchDataChanges, 3000);
