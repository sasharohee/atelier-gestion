# 🔧 CORRECTION FINALE - SYSTEM_SETTINGS

## 🚨 ERREUR IDENTIFIÉE
```
ERROR: 42883: function min(uuid) does not exist
```

## 🎯 CAUSE DU PROBLÈME
La fonction `MIN()` ne fonctionne pas avec les UUID dans PostgreSQL.

## ⚡ SOLUTION FINALE

### Étape 1 : Exécuter le script simple
1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet : `wlqyrmntfxwdvkzzsujv`
3. Ouvrez SQL Editor
4. Copiez-collez le contenu de `solution_simple_system_settings.sql`
5. Cliquez sur "Run"

### Étape 2 : Vérification
Le script devrait afficher :
```
status              | total_settings
--------------------|----------------
Correction terminée | 12
```

## ✅ RÉSULTATS ATTENDUS

Après l'exécution :
- ✅ Toutes les contraintes problématiques supprimées
- ✅ Table nettoyée avec `TRUNCATE`
- ✅ Colonne `user_id` ajoutée
- ✅ Politiques RLS configurées pour l'isolation
- ✅ 12 paramètres par défaut créés
- ✅ Contrainte unique sur `(user_id, key)` ajoutée
- ✅ Boutons de sauvegarde fonctionnels

## 🔧 CE QUE FAIT LE SCRIPT

1. **Supprime toutes les contraintes** existantes
2. **Nettoie la table** avec `TRUNCATE` (plus simple que `DELETE`)
3. **Ajoute la colonne `user_id`** si elle n'existe pas
4. **Crée l'index** sur `user_id`
5. **Configure les politiques RLS** pour l'isolation
6. **Insère les 12 paramètres** par défaut
7. **Ajoute la contrainte unique** sur `(user_id, key)`

## 🧪 TEST APRÈS CORRECTION

1. **Rechargez** la page Administration
2. **Vérifiez** que les champs sont remplis avec les valeurs par défaut
3. **Modifiez** un paramètre (ex: nom de l'atelier)
4. **Cliquez** sur "Sauvegarder"
5. **Vérifiez** que le message de succès s'affiche
6. **Rechargez** la page pour confirmer que la modification est persistante

## 📊 PARAMÈTRES CRÉÉS

Le script crée 12 paramètres par défaut :

**Généraux (4) :**
- `workshop_name` : Nom de l'atelier
- `workshop_address` : Adresse
- `workshop_phone` : Téléphone
- `workshop_email` : Email

**Facturation (4) :**
- `vat_rate` : Taux de TVA
- `currency` : Devise
- `invoice_prefix` : Préfixe facture
- `date_format` : Format de date

**Système (4) :**
- `auto_backup` : Sauvegarde automatique
- `notifications` : Notifications
- `backup_frequency` : Fréquence de sauvegarde
- `max_file_size` : Taille max des fichiers

## 🔒 ISOLATION DES DONNÉES

Après cette correction :
- ✅ Chaque utilisateur ne voit que ses propres paramètres
- ✅ Les données sont isolées par `user_id`
- ✅ Les politiques RLS empêchent l'accès aux données d'autres utilisateurs

## 📞 EN CAS DE PROBLÈME

Si le script ne fonctionne pas :
1. Vérifiez que vous êtes bien connecté à Supabase
2. Assurez-vous d'avoir copié tout le script
3. Vérifiez qu'il n'y a pas d'erreur dans l'interface SQL
4. Attendez 30 secondes et rechargez la page

---

**⚠️ IMPORTANT :** Cette solution corrige définitivement le problème et configure l'isolation des données par utilisateur.
