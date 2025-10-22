# 🔧 Guide de Correction - Erreurs Page Quote Requests

## 📋 Problème Identifié

La page Quote Requests génère des erreurs 404 car les tables et fonctions nécessaires n'existent pas dans votre base de données Supabase :

1. **Fonction `get_quote_request_stats` manquante** (erreur PGRST202)
2. **Table `technician_custom_urls` manquante** (erreur PGRST205)
3. **Table `quote_requests` manquante**
4. **Table `user_profiles` manquante**

## ✅ Solutions Appliquées

### 1. Service Corrigé
- ✅ Création d'un service avec gestion d'erreurs robuste (`quoteRequestServiceFixed.ts`)
- ✅ Ajout de méthodes de fallback pour les statistiques
- ✅ Gestion gracieuse des tables manquantes
- ✅ Amélioration du service original (`quoteRequestServiceReal.ts`)

### 2. Script SQL Complet
- ✅ Création du fichier `quote_requests_setup.sql` avec toutes les tables et fonctions nécessaires

## 🚀 Étapes de Correction

### Étape 1: Diagnostic (Optionnel)

Si vous voulez d'abord voir l'état actuel de votre base de données :

1. **Connectez-vous à votre dashboard Supabase** : https://supabase.com/dashboard
2. **Sélectionnez votre projet**
3. **Allez dans l'éditeur SQL** (SQL Editor dans le menu de gauche)
4. **Exécutez le script `diagnose_quote_requests_tables.sql`** pour voir l'état actuel

### Étape 2: Correction de la Structure

1. **Dans l'éditeur SQL de Supabase**
2. **Copiez et collez le contenu du fichier `fix_quote_requests_structure.sql`**
3. **Exécutez le script** en cliquant sur "Run"

> ⚠️ **Attention** : Ce script supprime et recrée les tables `quote_requests` et `quote_request_attachments` pour corriger la structure. Toutes les données existantes dans ces tables seront perdues.

### Étape 3: Vérifier la Création des Tables

Après l'exécution du script, vous devriez avoir ces nouvelles tables :
- `user_profiles`
- `technician_custom_urls`
- `quote_requests`
- `quote_request_attachments`

Et ces nouvelles fonctions :
- `generate_quote_request_number()`
- `get_quote_request_stats(technician_uuid)`

### Étape 4: Tester la Page

1. **Redémarrez votre application** si nécessaire
2. **Naviguez vers la page Quote Requests**
3. **Les erreurs 404 devraient être résolues**

## 🔍 Vérification des Corrections

### Console du Navigateur
Vous ne devriez plus voir ces erreurs :
```
POST https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/rpc/get_quote_request_stats 404 (Not Found)
GET https://wlqyrmntfxwdvkzzsujv.supabase.co/rest/v1/technician_custom_urls 404 (Not Found)
```

### Fonctionnalités Disponibles
Une fois corrigé, la page Quote Requests permettra :
- ✅ Gérer les demandes de devis
- ✅ Afficher les statistiques
- ✅ Créer et gérer les URLs personnalisées
- ✅ Suivre l'état des demandes

## 🛠️ Améliorations Apportées

### Gestion d'Erreurs Robuste
- **Fallback automatique** : Si une fonction RPC échoue, le service calcule les statistiques manuellement
- **Messages d'erreur informatifs** : Indication claire si les tables manquent
- **Valeurs par défaut** : Retour de données vides plutôt que des erreurs

### Performance
- **Index optimisés** pour les requêtes fréquentes
- **Triggers automatiques** pour la mise à jour des timestamps
- **Requêtes optimisées** avec sélection de colonnes spécifiques

### Sécurité
- **Row Level Security (RLS)** activé sur toutes les tables
- **Politiques de sécurité** pour l'isolation des données
- **Validation des données** avec des contraintes CHECK

## 📊 Structure des Données

### Table `quote_requests`
```sql
- id (UUID, Primary Key)
- request_number (TEXT, Unique)
- technician_id (UUID, Foreign Key)
- client_* (informations client)
- device_* (informations appareil)
- status, urgency, priority
- created_at, updated_at
```

### Table `technician_custom_urls`
```sql
- id (UUID, Primary Key)
- technician_id (UUID, Foreign Key)
- custom_url (TEXT, Unique)
- is_active (BOOLEAN)
- created_at, updated_at
```

### Fonction `get_quote_request_stats`
```sql
Retourne un JSON avec :
- total, pending, inReview, quoted, accepted, rejected
- byUrgency (low, medium, high)
- byStatus (tous les statuts)
- monthly, weekly, daily
```

## 🔧 En Cas de Problème

### Erreur "column does not exist"
Si vous obtenez l'erreur `column "request_number" named in key does not exist` :
1. Cela signifie que la table `quote_requests` existe déjà avec une structure différente
2. Utilisez le script `fix_quote_requests_structure.sql` qui supprime et recrée les tables problématiques
3. Ou utilisez le script `cleanup_quote_requests.sql` pour tout nettoyer avant de recommencer

### Erreur "there is no unique constraint"
Si vous obtenez l'erreur `there is no unique constraint matching given keys` :
1. La table `quote_requests` n'a pas la contrainte unique nécessaire
2. Utilisez le script `fix_quote_requests_structure.sql` qui gère cette situation

### Erreur de Permissions
Si vous avez des erreurs de permissions :
1. Vérifiez que vous êtes connecté avec un compte administrateur Supabase
2. Assurez-vous que votre projet a les bonnes permissions

### Tables Déjà Existantes avec Structure Incorrecte
Si certaines tables existent déjà avec une mauvaise structure :
1. Utilisez le script `fix_quote_requests_structure.sql` qui supprime et recrée les tables problématiques
2. Ce script préserve les tables `user_profiles` et `technician_custom_urls` si elles ont la bonne structure

### Rollback Complet
Si vous voulez tout annuler et repartir de zéro :
1. Utilisez le script `cleanup_quote_requests.sql`
2. Puis relancez le script `fix_quote_requests_structure.sql`

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs de la console du navigateur
2. Vérifiez les logs de Supabase dans le dashboard
3. Assurez-vous que le script SQL s'est exécuté sans erreur

---

**Note** : Ce guide résout définitivement les erreurs 404 de la page Quote Requests en créant l'infrastructure de base de données nécessaire.
