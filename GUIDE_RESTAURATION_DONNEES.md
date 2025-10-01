# 🔄 Guide de Restauration des Données

## 🐛 **Problème Identifié**

Les données (modèles, catégories, marques) qui étaient créées ne sont plus visibles. Cela peut être dû à :

1. **Politiques RLS (Row Level Security)** qui bloquent l'accès
2. **Données supprimées** lors d'une migration ou d'un reset
3. **Problème d'authentification** dans l'application
4. **Erreur de connexion** à la base de données

## 🛠️ **Outils de Diagnostic Créés**

### **1. `diagnostic_donnees_manquantes.html`**
- ✅ Diagnostique l'état de la base de données
- ✅ Compte les données dans chaque table
- ✅ Identifie les problèmes de connexion
- ✅ Restaure automatiquement les données par défaut

### **2. `check_rls_policies.html`**
- ✅ Vérifie si les politiques RLS bloquent l'accès
- ✅ Teste l'authentification
- ✅ Fournit un script pour désactiver RLS temporairement

### **3. `restore_default_data.sql`**
- ✅ Script SQL complet pour restaurer les données
- ✅ Désactive temporairement RLS
- ✅ Crée les catégories, marques et modèles par défaut
- ✅ Vérifie les données créées

## 🚀 **Solution Étape par Étape**

### **Étape 1: Diagnostiquer le Problème**

1. **Ouvrez** `diagnostic_donnees_manquantes.html` dans votre navigateur
2. **Cliquez sur** "Diagnostiquer"
3. **Regardez les résultats** :
   - ✅ **Données trouvées** : Le problème vient de l'application
   - ❌ **Aucune donnée** : Le problème vient de la base de données

### **Étape 2: Vérifier les Politiques RLS**

1. **Ouvrez** `check_rls_policies.html` dans votre navigateur
2. **Cliquez sur** "Vérifier RLS"
3. **Regardez les résultats** :
   - ✅ **RLS OK** : Les politiques ne bloquent pas
   - ❌ **RLS bloque** : Les politiques bloquent l'accès

#### **Si RLS bloque l'accès :**
1. **Cliquez sur** "Désactiver RLS"
2. **Copiez le script SQL** affiché
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script** et cliquez sur **"Run"**

### **Étape 3: Restaurer les Données**

#### **Option A: Restauration Automatique**
1. **Dans** `diagnostic_donnees_manquantes.html`
2. **Cliquez sur** "Restaurer les Données"
3. **Attendez** que la restauration se termine

#### **Option B: Restauration Manuelle**
1. **Ouvrez** `restore_default_data.sql`
2. **Copiez tout le contenu**
3. **Allez sur** [https://supabase.com/dashboard](https://supabase.com/dashboard)
4. **Ouvrez votre projet** > **SQL Editor**
5. **Collez le script** et cliquez sur **"Run"**

### **Étape 4: Vérifier la Restauration**

1. **Revenez à** `diagnostic_donnees_manquantes.html`
2. **Cliquez sur** "Diagnostiquer" à nouveau
3. **Vérifiez** que les données sont maintenant visibles :
   - ✅ **1 catégorie** : "Électronique"
   - ✅ **5 marques** : Apple, Samsung, Google, Microsoft, Sony
   - ✅ **5 modèles** : iPhone 15, Galaxy S24, Pixel 8, Surface Pro 9, WH-1000XM5

### **Étape 5: Tester l'Application**

1. **Ouvrez l'application** dans votre navigateur
2. **Allez dans** "Gestion des Appareils"
3. **Testez les 3 onglets** :
   - ✅ **Marques** : Doit afficher 5 marques
   - ✅ **Catégories** : Doit afficher 1 catégorie
   - ✅ **Modèles** : Doit afficher 5 modèles

## 🎯 **Données qui Seront Restaurées**

### **Catégories**
- **Électronique** : Catégorie par défaut pour les appareils électroniques

### **Marques**
- **Apple** : Fabricant américain de produits électroniques premium
- **Samsung** : Fabricant sud-coréen d'électronique grand public
- **Google** : Entreprise américaine de technologie
- **Microsoft** : Entreprise américaine de technologie
- **Sony** : Conglomérat japonais d'électronique

### **Modèles**
- **iPhone 15** : Dernier smartphone d'Apple
- **Galaxy S24** : Smartphone Android haut de gamme
- **Pixel 8** : Smartphone Google avec IA
- **Surface Pro 9** : Tablette 2-en-1 Microsoft
- **WH-1000XM5** : Casque audio sans fil Sony

### **Relations**
- Toutes les marques sont associées à la catégorie "Électronique"

## 🔍 **Vérifications**

### **Après la Restauration**
- ✅ **Console du navigateur** : Plus d'erreurs de données manquantes
- ✅ **Interface** : Les 3 sections affichent les données
- ✅ **Navigation** : Possibilité de cliquer sur les onglets
- ✅ **Filtres** : Les filtres fonctionnent avec les données

### **Si les Données Ne S'Affichent Toujours Pas**
1. **Vérifiez** que le script SQL a été exécuté sans erreur
2. **Vérifiez** que RLS a été désactivé
3. **Redémarrez** l'application avec `./fix_connection_error.sh`
4. **Vérifiez** les logs de la console du navigateur

## 🆘 **En cas de Problème Persistant**

Si les données ne s'affichent toujours pas après avoir suivi ce guide :

1. **Vérifiez** que vous êtes connecté à Supabase
2. **Vérifiez** que le script SQL a été exécuté sans erreur
3. **Vérifiez** que RLS a été désactivé
4. **Redémarrez** complètement votre navigateur
5. **Contactez** le support si le problème persiste

## 📝 **Notes Importantes**

- **RLS désactivé** : La sécurité au niveau des lignes est temporairement désactivée
- **Données par défaut** : Les données restaurées sont des exemples
- **Réactivation RLS** : Vous pouvez réactiver RLS après avoir testé
- **Sauvegarde** : Les données existantes ne sont pas supprimées (ON CONFLICT DO NOTHING)

---

**🎉 Suivez ce guide pour restaurer vos données et faire fonctionner l'application !**
