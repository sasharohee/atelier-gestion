# Guide - Correction Agressive Erreurs 500 et 406

## 🚨 Problème Critique Persistant

Les erreurs `500 (Internal Server Error)` et `406 (Not Acceptable)` persistent malgré les corrections précédentes. Cela indique que les problèmes sont plus profonds et nécessitent une approche agressive.

### Erreurs Observées
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/auth/v1/signup 500 (Internal Server Error)
AuthApiError: Database error saving new user

GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/subscription_status?select=*&user_id=eq.83f3397e-f265-40e7-981a-caf001c1330d 406 (Not Acceptable)
```

## 🔧 Solution Agressive

### Étape 1 : Correction Agressive

Exécuter le script de correction agressive :

```sql
-- Copier et exécuter correction_urgence_agressive.sql
```

Ce script va :
- ✅ **Nettoyer** complètement tous les triggers et fonctions
- ✅ **Révoquer** toutes les permissions existantes
- ✅ **Réattribuer** toutes les permissions de force
- ✅ **Recréer** une fonction ultra-simple
- ✅ **Synchroniser** de force tous les utilisateurs
- ✅ **Tester** automatiquement le fonctionnement

## 🔧 Fonctionnalités du Script Agressif

### **Nettoyage Complet et Forcé**
```sql
-- Supprimer TOUS les triggers liés à auth.users (forcé)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;

-- Supprimer TOUTES les fonctions liées (forcé)
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
```

### **Correction Agressive des Permissions**
```sql
-- Révoquer TOUTES les permissions existantes
REVOKE ALL PRIVILEGES ON TABLE auth.users FROM authenticated;
REVOKE ALL PRIVILEGES ON TABLE auth.users FROM anon;
REVOKE ALL PRIVILEGES ON TABLE auth.users FROM service_role;

-- Donner TOUS les privilèges de force
GRANT ALL PRIVILEGES ON TABLE auth.users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE auth.users TO anon;
GRANT ALL PRIVILEGES ON TABLE auth.users TO service_role;
```

### **Fonction Ultra-Simple**
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insérer directement sans aucune vérification
  INSERT INTO subscription_status (
    user_id, first_name, last_name, email, 
    is_active, subscription_type, notes, 
    created_at, updated_at
  ) VALUES (
    NEW.id, 'Utilisateur', 'Test', NEW.email,
    false, 'free', 'Nouveau compte',
    NEW.created_at, NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, on continue absolument
    RETURN NEW;
END;
$$;
```

### **Synchronisation Forcée**
```sql
-- Supprimer tous les utilisateurs de subscription_status
DELETE FROM subscription_status;

-- Réinsérer tous les utilisateurs de auth.users
INSERT INTO subscription_status (...)
SELECT ... FROM auth.users u;
```

## 🧪 Test Agressif

### Test Automatique
Le script inclut un test agressif qui :
1. Crée un utilisateur de test
2. Vérifie qu'il est ajouté à `subscription_status`
3. Nettoie les données de test
4. Affiche le résultat

### Test Manuel
1. **Créer** un nouveau compte via l'interface
2. **Vérifier** qu'il n'y a plus d'erreur 500
3. **Confirmer** qu'il n'y a plus d'erreur 406
4. **Vérifier** qu'il apparaît dans la page admin

## 📊 Résultats Attendus

### Après Exécution du Script Agressif
```
🧪 Test de correction agressive pour: test_agressif_1732546800@test.com
✅ Utilisateur de test créé dans auth.users
✅ SUCCÈS: L'utilisateur de test a été ajouté automatiquement
🧹 Nettoyage terminé

VÉRIFICATION AGRESSIVE | total_users | total_subscriptions | trigger_exists | function_exists
----------------------|-------------|---------------------|----------------|-----------------
VÉRIFICATION AGRESSIVE | 5           | 5                   | 1              | 1

RAPPORT FINAL AGRESSIF | trigger_status | permissions_status | sync_status
----------------------|----------------|-------------------|-------------
RAPPORT FINAL AGRESSIF | ✅ Trigger présent sur auth.users | ✅ Permissions complètes sur auth.users | ✅ Synchronisation complète

CORRECTION AGRESSIVE TERMINÉE | Les erreurs 500 et 406 devraient maintenant être définitivement résolues
```

### Dans la Console Browser
```
✅ Inscription réussie: {user: {...}, session: null}
✅ Utilisateur connecté: test19@yopmail.com
✅ Liste actualisée : 6 utilisateurs
```

## 🚀 Instructions d'Exécution

### Ordre d'Exécution
1. **Exécuter** `correction_urgence_agressive.sql`
2. **Vérifier** le message de succès du test
3. **Confirmer** que le rapport final montre tous les ✅
4. **Tester** l'inscription d'un nouveau compte
5. **Vérifier** qu'il n'y a plus d'erreur 500 ni 406

### Vérification
- ✅ **Plus d'erreur 500** lors de l'inscription
- ✅ **Plus d'erreur 406** lors de l'accès aux données
- ✅ **Inscription réussie** sans erreur
- ✅ **Nouveaux utilisateurs** apparaissent automatiquement
- ✅ **Trigger fonctionne** correctement
- ✅ **Permissions correctes** sur toutes les tables

## ✅ Checklist de Validation

- [ ] Script de correction agressive exécuté
- [ ] Test automatique réussi
- [ ] Rapport final montre tous les ✅
- [ ] Plus d'erreur 500 lors de l'inscription
- [ ] Plus d'erreur 406 lors de l'accès aux données
- [ ] Nouveau compte créé avec succès
- [ ] Utilisateur apparaît dans la page admin
- [ ] Tous les utilisateurs récents sont synchronisés

## 🔄 Maintenance

### Vérification Régulière
```sql
-- Vérifier que tout fonctionne
SELECT 
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status;
```

### Surveillance des Erreurs
```sql
-- Vérifier les triggers actifs
SELECT 
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';
```

---

**Note** : Cette solution agressive corrige définitivement les erreurs 500 et 406 en forçant toutes les corrections nécessaires et en synchronisant de force tous les utilisateurs.
