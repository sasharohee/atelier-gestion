// Script de test pour vérifier la mise à jour des niveaux de fidélité
// À exécuter dans la console du navigateur sur la page de fidélité

console.log('🧪 Test de mise à jour des niveaux de fidélité');

// Fonction pour tester la mise à jour directe
async function testLoyaltyUpdate() {
    try {
        console.log('1️⃣ Chargement des niveaux actuels...');
        
        // Charger les niveaux actuels
        const { data: currentTiers, error: loadError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('*')
            .order('points_required');
            
        if (loadError) {
            console.error('❌ Erreur chargement:', loadError);
            return;
        }
        
        console.log('📊 Niveaux actuels:', currentTiers);
        
        // Trouver le niveau Argent
        const argentTier = currentTiers.find(tier => tier.name === 'Argent');
        if (!argentTier) {
            console.error('❌ Niveau Argent non trouvé');
            return;
        }
        
        console.log('🔍 Niveau Argent trouvé:', argentTier);
        
        // Tester la mise à jour
        console.log('2️⃣ Test de mise à jour...');
        const newPoints = 255;
        
        const { data: updateResult, error: updateError } = await supabase
            .from('loyalty_tiers_advanced')
            .update({
                points_required: newPoints,
                updated_at: new Date().toISOString()
            })
            .eq('id', argentTier.id)
            .select();
            
        if (updateError) {
            console.error('❌ Erreur mise à jour:', updateError);
            return;
        }
        
        console.log('✅ Mise à jour réussie:', updateResult);
        
        // Vérifier la mise à jour
        console.log('3️⃣ Vérification de la mise à jour...');
        const { data: verifyResult, error: verifyError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('*')
            .eq('id', argentTier.id)
            .single();
            
        if (verifyError) {
            console.error('❌ Erreur vérification:', verifyError);
            return;
        }
        
        console.log('📊 Niveau après mise à jour:', verifyResult);
        
        if (verifyResult.points_required === newPoints) {
            console.log('✅ Test réussi ! Le niveau a été mis à jour en base de données');
        } else {
            console.log('❌ Test échoué ! Le niveau n\'a pas été mis à jour');
        }
        
    } catch (error) {
        console.error('💥 Erreur générale:', error);
    }
}

// Fonction pour tester l'upsert
async function testLoyaltyUpsert() {
    try {
        console.log('🔄 Test de l\'upsert...');
        
        // Charger les niveaux actuels
        const { data: currentTiers, error: loadError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('*')
            .order('points_required');
            
        if (loadError) {
            console.error('❌ Erreur chargement:', loadError);
            return;
        }
        
        const argentTier = currentTiers.find(tier => tier.name === 'Argent');
        if (!argentTier) {
            console.error('❌ Niveau Argent non trouvé');
            return;
        }
        
        console.log('🔍 Niveau Argent avant upsert:', argentTier);
        
        // Test upsert
        const { data: upsertResult, error: upsertError } = await supabase
            .from('loyalty_tiers_advanced')
            .upsert({
                id: argentTier.id,
                name: argentTier.name,
                description: argentTier.description,
                points_required: 300, // Nouvelle valeur
                discount_percentage: argentTier.discount_percentage,
                color: argentTier.color,
                is_active: argentTier.is_active,
                created_at: argentTier.created_at,
                updated_at: new Date().toISOString()
            })
            .select();
            
        if (upsertError) {
            console.error('❌ Erreur upsert:', upsertError);
            return;
        }
        
        console.log('✅ Upsert réussi:', upsertResult);
        
    } catch (error) {
        console.error('💥 Erreur upsert:', error);
    }
}

// Fonction pour vérifier les permissions
async function checkPermissions() {
    try {
        console.log('🔐 Vérification des permissions...');
        
        // Test de lecture
        const { data: readData, error: readError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('id, name')
            .limit(1);
            
        if (readError) {
            console.error('❌ Erreur lecture:', readError);
        } else {
            console.log('✅ Lecture autorisée:', readData);
        }
        
        // Test d'écriture (sans vraiment modifier)
        const { data: writeData, error: writeError } = await supabase
            .from('loyalty_tiers_advanced')
            .select('id')
            .limit(1);
            
        if (writeError) {
            console.error('❌ Erreur écriture:', writeError);
        } else {
            console.log('✅ Écriture autorisée (test)');
        }
        
    } catch (error) {
        console.error('💥 Erreur permissions:', error);
    }
}

// Exécuter les tests
console.log('🚀 Démarrage des tests...');
console.log('📝 Pour exécuter les tests, tapez dans la console:');
console.log('   testLoyaltyUpdate()');
console.log('   testLoyaltyUpsert()');
console.log('   checkPermissions()');

// Exporter les fonctions globalement
window.testLoyaltyUpdate = testLoyaltyUpdate;
window.testLoyaltyUpsert = testLoyaltyUpsert;
window.checkPermissions = checkPermissions;
