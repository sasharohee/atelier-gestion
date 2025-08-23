# 🔧 GUIDE FIX BOUTONS DE SAUVEGARDE

## 🚨 PROBLÈME
Les boutons de sauvegarde ne fonctionnent pas.

## ⚡ SOLUTION RAPIDE

### Étape 1 : Corriger les politiques RLS
1. Allez sur https://supabase.com/dashboard
2. Sélectionnez votre projet : `wlqyrmntfxwdvkzzsujv`
3. Ouvrez SQL Editor
4. Copiez-collez le contenu de `fix_politiques_rls.sql`
5. Cliquez sur "Run"

### Étape 2 : Créer les paramètres
1. Créez un nouveau script SQL
2. Copiez-collez le contenu de `fix_boutons_sauvegarde.sql`
3. Cliquez sur "Run"

### Étape 3 : Vérification
Le script devrait afficher :
```
status        | total_settings
--------------|----------------
Fix terminé   | 12
```

## ✅ RÉSULTAT ATTENDU

Après l'exécution :
- ✅ Les politiques RLS sont corrigées
- ✅ L'utilisateur a ses paramètres
- ✅ Les boutons de sauvegarde fonctionnent

## 🧪 TEST

1. **Rechargez** la page Administration
2. **Vérifiez** que les champs sont remplis
3. **Modifiez** un paramètre
4. **Cliquez** sur "Sauvegarder"
5. **Vérifiez** que le message de succès s'affiche

## 📞 EN CAS DE PROBLÈME

Si ça ne fonctionne pas :
1. Vérifiez que les scripts se sont bien exécutés
2. Attendez 30 secondes et rechargez la page
3. Vérifiez les logs de la console

---

**⚠️ IMPORTANT :** Exécutez les deux scripts dans l'ordre pour corriger le problème.
