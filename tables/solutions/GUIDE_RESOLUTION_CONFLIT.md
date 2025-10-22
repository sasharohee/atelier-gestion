# 🔧 Résolution Conflit Migration V1

## ❌ Problème Identifié

L'erreur `Found more than one migration with version 1` indique qu'il y a deux fichiers de migration avec la même version V1.

## ✅ Solution Appliquée

J'ai supprimé le fichier en double `V1__Initial_Schema_Fixed.sql` pour résoudre le conflit.

### 📁 **État Actuel**

- ✅ `V1__Initial_Schema.sql` - Migration V1 principale (conservée)
- ❌ `V1__Initial_Schema_Fixed.sql` - Migration V1 en double (supprimée)

### 🔍 **Vérification**

Vérifiez qu'il n'y a plus qu'un seul fichier V1 :
```bash
ls -la migrations/V1*
```

Vous devriez voir seulement :
```
-rw-r--r-- migrations/V1__Initial_Schema.sql
```

## 🚀 **Prochaines Étapes**

1. **Vérifiez l'état des migrations** dans Flyway Desktop
2. **Relancez la migration V1** si nécessaire
3. **Continuez avec les autres migrations** (V2, V3, V4, V5)

## 🛠️ **Si l'Erreur de Types Persiste**

Si vous avez encore l'erreur `type "alert_severity_type" already exists`, vous pouvez :

### Option 1 : Modifier la Migration V1 Existante
Éditez `migrations/V1__Initial_Schema.sql` et remplacez les `CREATE TYPE` par :
```sql
DO $$ BEGIN
    CREATE TYPE "public"."alert_severity_type" AS ENUM ('info', 'warning', 'error', 'critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
```

### Option 2 : Nettoyer la Base de Production
```sql
-- Supprimer les types existants (ATTENTION : supprime les données)
DROP TYPE IF EXISTS "public"."alert_severity_type" CASCADE;
```

## ✅ **Checklist**

- [ ] Conflit de migration résolu
- [ ] Un seul fichier V1 présent
- [ ] Migration V1 prête à être exécutée
- [ ] Pas d'erreur de duplication de version

---

**Le conflit de migration V1 est maintenant résolu !** 🎉
