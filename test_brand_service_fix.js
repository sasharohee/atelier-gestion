// ============================================================================
// TEST DU SERVICE BRAND AVEC LA FONCTION CORRIGÉE
// ============================================================================

// Test de la fonction upsert_brand avec les bons paramètres
const testUpsertBrand = async () => {
  try {
    console.log('🧪 Test de la fonction upsert_brand...');
    
    // Paramètres de test
    const testParams = {
      p_id: 'test_brand_' + Date.now(),
      p_name: 'Test Brand',
      p_description: 'Description de test',
      p_logo: '',
      p_category_ids: null // ou ['category_id_1', 'category_id_2'] si des catégories existent
    };
    
    console.log('📤 Paramètres envoyés:', testParams);
    
    // Appel de la fonction RPC
    const { data, error } = await supabase.rpc('upsert_brand', testParams);
    
    if (error) {
      console.error('❌ Erreur lors de l\'appel RPC:', error);
      return { success: false, error };
    }
    
    console.log('✅ Réponse de la fonction:', data);
    return { success: true, data };
    
  } catch (err) {
    console.error('❌ Erreur inattendue:', err);
    return { success: false, error: err };
  }
};

// Test de la fonction upsert_brand_simple
const testUpsertBrandSimple = async () => {
  try {
    console.log('🧪 Test de la fonction upsert_brand_simple...');
    
    const testParams = {
      p_id: 'test_brand_simple_' + Date.now(),
      p_name: 'Test Brand Simple',
      p_description: 'Description de test simple',
      p_logo: ''
    };
    
    console.log('📤 Paramètres envoyés:', testParams);
    
    const { data, error } = await supabase.rpc('upsert_brand_simple', testParams);
    
    if (error) {
      console.error('❌ Erreur lors de l\'appel RPC:', error);
      return { success: false, error };
    }
    
    console.log('✅ Réponse de la fonction:', data);
    return { success: true, data };
    
  } catch (err) {
    console.error('❌ Erreur inattendue:', err);
    return { success: false, error: err };
  }
};

// Test de la fonction create_brand_basic
const testCreateBrandBasic = async () => {
  try {
    console.log('🧪 Test de la fonction create_brand_basic...');
    
    const testParams = {
      p_id: 'test_brand_basic_' + Date.now(),
      p_name: 'Test Brand Basic',
      p_description: 'Description de test basique',
      p_logo: ''
    };
    
    console.log('📤 Paramètres envoyés:', testParams);
    
    const { data, error } = await supabase.rpc('create_brand_basic', testParams);
    
    if (error) {
      console.error('❌ Erreur lors de l\'appel RPC:', error);
      return { success: false, error };
    }
    
    console.log('✅ Réponse de la fonction:', data);
    return { success: true, data };
    
  } catch (err) {
    console.error('❌ Erreur inattendue:', err);
    return { success: false, error: err };
  }
};

// Fonction pour exécuter tous les tests
const runAllTests = async () => {
  console.log('🚀 Début des tests des fonctions RPC...');
  
  const results = {
    upsert_brand: await testUpsertBrand(),
    upsert_brand_simple: await testUpsertBrandSimple(),
    create_brand_basic: await testCreateBrandBasic()
  };
  
  console.log('📊 Résultats des tests:', results);
  
  const successCount = Object.values(results).filter(r => r.success).length;
  const totalCount = Object.keys(results).length;
  
  console.log(`✅ Tests réussis: ${successCount}/${totalCount}`);
  
  return results;
};

// Exporter les fonctions pour utilisation
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    testUpsertBrand,
    testUpsertBrandSimple,
    testCreateBrandBasic,
    runAllTests
  };
}

// Si exécuté directement dans le navigateur
if (typeof window !== 'undefined') {
  console.log('🔧 Fonctions de test chargées. Utilisez runAllTests() pour exécuter tous les tests.');
}















