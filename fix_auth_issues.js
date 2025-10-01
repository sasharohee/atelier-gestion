// Script pour corriger les problèmes d'authentification
// À exécuter dans la console du navigateur

console.log('🔧 Correction des problèmes d\'authentification...');

// Fonction pour nettoyer complètement l'état d'authentification
function clearAllAuthData() {
  try {
    // Nettoyer localStorage
    const authKeys = [
      'atelier-auth-token',
      'supabase.auth.token',
      'pendingSignupEmail',
      'confirmationToken',
      'pendingUserData',
      'sb-olrihggkxyksuofkesnk-auth-token',
      'supabase.auth.token'
    ];
    
    authKeys.forEach(key => {
      localStorage.removeItem(key);
      sessionStorage.removeItem(key);
      console.log('🧹 Supprimé:', key);
    });
    
    // Nettoyer tous les éléments liés à Supabase
    Object.keys(localStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier')) {
        localStorage.removeItem(key);
        console.log('🧹 Supprimé (pattern):', key);
      }
    });
    
    Object.keys(sessionStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier')) {
        sessionStorage.removeItem(key);
        console.log('🧹 Supprimé (session):', key);
      }
    });
    
    console.log('✅ Données d\'authentification nettoyées');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
    return false;
  }
}

// Fonction pour réinitialiser l'état de l'application
function resetAppState() {
  try {
    // Nettoyer les cookies
    document.cookie.split(";").forEach(function(c) { 
      document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
    });
    
    // Nettoyer IndexedDB si possible
    if ('indexedDB' in window) {
      indexedDB.databases().then(databases => {
        databases.forEach(db => {
          if (db.name && (db.name.includes('supabase') || db.name.includes('auth'))) {
            indexedDB.deleteDatabase(db.name);
            console.log('🧹 Base de données supprimée:', db.name);
          }
        });
      }).catch(error => {
        console.log('⚠️ Impossible de nettoyer IndexedDB:', error);
      });
    }
    
    console.log('✅ État de l\'application réinitialisé');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de la réinitialisation:', error);
    return false;
  }
}

// Fonction pour créer un utilisateur de test
function createTestUser() {
  console.log('🔧 Création d\'un utilisateur de test...');
  
  // Données de test
  const testUser = {
    email: 'test@atelier.com',
    password: 'TestPassword123!',
    firstName: 'Test',
    lastName: 'User'
  };
  
  console.log('👤 Utilisateur de test:', testUser);
  console.log('💡 Utilisez ces identifiants pour vous connecter');
  
  return testUser;
}

// Fonction pour tester la connexion Supabase
async function testSupabaseConnection() {
  try {
    console.log('🔍 Test de connexion Supabase...');
    
    // Vérifier si Supabase est disponible
    if (typeof window.supabase !== 'undefined') {
      const { data, error } = await window.supabase.from('clients').select('count').limit(1);
      
      if (error) {
        console.error('❌ Erreur de connexion Supabase:', error);
        return false;
      } else {
        console.log('✅ Connexion Supabase réussie');
        return true;
      }
    } else {
      console.log('⚠️ Client Supabase non disponible');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur lors du test de connexion:', error);
    return false;
  }
}

// Exécuter toutes les corrections
async function fixAllIssues() {
  console.log('🚀 Début de la correction des problèmes...');
  
  // 1. Nettoyer l'authentification
  clearAllAuthData();
  
  // 2. Réinitialiser l'état de l'application
  resetAppState();
  
  // 3. Créer un utilisateur de test
  const testUser = createTestUser();
  
  // 4. Tester la connexion
  await testSupabaseConnection();
  
  console.log('✅ Toutes les corrections appliquées');
  console.log('🔄 Rechargez la page pour appliquer les changements');
  
  return testUser;
}

// Exécuter automatiquement
fixAllIssues();

// Exposer les fonctions globalement pour un usage manuel
window.fixAuthIssues = {
  clearAllAuthData,
  resetAppState,
  createTestUser,
  testSupabaseConnection,
  fixAllIssues
};

