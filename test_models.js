const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

async function checkModels() {
  try {
    console.log('🔍 Vérification des modèles d\'appareils...');
    
    const { data, error } = await supabase
      .from('device_models')
      .select('*')
      .order('brand', { ascending: true });
    
    if (error) {
      console.error('❌ Erreur:', error);
      return;
    }
    
    console.log('📱 Modèles d\'appareils dans la base:');
    console.log('Total:', data.length);
    
    if (data.length === 0) {
      console.log('⚠️ Aucun modèle trouvé dans la base de données');
      return;
    }
    
    data.forEach((model, index) => {
      console.log(`${index + 1}. ${model.brand} ${model.model} (${model.type}) - Actif: ${model.is_active}`);
    });
    
    // Grouper par type
    const byType = {};
    data.forEach(model => {
      if (!byType[model.type]) byType[model.type] = [];
      byType[model.type].push(model);
    });
    
    console.log('\n📊 Répartition par type:');
    Object.keys(byType).forEach(type => {
      console.log(`${type}: ${byType[type].length} modèles`);
    });
    
    // Vérifier les types uniques
    const uniqueTypes = [...new Set(data.map(m => m.type))];
    console.log('\n🎯 Types uniques trouvés:', uniqueTypes);
    
  } catch (err) {
    console.error('💥 Exception:', err);
  }
}

checkModels();
