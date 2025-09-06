# 🔧 Instructions pour l'Isolation des Données

## 🚨 Problème
L'isolation ne fonctionne pas dans la page modèle - les modèles créés sur le compte A apparaissent aussi sur le compte B.

## ✅ Solution Appliquée
Nous avons créé une approche agressive avec :
- **Vues filtrées** : `device_models_filtered`, `clients_filtered`, etc.
- **Fonctions de service** : `get_my_device_models()`, `create_device_model()`
- **Triggers agressifs** : Forcent l'assignation de `user_id`/`created_by`

## 🔄 Modifications Nécessaires dans l'Application

### 1. Modifier le service Supabase

Dans `src/services/supabaseService.ts`, remplacer les requêtes directes par les vues filtrées :

```typescript
// AVANT (ligne ~2150)
export const deviceModelService = {
  async getAll() {
    const { data, error } = await supabase
      .from('device_models')  // ❌ Table directe
      .select('*')
      .order('brand', { ascending: true })
      .order('model', { ascending: true });

// APRÈS
export const deviceModelService = {
  async getAll() {
    const { data, error } = await supabase
      .from('device_models_filtered')  // ✅ Vue filtrée
      .select('*')
      .order('brand', { ascending: true })
      .order('model', { ascending: true });
```

### 2. Alternative : Utiliser les fonctions PostgreSQL

Ou utiliser les fonctions créées :

```typescript
export const deviceModelService = {
  async getAll() {
    const { data, error } = await supabase
      .rpc('get_my_device_models');  // ✅ Fonction filtrée
    
    if (error) return handleSupabaseError(error);
    
    // Convertir les données
    const convertedData = data?.map(model => ({
      id: model.id,
      brand: model.brand,
      model: model.model,
      type: model.type,
      year: model.year,
      specifications: model.specifications || {},
      commonIssues: model.common_issues || [],
      repairDifficulty: model.repair_difficulty,
      partsAvailability: model.parts_availability,
      isActive: model.is_active,
      createdAt: new Date(model.created_at),
      updatedAt: new Date(model.updated_at)
    })) || [];
    
    return handleSupabaseSuccess(convertedData);
  },

  async create(model: any) {
    // Utiliser la fonction PostgreSQL
    const { data, error } = await supabase
      .rpc('create_device_model', {
        p_brand: model.brand,
        p_model: model.model,
        p_type: model.type,
        p_year: model.year,
        p_specifications: model.specifications || {},
        p_common_issues: model.commonIssues || [],
        p_repair_difficulty: model.repairDifficulty,
        p_parts_availability: model.partsAvailability,
        p_is_active: model.isActive !== undefined ? model.isActive : true
      });
    
    if (error) return handleSupabaseError(error);
    
    // Récupérer le modèle créé
    const { data: createdModel, error: fetchError } = await supabase
      .from('device_models_filtered')
      .select('*')
      .eq('id', data)
      .single();
    
    if (fetchError) return handleSupabaseError(fetchError);
    
    // Convertir la réponse
    const convertedData = {
      id: createdModel.id,
      brand: createdModel.brand,
      model: createdModel.model,
      type: createdModel.type,
      year: createdModel.year,
      specifications: createdModel.specifications || {},
      commonIssues: createdModel.common_issues || [],
      repairDifficulty: createdModel.repair_difficulty,
      partsAvailability: createdModel.parts_availability,
      isActive: createdModel.is_active,
      createdAt: new Date(createdModel.created_at),
      updatedAt: new Date(createdModel.updated_at)
    };
    
    return handleSupabaseSuccess(convertedData);
  }
};
```

### 3. Modifier les autres services

Faire la même chose pour les autres services :

```typescript
// clients
.from('clients_filtered')

// devices  
.from('devices_filtered')

// repairs
.from('repairs_filtered')
```

## 🧪 Test de l'Isolation

### Test 1 : Création
1. Se connecter avec le compte A
2. Créer un modèle d'appareil
3. Vérifier qu'il apparaît dans la liste

### Test 2 : Isolation
1. Se déconnecter
2. Se connecter avec le compte B
3. Vérifier que le modèle du compte A n'apparaît PAS

### Test 3 : Vérification SQL
```sql
-- Vérifier les données par utilisateur
SELECT 
    created_by,
    COUNT(*) as nombre_modeles
FROM device_models 
GROUP BY created_by;

-- Tester la vue filtrée
SELECT COUNT(*) FROM device_models_filtered;
```

## 🔍 Diagnostic en Cas de Problème

Si l'isolation ne fonctionne toujours pas :

1. **Vérifier les triggers** :
```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE event_object_table = 'device_models';
```

2. **Vérifier les vues** :
```sql
SELECT viewname FROM pg_views 
WHERE schemaname = 'public' 
AND viewname LIKE '%_filtered';
```

3. **Vérifier les fonctions** :
```sql
SELECT proname FROM pg_proc 
WHERE proname IN ('get_my_device_models', 'create_device_model');
```

4. **Tester manuellement** :
```sql
-- Créer un modèle de test
INSERT INTO device_models (brand, model, type, year)
VALUES ('Test', 'Isolation', 'other', 2024);

-- Vérifier qu'il a le bon created_by
SELECT created_by FROM device_models WHERE brand = 'Test';
```

## ✅ Résultat Attendu

Après ces modifications :
- ✅ Chaque utilisateur ne voit que ses propres modèles
- ✅ Les modèles créés sont automatiquement assignés à l'utilisateur connecté
- ✅ L'isolation fonctionne sur toutes les pages (modèles, clients, appareils, réparations)
- ✅ Pas de partage de données entre comptes différents
