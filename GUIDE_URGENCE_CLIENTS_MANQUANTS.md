# 🚨 GUIDE D'URGENCE - Clients Manquants Après Isolation

## 🚨 Problème Identifié

**Après l'isolation des données, les clients qui appartiennent à votre compte ne s'affichent plus** - L'isolation fonctionne mais cache même vos propres données.

## 🔍 Cause du Problème

Le problème vient du fait que :
1. **Les clients existants n'ont pas le bon `workshop_id`** (NULL ou valeur par défaut)
2. **Les politiques RLS sont trop strictes** et cachent même vos propres données
3. **L'isolation fonctionne trop bien** et filtre tout

## ⚡ Solution d'Urgence

### Étape 1: Diagnostic du Problème
Exécutez le script de diagnostic :

```bash
psql "postgresql://user:pass@host:port/db" -f diagnostic_clients_missing.sql
```

### Étape 2: Correction des Clients
Exécutez le script de correction :

```bash
psql "postgresql://user:pass@host:port/db" -f correction_clients_missing.sql
```

### Étape 3: Vérification
Vérifiez que les clients sont maintenant visibles :

```bash
psql "postgresql://user:pass@host:port/db" -f diagnostic_clients_missing.sql
```

## 🔧 Actions du Script de Correction

Le script `correction_clients_missing.sql` effectue :

1. **Diagnostic initial** - Identifie le problème exact
2. **Désactivation temporaire de RLS** - Permet l'accès aux données
3. **Mise à jour des workshop_id** - Assigne le bon `workshop_id` à vos clients
4. **Recréation des politiques RLS** - Recrée l'isolation correctement
5. **Réactivation de RLS** - Remet l'isolation en place
6. **Vérification finale** - Confirme que tout fonctionne

## ✅ Résultat Attendu

Après exécution, vous devriez voir :
- ✅ **Vos clients sont maintenant visibles** dans la page clients
- ✅ **L'isolation fonctionne toujours** - Pas de données d'autres ateliers
- ✅ **Toutes les opérations fonctionnent** (création, modification, suppression)

## 📋 Vérification Manuelle

### Vérifier le workshop_id actuel
```sql
SELECT value FROM system_settings WHERE key = 'workshop_id';
```

### Vérifier les clients visibles
```sql
SELECT COUNT(*) FROM clients;
```

### Vérifier les workshop_id des clients
```sql
SELECT workshop_id, COUNT(*) 
FROM clients 
GROUP BY workshop_id 
ORDER BY COUNT(*) DESC;
```

## 🆘 Si le Problème Persiste

### Option 1: Correction Manuelle
```sql
-- Désactiver RLS temporairement
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Mettre à jour tous les clients avec votre workshop_id
UPDATE clients 
SET workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
WHERE workshop_id IS NULL 
   OR workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
```

### Option 2: Vérification du workshop_id
```sql
-- Vérifier que le workshop_id est correct
SELECT 
    key,
    value,
    CASE 
        WHEN value IS NULL THEN 'PROBLÈME: workshop_id non défini'
        WHEN value = '00000000-0000-0000-0000-000000000000' THEN 'PROBLÈME: workshop_id par défaut'
        ELSE 'OK: workshop_id défini'
    END as status
FROM system_settings 
WHERE key = 'workshop_id';
```

## 🎯 Résultat Final

Après application de cette solution :
- 🔒 **Isolation maintenue** : Seules vos données sont visibles
- 👥 **Clients restaurés** : Vos clients sont maintenant visibles
- ⚡ **Fonctionnalité complète** : Toutes les opérations fonctionnent

**Vos clients sont maintenant visibles tout en gardant l'isolation !** 🎉

## 📞 Support d'Urgence

Si le problème persiste après ces étapes :

1. **Sauvegardez vos données** avant toute action
2. **Exécutez le diagnostic** pour identifier la cause exacte
3. **Contactez le support** avec les résultats du diagnostic
