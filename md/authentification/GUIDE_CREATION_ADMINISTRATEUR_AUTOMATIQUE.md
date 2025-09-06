# Guide : Création Automatique d'Administrateur

## Vue d'ensemble

Cette fonctionnalité permet de créer automatiquement un compte administrateur pour l'utilisateur connecté lorsqu'il accède à la page Administration. Cela garantit qu'il y a toujours au moins un administrateur dans le système.

## Fonctionnement

### 1. Vérification automatique
- Lors de l'accès à la page Administration, le système vérifie automatiquement si l'utilisateur connecté existe dans la table `users`
- Si l'utilisateur n'existe pas, il est automatiquement créé avec le rôle `admin`
- Si l'utilisateur existe mais n'a pas le rôle `admin`, il est promu administrateur

### 2. Extraction intelligente du nom
- Si le prénom et nom ne sont pas disponibles, le système les extrait automatiquement de l'adresse email
- Exemple : `john.doe@example.com` → Prénom: `John`, Nom: `Doe`
- Si l'email ne contient pas de point, le nom complet devient le prénom et "Administrateur" devient le nom

### 3. Interface utilisateur
- Une bannière informative apparaît pour expliquer la fonctionnalité
- Un bouton "Créer maintenant" permet de déclencher manuellement la création
- Des notifications informent l'utilisateur du succès ou des erreurs

## Installation

### 1. Exécuter le script SQL
```sql
-- Exécuter le fichier create_admin_user_function.sql dans votre base de données Supabase
```

### 2. Vérifier les permissions
Assurez-vous que la fonction RPC a les bonnes permissions :
```sql
GRANT EXECUTE ON FUNCTION create_admin_user_auto(TEXT, TEXT, TEXT) TO authenticated;
```

## Utilisation

### Accès automatique
1. Connectez-vous à l'application
2. Naviguez vers la page Administration
3. Le système vérifie automatiquement votre compte
4. Si nécessaire, votre compte est créé ou promu administrateur

### Création manuelle
1. Sur la page Administration, cliquez sur le bouton "Créer mon compte admin"
2. Ou cliquez sur "Créer maintenant" dans la bannière d'information
3. Le système crée ou met à jour votre compte

## Fonction RPC

### Signature
```sql
create_admin_user_auto(
  p_email TEXT,
  p_first_name TEXT DEFAULT NULL,
  p_last_name TEXT DEFAULT NULL
) RETURNS JSON
```

### Paramètres
- `p_email` : L'adresse email de l'utilisateur (obligatoire)
- `p_first_name` : Le prénom (optionnel, extrait de l'email si non fourni)
- `p_last_name` : Le nom (optionnel, extrait de l'email si non fourni)

### Retour
```json
{
  "success": true,
  "message": "Utilisateur administrateur créé avec succès",
  "data": {
    "id": "uuid",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "role": "admin",
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

## Exemples d'utilisation

### Via l'interface
- Accédez à la page Administration
- Le système détecte automatiquement votre email connecté
- Votre compte est créé ou promu administrateur

### Via SQL direct
```sql
-- Créer un administrateur avec nom complet
SELECT create_admin_user_auto('admin@example.com', 'John', 'Doe');

-- Créer un administrateur avec extraction automatique du nom
SELECT create_admin_user_auto('john.doe@example.com');

-- Créer un administrateur avec email simple
SELECT create_admin_user_auto('admin@example.com');
```

## Gestion des erreurs

### Erreurs courantes
1. **Fonction RPC non disponible** : Le système utilise automatiquement une méthode de fallback
2. **Email déjà utilisé** : L'utilisateur existant est promu administrateur
3. **Erreur de connexion** : Vérifiez votre connexion à Supabase

### Messages d'erreur
- "Compte administrateur créé avec succès !"
- "Votre compte a été promu administrateur avec succès"
- "Erreur lors de la création du compte administrateur"

## Sécurité

### Permissions
- Seuls les utilisateurs authentifiés peuvent exécuter la fonction
- La fonction vérifie l'existence avant la création
- Les doublons sont gérés automatiquement

### Isolation des données
- Chaque utilisateur ne peut créer que son propre compte administrateur
- Les politiques RLS (Row Level Security) sont respectées

## Dépannage

### Problème : "Fonction RPC non disponible"
**Solution** : Exécutez le script SQL `create_admin_user_function.sql`

### Problème : "Erreur de permission"
**Solution** : Vérifiez que la fonction a les bonnes permissions :
```sql
GRANT EXECUTE ON FUNCTION create_admin_user_auto(TEXT, TEXT, TEXT) TO authenticated;
```

### Problème : "Utilisateur non trouvé"
**Solution** : Vérifiez que vous êtes bien connecté et que votre email est correct

## Avantages

1. **Simplicité** : Création automatique sans intervention manuelle
2. **Sécurité** : Vérification et promotion automatique des comptes
3. **Flexibilité** : Extraction intelligente des noms depuis l'email
4. **Robustesse** : Méthode de fallback si la fonction RPC n'est pas disponible
5. **Interface intuitive** : Notifications claires et boutons d'action

## Notes importantes

- Le mot de passe temporaire "admin123" est utilisé pour la création via l'interface
- Il est recommandé de changer ce mot de passe après la première connexion
- La fonction est idempotente : elle peut être appelée plusieurs fois sans effet secondaire
- Les utilisateurs existants sont automatiquement promus administrateur si nécessaire
