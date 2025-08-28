// Test direct de la mise à jour des réparations
console.log('🧪 Test de mise à jour des réparations');

// Fonction pour tester la mise à jour
async function testMiseAJourReparations() {
  try {
    console.log('1️⃣ Vérification du store...');
    
    // Vérifier si le store est accessible
    if (typeof window !== 'undefined' && window.useAppStore) {
      const store = window.useAppStore.getState();
      console.log('✅ Store accessible:', store);
      
      // Vérifier les réparations existantes
      console.log('📋 Réparations existantes:', store.repairs.length);
      
      if (store.repairs.length > 0) {
        const premiereReparation = store.repairs[0];
        console.log('🔍 Première réparation:', premiereReparation);
        
        // Tester la mise à jour
        console.log('🔄 Test de mise à jour...');
        await store.updateRepair(premiereReparation.id, { 
          status: 'en_cours',
          notes: 'Test de mise à jour - ' + new Date().toISOString()
        });
        
        console.log('✅ Mise à jour terminée');
        
        // Vérifier le résultat
        const storeApres = window.useAppStore.getState();
        const reparationMiseAJour = storeApres.repairs.find(r => r.id === premiereReparation.id);
        console.log('📊 Réparation après mise à jour:', reparationMiseAJour);
        
      } else {
        console.log('⚠️ Aucune réparation trouvée');
      }
    } else {
      console.log('❌ Store non accessible');
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test:', error);
  }
}

// Fonction pour tester le service directement
async function testServiceDirect() {
  try {
    console.log('2️⃣ Test du service direct...');
    
    if (typeof window !== 'undefined' && window.repairService) {
      console.log('✅ Service accessible');
      
      // Récupérer toutes les réparations
      const result = await window.repairService.getAll();
      console.log('📥 Résultat getAll:', result);
      
      if (result.success && result.data && result.data.length > 0) {
        const premiereReparation = result.data[0];
        console.log('🔍 Première réparation du service:', premiereReparation);
        
        // Tester la mise à jour directe
        const updateResult = await window.repairService.update(premiereReparation.id, {
          status: 'termine',
          notes: 'Test direct - ' + new Date().toISOString()
        });
        
        console.log('📤 Résultat update:', updateResult);
        
      } else {
        console.log('⚠️ Aucune réparation trouvée dans le service');
      }
    } else {
      console.log('❌ Service non accessible');
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test du service:', error);
  }
}

// Fonction pour exposer les objets globaux
function exposeGlobals() {
  if (typeof window !== 'undefined') {
    // Exposer le store
    if (window.useAppStore) {
      console.log('✅ Store exposé globalement');
    }
    
    // Exposer le service
    if (window.repairService) {
      console.log('✅ Service exposé globalement');
    }
    
    // Exposer les fonctions de test
    window.testMiseAJourReparations = testMiseAJourReparations;
    window.testServiceDirect = testServiceDirect;
    
    console.log('🎯 Fonctions de test exposées:');
    console.log('  - testMiseAJourReparations()');
    console.log('  - testServiceDirect()');
  }
}

// Exécuter les tests
console.log('🚀 Démarrage des tests...');
exposeGlobals();

// Attendre un peu puis lancer les tests
setTimeout(() => {
  testMiseAJourReparations();
  setTimeout(() => {
    testServiceDirect();
  }, 1000);
}, 1000);

console.log('✅ Script de test chargé');
