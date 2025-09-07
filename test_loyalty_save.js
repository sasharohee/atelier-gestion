// Script de test pour vérifier la sauvegarde des niveaux de fidélité
// Ce script teste directement la base de données

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testLoyaltySave() {
  console.log('🧪 Test de sauvegarde des niveaux de fidélité...');
  
  try {
    // 1. Vérifier les niveaux existants
    console.log('\n📋 1. Vérification des niveaux existants...');
    const { data: existingTiers, error: fetchError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required');
    
    if (fetchError) {
      console.error('❌ Erreur lors de la récupération des niveaux:', fetchError);
      return;
    }
    
    console.log(`✅ ${existingTiers.length} niveaux trouvés:`, existingTiers.map(t => t.name));
    
    // 2. Tester la mise à jour d'un niveau
    if (existingTiers.length > 0) {
      const tierToUpdate = existingTiers[0];
      const newDescription = `Test de sauvegarde - ${new Date().toISOString()}`;
      
      console.log(`\n🔄 2. Test de mise à jour du niveau "${tierToUpdate.name}"...`);
      console.log(`   Description actuelle: ${tierToUpdate.description}`);
      console.log(`   Nouvelle description: ${newDescription}`);
      
      const { data: updateResult, error: updateError } = await supabase
        .from('loyalty_tiers_advanced')
        .update({
          description: newDescription,
          updated_at: new Date().toISOString()
        })
        .eq('id', tierToUpdate.id)
        .select();
      
      if (updateError) {
        console.error('❌ Erreur lors de la mise à jour:', updateError);
      } else {
        console.log('✅ Mise à jour réussie:', updateResult[0]);
      }
    }
    
    // 3. Tester l'insertion d'un nouveau niveau
    console.log('\n➕ 3. Test d\'insertion d\'un nouveau niveau...');
    const newTier = {
      id: 'test-' + Date.now(),
      name: 'Test Niveau',
      description: 'Niveau de test créé automatiquement',
      points_required: 999,
      discount_percentage: 25.0,
      color: '#FF0000',
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    const { data: insertResult, error: insertError } = await supabase
      .from('loyalty_tiers_advanced')
      .insert(newTier)
      .select();
    
    if (insertError) {
      console.error('❌ Erreur lors de l\'insertion:', insertError);
    } else {
      console.log('✅ Insertion réussie:', insertResult[0]);
      
      // 4. Supprimer le niveau de test
      console.log('\n🗑️ 4. Suppression du niveau de test...');
      const { error: deleteError } = await supabase
        .from('loyalty_tiers_advanced')
        .delete()
        .eq('id', newTier.id);
      
      if (deleteError) {
        console.error('❌ Erreur lors de la suppression:', deleteError);
      } else {
        console.log('✅ Suppression réussie');
      }
    }
    
    // 5. Vérifier les triggers
    console.log('\n🔧 5. Vérification des triggers...');
    const { data: triggerData, error: triggerError } = await supabase
      .rpc('get_table_triggers', { table_name: 'loyalty_tiers_advanced' });
    
    if (triggerError) {
      console.log('⚠️ Impossible de vérifier les triggers (fonction non disponible)');
    } else {
      console.log('✅ Triggers vérifiés:', triggerData);
    }
    
    console.log('\n🎉 Test terminé avec succès !');
    
  } catch (error) {
    console.error('💥 Erreur générale:', error);
  }
}

// Fonction pour vérifier les triggers (alternative)
async function checkTriggers() {
  console.log('\n🔍 Vérification manuelle des triggers...');
  
  // Test simple : mettre à jour un niveau et vérifier si updated_at change
  const { data: tiers } = await supabase
    .from('loyalty_tiers_advanced')
    .select('id, name, updated_at')
    .limit(1);
  
  if (tiers && tiers.length > 0) {
    const tier = tiers[0];
    const oldUpdatedAt = tier.updated_at;
    
    console.log(`   Niveau: ${tier.name}`);
    console.log(`   updated_at avant: ${oldUpdatedAt}`);
    
    // Attendre 1 seconde pour s'assurer que le timestamp change
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const { data: updateResult } = await supabase
      .from('loyalty_tiers_advanced')
      .update({ description: 'Test trigger - ' + Date.now() })
      .eq('id', tier.id)
      .select('updated_at');
    
    if (updateResult && updateResult.length > 0) {
      const newUpdatedAt = updateResult[0].updated_at;
      console.log(`   updated_at après: ${newUpdatedAt}`);
      
      if (newUpdatedAt !== oldUpdatedAt) {
        console.log('✅ Trigger updated_at fonctionne correctement !');
      } else {
        console.log('⚠️ Trigger updated_at ne semble pas fonctionner');
      }
    }
  }
}

// Exécuter les tests
async function runTests() {
  console.log('🚀 Démarrage des tests de sauvegarde...');
  await testLoyaltySave();
  await checkTriggers();
}

// Exécuter si le script est appelé directement
if (require.main === module) {
  runTests().catch(console.error);
}

module.exports = { testLoyaltySave, checkTriggers };
