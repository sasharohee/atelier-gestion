// Script pour désactiver les extensions problématiques
// À exécuter dans la console du navigateur

console.log('🔧 Désactivation des extensions problématiques...');

// Désactiver React DevTools
if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
    window.__REACT_DEVTOOLS_GLOBAL_HOOK__.isDisabled = true;
    console.log('✅ React DevTools désactivé');
}

// Désactiver Redux DevTools
if (window.__REDUX_DEVTOOLS_EXTENSION__) {
    window.__REDUX_DEVTOOLS_EXTENSION__ = undefined;
    console.log('✅ Redux DevTools désactivé');
}

// Désactiver Vue DevTools
if (window.__VUE_DEVTOOLS_GLOBAL_HOOK__) {
    window.__VUE_DEVTOOLS_GLOBAL_HOOK__.enabled = false;
    console.log('✅ Vue DevTools désactivé');
}

// Désactiver les autres extensions de développement
if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
    window.__REACT_DEVTOOLS_GLOBAL_HOOK__.inject = function() {};
    window.__REACT_DEVTOOLS_GLOBAL_HOOK__.onCommitFiberRoot = function() {};
    window.__REACT_DEVTOOLS_GLOBAL_HOOK__.onCommitFiberUnmount = function() {};
}

console.log('🎉 Extensions désactivées - Erreurs d\'extension supprimées');

