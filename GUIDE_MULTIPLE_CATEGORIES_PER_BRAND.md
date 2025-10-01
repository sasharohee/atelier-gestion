# Guide - Plusieurs Catégories par Marque

## 🎯 Objectif

Permettre à une marque d'être associée à plusieurs catégories d'appareils au lieu d'une seule. Par exemple, Apple peut être associé à la fois aux catégories "Smartphone" et "Tablette".

## 🔧 Modifications Apportées

### 1. **Structure de Base de Données**

#### **Nouvelle Table de Liaison**
```sql
-- Table de liaison many-to-many
CREATE TABLE public.brand_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand_id UUID REFERENCES public.device_brands(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.device_categories(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brand_id, category_id)
);
```

#### **Vue pour Faciliter les Requêtes**
```sql
-- Vue qui agrège les catégories par marque
CREATE VIEW public.brand_with_categories AS
SELECT 
    db.id,
    db.name,
    db.description,
    db.logo,
    db.is_active,
    db.user_id,
    db.created_by,
    db.created_at,
    db.updated_at,
    COALESCE(
        json_agg(
            json_build_object(
                'id', dc.id,
                'name', dc.name,
                'description', dc.description,
                'icon', dc.icon
            )
        ) FILTER (WHERE dc.id IS NOT NULL),
        '[]'::json
    ) as categories
FROM public.device_brands db
LEFT JOIN public.brand_categories bc ON db.id = bc.brand_id
LEFT JOIN public.device_categories dc ON bc.category_id = dc.id
GROUP BY db.id, db.name, db.description, db.logo, db.is_active, db.user_id, db.created_by, db.created_at, db.updated_at;
```

#### **Fonctions Utilitaires**
```sql
-- Fonction pour mettre à jour toutes les catégories d'une marque
CREATE OR REPLACE FUNCTION update_brand_categories(
    p_brand_id UUID,
    p_category_ids UUID[]
) RETURNS BOOLEAN;

-- Fonction pour ajouter une catégorie à une marque
CREATE OR REPLACE FUNCTION add_category_to_brand(
    p_brand_id UUID,
    p_category_id UUID
) RETURNS BOOLEAN;

-- Fonction pour supprimer une catégorie d'une marque
CREATE OR REPLACE FUNCTION remove_category_from_brand(
    p_brand_id UUID,
    p_category_id UUID
) RETURNS BOOLEAN;
```

### 2. **Types TypeScript Mis à Jour**

#### **Interface DeviceBrand**
```typescript
export interface DeviceBrand {
  id: string;
  name: string;
  categoryId: string; // Pour compatibilité avec l'ancien système
  categoryIds?: string[]; // Nouveaux IDs de catégories (many-to-many)
  categories?: DeviceCategory[]; // Données complètes des catégories
  description?: string;
  logo?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}
```

### 3. **Services Mis à Jour**

#### **brandService.getAll()**
- Utilise la vue `brand_with_categories` pour récupérer les marques avec leurs catégories
- Retourne les données dans le nouveau format avec `categoryIds` et `categories`

#### **brandService.create()**
- Crée d'abord la marque
- Utilise la fonction `update_brand_categories` pour associer les catégories
- Récupère la marque complète avec ses catégories

#### **brandService.update()**
- Met à jour la marque
- Met à jour les catégories si `categoryIds` est spécifié
- Récupère la marque complète avec ses catégories

### 4. **Interface Utilisateur**

#### **Formulaire de Création/Modification**
- **Sélection multiple** : Le champ catégorie est maintenant un `Select` avec `multiple={true}`
- **Affichage des sélections** : Les catégories sélectionnées sont affichées comme des chips colorés
- **Validation** : Le bouton est désactivé si aucune catégorie n'est sélectionnée

```typescript
<Select
  multiple
  value={newBrand.categoryIds}
  label="Catégories *"
  onChange={(e) => setNewBrand(prev => ({ 
    ...prev, 
    categoryIds: typeof e.target.value === 'string' ? e.target.value.split(',') : e.target.value
  }))}
  required
  renderValue={(selected) => (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
      {(selected as string[]).map((value) => {
        const category = defaultCategories.find(cat => cat.id === value);
        return (
          <Chip
            key={value}
            label={category?.name || value}
            size="small"
            sx={{
              bgcolor: getDeviceTypeColor(category?.icon || 'other'),
              color: 'white',
              fontSize: '0.7rem'
            }}
          />
        );
      })}
    </Box>
  )}
>
```

#### **Tableau des Marques**
- **Affichage multiple** : Chaque marque peut maintenant afficher plusieurs chips de catégories
- **Filtrage intelligent** : Le filtrage par catégorie fonctionne avec le nouveau système
- **Comptage mis à jour** : Le comptage des marques par catégorie prend en compte les relations many-to-many

