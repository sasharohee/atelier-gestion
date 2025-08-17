# 🛠️ Application de Gestion d'Atelier

Une application moderne de gestion d'atelier de réparation d'appareils électroniques, construite avec React, TypeScript, Material-UI, Supabase et déployée sur Vercel.

## 🚀 Fonctionnalités

- **Dashboard interactif** avec statistiques en temps réel
- **Gestion des clients** - CRUD complet
- **Catalogue de produits** avec gestion des stocks
- **Services de réparation** avec tarification
- **Suivi des réparations** avec statuts
- **Gestion des pièces détachées**
- **Commandes et facturation**
- **Calendrier de rendez-vous**
- **Interface Kanban** pour le suivi des tâches
- **Messagerie intégrée**
- **Statistiques et rapports**

## 🛠️ Technologies Utilisées

- **Frontend** : React 18, TypeScript, Material-UI
- **Backend** : Supabase (PostgreSQL + API REST)
- **Build Tool** : Vite
- **Déploiement** : Vercel
- **État Global** : Zustand
- **Routing** : React Router DOM
- **Calendrier** : FullCalendar
- **Graphiques** : Recharts
- **Drag & Drop** : React Beautiful DnD

## 📦 Installation

### Prérequis

- Node.js 18+ 
- npm ou yarn
- Compte Supabase (gratuit)

### Installation locale

```bash
# Cloner le repository
git clone https://github.com/votre-username/atelier-gestion.git
cd atelier-gestion

# Installer les dépendances
npm install

# Démarrer le serveur de développement
npm run dev
```

L'application sera accessible sur `http://localhost:3000`

## 🔧 Configuration Supabase

1. Créez un projet sur [Supabase](https://supabase.com)
2. Récupérez vos clés d'API dans les paramètres du projet
3. Exécutez le script SQL dans l'éditeur Supabase (voir `SUPABASE_SETUP.md`)
4. Mettez à jour les variables d'environnement dans `src/lib/supabase.ts`

## 🚀 Déploiement

### Déploiement sur Vercel

```bash
# Installer Vercel CLI
npm install -g vercel

# Déployer
vercel --prod
```

### Déploiement sur GitHub Pages

```bash
# Build de production
npm run build

# Déployer (si configuré)
npm run deploy
```

## 📁 Structure du Projet

```
atelier-gestion/
├── src/
│   ├── components/          # Composants réutilisables
│   │   ├── Layout/         # Layout principal
│   │   └── SupabaseTest/   # Test de connexion
│   ├── pages/              # Pages de l'application
│   │   ├── Dashboard/      # Tableau de bord
│   │   ├── Catalog/        # Catalogue produits
│   │   ├── Sales/          # Ventes
│   │   ├── Calendar/       # Calendrier
│   │   ├── Kanban/         # Kanban
│   │   └── ...
│   ├── hooks/              # Hooks personnalisés
│   ├── services/           # Services Supabase
│   ├── lib/                # Configuration Supabase
│   ├── store/              # État global (Zustand)
│   ├── types/              # Types TypeScript
│   └── theme/              # Thème Material-UI
├── database/               # Schéma de base de données
├── scripts/                # Scripts utilitaires
├── public/                 # Assets statiques
└── docs/                   # Documentation
```

## 🗄️ Base de Données

### Tables principales

- **clients** - Informations des clients
- **produits** - Catalogue des produits
- **services** - Services de réparation
- **reparations** - Suivi des réparations
- **pieces** - Pièces détachées
- **commandes** - Commandes clients
- **users** - Utilisateurs système
- **rendez_vous** - Calendrier

### Relations

- Réparations ↔ Clients (Many-to-One)
- Commandes ↔ Clients (Many-to-One)
- Commande_Produits ↔ Commandes (Many-to-One)
- Commande_Produits ↔ Produits (Many-to-One)

## 🔐 Sécurité

- **Row Level Security (RLS)** activé sur toutes les tables
- **Authentification** via Supabase Auth
- **Validation** côté client et serveur
- **HTTPS** obligatoire en production

## 📊 Fonctionnalités Avancées

### Dashboard
- Statistiques en temps réel
- Graphiques interactifs
- Vue d'ensemble des réparations
- Alertes et notifications

### Gestion des Réparations
- Workflow Kanban
- Suivi des statuts
- Estimation des coûts
- Historique complet

### Catalogue
- Gestion des stocks
- Catégorisation
- Images des produits
- Prix dynamiques

### Clients
- Profils complets
- Historique des réparations
- Communication intégrée
- Fidélisation

## 🧪 Tests

```bash
# Tests unitaires
npm test

# Tests d'intégration
npm run test:integration

# Tests E2E
npm run test:e2e
```

## 📈 Performance

- **Lazy Loading** des composants
- **Code Splitting** automatique
- **Optimisation** des images
- **Cache** intelligent
- **PWA** ready

## 🤝 Contribution

1. Fork le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📝 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

- **Documentation** : `SUPABASE_SETUP.md`
- **Issues** : [GitHub Issues](https://github.com/votre-username/atelier-gestion/issues)
- **Discussions** : [GitHub Discussions](https://github.com/votre-username/atelier-gestion/discussions)

## 🙏 Remerciements

- [Supabase](https://supabase.com) pour le backend
- [Vercel](https://vercel.com) pour l'hébergement
- [Material-UI](https://mui.com) pour les composants
- [React](https://reactjs.org) pour le framework

---

**Développé avec ❤️ pour les ateliers de réparation**

## 🔗 Liens Utiles

- **Application en ligne** : [https://atelier-gestion-8kjroglwg-sasharohees-projects.vercel.app](https://atelier-gestion-8kjroglwg-sasharohees-projects.vercel.app)
- **Dashboard Supabase** : [https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv](https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv)
- **Documentation Supabase** : [SUPABASE_SETUP.md](./SUPABASE_SETUP.md)
