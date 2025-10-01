const { createClient } = require('@supabase/supabase-js');

// Configuration de production
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

const supabase = createClient(supabaseUrl, supabaseKey);

async function createBrandWithCategoriesView() {
  console.log('🔄 Création de la vue brand_with_categories...');
  
  const sql = `
    -- Supprimer la vue si elle existe déjà
    DROP VIEW IF EXISTS public.brand_with_categories CASCADE;

    -- Créer la vue brand_with_categories
    CREATE VIEW public.brand_with_categories AS
    SELECT 
        db.id,
        db.name,
        db.description,
        db.logo,
        db.is_active,
        db.user_id,
        db.created_by,
        db.updated_by,
        db.created_at,
        db.updated_at,
        COALESCE(
            JSON_AGG(
                JSON_BUILD_OBJECT(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description
                )
            ) FILTER (WHERE dc.id IS NOT NULL),
            '[]'::json
        ) as categories
    FROM public.device_brands db
    LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
    GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.updated_by, db.created_at, db.updated_at;

    -- Configurer la sécurité de la vue
    ALTER VIEW public.brand_with_categories SET (security_invoker = true);
  `;

  try {
    const { data, error } = await supabase.rpc('exec_sql', { sql_query: sql });
    
    if (error) {
      console.error('❌ Erreur lors de la création de la vue:', error);
      return false;
    }
    
    console.log('✅ Vue brand_with_categories créée avec succès');
    
    // Tester la vue
    const { data: testData, error: testError } = await supabase
      .from('brand_with_categories')
      .select('*')
      .limit(1);
    
    if (testError) {
      console.error('❌ Erreur lors du test de la vue:', testError);
      return false;
    }
    
    console.log('✅ Vue testée avec succès');
    console.log('📊 Données de test:', testData);
    
    return true;
  } catch (error) {
    console.error('❌ Erreur inattendue:', error);
    return false;
  }
}

// Fonction alternative utilisant l'API REST
async function createViewAlternative() {
  console.log('🔄 Tentative alternative de création de la vue...');
  
  const sql = `
    DROP VIEW IF EXISTS public.brand_with_categories CASCADE;
    CREATE VIEW public.brand_with_categories AS
    SELECT 
        db.id,
        db.name,
        db.description,
        db.logo,
        db.is_active,
        db.user_id,
        db.created_by,
        db.updated_by,
        db.created_at,
        db.updated_at,
        COALESCE(
            JSON_AGG(
                JSON_BUILD_OBJECT(
                    'id', dc.id,
                    'name', dc.name,
                    'description', dc.description
                )
            ) FILTER (WHERE dc.id IS NOT NULL),
            '[]'::json
        ) as categories
    FROM public.device_brands db
    LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
    LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
    GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.updated_by, db.created_at, db.updated_at;
  `;

  try {
    // Utiliser l'API REST directement
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec_sql`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseKey}`,
        'apikey': supabaseKey
      },
      body: JSON.stringify({ sql_query: sql })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Erreur API:', response.status, errorText);
      return false;
    }

    console.log('✅ Vue créée via API REST');
    return true;
  } catch (error) {
    console.error('❌ Erreur lors de l\'appel API:', error);
    return false;
  }
}

async function main() {
  console.log('🚀 Début de la création de la vue brand_with_categories');
  console.log('🔗 Connexion à:', supabaseUrl);
  
  // Essayer la première méthode
  const success = await createBrandWithCategoriesView();
  
  if (!success) {
    console.log('🔄 Tentative avec méthode alternative...');
    await createViewAlternative();
  }
  
  console.log('✅ Processus terminé');
}

main().catch(console.error);
