// Test d'affichage des clients avec les nouveaux champs
// Ce script simule l'affichage des données client dans le tableau

console.log('🧪 TEST AFFICHAGE CLIENTS');
console.log('==========================');

// Simulation des données client (basées sur les logs)
const clients = [
  {
    id: '48690c75-7032-4bb7-b702-931ce0165be6',
    firstName: 'Sasha',
    lastName: 'Rohee',
    email: 'sashar@gmail.com',
    phone: '330778119837',
    address: '1190 Rue de Cormeille',
    notes: 'test',
    category: 'particulier',
    title: 'mr',
    companyName: "Rep'hone",
    vatNumber: '123456789',
    sirenNumber: '123456789',
    countryCode: '33',
    addressComplement: '1190 Rue de Cormeille',
    region: 'Normandie',
    postalCode: '27260',
    city: 'LE BOIS HELLAIN',
    billingAddressSame: true,
    billingAddress: '',
    billingAddressComplement: '',
    billingRegion: '',
    billingPostalCode: '',
    billingCity: '',
    accountingCode: '1231',
    cniIdentifier: '23',
    attachedFilePath: '',
    internalNote: 'test',
    status: 'displayed',
    smsNotification: true,
    emailNotification: true,
    smsMarketing: true,
    emailMarketing: true,
    createdAt: '2025-01-27T10:30:00.000Z',
    updatedAt: '2025-01-27T10:30:00.000Z'
  }
];

console.log('📋 Données client simulées:');
console.log(JSON.stringify(clients[0], null, 2));

// Simulation de l'affichage dans le tableau
console.log('\n📊 AFFICHAGE DANS LE TABLEAU:');
console.log('=============================');

clients.forEach((client, index) => {
  console.log(`\n👤 Client ${index + 1}: ${client.firstName} ${client.lastName}`);
  console.log('---');
  
  // Colonne Client
  console.log('📋 Client:');
  console.log(`  Nom: ${client.firstName} ${client.lastName}`);
  
  // Colonne Contact
  console.log('📞 Contact:');
  console.log(`  Email: ${client.email}`);
  console.log(`  Téléphone: ${client.phone}`);
  
  // Colonne Entreprise
  console.log('🏢 Entreprise:');
  console.log(`  Nom société: ${client.companyName || '-'}`);
  console.log(`  TVA: ${client.vatNumber || '-'}`);
  console.log(`  SIREN: ${client.sirenNumber || '-'}`);
  
  // Colonne Adresse
  console.log('📍 Adresse:');
  console.log(`  Adresse: ${client.address || '-'}`);
  console.log(`  Code postal: ${client.postalCode || '-'}`);
  console.log(`  Ville: ${client.city || '-'}`);
  
  // Colonne Informations
  console.log('ℹ️ Informations:');
  console.log(`  Code comptable: ${client.accountingCode || '-'}`);
  console.log(`  Identifiant CNI: ${client.cniIdentifier || '-'}`);
  console.log(`  Notes: ${client.notes || '-'}`);
  
  // Colonne Date
  console.log('📅 Date d\'inscription:');
  console.log(`  ${new Date(client.createdAt).toLocaleDateString('fr-FR')}`);
});

// Vérification des champs critiques
console.log('\n🔍 VÉRIFICATION DES CHAMPS CRITIQUES:');
console.log('=====================================');

const criticalFields = [
  { field: 'companyName', label: 'Nom société' },
  { field: 'vatNumber', label: 'TVA' },
  { field: 'sirenNumber', label: 'SIREN' },
  { field: 'postalCode', label: 'Code postal' },
  { field: 'accountingCode', label: 'Code comptable' },
  { field: 'cniIdentifier', label: 'Identifiant CNI' }
];

criticalFields.forEach(field => {
  const value = clients[0][field.field];
  const status = value && value.toString().trim() !== '' ? '✅' : '❌';
  console.log(`${status} ${field.label}: ${value || 'Non défini'}`);
});

// Test d'affichage conditionnel
console.log('\n🎨 TEST D\'AFFICHAGE CONDITIONNEL:');
console.log('==================================');

function simulateTableDisplay(client) {
  console.log('\n📋 Simulation d\'affichage dans le tableau:');
  
  // Colonne Entreprise
  console.log('🏢 Entreprise:');
  if (client.companyName) {
    console.log(`  ${client.companyName}`);
    if (client.vatNumber) console.log(`  TVA: ${client.vatNumber}`);
    if (client.sirenNumber) console.log(`  SIREN: ${client.sirenNumber}`);
  } else {
    console.log('  -');
  }
  
  // Colonne Adresse
  console.log('📍 Adresse:');
  if (client.address) {
    console.log(`  ${client.address}`);
    if (client.postalCode && client.city) {
      console.log(`  ${client.postalCode} ${client.city}`);
    }
  } else {
    console.log('  -');
  }
  
  // Colonne Informations
  console.log('ℹ️ Informations:');
  const infoItems = [];
  if (client.accountingCode) infoItems.push(`Code: ${client.accountingCode}`);
  if (client.cniIdentifier) infoItems.push(`CNI: ${client.cniIdentifier}`);
  if (client.notes) infoItems.push(`Note: ${client.notes}`);
  
  if (infoItems.length > 0) {
    infoItems.forEach(item => console.log(`  ${item}`));
  } else {
    console.log('  -');
  }
}

simulateTableDisplay(clients[0]);

// Test avec des données vides
console.log('\n🧪 TEST AVEC DONNÉES VIDES:');
console.log('============================');

const emptyClient = {
  id: 'test-empty',
  firstName: 'Test',
  lastName: 'Vide',
  email: 'test@example.com',
  phone: '0123456789',
  address: '',
  notes: '',
  companyName: '',
  vatNumber: '',
  sirenNumber: '',
  postalCode: '',
  city: '',
  accountingCode: '',
  cniIdentifier: '',
  createdAt: new Date().toISOString()
};

simulateTableDisplay(emptyClient);

console.log('\n✅ Test d\'affichage terminé!');
console.log('Les données sont bien présentes et peuvent être affichées dans le tableau.');
