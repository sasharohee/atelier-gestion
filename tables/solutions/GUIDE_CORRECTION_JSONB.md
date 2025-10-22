# 🔧 Guide de Correction de l'Erreur JSONB

## 🐛 **Erreur Identifiée**

```
ERROR: 42804: column "specifications" is of type jsonb but expression is of type text
LINE 59: model_specifications,
HINT: You will need to rewrite or cast the expression.
```

**Cause :** La colonne `specifications` dans la table `device_models` est de type `jsonb` et non `text`. Le script tentait d'insérer du texte dans une colonne JSONB.

## 🛠️ **Solutions Créées**

### **1. Script avec Cast JSONB**
- **`restore_default_data_jsonb_fixed.sql`** : Script avec conversion en JSONB

### **2. Script Simple (Recommandé)**
- **`restore_default_data_simple.sql`** : Script sans specifications pour éviter les problèmes

## 🚀 **Solution Étape par Étape**

### **Option A: Script Simple (Recommandé)**

1. **Ouvrez** `restore_default_data_simple.sql`
2. **Copiez tout le contenu**
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script simple** et cliquez sur **"Run"**

**Avantages :**
- ✅ Pas de problème de type
- ✅ Plus simple à exécuter
- ✅ Crée toutes les données essentielles

### **Option B: Script avec JSONB**

1. **Ouvrez** `restore_default_data_jsonb_fixed.sql`
2. **Copiez tout le contenu**
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script JSONB** et cliquez sur **"Run"**

**Avantages :**
- ✅ Inclut les specifications en format JSON
- ✅ Plus de détails sur les modèles

## 🔍 **Différences entre les Scripts**

### **Script Original (Erreur)**
```sql
INSERT INTO public.device_models (name, specifications, ...)
VALUES ('iPhone 15', 'Écran 6.1", A17 Pro, 128GB', ...)
```

### **Script Simple (Recommandé)**
```sql
INSERT INTO public.device_models (name, brand_id, category_id, ...)
VALUES ('iPhone 15', '1', category_id, ...)
```

### **Script JSONB**
```sql
INSERT INTO public.device_models (name, specifications, ...)
VALUES ('iPhone 15', '{"ecran": "6.1 pouces", "processeur": "A17 Pro"}', ...)
```

## 📊 **Structure de la Table device_models**

```sql
device_models:
- id (UUID, Primary Key)
- name (TEXT)
- specifications (JSONB) ← Type JSONB, pas TEXT
- brand_id (TEXT, Foreign Key)
- category_id (UUID, Foreign Key)
- is_active (BOOLEAN)
- user_id (UUID)
- created_by (UUID)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

## 🎯 **Données qui Seront Restaurées**

### **Avec le Script Simple**
- ✅ **1 catégorie** : "Électronique"
- ✅ **5 marques** : Apple, Samsung, Google, Microsoft, Sony
- ✅ **5 modèles** : iPhone 15, Galaxy S24, Pixel 8, Surface Pro 9, WH-1000XM5
- ✅ **Relations** : Toutes les marques liées à la catégorie "Électronique"
- ⚠️ **Specifications** : Vides (à ajouter plus tard)

### **Avec le Script JSONB**
- ✅ **1 catégorie** : "Électronique"
- ✅ **5 marques** : Apple, Samsung, Google, Microsoft, Sony
- ✅ **5 modèles** : iPhone 15, Galaxy S24, Pixel 8, Surface Pro 9, WH-1000XM5
- ✅ **Specifications** : En format JSON avec détails
- ✅ **Relations** : Toutes les marques liées à la catégorie "Électronique"

## 🔍 **Exemple de Specifications JSONB**

```json
{
  "ecran": "6.1 pouces",
  "processeur": "A17 Pro",
  "stockage": "128GB",
  "couleur": "Noir"
}
```

## 🚀 **Recommandation**

**Utilisez le script simple** (`restore_default_data_simple.sql`) car :

1. ✅ **Plus fiable** : Pas de problème de type
2. ✅ **Plus rapide** : Exécution plus simple
3. ✅ **Suffisant** : Crée toutes les données essentielles
4. ✅ **Extensible** : Vous pourrez ajouter les specifications plus tard

## 🔍 **Vérifications**

### **Après l'Exécution du Script Simple**
- ✅ **Pas d'erreur SQL** : Le script s'exécute sans erreur
- ✅ **Données créées** : Les catégories, marques et modèles sont créés
- ✅ **Relations établies** : Les marques sont liées aux catégories
- ✅ **Application fonctionnelle** : Les données s'affichent dans l'interface
- ⚠️ **Specifications vides** : À ajouter manuellement si nécessaire

### **Si vous voulez ajouter des Specifications plus tard**
```sql
UPDATE public.device_models 
SET specifications = '{"ecran": "6.1 pouces", "processeur": "A17 Pro"}'::jsonb
WHERE name = 'iPhone 15';
```

## 🆘 **En cas de Problème**

Si vous rencontrez encore des erreurs :

1. **Utilisez le script simple** : `restore_default_data_simple.sql`
2. **Vérifiez** que RLS est désactivé
3. **Exécutez** une table à la fois si nécessaire
4. **Vérifiez** les logs d'erreur dans Supabase

## 📝 **Notes Importantes**

- **Type JSONB** : Les specifications doivent être en format JSON valide
- **Cast nécessaire** : Utilisez `::jsonb` pour convertir du texte en JSONB
- **Script simple** : Évite les problèmes de type en omettant les specifications
- **Extensibilité** : Vous pourrez ajouter les specifications plus tard via l'interface

---

**🎉 Utilisez le script simple pour restaurer vos données sans erreur !**
