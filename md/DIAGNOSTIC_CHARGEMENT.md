# Diagnostic : Problème de chargement des paramètres

## Situation actuelle
- ✅ Table `system_settings` existe dans Supabase
- ✅ Aucune erreur dans la console
- ❌ Les paramètres ne se chargent pas
- ❌ Les boutons de sauvegarde restent désactivés

## Diagnostic étape par étape

### 1. Test de connexion directe

**Dans la page Administration :**
1. Cliquer sur le bouton **"Test connexion"**
2. Vérifier la notification qui apparaît
3. Vérifier les logs dans la console

**Résultats attendus :**
- ✅ Notification : "Connexion OK: 12 paramètres"
- ✅ Logs : "🧪 Test de connexion Supabase..." + "📊 Test direct Supabase: {...}"

### 2. Test de chargement via le service

**Dans la page Administration :**
1. Cliquer sur le bouton **"Recharger paramètres"**
2. Vérifier les logs dans la console

**Résultats attendus :**
```
🔄 Chargement des paramètres système...
🔍 systemSettingsService.getAll() appelé
📊 Résultat Supabase: {data: [...], error: null}
✅ Données récupérées: [...]
📊 Résultat du chargement: {success: true, data: [...]}
✅ Paramètres système chargés: [...]
```

### 3. Vérification des politiques RLS

**Dans Supabase SQL Editor :**
```sql
-- Vérifier les politiques existantes
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'system_settings';
```

**Résultats attendus :**
- 4 politiques : view, update, create, delete
- Toutes pour les administrateurs

### 4. Vérification du rôle utilisateur

**Dans Supabase SQL Editor :**
```sql
-- Vérifier le rôle de l'utilisateur connecté
SELECT id, email, role 
FROM users 
WHERE id = auth.uid();
```

**Résultats attendus :**
- Utilisateur trouvé
- Rôle = 'admin'

### 5. Test de lecture directe

**Dans Supabase SQL Editor :**
```sql
-- Test sans RLS (doit fonctionner)
SELECT COUNT(*) FROM system_settings;

-- Test avec RLS (peut échouer si pas admin)
SELECT COUNT(*) FROM system_settings;
```

## Problèmes possibles et solutions

### Problème 1 : Politiques RLS trop restrictives

**Symptômes :**
- Test connexion échoue
- Erreur "Permission denied"

**Solution :**
```sql
-- Créer une politique temporaire pour tous les utilisateurs
CREATE POLICY "Temporary allow all" ON system_settings
  FOR ALL USING (true);
```

### Problème 2 : Utilisateur non administrateur

**Symptômes :**
- Utilisateur connecté mais rôle ≠ 'admin'
- Erreur "Permission denied"

**Solution :**
```sql
-- Mettre à jour le rôle de l'utilisateur
UPDATE users 
SET role = 'admin' 
WHERE id = auth.uid();
```

### Problème 3 : Table vide

**Symptômes :**
- Connexion OK mais 0 paramètres
- Table existe mais pas de données

**Solution :**
```sql
-- Insérer les paramètres par défaut
INSERT INTO system_settings (key, value, description, category) VALUES
('workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
('workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse', 'general'),
('workshop_phone', '01 23 45 67 89', 'Téléphone', 'general'),
('workshop_email', 'contact@atelier.fr', 'Email', 'general'),
('vat_rate', '20', 'TVA', 'billing'),
('currency', 'EUR', 'Devise', 'billing'),
('invoice_prefix', 'FACT-', 'Préfixe facture', 'billing'),
('date_format', 'dd/MM/yyyy', 'Format date', 'billing'),
('auto_backup', 'true', 'Sauvegarde auto', 'system'),
('notifications', 'true', 'Notifications', 'system'),
('backup_frequency', 'daily', 'Fréquence backup', 'system'),
('max_file_size', '10', 'Taille max fichier', 'system');
```

### Problème 4 : Variables d'environnement

**Symptômes :**
- Erreur de connexion Supabase
- Impossible de se connecter

**Solution :**
Vérifier le fichier `.env` :
```
VITE_SUPABASE_URL=votre_url_supabase
VITE_SUPABASE_ANON_KEY=votre_clé_anon
```

## Tests de validation

### Test 1 : Connexion de base
```javascript
// Dans la console du navigateur
console.log('Test Supabase:', supabase);
```

### Test 2 : Test d'authentification
```javascript
// Dans la console du navigateur
supabase.auth.getUser().then(console.log);
```

### Test 3 : Test de lecture
```javascript
// Dans la console du navigateur
supabase.from('system_settings').select('*').then(console.log);
```

## Logs à vérifier

### Logs de succès
```
🔄 Chargement des paramètres système...
🔍 systemSettingsService.getAll() appelé
📊 Résultat Supabase: {data: Array(12), error: null}
✅ Données récupérées: [...]
📊 Résultat du chargement: {success: true, data: [...]}
✅ Paramètres système chargés: [...]
```

### Logs d'erreur courants
```
❌ Erreur Supabase: {message: "Permission denied"}
💥 Exception dans getAll: Error: ...
⚠️ Aucun paramètre système trouvé ou erreur: {success: false, error: "..."}
```

## Solution d'urgence

Si rien ne fonctionne, créer une version temporaire :

```javascript
// Dans le store, remplacer loadSystemSettings par :
loadSystemSettings: async () => {
  const defaultSettings = [
    { id: '1', key: 'workshop_name', value: 'Atelier de réparation', category: 'general' },
    { id: '2', key: 'vat_rate', value: '20', category: 'billing' },
    // ... autres paramètres
  ];
  set({ systemSettings: defaultSettings });
}
```
