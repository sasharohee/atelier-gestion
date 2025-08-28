// Debug de la transformation des clients
// Ce script simule exactement ce qui se passe dans le service

console.log('🔍 DEBUG TRANSFORMATION CLIENTS');
console.log('==============================');

// Simulation des données brutes de Supabase (basées sur les logs)
const rawSupabaseData = [
  {
    id: '48690c75-7032-4bb7-b702-931ce0165be6',
    first_name: 'Sasha',
    last_name: 'Rohee',
    email: 'sashar@gmail.com',
    phone: '330778119837',
    address: '1190 Rue de Cormeille',
    notes: 'test',
    category: 'particulier',
    title: 'mr',
    company_name: "Rep'hone",
    vat_number: '123456789',
    siren_number: '123456789',
    country_code: '33',
    address_complement: '1190 Rue de Cormeille',
    region: 'Normandie',
    postal_code: '27260',
    city: 'LE BOIS HELLAIN',
    billing_address_same: true,
    billing_address: '',
    billing_address_complement: '',
    billing_region: '',
    billing_postal_code: '',
    billing_city: '',
    accounting_code: '1231',
    cni_identifier: '23',
    attached_file_path: '',
    internal_note: 'test',
    status: 'displayed',
    sms_notification: true,
    email_notification: true,
    sms_marketing: true,
    email_marketing: true,
    user_id: 'e454cc8c-3e40-4f72-bf26-4f6f43e78d0b',
    created_at: '2025-01-27T10:30:00.000Z',
    updated_at: '2025-01-27T10:30:00.000Z'
  }
];

console.log('📋 1. Données brutes de Supabase:');
console.log(JSON.stringify(rawSupabaseData, null, 2));

// Simulation de la transformation (copie exacte du code du service)
const convertedData = rawSupabaseData.map(client => ({
  id: client.id,
  firstName: client.first_name,
  lastName: client.last_name,
  email: client.email,
  phone: client.phone,
  address: client.address,
  notes: client.notes,
  
  // Nouveaux champs pour les informations personnelles et entreprise
  category: client.category,
  title: client.title,
  companyName: client.company_name,
  vatNumber: client.vat_number,
  sirenNumber: client.siren_number,
  countryCode: client.country_code,
  
  // Nouveaux champs pour l'adresse détaillée
  addressComplement: client.address_complement,
  region: client.region,
  postalCode: client.postal_code,
  city: client.city,
  
  // Nouveaux champs pour l'adresse de facturation
  billingAddressSame: client.billing_address_same,
  billingAddress: client.billing_address,
  billingAddressComplement: client.billing_address_complement,
  billingRegion: client.billing_region,
  billingPostalCode: client.billing_postal_code,
  billingCity: client.billing_city,
  
  // Nouveaux champs pour les informations complémentaires
  accountingCode: client.accounting_code,
  cniIdentifier: client.cni_identifier,
  attachedFilePath: client.attached_file_path,
  internalNote: client.internal_note,
  
  // Nouveaux champs pour les préférences
  status: client.status,
  smsNotification: client.sms_notification,
  emailNotification: client.email_notification,
  smsMarketing: client.sms_marketing,
  emailMarketing: client.email_marketing,
  
  createdAt: client.created_at,
  updatedAt: client.updated_at
}));

console.log('\n📋 2. Données transformées:');
console.log(JSON.stringify(convertedData, null, 2));

// Vérification des champs critiques
const criticalFields = [
  { rawField: 'company_name', transformedField: 'companyName', label: 'Nom société' },
  { rawField: 'vat_number', transformedField: 'vatNumber', label: 'TVA' },
  { rawField: 'siren_number', transformedField: 'sirenNumber', label: 'SIREN' },
  { rawField: 'postal_code', transformedField: 'postalCode', label: 'Code Postal' },
  { rawField: 'accounting_code', transformedField: 'accountingCode', label: 'Code Comptable' },
  { rawField: 'cni_identifier', transformedField: 'cniIdentifier', label: 'Identifiant CNI' }
];

console.log('\n🔍 3. Vérification des champs critiques:');
console.log('Champ\t\t\tRaw Value\t\tTransformed Value\tStatus');
console.log('-----\t\t\t---------\t\t-----------------\t------');

criticalFields.forEach(field => {
  const rawValue = rawSupabaseData[0][field.rawField];
  const transformedValue = convertedData[0][field.transformedField];
  
  const rawStatus = rawValue && rawValue.trim() !== '' ? '✅' : '❌';
  const transformedStatus = transformedValue && transformedValue.trim() !== '' ? '✅' : '❌';
  
  console.log(`${field.label.padEnd(20)}\t${(rawValue || '').padEnd(15)}\t${(transformedValue || '').padEnd(17)}\t${rawStatus}${transformedStatus}`);
});

// Vérification des types de données
console.log('\n🔍 4. Vérification des types de données:');
criticalFields.forEach(field => {
  const rawValue = rawSupabaseData[0][field.rawField];
  const transformedValue = convertedData[0][field.transformedField];
  
  console.log(`${field.label}:`);
  console.log(`  Raw: ${rawValue} (${typeof rawValue})`);
  console.log(`  Transformed: ${transformedValue} (${typeof transformedValue})`);
  console.log(`  Match: ${rawValue === transformedValue ? '✅' : '❌'}`);
});

// Test avec des valeurs undefined/null
console.log('\n🔍 5. Test avec des valeurs problématiques:');
const testCases = [
  { company_name: null, vat_number: undefined, siren_number: '', postal_code: '   ', accounting_code: 'test', cni_identifier: '123' },
  { company_name: 'Test SARL', vat_number: 'FR12345678901', siren_number: '123456789', postal_code: '75001', accounting_code: 'CLI001', cni_identifier: 'CNI123456789' }
];

testCases.forEach((testCase, index) => {
  console.log(`\nTest ${index + 1}:`);
  
  const transformed = {
    companyName: testCase.company_name,
    vatNumber: testCase.vat_number,
    sirenNumber: testCase.siren_number,
    postalCode: testCase.postal_code,
    accountingCode: testCase.accounting_code,
    cniIdentifier: testCase.cni_identifier
  };
  
  criticalFields.forEach(field => {
    const value = transformed[field.transformedField];
    const status = value && value.toString().trim() !== '' ? '✅' : '❌';
    console.log(`  ${field.label}: ${value} ${status}`);
  });
});

// Résumé
console.log('\n📊 6. Résumé:');
const rawFilled = criticalFields.filter(f => {
  const value = rawSupabaseData[0][f.rawField];
  return value && value.toString().trim() !== '';
}).length;

const transformedFilled = criticalFields.filter(f => {
  const value = convertedData[0][f.transformedField];
  return value && value.toString().trim() !== '';
}).length;

console.log(`Champs remplis dans les données brutes: ${rawFilled}/${criticalFields.length}`);
console.log(`Champs remplis après transformation: ${transformedFilled}/${criticalFields.length}`);

if (rawFilled === transformedFilled) {
  console.log('✅ La transformation fonctionne correctement');
} else {
  console.log('❌ Problème dans la transformation');
  console.log('Les données sont perdues lors de la conversion');
}

console.log('\n💡 Conclusion:');
console.log('Si les données brutes contiennent les valeurs mais que les données transformées sont vides,');
console.log('le problème vient probablement de la correspondance des noms de colonnes dans la base de données.');
console.log('Vérifiez que les noms de colonnes dans Supabase correspondent exactement aux noms attendus.');
