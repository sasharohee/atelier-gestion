// =====================================================
// DÉPLOIEMENT DES CATÉGORIES PAR DÉFAUT
// =====================================================
// Date: 2025-01-23
// Objectif: Déployer automatiquement la création des catégories par défaut
// =====================================================

import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
import path from 'path';

// Configuration Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function deployDefaultCategories() {
    console.log('🚀 Déploiement des catégories par défaut...');
    
    try {
        // 1. Lire le fichier SQL
        const sqlFilePath = path.join(__dirname, 'creation_categories_defaut_utilisateur.sql');
        const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
        
        console.log('📖 Fichier SQL lu:', sqlFilePath);
        
        // 2. Exécuter le script SQL
        console.log('🔧 Exécution du script SQL...');
        
        const { data, error } = await supabase.rpc('exec_sql', {
            sql_query: sqlContent
        });
        
        if (error) {
            // Si exec_sql n'existe pas, on utilise une approche alternative
            console.log('⚠️ exec_sql non disponible, utilisation de l\'approche alternative...');
            
            // Créer les catégories pour l'utilisateur actuel
            await createCategoriesForCurrentUser();
            
        } else {
            console.log('✅ Script SQL exécuté avec succès');
        }
        
        // 3. Vérifier le résultat
        await verifyDefaultCategories();
        
    } catch (error) {
        console.error('❌ Erreur lors du déploiement:', error.message);
        
        // Fallback : créer les catégories pour l'utilisateur actuel
        console.log('🔄 Tentative de création des catégories pour l\'utilisateur actuel...');
        await createCategoriesForCurrentUser();
    }
}

async function createCategoriesForCurrentUser() {
    try {
        // Récupérer l'utilisateur actuel
        const { data: { user }, error: userError } = await supabase.auth.getUser();
        
        if (userError || !user) {
            throw new Error('Utilisateur non connecté');
        }
        
        console.log(`👤 Création des catégories pour l'utilisateur: ${user.email}`);
        
        // Créer les 4 catégories par défaut
        const defaultCategories = [
            {
                name: 'Smartphones',
                description: 'Téléphones mobiles et smartphones',
                icon: 'smartphone',
                is_active: true
            },
            {
                name: 'Tablettes',
                description: 'Tablettes tactiles',
                icon: 'tablet',
                is_active: true
            },
            {
                name: 'Ordinateurs portables',
                description: 'Laptops et notebooks',
                icon: 'laptop',
                is_active: true
            },
            {
                name: 'Ordinateurs fixes',
                description: 'PC de bureau et stations de travail',
                icon: 'desktop',
                is_active: true
            }
        ];
        
        // Vérifier quelles catégories existent déjà
        const { data: existingCategories, error: fetchError } = await supabase
            .from('product_categories')
            .select('name')
            .eq('user_id', user.id);
            
        if (fetchError) {
            throw new Error(`Erreur lors de la récupération des catégories: ${fetchError.message}`);
        }
        
        const existingNames = existingCategories.map(cat => cat.name);
        const categoriesToCreate = defaultCategories.filter(cat => !existingNames.includes(cat.name));
        
        if (categoriesToCreate.length === 0) {
            console.log('✅ Toutes les catégories par défaut existent déjà');
            return;
        }
        
        // Créer les catégories manquantes
        const { data: createdCategories, error: createError } = await supabase
            .from('product_categories')
            .insert(categoriesToCreate.map(cat => ({
                ...cat,
                user_id: user.id
            })))
            .select();
            
        if (createError) {
            throw new Error(`Erreur lors de la création des catégories: ${createError.message}`);
        }
        
        console.log(`✅ ${createdCategories.length} catégories créées:`, createdCategories.map(c => c.name));
        
    } catch (error) {
        console.error('❌ Erreur lors de la création des catégories:', error.message);
        throw error;
    }
}

async function verifyDefaultCategories() {
    console.log('\n🔍 Vérification des catégories par défaut...');
    
    try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
            console.log('⚠️ Aucun utilisateur connecté pour la vérification');
            return;
        }
        
        // Récupérer toutes les catégories de l'utilisateur
        const { data: categories, error } = await supabase
            .from('product_categories')
            .select('*')
            .eq('user_id', user.id)
            .order('name');
            
        if (error) {
            throw new Error(`Erreur lors de la vérification: ${error.message}`);
        }
        
        console.log(`📊 Catégories trouvées pour ${user.email}:`);
        console.table(categories);
        
        // Vérifier que les 4 catégories par défaut sont présentes
        const defaultNames = ['Smartphones', 'Tablettes', 'Ordinateurs portables', 'Ordinateurs fixes'];
        const foundDefaults = defaultNames.filter(name => 
            categories.some(cat => cat.name === name)
        );
        
        if (foundDefaults.length === defaultNames.length) {
            console.log('✅ Toutes les catégories par défaut sont présentes!');
        } else {
            console.log('⚠️ Catégories manquantes:', defaultNames.filter(name => !foundDefaults.includes(name)));
        }
        
    } catch (error) {
        console.error('❌ Erreur lors de la vérification:', error.message);
    }
}

// Fonction principale
async function main() {
    console.log('🔧 Déploiement des catégories par défaut');
    console.log('==========================================');
    
    try {
        await deployDefaultCategories();
        console.log('\n🎉 Déploiement terminé avec succès!');
        
    } catch (error) {
        console.error('\n💥 Déploiement échoué:', error.message);
        process.exit(1);
    }
}

// Exécuter le script
if (typeof window === 'undefined') {
    // Node.js environment
    main().catch(console.error);
} else {
    // Browser environment
    window.deployDefaultCategories = deployDefaultCategories;
    console.log('🌐 Script chargé dans le navigateur. Utilisez: window.deployDefaultCategories()');
}

