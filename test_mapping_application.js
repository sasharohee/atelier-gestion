// Script de test pour vérifier le mapping des données dans l'application
// À exécuter dans la console du navigateur pendant l'utilisation du formulaire client

console.log('🔍 Test du mapping des données dans l\'application');

// Fonction pour surveiller les appels à Supabase
function monitorSupabaseCalls() {
  console.log('👀 Surveillance des appels Supabase...');
  
  // Intercepter les appels à Supabase
  const originalSupabase = window.supabase;
  if (originalSupabase) {
    const originalFrom = originalSupabase.from;
    
    originalSupabase.from = function(tableName) {
      const table = originalFrom.call(this, tableName);
      
      // Intercepter les méthodes
      const originalInsert = table.insert;
      const originalUpdate = table.update;
      const originalSelect = table.select;
      
      table.insert = function(data) {
        console.log('📝 INSERT appelé sur', tableName, 'avec données:', data);
        return originalInsert.call(this, data);
      };
      
      table.update = function(data) {
        console.log('🔄 UPDATE appelé sur', tableName, 'avec données:', data);
        return originalUpdate.call(this, data);
      };
      
      table.select = function(columns) {
        console.log('📋 SELECT appelé sur', tableName, 'avec colonnes:', columns);
        return originalSelect.call(this, columns);
      };
      
      return table;
    };
    
    console.log('✅ Surveillance Supabase activée');
  } else {
    console.log('❌ Objet Supabase non trouvé');
  }
}

// Fonction pour tester le store Zustand
function testZustandStore() {
  console.log('📊 Test du store Zustand...');
  
  const store = window.__ZUSTAND_STORE__;
  if (!store) {
    console.log('❌ Store Zustand non trouvé');
    return;
  }

  const state = store.getState();
  console.log('📋 État actuel du store:', state);
  
  // Vérifier les fonctions du store
  if (state.addClient) {
    console.log('✅ Fonction addClient disponible');
  } else {
    console.log('❌ Fonction addClient manquante');
  }
  
  if (state.updateClient) {
    console.log('✅ Fonction updateClient disponible');
  } else {
    console.log('❌ Fonction updateClient manquante');
  }
  
  if (state.clients) {
    console.log('✅ Liste des clients disponible:', state.clients.length, 'clients');
  } else {
    console.log('❌ Liste des clients manquante');
  }
}

// Fonction pour tester le formulaire client
function testClientForm() {
  console.log('📝 Test du formulaire client...');
  
  // Vérifier si le formulaire est ouvert
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) {
    console.log('❌ Aucun formulaire client ouvert');
    return;
  }

  console.log('✅ Formulaire client détecté');

  // Récupérer tous les champs du formulaire
  const formFields = {
    // Détails Client
    category: getFormFieldValue('category'),
    title: getFormFieldValue('title'),
    firstName: getFormFieldValue('firstName'),
    lastName: getFormFieldValue('lastName'),
    companyName: getFormFieldValue('companyName'),
    vatNumber: getFormFieldValue('vatNumber'),
    sirenNumber: getFormFieldValue('sirenNumber'),
    email: getFormFieldValue('email'),
    countryCode: getFormFieldValue('countryCode'),
    mobile: getFormFieldValue('mobile'),
    
    // Détails Adresse
    address: getFormFieldValue('address'),
    addressComplement: getFormFieldValue('addressComplement'),
    region: getFormFieldValue('region'),
    postalCode: getFormFieldValue('postalCode'),
    city: getFormFieldValue('city'),
    
    // Autres informations
    accountingCode: getFormFieldValue('accountingCode'),
    cniIdentifier: getFormFieldValue('cniIdentifier'),
    internalNote: getFormFieldValue('internalNote'),
  };

  console.log('📋 Valeurs actuelles du formulaire:');
  Object.entries(formFields).forEach(([field, value]) => {
    const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
    console.log(`${status} ${field}: ${value}`);
  });

  // Vérifier les champs problématiques spécifiquement
  const problematicFields = ['region', 'postalCode', 'city', 'accountingCode', 'cniIdentifier', 'companyName', 'sirenNumber', 'vatNumber'];
  const emptyProblematicFields = problematicFields.filter(field => !formFields[field] || formFields[field] === '');
  
  if (emptyProblematicFields.length > 0) {
    console.log('❌ Champs problématiques vides:', emptyProblematicFields);
  } else {
    console.log('✅ Tous les champs problématiques sont remplis');
  }
}

// Fonction utilitaire pour récupérer la valeur d'un champ
function getFormFieldValue(fieldName) {
  // Essayer différents sélecteurs
  const selectors = [
    `input[name="${fieldName}"]`,
    `input[id="${fieldName}"]`,
    `select[name="${fieldName}"]`,
    `select[id="${fieldName}"]`,
    `textarea[name="${fieldName}"]`,
    `textarea[id="${fieldName}"]`,
    `[data-field="${fieldName}"]`,
    `[data-testid="${fieldName}"]`
  ];

  for (const selector of selectors) {
    const element = document.querySelector(selector);
    if (element) {
      if (element.type === 'checkbox') {
        return element.checked;
      } else if (element.type === 'radio') {
        const checkedRadio = element.closest('div')?.querySelector('input[type="radio"]:checked');
        return checkedRadio ? checkedRadio.value : null;
      } else {
        return element.value;
      }
    }
  }

  return null;
}

