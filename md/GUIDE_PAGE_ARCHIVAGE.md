# 📁 Guide de la Page d'Archivage des Réparations

## 🎯 Objectif

La page d'archivage permet de gérer les réparations terminées et restituées aux clients, évitant ainsi l'encombrement du tableau Kanban principal.

## 🚀 Fonctionnalités

### ✅ Archivage Automatique
- **Déplacement vers "Restitué"** : Quand une réparation est déplacée vers la colonne "Restitué" dans le Kanban, elle est automatiquement archivée
- **Notification** : Une alerte confirme l'archivage et indique où trouver la réparation
- **Statut préservé** : Les réparations gardent leur statut "returned" dans les archives

### 🔍 Recherche et Filtrage
- **Recherche textuelle** : Recherche dans le nom du client, email, marque/modèle d'appareil, description
- **Filtre par type d'appareil** : Smartphone, tablette, ordinateur portable, fixe, autre
- **Filtre par période** : 30 jours, 90 jours, 1 an, toutes les dates
- **Filtre par paiement** : Payées uniquement ou toutes les réparations

### 📊 Affichage Optimisé
- **Tableau paginé** : 10 réparations par page pour de meilleures performances
- **Informations complètes** : Client, appareil, description, date, prix, statut de paiement
- **Actions rapides** : Voir facture, restaurer, supprimer définitivement

## 🛠️ Utilisation

### 1. Accès à la Page d'Archivage

#### Via le Menu Principal
1. Cliquez sur **"Archives"** dans le menu de navigation
2. La page s'ouvre avec toutes les réparations restituées

#### Via le Kanban
1. Dans le tableau Kanban, cliquez sur **"Voir les archives"** en haut à droite
2. Accès direct aux réparations archivées

### 2. Archivage d'une Réparation

#### Méthode 1 : Drag & Drop dans le Kanban
1. Dans le tableau Kanban, trouvez la réparation à archiver
2. Glissez-déposez la carte vers la colonne **"Restitué"**
3. Une notification confirme l'archivage automatique
4. La réparation disparaît du Kanban et apparaît dans les archives

#### Méthode 2 : Changement de Statut Manuel
1. Cliquez sur une réparation dans le Kanban
2. Changez le statut vers **"Restitué"**
3. Sauvegardez les modifications
4. La réparation est automatiquement archivée

### 3. Recherche dans les Archives

#### Recherche Textuelle
- Tapez dans le champ **"Rechercher..."**
- La recherche s'effectue en temps réel
- Recherche dans : nom client, email, marque/modèle, description, problème

#### Filtres Avancés
- **Type d'appareil** : Sélectionnez un type spécifique ou "Tous les types"
- **Période** : Limitez aux 30/90 derniers jours ou 1 an
- **Paiement** : Cochez "Payées uniquement" pour filtrer

### 4. Actions sur les Réparations Archivées

#### Voir la Facture
1. Cliquez sur l'icône **📄** (facture) dans la colonne Actions
2. La facture s'ouvre dans une modale
3. Possibilité d'imprimer ou d'envoyer par email

#### Restaurer une Réparation
1. Cliquez sur l'icône **🔄** (restaurer) dans la colonne Actions
2. La réparation repasse en statut "Terminée"
3. Elle réapparaît dans le Kanban pour modification si nécessaire

#### Supprimer Définitivement
1. Cliquez sur l'icône **🗑️** (supprimer) dans la colonne Actions
2. Confirmez la suppression dans la boîte de dialogue
3. **⚠️ Attention** : Cette action est irréversible

## 📈 Statistiques et Informations

### Compteurs en Temps Réel
- **Nombre total** de réparations archivées
- **Nombre de réparations** trouvées avec les filtres actuels
- **Badge** sur le bouton "Restituées" dans l'en-tête

### Informations Affichées
- **Client** : Nom complet et email
- **Appareil** : Marque, modèle et type avec icône colorée
- **Description** : Problème et description de la réparation
- **Date de restitution** : Quand la réparation a été archivée
- **Prix** : Montant total de la réparation
- **Statut de paiement** : Chip coloré (Payée/En attente)

## 🔧 Configuration Technique

### Base de Données
- **Statut "returned"** : Statut spécial pour les réparations restituées
- **Index optimisés** : Performance améliorée pour les requêtes d'archivage
- **Vue spécialisée** : `archived_repairs_view` pour les données optimisées

