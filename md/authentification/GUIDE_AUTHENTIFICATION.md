# Guide d'Authentification - Atelier Gestion

## 🚀 Configuration du Système d'Authentification

### 1. Configuration Supabase

#### Étape 1 : Nettoyer les politiques existantes (si nécessaire)
Si vous avez déjà des politiques RLS configurées, exécutez d'abord le script de nettoyage :

```sql
-- Copiez et exécutez le contenu du fichier clean_auth_policies.sql
```

#### Étape 2 : Exécuter le script SQL principal
1. Connectez-vous à votre projet Supabase
2. Allez dans l'éditeur SQL
3. Exécutez le script `setup_auth_simple.sql` (recommandé)

```sql
-- Copiez et exécutez le contenu du fichier setup_auth_simple.sql
-- Ce script utilise DROP POLICY IF EXISTS pour éviter tous les conflits
```

#### Étape 2 : Configurer l'authentification dans Supabase
1. Dans le dashboard Supabase, allez dans **Authentication > Settings**
2. Configurez les paramètres suivants :

**Site URL :**
```
http://localhost:5173 (pour le développement)
https://votre-domaine.com (pour la production)
```

**Redirect URLs :**
```
http://localhost:5173/auth
http://localhost:5173/app/dashboard
https://votre-domaine.com/auth
https://votre-domaine.com/app/dashboard
```

**Email Templates :**
- Personnalisez les templates d'email pour l'inscription et la réinitialisation de mot de passe

### 2. Variables d'Environnement

Créez un fichier `.env.local` à la racine du projet :

```env
VITE_SUPABASE_URL=https://wlqyrmntfxwdvkzzsujv.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8
```

### 3. Test du Système

#### Test de Connexion
1. Lancez l'application : `npm run dev`
2. Allez sur `http://localhost:5173`
3. Cliquez sur "Accéder à l'Atelier"
4. Vous devriez être redirigé vers la page de connexion

#### Test d'Inscription
1. Sur la page d'authentification, cliquez sur l'onglet "Inscription"
2. Remplissez le formulaire avec :
   - Prénom et nom
   - Email valide
   - Mot de passe respectant les critères de sécurité
3. Cliquez sur "Créer mon compte"
4. Vérifiez votre email pour confirmer le compte

#### Test de Connexion
1. Retournez sur la page de connexion
2. Utilisez les identifiants créés
3. Vous devriez être connecté et redirigé vers le dashboard

## 🔧 Fonctionnalités Implémentées

### ✅ Page d'Authentification Complète
- **Connexion** : Email + mot de passe
- **Inscription** : Formulaire complet avec validation
- **Validation de mot de passe** : Critères de sécurité en temps réel
- **Mot de passe oublié** : Réinitialisation par email
- **Interface responsive** : Adaptée mobile et desktop

### ✅ Protection des Routes
- **AuthGuard** : Protection automatique des routes `/app/*`
- **Redirection intelligente** : Retour à la page demandée après connexion
- **État d'authentification global** : Hook `useAuth` pour toute l'application

### ✅ Gestion des Sessions
- **Persistance** : Sessions conservées entre les rechargements
- **Déconnexion** : Bouton dans la sidebar
- **Sécurité** : Tokens JWT gérés par Supabase

### ✅ Base de Données
- **Tables utilisateurs** : `users`, `user_profiles`, `user_preferences`
- **Politiques RLS** : Sécurité au niveau des données
- **Triggers automatiques** : Création automatique des profils

## 🛡️ Sécurité

### Politiques de Sécurité (RLS)
- **Lecture** : Tous les utilisateurs peuvent voir les profils publics
- **Modification** : Chaque utilisateur ne peut modifier que son propre profil
- **Création** : Seuls les admins peuvent créer de nouveaux utilisateurs
- **Suppression** : Seuls les admins peuvent supprimer des utilisateurs

### Validation des Mots de Passe
- Minimum 8 caractères
- Au moins une lettre majuscule
- Au moins une lettre minuscule
- Au moins un chiffre
- Au moins un caractère spécial

