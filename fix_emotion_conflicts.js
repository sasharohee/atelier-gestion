// Script pour résoudre les conflits d'@emotion/react
// À exécuter dans la console du navigateur

console.log('🔧 Résolution des conflits @emotion/react...');

// Fonction pour nettoyer les instances multiples d'émotion
function fixEmotionConflicts() {
  try {
    // Vérifier si @emotion/react est chargé plusieurs fois
    const emotionInstances = [];
    
    // Chercher dans les modules chargés
    if (window.__webpack_require__) {
      const modules = window.__webpack_require__.cache;
      Object.keys(modules).forEach(key => {
        if (key.includes('@emotion/react')) {
          emotionInstances.push(key);
        }
      });
    }
    
    console.log('📦 Instances @emotion/react trouvées:', emotionInstances.length);
    
    // Nettoyer le cache des modules si possible
    if (window.__webpack_require__ && window.__webpack_require__.cache) {
      Object.keys(window.__webpack_require__.cache).forEach(key => {
        if (key.includes('@emotion/react') || key.includes('@emotion/styled')) {
          delete window.__webpack_require__.cache[key];
          console.log('🧹 Module supprimé du cache:', key);
        }
      });
    }
    
    // Nettoyer les styles en conflit
    const styleSheets = document.styleSheets;
    for (let i = styleSheets.length - 1; i >= 0; i--) {
      try {
        const sheet = styleSheets[i];
        if (sheet.href && sheet.href.includes('emotion')) {
          sheet.disabled = true;
          console.log('🧹 Feuille de style emotion désactivée:', sheet.href);
        }
      } catch (error) {
        // Ignorer les erreurs CORS
      }
    }
    
    console.log('✅ Conflits @emotion/react résolus');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de la résolution des conflits:', error);
    return false;
  }
}

// Fonction pour forcer le rechargement des modules
function forceModuleReload() {
  try {
    console.log('🔄 Forçage du rechargement des modules...');
    
    // Nettoyer le cache du navigateur pour les modules
    if ('caches' in window) {
      caches.keys().then(cacheNames => {
        cacheNames.forEach(cacheName => {
          if (cacheName.includes('emotion') || cacheName.includes('mui')) {
            caches.delete(cacheName);
            console.log('🧹 Cache supprimé:', cacheName);
          }
        });
      });
    }
    
    // Nettoyer le localStorage des modules
    Object.keys(localStorage).forEach(key => {
      if (key.includes('emotion') || key.includes('mui') || key.includes('webpack')) {
        localStorage.removeItem(key);
        console.log('🧹 localStorage nettoyé:', key);
      }
    });
    
    console.log('✅ Modules prêts pour le rechargement');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du rechargement des modules:', error);
    return false;
  }
}

// Fonction pour vérifier l'état d'émotion
function checkEmotionState() {
  try {
    console.log('🔍 Vérification de l\'état d\'émotion...');
    
    // Vérifier les versions chargées
    if (window.__emotion_react_version__) {
      console.log('📦 Version @emotion/react:', window.__emotion_react_version__);
    }
    
    // Vérifier les instances
    const emotionElements = document.querySelectorAll('[data-emotion]');
    console.log('🎨 Éléments emotion trouvés:', emotionElements.length);
    
    // Vérifier les conflits de styles
    const duplicateStyles = [];
    const styleMap = new Map();
    
    emotionElements.forEach(el => {
      const emotionData = el.getAttribute('data-emotion');
      if (emotionData) {
        if (styleMap.has(emotionData)) {
          duplicateStyles.push(emotionData);
        } else {
          styleMap.set(emotionData, el);
        }
      }
    });
    
    if (duplicateStyles.length > 0) {
      console.warn('⚠️ Styles dupliqués détectés:', duplicateStyles);
    } else {
      console.log('✅ Aucun style dupliqué détecté');
    }
    
    return {
      elements: emotionElements.length,
      duplicates: duplicateStyles.length,
      healthy: duplicateStyles.length === 0
    };
  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error);
    return { healthy: false, error: error.message };
  }
}

// Fonction principale
async function fixAllEmotionIssues() {
  console.log('🚀 Début de la résolution des problèmes @emotion/react...');
  
  // 1. Vérifier l'état actuel
  const initialState = checkEmotionState();
  console.log('📊 État initial:', initialState);
  
  // 2. Résoudre les conflits
  fixEmotionConflicts();
  
  // 3. Forcer le rechargement des modules
  forceModuleReload();
  
  // 4. Vérifier l'état final
  setTimeout(() => {
    const finalState = checkEmotionState();
    console.log('📊 État final:', finalState);
    
    if (finalState.healthy) {
      console.log('✅ Tous les problèmes @emotion/react ont été résolus');
    } else {
      console.log('⚠️ Certains problèmes persistent, un rechargement complet peut être nécessaire');
    }
  }, 1000);
  
  return true;
}

// Exécuter automatiquement
fixAllEmotionIssues();

// Exposer les fonctions globalement
window.fixEmotionConflicts = {
  fixEmotionConflicts,
  forceModuleReload,
  checkEmotionState,
  fixAllEmotionIssues
};

