// Test final de création de client
// Ce script simule le processus complet et vérifie tous les points critiques

console.log('🧪 TEST FINAL - CRÉATION COMPLÈTE DE CLIENT');
console.log('===========================================');

// Simulation des données du formulaire (comme si l'utilisateur les saisissait)
const formData = {
  // Détails Client
  category: 'entreprise',
  title: 'mr',
  firstName: 'Jean',
  lastName: 'Dupont',
  companyName: 'Entreprise Test SARL',
  vatNumber: 'FR12345678901',
  sirenNumber: '123456789',
  email: 'test.final@example.com',
  countryCode: '33',
  mobile: '123456789',
  
  // Détails Adresse
  address: '123 Rue de Test',
  addressComplement: 'Bâtiment A, Étage 2',
  region: 'Île-de-France',
  postalCode: '75001',
  city: 'Paris',
  billingAddressSame: false,
  billingAddress: '456 Avenue de Facturation',
  billingAddressComplement: 'Bureau 101',
  billingRegion: 'Île-de-France',
  billingPostalCode: '75002',
  billingCity: 'Paris',
  
  // Autres informations
  accountingCode: 'CLI001',
  cniIdentifier: 'CNI123456789',
  attachedFile: null,
  internalNote: 'Client de test final',
  status: 'displayed',
  smsNotification: true,
  emailNotification: true,
  smsMarketing: false,
  emailMarketing: true,
};

console.log('📋 1. Données du formulaire (formData):');
console.log(JSON.stringify(formData, null, 2));

// Simulation de la transformation dans handleCreateNewClient (Clients.tsx)
const clientData = {
  firstName: formData.firstName || '',
  lastName: formData.lastName || '',
  email: formData.email || '',
  phone: (formData.countryCode || '33') + (formData.mobile || ''),
  address: formData.address || '',
  notes: formData.internalNote || '',
  
  // Nouveaux champs pour les informations personnelles et entreprise
  category: formData.category || 'particulier',
  title: formData.title || 'mr',
  companyName: formData.companyName || '',
  vatNumber: formData.vatNumber || '',
  sirenNumber: formData.sirenNumber || '',
  countryCode: formData.countryCode || '33',
  
  // Nouveaux champs pour l'adresse détaillée
  addressComplement: formData.addressComplement || '',
  region: formData.region || '',
  postalCode: formData.postalCode || '',
  city: formData.city || '',
  
  // Nouveaux champs pour l'adresse de facturation
  billingAddressSame: formData.billingAddressSame !== undefined ? formData.billingAddressSame : true,
  billingAddress: formData.billingAddress || '',
  billingAddressComplement: formData.billingAddressComplement || '',
  billingRegion: formData.billingRegion || '',
  billingPostalCode: formData.billingPostalCode || '',
  billingCity: formData.billingCity || '',
  
  // Nouveaux champs pour les informations complémentaires
  accountingCode: formData.accountingCode || '',
  cniIdentifier: formData.cniIdentifier || '',
  attachedFilePath: formData.attachedFile ? formData.attachedFile.name : '',
  internalNote: formData.internalNote || '',
  
  // Nouveaux champs pour les préférences
  status: formData.status || 'displayed',
  smsNotification: formData.smsNotification !== undefined ? formData.smsNotification : true,
  emailNotification: formData.emailNotification !== undefined ? formData.emailNotification : true,
  smsMarketing: formData.smsMarketing !== undefined ? formData.smsMarketing : true,
  emailMarketing: formData.emailMarketing !== undefined ? formData.emailMarketing : true,
};

console.log('\n📋 2. Données transformées (clientData):');
console.log(JSON.stringify(clientData, null, 2));

// Simulation de la transformation dans clientService.create (supabaseService.ts)
const supabaseData = {
  first_name: clientData.firstName || '',
  last_name: clientData.lastName || '',
  email: clientData.email || '',
  phone: clientData.phone || '',
  address: clientData.address || '',
  notes: clientData.notes || '',
  
  // Nouveaux champs pour les informations personnelles et entreprise
  category: clientData.category || 'particulier',
  title: clientData.title || 'mr',
  company_name: clientData.companyName || '',
  vat_number: clientData.vatNumber || '',
  siren_number: clientData.sirenNumber || '',
  country_code: clientData.countryCode || '33',
  
  // Nouveaux champs pour l'adresse détaillée
  address_complement: clientData.addressComplement || '',
  region: clientData.region || '',
  postal_code: clientData.postalCode || '',
  city: clientData.city || '',
  
  // Nouveaux champs pour l'adresse de facturation
  billing_address_same: clientData.billingAddressSame !== undefined ? clientData.billingAddressSame : true,
  billing_address: clientData.billingAddress || '',
  billing_address_complement: clientData.billingAddressComplement || '',
  billing_region: clientData.billingRegion || '',
  billing_postal_code: clientData.billingPostalCode || '',
  billing_city: clientData.billingCity || '',
  
  // Nouveaux champs pour les informations complémentaires
  accounting_code: clientData.accountingCode || '',
  cni_identifier: clientData.cniIdentifier || '',
  attached_file_path: clientData.attachedFilePath || '',
  internal_note: clientData.internalNote || '',
  
  // Nouveaux champs pour les préférences
  status: clientData.status || 'displayed',
  sms_notification: clientData.smsNotification !== undefined ? clientData.smsNotification : true,
  email_notification: clientData.emailNotification !== undefined ? clientData.emailNotification : true,
  sms_marketing: clientData.smsMarketing !== undefined ? clientData.smsMarketing : true,
  email_marketing: clientData.emailMarketing !== undefined ? clientData.emailMarketing : true,
};

