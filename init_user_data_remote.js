#!/usr/bin/env node

const { createClient } = require('@supabase/supabase-js');

// Configuration pour la base distante
const supabaseUrl = 'https://olrihggkxyksuofkesnk.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9scmloZ2dreHlrc3VvZmtlc25rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5NDA2OTMsImV4cCI6MjA3MzUxNjY5M30.-Gypdwe8jMt3qVqrl4pKc6a98rzO0lxlYh5ZCtgG7oE';

const supabase = createClient(supabaseUrl, supabaseKey);

const USER_ID = '13d6e91c-8f4b-415a-b165-d5f8b4b0f72a';
const USER_EMAIL = 'sasharohee@icloud.com';

async function initUserData() {
  console.log('🚀 Initialisation des données utilisateur dans la base distante...\n');
  
  try {
    // S'authentifier d'abord
    console.log('🔐 Authentification...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: USER_EMAIL,
      password: 'woJcy7-cusmod-sywxyn@'
    });

    if (authError) {
      console.error('❌ Erreur d\'authentification:', authError.message);
      return;
    }

    console.log('✅ Authentification réussie');
    console.log('👤 Utilisateur connecté:', authData.user.email);
    // 1. Vérifier/créer subscription_status
    console.log('📋 Vérification de subscription_status...');
    const { data: existingStatus } = await supabase
      .from('subscription_status')
      .select('*')
      .eq('user_id', USER_ID)
      .single();

    if (!existingStatus) {
      console.log('✅ Création de subscription_status...');
      const { error: statusError } = await supabase
        .from('subscription_status')
        .insert({
          user_id: USER_ID,
          email: USER_EMAIL,
          first_name: 'Sasha',
          last_name: 'Rohee',
          is_active: true,
          subscription_type: 'premium',
          status: 'active',
          role: 'admin'
        });

      if (statusError) {
        console.error('❌ Erreur subscription_status:', statusError.message);
      } else {
        console.log('✅ subscription_status créé');
      }
    } else {
      console.log('✅ subscription_status existe déjà');
    }

    // 2. Créer un profil utilisateur
    console.log('\n👤 Création du profil utilisateur...');
    const { error: userError } = await supabase
      .from('users')
      .upsert({
        id: USER_ID,
        email: USER_EMAIL,
        first_name: 'Sasha',
        last_name: 'Rohee',
        role: 'admin'
      });

    if (userError) {
      console.error('❌ Erreur users:', userError.message);
    } else {
      console.log('✅ Profil utilisateur créé/mis à jour');
    }

    // 3. Créer des paramètres système par défaut
    console.log('\n⚙️  Création des paramètres système...');
    const { error: settingsError } = await supabase
      .from('system_settings')
      .upsert({
        user_id: USER_ID,
        setting_key: 'workshop_name',
        setting_value: 'Atelier Sasha',
        setting_type: 'string'
      });

    if (settingsError) {
      console.error('❌ Erreur system_settings:', settingsError.message);
    } else {
      console.log('✅ Paramètres système créés');
    }

    // 4. Créer des catégories par défaut
    console.log('\n📂 Création des catégories par défaut...');
    const defaultCategories = [
      { name: 'Smartphones', description: 'Réparation de smartphones' },
      { name: 'Ordinateurs', description: 'Réparation d\'ordinateurs' },
      { name: 'Tablettes', description: 'Réparation de tablettes' }
    ];

    for (const category of defaultCategories) {
      const { error: catError } = await supabase
        .from('device_categories')
        .upsert({
          name: category.name,
          description: category.description,
          user_id: USER_ID
        });

      if (catError) {
        console.error(`❌ Erreur catégorie ${category.name}:`, catError.message);
      } else {
        console.log(`✅ Catégorie "${category.name}" créée`);
      }
    }

    // 5. Créer des services par défaut
    console.log('\n🔧 Création des services par défaut...');
    const defaultServices = [
      { name: 'Diagnostic', description: 'Diagnostic complet', price: 25.00 },
      { name: 'Réparation écran', description: 'Remplacement d\'écran', price: 80.00 },
      { name: 'Réparation batterie', description: 'Remplacement de batterie', price: 45.00 }
    ];

    for (const service of defaultServices) {
      const { error: serviceError } = await supabase
        .from('services')
        .upsert({
          name: service.name,
          description: service.description,
          price: service.price,
          user_id: USER_ID
        });

      if (serviceError) {
        console.error(`❌ Erreur service ${service.name}:`, serviceError.message);
      } else {
        console.log(`✅ Service "${service.name}" créé`);
      }
    }

    console.log('\n🎉 Initialisation terminée avec succès!');
    console.log('🌐 Votre application est maintenant prête à être utilisée avec la base distante.');
    console.log('\n📝 Identifiants de connexion:');
    console.log(`   Email: ${USER_EMAIL}`);
    console.log('   Mot de passe: woJcy7-cusmod-sywxyn@');

  } catch (err) {
    console.error('❌ Erreur générale:', err.message);
  }
}

initUserData().catch(console.error);
