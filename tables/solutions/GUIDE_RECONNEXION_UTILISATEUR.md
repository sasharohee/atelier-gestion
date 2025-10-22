# 🔧 GUIDE DE RECONNEXION - ERREUR "Invalid login credentials"

## 🚨 **Problème identifié**
L'erreur "Invalid login credentials" indique que l'utilisateur `sasha4@yopmail.com` ne peut plus se connecter après le nettoyage des sessions.

## 🛠️ **Solutions à appliquer**

### **ÉTAPE 1 : Correction côté serveur (OBLIGATOIRE)**
**Exécutez le script `DIAGNOSTIC_ET_CORRECTION_LOGIN.sql`** dans l'éditeur SQL de Supabase.

Ce script va :
- ✅ Diagnostiquer l'état de l'utilisateur
- ✅ Corriger les problèmes d'authentification
- ✅ Réinitialiser l'utilisateur si nécessaire
- ✅ S'assurer qu'il est dans `subscription_status`

### **ÉTAPE 2 : Solutions pour l'utilisateur**

#### **Option A : Réinitialisation du mot de passe (RECOMMANDÉE)**
1. Sur la page de connexion, cliquez sur **"Mot de passe oublié ?"**
2. Entrez l'email : `sasha4@yopmail.com`
3. Vérifiez votre boîte email (yopmail.com)
4. Cliquez sur le lien de réinitialisation
5. Créez un nouveau mot de passe
6. Connectez-vous avec le nouveau mot de passe

#### **Option B : Création d'un nouveau compte**
1. Créez un nouveau compte avec l'email `sasha4@yopmail.com`
2. L'ancien compte sera automatiquement remplacé
3. L'utilisateur sera ajouté à `subscription_status`

#### **Option C : Connexion directe (si le mot de passe est connu)**
1. Essayez de vous connecter avec :
   - **Email** : `sasha4@yopmail.com`
   - **Mot de passe** : Le mot de passe original
2. Si cela ne fonctionne pas, utilisez l'Option A

### **ÉTAPE 3 : Nettoyage côté client (si nécessaire)**

Si l'utilisateur a encore des problèmes :

#### **Nettoyage complet du navigateur**
1. Ouvrez les **Outils de développement** (F12)
2. Allez dans **Application** → **Local Storage**
3. Supprimez toutes les clés contenant "supabase"
4. Faites de même pour **Session Storage**
5. **Rafraîchir la page** (Ctrl+F5)

#### **Mode incognito**
1. Ouvrez un **nouvel onglet en mode incognito**
2. Naviguez vers votre application
3. Testez la connexion

## 🧪 **Test après correction**

1. **Exécutez le script SQL** `DIAGNOSTIC_ET_CORRECTION_LOGIN.sql`
2. **Testez la reconnexion** avec l'une des options ci-dessus
3. **Vérifiez** que l'utilisateur apparaît dans `subscription_status`
4. **Vérifiez** que l'application fonctionne correctement

## 🔍 **Diagnostic supplémentaire**

Si le problème persiste, vérifiez dans la console du navigateur :
- Les erreurs de réseau (onglet Network)
- Les erreurs d'authentification
- Les cookies et tokens (onglet Application)

## 📋 **Ordre d'exécution**

1. ✅ **Script SQL** : `DIAGNOSTIC_ET_CORRECTION_LOGIN.sql`
2. ✅ **Test reconnexion** : Option A, B ou C
3. ✅ **Nettoyage cache** : Si nécessaire
4. ✅ **Vérification** : L'utilisateur doit pouvoir se connecter

## 🎯 **Résultat attendu**

Après ces corrections :
- ✅ Plus d'erreurs "Invalid login credentials"
- ✅ L'utilisateur peut se connecter normalement
- ✅ L'utilisateur apparaît dans `subscription_status`
- ✅ L'application fonctionne correctement

## 🆘 **En cas de problème persistant**

Si l'utilisateur ne peut toujours pas se connecter :
1. **Vérifiez** que l'email est correct : `sasha4@yopmail.com`
2. **Essayez** de créer un nouveau compte avec un email différent
3. **Contactez** l'administrateur pour vérifier les paramètres Supabase

## 📞 **Support**

Si vous avez besoin d'aide supplémentaire :
- Vérifiez les logs de la console du navigateur
- Vérifiez les logs de Supabase dans le dashboard
- Contactez l'équipe de développement
