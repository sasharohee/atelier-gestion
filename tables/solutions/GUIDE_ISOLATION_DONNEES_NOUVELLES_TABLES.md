# 🔒 Guide d'Isolation des Données - Nouvelles Tables

## 📋 Vue d'ensemble

Ce guide explique comment l'isolation des données est implémentée pour les nouvelles tables créées dans l'application. L'isolation garantit que chaque atelier ne peut voir et modifier que ses propres données.

## 🏗️ Architecture d'Isolation

### 1. **Colonne `workshop_id`**
Chaque nouvelle table contient une colonne `workshop_id` qui identifie l'atelier propriétaire des données.

### 2. **Colonne `created_by`**
Pour les tables de création, une colonne `created_by` enregistre l'utilisateur qui a créé l'enregistrement.

### 3. **Politiques RLS (Row Level Security)**
Des politiques PostgreSQL contrôlent l'accès aux données basé sur le rôle utilisateur et l'atelier.

## 📊 Tables Concernées

| Table | Description | Isolation |
|-------|-------------|-----------|
| `device_models` | Modèles d'appareils | ✅ `workshop_id` + `created_by` |
| `performance_metrics` | Métriques de performance | ✅ `workshop_id` + `created_by` |
| `reports` | Rapports générés | ✅ `workshop_id` |
| `advanced_alerts` | Alertes avancées | ✅ `workshop_id` |
| `technician_performance` | Performance des techniciens | ✅ `workshop_id` |
| `transactions` | Transactions financières | ✅ `workshop_id` |
| `activity_logs` | Logs d'activité | ✅ `workshop_id` |
| `advanced_settings` | Paramètres avancés | ✅ `workshop_id` |

## 🔐 Politiques de Sécurité

### **Lecture (SELECT)**
- **Toutes les tables** : Seules les données de l'atelier actuel sont visibles
- **Reports** : L'utilisateur voit ses propres rapports + tous les rapports (admin)
- **Alerts** : L'utilisateur voit ses alertes + alertes de son rôle

### **Écriture (INSERT/UPDATE/DELETE)**
- **Device Models** : Techniciens et admins peuvent créer/modifier
- **Performance Metrics** : Admins seulement
- **Reports** : Tous les utilisateurs peuvent créer leurs rapports
- **Alerts** : Mise à jour par l'utilisateur cible
- **Transactions** : Techniciens et admins
- **Activity Logs** : Création automatique, lecture admin seulement
- **Settings** : Admins seulement

## ⚙️ Automatisation

### **Fonction `set_workshop_context()`**
```sql
-- Définit automatiquement workshop_id et created_by
CREATE OR REPLACE FUNCTION set_workshop_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    );
    
    IF TG_OP = 'INSERT' THEN
        NEW.created_by = auth.uid();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### **Triggers Automatiques**
Chaque table a un trigger qui exécute `set_workshop_context()` avant INSERT/UPDATE.

## 🔍 Vérification de l'Isolation

### **Fonction `verify_data_isolation()`**
```sql
-- Vérifie le niveau d'isolation par table
SELECT * FROM verify_data_isolation();
```

**Résultat attendu :**
```
table_name           | total_rows | isolated_rows | isolation_percentage
device_models        | 10         | 10            | 100.00
performance_metrics  | 5          | 5             | 100.00
reports              | 8          | 8             | 100.00
...
```

## 🛡️ Contraintes de Sécurité

### **Contraintes NOT NULL**
```sql
-- workshop_id ne peut jamais être NULL
ALTER TABLE device_models ALTER COLUMN workshop_id SET NOT NULL;
ALTER TABLE performance_metrics ALTER COLUMN workshop_id SET NOT NULL;
-- ... (toutes les tables)
```

### **Contraintes de Référence**
```sql
-- created_by doit référencer un utilisateur valide
ALTER TABLE device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
```

## 📈 Index de Performance

### **Index sur workshop_id**
```sql
-- Optimise les requêtes filtrées par atelier
CREATE INDEX idx_device_models_workshop ON device_models(workshop_id);
CREATE INDEX idx_performance_metrics_workshop ON performance_metrics(workshop_id);
-- ... (toutes les tables)
```

## 🔧 Utilisation dans l'Application

### **Frontend (React)**
```typescript
// Les requêtes Supabase sont automatiquement filtrées par workshop_id
const { data: models } = await supabase
  .from('device_models')
  .select('*');
// Seuls les modèles de l'atelier actuel sont retournés
```

### **Backend (Supabase)**
```sql
-- Les politiques RLS s'appliquent automatiquement
SELECT * FROM device_models;
-- Équivalent à :
SELECT * FROM device_models 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id');
```

## 🚨 Gestion des Erreurs

### **Cas d'Erreur Courants**
1. **workshop_id manquant** : Utilise l'UUID par défaut
2. **Utilisateur non authentifié** : Bloque l'accès
3. **Rôle insuffisant** : Retourne une erreur de permission

### **Logs de Sécurité**
```sql
-- Les tentatives d'accès non autorisées sont loggées
INSERT INTO activity_logs (action, entity_type, entity_id, user_id, workshop_id)
VALUES ('unauthorized_access', 'device_models', NULL, auth.uid(), 
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id'));
```

## 📋 Checklist de Vérification

### **Avant Déploiement**
- [ ] Toutes les tables ont une colonne `workshop_id`
- [ ] Les politiques RLS sont activées
- [ ] Les triggers sont créés
- [ ] Les index sont optimisés
- [ ] Les contraintes sont définies

### **Après Déploiement**
- [ ] Exécuter `verify_data_isolation()`
- [ ] Tester l'accès avec différents rôles
- [ ] Vérifier les performances des requêtes
- [ ] Tester la création de nouveaux enregistrements

## 🔄 Migration des Données Existantes

### **Script de Migration**
```sql
-- Exécuter improve_data_isolation.sql
-- Ce script :
-- 1. Ajoute les colonnes workshop_id et created_by
-- 2. Met à jour les données existantes
-- 3. Crée les nouvelles politiques RLS
-- 4. Ajoute les contraintes et index
```

## 📚 Bonnes Pratiques

### **Développement**
1. **Toujours inclure workshop_id** dans les nouvelles tables
2. **Tester l'isolation** avec différents ateliers
3. **Documenter les politiques** de sécurité
4. **Optimiser les requêtes** avec les index appropriés

### **Maintenance**
1. **Surveiller les performances** des requêtes filtrées
2. **Vérifier régulièrement** l'isolation des données
3. **Mettre à jour les politiques** si nécessaire
4. **Sauvegarder** les configurations de sécurité

## 🎯 Avantages de cette Approche

### **Sécurité**
- ✅ Isolation complète des données par atelier
- ✅ Contrôle d'accès basé sur les rôles
- ✅ Audit trail avec `created_by`
- ✅ Protection contre les fuites de données

### **Performance**
- ✅ Index optimisés pour les requêtes filtrées
- ✅ Requêtes automatiquement optimisées
- ✅ Pas de surcharge de filtrage manuel

### **Maintenabilité**
- ✅ Configuration centralisée
- ✅ Politiques réutilisables
- ✅ Documentation complète
- ✅ Tests automatisés possibles

## 🔗 Fichiers Associés

- `create_new_tables.sql` : Création initiale des tables
- `improve_data_isolation.sql` : Amélioration de l'isolation
- `src/types/index.ts` : Types TypeScript pour les nouvelles tables
- `src/pages/Catalog/Models.tsx` : Interface de gestion des modèles
- `src/pages/Statistics/Statistics.tsx` : Dashboard avec données isolées
