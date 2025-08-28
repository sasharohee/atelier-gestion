// Script de test pour vérifier les données de réduction dans les réparations
console.log('🔍 Vérification des données de réduction dans les réparations...');

// Attendre que l'application soit chargée
setTimeout(async () => {
  try {
    if (typeof window !== 'undefined' && window.repairService) {
      console.log('✅ repairService disponible');
      
      // Récupérer toutes les réparations
      const result = await window.repairService.getAll();
      
      if (result.success && result.data) {
        console.log(`📊 Nombre total de réparations: ${result.data.length}`);
        
        // Filtrer les réparations avec réduction
        const reparationsAvecReduction = result.data.filter(repair => 
          repair.discountPercentage && repair.discountPercentage > 0
        );
        
        console.log(`🎯 Réparations avec réduction: ${reparationsAvecReduction.length}`);
        
        // Afficher les détails des réparations avec réduction
        reparationsAvecReduction.forEach((repair, index) => {
          console.log(`\n🔧 Réparation ${index + 1}:`);
          console.log(`   ID: ${repair.id}`);
          console.log(`   Prix total: ${repair.totalPrice} €`);
          console.log(`   Prix original: ${repair.originalPrice || 'Non défini'} €`);
          console.log(`   Réduction: ${repair.discountPercentage}%`);
          console.log(`   Montant réduction: ${repair.discountAmount || 'Non défini'} €`);
          console.log(`   Statut: ${repair.status}`);
        });
        
        // Tester la récupération d'une réparation spécifique
        if (reparationsAvecReduction.length > 0) {
          const premiereReparation = reparationsAvecReduction[0];
          console.log(`\n🧪 Test de récupération de la réparation ${premiereReparation.id}...`);
          
          const detailResult = await window.repairService.getById(premiereReparation.id);
          
          if (detailResult.success && detailResult.data) {
            console.log('✅ Récupération réussie:');
            console.log(`   Prix total: ${detailResult.data.totalPrice} €`);
            console.log(`   Prix original: ${detailResult.data.originalPrice || 'Non défini'} €`);
            console.log(`   Réduction: ${detailResult.data.discountPercentage}%`);
            console.log(`   Montant réduction: ${detailResult.data.discountAmount || 'Non défini'} €`);
          } else {
            console.error('❌ Erreur lors de la récupération:', detailResult.error);
          }
        }
        
      } else {
        console.error('❌ Erreur lors de la récupération des réparations:', result.error);
      }
    } else {
      console.error('❌ repairService non disponible');
    }
  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}, 2000);
