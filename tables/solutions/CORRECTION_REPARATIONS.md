# Correction des erreurs de réparations

## 🐛 Problème identifié

Lors de la création d'une réparation, l'erreur suivante apparaissait :
```
Could not find the 'clientId' column of 'repairs' in the schema cache
```

## 🔍 Cause du problème

Même problème que pour les ventes : **incompatibilité entre le code TypeScript (camelCase) et la structure de la base de données (snake_case)**.

### Structure TypeScript (camelCase) :
```typescript
interface Repair {
  clientId: string;        // ❌ camelCase
  deviceId: string;        // ❌ camelCase
  assignedTechnicianId?: string; // ❌ camelCase
  estimatedDuration: number;     // ❌ camelCase
  // ...
}
```

### Structure Base de données (snake_case) :
```sql
CREATE TABLE repairs (
  client_id UUID,              // ✅ snake_case
  device_id UUID,              // ✅ snake_case
  assigned_technician_id UUID, // ✅ snake_case
  estimated_duration INTEGER,  // ✅ snake_case
  // ...
);
```

## ✅ Solution appliquée

### 1. Correction du service repairService

**Fichier modifié :** `src/services/supabaseService.ts`

#### Méthode `create` :
```typescript
async create(repair: Omit<Repair, 'id' | 'createdAt' | 'updatedAt'>) {
  // Convertir les noms de propriétés camelCase vers snake_case
  const repairData = {
    client_id: repair.clientId,
    device_id: repair.deviceId,
    status: repair.status,
    assigned_technician_id: repair.assignedTechnicianId,
    description: repair.description,
    issue: repair.issue,
    estimated_duration: repair.estimatedDuration,
    actual_duration: repair.actualDuration,
    estimated_start_date: repair.estimatedStartDate,
    estimated_end_date: repair.estimatedEndDate,
    start_date: repair.startDate,
    end_date: repair.endDate,
    due_date: repair.dueDate,
    is_urgent: repair.isUrgent,
    notes: repair.notes,
    total_price: repair.totalPrice,
    is_paid: repair.isPaid,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  const { data, error } = await supabase
    .from('repairs')
    .insert([repairData])
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
    .from('repairs')
    .select('*')
    .order('created_at', { ascending: false });
  
  if (error) return handleSupabaseError(error);
  
  // Convertir les données de snake_case vers camelCase
  const convertedData = data?.map(repair => ({
    id: repair.id,
    clientId: repair.client_id,
    deviceId: repair.device_id,
    status: repair.status,
    assignedTechnicianId: repair.assigned_technician_id,
    description: repair.description,
    issue: repair.issue,
    estimatedDuration: repair.estimated_duration,
    actualDuration: repair.actual_duration,
    estimatedStartDate: repair.estimated_start_date,
    estimatedEndDate: repair.estimated_end_date,
    startDate: repair.start_date,
    endDate: repair.end_date,
    dueDate: repair.due_date,
    isUrgent: repair.is_urgent,
    notes: repair.notes,
    services: [], // Tableau vide par défaut
    parts: [], // Tableau vide par défaut
    totalPrice: repair.total_price,
    isPaid: repair.is_paid,
    createdAt: repair.created_at,
    updatedAt: repair.updated_at
  })) || [];
  
  return handleSupabaseSuccess(convertedData);
}
```

#### Méthode `update` :
```typescript
async update(id: string, updates: Partial<Repair>) {
  // Convertir les noms de propriétés camelCase vers snake_case
  const updateData: any = { updated_at: new Date().toISOString() };
  
  if (updates.clientId !== undefined) updateData.client_id = updates.clientId;
  if (updates.deviceId !== undefined) updateData.device_id = updates.deviceId;
  if (updates.status !== undefined) updateData.status = updates.status;
  if (updates.assignedTechnicianId !== undefined) updateData.assigned_technician_id = updates.assignedTechnicianId;
  if (updates.description !== undefined) updateData.description = updates.description;
  if (updates.issue !== undefined) updateData.issue = updates.issue;
  if (updates.estimatedDuration !== undefined) updateData.estimated_duration = updates.estimatedDuration;
  if (updates.actualDuration !== undefined) updateData.actual_duration = updates.actualDuration;
  if (updates.estimatedStartDate !== undefined) updateData.estimated_start_date = updates.estimatedStartDate;
  if (updates.estimatedEndDate !== undefined) updateData.estimated_end_date = updates.estimatedEndDate;
  if (updates.startDate !== undefined) updateData.start_date = updates.startDate;
  if (updates.endDate !== undefined) updateData.end_date = updates.endDate;
  if (updates.dueDate !== undefined) updateData.due_date = updates.dueDate;
  if (updates.isUrgent !== undefined) updateData.is_urgent = updates.isUrgent;
  if (updates.notes !== undefined) updateData.notes = updates.notes;
  if (updates.totalPrice !== undefined) updateData.total_price = updates.totalPrice;
  if (updates.isPaid !== undefined) updateData.is_paid = updates.isPaid;

  const { data, error } = await supabase
    .from('repairs')
    .update(updateData)
    .eq('id', id)
    .select()
    .single();
  
  if (error) return handleSupabaseError(error);
  return handleSupabaseSuccess(data);
}
```

### 2. Mise à jour de la base de données

**Script mis à jour :** `update_database.sql`

Ajout de vérifications pour toutes les colonnes de la table `repairs` :
- `client_id`
- `device_id`
- `assigned_technician_id`
- `estimated_duration`
- `actual_duration`
- `estimated_start_date`
- `estimated_end_date`
- `start_date`
- `end_date`
- `due_date`
- `is_urgent`
- `total_price`
- `is_paid`

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

3. **Tester la création d'une réparation** :
   - Aller dans le Kanban
   - Cliquer sur "Nouvelle réparation"
   - Remplir le formulaire
   - Vérifier que la réparation se crée sans erreur

4. **Vérifier la console** :
   - Plus d'erreurs Supabase
   - Messages de succès

## ✅ Résultat attendu

Après la correction :
- ✅ Création de réparations fonctionnelle
- ✅ Plus d'erreurs de colonnes manquantes
- ✅ Données correctement converties entre camelCase et snake_case
- ✅ Interface Kanban opérationnelle

## 📝 Notes importantes

- Les corrections sont rétrocompatibles
- Les données existantes ne sont pas affectées
- La conversion est automatique et transparente
- Toutes les opérations CRUD sont maintenant fonctionnelles
