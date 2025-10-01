# 🗄️ Guide Configuration Bases de Données - Flyway Desktop

## ✅ Configuration Corrigée !

J'ai restructuré la configuration pour que Flyway Desktop puisse correctement identifier et utiliser vos environnements de base de données.

## 🔧 Configuration Actuelle

### Environnement de Développement
```
Nom: Développement
Type: PostgreSQL
URL: postgresql://postgres:postgres@localhost:54322/postgres
Utilisateur: postgres
Mot de passe: postgres
Schéma: public
```

### Environnement de Production
```
Nom: Production
Type: PostgreSQL
URL: postgresql://postgres:EGQUN6paP21OlNUu@db.gggoqnxrspviuxadvkbh.supabase.co:5432/postgres
Utilisateur: postgres
Mot de passe: EGQUN6paP21OlNUu
Schéma: public
```

## 🚀 Étapes dans Flyway Desktop

### 1. Recharger le Projet
1. **Fermez Flyway Desktop**
2. **Rouvrez Flyway Desktop**
3. **Ouvrez votre projet "Atelier Gestion"**

### 2. Vérifier les Environnements
Vous devriez maintenant voir :
- **Working Environments** : "Développement"
- **Deployment Environments** : "Production"

### 3. Configurer la Connexion

#### Pour le Développement :
1. **Cliquez sur "Configure development environment"**
2. **Sélectionnez "Existing database"**
3. **Remplissez :**
   ```
   Display name: Développement
   Driver: PostgreSQL
   Host: localhost
   Port: 54322
   Database: postgres
   Schemas: public
   Username: postgres
   Password: postgres
   ```

#### Pour la Production :
1. **Cliquez sur "Configure new environment"**
2. **Sélectionnez "Existing database"**
3. **Remplissez :**
   ```
   Display name: Production
   Driver: PostgreSQL
   Host: db.gggoqnxrspviuxadvkbh.supabase.co
   Port: 5432
   Database: postgres
   Schemas: public
   Username: postgres
   Password: EGQUN6paP21OlNUu
   ```

## 🔍 Vérification

### Test de Connexion
- Cliquez sur **"Test connection"** pour chaque environnement
- Vous devriez voir "Connection successful"

### Si l'Erreur Persiste

#### Pour le Développement :
```bash
# Vérifier que Supabase local est démarré
supabase start

# Vérifier le statut
supabase status
```

#### Pour la Production :
- Vérifiez que l'URL Supabase est correcte
- Vérifiez que les identifiants sont corrects
- Vérifiez que la base est accessible

## 📁 Migrations

Une fois connecté, vous devriez voir vos migrations :
- `V1__Initial_Schema.sql`
- `V2__Complete_Schema.sql`
- `V3__Additional_Tables.sql`
- `V4__Indexes_And_Constraints.sql`
- `V5__RLS_Policies.sql`

## 🚀 Processus de Migration

### 1. Test en Développement
1. **Sélectionnez l'environnement "Développement"**
2. **Allez dans "Migration scripts"**
3. **Cliquez sur "Migrate"**
4. **Vérifiez que toutes les migrations s'appliquent**

### 2. Déploiement en Production
1. **Sélectionnez l'environnement "Production"**
2. **Cliquez sur "Migrate"**
3. **Confirmez le déploiement**

## 🛡️ Sécurité

- **Sauvegarde automatique** : Flyway Desktop peut créer des sauvegardes
- **Validation** : Toujours valider avant de déployer
- **Test** : Testez d'abord en développement

## ✅ Checklist

- [ ] Environnement de développement configuré
- [ ] Environnement de production configuré
- [ ] Connexions testées avec succès
- [ ] Migrations visibles
- [ ] Test en développement
- [ ] Déploiement en production

---

**Vos bases de données sont maintenant correctement configurées dans Flyway Desktop !** 🎉
