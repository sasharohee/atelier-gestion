// =====================================================
// TEST ISOLATION NIVEAUX DE FIDÉLITÉ PAR ATELIER
// =====================================================
// Script pour tester que chaque atelier ne voit que ses propres niveaux
// Date: 2025-01-23
// =====================================================

const { createClient } = require('@supabase/supabase-js');

// Configuration Supabase (remplacer par vos vraies valeurs)
const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testLoyaltyIsolation() {
  console.log('🧪 === TEST ISOLATION NIVEAUX DE FIDÉLITÉ ===\n');

  try {
    // Test 1: Vérifier que les fonctions existent
    console.log('1️⃣ Test des fonctions utilitaires...');
    
    const { data: tiersData, error: tiersError } = await supabase.rpc('get_workshop_loyalty_tiers');
    if (tiersError) {
      console.log('❌ Fonction get_workshop_loyalty_tiers non disponible:', tiersError.message);
    } else {
      console.log('✅ Fonction get_workshop_loyalty_tiers disponible');
      console.log(`   📊 Niveaux trouvés: ${tiersData?.length || 0}`);
    }

    const { data: configData, error: configError } = await supabase.rpc('get_workshop_loyalty_config');
    if (configError) {
      console.log('❌ Fonction get_workshop_loyalty_config non disponible:', configError.message);
    } else {
      console.log('✅ Fonction get_workshop_loyalty_config disponible');
      console.log(`   📊 Configurations trouvées: ${configData?.length || 0}`);
    }

    // Test 2: Vérifier l'isolation RLS
    console.log('\n2️⃣ Test de l\'isolation RLS...');
    
    const { data: directTiers, error: directError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required');

    if (directError) {
      console.log('❌ Erreur lors du chargement direct:', directError.message);
    } else {
      console.log('✅ Chargement direct réussi');
      console.log(`   📊 Niveaux visibles: ${directTiers?.length || 0}`);
      
      if (directTiers && directTiers.length > 0) {
        console.log('   📋 Détail des niveaux:');
        directTiers.forEach(tier => {
          console.log(`      - ${tier.name}: ${tier.points_required} pts (${tier.discount_percentage}% réduction)`);
        });
      }
    }

    // Test 3: Vérifier la configuration
    console.log('\n3️⃣ Test de la configuration...');
    
    const { data: directConfig, error: directConfigError } = await supabase
      .from('loyalty_config')
      .select('*')
      .order('key');

    if (directConfigError) {
      console.log('❌ Erreur lors du chargement de la config:', directConfigError.message);
    } else {
      console.log('✅ Chargement de la config réussi');
      console.log(`   📊 Configurations visibles: ${directConfig?.length || 0}`);
      
      if (directConfig && directConfig.length > 0) {
        console.log('   📋 Détail des configurations:');
        directConfig.forEach(config => {
          console.log(`      - ${config.key}: ${config.value} (${config.description})`);
        });
      }
    }

    // Test 4: Tester la création d'un niveau
    console.log('\n4️⃣ Test de création d\'un niveau...');
    
    const testTier = {
      name: 'Test Isolation',
      points_required: 50,
      discount_percentage: 2.5,
      color: '#FF0000',
      description: 'Niveau de test pour vérifier l\'isolation',
      is_active: true
    };

    const { data: insertData, error: insertError } = await supabase
      .from('loyalty_tiers_advanced')
      .insert([testTier])
      .select();

    if (insertError) {
      console.log('❌ Erreur lors de la création du niveau test:', insertError.message);
    } else {
      console.log('✅ Niveau test créé avec succès');
      console.log(`   🆔 ID du niveau: ${insertData[0]?.id}`);
      
      // Vérifier que le niveau est visible
      const { data: verifyData, error: verifyError } = await supabase
        .from('loyalty_tiers_advanced')
        .select('*')
        .eq('id', insertData[0]?.id);

      if (verifyError) {
        console.log('❌ Erreur lors de la vérification:', verifyError.message);
      } else if (verifyData && verifyData.length > 0) {
        console.log('✅ Niveau test visible après création');
        
        // Nettoyer le test
        const { error: deleteError } = await supabase
          .from('loyalty_tiers_advanced')
          .delete()
          .eq('id', insertData[0]?.id);

        if (deleteError) {
          console.log('⚠️ Erreur lors du nettoyage:', deleteError.message);
        } else {
          console.log('✅ Niveau test supprimé');
        }
      } else {
        console.log('❌ Niveau test non visible après création');
      }
    }

    // Test 5: Tester la fonction de création par défaut
    console.log('\n5️⃣ Test de la fonction de création par défaut...');
    
    const { data: createResult, error: createError } = await supabase.rpc(
      'create_default_loyalty_tiers_for_workshop',
      { p_workshop_id: '00000000-0000-0000-0000-000000000000' } // UUID de test
    );

    if (createError) {
      console.log('❌ Erreur lors de la création par défaut:', createError.message);
    } else {
      console.log('✅ Fonction de création par défaut testée');
      console.log(`   📊 Résultat: ${JSON.stringify(createResult)}`);
    }

    // Test 6: Vérifier les politiques RLS
    console.log('\n6️⃣ Test des politiques RLS...');
    
    // Essayer de voir tous les niveaux (devrait être filtré par RLS)
    const { data: allTiers, error: allTiersError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('id, name, workshop_id')
      .limit(10);

    if (allTiersError) {
      console.log('❌ Erreur lors du test RLS:', allTiersError.message);
    } else {
      console.log('✅ Test RLS réussi');
      console.log(`   📊 Niveaux visibles: ${allTiers?.length || 0}`);
      
      if (allTiers && allTiers.length > 0) {
        console.log('   📋 Détail des niveaux visibles:');
        allTiers.forEach(tier => {
          console.log(`      - ${tier.name} (workshop_id: ${tier.workshop_id})`);
        });
      }
    }

    console.log('\n🎉 === RÉSUMÉ DU TEST ===');
    console.log('✅ Tests d\'isolation des niveaux de fidélité terminés');
    console.log('📊 Vérifiez les résultats ci-dessus pour confirmer l\'isolation');
    console.log('🔒 Chaque atelier devrait ne voir que ses propres niveaux');

  } catch (error) {
    console.error('❌ Erreur lors du test:', error);
  }
}

// Fonction pour tester avec un utilisateur spécifique
async function testWithUser(userId) {
  console.log(`\n🔐 Test avec utilisateur spécifique: ${userId}`);
  
  // Note: Dans un vrai test, vous devriez vous authentifier avec cet utilisateur
  // Ici on simule juste l'appel des fonctions
  
  try {
    const { data: tiersData, error: tiersError } = await supabase.rpc('get_workshop_loyalty_tiers');
    
    if (tiersError) {
      console.log('❌ Erreur avec utilisateur spécifique:', tiersError.message);
    } else {
      console.log(`✅ Niveaux pour l'utilisateur ${userId}: ${tiersData?.length || 0}`);
    }
  } catch (error) {
    console.error('❌ Erreur lors du test utilisateur:', error);
  }
}

// Exécuter les tests
if (require.main === module) {
  testLoyaltyIsolation()
    .then(() => {
      console.log('\n✅ Tests terminés');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Erreur fatale:', error);
      process.exit(1);
    });
}

module.exports = {
  testLoyaltyIsolation,
  testWithUser
};
