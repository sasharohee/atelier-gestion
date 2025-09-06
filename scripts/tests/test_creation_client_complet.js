// Test de création complète d'un client avec tous les champs
// Ce script simule la création d'un client avec tous les champs remplis

const testClientData = {
  // Détails Client
  category: 'entreprise',
  title: 'mr',
  firstName: 'Jean',
  lastName: 'Dupont',
  companyName: 'Entreprise Test SARL',
  vatNumber: 'FR12345678901',
  sirenNumber: '123456789',
  email: 'test.complet@example.com',
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
  internalNote: 'Client de test avec tous les champs remplis',
  status: 'displayed',
  smsNotification: true,
  emailNotification: true,
  smsMarketing: false,
  emailMarketing: true,
};

console.log('🧪 TEST DE CRÉATION COMPLÈTE DE CLIENT');
console.log('=====================================');
console.log('📋 Données de test:');
console.log(JSON.stringify(testClientData, null, 2));

// Simulation de la transformation des données
const transformedData = {
  first_name: testClientData.firstName,
  last_name: testClientData.lastName,
  email: testClientData.email,
  phone: testClientData.countryCode + testClientData.mobile,
  address: testClientData.address,
  notes: testClientData.internalNote,
  
  // Nouveaux champs pour les informations personnelles et entreprise
  category: testClientData.category,
  title: testClientData.title,
  company_name: testClientData.companyName,
  vat_number: testClientData.vatNumber,
  siren_number: testClientData.sirenNumber,
  country_code: testClientData.countryCode,
  
  // Nouveaux champs pour l'adresse détaillée
  address_complement: testClientData.addressComplement,
  region: testClientData.region,
  postal_code: testClientData.postalCode,
  city: testClientData.city,
  
  // Nouveaux champs pour l'adresse de facturation
  billing_address_same: testClientData.billingAddressSame,
  billing_address: testClientData.billingAddress,
  billing_address_complement: testClientData.billingAddressComplement,
  billing_region: testClientData.billingRegion,
  billing_postal_code: testClientData.billingPostalCode,
  billing_city: testClientData.billingCity,
  
  // Nouveaux champs pour les informations complémentaires
  accounting_code: testClientData.accountingCode,
  cni_identifier: testClientData.cniIdentifier,
  attached_file_path: testClientData.attachedFile ? testClientData.attachedFile.name : '',
  internal_note: testClientData.internalNote,
  
  // Nouveaux champs pour les préférences
  status: testClientData.status,
  sms_notification: testClientData.smsNotification,
  email_notification: testClientData.emailNotification,
  sms_marketing: testClientData.smsMarketing,
  email_marketing: testClientData.emailMarketing,
};

console.log('\n🔄 Données transformées pour Supabase:');
console.log(JSON.stringify(transformedData, null, 2));

// Vérification des champs critiques
const criticalFields = [
  'company_name',
  'vat_number', 
  'siren_number',
  'postal_code',
  'accounting_code',
  'cni_identifier'
];

console.log('\n🔍 Vérification des champs critiques:');
criticalFields.forEach(field => {
  const value = transformedData[field];
  const status = value && value.trim() !== '' ? '✅' : '❌';
  console.log(`${status} ${field}: "${value}"`);
});

console.log('\n📊 Résumé:');
const filledFields = criticalFields.filter(field => 
  transformedData[field] && transformedData[field].trim() !== ''
).length;

console.log(`Champs critiques remplis: ${filledFields}/${criticalFields.length}`);
console.log(`Taux de remplissage: ${(filledFields / criticalFields.length * 100).toFixed(1)}%`);

if (filledFields === criticalFields.length) {
  console.log('🎉 Tous les champs critiques sont remplis!');
} else {
  console.log('⚠️ Certains champs critiques sont vides.');
}
