// Script de diagnostic pour la fidélité
import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticLoyalty() {
  console.log('🔍 Diagnostic de la fidélité...\n');

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
      console.log(`✅ ${tiers?.length || 0} niveaux trouvés:`);
      tiers?.forEach(tier => {
        console.log(`   - ${tier.name}: ${tier.points_required} pts (${tier.discount_percentage}%)`);
      });
    }

    // 2. Vérifier les clients avec points
    console.log('\n2. Vérification des clients:');
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('id, first_name, last_name, loyalty_points, current_tier_id')
      .gt('loyalty_points', 0);

    if (clientsError) {
      console.error('❌ Erreur clients:', clientsError);
    } else {
      console.log(`✅ ${clients?.length || 0} clients avec points:`);
      clients?.forEach(client => {
        console.log(`   - ${client.first_name} ${client.last_name}: ${client.loyalty_points} pts (tier: ${client.current_tier_id})`);
      });
    }

    // 3. Vérifier l'historique des points
    console.log('\n3. Vérification de l\'historique:');
    const { data: history, error: historyError } = await supabase
      .from('loyalty_points_history')
      .select('*')
      .limit(5);

    if (historyError) {
      console.error('❌ Erreur historique:', historyError);
    } else {
      console.log(`✅ ${history?.length || 0} entrées d'historique trouvées`);
    }

    // 4. Test de calcul de progression
    console.log('\n4. Test de calcul de progression:');
    if (tiers && clients) {
      clients.forEach(client => {
        const availablePoints = client.loyalty_points || 0;
        const currentTier = tiers.find(t => t.id === client.current_tier_id);
        const nextTier = tiers.find(t => t.points_required > availablePoints);
        
        let progress = 0;
        if (nextTier && currentTier) {
          const currentTierPoints = currentTier.points_required || 0;
          const nextTierPoints = nextTier.points_required;
          const pointsInCurrentTier = availablePoints - currentTierPoints;
          const pointsNeededForNextTier = nextTierPoints - currentTierPoints;
          
          if (pointsNeededForNextTier > 0) {
            progress = Math.max(0, Math.min(100, (pointsInCurrentTier / pointsNeededForNextTier) * 100));
          } else {
            progress = 100;
          }
        } else if (nextTier && !currentTier) {
          progress = Math.max(0, Math.min(100, (availablePoints / nextTier.points_required) * 100));
        } else {
          progress = 100;
        }

        console.log(`   - ${client.first_name}: ${availablePoints} pts, progression: ${Math.round(progress)}% vers ${nextTier?.name || 'max'}`);
      });
    }

  } catch (error) {
    console.error('💥 Erreur générale:', error);
  }
}

// Exécuter le diagnostic
diagnosticLoyalty();