console.log('\n📋 3. Données pour Supabase (supabaseData):');
console.log(JSON.stringify(supabaseData, null, 2));

// Vérification des champs critiques
const criticalFields = [
  { formField: 'companyName', clientField: 'companyName', supabaseField: 'company_name', label: 'Nom société' },
  { formField: 'vatNumber', clientField: 'vatNumber', supabaseField: 'vat_number', label: 'TVA' },
  { formField: 'sirenNumber', clientField: 'sirenNumber', supabaseField: 'siren_number', label: 'SIREN' },
  { formField: 'postalCode', clientField: 'postalCode', supabaseField: 'postal_code', label: 'Code Postal' },
  { formField: 'accountingCode', clientField: 'accountingCode', supabaseField: 'accounting_code', label: 'Code Comptable' },
  { formField: 'cniIdentifier', clientField: 'cniIdentifier', supabaseField: 'cni_identifier', label: 'Identifiant CNI' }
];

console.log('\n🔍 4. Vérification des champs critiques:');
console.log('Champ\t\t\tFormData\tClientData\tSupabaseData\tStatus');
console.log('-----\t\t\t--------\t----------\t-------------\t------');

criticalFields.forEach(field => {
  const formValue = formData[field.formField] || '';
  const clientValue = clientData[field.clientField] || '';
  const supabaseValue = supabaseData[field.supabaseField] || '';
  
  const formStatus = formValue.trim() !== '' ? '✅' : '❌';
  const clientStatus = clientValue.trim() !== '' ? '✅' : '❌';
  const supabaseStatus = supabaseValue.trim() !== '' ? '✅' : '❌';
  
  console.log(`${field.label.padEnd(20)}\t${formValue.padEnd(10)}\t${clientValue.padEnd(10)}\t${supabaseValue.padEnd(13)}\t${formStatus}${clientStatus}${supabaseStatus}`);
});

// Résumé final
console.log('\n📊 5. Résumé final:');
const formFilled = criticalFields.filter(f => formData[f.formField] && formData[f.formField].trim() !== '').length;
const clientFilled = criticalFields.filter(f => clientData[f.clientField] && clientData[f.clientField].trim() !== '').length;
const supabaseFilled = criticalFields.filter(f => supabaseData[f.supabaseField] && supabaseData[f.supabaseField].trim() !== '').length;

console.log(`FormData: ${formFilled}/${criticalFields.length} champs remplis`);
console.log(`ClientData: ${clientFilled}/${criticalFields.length} champs remplis`);
console.log(`SupabaseData: ${supabaseFilled}/${criticalFields.length} champs remplis`);

if (formFilled === criticalFields.length && clientFilled === criticalFields.length && supabaseFilled === criticalFields.length) {
  console.log('\n🎉 SUCCÈS: Toutes les étapes sont correctes!');
  console.log('✅ Le formulaire devrait fonctionner correctement');
  console.log('✅ Tous les champs critiques sont transmis correctement');
  console.log('✅ Les données sont prêtes pour Supabase');
} else {
  console.log('\n❌ ÉCHEC: Problème détecté dans une ou plusieurs étapes');
  
  if (formFilled < criticalFields.length) {
    console.log('❌ Problème: Données manquantes dans le formulaire');
  }
  if (clientFilled < formFilled) {
    console.log('❌ Problème: Données perdues lors de la transformation clientData');
  }
  if (supabaseFilled < clientFilled) {
    console.log('❌ Problème: Données perdues lors de la transformation supabaseData');
  }
}

// Instructions pour le test manuel
console.log('\n📋 6. Instructions pour le test manuel:');
console.log('1. Ouvrir l\'application dans le navigateur');
console.log('2. Aller dans la page Clients');
console.log('3. Cliquer sur "Nouveau Client"');
console.log('4. Remplir tous les champs avec les valeurs de test:');
console.log('   - Nom société: Entreprise Test SARL');
console.log('   - TVA: FR12345678901');
console.log('   - SIREN: 123456789');
console.log('   - Code Postal: 75001');
console.log('   - Code comptable: CLI001');
console.log('   - Identifiant CNI: CNI123456789');
console.log('5. Cliquer sur "Créer"');
console.log('6. Vérifier dans la console les logs de debug');
console.log('7. Vérifier que le client est créé avec tous les champs');

console.log('\n🔧 Si le problème persiste:');
console.log('- Vérifiez les erreurs dans la console du navigateur');
console.log('- Exécutez le script correction_formulaire_client.sql dans Supabase');
console.log('- Consultez le guide GUIDE_DEPANNAGE_CHAMPS_CLIENT.md');
