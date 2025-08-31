const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Configuration Supabase
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceKey) {
    console.error('❌ Erreur: SUPABASE_SERVICE_ROLE_KEY non définie');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function deployCorrectionValidationEmail() {
    console.log('🚀 Déploiement de la correction de validation d\'email...');
    
    try {
        // Lire le fichier SQL de correction
        const sqlFile = path.join(__dirname, 'correction_validation_email_clients.sql');
        const sqlContent = fs.readFileSync(sqlFile, 'utf8');
        
        console.log('📖 Lecture du fichier SQL de correction...');
        
        // Exécuter le script SQL
        console.log('⚡ Exécution du script SQL...');
        const { data, error } = await supabase.rpc('exec_sql', { sql: sqlContent });
        
        if (error) {
            console.error('❌ Erreur lors de l\'exécution SQL:', error);
            return;
        }
        
        console.log('✅ Correction de validation d\'email déployée avec succès!');
        console.log('📊 Résultats:', data);
        
        // Tester la création d'un client avec un email court
        console.log('\n🧪 Test de création d\'un client avec email court...');
        
        const testResult = await supabase
            .from('clients')
            .insert({
                first_name: 'Test',
                last_name: 'Email',
                email: 'test@example.u',
                phone: '123456789',
                address: 'Adresse de test',
                notes: 'Client de test pour validation email',
                user_id: (await supabase.auth.getUser()).data.user?.id
            })
            .select();
        
        if (testResult.error) {
            console.error('❌ Erreur lors du test:', testResult.error);
        } else {
            console.log('✅ Test réussi! Client créé avec email court');
            console.log('📋 Client créé:', testResult.data[0]);
            
            // Nettoyer le client de test
            await supabase
                .from('clients')
                .delete()
                .eq('email', 'test@example.u');
            
            console.log('🧹 Client de test supprimé');
        }
        
    } catch (error) {
        console.error('💥 Erreur lors du déploiement:', error);
    }
}

// Fonction alternative si exec_sql n'existe pas
async function deployCorrectionAlternative() {
    console.log('🔄 Utilisation de la méthode alternative...');
    
    try {
        // Supprimer les triggers existants
        console.log('🗑️ Suppression des triggers existants...');
        
        await supabase.rpc('exec_sql', { 
            sql: 'DROP TRIGGER IF EXISTS trigger_prevent_duplicate_emails ON clients;' 
        });
        
        await supabase.rpc('exec_sql', { 
            sql: 'DROP TRIGGER IF EXISTS trigger_validate_client_email ON clients;' 
        });
        
        // Créer la nouvelle fonction de validation
        console.log('🔧 Création de la nouvelle fonction de validation...');
        
        const validationFunction = `
            CREATE OR REPLACE FUNCTION validate_client_email_format()
            RETURNS TRIGGER AS $$
            BEGIN
                IF NEW.email IS NOT NULL AND TRIM(NEW.email) != '' THEN
                    IF NOT (NEW.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,}$') THEN
                        RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
                    END IF;
                    
                    IF LENGTH(NEW.email) < 5 THEN
                        RAISE EXCEPTION 'Email trop court: %', NEW.email;
                    END IF;
                    
                    IF POSITION('@' IN NEW.email) = 0 OR POSITION('.' IN SUBSTRING(NEW.email FROM POSITION('@' IN NEW.email))) = 0 THEN
                        RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
                    END IF;
                END IF;
                
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        `;
        
        await supabase.rpc('exec_sql', { sql: validationFunction });
        
        // Créer le nouveau trigger
        console.log('⚡ Création du nouveau trigger...');
        
        const triggerSQL = `
            CREATE TRIGGER trigger_validate_client_email_format
                BEFORE INSERT OR UPDATE ON clients
                FOR EACH ROW
                EXECUTE FUNCTION validate_client_email_format();
        `;
        
        await supabase.rpc('exec_sql', { sql: triggerSQL });
        
        console.log('✅ Correction alternative déployée avec succès!');
        
    } catch (error) {
        console.error('❌ Erreur lors du déploiement alternatif:', error);
    }
}

// Exécuter le déploiement
async function main() {
    try {
        await deployCorrectionValidationEmail();
    } catch (error) {
        console.log('🔄 Tentative avec la méthode alternative...');
        await deployCorrectionAlternative();
    }
}

main().catch(console.error);

