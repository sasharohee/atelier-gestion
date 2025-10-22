# 🚀 Guide de Configuration Supabase - URLs de Redirection

## ✅ Problème résolu côté client
Les modifications ont été apportées au code pour utiliser les bonnes URLs de redirection.

## 🔧 Configuration requise dans le Dashboard Supabase

### 1. Accéder au Dashboard
1. Aller sur [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Se connecter avec votre compte
3. Sélectionner le projet **atelier-gestion**

### 2. Configuration des URLs
1. Dans le menu de gauche, cliquer sur **Authentication**
2. Cliquer sur **URL Configuration**

### 3. Site URL
Remplacer l'URL actuelle par :
```
https://atelier-gestion-app.vercel.app
```

### 4. Redirect URLs
Ajouter ces URLs dans la section **Redirect URLs** :
```
https://atelier-gestion-app.vercel.app/auth/callback
https://atelier-gestion-app.vercel.app/auth/confirm
https://atelier-gestion-app.vercel.app/auth/reset-password
https://atelier-gestion-app.vercel.app/auth/verify
```

### 5. Sauvegarder
Cliquer sur **Save** pour appliquer les modifications.

## 🧪 Test de la configuration

### Test 1 : Création de compte
1. Aller sur [https://atelier-gestion-app.vercel.app](https://atelier-gestion-app.vercel.app)
2. Créer un nouveau compte
3. Vérifier que l'email de confirmation pointe vers la bonne URL

### Test 2 : Réinitialisation de mot de passe
1. Utiliser la fonction "Mot de passe oublié"
2. Vérifier que l'email pointe vers la bonne URL

## 📧 Templates d'Email (Optionnel)
Si vous voulez personnaliser les emails :
1. Dans **Authentication** > **Email Templates**
2. Vérifier que les URLs dans les templates utilisent la bonne base

## 🔗 URLs importantes
- **Application en production** : https://atelier-gestion-app.vercel.app
- **Dashboard Supabase** : https://supabase.com/dashboard
- **Projet Supabase** : atelier-gestion

## ✅ Vérification finale
Après la configuration :
- ✅ Les emails de confirmation pointent vers la production
- ✅ Les liens de réinitialisation fonctionnent
- ✅ L'authentification fonctionne correctement
- ✅ Les redirections sont correctes

## 🆘 En cas de problème
1. Vérifier que toutes les URLs sont correctement configurées
2. Attendre quelques minutes pour la propagation des changements
3. Vider le cache du navigateur
4. Tester avec un nouvel email

---
**Note** : Cette configuration est essentielle pour que l'authentification fonctionne correctement en production.
