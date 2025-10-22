# 🔧 Guide Flyway Desktop vs CLI - Atelier Gestion

## 🎯 Le Problème

L'erreur `No Flyway database plugin found to handle postgresql` indique que vous essayez d'utiliser la **CLI Flyway** mais que vous devriez utiliser **Flyway Desktop** (interface graphique).

## 🔍 Différence entre Flyway Desktop et CLI

### Flyway Desktop (Interface Graphique)
- ✅ **Recommandé pour votre cas**
- Interface graphique intuitive
- Gestion des environnements intégrée
- Pas besoin d'installer la CLI
- Configuration via fichiers `.toml`

### Flyway CLI (Ligne de Commande)
- ❌ **Non nécessaire pour votre cas**
- Nécessite installation séparée
- Nécessite plugins PostgreSQL
- Configuration plus complexe

## 🚀 Solution : Utiliser Flyway Desktop

### 1. Ouvrir Flyway Desktop
- Lancez **Flyway Desktop** (pas la CLI)
- Ouvrez votre projet "Atelier Gestion"

### 2. Configurer les Environnements

#### Environnement de Développement :
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

#### Environnement de Production :
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

### 3. Tester les Connexions
- Cliquez sur **"Test connection"** pour chaque environnement
- Vous devriez voir "Connection successful"

### 4. Appliquer les Migrations
1. **Sélectionnez l'environnement "Développement"**
2. **Allez dans l'onglet "Migration scripts"**
3. **Cliquez sur "Migrate"**
4. **Vérifiez que toutes les migrations s'appliquent**

## 🛠️ Si Vous Voulez Utiliser la CLI

### Installation de Flyway CLI
```bash
# Installation via Homebrew
brew install flyway

# Ou téléchargement direct
# https://flywaydb.org/download/
```

### Installation du Plugin PostgreSQL
```bash
# Télécharger le plugin PostgreSQL
# https://flywaydb.org/download/
```

### Configuration CLI
```bash
# Utiliser la configuration
flyway -configFiles=flyway.toml info
```

## 🎯 Recommandation

**Utilisez Flyway Desktop** pour votre projet :
- Plus simple et intuitif
- Gestion des environnements intégrée
- Pas besoin d'installer des plugins
- Interface graphique claire

## ✅ Checklist

- [ ] Utiliser Flyway Desktop (pas la CLI)
- [ ] Configurer l'environnement de développement
- [ ] Configurer l'environnement de production
- [ ] Tester les connexions
- [ ] Appliquer les migrations

---

**Utilisez Flyway Desktop pour éviter les problèmes de plugins !** 🎉
