# Correction URL de redirection Supabase

## Problème
Les emails de confirmation de Supabase pointent vers `localhost` au lieu de `https://atelier-gestion-app.vercel.app`

## Solution

### 1. Accéder au Dashboard Supabase
1. Aller sur https://supabase.com/dashboard
2. Se connecter avec votre compte
3. Sélectionner le projet `atelier-gestion`

### 2. Configurer l'URL de redirection
1. Dans le menu de gauche, cliquer sur **Authentication**
2. Cliquer sur **URL Configuration**
3. Dans la section **Site URL**, remplacer :
   - ❌ `http://localhost:5173` 
   - ✅ `https://atelier-gestion-app.vercel.app`

### 3. Configurer les URLs de redirection
Dans la section **Redirect URLs**, ajouter :
```
https://atelier-gestion-app.vercel.app/auth/callback
https://atelier-gestion-app.vercel.app/auth/confirm
https://atelier-gestion-app.vercel.app/auth/reset-password
```

### 4. Sauvegarder les modifications
Cliquer sur **Save** pour appliquer les changements.

### 5. Tester la configuration
1. Créer un nouveau compte utilisateur
2. Vérifier que l'email de confirmation pointe vers la bonne URL
3. Tester la confirmation d'email

## URLs importantes à configurer

### Site URL
```
https://atelier-gestion-app.vercel.app
```

### Redirect URLs
```
https://atelier-gestion-app.vercel.app/auth/callback
https://atelier-gestion-app.vercel.app/auth/confirm
https://atelier-gestion-app.vercel.app/auth/reset-password
https://atelier-gestion-app.vercel.app/auth/verify
```

### Email Templates
Vérifier que les templates d'email utilisent la bonne URL de base.

## Vérification
Après la configuration, tester :
1. ✅ Création de compte
2. ✅ Confirmation d'email
3. ✅ Réinitialisation de mot de passe
4. ✅ Connexion OAuth (si configuré)
