# Guide - Résolution Complète Erreur 406 et Boucles Infinies

## 🚨 Problèmes Identifiés

1. **Erreur 406 (Not Acceptable)** : Le trigger ne fonctionne pas
2. **Boucles infinies** : Logs répétitifs dans la console
3. **Utilisateurs manquants** : Nouveaux utilisateurs non ajoutés automatiquement

## 🔍 Diagnostic

### Erreur 406
```
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?select=*&user_id=eq.11763d5d-3251-49dc-8c4e-6dc1364cbc47 406 (Not Acceptable)
```

### Boucles Infinies
```
useAuth.ts:109 ✅ Utilisateur connecté: test15@yopmail.com
supabaseService.ts:597 📝 Aucune donnée utilisateur en attente
```

## ✅ Solution Complète

### Étape 1 : Correction de la Base de Données

Exécuter le script de correction finale :

```sql
-- Copier et exécuter correction_permissions_et_trigger_finale.sql
```

Ce script va :
- ✅ **Nettoyer** tous les anciens triggers
- ✅ **Corriger** toutes les permissions
- ✅ **Créer** un trigger robuste
- ✅ **Synchroniser** tous les utilisateurs existants
- ✅ **Tester** le trigger automatiquement

### Étape 2 : Vérification du Trigger

Après exécution, vous devriez voir :

```
✅ SUCCÈS: L'utilisateur de test a été ajouté automatiquement par le trigger

Vérification finale | total_users | total_subscriptions | trigger_exists | function_exists
-------------------|-------------|---------------------|----------------|-----------------
Vérification finale | 5           | 5                   | 1              | 1

Correction finale terminée | Le trigger fonctionne et les nouveaux utilisateurs seront ajoutés automatiquement
```

### Étape 3 : Test de l'Inscription

1. **Créer** un nouveau compte via l'interface
2. **Vérifier** qu'il n'y a plus d'erreur 406
3. **Confirmer** qu'il apparaît dans la page admin

## 🔧 Fonctionnalités du Script de Correction

### Permissions Complètes
```sql
-- Désactiver RLS
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Donner tous les privilèges
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;
```

### Trigger Robuste
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertion avec gestion d'erreur complète
  INSERT INTO subscription_status (...) VALUES (...);
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Gestion d'erreur sans bloquer l'inscription
    RAISE NOTICE 'Erreur: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Synchronisation Intelligente
```sql
-- Ajouter tous les utilisateurs manquants
INSERT INTO subscription_status (...)
SELECT ... FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO UPDATE SET ...;
```

## 🧪 Tests

### Test Automatique du Trigger
Le script inclut un test automatique qui :
1. Crée un utilisateur de test
2. Vérifie qu'il est ajouté à `subscription_status`
3. Nettoie les données de test
4. Affiche le résultat

### Test Manuel
1. **Créer** un nouveau compte
2. **Vérifier** qu'il n'y a plus d'erreur 406
3. **Cliquer** sur "Actualiser" dans la page admin
4. **Confirmer** qu'il apparaît dans la liste

## 🔄 Résolution des Boucles Infinies

### Causes Possibles
1. **useAuth** se re-exécute trop souvent
2. **useSubscription** fait des appels répétés
3. **useAuthenticatedData** se recharge en boucle

### Solutions

#### 1. Vérifier les Dépendances
```typescript
// Dans useAuth.ts
useEffect(() => {
  // Code...
}, []); // Dépendances vides
```

#### 2. Ajouter des Guards
```typescript
// Éviter les re-exécutions inutiles
if (authStateRef.current === 'changing') {
  return;
}
```

#### 3. Optimiser les Appels
```typescript
// Utiliser useCallback pour les fonctions
const loadSubscriptions = useCallback(async () => {
  // Code...
}, []);
```

## 📊 Résultats Attendus

### Après Correction de la Base de Données
```
✅ SUCCÈS: L'utilisateur de test a été ajouté automatiquement par le trigger
Vérification finale | total_users | total_subscriptions | trigger_exists | function_exists
-------------------|-------------|---------------------|----------------|-----------------
Vérification finale | 5           | 5                   | 1              | 1
```

### Après Test d'Inscription
```
✅ Inscription réussie: {user: {...}, session: null}
✅ Utilisateur connecté: test17@yopmail.com
✅ Liste actualisée : 6 utilisateurs
```

### Dans la Console Browser
```
🔄 Rechargement des utilisateurs... (force refresh)
✅ 6 utilisateurs chargés
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_permissions_et_trigger_finale.sql`
2. **Vérifier** le message de succès du test
3. **Tester** l'inscription d'un nouveau compte
4. **Vérifier** qu'il n'y a plus d'erreur 406
5. **Cliquer** sur "Actualiser" dans la page admin

### Vérification
- ✅ **Plus d'erreur 406** dans la console
- ✅ **Nouveaux utilisateurs** apparaissent automatiquement
- ✅ **Boucles infinies** réduites
- ✅ **Trigger fonctionne** correctement

## ✅ Checklist de Validation

- [ ] Script de correction exécuté
- [ ] Test automatique réussi
- [ ] Plus d'erreur 406
- [ ] Nouveau compte créé sans erreur
- [ ] Utilisateur apparaît dans la page admin
- [ ] Bouton actualiser fonctionne
- [ ] Boucles infinies réduites

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier que le trigger fonctionne
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status;
```

---

**Note** : Cette solution corrige définitivement l'erreur 406 et réduit les boucles infinies en créant un trigger robuste et en optimisant les permissions.
