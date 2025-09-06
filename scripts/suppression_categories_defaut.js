// =====================================================
// SUPPRESSION DES CATÉGORIES PAR DÉFAUT
// =====================================================
// Date: 2025-01-23
// Objectif: Supprimer les catégories d'appareils par défaut via Supabase
// =====================================================

import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (à adapter selon votre projet)
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function supprimerCategoriesDefaut() {
    console.log('🚀 Début de la suppression des catégories par défaut...');
    
    try {
        // 1. Afficher les catégories actuelles
        console.log('\n📋 Catégories actuelles:');
        const { data: categoriesActuelles, error: errorLecture } = await supabase
            .from('product_categories')
            .select('id, name, description, is_active, created_at')
            .order('name');
            
        if (errorLecture) {
            throw new Error(`Erreur lors de la lecture: ${errorLecture.message}`);
        }
        
        console.table(categoriesActuelles);
        
        // 2. Supprimer les catégories par défaut
        console.log('\n🗑️ Suppression des catégories par défaut...');
        
        const categoriesASupprimer = [
            'Smartphones',
            'Tablettes', 
            'Ordinateurs portables',
            'Ordinateurs fixes'
        ];
        
        const { data: suppression, error: errorSuppression } = await supabase
            .from('product_categories')
            .delete()
            .in('name', categoriesASupprimer)
            .select();
            
        if (errorSuppression) {
            throw new Error(`Erreur lors de la suppression: ${errorSuppression.message}`);
        }
        
        console.log(`✅ ${suppression.length} catégories supprimées:`, suppression);
        
        // 3. Vérifier la suppression
        console.log('\n🔍 Vérification de la suppression...');
        const { data: verification, error: errorVerification } = await supabase
            .from('product_categories')
            .select('id, name')
            .in('name', categoriesASupprimer);
            
        if (errorVerification) {
            throw new Error(`Erreur lors de la vérification: ${errorVerification.message}`);
        }
        
        if (verification.length === 0) {
            console.log('✅ Toutes les catégories par défaut ont été supprimées avec succès!');
        } else {
            console.log('⚠️ Certaines catégories n\'ont pas été supprimées:', verification);
        }
        
        // 4. Afficher les catégories restantes
        console.log('\n📋 Catégories restantes:');
        const { data: categoriesRestantes, error: errorRestantes } = await supabase
            .from('product_categories')
            .select('id, name, description, is_active, created_at')
            .order('name');
            
        if (errorRestantes) {
            throw new Error(`Erreur lors de la lecture des catégories restantes: ${errorRestantes.message}`);
        }
        
        console.table(categoriesRestantes);
        
        // 5. Statistiques finales
        console.log('\n📊 Statistiques finales:');
        const totalRestantes = categoriesRestantes.length;
        const actives = categoriesRestantes.filter(cat => cat.is_active).length;
        const inactives = totalRestantes - actives;
        
        console.log(`Total catégories restantes: ${totalRestantes}`);
        console.log(`Catégories actives: ${actives}`);
        console.log(`Catégories inactives: ${inactives}`);
        
        console.log('\n🎉 Suppression terminée avec succès!');
        
    } catch (error) {
        console.error('❌ Erreur lors de la suppression:', error.message);
        console.error('Stack trace:', error.stack);
    }
}

// Fonction pour exécuter le script
async function main() {
    console.log('🔧 Script de suppression des catégories par défaut');
    console.log('================================================');
    
    // Vérifier la connexion Supabase
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
        console.error('❌ Erreur d\'authentification. Veuillez vous connecter.');
        return;
    }
    
    console.log(`👤 Utilisateur connecté: ${user.email}`);
    
    // Exécuter la suppression
    await supprimerCategoriesDefaut();
}

// Exécuter le script si appelé directement
if (typeof window === 'undefined') {
    // Node.js environment
    main().catch(console.error);
} else {
    // Browser environment
    window.supprimerCategoriesDefaut = supprimerCategoriesDefaut;
    console.log('🌐 Script chargé dans le navigateur. Utilisez: window.supprimerCategoriesDefaut()');
}

