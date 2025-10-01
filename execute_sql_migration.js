const { createClient } = require('@supabase/supabase-js');

// Configuration de production
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

const supabase = createClient(supabaseUrl, supabaseKey);

async function executeSQLMigration() {
  console.log('🔄 Exécution de la migration SQL...');
  
  // Lire le fichier SQL
  const fs = require('fs');
  const path = require('path');
  
  try {
    const sqlContent = fs.readFileSync(path.join(__dirname, 'fix_brand_view_direct.sql'), 'utf8');
    console.log('📄 Contenu SQL lu:', sqlContent.substring(0, 200) + '...');
    
    // Diviser le SQL en requêtes individuelles
    const queries = sqlContent
      .split(';')
      .map(q => q.trim())
      .filter(q => q.length > 0 && !q.startsWith('--'));
    
    console.log(`📊 ${queries.length} requêtes à exécuter`);
    
    for (let i = 0; i < queries.length; i++) {
      const query = queries[i];
      if (query.trim()) {
        console.log(`🔄 Exécution de la requête ${i + 1}/${queries.length}...`);
        console.log(`📝 Requête: ${query.substring(0, 100)}...`);
        
        try {
          // Utiliser l'API REST pour exécuter le SQL
          const response = await fetch(`${supabaseUrl}/rest/v1/rpc/exec`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${supabaseKey}`,
              'apikey': supabaseKey
            },
            body: JSON.stringify({ sql: query })
          });

          if (!response.ok) {
            const errorText = await response.text();
            console.error(`❌ Erreur requête ${i + 1}:`, response.status, errorText);
            continue;
          }
          
          const result = await response.json();
          console.log(`✅ Requête ${i + 1} exécutée avec succès`);
          if (result && result.length > 0) {
            console.log(`📊 Résultat:`, result);
          }
        } catch (error) {
          console.error(`❌ Erreur lors de l'exécution de la requête ${i + 1}:`, error.message);
        }
      }
    }
    
    // Tester la vue créée
    console.log('🧪 Test de la vue créée...');
    const { data, error } = await supabase
      .from('brand_with_categories')
      .select('*')
      .limit(1);
    
    if (error) {
      console.error('❌ Erreur lors du test de la vue:', error);
    } else {
      console.log('✅ Vue testée avec succès');
      console.log('📊 Données de test:', data);
    }
    
  } catch (error) {
    console.error('❌ Erreur lors de la lecture du fichier SQL:', error);
  }
}

async function main() {
  console.log('🚀 Début de l\'exécution de la migration SQL');
  console.log('🔗 Connexion à:', supabaseUrl);
  
  await executeSQLMigration();
  
  console.log('✅ Migration terminée');
}

main().catch(console.error);
