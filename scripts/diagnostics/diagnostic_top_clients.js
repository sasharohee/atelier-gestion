// =====================================================
// DIAGNOSTIC TOP 10 CLIENTS - STATISTIQUES
// =====================================================
// Script pour diagnostiquer pourquoi le top 10 des clients
// ne fonctionne pas dans les statistiques
// Date: 2025-01-23
// =====================================================

import { createClient } from '@supabase/supabase-js';

// Configuration Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://your-project.supabase.co';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'your-anon-key';

const supabase = createClient(supabaseUrl, supabaseKey);

async function diagnosticTopClients() {
  console.log('🔍 DIAGNOSTIC TOP 10 CLIENTS - STATISTIQUES');
  console.log('==========================================\n');

  try {
    // 1. Vérifier l'utilisateur connecté
    console.log('1️⃣ Vérification de l\'utilisateur connecté...');
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    
    if (userError || !user) {
      console.log('❌ Aucun utilisateur connecté');
      console.log('💡 Solution: Connectez-vous à l\'application');
      return;
    }
    
    console.log('✅ Utilisateur connecté:', user.id);
    console.log('📧 Email:', user.email);
    console.log('');

    // 2. Vérifier les clients de l'utilisateur
    console.log('2️⃣ Vérification des clients...');
    const { data: clients, error: clientsError } = await supabase
      .from('clients')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (clientsError) {
      console.log('❌ Erreur lors de la récupération des clients:', clientsError);
      return;
    }
    
    console.log(`✅ ${clients.length} clients trouvés pour l'utilisateur`);
    if (clients.length > 0) {
      console.log('📋 Premiers clients:');
      clients.slice(0, 3).forEach((client, index) => {
        console.log(`  ${index + 1}. ${client.first_name} ${client.last_name} (${client.email}) - ID: ${client.id}`);
      });
    }
    console.log('');

    // 3. Vérifier les réparations de l'utilisateur
    console.log('3️⃣ Vérification des réparations...');
    const { data: repairs, error: repairsError } = await supabase
      .from('repairs')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    if (repairsError) {
      console.log('❌ Erreur lors de la récupération des réparations:', repairsError);
      return;
    }
    
    console.log(`✅ ${repairs.length} réparations trouvées pour l'utilisateur`);
    if (repairs.length > 0) {
      console.log('📋 Premières réparations:');
      repairs.slice(0, 3).forEach((repair, index) => {
        console.log(`  ${index + 1}. Réparation #${repair.repair_number} - Client ID: ${repair.client_id} - Prix: ${repair.total_price}€`);
      });
    }
    console.log('');

    // 4. Vérifier la correspondance clients-réparations
    console.log('4️⃣ Vérification de la correspondance clients-réparations...');
    
    if (clients.length === 0) {
      console.log('⚠️ Aucun client trouvé - le top 10 sera vide');
      return;
    }
    
    if (repairs.length === 0) {
      console.log('⚠️ Aucune réparation trouvée - le top 10 sera vide');
      return;
    }

    // Créer un map des clients pour un accès rapide
    const clientMap = new Map();
    clients.forEach(client => {
      clientMap.set(client.id, client);
    });

    // Analyser les réparations
    const clientRepairs = new Map();
    let repairsWithValidClients = 0;
    let repairsWithInvalidClients = 0;

    repairs.forEach(repair => {
      const client = clientMap.get(repair.client_id);
      if (client) {
        repairsWithValidClients++;
        const existing = clientRepairs.get(client.id);
        if (existing) {
          existing.repairs += 1;
          existing.revenue += parseFloat(repair.total_price || 0);
        } else {
          clientRepairs.set(client.id, {
            client,
            repairs: 1,
            revenue: parseFloat(repair.total_price || 0)
          });
        }
      } else {
        repairsWithInvalidClients++;
        console.log(`⚠️ Réparation #${repair.repair_number} référence un client inexistant: ${repair.client_id}`);
      }
    });

    console.log(`✅ ${repairsWithValidClients} réparations avec clients valides`);
    console.log(`⚠️ ${repairsWithInvalidClients} réparations avec clients invalides`);
    console.log('');

    // 5. Calculer le top 10 des clients
    console.log('5️⃣ Calcul du top 10 des clients...');
    
    const topClients = Array.from(clientRepairs.values())
      .sort((a, b) => b.repairs - a.repairs)
      .slice(0, 10);

    if (topClients.length === 0) {
      console.log('❌ Aucun client avec des réparations trouvé');
      console.log('💡 Causes possibles:');
      console.log('   - Les réparations ne sont pas liées aux clients');
      console.log('   - Les client_id dans les réparations sont incorrects');
      console.log('   - Problème d\'isolation des données');
      return;
    }

    console.log(`✅ Top ${topClients.length} clients calculé:`);
    topClients.forEach((item, index) => {
      console.log(`  ${index + 1}. ${item.client.first_name} ${item.client.last_name}`);
      console.log(`     📊 Réparations: ${item.repairs}`);
      console.log(`     💰 CA: ${item.revenue.toFixed(2)}€`);
      console.log(`     🆔 Client ID: ${item.client.id}`);
    });
    console.log('');

    // 6. Vérifier les données dans le store (simulation)
    console.log('6️⃣ Simulation du calcul dans les statistiques...');
    
    // Simuler la logique du composant Statistics
    const simulatedTopClients = [];
    const clientRepairsSim = new Map();
    
    repairs.forEach(repair => {
      const client = clientMap.get(repair.client_id);
      if (client) {
        const existing = clientRepairsSim.get(client.id);
        if (existing) {
          existing.repairs += 1;
          existing.revenue += parseFloat(repair.total_price || 0);
        } else {
          clientRepairsSim.set(client.id, {
            client: {
              id: client.id,
              firstName: client.first_name,
              lastName: client.last_name,
              email: client.email
            },
            repairs: 1,
            revenue: parseFloat(repair.total_price || 0)
          });
        }
      }
    });
    
    const simulatedResult = Array.from(clientRepairsSim.values())
      .sort((a, b) => b.repairs - a.repairs)
      .slice(0, 10);

    console.log(`✅ Simulation réussie: ${simulatedResult.length} clients dans le top 10`);
    if (simulatedResult.length > 0) {
      console.log('📋 Résultat simulé:');
      simulatedResult.forEach((item, index) => {
        console.log(`  ${index + 1}. ${item.client.firstName} ${item.client.lastName} (${item.repairs} réparations, ${item.revenue.toFixed(2)}€)`);
      });
    }
    console.log('');

    // 7. Recommandations
    console.log('7️⃣ Recommandations...');
    
    if (repairsWithInvalidClients > 0) {
      console.log('🔧 Actions recommandées:');
      console.log('   1. Vérifier les client_id dans la table repairs');
      console.log('   2. Nettoyer les données orphelines');
      console.log('   3. S\'assurer que les réparations sont créées avec les bons client_id');
    }
    
    if (topClients.length === 0 && repairs.length > 0) {
      console.log('🔧 Actions recommandées:');
      console.log('   1. Vérifier l\'isolation des données (RLS)');
      console.log('   2. S\'assurer que les clients et réparations appartiennent au même utilisateur');
      console.log('   3. Vérifier les triggers de création des réparations');
    }
    
    if (topClients.length > 0) {
      console.log('✅ Le top 10 des clients devrait fonctionner correctement');
      console.log('💡 Si le problème persiste, vérifier:');
      console.log('   1. Le rechargement des données dans l\'interface');
      console.log('   2. Les erreurs JavaScript dans la console');
      console.log('   3. La synchronisation entre le store et les services');
    }

  } catch (error) {
    console.error('💥 Erreur lors du diagnostic:', error);
  }
}

// Exécuter le diagnostic
diagnosticTopClients().then(() => {
  console.log('\n🏁 Diagnostic terminé');
  process.exit(0);
}).catch(error => {
  console.error('💥 Erreur fatale:', error);
  process.exit(1);
});
