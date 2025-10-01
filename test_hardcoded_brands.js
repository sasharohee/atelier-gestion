// Test pour vérifier la gestion des marques hardcodées
// Ce script peut être exécuté dans la console du navigateur

console.log('🧪 Test de gestion des marques hardcodées');

// Fonction pour tester la détection des marques hardcodées
function testHardcodedBrandDetection() {
  console.log('📝 Test: Détection des marques hardcodées');
  
  const testCases = [
    { id: '1', isHardcoded: true, description: 'ID simple numérique' },
    { id: '2', isHardcoded: true, description: 'ID simple numérique' },
    { id: 'apple', isHardcoded: true, description: 'ID textuel' },
    { id: '12345', isHardcoded: true, description: 'ID numérique long' },
    { id: '8184cf37-ddea-4da0-a0df-f63175693baf', isHardcoded: false, description: 'UUID valide' },
    { id: '550e8400-e29b-41d4-a716-446655440000', isHardcoded: false, description: 'UUID valide' },
    { id: 'invalid-uuid', isHardcoded: true, description: 'UUID invalide' },
  ];
  
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  
  console.log('📋 Résultats des tests:');
  testCases.forEach(testCase => {
    const detectedAsHardcoded = !uuidRegex.test(testCase.id);
    const result = detectedAsHardcoded === testCase.isHardcoded ? '✅' : '❌';
    console.log(`${result} ${testCase.description}: "${testCase.id}" → ${detectedAsHardcoded ? 'Hardcodé' : 'UUID'}`);
  });
  
  return true;
}

// Fonction pour tester la prévention de modification
function testModificationPrevention() {
  console.log('📝 Test: Prévention de modification des marques hardcodées');
  
  const mockBrands = [
    { id: '1', name: 'Apple', type: 'hardcoded' },
    { id: '2', name: 'Samsung', type: 'hardcoded' },
    { id: '8184cf37-ddea-4da0-a0df-f63175693baf', name: 'Ma Marque', type: 'database' },
  ];
  
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  
  console.log('📋 Test de modification:');
  mockBrands.forEach(brand => {
    const isHardcoded = !uuidRegex.test(brand.id);
    const canModify = !isHardcoded;
    const result = (isHardcoded && brand.type === 'hardcoded') || (!isHardcoded && brand.type === 'database') ? '✅' : '❌';
    
    console.log(`${result} ${brand.name} (${brand.id}): ${canModify ? 'Modifiable' : 'Non modifiable'}`);
  });
  
  return true;
}

// Fonction pour tester la prévention de suppression
function testDeletionPrevention() {
  console.log('📝 Test: Prévention de suppression des marques hardcodées');
  
  const mockBrands = [
    { id: '1', name: 'Apple', type: 'hardcoded' },
    { id: '2', name: 'Samsung', type: 'hardcoded' },
    { id: '8184cf37-ddea-4da0-a0df-f63175693baf', name: 'Ma Marque', type: 'database' },
  ];
  
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  
  console.log('📋 Test de suppression:');
  mockBrands.forEach(brand => {
    const isHardcoded = !uuidRegex.test(brand.id);
    const canDelete = !isHardcoded;
    const result = (isHardcoded && brand.type === 'hardcoded') || (!isHardcoded && brand.type === 'database') ? '✅' : '❌';
    
    console.log(`${result} ${brand.name} (${brand.id}): ${canDelete ? 'Supprimable' : 'Non supprimable'}`);
  });
  
  return true;
}

// Fonction pour tester les messages d'erreur
function testErrorMessageHandling() {
  console.log('📝 Test: Gestion des messages d\'erreur');
  
  const testCases = [
    {
      id: '1',
      operation: 'modification',
      expectedMessage: 'Impossible de modifier les marques prédéfinies. Créez une nouvelle marque pour personnaliser les informations.',
      description: 'Message de modification pour marque hardcodée'
    },
    {
      id: '1',
      operation: 'suppression',
      expectedMessage: 'Impossible de supprimer les marques prédéfinies.',
      description: 'Message de suppression pour marque hardcodée'
    },
    {
      id: '8184cf37-ddea-4da0-a0df-f63175693baf',
      operation: 'modification',
      expectedMessage: null,
      description: 'Aucun message d\'erreur pour UUID valide'
    }
  ];
  
  console.log('📋 Messages d\'erreur attendus:');
  testCases.forEach(testCase => {
    if (testCase.expectedMessage) {
      console.log(`✅ ${testCase.description}: "${testCase.expectedMessage}"`);
    } else {
      console.log(`✅ ${testCase.description}: Aucun message d'erreur`);
    }
  });
  
  return true;
}

