// Script pour configurer l'authentification locale
// À exécuter dans la console du navigateur

console.log('🔧 Configuration de l\'authentification locale...');

// Fonction pour nettoyer complètement l'état d'authentification
function clearAllAuthData() {
  try {
    console.log('🧹 Nettoyage de l\'état d\'authentification...');
    
    // Nettoyer localStorage
    const authKeys = [
      'atelier-auth-token',
      'supabase.auth.token',
      'pendingSignupEmail',
      'confirmationToken',
      'pendingUserData',
      'sb-localhost-auth-token',
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

// Fonction pour créer un utilisateur de test
async function createTestUser() {
  try {
    console.log('👤 Création d\'un utilisateur de test...');
    
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

// Fonction pour tester l'authentification
async function testAuthentication() {
  try {
    console.log('🔐 Test de l\'authentification...');
    
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
      console.log('✅ Authentification réussie');
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

// Fonction principale
async function setupLocalAuth() {
  console.log('🚀 Début de la configuration de l\'authentification locale...');
  
  // 1. Nettoyer l'état d'authentification
  clearAllAuthData();
  
  // 2. Tester la connexion locale
  const connectionOk = await testLocalConnection();
  if (!connectionOk) {
    console.error('❌ Impossible de se connecter à Supabase local');
    return false;
  }
  
  // 3. Créer un utilisateur de test
  const testUser = await createTestUser();
  if (!testUser) {
    console.error('❌ Impossible de créer l\'utilisateur de test');
    return false;
  }
  
  // 4. Tester l'authentification
  const authOk = await testAuthentication();
  if (!authOk) {
    console.error('❌ Test d\'authentification échoué');
    return false;
  }
  
  console.log('✅ Configuration de l\'authentification locale terminée');
  console.log('👤 Utilisez ces identifiants pour vous connecter:');
  console.log('   Email: test@atelier.local');
  console.log('   Mot de passe: TestPassword123!');
  
  return true;
}

// Exécuter automatiquement
setupLocalAuth();

// Exposer les fonctions globalement
window.setupLocalAuth = {
  clearAllAuthData,
  createTestUser,
  testLocalConnection,
  testAuthentication,
  setupLocalAuth
};

