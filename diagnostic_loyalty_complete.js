// Script de diagnostic complet de la fidélité
import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticLoyaltyComplete() {
  console.log('🔍 Diagnostic complet de la fidélité...\n');

  try {
    // 1. Vérifier les niveaux de fidélité
    console.log('1. Vérification des niveaux de fidélité:');
    const { data: tiers, error: tiersError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required', { ascending: true });

    if (tiersError) {
      console.error('❌ Erreur niveaux:', tiersError);
    } else {
      console.log(`📊 ${tiers?.length || 0} niveaux trouvés:`);
      if (tiers && tiers.length > 0) {
        tiers.forEach(tier => {
          console.log(`   ✅ ${tier.name}: ${tier.points_required} pts (${tier.discount_percentage}%)`);
        });
      } else {
        console.log('   ⚠️  Aucun niveau trouvé - problème détecté !');
      }
    }

    // 2. Vérifier les configurations
    console.log('\n2. Vérification des configurations:');
    const { data: configs, error: configsError } = await supabase
      .from('loyalty_config')
      .select('*')
      .order('key');

    if (configsError) {
      console.error('❌ Erreur configurations:', configsError);
    } else {
      console.log(`📊 ${configs?.length || 0} configurations trouvées:`);
      if (configs && configs.length > 0) {
        configs.forEach(config => {
          console.log(`   ✅ ${config.key}: ${config.value}`);
        });
      } else {
        console.log('   ⚠️  Aucune configuration trouvée - problème détecté !');
      }
    }

    // 3. Vérifier les clients
    console.log('\n3. Vérification des clients:');
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('id, first_name, last_name, loyalty_points, current_tier_id')
      .gt('loyalty_points', 0);

    if (clientsError) {
      console.error('❌ Erreur clients:', clientsError);
    } else {
      console.log(`📊 ${clients?.length || 0} clients avec points:`);
      clients?.forEach(client => {
        const tier = tiers?.find(t => t.id === client.current_tier_id);
        console.log(`   ✅ ${client.first_name} ${client.last_name}: ${client.loyalty_points} pts → ${tier?.name || 'TIER NON TROUVÉ'}`);
      });
    }

    // 4. Vérifier l'historique
    console.log('\n4. Vérification de l\'historique:');
    const { data: history, error: historyError } = await supabase
      .from('loyalty_points_history')
      .select('*')
      .limit(5);

    if (historyError) {
      console.error('❌ Erreur historique:', historyError);
    } else {
      console.log(`📊 ${history?.length || 0} entrées d'historique trouvées`);
    }

    // 5. Diagnostic et recommandations
    console.log('\n5. Diagnostic et recommandations:');
    
    const hasTiers = tiers && tiers.length > 0;
    const hasConfigs = configs && configs.length > 0;
    const hasClients = clients && clients.length > 0;
    
    if (!hasTiers && !hasConfigs) {
      console.log('🔧 PROBLÈME MAJEUR DÉTECTÉ:');
      console.log('   - Aucun niveau de fidélité trouvé');
      console.log('   - Aucune configuration trouvée');
      console.log('   - Les paramètres ne peuvent pas fonctionner');
      console.log('\n📋 ACTIONS REQUISES:');
      console.log('   1. Exécuter le script fix_loyalty_complete.sql');
      console.log('   2. Recharger la page de fidélité');
      console.log('   3. Vérifier que les paramètres fonctionnent');
    } else if (!hasTiers) {
      console.log('🔧 PROBLÈME DÉTECTÉ:');
      console.log('   - Aucun niveau de fidélité trouvé');
      console.log('   - Les barres de progression ne fonctionneront pas');
      console.log('\n📋 ACTIONS REQUISES:');
      console.log('   1. Exécuter le script cleanup_duplicate_tiers.sql');
      console.log('   2. Recharger la page de fidélité');
    } else if (!hasConfigs) {
      console.log('🔧 PROBLÈME DÉTECTÉ:');
      console.log('   - Aucune configuration trouvée');
      console.log('   - Les paramètres ne peuvent pas être sauvegardés');
      console.log('\n📋 ACTIONS REQUISES:');
      console.log('   1. Exécuter le script create_loyalty_config.sql');
      console.log('   2. Recharger la page de fidélité');
    } else {
      console.log('✅ SYSTÈME EN BON ÉTAT:');
      console.log('   - Niveaux de fidélité: OK');
      console.log('   - Configurations: OK');
      console.log('   - Clients: OK');
      console.log('\n🎉 Aucune action requise - tout fonctionne correctement !');
    }

  } catch (error) {
    console.error('💥 Erreur générale:', error);
  }
}

// Exécuter le diagnostic
diagnosticLoyaltyComplete();
