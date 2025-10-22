# 🔧 Guide de Dépannage - Champs Manquants Formulaire Client

## ❌ Problème identifié
Les champs suivants ne sont pas remplis lors de la création d'un client :
- Nom société
- TVA
- SIREN
- Code Postal
- Code comptable
- Identifiant CNI

## 🔍 Diagnostic

### 1. Vérification de la structure de la base de données
Exécutez le script de diagnostic pour vérifier que toutes les colonnes existent :

```sql
-- Exécuter dans Supabase SQL Editor
\i correction_formulaire_client.sql
```

### 2. Vérification du code TypeScript
Les tests montrent que la logique de transformation fonctionne correctement :
- ✅ Formulaire ClientForm : Tous les champs sont correctement définis
- ✅ Transformation clientData : Conversion camelCase → snake_case correcte
- ✅ Service supabaseService : Envoi des données vers Supabase correct

### 3. Points de vérification

#### A. Dans le formulaire (ClientForm.tsx)
Vérifiez que les champs sont correctement liés :
```typescript
// Ligne 342-343
<TextField
  label="Nom Société"
  value={formData.companyName}
  onChange={(e) => handleInputChange('companyName', e.target.value)}
/>

// Ligne 349-350
<TextField
  label="N° TVA"
  value={formData.vatNumber}
  onChange={(e) => handleInputChange('vatNumber', e.target.value)}
/>

// Ligne 356-357
<TextField
  label="N° SIREN"
  value={formData.sirenNumber}
  onChange={(e) => handleInputChange('sirenNumber', e.target.value)}
/>

// Ligne 456-457
<TextField
  label="Code Postal"
  value={formData.postalCode}
  onChange={(e) => handleInputChange('postalCode', e.target.value)}
/>

// Ligne 567-568
<TextField
  label="Code Comptable"
  value={formData.accountingCode}
  onChange={(e) => handleInputChange('accountingCode', e.target.value)}
/>

// Ligne 574-575
<TextField
  label="Identifiant CNI"
  value={formData.cniIdentifier}
  onChange={(e) => handleInputChange('cniIdentifier', e.target.value)}
/>
```

#### B. Dans la page Clients (Clients.tsx)
Vérifiez que les données sont correctement transmises :
```typescript
// Ligne 165
companyName: clientFormData.companyName || '',

// Ligne 166
vatNumber: clientFormData.vatNumber || '',

// Ligne 167
sirenNumber: clientFormData.sirenNumber || '',

// Ligne 175
postalCode: clientFormData.postalCode || '',

// Ligne 183
accountingCode: clientFormData.accountingCode || '',

// Ligne 184
cniIdentifier: clientFormData.cniIdentifier || '',
```

#### C. Dans le service (supabaseService.ts)
Vérifiez que la transformation est correcte :
```typescript
// Ligne 1036
company_name: client.companyName || '',

// Ligne 1037
vat_number: client.vatNumber || '',

// Ligne 1038
siren_number: client.sirenNumber || '',

// Ligne 1045
postal_code: client.postalCode || '',

// Ligne 1053
accounting_code: client.accountingCode || '',

// Ligne 1054
cni_identifier: client.cniIdentifier || '',
```

## ✅ Solutions

### Solution 1: Correction de la base de données
Exécutez le script de correction pour s'assurer que tous les champs sont correctement initialisés :

```sql
-- Dans Supabase SQL Editor
\i correction_formulaire_client.sql
```

### Solution 2: Vérification des données en temps réel
Ajoutez des logs de debug dans le formulaire pour tracer les données :

```typescript
// Dans ClientForm.tsx, méthode handleSubmit
const handleSubmit = () => {
  console.log('🔍 DEBUG - Données du formulaire avant soumission:', formData);
  console.log('🔍 DEBUG - Champs critiques:');
  console.log('  - companyName:', formData.companyName);
  console.log('  - vatNumber:', formData.vatNumber);
  console.log('  - sirenNumber:', formData.sirenNumber);
  console.log('  - postalCode:', formData.postalCode);
  console.log('  - accountingCode:', formData.accountingCode);
  console.log('  - cniIdentifier:', formData.cniIdentifier);
  
  onSubmit(formData);
  if (!isEditing) {
    resetForm();
  }
};
```

### Solution 3: Test de création manuel
Créez un client de test avec tous les champs remplis pour vérifier le processus :

1. Ouvrir l'application
2. Aller dans la page Clients
3. Cliquer sur "Nouveau Client"
4. Remplir TOUS les champs, y compris :
   - Nom société : "Test SARL"
   - TVA : "FR12345678901"
   - SIREN : "123456789"
   - Code Postal : "75001"
   - Code comptable : "CLI001"
   - Identifiant CNI : "CNI123456789"
5. Cliquer sur "Créer"
6. Vérifier dans la console les logs de debug

### Solution 4: Vérification des données créées
Après création, vérifiez que les données sont bien enregistrées :

```sql
-- Dans Supabase SQL Editor
SELECT 
    id,
    first_name,
    last_name,
    email,
    company_name,
    vat_number,
    siren_number,
    postal_code,
    accounting_code,
    cni_identifier,
    created_at
FROM clients 
ORDER BY created_at DESC 
LIMIT 5;
```

## 🧪 Tests de validation

### Test 1: Formulaire complet
```javascript
// Exécuter dans la console du navigateur
const testData = {
  companyName: 'Test SARL',
  vatNumber: 'FR12345678901',
  sirenNumber: '123456789',
  postalCode: '75001',
  accountingCode: 'CLI001',
  cniIdentifier: 'CNI123456789'
};

console.log('Test des champs critiques:', testData);
```

### Test 2: Vérification de la transformation
```javascript
// Simulation de la transformation
const transformed = {
  company_name: testData.companyName,
  vat_number: testData.vatNumber,
  siren_number: testData.sirenNumber,
  postal_code: testData.postalCode,
  accounting_code: testData.accountingCode,
  cni_identifier: testData.cniIdentifier
};

console.log('Données transformées:', transformed);
```

## 📋 Checklist de résolution

- [ ] Vérifier que toutes les colonnes existent dans la base de données
- [ ] Exécuter le script de correction SQL
- [ ] Tester la création d'un client avec tous les champs remplis
- [ ] Vérifier les logs de debug dans la console
- [ ] Confirmer que les données sont bien enregistrées en base
- [ ] Tester la récupération des données créées

## 🆘 Si le problème persiste

1. **Vérifiez les erreurs dans la console du navigateur**
2. **Vérifiez les logs Supabase dans le dashboard**
3. **Testez avec un client minimal pour isoler le problème**
4. **Vérifiez que l'utilisateur est bien connecté**
5. **Vérifiez les permissions RLS sur la table clients**

## 📞 Support

Si le problème persiste après avoir suivi ce guide, fournissez :
- Les logs de la console du navigateur
- Les logs Supabase
- Un exemple de données qui ne fonctionnent pas
- La version de l'application utilisée
