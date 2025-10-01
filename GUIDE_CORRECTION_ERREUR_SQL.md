# 🔧 Guide de Correction de l'Erreur SQL

## 🐛 **Erreur Identifiée**

```
ERROR: 42703: column "description" of relation "device_models" does not exist
LINE 62: INSERT INTO public.device_models (name, description, specifications, brand_id, category_id, is_active, user_id, created_by)
```

**Cause :** La table `device_models` n'a pas de colonne `description`. Le script SQL tentait d'insérer des données dans une colonne qui n'existe pas.

## 🛠️ **Solutions Créées**

### **1. Script de Vérification de Structure**
- **`check_table_structure.sql`** : Script SQL pour vérifier la structure des tables
- **`diagnostic_table_structure.html`** : Page web pour diagnostiquer la structure

### **2. Script Corrigé**
- **`restore_default_data_fixed.sql`** : Script SQL corrigé sans la colonne `description`

## 🚀 **Solution Étape par Étape**

### **Étape 1: Vérifier la Structure des Tables**

1. **Ouvrez** `diagnostic_table_structure.html` dans votre navigateur
2. **Cliquez sur** "Vérifier Structure"
3. **Regardez les résultats** pour voir les colonnes disponibles

**OU**

1. **Ouvrez** `check_table_structure.sql`
2. **Copiez le contenu**
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script** et cliquez sur **"Run"**

### **Étape 2: Utiliser le Script Corrigé**

1. **Ouvrez** `restore_default_data_fixed.sql`
2. **Copiez tout le contenu**
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script corrigé** et cliquez sur **"Run"**

### **Étape 3: Vérifier la Restauration**

1. **Revenez à** `diagnostic_donnees_manquantes.html`
2. **Cliquez sur** "Diagnostiquer"
3. **Vérifiez** que les données sont maintenant visibles

## 🔍 **Différences entre les Scripts**

### **Script Original (Erreur)**
```sql
INSERT INTO public.device_models (name, description, specifications, brand_id, category_id, is_active, user_id, created_by)
```

### **Script Corrigé**
```sql
INSERT INTO public.device_models (name, specifications, brand_id, category_id, is_active, user_id, created_by)
```

**Changement :** Suppression de la colonne `description` qui n'existe pas dans la table.

## 📊 **Structure Probable des Tables**

### **device_categories**
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `description` (TEXT)
- `icon` (TEXT)
- `is_active` (BOOLEAN)
- `user_id` (UUID)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### **device_brands**
- `id` (TEXT, Primary Key)
- `name` (TEXT)
- `description` (TEXT)
- `logo` (TEXT)
- `is_active` (BOOLEAN)
- `user_id` (UUID)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### **device_models**
- `id` (UUID, Primary Key)
- `name` (TEXT)
- `specifications` (TEXT) ← **Pas de colonne `description`**
- `brand_id` (TEXT, Foreign Key)
- `category_id` (UUID, Foreign Key)
- `is_active` (BOOLEAN)
- `user_id` (UUID)
- `created_by` (UUID)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### **brand_categories**
- `id` (UUID, Primary Key)
- `brand_id` (TEXT, Foreign Key)
- `category_id` (UUID, Foreign Key)

## 🎯 **Données qui Seront Restaurées**

### **Catégories**
- **Électronique** : Catégorie par défaut

### **Marques**
- **Apple** : Fabricant américain de produits électroniques premium
- **Samsung** : Fabricant sud-coréen d'électronique grand public
- **Google** : Entreprise américaine de technologie
- **Microsoft** : Entreprise américaine de technologie
- **Sony** : Conglomérat japonais d'électronique

### **Modèles (Sans Description)**
- **iPhone 15** : Écran 6.1", A17 Pro, 128GB
- **Galaxy S24** : Écran 6.2", Snapdragon 8 Gen 3, 256GB
- **Pixel 8** : Écran 6.2", Tensor G3, 128GB
- **Surface Pro 9** : Écran 13", Intel i7, 512GB
- **WH-1000XM5** : Réduction de bruit, 30h autonomie

## 🔍 **Vérifications**

### **Après l'Exécution du Script Corrigé**
- ✅ **Pas d'erreur SQL** : Le script s'exécute sans erreur
- ✅ **Données créées** : Les catégories, marques et modèles sont créés
- ✅ **Relations établies** : Les marques sont liées aux catégories
- ✅ **Application fonctionnelle** : Les données s'affichent dans l'interface

### **Si l'Erreur Persiste**
1. **Vérifiez** que vous utilisez le script corrigé (`restore_default_data_fixed.sql`)
2. **Vérifiez** la structure exacte de vos tables avec `check_table_structure.sql`
3. **Adaptez** le script selon la structure réelle de vos tables

## 🆘 **En cas de Problème**

Si vous rencontrez encore des erreurs :

1. **Exécutez** `check_table_structure.sql` pour voir la structure exacte
2. **Comparez** avec le script corrigé
3. **Adaptez** les colonnes selon votre structure
4. **Testez** avec une seule table à la fois

## 📝 **Notes Importantes**

- **Colonnes manquantes** : Certaines colonnes peuvent ne pas exister dans votre structure
- **Types de données** : Vérifiez que les types correspondent (TEXT vs UUID)
- **Contraintes** : Respectez les contraintes de clés étrangères
- **RLS** : Le script désactive temporairement RLS pour permettre l'insertion

---

**🎉 Utilisez le script corrigé pour restaurer vos données sans erreur !**
