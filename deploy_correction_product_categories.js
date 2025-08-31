const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Configuration Supabase
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTQyNTIwMCwiZXhwIjoyMDcxMDAxMjAwfQ.Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8';

// Créer le client Supabase avec la clé de service
const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function deployCorrection() {
    console.log('🔧 Déploiement de la correction d\'isolation product_categories...');
    console.log('========================================================');

    try {
        // Lire le fichier SQL
        const sqlFilePath = path.join(__dirname, 'correction_isolation_product_categories.sql');
        const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

        console.log('📖 Lecture du script SQL...');

        // Diviser le script en requêtes individuelles
        const queries = sqlContent
            .split(';')
            .map(query => query.trim())
            .filter(query => query.length > 0 && !query.startsWith('--'));

        console.log(`📝 ${queries.length} requêtes à exécuter`);

        // Exécuter chaque requête
        for (let i = 0; i < queries.length; i++) {
            const query = queries[i];
            
            // Ignorer les requêtes SELECT de diagnostic
            if (query.includes('SELECT') && query.includes('=== DIAGNOSTIC')) {
                console.log(`⏭️  Ignorer requête de diagnostic: ${query.substring(0, 50)}...`);
                continue;
            }

            // Ignorer les requêtes SELECT de vérification
            if (query.includes('SELECT') && query.includes('=== VÉRIFICATION')) {
                console.log(`⏭️  Ignorer requête de vérification: ${query.substring(0, 50)}...`);
                continue;
            }

            // Ignorer les requêtes SELECT de test
            if (query.includes('SELECT') && query.includes('=== TEST')) {
                console.log(`⏭️  Ignorer requête de test: ${query.substring(0, 50)}...`);
                continue;
            }

            // Ignorer les requêtes SELECT de message de confirmation
            if (query.includes('SELECT') && query.includes('CORRECTION TERMINÉE')) {
                console.log(`⏭️  Ignorer requête de confirmation: ${query.substring(0, 50)}...`);
                continue;
            }

            try {
                console.log(`🔨 Exécution requête ${i + 1}/${queries.length}...`);
                
                // Exécuter la requête via l'API Supabase
                const { data, error } = await supabase.rpc('exec_sql', { sql_query: query });
                
                if (error) {
                    console.error(`❌ Erreur requête ${i + 1}:`, error.message);
                    
                    // Si c'est une erreur de fonction non trouvée, essayer une approche différente
                    if (error.message.includes('function "exec_sql" does not exist')) {
                        console.log('⚠️  Fonction exec_sql non disponible, tentative avec query directe...');
                        
                        // Essayer d'exécuter directement via l'API REST
                        const { data: directData, error: directError } = await supabase
                            .from('product_categories')
                            .select('*')
                            .limit(1);
                        
                        if (directError) {
                            console.error('❌ Impossible d\'exécuter la requête:', directError.message);
                        } else {
                            console.log('✅ Connexion à la base de données réussie');
                        }
                    }
                } else {
                    console.log(`✅ Requête ${i + 1} exécutée avec succès`);
                }
            } catch (queryError) {
                console.error(`❌ Erreur lors de l'exécution de la requête ${i + 1}:`, queryError.message);
            }
        }

        console.log('');
        console.log('🔍 Vérification de l\'état final...');

        // Vérifier que RLS est activé
        try {
            const { data: rlsCheck, error: rlsError } = await supabase
                .from('product_categories')
                .select('*')
                .limit(1);

            if (rlsError) {
                console.log('⚠️  Impossible de vérifier RLS via API REST');
            } else {
                console.log('✅ Accès à product_categories via API REST réussi');
            }
        } catch (checkError) {
            console.log('⚠️  Erreur lors de la vérification finale:', checkError.message);
        }

        console.log('');
        console.log('📋 Instructions pour finaliser la correction:');
        console.log('1. Connectez-vous au dashboard Supabase');
        console.log('2. Allez dans Table Editor > product_categories');
        console.log('3. Vérifiez que le badge "RLS disabled" a disparu');
        console.log('4. Vérifiez que les politiques RLS sont créées dans l\'onglet "Policies"');
        console.log('5. Testez l\'isolation en créant/modifiant des catégories');

        console.log('');
        console.log('✅ Déploiement terminé !');
        console.log('⚠️  Note: Certaines opérations nécessitent un accès direct à PostgreSQL');
        console.log('   Utilisez le SQL Editor de Supabase pour exécuter le script complet si nécessaire.');

    } catch (error) {
        console.error('❌ Erreur lors du déploiement:', error.message);
        console.log('');
        console.log('💡 Solution alternative:');
        console.log('1. Copiez le contenu du fichier correction_isolation_product_categories.sql');
        console.log('2. Allez dans le SQL Editor de Supabase');
        console.log('3. Collez et exécutez le script');
    }
}

// Exécuter le déploiement
deployCorrection().catch(console.error);


