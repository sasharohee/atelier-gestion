# Guide de Correction - Erreur 500 lors de l'Inscription

## 🚨 Problème Identifié

L'erreur `Failed to load resource: the server responded with a status of 500` lors de l'inscription est causée par les politiques RLS (Row Level Security) sur la table `subscription_status`. Le code frontend tente d'insérer directement dans cette table après l'inscription, mais les politiques RLS empêchent cette insertion car l'utilisateur n'est pas encore authentifié dans le contexte de la requête.

## 🔧 Solution Appliquée

### 1. Modification du Code Frontend
- **Fichier modifié**: `src/services/supabaseService.ts`
- **Changement**: Remplacement de l'insertion directe par un appel à une fonction RPC
- **Avantage**: Utilise le contexte `SECURITY DEFINER` pour contourner les restrictions RLS

### 2. Script SQL de Correction
- **Fichier créé**: `correction_inscription_rls_secure.sql`
- **Fonctionnalités**:
  - Supprime les triggers problématiques
  - Crée les tables nécessaires avec les bonnes contraintes
  - Configure RLS avec des politiques sécurisées
  - Crée une fonction RPC `create_user_default_data` avec `SECURITY DEFINER`
  - Ajoute des politiques pour le service role

## 📋 Instructions de Déploiement

### Option 1: Script Automatique (Recommandé)

1. **Configurer les variables d'environnement**:
   ```bash
   export SUPABASE_SERVICE_ROLE_KEY="votre_clé_service_role"
   export VITE_SUPABASE_URL="https://votre-projet.supabase.co"
   ```

2. **Exécuter le script de déploiement**:
   ```bash
   node deploy_correction_inscription.js
   ```

### Option 2: Déploiement Manuel

1. **Ouvrir l'éditeur SQL de Supabase**:
   - Allez dans votre projet Supabase
   - Ouvrez l'onglet "SQL Editor"

2. **Exécuter le script**:
   - Copiez le contenu de `correction_inscription_rls_secure.sql`
   - Collez-le dans l'éditeur SQL
   - Cliquez sur "Run"

## 🔍 Vérification de la Correction

### 1. Vérifier les Tables
```sql
-- Vérifier que les tables existent
SELECT table_name FROM information_schema.tables 
WHERE table_name IN ('subscription_status', 'system_settings');
```

### 2. Vérifier les Politiques RLS
```sql
-- Vérifier les politiques sur subscription_status
SELECT policyname, cmd, qual FROM pg_policies 
WHERE tablename = 'subscription_status';
```

### 3. Vérifier la Fonction RPC
```sql
-- Vérifier que la fonction existe
SELECT routine_name FROM information_schema.routines 
WHERE routine_name = 'create_user_default_data';
```

### 4. Tester l'Inscription
1. Allez sur votre application
2. Tentez de créer un nouveau compte
3. Vérifiez que l'inscription se termine sans erreur 500
4. Vérifiez que les données sont créées dans `subscription_status`

## 🛡️ Sécurité Maintenue

Cette solution **maintient RLS activé** et respecte les principes de sécurité :

- ✅ RLS reste activé sur toutes les tables
- ✅ Les utilisateurs ne peuvent accéder qu'à leurs propres données
- ✅ Le service role peut gérer les données lors de l'inscription
- ✅ Les politiques sont strictes et sécurisées
- ✅ Aucune désactivation de sécurité

## 🔄 Fonctionnement de la Solution

1. **Inscription Supabase Auth**: L'utilisateur s'inscrit via `supabase.auth.signUp()`
2. **Appel RPC**: Le frontend appelle `create_user_default_data(user_id)`
3. **Contexte Sécurisé**: La fonction RPC s'exécute avec `SECURITY DEFINER`
4. **Création des Données**: Les données par défaut sont créées dans les tables
5. **Politiques RLS**: Les politiques permettent l'accès via le service role

## 🚨 Points d'Attention

- **Service Role Key**: Assurez-vous que votre clé service role est correctement configurée
- **Permissions**: Vérifiez que les permissions sont accordées aux rôles `authenticated`, `anon`, et `service_role`
- **Tests**: Testez l'inscription avec différents types d'utilisateurs (admin, technician, etc.)

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs de la console du navigateur
2. Vérifiez les logs de Supabase
3. Exécutez les requêtes de vérification ci-dessus
4. Assurez-vous que toutes les étapes de déploiement ont été suivies

## ✅ Résultat Attendu

Après application de cette correction :
- ✅ L'inscription fonctionne sans erreur 500
- ✅ Les données par défaut sont créées automatiquement
- ✅ RLS reste activé et sécurisé
- ✅ Les utilisateurs peuvent accéder à l'application après confirmation email
