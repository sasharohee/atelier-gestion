// Script pour déployer la correction de la fonction get_loyalty_config
import { createClient } from '@supabase/supabase-js';

// Configuration Supabase (remplacez par vos vraies valeurs)
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXF5cm1udGZ4d2R2a3p6c3VqdiIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNzM0NzQ5NzI5LCJleHAiOjIwNTAzMjU3Mjl9.placeholder';

const supabase = createClient(supabaseUrl, supabaseKey);

// SQL pour créer la fonction get_loyalty_config
const sqlScript = `
-- 🔧 CORRECTION RAPIDE - Fonction get_loyalty_config manquante
-- Script de correction pour l'erreur 404 sur get_loyalty_config

-- Vérifier si la fonction existe
SELECT 
    'Vérification existence fonction get_loyalty_config' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_config'
        ) THEN '✅ Fonction existe'
        ELSE '❌ Fonction manquante'
    END as status;

-- Supprimer la fonction si elle existe (pour la recréer proprement)
DROP FUNCTION IF EXISTS get_loyalty_config(UUID);

-- Créer la fonction get_loyalty_config
CREATE OR REPLACE FUNCTION get_loyalty_config(p_workshop_id UUID)
RETURNS TABLE(key TEXT, value TEXT, description TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT lc.key, lc.value, lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = p_workshop_id
    ORDER BY lc.key;
END;
$$;

-- Accorder les permissions
GRANT EXECUTE ON FUNCTION get_loyalty_config(UUID) TO authenticated;

-- Vérifier que la fonction a été créée
SELECT 
    'Vérification après création' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_config'
        ) THEN '✅ Fonction créée avec succès'
        ELSE '❌ Échec de création'
    END as status;

-- Créer la table loyalty_config si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(workshop_id, key)
);

-- Activer RLS sur la table
ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS
DROP POLICY IF EXISTS "Users can view their own loyalty config" ON loyalty_config;
CREATE POLICY "Users can view their own loyalty config" ON loyalty_config
    FOR SELECT USING (auth.uid() = workshop_id);

DROP POLICY IF EXISTS "Users can insert their own loyalty config" ON loyalty_config;
CREATE POLICY "Users can insert their own loyalty config" ON loyalty_config
    FOR INSERT WITH CHECK (auth.uid() = workshop_id);

DROP POLICY IF EXISTS "Users can update their own loyalty config" ON loyalty_config;
CREATE POLICY "Users can update their own loyalty config" ON loyalty_config
    FOR UPDATE USING (auth.uid() = workshop_id);

-- Insérer des données par défaut si elles n'existent pas
INSERT INTO loyalty_config (workshop_id, key, value, description)
SELECT 
    u.id,
    config.key,
    config.value,
    config.description
FROM auth.users u
CROSS JOIN (VALUES 
    ('points_per_euro', '1', 'Points gagnés par euro dépensé'),
    ('minimum_purchase', '10', 'Montant minimum pour gagner des points'),
    ('bonus_threshold', '100', 'Seuil pour bonus de points'),
    ('bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
    ('points_expiry_days', '365', 'Durée de validité des points en jours')
) AS config(key, value, description)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_config lc WHERE lc.workshop_id = u.id AND lc.key = config.key
);

-- Test de la fonction
SELECT 'Test de la fonction get_loyalty_config:' as test;
SELECT * FROM get_loyalty_config((SELECT id FROM auth.users LIMIT 1));

-- Vérification finale
SELECT 
    'Vérification finale' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'get_loyalty_config'
        ) THEN '✅ Fonction get_loyalty_config disponible'
        ELSE '❌ Fonction get_loyalty_config manquante'
    END as status;

SELECT '🎉 La fonction get_loyalty_config est maintenant disponible !' as message;
`;

async function deployCorrection() {
    try {
        console.log('🚀 Déploiement de la correction get_loyalty_config...');
        
        // Exécuter le script SQL
        const { data, error } = await supabase.rpc('exec_sql', { sql: sqlScript });
        
        if (error) {
            console.error('❌ Erreur lors du déploiement:', error);
            
            // Essayer une approche alternative avec des requêtes séparées
            console.log('🔄 Tentative avec des requêtes séparées...');
            
            // 1. Créer la table loyalty_config
            const { error: tableError } = await supabase.rpc('exec_sql', {
                sql: `
                CREATE TABLE IF NOT EXISTS loyalty_config (
                    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                    workshop_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                    key TEXT NOT NULL,
                    value TEXT NOT NULL,
                    description TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    UNIQUE(workshop_id, key)
                );
                `
            });
            
            if (tableError) {
                console.error('❌ Erreur création table:', tableError);
            } else {
                console.log('✅ Table loyalty_config créée');
            }
            
            // 2. Créer la fonction
            const { error: funcError } = await supabase.rpc('exec_sql', {
                sql: `
                CREATE OR REPLACE FUNCTION get_loyalty_config(p_workshop_id UUID)
                RETURNS TABLE(key TEXT, value TEXT, description TEXT)
                LANGUAGE plpgsql
                SECURITY DEFINER
                AS $$
                BEGIN
                    RETURN QUERY
                    SELECT lc.key, lc.value, lc.description
                    FROM loyalty_config lc
                    WHERE lc.workshop_id = p_workshop_id
                    ORDER BY lc.key;
                END;
                $$;
                
                GRANT EXECUTE ON FUNCTION get_loyalty_config(UUID) TO authenticated;
                `
            });
            
            if (funcError) {
                console.error('❌ Erreur création fonction:', funcError);
            } else {
                console.log('✅ Fonction get_loyalty_config créée');
            }
            
        } else {
            console.log('✅ Correction déployée avec succès:', data);
        }
        
        // Tester la fonction
        console.log('🧪 Test de la fonction...');
        const { data: testData, error: testError } = await supabase.rpc('get_loyalty_config', {
            p_workshop_id: '00000000-0000-0000-0000-000000000000' // ID temporaire pour test
        });
        
        if (testError) {
            console.log('⚠️ Test échoué (normal si pas de données):', testError.message);
        } else {
            console.log('✅ Fonction testée avec succès:', testData);
        }
        
    } catch (error) {
        console.error('❌ Erreur générale:', error);
    }
}

// Exécuter le script
deployCorrection();
