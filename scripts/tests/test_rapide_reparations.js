// Test rapide des réparations
// Ce script vérifie rapidement que les réparations fonctionnent

console.log('🧪 Test rapide des réparations...');

// Vérifier que le store est accessible
if (typeof window !== 'undefined' && window.store) {
  console.log('✅ Store accessible');
  
  const state = window.store.getState();
  console.log('📊 État du store:', {
    repairs: state.repairs?.length || 0,
    clients: state.clients?.length || 0,
    devices: state.devices?.length || 0
  });
  
  // Vérifier les réparations
  if (state.repairs && state.repairs.length > 0) {
    console.log('✅ Réparations trouvées:', state.repairs.length);
    console.log('📋 Première réparation:', state.repairs[0]);
    
    // Tester la fonction updateRepair
    if (state.updateRepair) {
      console.log('✅ Fonction updateRepair disponible');
      
      // Test de mise à jour (commenté pour éviter les modifications accidentelles)
      // const repairId = state.repairs[0].id;
      // console.log('🔄 Test de mise à jour pour:', repairId);
      // state.updateRepair(repairId, { status: 'test' });
    } else {
      console.error('❌ Fonction updateRepair non disponible');
    }
  } else {
    console.warn('⚠️ Aucune réparation trouvée');
  }
  
  // Vérifier les services
  if (state.repairService) {
    console.log('✅ Service de réparations disponible');
  } else {
    console.warn('⚠️ Service de réparations non disponible');
  }
  
} else {
  console.error('❌ Store non accessible');
}

// Vérifier l'authentification
if (typeof window !== 'undefined' && window.supabase) {
  console.log('✅ Supabase accessible');
  
  // Vérifier l'utilisateur connecté
  window.supabase.auth.getUser().then(({ data, error }) => {
    if (error) {
      console.error('❌ Erreur d\'authentification:', error);
    } else if (data.user) {
      console.log('✅ Utilisateur connecté:', data.user.id);
    } else {
      console.warn('⚠️ Aucun utilisateur connecté');
    }
  });
} else {
  console.error('❌ Supabase non accessible');
}

// Instructions pour le test manuel
console.log(`
📋 Instructions pour tester manuellement :

1. Allez sur la page "Suivi des réparations"
2. Ouvrez la console (F12)
3. Essayez de déplacer une réparation d'une colonne à l'autre
4. Vérifiez les logs dans la console
5. Vérifiez que la réparation change visuellement

Logs attendus :
🎯 handleDragEnd appelé avec: {...}
🔄 updateRepair appelé avec: {...}
🔧 repairService.update appelé avec: {...}
✅ Mise à jour réussie
✅ Mise à jour du store terminée
`);

console.log('✅ Test rapide terminé');
