import React from 'react';
import {
  Build as BuildIcon,
  Schedule as ScheduleIcon,
  People as PeopleIcon,
  Assessment as AssessmentIcon,
  Handyman as HandymanIcon,
  Archive as ArchiveIcon,
  Loyalty as LoyaltyIcon,
  Receipt as ReceiptIcon,
  Description as DescriptionIcon,
  LocalShipping as ShippingIcon,
  Warning as WarningIcon,
  DeviceHub as DeviceHubIcon,
  AccountBalance as AccountBalanceIcon,
  AdminPanelSettings as AdminIcon,
  Memory as MemoryIcon,
  Inventory2 as Inventory2Icon,
  ShoppingCart as ShoppingCartIcon,
} from '@mui/icons-material';

export interface Feature {
  icon: React.ElementType;
  title: string;
  description: string;
}

export interface FeatureCategory {
  id: string;
  label: string;
  features: Feature[];
}

export const featureCategories: FeatureCategory[] = [
  {
    id: 'repairs',
    label: 'Réparations & SAV',
    features: [
      {
        icon: BuildIcon,
        title: 'Suivi des Réparations',
        description: 'Gérez vos réparations avec le système Kanban intuitif et suivez l\'état en temps réel.',
      },
      {
        icon: HandymanIcon,
        title: 'SAV & Garanties',
        description: 'Gérez les retours et les garanties avec un système SAV complet et organisé.',
      },
      {
        icon: ScheduleIcon,
        title: 'Calendrier & RDV',
        description: 'Planifiez et gérez vos rendez-vous clients avec un calendrier intégré.',
      },
      {
        icon: PeopleIcon,
        title: 'Gestion Clients',
        description: 'Centralisez les informations de vos clients et leur historique complet.',
      },
      {
        icon: DeviceHubIcon,
        title: 'Gestion des Appareils',
        description: 'Catalogue complet des modèles d\'appareils avec gestion centralisée.',
      },
    ],
  },
  {
    id: 'commercial',
    label: 'Commercial',
    features: [
      {
        icon: ReceiptIcon,
        title: 'Ventes & Facturation',
        description: 'Gestion complète des ventes, factures et encaissements.',
      },
      {
        icon: DescriptionIcon,
        title: 'Devis & Estimations',
        description: 'Création et gestion des devis avec suivi des conversions.',
      },
      {
        icon: ShippingIcon,
        title: 'Suivi des Commandes',
        description: 'Gestion des commandes fournisseurs avec suivi des livraisons.',
      },
      {
        icon: LoyaltyIcon,
        title: 'Programme Fidélité',
        description: 'Récompensez vos clients réguliers avec un programme de fidélité intégré.',
      },
    ],
  },
  {
    id: 'inventory',
    label: 'Inventaire',
    features: [
      {
        icon: MemoryIcon,
        title: 'Pièces Détachées',
        description: 'Gestion complète du stock de pièces détachées avec alertes de rupture.',
      },
      {
        icon: Inventory2Icon,
        title: 'Produits & Accessoires',
        description: 'Gestion des produits et accessoires en vente avec suivi des stocks.',
      },
      {
        icon: WarningIcon,
        title: 'Alertes de Rupture',
        description: 'Surveillance automatique des ruptures de stock avec notifications.',
      },
      {
        icon: ShoppingCartIcon,
        title: 'Services de Réparation',
        description: 'Catalogue des services proposés avec tarification et durée estimée.',
      },
    ],
  },
  {
    id: 'management',
    label: 'Pilotage & Admin',
    features: [
      {
        icon: AssessmentIcon,
        title: 'Statistiques & Rapports',
        description: 'Tableaux de bord détaillés et analyses de performance.',
      },
      {
        icon: ArchiveIcon,
        title: 'Archives',
        description: 'Conservation et consultation des données historiques.',
      },
      {
        icon: AccountBalanceIcon,
        title: 'Gestion des Dépenses',
        description: 'Suivi des dépenses et coûts de l\'atelier pour un meilleur contrôle.',
      },
      {
        icon: AdminIcon,
        title: 'Administration',
        description: 'Outils d\'administration complets pour gérer votre atelier.',
      },
    ],
  },
];
