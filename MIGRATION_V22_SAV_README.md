# 🔧 Migration V22 - Tables et Fonctionnalités SAV

## 📋 Résumé

La migration V22 ajoute toutes les tables et fonctionnalités nécessaires pour la page SAV (Service Après-Vente). Elle complète la migration V21 en ajoutant la gestion complète des réparations, pièces, services et suivi.

## 🎯 Fonctionnalités SAV Ajoutées

### ✅ **Tables Principales**
- **`repairs`** - Gestion des réparations avec colonne `source`
- **`parts`** - Gestion des pièces de rechange et stock
- **`services`** - Catalogue des services de réparation
- **`repair_parts`** - Liaison réparations ↔ pièces
- **`repair_services`** - Liaison réparations ↔ services

### ✅ **Tables de Suivi**
- **`appointments`** - Gestion des rendez-vous
- **`messages`** - Communication interne
- **`notifications`** - Alertes et notifications
- **`stock_alerts`** - Alertes de stock faible

### ✅ **Fonctionnalités Avancées**
- **Numérotation automatique** des réparations (R000001, R000002, etc.)
- **Vérification de stock** en temps réel
- **Alertes automatiques** de stock faible
- **Gestion des garanties** (90 jours par défaut)
- **Suivi des rendez-vous** et messages

## 📊 Structure des Tables

### Table `repairs` (Réparations)
```sql
CREATE TABLE public.repairs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    client_id UUID REFERENCES public.clients(id),
    device_id UUID REFERENCES public.devices(id),
    status TEXT DEFAULT 'new',
    assigned_technician_id UUID REFERENCES public.users(id),
    description TEXT,
    issue TEXT,
    estimated_duration INTEGER,
    actual_duration INTEGER,
    estimated_start_date TIMESTAMP WITH TIME ZONE,
    estimated_end_date TIMESTAMP WITH TIME ZONE,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_urgent BOOLEAN DEFAULT false,
    notes TEXT,
    total_price DECIMAL(10,2) DEFAULT 0,
    is_paid BOOLEAN DEFAULT false,
    repair_number TEXT UNIQUE,           -- ⭐ Nouveau
    warranty_period INTEGER DEFAULT 90,  -- ⭐ Nouveau
    warranty_start_date TIMESTAMP WITH TIME ZONE, -- ⭐ Nouveau
    source TEXT DEFAULT 'kanban',        -- ⭐ Nouveau
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table `parts` (Pièces de Rechange)
```sql
CREATE TABLE public.parts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    part_number TEXT,
    brand TEXT,
    compatible_devices TEXT[],
    stock_quantity INTEGER DEFAULT 0,
    min_stock_level INTEGER DEFAULT 5,
    price DECIMAL(10,2) NOT NULL,
    supplier TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table `services` (Services de Réparation)
```sql
CREATE TABLE public.services (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    duration INTEGER NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category TEXT,
    applicable_devices TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔧 Fonctions Utilitaires

### Génération Automatique de Numéros de Réparation
```sql
-- Fonction pour générer un numéro unique (R000001, R000002, etc.)
SELECT generate_repair_number(); -- Retourne: R000001
```

### Vérification de Stock
```sql
-- Vérifier si une pièce est disponible
SELECT check_part_stock('part-uuid', 2); -- Retourne: true/false
```

### Création d'Alertes de Stock
```sql
-- Créer une alerte de stock faible
SELECT create_stock_alert('part-uuid', 'low_stock', 'Stock faible détecté');
```

## 🚀 Triggers Automatiques

### 1. **Génération de Numéro de Réparation**
- Se déclenche automatiquement lors de la création d'une réparation
- Génère un numéro unique au format R000001, R000002, etc.

### 2. **Vérification de Stock**
- Vérifie automatiquement le stock lors de l'ajout de pièces à une réparation
- Empêche l'ajout si le stock est insuffisant

### 3. **Alertes de Stock**
- Crée automatiquement des alertes quand le stock descend sous le minimum
- Notifie les utilisateurs des pièces à réapprovisionner

## 📱 Utilisation dans l'Application

### Page SAV - Création de Réparation
```typescript
// Créer une nouvelle réparation SAV
const newRepair = {
    client_id: "client-uuid",
    device_id: "device-uuid",
    description: "Écran cassé",
    issue: "Fissure sur l'écran principal",
    source: "sav", // ⭐ Distingue du Kanban
    estimated_duration: 60,
    // repair_number sera généré automatiquement
};
```

### Gestion des Pièces
```typescript
// Ajouter des pièces à une réparation
const repairPart = {
    repair_id: "repair-uuid",
    part_id: "part-uuid",
    quantity: 1,
    price: 89.99
};
// Le trigger vérifiera automatiquement le stock
```

### Suivi des Réparations
```typescript
// Récupérer les réparations SAV
const savRepairs = await supabase
    .from('repairs')
    .select('*')
    .eq('source', 'sav')
    .order('created_at', { ascending: false });