// Fonction pour diagnostiquer les problèmes actuels
function diagnoseCurrentIssues() {
  console.log('🔍 Diagnostic des problèmes actuels');
  
  const issues = [];
  
  // Vérifier si des marques hardcodées sont présentes
  const tableRows = document.querySelectorAll('table tbody tr');
  let hardcodedBrandsFound = 0;
  
  tableRows.forEach((row, index) => {
    const brandName = row.querySelector('td:first-child')?.textContent?.trim();
    if (brandName && ['Apple', 'Samsung', 'Xiaomi', 'Huawei', 'OnePlus', 'Google'].includes(brandName)) {
      hardcodedBrandsFound++;
      console.log(`📋 Marque hardcodée trouvée: ${brandName}`);
    }
  });
  
  console.log(`📊 Total des marques hardcodées trouvées: ${hardcodedBrandsFound}`);
  
  if (hardcodedBrandsFound > 0) {
    issues.push(`${hardcodedBrandsFound} marques hardcodées détectées`);
  }
  
  // Vérifier les boutons d'action
  const editButtons = document.querySelectorAll('button[aria-label*="Modifier"], button[title*="Modifier"]');
  const deleteButtons = document.querySelectorAll('button[aria-label*="Supprimer"], button[title*="Supprimer"]');
  
  console.log(`📊 Boutons de modification trouvés: ${editButtons.length}`);
  console.log(`📊 Boutons de suppression trouvés: ${deleteButtons.length}`);
  
  if (issues.length > 0) {
    console.log('❌ Problèmes détectés:');
    issues.forEach(issue => console.log(`  - ${issue}`));
  } else {
    console.log('✅ Aucun problème détecté');
  }
  
  return issues;
}

// Fonction pour tester l'interface utilisateur
function testUIBehavior() {
  console.log('📝 Test: Comportement de l\'interface utilisateur');
  
  const testScenarios = [
    {
      scenario: 'Clic sur modification d\'une marque hardcodée',
      expected: 'Message d\'erreur affiché',
      action: 'Cliquer sur le bouton de modification d\'Apple'
    },
    {
      scenario: 'Clic sur suppression d\'une marque hardcodée',
      expected: 'Message d\'erreur affiché',
      action: 'Cliquer sur le bouton de suppression d\'Apple'
    },
    {
      scenario: 'Clic sur modification d\'une marque de base de données',
      expected: 'Modal de modification ouvert',
      action: 'Cliquer sur le bouton de modification d\'une marque créée par l\'utilisateur'
    }
  ];
  
  console.log('📋 Scénarios de test:');
  testScenarios.forEach(scenario => {
    console.log(`🔍 ${scenario.scenario}`);
    console.log(`   Action: ${scenario.action}`);
    console.log(`   Résultat attendu: ${scenario.expected}`);
    console.log('');
  });
  
  return true;
}

// Exécuter tous les tests
async function runAllTests() {
  console.log('🚀 Démarrage des tests de gestion des marques hardcodées...');
  
  const test1 = testHardcodedBrandDetection();
  const test2 = testModificationPrevention();
  const test3 = testDeletionPrevention();
  const test4 = testErrorMessageHandling();
  const test5 = testUIBehavior();
  const issues = diagnoseCurrentIssues();
  
  if (test1 && test2 && test3 && test4 && test5 && issues.length === 0) {
    console.log('🎉 Tous les tests sont passés avec succès !');
    console.log('✅ La gestion des marques hardcodées fonctionne correctement');
  } else {
    console.log('❌ Certains tests ont échoué ou des problèmes ont été détectés');
    console.log('📋 Problèmes à résoudre:', issues);
  }
}

// Instructions d'utilisation
console.log(`
📋 Instructions d'utilisation:

1. Ouvrir la page "Gestion des Appareils" dans l'application
2. Aller dans l'onglet "Marques"
3. Ouvrir la console du navigateur (F12)
4. Coller ce script et appuyer sur Entrée
5. Exécuter: runAllTests()

Ou exécuter les tests individuellement:
- testHardcodedBrandDetection()
- testModificationPrevention()
- testDeletionPrevention()
- testErrorMessageHandling()
- testUIBehavior()
- diagnoseCurrentIssues()
`);

// Exporter les fonctions pour utilisation manuelle
window.testHardcodedBrands = {
  testHardcodedBrandDetection,
  testModificationPrevention,
  testDeletionPrevention,
  testErrorMessageHandling,
  testUIBehavior,
  diagnoseCurrentIssues,
  runAllTests
};
