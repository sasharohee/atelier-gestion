#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

// Configuration pour la base distante
const supabaseUrl = 'https://olrihggkxyksuofkesnk.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scmloZ2dreHlrc3VvZmtlc25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5NDA2OTMsImV4cCI6MjA3MzUxNjY5M30.-Gypdwe8jMt3qVqrl4pKc6a98rzO0lxlYh5ZCtgG7oE';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createTestUser() {
  console.log('🔧 Création d\'un utilisateur de test pour la base distante...');
  
  try {
    // Créer un utilisateur de test
    const { data, error } = await supabase.auth.signUp({
      email: 'test@atelier-dev.com',
      password: 'test123456',
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
    console.log('📋 Status:', data.user?.email_confirmed_at ? 'Email confirmé' : 'Email non confirmé');
    
    if (!data.user?.email_confirmed_at) {
      console.log('\n⚠️  IMPORTANT: L\'email n\'est pas confirmé.');
      console.log('📧 Vérifiez votre boîte email pour le lien de confirmation.');
      console.log('🔗 Ou utilisez les identifiants suivants dans votre application:');
      console.log('   Email: test@atelier-dev.com');
      console.log('   Mot de passe: test123456');
    }

  } catch (err) {
    console.error('❌ Erreur:', err.message);
  }
}

// Créer aussi un utilisateur admin
async function createAdminUser() {
  console.log('\n🔧 Création d\'un utilisateur admin...');
  
  try {
    const { data, error } = await supabase.auth.signUp({
      email: 'admin@atelier-dev.com',
      password: 'At3l13r@dm1n#2024$ecur3!',
      options: {
        emailRedirectTo: 'http://localhost:3000'
      }
    });

    if (error) {
      console.error('❌ Erreur lors de la création admin:', error.message);
      return;
    }

    console.log('✅ Utilisateur admin créé avec succès!');
    console.log('📧 Email:', data.user?.email);
    console.log('🆔 ID:', data.user?.id);
    console.log('🔗 Identifiants admin:');
    console.log('   Email: admin@atelier-dev.com');
    console.log('   Mot de passe: At3l13r@dm1n#2024$ecur3!');

  } catch (err) {
    console.error('❌ Erreur admin:', err.message);
  }
}

async function main() {
  console.log('🚀 Configuration des utilisateurs de test pour la base distante\n');
  
  await createTestUser();
  await createAdminUser();
  
  console.log('\n✅ Configuration terminée!');
  console.log('🌐 Votre application utilise maintenant la base distante:');
  console.log('   URL: https://olrihggkxyksuofkesnk.supabase.co');
  console.log('\n📝 Utilisez les identifiants créés ci-dessus pour vous connecter.');
}

main().catch(console.error);

