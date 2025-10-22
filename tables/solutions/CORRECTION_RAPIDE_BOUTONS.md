# 🔧 CORRECTION RAPIDE - BOUTONS DE SAUVEGARDE

## ⚡ PROBLÈME
Les boutons de sauvegarde ne fonctionnent pas car la table `system_settings` est vide.

## 🎯 SOLUTION RAPIDE (2 minutes)

### Étape 1 : Vérifier l'état actuel
1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet : `wlqyrmntfxwdvkzzsujv`
3. Ouvrez SQL Editor
4. Copiez-collez le contenu de `verifier_system_settings_simple.sql`
5. Cliquez sur "Run"

### Étape 2 : Créer et peupler la table
1. Créez un nouveau script SQL
2. Copiez-collez le contenu de `creer_system_settings.sql`
3. Cliquez sur "Run"

### Étape 3 : Vérification
Le script devrait afficher :
```
status                              | total_settings | general_settings | billing_settings | system_settings
------------------------------------|----------------|------------------|------------------|-----------------
SYSTEM_SETTINGS CRÉÉE ET PEUPLÉE    | 12            | 4                | 4                | 4
```

## ✅ RÉSULTAT ATTENDU

Après l'exécution :
- ✅ Table `system_settings` créée et peuplée
- ✅ Paramètres système chargés correctement
- ✅ Boutons de sauvegarde fonctionnels

## 🧪 TEST IMMÉDIAT

1. **Rechargez** la page Administration
2. **Vérifiez** que les champs sont maintenant remplis
3. **Modifiez** un paramètre
4. **Cliquez** sur "Sauvegarder"
5. **Vérifiez** que le message de succès s'affiche

## 📞 EN CAS D'ERREUR

Si vous avez une erreur de syntaxe :
- Utilisez `verifier_system_settings_simple.sql` au lieu de `verifier_system_settings.sql`
- Ce script évite les caractères spéciaux qui causent des erreurs

---

**⚠️ IMPORTANT :** Cette solution crée la table `system_settings` avec tous les paramètres nécessaires.