// Fonction pour simuler la soumission du formulaire
function simulateFormSubmission() {
  console.log('🚀 Simulation de soumission du formulaire...');
  
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) {
    console.log('❌ Aucun formulaire ouvert');
    return;
  }

  // Récupérer le bouton de soumission
  const submitButton = dialog.querySelector('button[type="submit"], button:contains("Modifier"), button:contains("Créer")');
  if (submitButton) {
    console.log('🔘 Bouton de soumission trouvé:', submitButton.textContent);
    console.log('🔘 Bouton désactivé:', submitButton.disabled);
    
    if (!submitButton.disabled) {
      console.log('💡 Le bouton est activé - prêt pour la soumission');
    } else {
      console.log('⚠️ Le bouton est désactivé - vérifiez la validation du formulaire');
    }
  } else {
    console.log('❌ Bouton de soumission non trouvé');
  }
}

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
        
        // Analyser le dernier client ajouté
        if (currentClients.length > previousClients.length) {
          const newClient = currentClients[0]; // Le plus récent
          console.log('📋 Nouveau client ajouté:', newClient);
          
          // Vérifier les champs problématiques
          const problematicFields = ['region', 'postalCode', 'city', 'accountingCode', 'cniIdentifier', 'companyName', 'sirenNumber', 'vatNumber'];
          problematicFields.forEach(field => {
            const value = newClient[field];
            const status = value !== undefined && value !== null && value !== '' ? '✅' : '❌';
            console.log(`${status} ${field}: ${value}`);
          });
        }
        
        previousClients = currentClients;
      }
    }, 1000);
  }
}

// Fonction pour tester la validation du formulaire
function testFormValidation() {
  console.log('✅ Test de validation du formulaire...');
  
  const dialog = document.querySelector('[role="dialog"]');
  if (!dialog) {
    console.log('❌ Aucun formulaire ouvert');
    return;
  }

  // Vérifier les champs requis
  const requiredFields = dialog.querySelectorAll('input[required], select[required], textarea[required]');
  console.log('📋 Champs requis trouvés:', requiredFields.length);
  
  requiredFields.forEach((field, index) => {
    const isValid = field.checkValidity();
    const status = isValid ? '✅' : '❌';
    console.log(`${status} Champ requis ${index + 1}: ${field.name || field.id} - Valide: ${isValid}`);
  });

  // Vérifier les messages d'erreur
  const errorMessages = dialog.querySelectorAll('.Mui-error, [role="alert"], .error-message');
  if (errorMessages.length > 0) {
    console.log('❌ Messages d\'erreur trouvés:', errorMessages.length);
    errorMessages.forEach((error, index) => {
      console.log(`   Erreur ${index + 1}: ${error.textContent}`);
    });
  } else {
    console.log('✅ Aucun message d\'erreur trouvé');
  }
}

// Exécuter tous les tests
console.log('🚀 Démarrage des tests de mapping...');

// Test 1: Store Zustand
testZustandStore();

// Test 2: Surveillance Supabase
monitorSupabaseCalls();

// Test 3: Formulaire client
setTimeout(() => {
  testClientForm();
}, 1000);

// Test 4: Validation du formulaire
setTimeout(() => {
  testFormValidation();
}, 1500);

// Test 5: Simulation de soumission
setTimeout(() => {
  simulateFormSubmission();
}, 2000);

// Test 6: Surveillance des changements
setTimeout(() => {
  watchDataChanges();
}, 2500);

// Instructions pour l'utilisateur
console.log(`
📝 Instructions pour tester le mapping:

1. Ouvrez le formulaire "Nouveau Client" ou "Modifier le Client"
2. Remplissez tous les champs (région, code postal, ville, etc.)
3. Ce script va surveiller:
   - Les appels à Supabase
   - Les changements dans le store
   - La validation du formulaire
   - Les données transmises

4. Cliquez sur "Créer" ou "Modifier" et observez les logs
5. Vérifiez que toutes les données sont bien transmises

Si des champs montrent ❌, cela signifie qu'ils ne sont pas correctement mappés.
`);

// Fonction pour afficher les données en temps réel
function showRealTimeData() {
  const store = window.__ZUSTAND_STORE__;
  if (store) {
    setInterval(() => {
      const clients = store.getState().clients;
      if (clients.length > 0) {
        const lastClient = clients[0];
        console.log('📊 Dernier client en temps réel:', {
          id: lastClient.id,
          firstName: lastClient.firstName,
          lastName: lastClient.lastName,
          email: lastClient.email,
          region: lastClient.region,
          postalCode: lastClient.postalCode,
          city: lastClient.city,
          accountingCode: lastClient.accountingCode,
          cniIdentifier: lastClient.cniIdentifier,
          companyName: lastClient.companyName,
          sirenNumber: lastClient.sirenNumber,
          vatNumber: lastClient.vatNumber
        });
      }
    }, 5000);
  }
}

// Démarrer l'affichage en temps réel
setTimeout(showRealTimeData, 3000);