### Fonctions SQL Disponibles
- `get_archive_stats()` : Statistiques des archives
- `search_archived_repairs()` : Recherche avancée
- `restore_repair_from_archive()` : Restauration programmatique
- `get_archived_repairs_by_period()` : Réparations par période

## 🎨 Interface Utilisateur

### Design Responsive
- **Tableau adaptatif** : S'adapte à toutes les tailles d'écran
- **Pagination** : Navigation facile entre les pages
- **Icônes intuitives** : Actions clairement identifiées

### Couleurs et Thème
- **Couleurs cohérentes** : Utilise le thème de l'application
- **Icônes d'appareils** : Couleurs spécifiques par type
- **Statuts visuels** : Chips colorés pour les statuts de paiement

## 🔄 Workflow Recommandé

### Pour les Techniciens
1. **Terminer la réparation** → Statut "Terminée"
2. **Remettre au client** → Déplacer vers "Restitué"
3. **Confirmation** → Réparation automatiquement archivée
4. **Suivi** : Consulter les archives si nécessaire

### Pour les Administrateurs
1. **Vérification** : Contrôler les réparations archivées
2. **Facturation** : Voir les factures des réparations payées
3. **Statistiques** : Analyser les performances via les archives
4. **Nettoyage** : Supprimer les anciennes réparations si nécessaire

## ⚠️ Points d'Attention

### Sécurité des Données
- **Suppression définitive** : Impossible de récupérer après suppression
- **Confirmation requise** : Double validation pour les actions critiques
- **Traçabilité** : Toutes les actions sont enregistrées

### Performance
- **Pagination** : Limite de 10 réparations par page
- **Index optimisés** : Recherche rapide même avec beaucoup de données
- **Chargement progressif** : Interface réactive

### Compatibilité
- **Statut existant** : Compatible avec les réparations existantes
- **Migration automatique** : Pas d'action manuelle requise
- **Rétrocompatibilité** : Fonctionne avec l'ancien système

## 🆘 Dépannage

### Problèmes Courants

#### Réparation non archivée
- **Vérifier le statut** : Doit être "returned"
- **Actualiser la page** : Recharger les données
- **Vérifier les permissions** : Droits d'accès suffisants

#### Recherche qui ne fonctionne pas
- **Vérifier l'orthographe** : Recherche sensible à la casse
- **Essayer des termes plus courts** : Recherche partielle
- **Vider les filtres** : Réinitialiser les critères

#### Performance lente
- **Réduire les filtres** : Moins de critères = plus rapide
- **Vérifier la connexion** : Problème réseau possible
- **Actualiser** : Recharger la page

### Support
- **Logs** : Vérifier la console du navigateur
- **Base de données** : Contrôler les requêtes SQL
- **Permissions** : Vérifier les droits utilisateur

## 📋 Checklist de Mise en Place

- [ ] **Script SQL exécuté** : `creation_page_archivage.sql`
- [ ] **Route ajoutée** : `/app/archive` dans App.tsx
- [ ] **Menu mis à jour** : Lien "Archives" dans la sidebar
- [ ] **Kanban modifié** : Bouton "Voir les archives" ajouté
- [ ] **Notification testée** : Alerte lors du déplacement vers "Restitué"
- [ ] **Recherche testée** : Filtres et recherche fonctionnels
- [ ] **Actions testées** : Facture, restauration, suppression
- [ ] **Responsive testé** : Interface sur mobile et desktop

## 🎯 Avantages

### Pour l'Atelier
- **Kanban épuré** : Seules les réparations actives visibles
- **Organisation** : Séparation claire entre actif et archivé
- **Performance** : Interface plus rapide avec moins de données

### Pour les Utilisateurs
- **Simplicité** : Archivage automatique sans action manuelle
- **Accès facile** : Page dédiée aux réparations terminées
- **Recherche puissante** : Trouver rapidement une réparation

### Pour la Gestion
- **Traçabilité** : Historique complet des réparations
- **Statistiques** : Données pour l'analyse des performances
- **Conformité** : Conservation des données selon les besoins légaux

---

**Note** : Cette fonctionnalité améliore significativement l'organisation du workflow de réparation en séparant automatiquement les réparations actives des réparations terminées.
