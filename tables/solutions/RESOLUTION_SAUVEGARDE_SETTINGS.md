# RÉSOLUTION RAPIDE : Problème de sauvegarde Settings

## 🚨 Problème
La page Réglages ne sauvegarde pas les données.

## ✅ Solution en 3 étapes (2 minutes)

### Étape 1 : Vérifier les tables (30 secondes)
1. **Exécuter le script** `debug_settings.sql` dans Supabase
2. **Vérifier que les tables existent** et ont des données
3. **Vérifier les politiques RLS** sont correctes

### Étape 2 : Utiliser les boutons de débogage (30 secondes)
1. **Aller sur la page Réglages**
2. **Cliquer sur "Debug"** (bouton violet)
3. **Vérifier la console** (F12) pour voir les erreurs
4. **Cliquer sur "Créer données"** (bouton orange) si nécessaire

### Étape 3 : Tester la sauvegarde (1 minute)
1. **Modifier un paramètre** (ex: prénom)
2. **Cliquer sur "Sauvegarder les modifications"**
3. **Vérifier la notification** de succès
4. **Recharger la page** pour confirmer la persistance

## 🔧 Boutons de débogage ajoutés

### Bouton "Debug" (violet)
- Affiche toutes les données dans la console
- Teste la connexion directe à Supabase
- Affiche le nombre de profils/préférences trouvés

### Bouton "Créer données" (orange)
- Force la création du profil utilisateur
- Force la création des préférences par défaut
- Recharge automatiquement les données

## 🐛 Causes possibles

### 1. Tables non créées
**Solution** : Exécuter `create_user_settings_tables.sql`

### 2. Politiques RLS trop restrictives
**Solution** : Vérifier avec `debug_settings.sql`

### 3. Données utilisateur non créées
**Solution** : Cliquer sur "Créer données"

### 4. Erreur de connexion Supabase
**Solution** : Vérifier les logs dans la console

## 📊 Vérifications à faire

### Dans la console (F12) :
```
🔍 Debug: Vérification des données...
Current User: {id: "...", email: "..."}
User Profile: null ou {...}
User Preferences: null ou {...}
📊 Test user_profiles: {data: [...], error: null}
📊 Test user_preferences: {data: [...], error: null}
```

### Dans Supabase :
```sql
-- Vérifier les tables
SELECT COUNT(*) FROM user_profiles;
SELECT COUNT(*) FROM user_preferences;

-- Vérifier les politiques
SELECT * FROM pg_policies WHERE tablename IN ('user_profiles', 'user_preferences');
```

## 🎯 Résultat attendu

Après les étapes :
- ✅ Bouton "Debug" affiche des données
- ✅ Bouton "Créer données" fonctionne
- ✅ Sauvegarde des paramètres fonctionne
- ✅ Notifications de succès s'affichent
- ✅ Données persistent après rechargement

## 🆘 Si rien ne fonctionne

### Solution d'urgence :
1. **Cliquer sur "Créer données"** (bouton orange)
2. **Attendre la notification** de succès
3. **Tester la sauvegarde** immédiatement

### Vérification complète :
1. **Ouvrir la console** (F12)
2. **Cliquer sur "Debug"**
3. **Vérifier tous les logs** pour identifier l'erreur
4. **Exécuter le script SQL** de débogage

## 📁 Fichiers de débogage

1. **`debug_settings.sql`** - Script de vérification
2. **`src/pages/Settings/Settings.tsx`** - Boutons de débogage ajoutés
3. **`RESOLUTION_SAUVEGARDE_SETTINGS.md`** - Ce guide

## ⏱️ Temps estimé

- **Vérification** : 30 secondes
- **Débogage** : 30 secondes  
- **Test** : 1 minute
- **Total** : ~2 minutes
