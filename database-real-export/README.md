# Export des Vraies Tables de Production

## Fichiers

- `export-real-tables.sql`: Script complet pour exporter toutes les vraies tables
- `export-simple.sql`: Script simplifié pour l'export
- `README.md`: Ce fichier d'explication

## Utilisation

### Méthode 1: Script complet

1. **Connectez-vous à votre base de données de PRODUCTION**
2. **Exécutez le script** `export-real-tables.sql`
3. **Copiez les résultats** dans un fichier
4. **Adaptez le script** selon vos besoins
5. **Exécutez dans votre base de développement**

### Méthode 2: Script simple

1. **Connectez-vous à votre base de données de PRODUCTION**
2. **Exécutez le script** `export-simple.sql`
3. **Pour chaque table trouvée**, générez le CREATE TABLE
4. **Copiez les scripts générés** dans votre base de développement

## Tables qui seront exportées

Le script va lister TOUTES les tables existantes dans votre base de production, notamment:

- Tables de votre application
- Tables système Supabase
- Tables d'authentification
- Tables de stockage
- Et toutes les autres tables présentes

## Sécurité

⚠️ **ATTENTION**: 
- Exécutez d'abord dans la PRODUCTION pour voir la structure
- Vérifiez les résultats avant de les importer
- Certaines tables système ne doivent pas être copiées
- Adaptez le script selon vos besoins spécifiques

## Alternative recommandée

Si vous voulez une méthode plus simple, utilisez l'interface Supabase:

1. **Dashboard Supabase Production** → **Table Editor**
2. **Pour chaque table** → **View** → **Copy as SQL**
3. **Copiez le script** dans votre base de développement

Généré le: 2025-09-06T16:55:33.620Z