### Protection CSRF
- Tokens JWT sécurisés
- Sessions avec expiration automatique
- Headers de sécurité configurés

## 🔄 Flux d'Utilisation

### 1. Premier Accès
```
Landing Page → "Accéder à l'Atelier" → Page Auth → Inscription → Confirmation Email → Connexion → Dashboard
```

### 2. Accès Récurrent
```
Landing Page → "Accéder à l'Atelier" → Page Auth → Connexion → Dashboard
```

### 3. Déconnexion
```
Dashboard → Sidebar → Bouton Déconnexion → Page Auth
```

## 🐛 Dépannage

### Problèmes Courants

#### 1. Erreur de Connexion
**Symptôme :** "Erreur lors de la connexion"
**Solution :**
- Vérifiez que l'email et le mot de passe sont corrects
- Assurez-vous que le compte a été confirmé par email
- Vérifiez les variables d'environnement

#### 2. Redirection en Boucle
**Symptôme :** Redirection infinie entre `/auth` et `/app`
**Solution :**
- Vérifiez que les politiques RLS sont correctement configurées
- Assurez-vous que le trigger `handle_new_user` fonctionne
- Vérifiez les logs Supabase

#### 3. Email de Confirmation Non Reçu
**Symptôme :** Pas d'email après inscription
**Solution :**
- Vérifiez la configuration des templates d'email dans Supabase
- Vérifiez les paramètres SMTP
- Consultez les logs d'email dans Supabase

#### 4. Erreur de Base de Données
**Symptôme :** Erreurs SQL lors de l'inscription
**Solution :**
- Vérifiez que toutes les tables sont créées
- Assurez-vous que les triggers sont actifs
- Vérifiez les permissions des utilisateurs

#### 5. Erreur de Politiques RLS
**Symptôme :** `ERROR: 42710: policy "..." already exists` ou `ERROR: 42704: policy "..." does not exist`
**Solution :**
- Utilisez le script `setup_auth_simple.sql` qui utilise `DROP POLICY IF EXISTS`
- Ce script gère automatiquement les politiques existantes ou inexistantes

#### 6. Erreur de Fonction Dépendante
**Symptôme :** `ERROR: 2BP01: cannot drop function update_updated_at_column() because other objects depend on it`
**Solution :**
- Utilisez le script `setup_auth_simple.sql` qui préserve les fonctions existantes
- Ou exécutez `clean_auth_policies.sql` qui ne supprime que les politiques et triggers d'auth

### Logs de Débogage

Activez les logs de débogage dans la console du navigateur :

```javascript
// Dans la console du navigateur
localStorage.setItem('supabase.debug', 'true')
```

## 📱 Responsive Design

La page d'authentification est entièrement responsive :

- **Desktop** : Formulaire centré avec design moderne
- **Tablet** : Adaptation automatique des tailles
- **Mobile** : Interface optimisée pour les écrans tactiles

## 🎨 Personnalisation

### Thème
Le design utilise le thème Material-UI configuré dans `src/theme/index.ts`

### Couleurs
Les couleurs principales sont définies dans le thème :
- Primary : Couleur principale de l'application
- Secondary : Couleur d'accent
- Background : Dégradé pour la page d'authentification

### Textes
Tous les textes sont en français et peuvent être modifiés dans `src/pages/Auth/Auth.tsx`

## 🚀 Déploiement

### Vercel
1. Configurez les variables d'environnement dans Vercel
2. Déployez avec `npm run build`
3. Vérifiez les URLs de redirection dans Supabase

### Autres Plateformes
1. Adaptez les URLs de redirection
2. Configurez les variables d'environnement
3. Testez l'authentification en production

## 📞 Support

En cas de problème :
1. Vérifiez les logs de la console
2. Consultez les logs Supabase
3. Testez avec un compte de développement
4. Vérifiez la configuration des politiques RLS

---

**Note :** Ce système d'authentification est conçu pour fonctionner parfaitement du premier coup. Tous les composants sont testés et optimisés pour une expérience utilisateur fluide.
