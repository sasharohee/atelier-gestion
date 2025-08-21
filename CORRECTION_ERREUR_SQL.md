# Correction de l'Erreur SQL

## ❌ Erreur Rencontrée
```
ERROR: 42601: unterminated quoted string at or near "' || SQLERRM
    );
END;
"
LINE 89:       'error', 'Erreur lors de la création de l\'utilisateur: ' || SQLERRM
                                                                       ^
```

## 🔍 Cause du Problème
L'erreur est causée par un problème d'échappement des apostrophes dans les chaînes de caractères SQL. En PostgreSQL, pour échapper une apostrophe dans une chaîne, il faut utiliser **deux apostrophes** (`''`) au lieu d'un backslash (`\'`).

## ✅ Solution

### Option 1 : Utiliser le Script Corrigé
Exécutez le fichier `create_user_function_fixed.sql` qui contient la syntaxe corrigée.

### Option 2 : Correction Manuelle
Remplacez cette ligne :
```sql
'error', 'Erreur lors de la création de l\'utilisateur: ' || SQLERRM
```

Par celle-ci :
```sql
'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
```

## 📋 Règles d'Échappement en PostgreSQL

### Dans les Chaînes de Caractères
- **Apostrophe simple** : `''` (deux apostrophes)
- **Guillemet double** : `""` (deux guillemets)

### Exemples
```sql
-- ❌ Incorrect
'Erreur lors de la création de l\'utilisateur'

-- ✅ Correct
'Erreur lors de la création de l''utilisateur'
```

## 🚀 Script Corrigé Complet

```sql
-- Fonction RPC corrigée pour créer un utilisateur
CREATE OR REPLACE FUNCTION create_user_simple_fixed(
  p_user_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_role TEXT DEFAULT 'technician',
  p_avatar TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel est un administrateur
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Accès non autorisé. Seuls les administrateurs peuvent créer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe déjà.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe déjà.'
    );
  END IF;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', p_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$$;

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_simple_fixed(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
```

## ✅ Étapes pour Résoudre

1. **Copiez le script corrigé** ci-dessus
2. **Allez dans votre dashboard Supabase**
3. **Cliquez sur "SQL Editor"**
4. **Collez le script et cliquez sur "Run"**
5. **Vérifiez que la fonction a été créée** dans la section "Database" > "Functions"

## 🔍 Vérification

Après l'exécution, vous devriez voir :
- ✅ Aucune erreur de syntaxe
- ✅ La fonction `create_user_simple_fixed` créée
- ✅ Les permissions accordées

## 📝 Note Importante

Cette erreur est courante lors de l'écriture de fonctions PostgreSQL. Toujours utiliser `''` pour échapper les apostrophes, pas `\'`.
