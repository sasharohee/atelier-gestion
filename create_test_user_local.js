// Script pour créer un utilisateur de test dans Supabase local
// À exécuter dans la console du navigateur

console.log('🔧 Création d\'un utilisateur de test dans Supabase local...');

// Fonction pour créer un utilisateur de test
async function createTestUserLocal() {
  try {
    console.log('👤 Création d\'un utilisateur de test...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const testUser = {
      email: 'test@atelier.local',
      password: 'TestPassword123!'
    };
    
    console.log('📧 Tentative de création avec:', testUser.email);
    
    // Essayer de créer l'utilisateur
    const { data, error } = await window.supabase.auth.signUp({
      email: testUser.email,
      password: testUser.password
    });
    
    if (error) {
      console.error('❌ Erreur lors de la création:', error);
      
      // Si l'utilisateur existe déjà, essayer de se connecter
      if (error.message.includes('already registered') || error.message.includes('User already registered')) {
        console.log('ℹ️ Utilisateur déjà existant, test de connexion...');
        
        const { data: loginData, error: loginError } = await window.supabase.auth.signInWithPassword({
          email: testUser.email,
          password: testUser.password
        });
        
        if (loginError) {
          console.error('❌ Erreur de connexion:', loginError);
          return false;
        } else {
          console.log('✅ Connexion réussie avec l\'utilisateur existant');
          console.log('👤 Utilisateur connecté:', loginData.user?.email);
          
          // Déconnexion pour le test
          await window.supabase.auth.signOut();
          console.log('🚪 Déconnexion effectuée');
          return testUser;
        }
      }
      
      return false;
    } else {
      console.log('✅ Utilisateur créé avec succès');
      console.log('👤 Utilisateur:', data.user?.email);
      
      // Déconnexion pour le test
      await window.supabase.auth.signOut();
      console.log('🚪 Déconnexion effectuée');
      return testUser;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la création de l\'utilisateur:', error);
    return false;
  }
}

// Fonction pour tester la connexion
async function testLogin() {
  try {
    console.log('🔐 Test de connexion...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const testUser = {
      email: 'test@atelier.local',
      password: 'TestPassword123!'
    };
    
    const { data, error } = await window.supabase.auth.signInWithPassword({
      email: testUser.email,
      password: testUser.password
    });
    
    if (error) {
      console.error('❌ Erreur de connexion:', error);
      return false;
    } else {
      console.log('✅ Connexion réussie !');
      console.log('👤 Utilisateur connecté:', data.user?.email);
      console.log('🔑 Session ID:', data.session?.access_token?.substring(0, 20) + '...');
      
      // Déconnexion pour le test
      await window.supabase.auth.signOut();
      console.log('🚪 Déconnexion effectuée');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors du test de connexion:', error);
    return false;
  }
}

// Fonction pour vérifier la configuration Supabase
function checkSupabaseConfig() {
  try {
    console.log('🔍 Vérification de la configuration Supabase...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const config = window.supabase.supabaseUrl;
    console.log('🌐 URL Supabase:', config);
    
    if (config.includes('127.0.0.1') || config.includes('localhost')) {
      console.log('✅ Configuration locale détectée');
      return true;
    } else {
      console.log('⚠️ Configuration non locale détectée');
      return false;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error);
    return false;
  }
}

// Fonction principale
async function setupTestUser() {
  console.log('🚀 Début de la configuration de l\'utilisateur de test...');
  
  // 1. Vérifier la configuration
  const configOk = checkSupabaseConfig();
  if (!configOk) {
    console.error('❌ Configuration Supabase incorrecte');
    return false;
  }
  
  // 2. Créer l'utilisateur de test
  const userCreated = await createTestUserLocal();
  if (!userCreated) {
    console.error('❌ Impossible de créer l\'utilisateur de test');
    return false;
  }
  
  // 3. Tester la connexion
  const loginOk = await testLogin();
  if (!loginOk) {
    console.error('❌ Test de connexion échoué');
    return false;
  }
  
  console.log('✅ Configuration de l\'utilisateur de test terminée !');
  console.log('👤 Identifiants de test:');
  console.log('   Email: test@atelier.local');
  console.log('   Mot de passe: TestPassword123!');
  console.log('💡 Vous pouvez maintenant vous connecter à l\'application');
  
  return true;
}

// Exécuter automatiquement
setupTestUser();

// Exposer les fonctions globalement
window.setupTestUser = {
  createTestUserLocal,
  testLogin,
  checkSupabaseConfig,
  setupTestUser
};