```typescript
<TableCell>
  <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
    {brand.categories && brand.categories.length > 0 ? (
      brand.categories.map((cat, index) => (
        <Chip
          key={cat.id || index}
          label={cat.name}
          size="small"
          sx={{
            bgcolor: getDeviceTypeColor(cat.icon),
            color: 'white',
            fontSize: '0.7rem'
          }}
        />
      ))
    ) : (
      <Chip label="N/A" size="small" sx={{ bgcolor: '#9e9e9e', color: 'white', fontSize: '0.7rem' }} />
    )}
  </Box>
</TableCell>
```

## 🚀 Déploiement

### 1. **Exécuter le Script SQL**
```bash
# Exécuter le script de modification de la base de données
psql -h your-supabase-host -U postgres -d postgres -f multiple_categories_per_brand.sql
```

### 2. **Vérifier la Migration**
```sql
-- Vérifier que la table de liaison existe
SELECT * FROM information_schema.tables WHERE table_name = 'brand_categories';

-- Vérifier que la vue existe
SELECT * FROM information_schema.views WHERE table_name = 'brand_with_categories';

-- Vérifier que les fonctions existent
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%brand%category%';
```

### 3. **Tester la Fonctionnalité**
1. **Créer une nouvelle marque** avec plusieurs catégories
2. **Modifier une marque existante** pour ajouter/supprimer des catégories
3. **Vérifier l'affichage** dans le tableau des marques
4. **Tester le filtrage** par catégorie

## 📋 Exemples d'Utilisation

### **Avant (Système Ancien)**
```
Apple → Catégorie: Smartphone
Samsung → Catégorie: Smartphone
iPad → Catégorie: Tablette
```

### **Après (Système Nouveau)**
```
Apple → Catégories: [Smartphone, Tablette, Ordinateur portable]
Samsung → Catégories: [Smartphone, Tablette]
iPad → Catégories: [Tablette]
Dell → Catégories: [Ordinateur portable, Ordinateur fixe]
```

## 🔍 Avantages du Nouveau Système

### **1. Flexibilité**
- Une marque peut être associée à plusieurs catégories
- Plus réaliste pour les marques qui produisent différents types d'appareils

### **2. Évolutivité**
- Facile d'ajouter de nouvelles catégories
- Facile d'associer/dissocier des catégories

### **3. Performance**
- Vue optimisée pour les requêtes fréquentes
- Index sur les colonnes importantes
- Fonctions RPC pour les opérations complexes

### **4. Rétrocompatibilité**
- L'ancien champ `categoryId` est conservé pour compatibilité
- Migration automatique des données existantes
- Interface progressive (ancien et nouveau système coexistent)

## 🧪 Tests à Effectuer

### **1. Test de Création**
```typescript
// Créer une marque avec plusieurs catégories
const newBrand = {
  name: 'Test Brand',
  categoryIds: ['uuid-smartphone', 'uuid-tablet'],
  description: 'Test description'
};

const result = await brandService.create(newBrand);
// Vérifier que result.data.categories contient 2 catégories
```

### **2. Test de Modification**
```typescript
// Modifier les catégories d'une marque existante
const updates = {
  categoryIds: ['uuid-smartphone', 'uuid-laptop', 'uuid-desktop']
};

const result = await brandService.update(brandId, updates);
// Vérifier que result.data.categories contient 3 catégories
```

### **3. Test d'Affichage**
```typescript
// Vérifier l'affichage dans le tableau
const brands = await brandService.getAll();
const brandWithMultipleCategories = brands.find(b => b.categories.length > 1);
// Vérifier que brandWithMultipleCategories.categories affiche correctement
```

### **4. Test de Filtrage**
```typescript
// Tester le filtrage par catégorie
const filteredBrands = brands.filter(brand => 
  brand.categories.some(cat => cat.id === selectedCategoryId)
);
// Vérifier que le filtrage fonctionne avec plusieurs catégories
```

## 🔧 Dépannage

### **Si les catégories ne s'affichent pas :**
1. Vérifier que la vue `brand_with_categories` existe
2. Vérifier que les données sont migrées dans `brand_categories`
3. Vérifier les logs de la console pour les erreurs

### **Si la création échoue :**
1. Vérifier que la fonction `update_brand_categories` existe
2. Vérifier que l'utilisateur a les permissions RLS
3. Vérifier que les catégories existent et appartiennent à l'utilisateur

### **Si l'interface ne fonctionne pas :**
1. Vérifier que `newBrand.categoryIds` est un tableau
2. Vérifier que le `Select` a `multiple={true}`
3. Vérifier que la validation fonctionne correctement

## 📊 Métriques de Succès

- ✅ **Création** : Une marque peut être créée avec plusieurs catégories
- ✅ **Modification** : Les catégories d'une marque peuvent être modifiées
- ✅ **Affichage** : Le tableau affiche correctement toutes les catégories
- ✅ **Filtrage** : Le filtrage fonctionne avec les relations many-to-many
- ✅ **Performance** : Les requêtes sont rapides grâce à la vue optimisée
- ✅ **Rétrocompatibilité** : L'ancien système continue de fonctionner
