#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

// Configuration pour la base distante
const supabaseUrl = 'https://olrihggkxyksuofkesnk.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scmloZ2dreHlrc3VvZmtlc25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5NDA2OTMsImV4cCI6MjA3MzUxNjY5M30.-Gypdwe8jMt3qVqrl4pKc6a98rzO0lxlYh5ZCtgG7oE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createConfirmedUser() {
  console.log('🔧 Création d\'un utilisateur avec email confirmé...');
  
  try {
    // Créer un utilisateur avec un email unique
    const timestamp = Date.now();
    const email = `user${timestamp}@atelier-test.com`;
    const password = 'test123456';
    
    console.log(`📧 Création de l'utilisateur: ${email}`);
    
    const { data, error } = await supabase.auth.signUp({
      email: email,
      password: password,
      options: {
        emailRedirectTo: 'http://localhost:3000'
      }
    });

    if (error) {
      console.error('❌ Erreur lors de la création:', error.message);
      return;
    }

    console.log('✅ Utilisateur créé avec succès!');
    console.log('📧 Email:', data.user?.email);
    console.log('🆔 ID:', data.user?.id);
    
    // Essayer de confirmer l'email via l'API
    console.log('\n🔧 Tentative de confirmation automatique...');
    
    // Attendre un peu pour que l'email soit traité
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Tenter la connexion
    const { data: loginData, error: loginError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password
    });

    if (loginError) {
      console.log('⚠️  Connexion échouée:', loginError.message);
      console.log('\n📋 Identifiants créés:');
      console.log(`   Email: ${email}`);
      console.log(`   Mot de passe: ${password}`);
      console.log('\n📧 Vérifiez votre boîte email pour confirmer l\'adresse.');
      console.log('🔗 Ou utilisez ces identifiants dans votre application après confirmation.');
    } else {
      console.log('✅ Connexion réussie!');
      console.log('🎉 L\'utilisateur est prêt à être utilisé.');
    }

  } catch (err) {
    console.error('❌ Erreur:', err.message);
  }
}

async function testExistingUsers() {
  console.log('\n🔧 Test des utilisateurs existants...');
  
  const testUsers = [
    { email: 'test@atelier.com', password: 'test123456' },
    { email: 'demo@atelier.com', password: 'demo123456' }
  ];
  
  for (const user of testUsers) {
    console.log(`\n🧪 Test de connexion: ${user.email}`);
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: user.email,
        password: user.password
      });

      if (error) {
        console.log(`❌ ${user.email}: ${error.message}`);
      } else {
        console.log(`✅ ${user.email}: Connexion réussie!`);
        console.log('🎉 Utilisez ces identifiants dans votre application:');
        console.log(`   Email: ${user.email}`);
        console.log(`   Mot de passe: ${user.password}`);
        return; // Arrêter au premier succès
      }
    } catch (err) {
      console.log(`❌ ${user.email}: ${err.message}`);
    }
  }
}

async function main() {
  console.log('🚀 Configuration de l\'authentification pour la base distante\n');
  
  await testExistingUsers();
  await createConfirmedUser();
  
  console.log('\n✅ Configuration terminée!');
  console.log('🌐 Votre application utilise la base distante:');
  console.log('   URL: https://olrihggkxyksuofkesnk.supabase.co');
  console.log('\n💡 Si aucun utilisateur ne fonctionne, vérifiez votre boîte email');
  console.log('   pour les liens de confirmation des comptes créés.');
}

main().catch(console.error);

