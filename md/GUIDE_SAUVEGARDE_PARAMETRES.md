# Guide de configuration des sauvegardes des paramètres système

## Problème résolu

Les sauvegardes des paramètres système ne fonctionnaient pas car elles n'étaient pas connectées à Supabase. Maintenant, tous les paramètres sont sauvegardés dans la base de données et persistent entre les sessions.

## Configuration requise

### 1. Créer la table system_settings

Exécuter le script SQL `create_system_settings_table.sql` dans l'éditeur SQL de Supabase :

```sql
-- Copier et exécuter le contenu complet du fichier create_system_settings_table.sql
```

### 2. Vérifier les politiques RLS

Le script crée automatiquement les politiques de sécurité nécessaires :
- Seuls les administrateurs peuvent voir/modifier les paramètres
- Les utilisateurs normaux ne peuvent pas accéder aux paramètres système

### 3. Paramètres par défaut

Le script insère automatiquement les paramètres par défaut :

#### Paramètres généraux
- `workshop_name` : "Atelier de réparation"
- `workshop_address` : "123 Rue de la Paix, 75001 Paris"
- `workshop_phone` : "01 23 45 67 89"
- `workshop_email` : "contact@atelier.fr"

#### Paramètres de facturation
- `vat_rate` : "20"
- `currency` : "EUR"
- `invoice_prefix` : "FACT-"
- `date_format` : "dd/MM/yyyy"

#### Paramètres système
- `auto_backup` : "true"
- `notifications` : "true"
- `backup_frequency` : "daily"
- `max_file_size` : "10"

## Fonctionnement

### 1. Chargement automatique

Les paramètres sont chargés automatiquement au démarrage de la page d'administration :
- Appel à `loadSystemSettings()` au montage du composant
- Les valeurs sont récupérées depuis Supabase
- Affichage dans les champs avec les valeurs par défaut si nécessaire

### 2. Sauvegarde par catégorie

Chaque section a son propre bouton de sauvegarde :
- **Paramètres généraux** → Sauvegarde la catégorie 'general'
- **Paramètres de facturation** → Sauvegarde la catégorie 'billing'
- **Paramètres système** → Sauvegarde la catégorie 'system'

### 3. Validation et feedback

- Validation côté client avant sauvegarde
- Notifications de succès/erreur via Snackbar
- Gestion des erreurs de connexion

## Utilisation

### Modifier un paramètre

1. Naviguer vers la page Administration
2. Modifier la valeur dans le champ souhaité
3. Cliquer sur "Sauvegarder" dans la section correspondante
4. Vérifier la notification de succès

### Vérifier la sauvegarde

1. Recharger la page
2. Vérifier que les valeurs modifiées sont toujours présentes
3. Les paramètres persistent maintenant entre les sessions

## Structure de la base de données

### Table system_settings

```sql
CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Champs
- `id` : Identifiant unique
- `key` : Clé du paramètre (unique)
- `value` : Valeur du paramètre
- `description` : Description du paramètre
- `category` : Catégorie (general, billing, system)
- `created_at` : Date de création
- `updated_at` : Date de dernière modification

## Services implémentés

### systemSettingsService

```typescript
// Récupérer tous les paramètres
systemSettingsService.getAll()

// Récupérer par catégorie
systemSettingsService.getByCategory('general')

// Récupérer par clé
systemSettingsService.getByKey('workshop_name')

// Mettre à jour un paramètre
systemSettingsService.update('workshop_name', 'Nouveau nom')

// Mettre à jour plusieurs paramètres
systemSettingsService.updateMultiple([
  { key: 'workshop_name', value: 'Nouveau nom' },
  { key: 'vat_rate', value: '21' }
])
```

## Actions du store

### loadSystemSettings()
Charge tous les paramètres depuis Supabase

### updateSystemSetting(key, value)
Met à jour un paramètre individuel

### updateMultipleSystemSettings(settings)
Met à jour plusieurs paramètres en une seule opération

## Dépannage

### Erreur "Table system_settings does not exist"
- Exécuter le script `create_system_settings_table.sql`
- Vérifier que la table a été créée dans Supabase

### Erreur "Permission denied"
- Vérifier que l'utilisateur a le rôle administrateur
- Vérifier les politiques RLS dans Supabase

### Paramètres non sauvegardés
- Vérifier la connexion à Supabase
- Vérifier les logs d'erreur dans la console
- Vérifier que les paramètres existent dans la table

### Valeurs par défaut non affichées
- Vérifier que les paramètres par défaut ont été insérés
- Vérifier la fonction `getSettingValue()` dans le code

## Tests

### Test de sauvegarde
1. Modifier un paramètre
2. Cliquer sur "Sauvegarder"
3. Vérifier la notification de succès
4. Recharger la page
5. Vérifier que la valeur persiste

### Test de catégories
1. Modifier un paramètre général
2. Sauvegarder
3. Modifier un paramètre de facturation
4. Sauvegarder
5. Vérifier que chaque catégorie est sauvegardée indépendamment

### Test d'erreur
1. Déconnecter internet
2. Essayer de sauvegarder
3. Vérifier l'affichage de l'erreur
4. Reconnecter et réessayer

## Notes importantes

- Les paramètres sont maintenant persistants dans Supabase
- Seuls les administrateurs peuvent modifier les paramètres
- Les sauvegardes sont effectuées par catégorie pour optimiser les performances
- Les valeurs par défaut sont utilisées si un paramètre n'existe pas
- Les erreurs sont gérées et affichées à l'utilisateur
