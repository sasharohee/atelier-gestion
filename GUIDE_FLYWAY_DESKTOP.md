# 🖥️ Guide Flyway Desktop - Atelier Gestion

## 🎯 Configuration Flyway Desktop

Maintenant que votre configuration est corrigée pour PostgreSQL, voici comment configurer Flyway Desktop :

## 📋 Étapes de Configuration

### 1. Ouvrir Flyway Desktop
- Lancez Flyway Desktop
- Ouvrez votre projet "Atelier Gestion"

### 2. Configurer l'Environnement de Développement

1. **Cliquez sur "Configure development environment"**
2. **Sélectionnez PostgreSQL**
3. **Remplissez les informations :**
   - **Server:** `localhost`
   - **Port:** `54322`
   - **Database:** `postgres`
   - **Username:** `postgres`
   - **Password:** `postgres`
   - **Schema:** `public`

### 3. Configurer l'Environnement de Production

1. **Cliquez sur "Configure new environment"** dans la section "Deployment Environments"
2. **Nom:** `Production`
3. **Sélectionnez PostgreSQL**
4. **Remplissez les informations :**
   - **Server:** `db.gggoqnxrspviuxadvkbh.supabase.co`
   - **Port:** `5432`
   - **Database:** `postgres`
   - **Username:** `postgres`
   - **Password:** `EGQUN6paP21OlNUu`
   - **Schema:** `public`

## 🚀 Utilisation des Migrations

### 1. Vérifier les Migrations
- Allez dans l'onglet "Migration scripts"
- Vous devriez voir vos 5 migrations :
  - `V1__Initial_Schema.sql`
  - `V2__Complete_Schema.sql`
  - `V3__Additional_Tables.sql`
  - `V4__Indexes_And_Constraints.sql`
  - `V5__RLS_Policies.sql`

### 2. Tester en Développement
1. **Sélectionnez l'environnement "Développement"**
2. **Cliquez sur "Migrate"**
3. **Vérifiez que toutes les migrations s'appliquent correctement**

### 3. Déployer en Production
1. **Sélectionnez l'environnement "Production"**
2. **Cliquez sur "Migrate"**
3. **Confirmez le déploiement**

## 🔍 Fonctionnalités Flyway Desktop

### Comparaison de Bases de Données
- **Compare** : Comparez votre base de dev avec la prod
- **Generate Script** : Générez des scripts de migration automatiques
- **Deploy** : Déployez les changements

### Gestion des Versions
- **History** : Voir l'historique des migrations
- **Status** : État actuel de chaque environnement
- **Validate** : Valider les migrations avant déploiement

## 🛡️ Sécurité

### Sauvegarde Automatique
- Flyway Desktop peut créer des sauvegardes automatiques
- Activez cette option dans les paramètres

### Validation
- Toujours valider les migrations avant déploiement
- Utilisez l'environnement de développement pour tester

## 📊 Monitoring

### Table flyway_schema_history
- Flyway Desktop gère automatiquement cette table
- Elle contient l'historique de toutes les migrations

### Logs
- Consultez les logs en cas d'erreur
- Les logs sont visibles dans l'interface Flyway Desktop

## 🚨 Résolution de Problèmes

### Erreur de Connexion
1. Vérifiez les paramètres de connexion
2. Vérifiez que la base de données est accessible
3. Vérifiez les permissions

### Erreur de Migration
1. Vérifiez la syntaxe SQL
2. Vérifiez les dépendances entre tables
3. Utilisez l'environnement de développement pour tester

### Rollback
1. Utilisez l'historique des migrations
2. Sélectionnez la version précédente
3. Cliquez sur "Undo"

## ✅ Checklist de Déploiement

- [ ] Environnement de développement configuré
- [ ] Environnement de production configuré
- [ ] Migrations testées en développement
- [ ] Sauvegarde de la production créée
- [ ] Migration vers la production
- [ ] Vérification du résultat

## 📞 Support

En cas de problème :
1. Vérifiez les logs Flyway Desktop
2. Consultez la documentation Flyway
3. Testez d'abord en développement

---

**Votre configuration Flyway Desktop est maintenant prête !** 🎉
