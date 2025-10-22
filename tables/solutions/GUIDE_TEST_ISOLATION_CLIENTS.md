# 🧪 GUIDE DE TEST - ISOLATION DES CLIENTS

## 🎯 OBJECTIF
Tester que l'isolation des clients fonctionne correctement après la correction radicale.

## 📋 ÉTAPES DE TEST

### 1. EXÉCUTION DE LA CORRECTION RADICALE

**Fichier à utiliser :** `correction_isolation_clients_radical.sql`

**Actions du script :**
- ✅ Supprime tous les clients existants
- ✅ Recrée complètement la table clients
- ✅ Applique des politiques RLS ultra strictes
- ✅ Teste l'isolation automatiquement

**Exécution :**
```sql
-- Dans l'interface SQL de Supabase
-- Copier et exécuter le contenu de correction_isolation_clients_radical.sql
```

### 2. TEST MANUEL AVEC COMPTE A

1. **Connectez-vous avec le compte A**
2. **Allez dans Catalogue > Clients**
3. **Créez un nouveau client** avec les informations suivantes :
   - Prénom : `Test A`
   - Nom : `Utilisateur`
   - Email : `test.a@example.com`
   - Téléphone : `0123456789`
4. **Vérifiez que le client apparaît** dans la liste
5. **Notez le nombre de clients** affichés

### 3. TEST MANUEL AVEC COMPTE B

1. **Déconnectez-vous du compte A**
2. **Connectez-vous avec le compte B**
3. **Allez dans Catalogue > Clients**
4. **Vérifiez que :**
   - ✅ Le client du compte A n'est PAS visible
   - ✅ La liste est vide (0 clients)
5. **Créez un nouveau client** avec les informations suivantes :
   - Prénom : `Test B`
   - Nom : `Utilisateur`
   - Email : `test.b@example.com`
   - Téléphone : `0987654321`
6. **Vérifiez que seul ce client apparaît**

### 4. TEST DE RETOUR AU COMPTE A

1. **Déconnectez-vous du compte B**
2. **Connectez-vous avec le compte A**
3. **Allez dans Catalogue > Clients**
4. **Vérifiez que :**
   - ✅ Seul le client du compte A est visible
   - ✅ Le client du compte B n'est PAS visible
   - ✅ Le nombre de clients est correct (1 client)

## ✅ RÉSULTATS ATTENDUS

### Compte A :
- ✅ Peut voir ses propres clients
- ✅ Ne peut PAS voir les clients du compte B
- ✅ Peut créer, modifier, supprimer ses clients

### Compte B :
- ✅ Peut voir ses propres clients
- ✅ Ne peut PAS voir les clients du compte A
- ✅ Peut créer, modifier, supprimer ses clients

### Isolation parfaite :
- ✅ Chaque utilisateur ne voit que ses propres données
- ✅ Aucun accès croisé entre comptes
- ✅ Politiques RLS strictement respectées

## 🚨 SIGNAUX D'ALERTE

### Si l'isolation ne fonctionne toujours pas :

1. **Vérifiez que vous êtes bien connecté** avec le bon compte
2. **Vérifiez les logs** du script de correction radicale
3. **Exécutez le diagnostic** pour identifier les problèmes restants
4. **Vérifiez les politiques RLS** dans Supabase

### Si des clients sont visibles entre comptes :

1. **Vérifiez que RLS est activé** sur la table clients
2. **Vérifiez que les politiques RADICAL_ISOLATION** sont présentes
3. **Vérifiez que tous les clients** ont un user_id valide
4. **Contactez l'administrateur** si nécessaire

## 🔧 DÉPANNAGE

### Problème : Les clients sont encore visibles entre comptes

**Solution :**
1. Exécutez à nouveau le script de correction radicale
2. Vérifiez que vous êtes connecté lors de l'exécution
3. Vérifiez les logs pour identifier les erreurs

### Problème : Impossible de créer des clients

**Solution :**
1. Vérifiez que l'utilisateur est connecté
2. Vérifiez les permissions sur la table clients
3. Vérifiez que les politiques RLS permettent l'insertion

### Problème : Erreur lors de l'exécution du script

**Solution :**
1. Vérifiez que vous avez les permissions nécessaires
2. Vérifiez que vous êtes connecté
3. Exécutez le script section par section si nécessaire

## 📊 VÉRIFICATION FINALE

Après avoir effectué tous les tests, vérifiez que :

1. **Compte A** : Voit uniquement ses propres clients
2. **Compte B** : Voit uniquement ses propres clients
3. **Aucun accès croisé** entre les comptes
4. **Création fonctionne** pour les deux comptes
5. **Modification fonctionne** pour les deux comptes
6. **Suppression fonctionne** pour les deux comptes

## 🎉 SUCCÈS

Si tous les tests sont réussis, l'isolation des clients fonctionne parfaitement !

---

**💡 CONSEIL** : Effectuez ces tests régulièrement pour vous assurer que l'isolation reste fonctionnelle.
