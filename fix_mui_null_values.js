// Script pour corriger les valeurs null dans les composants MUI
// Ce script identifie et corrige les problèmes de valeurs null

console.log('🔧 Correction des valeurs null dans les composants MUI...');

// Fonction pour corriger les valeurs null dans les TextField
function fixTextFieldNullValues() {
  console.log('📝 Correction des TextField avec valeurs null...');
  
  // Remplacer toutes les valeurs null par des chaînes vides
  const textFields = document.querySelectorAll('input[type="text"], input[type="email"], input[type="password"], textarea');
  textFields.forEach(field => {
    if (field.value === null || field.value === undefined) {
      field.value = '';
      console.log('✅ Valeur null corrigée pour:', field);
    }
  });
}

// Fonction pour corriger les valeurs null dans les Select
function fixSelectNullValues() {
  console.log('📋 Correction des Select avec valeurs null...');
  
  // Remplacer toutes les valeurs null par des chaînes vides
  const selects = document.querySelectorAll('select, [role="combobox"]');
  selects.forEach(select => {
    if (select.value === null || select.value === undefined) {
      select.value = '';
      console.log('✅ Valeur null corrigée pour:', select);
    }
  });
}

// Fonction pour corriger les valeurs null dans les composants MUI
function fixMUIComponents() {
  console.log('🎨 Correction des composants MUI...');
  
  // Corriger les TextField
  fixTextFieldNullValues();
  
  // Corriger les Select
  fixSelectNullValues();
  
  // Corriger les valeurs dans les états React
  if (window.React && window.React.useState) {
    console.log('⚛️ Correction des états React...');
    
    // Cette partie nécessiterait une modification du code source
    console.log('⚠️ Les états React nécessitent une modification du code source');
  }
}

// Exécuter la correction
fixMUIComponents();

console.log('✅ Correction des valeurs null terminée');

// Fonction pour surveiller les nouvelles valeurs null
function watchForNullValues() {
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList') {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const element = node;
            if (element.value === null || element.value === undefined) {
              element.value = '';
              console.log('🔍 Nouvelle valeur null détectée et corrigée:', element);
            }
          }
        });
      }
    });
  });
  
  observer.observe(document.body, {
    childList: true,
    subtree: true
  });
  
  console.log('👀 Surveillance des valeurs null activée');
}

// Activer la surveillance
watchForNullValues();


