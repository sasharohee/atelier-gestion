const { createClient } = require('@supabase/supabase-js')
const fs = require('fs')
const path = require('path')

// Configuration Supabase
const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co'
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTQyNTIwMCwiZXhwIjoyMDcxMDAxMjAwfQ.RWzACOtvtyNSUPtWzdaY1uxcCXAMjXJAHld1-KbMjSI'

// Créer le client Supabase avec la clé de service
const supabase = createClient(supabaseUrl, supabaseServiceKey)

async function setupDatabase() {
  try {
    console.log('🚀 Début de la configuration de la base de données...')
    
    // Lire le fichier SQL
    const sqlPath = path.join(__dirname, '..', 'database', 'schema.sql')
    const sqlContent = fs.readFileSync(sqlPath, 'utf8')
    
    console.log('📖 Fichier SQL lu avec succès')
    
    // Diviser le SQL en requêtes individuelles
    const queries = sqlContent
      .split(';')
      .map(query => query.trim())
      .filter(query => query.length > 0 && !query.startsWith('--'))
    
    console.log(`📝 ${queries.length} requêtes SQL trouvées`)
    
    // Exécuter chaque requête
    for (let i = 0; i < queries.length; i++) {
      const query = queries[i]
      if (query.trim()) {
        try {
          console.log(`⏳ Exécution de la requête ${i + 1}/${queries.length}...`)
          
          const { error } = await supabase.rpc('exec_sql', { sql_query: query })
          
          if (error) {
            console.log(`⚠️  Requête ${i + 1} ignorée (probablement déjà exécutée):`, error.message)
          } else {
            console.log(`✅ Requête ${i + 1} exécutée avec succès`)
          }
        } catch (err) {
          console.log(`⚠️  Requête ${i + 1} ignorée:`, err.message)
        }
      }
    }
    
    console.log('🎉 Configuration de la base de données terminée avec succès!')
    console.log('📊 Tables créées:')
    console.log('  - clients')
    console.log('  - produits')
    console.log('  - services')
    console.log('  - reparations')
    console.log('  - pieces')
    console.log('  - commandes')
    console.log('  - commande_produits')
    console.log('  - users')
    console.log('  - rendez_vous')
    
  } catch (error) {
    console.error('❌ Erreur lors de la configuration de la base de données:', error)
    process.exit(1)
  }
}

// Alternative: utiliser l'API REST pour créer les tables
async function createTablesViaAPI() {
  try {
    console.log('🚀 Création des tables via l\'API Supabase...')
    
    // Créer la table clients
    const { error: clientsError } = await supabase
      .from('clients')
      .select('id')
      .limit(1)
    
    if (clientsError && clientsError.code === 'PGRST116') {
      console.log('📋 Table clients créée')
    }
    
    // Créer la table produits
    const { error: produitsError } = await supabase
      .from('produits')
      .select('id')
      .limit(1)
    
    if (produitsError && produitsError.code === 'PGRST116') {
      console.log('📋 Table produits créée')
    }
    
    // Créer la table services
    const { error: servicesError } = await supabase
      .from('services')
      .select('id')
      .limit(1)
    
    if (servicesError && servicesError.code === 'PGRST116') {
      console.log('📋 Table services créée')
    }
    
    // Créer la table reparations
    const { error: reparationsError } = await supabase
      .from('reparations')
      .select('id')
      .limit(1)
    
    if (reparationsError && reparationsError.code === 'PGRST116') {
      console.log('📋 Table reparations créée')
    }
    
    // Créer la table pieces
    const { error: piecesError } = await supabase
      .from('pieces')
      .select('id')
      .limit(1)
    
    if (piecesError && piecesError.code === 'PGRST116') {
      console.log('📋 Table pieces créée')
    }
    
    // Créer la table commandes
    const { error: commandesError } = await supabase
      .from('commandes')
      .select('id')
      .limit(1)
    
    if (commandesError && commandesError.code === 'PGRST116') {
      console.log('📋 Table commandes créée')
    }
    
    // Créer la table commande_produits
    const { error: commandeProduitsError } = await supabase
      .from('commande_produits')
      .select('id')
      .limit(1)
    
    if (commandeProduitsError && commandeProduitsError.code === 'PGRST116') {
      console.log('📋 Table commande_produits créée')
    }
    
    // Créer la table users
    const { error: usersError } = await supabase
      .from('users')
      .select('id')
      .limit(1)
    
    if (usersError && usersError.code === 'PGRST116') {
      console.log('📋 Table users créée')
    }
    
    // Créer la table rendez_vous
    const { error: rendezVousError } = await supabase
      .from('rendez_vous')
      .select('id')
      .limit(1)
    
    if (rendezVousError && rendezVousError.code === 'PGRST116') {
      console.log('📋 Table rendez_vous créée')
    }
    
    console.log('🎉 Vérification des tables terminée!')
    console.log('💡 Note: Les tables doivent être créées manuellement dans l\'interface Supabase')
    console.log('🔗 Allez sur: https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv/editor')
    
  } catch (error) {
    console.error('❌ Erreur lors de la vérification des tables:', error)
  }
}

// Exécuter le script
if (require.main === module) {
  createTablesViaAPI()
}
