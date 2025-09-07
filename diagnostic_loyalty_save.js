// Script de diagnostic complet pour la sauvegarde des niveaux de fidélité
// Ce script teste tous les aspects de la sauvegarde

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticComplet() {
  console.log('🔍 DIAGNOSTIC COMPLET - Sauvegarde des niveaux de fidélité');
  console.log('=' .repeat(60));
  
  try {
    // 1. Vérifier la connexion à Supabase
    console.log('\n📡 1. Test de connexion Supabase...');
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError) {
      console.error('❌ Erreur d\'authentification:', authError);
    } else if (user) {
      console.log('✅ Utilisateur connecté:', user.email);
    } else {
      console.log('⚠️ Aucun utilisateur connecté');
    }
    
    // 2. Vérifier l'existence des tables
    console.log('\n🗄️ 2. Vérification des tables...');
    const tables = ['loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history'];
    
    for (const table of tables) {
      try {
        const { data, error } = await supabase
          .from(table)
          .select('*')
          .limit(1);
        
        if (error) {
          console.error(`❌ Table ${table}:`, error.message);
        } else {
          console.log(`✅ Table ${table}: accessible`);
        }
      } catch (err) {
        console.error(`❌ Table ${table}:`, err.message);
      }
    }
    
    // 3. Vérifier les niveaux existants
    console.log('\n📋 3. Vérification des niveaux existants...');
    const { data: tiers, error: tiersError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required');
    
    if (tiersError) {
      console.error('❌ Erreur lors de la récupération des niveaux:', tiersError);
    } else {
      console.log(`✅ ${tiers.length} niveaux trouvés:`);
      tiers.forEach(tier => {
        console.log(`   - ${tier.name}: ${tier.points_required} pts, ${tier.discount_percentage}%`);
      });
    }
    
    // 4. Tester les permissions RLS
    console.log('\n🔒 4. Test des permissions RLS...');
    if (tiers && tiers.length > 0) {
      const testTier = tiers[0];
      console.log(`   Test avec le niveau: ${testTier.name}`);
      
      // Test de lecture
      const { data: readTest, error: readError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .eq('id', testTier.id);
      
      if (readError) {
        console.error('❌ Erreur de lecture:', readError);
      } else {
        console.log('✅ Lecture autorisée');
      }
      
      // Test de mise à jour
      const { data: updateTest, error: updateError } = await supabase
        .from('loyalty_tiers_advanced')
        .update({ description: 'Test RLS - ' + Date.now() })
        .eq('id', testTier.id)
        .select();
      
      if (updateError) {
        console.error('❌ Erreur de mise à jour:', updateError);
        console.log('   Détails de l\'erreur:', JSON.stringify(updateError, null, 2));
      } else {
        console.log('✅ Mise à jour autorisée');
      }
    }
    
    // 5. Tester l'insertion
    console.log('\n➕ 5. Test d\'insertion...');
    const testTier = {
      id: 'test-diagnostic-' + Date.now(),
      name: 'Test Diagnostic',
      description: 'Niveau de test pour diagnostic',
      points_required: 999,
      discount_percentage: 25.0,
      color: '#FF0000',
      is_active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
    
    const { data: insertResult, error: insertError } = await supabase
      .from('loyalty_tiers_advanced')
      .insert(testTier)
      .select();
    
    if (insertError) {
      console.error('❌ Erreur d\'insertion:', insertError);
      console.log('   Détails de l\'erreur:', JSON.stringify(insertError, null, 2));
    } else {
      console.log('✅ Insertion réussie:', insertResult[0]);
      
      // Nettoyer le test
      await supabase
        .from('loyalty_tiers_advanced')
        .delete()
        .eq('id', testTier.id);
      console.log('✅ Niveau de test supprimé');
    }
    
    // 6. Vérifier les triggers
    console.log('\n🔧 6. Vérification des triggers...');
    try {
      // Test simple de trigger updated_at
      if (tiers && tiers.length > 0) {
        const tier = tiers[0];
        const oldUpdatedAt = tier.updated_at;
        
        console.log(`   Test du trigger updated_at sur: ${tier.name}`);
        console.log(`   updated_at avant: ${oldUpdatedAt}`);
        
        // Attendre pour s'assurer que le timestamp change
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const { data: triggerTest, error: triggerError } = await supabase
          .from('loyalty_tiers_advanced')
          .update({ description: 'Test trigger - ' + Date.now() })
          .eq('id', tier.id)
          .select('updated_at');
        
        if (triggerError) {
          console.error('❌ Erreur lors du test de trigger:', triggerError);
        } else if (triggerTest && triggerTest.length > 0) {
          const newUpdatedAt = triggerTest[0].updated_at;
          console.log(`   updated_at après: ${newUpdatedAt}`);
          
          if (newUpdatedAt !== oldUpdatedAt) {
            console.log('✅ Trigger updated_at fonctionne');
          } else {
            console.log('⚠️ Trigger updated_at ne semble pas fonctionner');
          }
        }
      }
    } catch (err) {
      console.error('❌ Erreur lors du test de trigger:', err);
    }
    
    // 7. Vérifier les configurations
    console.log('\n⚙️ 7. Vérification des configurations...');
    const { data: configs, error: configError } = await supabase
      .from('loyalty_config')
      .select('*');
    
    if (configError) {
      console.error('❌ Erreur lors de la récupération des configurations:', configError);
    } else {
      console.log(`✅ ${configs.length} configurations trouvées:`);
      configs.forEach(config => {
        console.log(`   - ${config.key}: ${config.value}`);
      });
    }
    
    // 8. Test de l'upsert
    console.log('\n🔄 8. Test de l\'upsert...');
    const upsertTier = {
      id: '11111111-1111-1111-1111-111111111111', // ID fixe pour test
      name: 'Bronze',
      description: 'Test upsert - ' + Date.now(),
      points_required: 0,
      discount_percentage: 0.0,
      color: '#CD7F32',
      is_active: true,
      updated_at: new Date().toISOString()
    };
    
    const { data: upsertResult, error: upsertError } = await supabase
      .from('loyalty_tiers_advanced')
      .upsert(upsertTier, { onConflict: 'id' })
      .select();
    
    if (upsertError) {
      console.error('❌ Erreur d\'upsert:', upsertError);
      console.log('   Détails de l\'erreur:', JSON.stringify(upsertError, null, 2));
    } else {
      console.log('✅ Upsert réussi:', upsertResult[0]);
    }
    
    console.log('\n🎉 DIAGNOSTIC TERMINÉ');
    console.log('=' .repeat(60));
    
  } catch (error) {
    console.error('💥 Erreur générale lors du diagnostic:', error);
  }
}

// Fonction pour tester spécifiquement les erreurs de sauvegarde
async function testErreursSauvegarde() {
  console.log('\n🔍 TEST SPÉCIFIQUE - Erreurs de sauvegarde');
  console.log('=' .repeat(50));
  
  try {
    // Simuler exactement ce que fait l'application
    const modificationsToSave = {
      '11111111-1111-1111-1111-111111111111': {
        points_required: 50,
        discount_percentage: 2.5
      }
    };
    
    console.log('📝 Modifications à sauvegarder:', modificationsToSave);
    
    for (const [id, updates] of Object.entries(modificationsToSave)) {
      console.log(`\n🔄 Sauvegarde tier ${id}...`);
      
      // Récupérer les données du tier
      const { data: tierData, error: fetchError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .eq('id', id)
        .single();
      
      if (fetchError) {
        console.error('❌ Erreur récupération tier:', fetchError);
        continue;
      }
      
      console.log('📊 Tier trouvé:', tierData.name);
      
      // Préparer les données de mise à jour
      const updateData = {
        name: tierData.name,
        description: tierData.description,
        points_required: updates.points_required !== undefined ? Number(updates.points_required) : tierData.points_required,
        discount_percentage: updates.discount_percentage !== undefined ? Number(updates.discount_percentage) : tierData.discount_percentage,
        color: tierData.color,
        is_active: tierData.is_active,
        updated_at: new Date().toISOString()
      };
      
      console.log('📝 Données de mise à jour:', updateData);
      
      // Essayer la mise à jour
      const { data: updateResult, error: updateError } = await supabase
        .from('loyalty_tiers_advanced')
        .update(updateData)
        .eq('id', id)
        .select();
      
      if (updateError) {
        console.error('❌ Erreur mise à jour:', updateError);
        console.log('   Détails:', JSON.stringify(updateError, null, 2));
        
        // Essayer l'insert
        console.log('🔄 Tentative d\'insert...');
        const { data: insertResult, error: insertError } = await supabase
          .from('loyalty_tiers_advanced')
          .insert({
            id: id,
            ...updateData,
            created_at: new Date().toISOString()
          })
          .select();
        
        if (insertError) {
          console.error('❌ Erreur insert:', insertError);
          console.log('   Détails:', JSON.stringify(insertError, null, 2));
        } else {
          console.log('✅ Insert réussi:', insertResult[0]);
        }
      } else {
        console.log('✅ Mise à jour réussie:', updateResult[0]);
      }
    }
    
  } catch (error) {
    console.error('💥 Erreur lors du test de sauvegarde:', error);
  }
}

// Exécuter les diagnostics
async function runDiagnostics() {
  await diagnosticComplet();
  await testErreursSauvegarde();
}

// Exécuter si le script est appelé directement
if (require.main === module) {
  runDiagnostics().catch(console.error);
}

module.exports = { diagnosticComplet, testErreursSauvegarde };
