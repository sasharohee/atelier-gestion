# Guide de Dépannage - Formulaire Client

## 🚨 Problème identifié

Les champs suivants ne s'enregistrent pas correctement :
- Région, code postal, ville
- Code comptable, CNI
- Complément d'adresse
- Nom d'entreprise, SIREN, TVA

## 🔧 Solutions appliquées

### 1. Mise à jour du service client

J'ai mis à jour `src/services/supabaseService.ts` pour inclure tous les nouveaux champs :

#### ✅ Fonction `getAll()` mise à jour
- Ajout du mapping des nouveaux champs de `snake_case` vers `camelCase`
- Tous les champs sont maintenant récupérés depuis Supabase

#### ✅ Fonction `create()` mise à jour
- Ajout du mapping des nouveaux champs de `camelCase` vers `snake_case`
- Tous les champs sont maintenant envoyés à Supabase

#### ✅ Fonction `update()` mise à jour
- Ajout du mapping conditionnel pour les mises à jour
- Gestion des champs undefined/null

### 2. Vérification de la base de données

Assurez-vous que le script SQL a été exécuté :

```bash
# Vérifier que les colonnes existent
psql votre_url_supabase -c "
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND column_name IN (
  'region', 'postal_code', 'city', 'accounting_code', 'cni_identifier',
  'address_complement', 'company_name', 'siren_number', 'vat_number'
)
ORDER BY column_name;
"
```

### 3. Test de diagnostic

Utilisez le script de test `test_client_form.js` :

1. **Ouvrir la console du navigateur** (F12)
2. **Créer un nouveau client** avec tous les champs remplis
3. **Copier-coller le contenu** de `test_client_form.js` dans la console
4. **Exécuter** et vérifier les résultats

## 🔍 Diagnostic étape par étape

### Étape 1 : Vérifier la base de données

```sql
-- Vérifier que les colonnes existent
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND column_name IN (
  'region', 'postal_code', 'city', 'accounting_code', 'cni_identifier',
  'address_complement', 'company_name', 'siren_number', 'vat_number'
);
```

### Étape 2 : Vérifier les données envoyées

Dans la console du navigateur :

```javascript
// Vérifier les données envoyées au service
console.log('Données du formulaire:', formData);

// Vérifier les données mappées
console.log('Données mappées:', clientData);
```

### Étape 3 : Vérifier la réponse Supabase

```javascript
// Dans le service client, ajouter des logs
console.log('Données envoyées à Supabase:', clientData);
console.log('Réponse Supabase:', data);
```

## 🛠️ Corrections spécifiques

### Problème 1 : Champs non mappés

**Symptôme** : Les champs sont vides dans la base de données

**Solution** : Vérifier le mapping dans `supabaseService.ts`

```typescript
// Vérifier que ces mappings existent
const clientData = {
  // ... autres champs
  region: client.region,                    // ✅
  postal_code: client.postalCode,           // ✅
  city: client.city,                        // ✅
  accounting_code: client.accountingCode,   // ✅
  cni_identifier: client.cniIdentifier,     // ✅
  address_complement: client.addressComplement, // ✅
  company_name: client.companyName,         // ✅
  siren_number: client.sirenNumber,         // ✅
  vat_number: client.vatNumber,             // ✅
};
```

### Problème 2 : Colonnes manquantes

**Symptôme** : Erreur SQL lors de l'insertion

**Solution** : Exécuter le script SQL

```bash
psql votre_url_supabase -f tables/extend_clients_table.sql
```

### Problème 3 : Données non transmises

**Symptôme** : Les champs sont undefined dans le formulaire

**Solution** : Vérifier le composant ClientForm

```typescript
// Vérifier que les valeurs sont bien transmises
const handleSubmit = () => {
  console.log('Données du formulaire:', formData);
  onSubmit(formData);
};
```

## 📋 Checklist de vérification

- [ ] Script SQL exécuté avec succès
- [ ] Colonnes ajoutées à la table `clients`
- [ ] Service `supabaseService.ts` mis à jour
- [ ] Type `Client` étendu dans `types/index.ts`
- [ ] Store mis à jour dans `store/index.ts`
- [ ] Composant `ClientForm` fonctionnel
- [ ] Test de création d'un client avec tous les champs
- [ ] Vérification dans la base de données

## 🚀 Test rapide

1. **Créer un client test** avec ces données :
   - Région : "Île-de-France"
   - Code postal : "75001"
   - Ville : "Paris"
   - Code comptable : "TEST001"
   - CNI : "123456789"
   - Nom entreprise : "Test SARL"
   - SIREN : "123456789"
   - TVA : "FR12345678901"

2. **Vérifier dans la base** :
   ```sql
   SELECT region, postal_code, city, accounting_code, cni_identifier,
          company_name, siren_number, vat_number
   FROM clients 
   WHERE email = 'test@example.com';
   ```

3. **Si les champs sont vides**, le problème vient du mapping
4. **Si les colonnes n'existent pas**, exécuter le script SQL

## 📞 Support

Si le problème persiste :

1. **Vérifier les logs** de la console
2. **Tester avec un client simple** d'abord
3. **Vérifier les permissions** Supabase
4. **Contrôler les politiques RLS** si activées

---

*Ce guide sera mis à jour selon les résultats des tests.*
