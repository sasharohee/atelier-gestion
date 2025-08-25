# Correction Rapide - Erreur de Contrainte Unique

## 🚨 Problème Identifié
L'erreur `ERROR: 42P10: there is no unique or exclusion constraint matching the ON CONFLICT specification` indique que nous essayons d'utiliser `ON CONFLICT (user_email)` mais il n'y a pas de contrainte unique sur cette colonne.

## 🔧 Solution Immédiate

### Étape 1: Exécuter la Correction
1. Ouvrez votre dashboard Supabase
2. Allez dans l'éditeur SQL
3. **EXÉCUTEZ** le script `tables/correction_contrainte_unique_email.sql`
4. Ce script corrige la contrainte unique manquante

### Étape 2: Vérifier la Correction
Après l'exécution, vérifiez que :
- ✅ La table `confirmation_emails` est recréée avec la bonne contrainte
- ✅ Les fonctions sont recréées correctement
- ✅ Les tests passent sans erreur

## 🛠️ Ce qui a été Corrigé

### Problème
- La colonne `user_email` n'avait pas de contrainte `UNIQUE`
- La fonction `generate_confirmation_token` utilisait `ON CONFLICT (user_email)` sans contrainte

### Solution
- Ajout de `UNIQUE` à la colonne `user_email`
- Recréation de la table avec la bonne structure
- Recréation de toutes les fonctions

## 📋 Vérifications Post-Correction

### 1. Vérifier la Structure de la Table
```sql
-- Vérifier que la contrainte unique existe
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints 
WHERE table_name = 'confirmation_emails' 
AND constraint_type = 'UNIQUE';
```

### 2. Tester la Génération de Token
```sql
-- Tester la fonction
SELECT generate_confirmation_token('test@example.com');
```

### 3. Vérifier les Logs
Dans la console du navigateur, vérifiez :
- ✅ Aucune erreur de contrainte unique
- ✅ Token généré avec succès
- ✅ URL de confirmation créée

## 🎯 Résultat Attendu

Après application de cette correction :
- ✅ Aucune erreur de contrainte unique
- ✅ Génération de tokens fonctionnelle
- ✅ Système d'emails de confirmation opérationnel
- ✅ Processus d'inscription complet fonctionnel

## ⚠️ Notes Importantes

### Impact
- La table `confirmation_emails` est recréée (les données existantes sont perdues)
- Toutes les fonctions sont recréées
- Les permissions sont reconfigurées

### Sécurité
- La contrainte unique empêche les doublons d'email
- Chaque email ne peut avoir qu'un seul token actif
- Les tokens sont toujours uniques

---

**CORRECTION** : Cette correction résout immédiatement l'erreur de contrainte unique et permet au système d'emails de confirmation de fonctionner correctement.
