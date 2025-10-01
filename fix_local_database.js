// Script pour corriger la base de données locale
// À exécuter dans la console du navigateur

console.log('🔧 Correction de la base de données locale...');

// Fonction pour vérifier la connexion à la base de données
async function checkDatabaseConnection() {
  try {
    console.log('🔍 Vérification de la connexion à la base de données...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    // Test de connexion simple
    const { data, error } = await window.supabase.from('clients').select('count').limit(1);
    
    if (error) {
      console.error('❌ Erreur de connexion à la base de données:', error);
      return false;
    } else {
      console.log('✅ Connexion à la base de données réussie');
      return true;
    }
  } catch (error) {
    console.error('❌ Erreur lors de la vérification:', error);
    return false;
  }
}

// Fonction pour créer un utilisateur de test avec différentes approches
async function createTestUserMultipleApproaches() {
  try {
    console.log('👤 Tentative de création d\'utilisateur avec différentes approches...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const testUsers = [
      { email: 'test@atelier.local', password: 'TestPassword123!' },
      { email: 'admin@atelier.local', password: 'AdminPassword123!' },
      { email: 'user@atelier.local', password: 'UserPassword123!' }
    ];
    
    for (const testUser of testUsers) {
      console.log(`📧 Tentative avec: ${testUser.email}`);
      
      try {
        // Essayer de créer l'utilisateur
        const { data, error } = await window.supabase.auth.signUp({
          email: testUser.email,
          password: testUser.password
        });
        
        if (error) {
          if (error.message.includes('already registered') || error.message.includes('User already registered')) {
            console.log(`✅ Utilisateur ${testUser.email} existe déjà`);
            
            // Tester la connexion
            const { data: loginData, error: loginError } = await window.supabase.auth.signInWithPassword({
              email: testUser.email,
              password: testUser.password
            });
            
            if (loginError) {
              console.log(`❌ Impossible de se connecter avec ${testUser.email}:`, loginError.message);
            } else {
              console.log(`✅ Connexion réussie avec ${testUser.email}`);
              await window.supabase.auth.signOut();
              return testUser;
            }
          } else {
            console.log(`❌ Erreur avec ${testUser.email}:`, error.message);
          }
        } else {
          console.log(`✅ Utilisateur ${testUser.email} créé avec succès`);
          await window.supabase.auth.signOut();
          return testUser;
        }
      } catch (error) {
        console.log(`❌ Exception avec ${testUser.email}:`, error.message);
      }
    }
    
    return false;
  } catch (error) {
    console.error('❌ Erreur lors de la création d\'utilisateur:', error);
    return false;
  }
}

// Fonction pour vérifier les tables de la base de données
async function checkDatabaseTables() {
  try {
    console.log('🔍 Vérification des tables de la base de données...');
    
    if (typeof window.supabase === 'undefined') {
      console.error('❌ Client Supabase non disponible');
      return false;
    }
    
    const tables = ['clients', 'users', 'auth.users'];
    
    for (const table of tables) {
      try {
        const { data, error } = await window.supabase.from(table).select('count').limit(1);
        
        if (error) {
          console.log(`⚠️ Table ${table}: ${error.message}`);
        } else {
          console.log(`✅ Table ${table}: accessible`);
        }
      } catch (error) {
        console.log(`❌ Table ${table}: ${error.message}`);
      }
    }
    
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des tables:', error);
    return false;
  }
}

// Fonction pour nettoyer et recréer l'état d'authentification
async function resetAuthState() {
  try {
    console.log('🧹 Réinitialisation de l\'état d\'authentification...');
    
    // Nettoyer localStorage
    const authKeys = [
      'atelier-auth-token',
      'supabase.auth.token',
      'pendingSignupEmail',
      'confirmationToken',
      'pendingUserData',
      'sb-localhost-auth-token',
      'sb-127.0.0.1-auth-token'
    ];
    
    authKeys.forEach(key => {
      localStorage.removeItem(key);
      sessionStorage.removeItem(key);
    });
    
    // Nettoyer tous les éléments liés à Supabase
    Object.keys(localStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier') || key.includes('sb-')) {
        localStorage.removeItem(key);
      }
    });
    
    Object.keys(sessionStorage).forEach(key => {
      if (key.includes('supabase') || key.includes('auth') || key.includes('atelier') || key.includes('sb-')) {
        sessionStorage.removeItem(key);
      }
    });
    
    console.log('✅ État d\'authentification nettoyé');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
    return false;
  }
}

// Fonction principale
async function fixLocalDatabase() {
  console.log('🚀 Début de la correction de la base de données locale...');
  
  // 1. Nettoyer l'état d'authentification
  await resetAuthState();
  
  // 2. Vérifier la connexion à la base de données
  const dbOk = await checkDatabaseConnection();
  if (!dbOk) {
    console.error('❌ Impossible de se connecter à la base de données');
    return false;
  }
  
  // 3. Vérifier les tables
  await checkDatabaseTables();
  
  // 4. Créer un utilisateur de test
  const userCreated = await createTestUserMultipleApproaches();
  if (!userCreated) {
    console.error('❌ Impossible de créer un utilisateur de test');
    return false;
  }
  
  console.log('✅ Correction de la base de données locale terminée !');
  console.log('👤 Utilisez ces identifiants pour vous connecter:');
  console.log(`   Email: ${userCreated.email}`);
  console.log(`   Mot de passe: ${userCreated.password}`);
  
  return true;
}

// Exécuter automatiquement
fixLocalDatabase();

// Exposer les fonctions globalement
window.fixLocalDatabase = {
  checkDatabaseConnection,
  createTestUserMultipleApproaches,
  checkDatabaseTables,
  resetAuthState,
  fixLocalDatabase
};

