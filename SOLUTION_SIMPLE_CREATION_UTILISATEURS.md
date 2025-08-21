# Solution Simple pour la Création d'Utilisateurs

## Problème
L'API `supabase.auth.admin.createUser` nécessite des permissions spéciales qui ne sont pas toujours disponibles dans les projets Supabase standard.

## Solution Alternative

### 1. Créer l'Utilisateur via l'Interface Supabase
1. Allez dans votre dashboard Supabase
2. Cliquez sur "Authentication" > "Users"
3. Cliquez sur "Add User"
4. Remplissez les informations :
   - Email
   - Mot de passe
   - Confirmez l'email
5. Cliquez sur "Create User"

### 2. Créer l'Enregistrement dans la Table Users
Une fois l'utilisateur créé dans auth.users, utilisez la fonction RPC pour créer l'enregistrement dans la table users :

```sql
-- Exécutez cette fonction avec l'ID de l'utilisateur créé
SELECT create_user_simple(
  'user-uuid-from-auth', -- Remplacez par l'ID réel
  'John',
  'Doe',
  'john.doe@example.com',
  'technician',
  NULL
);
```

### 3. Modification du Code Frontend
Modifiez temporairement le code pour ne créer que l'enregistrement dans la table users :

```typescript
// Dans supabaseService.ts, remplacer la fonction createUser par :
async createUser(userData: Omit<User, 'id' | 'createdAt' | 'updatedAt'> & { password: string }) {
  try {
    console.log('🔧 Création d\'utilisateur:', userData);
    
    // Générer un ID temporaire (sera remplacé par l'ID réel)
    const tempId = crypto.randomUUID();
    
    // Créer l'enregistrement dans la table users
    const userRecord = {
      id: tempId,
      first_name: userData.firstName,
      last_name: userData.lastName,
      email: userData.email,
      role: userData.role,
      avatar: userData.avatar,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    console.log('📝 Enregistrement utilisateur à créer:', userRecord);

    const { data, error } = await supabase
      .from('users')
      .insert([userRecord])
      .select()
      .single();

    if (error) {
      console.error('❌ Erreur lors de la création:', error);
      return handleSupabaseError(error);
    }
    
    console.log('✅ Utilisateur créé avec succès:', data);
    return handleSupabaseSuccess(data);
  } catch (err) {
    console.error('💥 Exception lors de la création:', err);
    return handleSupabaseError(err as any);
  }
}
```

### 4. Workflow Recommandé
1. Créez l'utilisateur dans auth.users via l'interface Supabase
2. Notez l'ID de l'utilisateur créé
3. Utilisez cet ID pour créer l'enregistrement dans la table users
4. Ou modifiez temporairement le code pour créer directement dans users

### 5. Solution Automatisée
Pour une solution plus automatisée, vous pouvez :
1. Créer un webhook qui se déclenche lors de la création d'un utilisateur dans auth.users
2. Utiliser ce webhook pour créer automatiquement l'enregistrement dans la table users
3. Ou utiliser des triggers PostgreSQL pour synchroniser les deux tables

## Avantages de cette Approche
- Pas besoin de permissions admin spéciales
- Plus simple à mettre en place
- Moins de risques d'erreurs
- Compatible avec tous les projets Supabase

## Inconvénients
- Processus manuel pour la création d'utilisateurs
- Nécessite une intervention manuelle pour lier auth.users et users

## Recommandation
Pour un usage en production, considérez l'utilisation de webhooks ou de triggers pour automatiser le processus.
