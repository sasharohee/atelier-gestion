# Dépannage : Problème de Création d'Administrateur

## Problème
Le bouton "Créer mon compte administrateur" ne fonctionne pas.

## Étapes de diagnostic

### 1. Vérifier la console du navigateur
1. Ouvrez les outils de développement (F12)
2. Allez dans l'onglet "Console"
3. Cliquez sur le bouton "Créer mon compte admin"
4. Notez les messages d'erreur affichés

### 2. Vérifier si vous êtes connecté
- Assurez-vous d'être connecté à l'application
- Vérifiez que votre email apparaît dans l'interface

### 3. Exécuter le script de diagnostic
Exécutez le fichier `diagnostic_admin_function.sql` dans votre base de données Supabase pour vérifier :
- Si les fonctions RPC existent
- Si la table `users` existe
- Si les permissions sont correctes

### 4. Installer les fonctions RPC

#### Option A : Fonction simplifiée (recommandée)
```sql
-- Exécuter le fichier create_simple_admin_function.sql
```

#### Option B : Fonction complète
```sql
-- Exécuter le fichier create_admin_user_function.sql
```

### 5. Vérifier les permissions
```sql
-- Vérifier que les fonctions ont les bonnes permissions
GRANT EXECUTE ON FUNCTION create_simple_admin_user(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION create_admin_user_auto(TEXT, TEXT, TEXT) TO authenticated;
```

### 6. Tester manuellement
```sql
-- Tester la fonction simplifiée
SELECT create_simple_admin_user('votre.email@example.com');

-- Ou tester la fonction complète
SELECT create_admin_user_auto('votre.email@example.com', 'Votre', 'Nom');
```

## Solutions courantes

### Problème : "Function does not exist"
**Solution** : Exécutez les scripts SQL pour créer les fonctions RPC

### Problème : "Permission denied"
**Solution** : Vérifiez que les permissions sont correctement accordées

### Problème : "Table users does not exist"
**Solution** : Créez la table users avec la structure appropriée

### Problème : "RLS policy violation"
**Solution** : Vérifiez les politiques RLS sur la table users

## Structure de table users requise

```sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'technician' CHECK (role IN ('admin', 'manager', 'technician')),
    avatar TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activer RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Politique de base (ajustez selon vos besoins)
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can manage all users" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

## Test de la fonctionnalité

### 1. Utiliser le bouton "Test RPC"
- Cliquez sur le bouton "Test RPC" dans l'interface
- Vérifiez le message de succès ou d'erreur

### 2. Vérifier les logs
- Ouvrez la console du navigateur
- Cliquez sur "Créer mon compte admin"
- Vérifiez les messages de débogage

### 3. Vérifier la base de données
```sql
-- Vérifier si l'utilisateur a été créé
SELECT * FROM users WHERE email = 'votre.email@example.com';

-- Vérifier tous les utilisateurs
SELECT id, first_name, last_name, email, role, created_at 
FROM users 
ORDER BY created_at DESC;
```

## Messages d'erreur courants et solutions

| Erreur | Solution |
|--------|----------|
| "Function does not exist" | Exécuter les scripts SQL |
| "Permission denied" | Vérifier les permissions GRANT |
| "Table users does not exist" | Créer la table users |
| "RLS policy violation" | Ajuster les politiques RLS |
| "Aucun utilisateur connecté" | Se connecter à l'application |
| "Erreur de connexion" | Vérifier la connexion Supabase |

## Contact et support

Si le problème persiste après avoir suivi ces étapes :
1. Notez les messages d'erreur exacts
2. Vérifiez la structure de votre base de données
3. Testez les fonctions RPC manuellement
4. Consultez les logs Supabase pour plus de détails
