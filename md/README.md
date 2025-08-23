# 🏪 Application de Gestion d'Atelier

Application complète de gestion d'atelier de réparation d'appareils électroniques avec interface moderne. L'atelier est vierge et prêt à recevoir vos données.

## 🚀 Démarrage Rapide

### 1. Installation des Dépendances

```bash
npm install
```

### 2. Démarrage de l'Application

```bash
npm run dev
```

L'application sera accessible sur `http://localhost:3001`

## 🎯 Fonctionnalités

### 📋 Gestion des Clients
- Ajout, modification et suppression de clients
- Historique des réparations par client
- Gestion des coordonnées et informations

### 🔧 Suivi des Réparations
- Création et suivi des réparations
- Statuts : en attente, en cours, terminée, restitué
- Estimation et facturation des prix
- Notes et commentaires

### 📦 Catalogue de Produits
- Gestion du stock de produits
- Catégorisation des articles
- Suivi des prix et disponibilités

### 🛠️ Services et Pièces
- Catalogue des services proposés
- Gestion des pièces détachées
- Tarification et durée estimée

### 📅 Gestion des Rendez-vous
- Planification des rendez-vous
- Calendrier interactif
- Gestion des disponibilités

### 📊 Tableau de Bord
- Statistiques en temps réel
- Graphiques et indicateurs
- Vue d'ensemble de l'activité

### 💼 Gestion des Commandes
- Création et suivi des commandes
- Gestion des statuts de livraison
- Facturation automatique

## 🛠️ Technologies Utilisées

- **Frontend** : React 18, TypeScript, Vite
- **UI** : Material-UI (MUI), Emotion
- **État** : Zustand
- **Routing** : React Router DOM
- **Graphiques** : Recharts
- **Calendrier** : FullCalendar
- **Notifications** : React Hot Toast

## 📁 Structure du Projet

```
src/
├── components/          # Composants réutilisables
│   └── Layout/         # Layout principal et sidebar
├── pages/              # Pages de l'application
│   ├── Administration/
│   ├── Calendar/
│   ├── Catalog/
│   ├── Dashboard/
│   ├── Kanban/
│   ├── Messaging/
│   ├── Sales/
│   ├── Settings/
│   └── Statistics/
├── hooks/              # Hooks personnalisés
├── store/              # État global (Zustand)
├── types/              # Types TypeScript
└── theme/              # Configuration du thème
```

## 🔧 Scripts Disponibles

```bash
# Développement
npm run dev          # Démarrer le serveur de développement
npm run start        # Alias pour dev

# Build
npm run build        # Construire pour la production
npm run preview      # Prévisualiser le build
```

## 📊 Données Locales

L'application utilise des données locales stockées dans le store Zustand. L'atelier est complètement vierge au démarrage et toutes les données se réinitialisent au rechargement de la page.

### Types de Données Disponibles

- **Clients** : Gestion des informations clients
- **Produits** : Catalogue des produits
- **Services** : Services de réparation
- **Réparations** : Suivi des réparations
- **Pièces** : Pièces détachées
- **Commandes** : Commandes clients
- **Rendez-vous** : Gestion des rendez-vous

## 🎨 Interface Utilisateur

### Design System
- **Material-UI** pour les composants
- **Thème personnalisé** avec couleurs adaptées
- **Responsive design** pour tous les écrans
- **Animations fluides** et transitions

### Navigation
- **Sidebar** avec navigation principale
- **Breadcrumbs** pour la navigation
- **Recherche globale** intégrée
- **Notifications** en temps réel

## 📈 Fonctionnalités Avancées

### Dashboard Interactif
- Statistiques en temps réel
- Graphiques dynamiques
- Vue d'ensemble complète
- Alertes et notifications

### Gestion des Réparations
- Workflow Kanban
- Suivi des statuts
- Estimation des coûts
- Historique complet

### Catalogue Intelligent
- Gestion des stocks
- Catégorisation automatique
- Prix dynamiques
- Images des produits

### Clients et Relations
- Profils complets
- Historique des réparations
- Communication intégrée
- Fidélisation

## 🚨 Dépannage

### Problèmes Courants

1. **Erreur de port**
   - L'application utilise le port 3001 par défaut
   - Si le port est occupé, Vite choisira automatiquement un autre port

2. **Problèmes de build**
   - Vérifiez que toutes les dépendances sont installées
   - Consultez les logs d'erreur

3. **Données perdues**
   - L'atelier est vierge au démarrage
   - Toutes les données se réinitialisent au rechargement de la page

## 🤝 Contribution

1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](./LICENSE) pour plus de détails.

## 🆘 Support

Si vous rencontrez des problèmes :

1. Consultez la documentation
2. Vérifiez les issues existantes
3. Créez une nouvelle issue avec les détails du problème

---

**Développé avec ❤️ pour la gestion d'atelier de réparation**