```

## 🧪 Données de Test Incluses

La migration inclut des données de test pour démarrer immédiatement :

### Services de Test
- Diagnostic (25€, 30min)
- Réparation écran (50€, 60min)
- Changement de batterie (35€, 45min)
- Nettoyage (15€, 15min)

### Pièces de Test
- Écran iPhone 13 (89.99€, stock: 5)
- Batterie Samsung S21 (45.50€, stock: 3)
- Clavier Dell XPS (120€, stock: 2)
- Écran iPad Air (150€, stock: 4)
- Batterie MacBook Pro (200€, stock: 1)

## 🔍 Vérifications Post-Déploiement

### 1. Tables Créées
```sql
-- Vérifier que toutes les tables SAV existent
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('repairs', 'parts', 'services', 'repair_parts', 'repair_services', 'appointments', 'messages', 'notifications', 'stock_alerts');
```

### 2. Colonne Source Ajoutée
```sql
-- Vérifier la colonne source dans repairs
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'repairs' AND column_name = 'source';
```

### 3. Fonctions Créées
```sql
-- Vérifier les fonctions utilitaires
SELECT routine_name FROM information_schema.routines 
WHERE routine_name IN ('generate_repair_number', 'check_part_stock', 'create_stock_alert');
```

### 4. Triggers Actifs
```sql
-- Vérifier les triggers
SELECT trigger_name, event_object_table FROM information_schema.triggers 
WHERE trigger_name IN ('trigger_repair_number', 'trigger_repair_parts_stock', 'trigger_parts_stock_alert');
```

## 📋 Utilisation Pratique

### Workflow SAV Typique

1. **Réception d'un appareil**
   - Créer une réparation avec `source = 'sav'`
   - Le numéro de réparation est généré automatiquement

2. **Diagnostic**
   - Ajouter des services de diagnostic
   - Estimer la durée et le coût

3. **Réparation**
   - Ajouter les pièces nécessaires
   - Le stock est vérifié automatiquement
   - Mettre à jour le statut de la réparation

4. **Suivi**
   - Planifier des rendez-vous
   - Envoyer des messages aux clients
   - Recevoir des notifications d'alertes

### Gestion des Stocks

1. **Surveillance Automatique**
   - Les alertes sont créées automatiquement
   - Notifications en temps réel

2. **Réapprovisionnement**
   - Consulter les alertes de stock
   - Mettre à jour les quantités

3. **Suivi des Fournisseurs**
   - Enregistrer les informations de fournisseurs
   - Suivre les prix et disponibilités

## ✅ Statut

- [x] Migration V22 créée
- [x] Toutes les tables SAV ajoutées
- [x] Colonne source ajoutée à repairs
- [x] Fonctions utilitaires créées
- [x] Triggers automatisés configurés
- [x] Données de test incluses
- [x] Politiques RLS configurées
- [x] Index de performance créés

**La page SAV est maintenant entièrement fonctionnelle ! 🔧**

## 🚀 Prochaines Étapes

1. **Tester la page SAV** dans l'application
2. **Créer des réparations** de test
3. **Vérifier la génération** des numéros
4. **Tester la gestion** des stocks
5. **Configurer les alertes** selon vos besoins

**Votre système SAV est maintenant prêt pour la production ! 🎉**
