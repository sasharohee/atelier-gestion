# 🔧 CORRECTION ERREUR DOUBLONS - SYSTEM_SETTINGS

## 🚨 ERREUR IDENTIFIÉE
```
ERROR: 23505: duplicate key value violates unique constraint "system_settings_key_key"
DETAIL: Key (key)=(vat_rate) already exists.
```

## 🎯 CAUSE DU PROBLÈME
La table `system_settings` a une contrainte unique sur la colonne `key`, mais nous voulons une contrainte unique sur `(user_id, key)` pour permettre l'isolation par utilisateur.

## ⚡ SOLUTION RAPIDE

### Étape 1 : Nettoyer et corriger
1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet : `wlqyrmntfxwdvkzzsujv`
3. Ouvrez SQL Editor
4. Copiez-collez le contenu de `nettoyer_et_corriger_system_settings.sql`
5. Cliquez sur "Run"

### Étape 2 : Vérification
Le script devrait afficher :
```
status              | total_settings | general_settings | billing_settings | system_settings
--------------------|----------------|------------------|------------------|-----------------
Nettoyage terminé   | 12            | 4                | 4                | 4
```

## ✅ RÉSULTATS ATTENDUS

Après l'exécution :
- ✅ Contrainte unique sur `key` supprimée
- ✅ Contrainte unique sur `(user_id, key)` ajoutée
- ✅ Données nettoyées et recréées
- ✅ Isolation par utilisateur fonctionnelle
- ✅ Boutons de sauvegarde opérationnels

## 🔧 CE QUE FAIT LE SCRIPT

1. **Supprime la contrainte unique** sur `key`
2. **Nettoie toutes les données** existantes
3. **Ajoute la colonne `user_id`** si elle n'existe pas
4. **Crée l'index** sur `user_id`
5. **Met à jour les politiques RLS** pour l'isolation
6. **Insère les paramètres par défaut** pour l'utilisateur actuel
7. **Ajoute la contrainte unique** sur `(user_id, key)`

## 🧪 TEST APRÈS CORRECTION

1. **Rechargez** la page Administration
2. **Vérifiez** que les champs sont remplis
3. **Modifiez** un paramètre
4. **Cliquez** sur "Sauvegarder"
5. **Vérifiez** que le message de succès s'affiche

## 📞 EN CAS DE PROBLÈME

Si l'erreur persiste :
1. Vérifiez que le script s'est bien exécuté
2. Attendez 30 secondes et rechargez la page
3. Vérifiez les logs de la console
4. Testez avec un paramètre simple d'abord

---

**⚠️ IMPORTANT :** Ce script nettoie complètement la table et la recrée avec la bonne structure. Les données existantes seront perdues mais remplacées par les paramètres par défaut.
