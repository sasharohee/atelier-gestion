// Script de test simple pour diagnostiquer le problème de suivi des réparations
// Ce script utilise les mêmes variables d'environnement que l'application React

console.log('🔍 Diagnostic de la fonctionnalité de suivi des réparations\n');

// Vérifier si les variables d'environnement sont disponibles
const supabaseUrl = process.env.VITE_SUPABASE_URL || 'Non définie';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || 'Non définie';

console.log('📋 Configuration actuelle:');
console.log('- VITE_SUPABASE_URL:', supabaseUrl);
console.log('- VITE_SUPABASE_ANON_KEY:', supabaseKey ? '✅ Définie' : '❌ Non définie');

if (supabaseUrl === 'Non définie' || supabaseKey === 'Non définie') {
  console.log('\n❌ Variables d\'environnement manquantes !');
  console.log('\n📝 Pour résoudre ce problème :');
  console.log('1. Créez un fichier .env à la racine du projet');
  console.log('2. Ajoutez vos variables Supabase :');
  console.log('   VITE_SUPABASE_URL=votre_url_supabase');
  console.log('   VITE_SUPABASE_ANON_KEY=votre_cle_anon_supabase');
  console.log('3. Redémarrez le serveur de développement');
  console.log('\n💡 Vous pouvez copier le fichier env.example et le renommer en .env');
  process.exit(1);
}

// Si les variables sont définies, tester la connexion
console.log('\n✅ Variables d\'environnement trouvées !');
console.log('\n📋 Prochaines étapes pour diagnostiquer :');
console.log('1. Vérifiez que les scripts SQL ont été exécutés dans Supabase :');
console.log('   - tables/add_repair_number.sql');
console.log('   - tables/repair_tracking_function.sql');
console.log('\n2. Testez la page de suivi dans l\'application :');
console.log('   - Allez sur http://localhost:3004/repair-tracking');
console.log('   - Créez une réparation dans le Kanban');
console.log('   - Utilisez le numéro de réparation pour tester');
console.log('\n3. Vérifiez la console du navigateur pour les erreurs');
console.log('\n4. Vérifiez les logs Supabase pour les erreurs SQL');

console.log('\n🔧 Pour tester manuellement dans Supabase :');
console.log('1. Ouvrez l\'éditeur SQL de votre projet Supabase');
console.log('2. Exécutez cette requête pour vérifier les réparations :');
console.log(`
SELECT 
  r.id,
  r.repair_number,
  r.status,
  c.email,
  c.first_name,
  c.last_name
FROM repairs r
JOIN clients c ON r.client_id = c.id
WHERE r.repair_number IS NOT NULL
ORDER BY r.created_at DESC
LIMIT 5;
`);

console.log('\n3. Testez la fonction de suivi :');
console.log(`
SELECT * FROM get_repair_tracking_info('REP-20241201-1234', 'email@test.com');
`);

console.log('\n🎯 Si le problème persiste, vérifiez :');
console.log('- Que la colonne repair_number existe dans la table repairs');
console.log('- Que les fonctions SQL ont été créées sans erreur');
console.log('- Que les données de test existent dans la base');
console.log('- Que les permissions Supabase permettent l\'accès aux fonctions RPC');
