# Guide : Administrateurs comme Techniciens pour les Réparations

## 🎯 Objectif

Permettre aux utilisateurs ayant le rôle `admin` d'apparaître également comme techniciens dans les listes de réparations, tout en conservant leurs droits d'administration.

## 🔧 Modifications apportées

### 1. Frontend - Fonctions utilitaires centralisées

**Fichier :** `src/utils/userUtils.ts`

Nouvelles fonctions créées :
- `getRepairEligibleUsers()` : Filtre les utilisateurs éligibles pour les réparations
- `isRepairEligible()` : Vérifie si un utilisateur peut être assigné à des réparations
- `getRepairUserDisplayName()` : Génère le nom d'affichage avec le rôle si nécessaire

```typescript
// Les administrateurs et managers apparaissent avec leur rôle
// Exemple : "Jean Dupont (admin)" ou "Marie Martin (manager)"
// Les techniciens apparaissent sans rôle
// Exemple : "Pierre Durand"
```

### 2. Frontend - Composants mis à jour

**Fichiers modifiés :**
- `src/pages/Kanban/Kanban.tsx`
- `src/pages/Calendar/Calendar.tsx`

**Changements :**
- Utilisation des fonctions utilitaires pour le filtrage
- Affichage cohérent des noms d'utilisateurs
- Les administrateurs apparaissent dans les listes de techniciens

### 3. Backend - Fonctions SQL

**Fichier :** `tables/update_admin_as_technician_for_repairs.sql`

**Nouvelles fonctions créées :**
- `can_be_assigned_to_repairs()` : Vérifie l'éligibilité pour les réparations
- `get_repair_eligible_users()` : Retourne tous les utilisateurs éligibles
- `get_repair_technicians()` : Fonction RPC pour l'API

**Politiques RLS mises à jour :**
- `repairs_insert_policy` : Permet aux admins/techniciens/managers de créer des réparations
- `repairs_update_policy` : Permet aux admins/techniciens/managers de modifier des réparations
- `clients_insert_policy` : Permet aux admins/techniciens/managers de créer des clients
- `devices_insert_policy` : Permet aux admins/techniciens/managers de créer des appareils

## 🚀 Application des modifications

### Étape 1 : Appliquer le script SQL
1. Aller dans le dashboard Supabase
2. Ouvrir l'éditeur SQL
3. Exécuter le script `tables/update_admin_as_technician_for_repairs.sql`

### Étape 2 : Vérifier les modifications
Après l'exécution, vous devriez voir :
- Les nouvelles fonctions créées
- Les politiques RLS mises à jour
- Les tests des fonctions avec les résultats

### Étape 3 : Tester l'application
1. Se connecter avec un compte administrateur
2. Aller dans la page Kanban (réparations)
3. Créer une nouvelle réparation
4. Vérifier que l'administrateur apparaît dans la liste des techniciens

## ✅ Vérifications

### Frontend
- [ ] Les administrateurs apparaissent dans les listes de techniciens
- [ ] Les noms d'affichage incluent le rôle pour les admins/managers
- [ ] Les techniciens apparaissent sans rôle dans l'affichage
- [ ] La cohérence est maintenue dans Kanban et Calendar

### Backend
- [ ] Les fonctions SQL sont créées et fonctionnelles
- [ ] Les politiques RLS permettent l'accès aux administrateurs
- [ ] La fonction RPC retourne les bons utilisateurs
- [ ] Les performances des techniciens incluent les administrateurs

## 🔍 Dépannage

### Problème : Les administrateurs n'apparaissent pas dans les listes
**Solution :**
1. Vérifier que le script SQL a été exécuté
2. Vérifier que l'utilisateur a bien le rôle `admin` dans les métadonnées
3. Vérifier les logs de la console pour les erreurs

### Problème : Erreur de permission lors de la création de réparations
**Solution :**
1. Vérifier que les politiques RLS sont en place
2. Vérifier que la fonction `can_be_assigned_to_repairs()` fonctionne
3. Vérifier que l'utilisateur est bien authentifié

### Problème : Affichage incohérent des noms
**Solution :**
1. Vérifier que les fonctions utilitaires sont importées
2. Vérifier que `getRepairUserDisplayName()` est utilisée partout
3. Vérifier que les rôles sont correctement définis

## 📝 Comportement attendu

### Pour les Techniciens
- **Affichage :** "Prénom Nom"
- **Permissions :** Accès complet aux réparations
- **Statistiques :** Incluses dans les performances

### Pour les Administrateurs
- **Affichage :** "Prénom Nom (admin)"
- **Permissions :** Accès complet aux réparations + administration
- **Statistiques :** Incluses dans les performances

### Pour les Managers
- **Affichage :** "Prénom Nom (manager)"
- **Permissions :** Accès complet aux réparations + gestion
- **Statistiques :** Incluses dans les performances

## 🎯 Résultat final

Après l'application de ces modifications :
- ✅ Les administrateurs apparaissent comme techniciens dans les réparations
- ✅ Les noms d'affichage sont cohérents et informatifs
- ✅ Les permissions sont correctement appliquées
- ✅ Les statistiques incluent tous les utilisateurs éligibles
- ✅ La logique est centralisée et maintenable
- ✅ L'interface utilisateur est intuitive

## 🔄 Évolutivité

La solution est conçue pour être facilement extensible :
- Ajouter de nouveaux rôles éligibles : modifier les fonctions de filtrage
- Changer l'affichage des noms : modifier `getRepairUserDisplayName()`
- Ajouter de nouvelles permissions : étendre les politiques RLS
