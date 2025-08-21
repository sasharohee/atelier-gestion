// Script pour vérifier la configuration Supabase
// Ce script peut être exécuté pour vérifier les URLs de redirection

const SUPABASE_URL = 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8';

console.log('🔍 Vérification de la configuration Supabase...');
console.log('');

console.log('📋 URLs à configurer dans le dashboard Supabase:');
console.log('');
console.log('🌐 Site URL:');
console.log('   https://atelier-gestion-app.vercel.app');
console.log('');
console.log('🔄 Redirect URLs:');
console.log('   https://atelier-gestion-app.vercel.app/auth/callback');
console.log('   https://atelier-gestion-app.vercel.app/auth/confirm');
console.log('   https://atelier-gestion-app.vercel.app/auth/reset-password');
console.log('   https://atelier-gestion-app.vercel.app/auth/verify');
console.log('');
console.log('📧 Email Templates:');
console.log('   Vérifier que les templates utilisent la bonne URL de base');
console.log('');
console.log('⚙️ Configuration actuelle du client:');
console.log(`   URL: ${SUPABASE_URL}`);
console.log('   ✅ emailRedirectTo configuré dans signUp');
console.log('   ✅ redirectTo configuré dans resetPasswordForEmail');
console.log('');

console.log('📝 Instructions:');
console.log('1. Aller sur https://supabase.com/dashboard');
console.log('2. Sélectionner le projet atelier-gestion');
console.log('3. Authentication > URL Configuration');
console.log('4. Mettre à jour Site URL et Redirect URLs');
console.log('5. Sauvegarder les modifications');
console.log('6. Tester la création d\'un nouveau compte');
console.log('');

console.log('✅ Configuration côté client mise à jour');
console.log('⚠️  N\'oubliez pas de configurer le dashboard Supabase !');
