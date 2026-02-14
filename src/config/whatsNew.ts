import React from 'react';

export interface WhatsNewItem {
  id: string;
  date: string;
  title: string;
  description: string;
  category: 'feature' | 'improvement' | 'fix';
  isNew?: boolean;
}

export const whatsNewItems: WhatsNewItem[] = [
  {
    id: 'buyback-pricing-v2',
    date: '2026-02-12',
    title: 'Rachat d\'appareils : pricing intelligent',
    description: 'Les prix de rachat sont désormais calculés automatiquement selon le modèle exact de l\'appareil (iPhone, Samsung, Pixel, Xiaomi, Huawei...) avec ajustements précis selon l\'état, l\'écran, la batterie, les accessoires et les blocages.',
    category: 'feature',
    isNew: true
  },
  {
    id: 'buyback-design-v2',
    date: '2026-02-12',
    title: 'Rachat : refonte du design',
    description: 'Nouveau design harmonisé pour les formulaires de rachat standard et express, avec des statistiques visuelles améliorées et des indicateurs de statut colorés dans le tableau.',
    category: 'improvement',
    isNew: true
  },
  {
    id: 'sav-module-v1',
    date: '2025-10-15',
    title: 'Nouveau module SAV',
    description: 'Gestion complète des tickets SAV avec suivi des réparations.',
    category: 'feature',
    isNew: false
  },
  {
    id: 'payment-status-tracking',
    date: '2025-10-10',
    title: 'Suivi des statuts de paiement',
    description: 'Amélioration du système de suivi des paiements avec mise à jour automatique des statuts.',
    category: 'improvement',
    isNew: false
  },
  {
    id: 'device-brands-fix',
    date: '2025-09-28',
    title: 'Correction gestion des marques',
    description: 'Résolution des problèmes d\'ambiguïté dans la gestion des marques d\'appareils.',
    category: 'fix',
    isNew: false
  },
  {
    id: 'loyalty-points-system',
    date: '2025-09-25',
    title: 'Système de points de fidélité',
    description: 'Nouveau système de fidélité avec gestion des niveaux et avantages clients.',
    category: 'feature',
    isNew: false
  },
  {
    id: 'kanban-performance',
    date: '2025-09-20',
    title: 'Optimisation du Kanban',
    description: 'Amélioration des performances du tableau Kanban avec chargement plus rapide.',
    category: 'improvement',
    isNew: false
  }
];

export interface CategoryInfo {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
}

export const getCategoryInfo = (category: string): CategoryInfo => {
  const categories: Record<string, CategoryInfo> = {
    feature: { label: 'Nouveauté', color: '#10b981', bgColor: 'rgba(16, 185, 129, 0.08)', icon: 'sparkles' },
    improvement: { label: 'Amélioration', color: '#6366f1', bgColor: 'rgba(99, 102, 241, 0.08)', icon: 'bolt' },
    fix: { label: 'Correction', color: '#f59e0b', bgColor: 'rgba(245, 158, 11, 0.08)', icon: 'wrench' }
  };
  return categories[category as keyof typeof categories] || categories.feature;
};
