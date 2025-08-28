# 🧪 Guide de Test - Numéros de Devis Uniques

## 🎯 Objectif

Vérifier que le système de génération de numéros de devis uniques fonctionne correctement et que chaque devis a un numéro différent.

## ✅ Prérequis

- ✅ Serveur de développement en cours d'exécution (`npm run dev`)
- ✅ Connexion Supabase active
- ✅ Au moins un client créé dans la base de données

## 🔍 Tests à effectuer

### **Test 1 : Création de plusieurs devis**

#### **Étapes :**
1. **Naviguer vers la page Devis**
   - Aller dans `Transaction` → `Devis`
   - Cliquer sur `+ Nouveau devis`

2. **Créer le premier devis**
   - Sélectionner un client existant
   - Ajouter quelques articles au devis
   - Cliquer sur `Créer le devis`
   - **Noter le numéro de devis affiché**

3. **Créer le deuxième devis**
   - Cliquer sur `+ Nouveau devis`
   - Sélectionner le même client ou un autre
   - Ajouter des articles différents
   - Cliquer sur `Créer le devis`
   - **Noter le numéro de devis affiché**

4. **Créer le troisième devis**
   - Répéter l'opération pour un troisième devis
   - **Noter le numéro de devis affiché**

#### **Vérifications :**
- ✅ Chaque devis a un numéro différent
- ✅ Le format est `DEV-01/12/2024-XXXX`
- ✅ Les numéros sont séquentiels par jour
- ✅ Les 4 derniers chiffres sont aléatoires

### **Test 2 : Vérification du format**

#### **Format attendu :**
```
DEV-JJ/MM/AAAA-XXXX
```

#### **Exemples valides :**
- `DEV-01/12/2024-1234`
- `DEV-01/12/2024-5678`
- `DEV-02/12/2024-0001`

#### **Vérifications :**
- ✅ Le préfixe est toujours `DEV-`
- ✅ La date est au format `JJ/MM/AAAA`
- ✅ Les 4 derniers chiffres sont entre 0000 et 9999
- ✅ Le format est cohérent pour tous les devis

### **Test 3 : Affichage dans la liste**

#### **Étapes :**
1. **Vérifier la liste des devis**
   - Dans la page Devis, vérifier la colonne "Numéro"
   - S'assurer que tous les devis affichent leur numéro

2. **Vérifier la recherche**
   - Utiliser la barre de recherche
   - Taper le numéro d'un devis
   - Vérifier que le devis apparaît dans les résultats

#### **Vérifications :**
- ✅ Tous les devis affichent leur numéro unique
- ✅ La recherche fonctionne avec les numéros
- ✅ L'affichage est formaté correctement

### **Test 4 : Affichage dans la vue détaillée**

#### **Étapes :**
1. **Ouvrir un devis**
   - Cliquer sur un devis dans la liste
   - Vérifier l'affichage du numéro dans l'en-tête

2. **Vérifier l'impression**
   - Cliquer sur le bouton "Imprimer"
   - Vérifier que le numéro apparaît sur la version imprimée

3. **Vérifier l'email**
   - Cliquer sur "Envoyer par email"
   - Vérifier que le numéro apparaît dans le sujet et le contenu

#### **Vérifications :**
- ✅ Le numéro apparaît dans l'en-tête du devis
- ✅ Le numéro apparaît sur la version imprimée
- ✅ Le numéro apparaît dans les emails

### **Test 5 : Conversion vers réparation**

#### **Étapes :**
1. **Accepter un devis**
   - Ouvrir un devis
   - Cliquer sur "Accepter"
   - Confirmer la conversion

2. **Vérifier la réparation créée**
   - Aller dans "Suivi des réparations"
   - Chercher la réparation créée
   - Vérifier que les notes contiennent le numéro de devis

#### **Vérifications :**
- ✅ La réparation est créée avec succès
- ✅ Les notes mentionnent le numéro de devis accepté
- ✅ Le format du numéro est préservé

## 🔍 Indicateurs de succès

### **Console du navigateur :**
```
✅ Connexion Supabase réussie
✅ Devis créé avec succès
✅ Numéros de devis uniques générés
```

### **Interface utilisateur :**
- ✅ Numéros de devis différents pour chaque devis
- ✅ Format cohérent : `DEV-JJ/MM/AAAA-XXXX`
- ✅ Affichage correct dans toutes les vues
- ✅ Recherche fonctionnelle

### **Fonctionnalités :**
- ✅ Création de devis avec numéros uniques
- ✅ Affichage formaté dans les listes
- ✅ Affichage dans les vues détaillées
- ✅ Intégration dans les emails
- ✅ Intégration dans les impressions
- ✅ Conversion vers réparation préservée

## 🚨 Cas d'échec possibles

### **Si les numéros sont identiques :**
1. **Vérifier la fonction de génération**
   - Ouvrir la console du navigateur
   - Tester `generateQuoteNumber()` plusieurs fois
   - Vérifier que les résultats sont différents

2. **Vérifier l'import des utilitaires**
   - S'assurer que `quoteUtils.ts` est correctement importé
   - Vérifier qu'il n'y a pas d'erreurs de compilation

### **Si le format est incorrect :**
1. **Vérifier la fonction de formatage**
   - Tester `formatQuoteNumber()` avec différents numéros
   - Vérifier que le format est correct

2. **Vérifier l'affichage**
   - S'assurer que `formatQuoteNumber()` est utilisé partout
   - Vérifier qu'il n'y a pas d'affichage direct de `quoteNumber`

### **Si la recherche ne fonctionne pas :**
1. **Vérifier la logique de recherche**
   - S'assurer que `quote.quoteNumber` est utilisé dans le filtre
   - Vérifier que la recherche est insensible à la casse

## 📋 Checklist de validation

### **Génération :**
- [ ] Chaque devis a un numéro unique
- [ ] Le format est `DEV-JJ/MM/AAAA-XXXX`
- [ ] Les numéros sont générés automatiquement
- [ ] Pas d'erreurs dans la console

### **Affichage :**
- [ ] Numéros affichés dans la liste des devis
- [ ] Numéros affichés dans la vue détaillée
- [ ] Numéros affichés dans les impressions
- [ ] Numéros affichés dans les emails

### **Fonctionnalités :**
- [ ] Recherche par numéro de devis
- [ ] Conversion vers réparation préservée
- [ ] Persistance des numéros
- [ ] Pas de régression des fonctionnalités existantes

## ✅ Conclusion

Si tous les tests passent avec succès, le système de numéros de devis uniques est **validé** et fonctionne correctement.

### **Prochaines étapes :**
1. **Tester en production** si nécessaire
2. **Documenter les bonnes pratiques** pour l'utilisation
3. **Implémenter des tests automatisés** pour prévenir les régressions
4. **Considérer une migration** pour les devis existants
