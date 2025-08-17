# Atelier Gestion - Application de gestion d'atelier de réparation

Une application complète de gestion d'atelier de réparation d'appareils électroniques, inspirée de Laast.io, développée avec React, TypeScript et Material-UI.

## 🚀 Fonctionnalités

### 📊 Dashboard
- Vue d'ensemble de l'atelier
- Statistiques en temps réel
- Réparations récentes
- Rendez-vous du jour
- Alertes et notifications

### 📋 Kanban
- Tableau de suivi des réparations
- Drag & drop pour changer les statuts
- Gestion des priorités
- Suivi des retards

### 📅 Calendrier
- Gestion des rendez-vous
- Planification des réparations
- Affectation des techniciens
- Notifications automatiques

### 💬 Messagerie
- Communication interne
- Messages avec les clients
- Historique des conversations
- Notifications en temps réel

### 📚 Catalogue multi-couche
- **Appareils** : Gestion des modèles et spécifications
- **Services** : Services de réparation proposés
- **Pièces détachées** : Stock et gestion des pièces
- **Produits** : Accessoires et produits de vente
- **Ruptures** : Alertes de stock
- **Clients** : Base de données clients

### 💰 Ventes
- Gestion des ventes
- Facturation électronique
- Historique des transactions
- Rapports de vente

### 📈 Statistiques
- Analyses détaillées
- Graphiques et rapports
- Suivi des performances
- Export des données

### ⚙️ Administration
- Gestion des utilisateurs
- Paramètres système
- Droits d'accès
- Configuration

## 🛠️ Technologies utilisées

- **React 18** - Framework frontend
- **TypeScript** - Typage statique
- **Material-UI (MUI)** - Composants UI
- **Zustand** - Gestion d'état
- **React Router** - Navigation
- **React Beautiful DnD** - Drag & drop
- **Date-fns** - Manipulation des dates
- **React Hot Toast** - Notifications

## 📦 Installation

1. **Cloner le repository**
```bash
git clone <repository-url>
cd atelier-gestion
```

2. **Installer les dépendances**
```bash
npm install
```

3. **Démarrer l'application**
```bash
npm start
```

L'application sera accessible à l'adresse `http://localhost:3000`

## 🏗️ Structure du projet

```
src/
├── components/          # Composants réutilisables
│   └── Layout/         # Composants de mise en page
├── pages/              # Pages de l'application
│   ├── Dashboard/      # Tableau de bord
│   ├── Kanban/         # Tableau Kanban
│   ├── Calendar/       # Calendrier
│   ├── Messaging/      # Messagerie
│   ├── Catalog/        # Catalogue
│   ├── Sales/          # Ventes
│   ├── Statistics/     # Statistiques
│   ├── Administration/ # Administration
│   └── Settings/       # Réglages
├── store/              # Gestion d'état (Zustand)
├── types/              # Types TypeScript
├── theme/              # Thème Material-UI
├── data/               # Données de démonstration
└── App.tsx             # Composant principal
```

## 🎨 Interface utilisateur

L'application propose une interface moderne et intuitive avec :

- **Design responsive** : Compatible desktop, tablette et mobile
- **Thème personnalisable** : Couleurs et styles adaptables
- **Navigation fluide** : Barre latérale rétractable
- **Notifications** : Système de notifications intégré
- **Accessibilité** : Respect des standards d'accessibilité

## 🔧 Configuration

### Variables d'environnement
Créer un fichier `.env` à la racine du projet :

```env
REACT_APP_API_URL=http://localhost:3001
REACT_APP_APP_NAME=Atelier Gestion
```

### Personnalisation du thème
Modifier le fichier `src/theme/index.ts` pour personnaliser les couleurs et styles.

## 📱 Fonctionnalités avancées

### Gestion des réparations
- Suivi en temps réel
- Notifications automatiques
- Gestion des priorités
- Historique complet

### Gestion du stock
- Alertes automatiques
- Seuils de réapprovisionnement
- Suivi des fournisseurs
- Gestion des ruptures

### Facturation
- Génération automatique
- Gestion de la TVA
- Historique des paiements
- Export PDF

### Reporting
- Statistiques détaillées
- Graphiques interactifs
- Export des données
- Rapports personnalisables

## 🚀 Déploiement

### Build de production
```bash
npm run build
```

### Déploiement sur serveur
```bash
npm run build
# Copier le contenu du dossier build sur votre serveur web
```

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou support :
- Email : support@atelier-gestion.fr
- Documentation : [Lien vers la documentation]
- Issues : [Lien vers les issues GitHub]

## 🔮 Roadmap

- [ ] Intégration calendrier avancé
- [ ] Graphiques Recharts
- [ ] API backend
- [ ] Application mobile
- [ ] Intégration QualiRépar
- [ ] Facturation électronique 2026
- [ ] Intelligence artificielle
- [ ] Multi-tenant

---

**Développé avec ❤️ pour les ateliers de réparation**
