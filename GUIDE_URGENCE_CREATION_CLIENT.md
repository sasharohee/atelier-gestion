# 🚨 GUIDE D'URGENCE - Erreur Création de Client

## 🚨 Problème Identifié

**Erreur PGRST116 lors de la création de client** - L'erreur `Cannot coerce the result to a single JSON object` indique un problème avec les politiques RLS ou la structure de la table.

## 🔍 Cause du Problème

L'erreur peut venir de :
1. **Politiques RLS manquantes** - Aucune politique INSERT définie
2. **Politiques RLS incorrectes** - Politiques qui bloquent la création
3. **Problème de workshop_id** - Le workshop_id n'est pas correctement assigné
4. **Structure de table incorrecte** - Colonnes manquantes ou contraintes

## ⚡ Solution d'Urgence

### Étape 1: Diagnostic
Exécutez le script de diagnostic :

```bash
psql "postgresql://user:pass@host:port/db" -f diagnostic_creation_client.sql
```

### Étape 2: Correction
Exécutez le script de correction :

```bash
psql "postgresql://user:pass@host:port/db" -f correction_creation_client.sql
```

### Étape 3: Vérification
Vérifiez que la création fonctionne :

```bash
psql "postgresql://user:pass@host:port/db" -f diagnostic_creation_client.sql
```

## 🔧 Actions du Script de Correction

Le script `correction_creation_client.sql` effectue :

1. **Diagnostic initial** - Identifie l'état actuel
2. **Suppression de toutes les politiques RLS** - Nettoie les politiques existantes
3. **Création de nouvelles politiques RLS complètes** - Politiques fonctionnelles
4. **Test de création de client** - Vérifie que la création fonctionne
5. **Vérification de l'isolation** - Assure que l'isolation est maintenue

## ✅ Résultat Attendu

Après exécution, vous devriez voir :
- ✅ **Plus d'erreur PGRST116** lors de la création de client
- ✅ **Création de client fonctionnelle** dans l'application
- ✅ **Clients visibles** dans la liste
- ✅ **Isolation maintenue** - Seules vos données sont visibles

## 📋 Vérification Manuelle

### Vérifier les politiques RLS
```sql
SELECT policyname, cmd FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'clients';
```

### Tester la création manuellement
```sql
INSERT INTO clients (
    first_name, last_name, email, phone, address, workshop_id
) VALUES (
    'Test', 'Manual', 'test.manual@example.com', '1234567890', 'Test Address',
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
) RETURNING id, first_name, last_name, email;
```

### Vérifier les clients visibles
```sql
SELECT COUNT(*) FROM clients;
```

## 🆘 Si le Problème Persiste

### Option 1: Désactiver RLS temporairement
```sql
-- Désactiver RLS pour permettre la création
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Tester la création
INSERT INTO clients (first_name, last_name, email, workshop_id) 
VALUES ('Test', 'Client', 'test@example.com', 
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1));

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
```

### Option 2: Politique RLS ultra-simple
```sql
-- Supprimer toutes les politiques
DROP POLICY IF EXISTS "Complete_Read_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Insert_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Update_Policy" ON clients;
DROP POLICY IF EXISTS "Complete_Delete_Policy" ON clients;

-- Créer une seule politique pour tout
CREATE POLICY "Ultra_Simple_All" ON clients
    FOR ALL USING (
        workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    );
```

### Option 3: Vérification de la structure
```sql
-- Vérifier la structure de la table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clients' 
ORDER BY ordinal_position;

-- Vérifier les contraintes
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'clients';
```

## 🎯 Résultat Final

Après application de cette solution :
- 🔧 **Création fonctionnelle** : Les clients peuvent être créés
- 📋 **Liste visible** : Les clients apparaissent dans l'application
- 🔒 **Isolation maintenue** : Seules vos données sont visibles
- ⚡ **Application fonctionnelle** : Plus d'erreur PGRST116

**La création de client fonctionne maintenant correctement !** 🎉

## 📞 Support d'Urgence

Si le problème persiste après ces étapes :

1. **Vérifiez les logs** de l'application pour plus de détails
2. **Testez la création manuellement** dans l'éditeur SQL de Supabase
3. **Contactez le support** avec les résultats des tests
4. **Considérez une réinitialisation** des politiques RLS si nécessaire
