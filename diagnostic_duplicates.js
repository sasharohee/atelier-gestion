// Script de diagnostic des doublons de niveaux de fidélité
import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticDuplicates() {
  console.log('🔍 Diagnostic des doublons de niveaux de fidélité...\n');

  try {
    // 1. Vérifier tous les niveaux
    console.log('1. Tous les niveaux chargés:');
    const { data: allTiers, error: allTiersError } = await supabase
      .from('loyalty_tiers_advanced')
      .select('*')
      .order('points_required', { ascending: true });

    if (allTiersError) {
      console.error('❌ Erreur:', allTiersError);
      return;
    }

    console.log(`📊 Total niveaux trouvés: ${allTiers?.length || 0}`);

    // 2. Analyser les doublons
    console.log('\n2. Analyse des doublons:');
    const tierCounts = {};
    allTiers?.forEach(tier => {
      if (!tierCounts[tier.name]) {
        tierCounts[tier.name] = [];
      }
      tierCounts[tier.name].push(tier);
    });

    Object.entries(tierCounts).forEach(([name, tiers]) => {
      if (tiers.length > 1) {
        console.log(`⚠️  DOUBLON: ${name} (${tiers.length} occurrences)`);
        tiers.forEach((tier, index) => {
          console.log(`   ${index + 1}. ID: ${tier.id}, Points: ${tier.points_required}, Couleur: ${tier.color}`);
        });
      } else {
        console.log(`✅ ${name}: 1 occurrence (OK)`);
      }
    });

    // 3. Vérifier les clients affectés
    console.log('\n3. Clients avec niveaux:');
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('id, first_name, last_name, loyalty_points, current_tier_id')
      .not('current_tier_id', 'is', null);

    if (clientsError) {
      console.error('❌ Erreur clients:', clientsError);
    } else {
      console.log(`📊 ${clients?.length || 0} clients avec current_tier_id:`);
      clients?.forEach(client => {
        const tier = allTiers?.find(t => t.id === client.current_tier_id);
        console.log(`   - ${client.first_name} ${client.last_name}: ${client.loyalty_points} pts → ${tier?.name || 'TIER NON TROUVÉ'}`);
      });
    }

    // 4. Recommandations
    console.log('\n4. Recommandations:');
    const hasDuplicates = Object.values(tierCounts).some(tiers => tiers.length > 1);
    
    if (hasDuplicates) {
      console.log('🔧 ACTIONS RECOMMANDÉES:');
      console.log('   1. Exécuter le script cleanup_duplicate_tiers.sql');
      console.log('   2. Recharger la page de fidélité');
      console.log('   3. Vérifier que les barres de progression fonctionnent');
    } else {
      console.log('✅ Aucun doublon détecté - système en bon état');
    }

  } catch (error) {
    console.error('💥 Erreur générale:', error);
  }
}

// Exécuter le diagnostic
diagnosticDuplicates();
