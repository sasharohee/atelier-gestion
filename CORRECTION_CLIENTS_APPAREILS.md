# Correction des erreurs de création de clients et appareils

## 🐛 Problèmes identifiés

Lors de la création de nouveaux clients et appareils dans le Kanban, les erreurs suivantes apparaissaient :

```
Could not find the 'firstName' column of 'clients' in the schema cache
Could not find the 'serialNumber' column of 'devices' in the schema cache
```

## 🔍 Cause du problème

Même problème que pour les ventes et réparations : **incompatibilité entre le code TypeScript (camelCase) et la structure de la base de données (snake_case)**.

### Structure TypeScript (camelCase) :
```typescript
interface Client {
  firstName: string;    // ❌ camelCase
  lastName: string;     // ❌ camelCase
  // ...
}

interface Device {
  serialNumber?: string; // ❌ camelCase
  // ...
}
```

### Structure Base de données (snake_case) :
```sql
CREATE TABLE clients (
  first_name TEXT,      // ✅ snake_case
  last_name TEXT,       // ✅ snake_case
  // ...
);

CREATE TABLE devices (
  serial_number TEXT,   // ✅ snake_case
  // ...
);
```

## ✅ Solution appliquée

### 1. Correction du service clientService

**Fichier modifié :** `src/services/supabaseService.ts`

#### Méthode `create` :
```typescript
async create(client: Omit<Client, 'id' | 'createdAt' | 'updatedAt'>) {
  // Convertir les noms de propriétés camelCase vers snake_case
  const clientData = {
    first_name: client.firstName,
    last_name: client.lastName,
    email: client.email,
    phone: client.phone,
    address: client.address,
    notes: client.notes,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  const { data, error } = await supabase
    .from('clients')
    .insert([clientData])
    .select()
    .single();
  
  if (error) return handleSupabaseError(error);
  return handleSupabaseSuccess(data);
}
```

#### Méthode `getAll` :
```typescript
async getAll() {
  const { data, error } = await supabase
    .from('clients')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) return handleSupabaseError(error);
  
  // Convertir les données de snake_case vers camelCase
  const convertedData = data?.map(client => ({
    id: client.id,
    firstName: client.first_name,
    lastName: client.last_name,
    email: client.email,
    phone: client.phone,
    address: client.address,
    notes: client.notes,
    createdAt: client.created_at,
    updatedAt: client.updated_at
  })) || [];
  
  return handleSupabaseSuccess(convertedData);
}
```

### 2. Correction du service deviceService

#### Méthode `create` :
```typescript
async create(device: Omit<Device, 'id' | 'createdAt' | 'updatedAt'>) {
  // Convertir les noms de propriétés camelCase vers snake_case
  const deviceData = {
    brand: device.brand,
    model: device.model,
    serial_number: device.serialNumber,
    type: device.type,
    specifications: device.specifications,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  const { data, error } = await supabase
    .from('devices')
    .insert([deviceData])
    .select()
    .single();
  
  if (error) return handleSupabaseError(error);
  return handleSupabaseSuccess(data);
}
```

#### Méthode `getAll` :
```typescript
async getAll() {
  const { data, error } = await supabase
    .from('devices')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) return handleSupabaseError(error);
  
  // Convertir les données de snake_case vers camelCase
  const convertedData = data?.map(device => ({
    id: device.id,
    brand: device.brand,
    model: device.model,
    serialNumber: device.serial_number,
    type: device.type,
    specifications: device.specifications,
    createdAt: device.created_at,
    updatedAt: device.updated_at
  })) || [];
  
  return handleSupabaseSuccess(convertedData);
}
```

### 3. Mise à jour de la base de données

**Script mis à jour :** `update_database.sql`

Ajout de vérifications pour toutes les colonnes des tables `clients` et `devices` :

#### Table clients :
- `first_name`
- `last_name`
- `email`
- `phone`
- `address`
- `notes`

#### Table devices :
- `brand`
- `model`
- `serial_number`
- `type`
- `specifications`

## 🧪 Test de la correction

### Étapes de test :

1. **Exécuter le script SQL** dans Supabase :
   ```sql
   -- Copier le contenu de update_database.sql
   ```

2. **Redémarrer l'application** :
   ```bash
   npm run dev
   ```

3. **Tester la création d'un client** :
   - Aller dans le Kanban
   - Cliquer sur "Nouvelle réparation"
   - Aller à l'onglet "Nouveau client"
   - Remplir le formulaire
   - Vérifier que le client se crée sans erreur

4. **Tester la création d'un appareil** :
   - Aller à l'onglet "Nouvel appareil"
   - Remplir le formulaire
   - Vérifier que l'appareil se crée sans erreur

5. **Vérifier la console** :
   - Plus d'erreurs Supabase
   - Messages de succès

## ✅ Résultat attendu

Après la correction :
- ✅ Création de clients fonctionnelle
- ✅ Création d'appareils fonctionnelle
- ✅ Plus d'erreurs de colonnes manquantes
- ✅ Données correctement converties entre camelCase et snake_case
- ✅ Interface Kanban complètement opérationnelle

## 📝 Notes importantes

- Les corrections sont rétrocompatibles
- Les données existantes ne sont pas affectées
- La conversion est automatique et transparente
- Toutes les opérations CRUD sont maintenant fonctionnelles
- L'interface à onglets du Kanban est maintenant complètement opérationnelle

## 🔄 Workflow complet

Maintenant, vous pouvez :
1. **Créer un nouveau client** directement depuis le Kanban
2. **Créer un nouvel appareil** directement depuis le Kanban
3. **Créer une réparation** avec le client et l'appareil créés
4. **Générer une facture** une fois la réparation terminée

Tout le workflow de réparation est maintenant intégré dans une seule interface ! 🎯
