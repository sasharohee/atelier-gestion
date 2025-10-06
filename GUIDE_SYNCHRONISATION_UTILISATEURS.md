# Guide de Synchronisation des Utilisateurs

## Problème Identifié

Il manque 3 utilisateurs dans la table `subscription_status` qui sont présents dans Supabase Auth :

1. **bilal bouhabane** (`bb0ee44a-a2bc-49ca-818a-8217e4346159`)
2. **Abdelhadi Ouldmiloud** (`d98c9371-a08e-4306-8454-64989d75c4e5`) 
3. **Fayçal El guerrouj** (`4de309fa-d33c-4472-93ce-14357d61ff6a`)

## Solutions Disponibles

### Option 1 : Synchronisation Manuelle (Recommandée)

Exécutez le script SQL `sync_missing_users.sql` dans l'éditeur SQL de Supabase :

```sql
-- Ce script ajoute les 3 utilisateurs manquants
-- Les utilisateurs seront créés avec is_active = false (en attente d'activation)
```

### Option 2 : Synchronisation Automatique Complète

Exécutez le script `sync_all_users_complete.sql` pour synchroniser TOUS les utilisateurs :

```sql
-- Ce script synchronise tous les utilisateurs Supabase Auth
-- vers la table subscription_status
```

### Option 3 : Script JavaScript (Avancé)

Utilisez le script `sync_all_users_to_subscription_status.js` pour une synchronisation programmatique.

## Étapes de Résolution

### 1. Accéder à l'Éditeur SQL Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Sélectionnez votre projet
3. Allez dans "SQL Editor" dans le menu de gauche
4. Créez une nouvelle requête

### 2. Exécuter la Synchronisation

**Pour les 3 utilisateurs manquants :**
```sql
-- Copiez et exécutez le contenu de sync_missing_users.sql
```

**Pour tous les utilisateurs :**
```sql
-- Copiez et exécutez le contenu de sync_all_users_complete.sql
```

### 3. Vérifier le Résultat

Après exécution, vérifiez que les utilisateurs apparaissent dans votre interface de gestion des accès.

## Configuration des Utilisateurs Synchronisés

- **Statut** : `is_active = false` (en attente d'activation)
- **Type d'abonnement** : `free`
- **Notes** : "Utilisateur synchronisé depuis Supabase Auth - en attente d'activation"

## Activation des Utilisateurs

Une fois synchronisés, vous pouvez :

1. Aller dans l'interface de gestion des accès
2. Trouver les utilisateurs synchronisés
3. Cliquer sur le bouton "Activer" pour leur donner l'accès
4. Ajouter des notes explicatives si nécessaire

## Prévention Future

Pour éviter ce problème à l'avenir, vous pouvez :

1. **Créer un trigger** qui synchronise automatiquement les nouveaux utilisateurs
2. **Utiliser un webhook** Supabase pour synchroniser en temps réel
3. **Vérifier régulièrement** la cohérence entre les deux tables

## Vérification Post-Synchronisation

Après la synchronisation, vérifiez que :

- ✅ Les 3 utilisateurs apparaissent dans l'interface
- ✅ Leur statut est "En attente d'activation"
- ✅ Vous pouvez les activer/désactiver
- ✅ Les données sont cohérentes

## Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs dans la console Supabase
2. Assurez-vous d'avoir les bonnes permissions
3. Contactez l'administrateur système si nécessaire
