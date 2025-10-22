# 🚨 Guide de Résolution - Champs qui ne s'enregistrent pas

## 📋 Problème identifié

D'après les captures d'écran, plusieurs champs du formulaire client ne s'enregistrent pas :
- Région, code postal, ville
- Code comptable, CNI
- Complément d'adresse
- Nom d'entreprise, SIREN, TVA

## 🔍 Diagnostic étape par étape

### Étape 1 : Vérifier la base de données

Exécutez le script de diagnostic complet :

```bash
# Remplacez VOTRE_URL_SUPABASE par votre URL Supabase
psql VOTRE_URL_SUPABASE -f diagnostic_complet_clients.sql
```

Ce script va :
- ✅ Vérifier si toutes les colonnes existent
- ✅ Identifier les champs NULL
- ✅ Corriger automatiquement les champs NULL
- ✅ Vérifier les corrections

### Étape 2 : Tester dans l'application

1. **Ouvrez la console du navigateur** (F12)
2. **Copiez-collez le contenu** de `test_form_data.js`
3. **Exécutez le script** dans la console
4. **Vérifiez les résultats** pour identifier les problèmes

### Étape 3 : Vérifier les données

Le script va tester :
- 📊 **Récupération des données** depuis le store
- 📝 **Valeurs du formulaire** ouvert
- 🔗 **Connexion Supabase** et données brutes

## 🛠️ Solutions possibles

### Solution 1 : Colonnes manquantes dans la base

Si le diagnostic montre des colonnes manquantes :

```bash
# Exécuter le script d'extension de la table
psql VOTRE_URL_SUPABASE -f tables/extend_clients_table.sql
```

### Solution 2 : Champs NULL dans la base

Si les colonnes existent mais sont NULL :

```bash
# Corriger automatiquement les champs NULL
psql VOTRE_URL_SUPABASE -f fix_null_clients_fields.sql
```

### Solution 3 : Problème de mapping dans le service

Si les données ne sont pas transmises correctement :

1. **Vérifiez le service** `src/services/supabaseService.ts`
2. **Vérifiez le store** `src/store/index.ts`
3. **Vérifiez le composant** `src/components/ClientForm.tsx`

## 🧪 Test de validation

### Test 1 : Création d'un nouveau client

1. **Ouvrez le formulaire** "Nouveau Client"
2. **Remplissez tous les champs** :
   - Région : "Île-de-France"
   - Code postal : "75001"
   - Ville : "Paris"
   - Code comptable : "TEST001"
   - CNI : "123456789"
   - Nom entreprise : "Test SARL"
   - SIREN : "123456789"
   - TVA : "FR12345678901"
3. **Sauvegardez** le client
4. **Vérifiez** dans la base de données

### Test 2 : Modification d'un client existant

1. **Ouvrez le formulaire** "Modifier le Client"
2. **Vérifiez** que tous les champs sont pré-remplis
3. **Modifiez** quelques champs
4. **Sauvegardez** et vérifiez les changements

## 🔍 Diagnostic manuel

### Vérifier la structure de la table

```sql
-- Vérifier les colonnes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
ORDER BY ordinal_position;
```

### Vérifier les données

```sql
-- Vérifier les champs NULL
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN region IS NULL THEN 1 END) as region_null,
    COUNT(CASE WHEN postal_code IS NULL THEN 1 END) as postal_code_null,
    COUNT(CASE WHEN city IS NULL THEN 1 END) as city_null,
    COUNT(CASE WHEN accounting_code IS NULL THEN 1 END) as accounting_code_null,
    COUNT(CASE WHEN cni_identifier IS NULL THEN 1 END) as cni_null,
    COUNT(CASE WHEN company_name IS NULL THEN 1 END) as company_name_null
FROM clients;
```

### Vérifier un client spécifique

```sql
-- Vérifier un client par email
SELECT 
    id, first_name, last_name, email,
    region, postal_code, city,
    accounting_code, cni_identifier,
    company_name, siren_number, vat_number
FROM clients 
WHERE email = 'test@gmail.com';
```

## 🚨 Problèmes courants et solutions

### Problème 1 : Colonnes manquantes

**Symptôme** : Erreur SQL lors de l'insertion
**Solution** : Exécuter `extend_clients_table.sql`

### Problème 2 : Données non transmises

**Symptôme** : Champs vides dans le formulaire
**Solution** : Vérifier le mapping dans `supabaseService.ts`

### Problème 3 : Validation du formulaire

**Symptôme** : Bouton "Modifier" désactivé
**Solution** : Vérifier les champs requis et la validation

### Problème 4 : Permissions Supabase

**Symptôme** : Erreur d'accès à la base
**Solution** : Vérifier les politiques RLS et les permissions

## 📊 Résultats attendus

Après correction, vous devriez voir :

1. **✅ Aucun champ NULL** dans la base de données
2. **✅ Formulaire pré-rempli** en mode édition
3. **✅ Bouton "Modifier" activé** quand le formulaire est valide
4. **✅ Données sauvegardées** après soumission

## 🔄 Processus de vérification

1. **Exécutez le diagnostic** : `diagnostic_complet_clients.sql`
2. **Testez dans l'application** : `test_form_data.js`
3. **Créez un client test** avec tous les champs
4. **Modifiez le client** et vérifiez les données
5. **Vérifiez la base** avec les requêtes SQL

## 📞 Support

Si le problème persiste :

1. **Vérifiez les logs** de la console
2. **Exécutez tous les tests** fournis
3. **Vérifiez les permissions** Supabase
4. **Testez avec un client simple** d'abord

---

**💡 Conseil** : Commencez par exécuter `diagnostic_complet_clients.sql` pour un diagnostic et une correction automatique !
