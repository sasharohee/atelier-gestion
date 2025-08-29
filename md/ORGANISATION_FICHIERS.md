# Organisation des Fichiers

## 📁 Structure des Dossiers

### **Dossier `tables/`**
Contient tous les fichiers SQL pour la gestion de la base de données :
- Scripts de création de tables
- Scripts de correction et maintenance
- Scripts de migration
- Scripts de diagnostic et vérification

### **Dossier `md/`**
Contient tous les fichiers de documentation Markdown :
- Guides d'utilisation
- Guides de correction
- Documentation technique
- Résolutions de problèmes

## 🔄 Réorganisation Effectuée

### **Fichiers SQL Déplacés vers `tables/`**

#### **Fonctionnalité Points de Fidélité**
- `creation_fonction_use_loyalty_points.sql` → `tables/`
- `correction_created_by_loyalty_points.sql` → `tables/`
- `correction_rapide_user_id_loyalty_points.sql` → `tables/`

#### **Corrections Stock Minimum**
- `correction_stock_minimum_1.sql` → `tables/`
- `correction_rapide_stock_minimum.sql` → `tables/`
- `verification_seuils_ruptures.sql` → `tables/`

#### **Corrections Niveau de Fidélité**
- `correction_niveau_actuel.sql` → `tables/`
- `correction_rapide_niveau_actuel.sql` → `tables/`

#### **Autres Scripts SQL**
- Tous les fichiers `.sql` du répertoire racine → `tables/`

### **Fichiers Markdown Déplacés vers `md/`**

#### **Guides de Fonctionnalités**
- `GUIDE_FONCTIONNALITE_UTILISATION_POINTS.md` → `md/`
- `GUIDE_CORRECTION_CREATED_BY_LOYALTY_POINTS.md` → `md/`
- `GUIDE_CORRECTION_SEUILS_RUPTURES.md` → `md/`
- `GUIDE_CORRECTION_STOCK_MINIMUM_MODIFIABLE.md` → `md/`
- `GUIDE_CORRECTION_NIVEAU_ACTUEL.md` → `md/`

#### **Autres Guides**
- Tous les fichiers `.md` du répertoire racine → `md/`

## 📝 Mises à Jour des Références

### **Références Mises à Jour**

Les références dans les fichiers de documentation ont été mises à jour pour pointer vers les nouveaux emplacements :

#### **Dans `md/GUIDE_CORRECTION_CREATED_BY_LOYALTY_POINTS.md`**
- `creation_fonction_use_loyalty_points.sql` → `tables/creation_fonction_use_loyalty_points.sql`
- `correction_created_by_loyalty_points.sql` → `tables/correction_created_by_loyalty_points.sql`
- `correction_rapide_user_id_loyalty_points.sql` → `tables/correction_rapide_user_id_loyalty_points.sql`

#### **Dans `md/GUIDE_FONCTIONNALITE_UTILISATION_POINTS.md`**
- `creation_fonction_use_loyalty_points.sql` → `tables/creation_fonction_use_loyalty_points.sql`

#### **Dans `md/GUIDE_CORRECTION_SEUILS_RUPTURES.md`**
- `verification_seuils_ruptures.sql` → `tables/verification_seuils_ruptures.sql`

#### **Dans `md/GUIDE_CORRECTION_STOCK_MINIMUM.md`**
- `correction_stock_minimum_1.sql` → `tables/correction_stock_minimum_1.sql`
- `correction_rapide_stock_minimum.sql` → `tables/correction_rapide_stock_minimum.sql`

#### **Dans `md/GUIDE_CORRECTION_NIVEAU_ACTUEL.md`**
- `correction_niveau_actuel.sql` → `tables/correction_niveau_actuel.sql`
- `correction_rapide_niveau_actuel.sql` → `tables/correction_rapide_niveau_actuel.sql`

## ✅ Avantages de cette Organisation

### **1. Clarté**
- Séparation claire entre code SQL et documentation
- Structure logique et intuitive

### **2. Maintenance**
- Plus facile de trouver les scripts SQL
- Documentation centralisée dans un dossier

### **3. Collaboration**
- Évite la confusion entre types de fichiers
- Structure standardisée pour l'équipe

### **4. Navigation**
- Répertoire racine plus propre
- Recherche plus efficace dans les dossiers spécialisés

## 🚀 Utilisation

### **Pour Exécuter un Script SQL**
1. Aller dans le dossier `tables/`
2. Trouver le script approprié
3. Copier le contenu
4. Exécuter dans l'éditeur SQL de Supabase

### **Pour Consulter la Documentation**
1. Aller dans le dossier `md/`
2. Trouver le guide approprié
3. Suivre les instructions

### **Exemple de Chemin**
```
📁 App atelier/
├── 📁 tables/
│   ├── creation_fonction_use_loyalty_points.sql
│   ├── correction_rapide_user_id_loyalty_points.sql
│   └── ...
├── 📁 md/
│   ├── GUIDE_FONCTIONNALITE_UTILISATION_POINTS.md
│   ├── GUIDE_CORRECTION_CREATED_BY_LOYALTY_POINTS.md
│   └── ...
└── 📁 src/
    └── ...
```

## 📋 Vérification

Pour vérifier que l'organisation est correcte :
```bash
# Vérifier qu'il n'y a plus de fichiers SQL dans le répertoire racine
ls *.sql

# Vérifier qu'il n'y a plus de fichiers MD dans le répertoire racine
ls *.md

# Vérifier le contenu des dossiers
ls tables/ | wc -l
ls md/ | wc -l
```

**Résultat attendu :** Aucun fichier `.sql` ou `.md` dans le répertoire racine, tous les fichiers sont dans leurs dossiers respectifs.
