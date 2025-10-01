// Script pour résoudre TOUS les problèmes d'authentification
// À exécuter dans la console du navigateur

console.log('🚀 Résolution complète des problèmes d\'authentification...');

// Fonction pour nettoyer complètement l'état d'authentification
function clearAllAuthData() {
  try {
    console.log('🧹 Nettoyage complet de l\'état d\'authentification...');
    
    // 1. Nettoyer localStorage
    const authKeys = [
      'atelier-auth-token',
      'supabase.auth.token',
      'pendingSignupEmail',
      'confirmationToken',
      'pendingUserData',
      'sb-localhost-auth-token',
      'sb-olrihggkxyksuofkesnk-auth-token',
      'supabase.auth.token',
      'supabase.auth.refresh_token',
      'supabase.auth.access_token'
    ];
    
    authKeys.forEach(key => {
      localStorage.removeItem(key);
      sessionStorage.removeItem(key);
      console.log('🧹 Supprimé:', key);
    });
    
    // 2. Nettoyer tous les éléments liés à Supabase
    Object.keys(localStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier') || key.includes('sb-')) {
        localStorage.removeItem(key);
        console.log('🧹 Supprimé (pattern):', key);
      }
    });
    
    Object.keys(sessionStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier') || key.includes('sb-')) {
        sessionStorage.removeItem(key);
        console.log('🧹 Supprimé (session):', key);
      }
    });
    
    // 3. Nettoyer les cookies
    document.cookie.split(";").forEach(function(c) { 
      document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/"); 
    });
    console.log('🧹 Cookies nettoyés');
    
    // 4. Nettoyer IndexedDB si possible
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
    
    console.log('✅ État d\'authentification complètement nettoyé');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
    return false;
  }
}

// Fonction pour résoudre les erreurs d'extension
function fixExtensionErrors() {
  try {
    console.log('🔧 Résolution des erreurs d\'extension...');
    
    // Intercepter les erreurs d'extension
    const originalError = window.onerror;
    window.onerror = function(message, source, lineno, colno, error) {
      if (message && message.includes('Could not establish connection')) {
        console.log('🚫 Erreur d\'extension ignorée:', message);
        return true; // Empêcher l'affichage de l'erreur
      }
      if (originalError) {
        return originalError.apply(this, arguments);
      }
      return false;
    };
    
    // Nettoyer les erreurs de runtime
    if (window.chrome?.runtime) {
      const originalRuntimeError = window.chrome.runtime.onError;
      window.chrome.runtime.onError = function(error) {
        if (error.message && error.message.includes('Could not establish connection')) {
          console.log('🚫 Erreur runtime ignorée:', error.message);
          return true;
        }
        if (originalRuntimeError) {
          return originalRuntimeError.apply(this, arguments);
        }
        return false;
      };
    }
    
    console.log('✅ Erreurs d\'extension résolues');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de la résolution des extensions:', error);
    return false;
  }
}

// Fonction pour créer un utilisateur de test local
async function createLocalTestUser() {
  try {
    console.log('👤 Création d\'un utilisateur de test local...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const testUser = {
      email: 'test@atelier.local',
      password: 'TestPassword123!',
      firstName: 'Test',
      lastName: 'User'
    };
    
    // Essayer de créer l'utilisateur
    const { data, error } = await window.supabase.auth.signUp({
      email: testUser.email,
      password: testUser.password
    });
    
    if (error) {
      if (error.message.includes('already registered')) {
        console.log('ℹ️ Utilisateur de test déjà existant');
        return testUser;
      } else {
        console.error('❌ Erreur lors de la création:', error);
        return false;
      }
    } else {
      console.log('✅ Utilisateur de test créé avec succès');
      console.log('👤 Identifiants de test:', testUser);
      return testUser;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la création de l\'utilisateur:', error);
    return false;
  }
}

// Fonction pour tester la connexion locale
async function testLocalConnection() {
  try {
    console.log('🔍 Test de connexion locale...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    // Test de connexion à la base de données
    const { data, error } = await window.supabase.from('clients').select('count').limit(1);
    
    if (error) {
      console.error('❌ Erreur de connexion locale:', error);
      return false;
    } else {
      console.log('✅ Connexion locale réussie');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors du test de connexion:', error);
    return false;
  }
}

// Fonction pour tester l'authentification locale
async function testLocalAuthentication() {
  try {
    console.log('🔐 Test de l\'authentification locale...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const testUser = {
      email: 'test@atelier.local',
      password: 'TestPassword123!'
    };
    
    // Test de connexion
    const { data, error } = await window.supabase.auth.signInWithPassword({
      email: testUser.email,
      password: testUser.password
    });
    
    if (error) {
      console.error('❌ Erreur d\'authentification:', error);
      return false;
    } else {
      console.log('✅ Authentification locale réussie');
      console.log('👤 Utilisateur connecté:', data.user?.email);
      
      // Déconnexion pour le test
      await window.supabase.auth.signOut();
      console.log('🚪 Déconnexion effectuée');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors du test d\'authentification:', error);
    return false;
  }
}

// Fonction pour forcer le rechargement de la page
function forcePageReload() {
  console.log('🔄 Rechargement de la page...');
  setTimeout(() => {
    window.location.reload();
  }, 2000);
}

// Fonction principale
async function fixAllAuthIssues() {
  console.log('🚀 Début de la résolution complète des problèmes...');
  
  // 1. Résoudre les erreurs d'extension
  fixExtensionErrors();
  
  // 2. Nettoyer complètement l'état d'authentification
  const cleanupOk = clearAllAuthData();
  if (!cleanupOk) {
    console.error('❌ Échec du nettoyage');
    return false;
  }
  
  // 3. Attendre un peu pour que le nettoyage soit effectif
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // 4. Tester la connexion locale
  const connectionOk = await testLocalConnection();
  if (!connectionOk) {
    console.error('❌ Impossible de se connecter à Supabase local');
    return false;
  }
  
  // 5. Créer un utilisateur de test
  const testUser = await createLocalTestUser();
  if (!testUser) {
    console.error('❌ Impossible de créer l\'utilisateur de test');
    return false;
  }
  
  // 6. Tester l'authentification
  const authOk = await testLocalAuthentication();
  if (!authOk) {
    console.error('❌ Test d\'authentification échoué');
    return false;
  }
  
  console.log('✅ Tous les problèmes d\'authentification ont été résolus !');
  console.log('👤 Utilisez ces identifiants pour vous connecter:');
  console.log('   Email: test@atelier.local');
  console.log('   Mot de passe: TestPassword123!');
  console.log('🔄 La page va se recharger automatiquement...');
  
  // 7. Recharger la page
  forcePageReload();
  
  return true;
}

// Exécuter automatiquement
fixAllAuthIssues();

// Exposer les fonctions globalement
window.fixAllAuthIssues = {
  clearAllAuthData,
  fixExtensionErrors,
  createLocalTestUser,
  testLocalConnection,
  testLocalAuthentication,
  fixAllAuthIssues
};

