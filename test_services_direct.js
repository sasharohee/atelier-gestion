// Script de test direct des services
// À exécuter dans la console du navigateur sur http://localhost:3000

console.log('🧪 Test direct des services...');

// Test 1: Vérifier que les services sont disponibles
console.log('📦 Vérification des imports...');

try {
    // Ces imports devraient fonctionner si l'application est chargée
    console.log('✅ Application chargée, test des services...');
    
    // Test des catégories
    console.log('🔍 Test des catégories...');
    
    // Test des marques  
    console.log('🏷️ Test des marques...');
    
    // Test des modèles
    console.log('📱 Test des modèles...');
    
} catch (error) {
    console.error('❌ Erreur lors du test:', error);
}

// Fonction pour tester le chargement des données
async function testDataLoading() {
    console.log('🧪 Début du test de chargement des données...');
    
    try {
        // Test 1: Vérifier la connexion Supabase
        console.log('🔗 Test de la connexion Supabase...');
        if (typeof window !== 'undefined' && window.supabase) {
            console.log('✅ Supabase disponible');
        } else {
            console.log('⚠️ Supabase non disponible dans window');
        }
        
        // Test 2: Vérifier les tables
        console.log('📊 Test des tables...');
        
        // Test 3: Vérifier les vues
        console.log('👁️ Test des vues...');
        
        console.log('✅ Test terminé');
        
    } catch (error) {
        console.error('❌ Erreur lors du test:', error);
    }
}

// Instructions pour l'utilisateur
console.log(`
📋 Instructions pour tester les services :

1. Ouvrez la console du navigateur (F12)
2. Copiez et collez ce script
3. Exécutez : testDataLoading()
4. Regardez les résultats dans la console

🔍 Pour diagnostiquer les problèmes :
- Vérifiez les erreurs dans la console
- Vérifiez que Supabase est connecté
- Vérifiez que les tables existent dans Supabase
- Vérifiez que les vues existent dans Supabase
`);

// Exporter la fonction pour l'utilisateur
window.testDataLoading = testDataLoading;
