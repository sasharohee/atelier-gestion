# 🎛️ Guide Complet - Page des Réglages

## 📋 Vue d'ensemble

La page des réglages a été entièrement refaite pour offrir une expérience complète et fonctionnelle. Elle est organisée en 4 onglets principaux :

1. **👤 Profil** - Informations personnelles de l'utilisateur
2. **🔔 Préférences** - Notifications et apparence
3. **🔒 Sécurité** - Gestion du mot de passe
4. **🏢 Atelier** - Paramètres de l'atelier

## 🚀 Installation et Configuration

### Étape 1 : Exécuter le script SQL

1. Ouvrez votre projet Supabase
2. Allez dans l'éditeur SQL
3. Copiez et exécutez le contenu du fichier `setup_settings_complete.sql`

```sql
-- Le script créera automatiquement :
-- ✅ Tables user_profiles et user_preferences
-- ✅ Table system_settings avec données par défaut
-- ✅ Politiques RLS appropriées
-- ✅ Profils et préférences pour l'utilisateur actuel
```

### Étape 2 : Vérifier l'installation

Après l'exécution du script, vous devriez voir :
- ✅ "Configuration terminée avec succès !"
- ✅ Tables créées avec des données
- ✅ Politiques RLS configurées

## 📱 Utilisation de la Page des Réglages

### Onglet 1 : Profil 👤

**Fonctionnalités :**
- Modification des informations personnelles (prénom, nom, email, téléphone)
- Affichage du rôle utilisateur et date d'inscription
- Sauvegarde automatique en base de données

**Actions disponibles :**
- ✅ Modifier les informations personnelles
- ✅ Sauvegarder les modifications
- ✅ Voir les informations du compte

### Onglet 2 : Préférences 🔔

**Fonctionnalités :**
- **Notifications :** Email, Push, SMS
- **Types de notifications :** Réparations, statuts, stock, rapports
- **Apparence :** Mode sombre, mode compact
- **Langue :** Français, English, Español
- **Sécurité :** 2FA, sessions multiples

**Actions disponibles :**
- ✅ Activer/désactiver les notifications
- ✅ Changer le thème d'apparence
- ✅ Sélectionner la langue
- ✅ Configurer les paramètres de sécurité

### Onglet 3 : Sécurité 🔒

**Fonctionnalités :**
- Changement de mot de passe sécurisé
- Validation des mots de passe
- Conseils de sécurité
- Visibilité des mots de passe

**Actions disponibles :**
- ✅ Changer le mot de passe
- ✅ Voir/masquer les mots de passe
- ✅ Validation automatique

### Onglet 4 : Atelier 🏢

**Fonctionnalités :**
- **Informations de l'atelier :** Nom, adresse, téléphone, email
- **Paramètres de facturation :** TVA, devise, préfixe facture, format date
- **Paramètres système :** Sauvegarde, notifications, taille fichiers

**Actions disponibles :**
- ✅ Modifier les informations de l'atelier
- ✅ Configurer la facturation
- ✅ Gérer les paramètres système
- ✅ Recharger les données

## 🔧 Fonctionnalités Techniques

### Intégration avec Supabase

La page utilise les services suivants :
- `userSettingsService` - Gestion des profils et préférences
- `systemSettingsService` - Gestion des paramètres système
- `useAppStore` - État global de l'application

### Gestion des États

```typescript
// États locaux pour les formulaires
const [profileForm, setProfileForm] = useState({...});
const [preferencesForm, setPreferencesForm] = useState({...});
const [passwordForm, setPasswordForm] = useState({...});
const [systemForm, setSystemForm] = useState({...});
```

### Sauvegarde Automatique

Toutes les modifications sont sauvegardées en temps réel :
- ✅ Profil utilisateur → Table `user_profiles`
- ✅ Préférences → Table `user_preferences`
- ✅ Paramètres système → Table `system_settings`

## 🎨 Interface Utilisateur

### Design Moderne

- **Onglets Material-UI** pour une navigation claire
- **Cartes organisées** par fonctionnalité
- **Indicateurs visuels** (chips, icônes, couleurs)
- **Responsive design** pour mobile et desktop

### Feedback Utilisateur

- **Snackbars** pour les confirmations et erreurs
- **Indicateurs de chargement** pendant les sauvegardes
- **Validation en temps réel** des formulaires
- **Statut du système** en temps réel

## 🔍 Dépannage

### Problèmes Courants

**1. Les données ne se chargent pas**
```bash
# Vérifier que le script SQL a été exécuté
# Vérifier les politiques RLS dans Supabase
# Vérifier la console du navigateur pour les erreurs
```

**2. Impossible de sauvegarder**
```bash
# Vérifier la connexion Supabase
# Vérifier les permissions utilisateur
# Vérifier les logs d'erreur
```

**3. Tables manquantes**
```bash
# Exécuter à nouveau le script setup_settings_complete.sql
# Vérifier que l'utilisateur a les droits d'administration
```

### Vérifications

**Dans Supabase Dashboard :**
1. Tables → Vérifier `user_profiles`, `user_preferences`, `system_settings`
2. Authentication → Vérifier l'utilisateur connecté
3. Policies → Vérifier les politiques RLS

**Dans la Console du Navigateur :**
```javascript
// Vérifier les appels API
// Vérifier les erreurs de connexion
// Vérifier les données chargées
```

## 📊 Structure des Données

### Table `user_profiles`
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key)
- first_name (VARCHAR)
- last_name (VARCHAR)
- email (VARCHAR)
- phone (VARCHAR)
- avatar (TEXT)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Table `user_preferences`
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key)
- notifications_email (BOOLEAN)
- notifications_push (BOOLEAN)
- notifications_sms (BOOLEAN)
- theme_dark_mode (BOOLEAN)
- theme_compact_mode (BOOLEAN)
- language (VARCHAR)
- two_factor_auth (BOOLEAN)
- multiple_sessions (BOOLEAN)
- repair_notifications (BOOLEAN)
- status_notifications (BOOLEAN)
- stock_notifications (BOOLEAN)
- daily_reports (BOOLEAN)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

### Table `system_settings`
```sql
- id (UUID, Primary Key)
- key (VARCHAR, Unique)
- value (TEXT)
- description (TEXT)
- category (VARCHAR)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

## 🚀 Améliorations Futures

### Fonctionnalités Prévues

- [ ] Upload d'avatar utilisateur
- [ ] Export/import des préférences
- [ ] Thèmes personnalisés
- [ ] Notifications push en temps réel
- [ ] Audit des modifications
- [ ] Sauvegarde automatique des paramètres

### Optimisations

- [ ] Mise en cache des paramètres
- [ ] Synchronisation en temps réel
- [ ] Validation côté serveur
- [ ] Gestion des conflits de données

## 📞 Support

En cas de problème :
1. Vérifier ce guide
2. Consulter les logs de la console
3. Vérifier la configuration Supabase
4. Contacter l'équipe de développement

---

**✅ La page des réglages est maintenant entièrement fonctionnelle et prête à l'utilisation !**
