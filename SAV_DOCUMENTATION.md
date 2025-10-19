# Documentation - Page SAV Réparateur

## 📋 Vue d'ensemble

La page **SAV Réparateur** est une interface dédiée et optimisée pour la gestion quotidienne des réparations dans l'atelier. Elle offre une expérience intuitive et pratique avec des fonctionnalités spécifiquement conçues pour les réparateurs.

## 🚀 Accès à la page

La page SAV est accessible via le menu latéral :
- **Chemin** : `/app/sav`
- **Icône** : Outil (HandymanIcon)
- **Couleur** : Vert (#16a34a)

## ✨ Fonctionnalités principales

### 1. Vue Kanban améliorée

- **Colonnes par statut** : Organisation visuelle des réparations par état (Nouvelle, En cours, En attente pièces, Terminée)
- **Drag & drop** : Changement de statut par glisser-déposer
- **Cartes enrichies** : Affichage compact avec toutes les informations essentielles

### 2. Statistiques en temps réel

Affichage de 4 indicateurs clés :
- Total des réparations
- Réparations en cours
- Réparations urgentes
- Réparations terminées

### 3. Filtres avancés

- **Recherche globale** : Par numéro, client, appareil, ou description
- **Filtre par technicien** : Voir uniquement vos réparations ou celles d'un collègue
- **Filtre par urgence** : Isoler les réparations urgentes

### 4. Timer de travail

Chaque carte de réparation dispose d'un timer intégré :
- ▶️ **Démarrer** : Lance le chronomètre
- ⏸️ **Pause** : Met en pause le décompte
- ⏹️ **Arrêter** : Finalise et enregistre la durée
- ⏱️ **Affichage** : Format HH:MM:SS en temps réel

### 5. Actions rapides

Sur chaque carte de réparation :
- 👁️ **Voir détails** : Ouvre la vue complète
- 🖨️ **Imprimer étiquette** : Génère une étiquette pour l'appareil
- 📋 **Bon de travail** : Imprime le document de réparation
- 🧾 **Reçu de dépôt** : Document remis au client

### 6. Vue détaillée (Dialog)

4 onglets d'informations :
- **Général** : Description, dates, durées
- **Client & Appareil** : Coordonnées et caractéristiques
- **Services & Pièces** : Détail des prestations et pièces utilisées
- **Notes** : Historique des notes et commentaires

### 7. Templates d'impression

4 types de documents disponibles :

#### Étiquette appareil
- Format compact (100x50mm)
- Numéro de réparation
- Infos client et appareil
- Badge "URGENT" si nécessaire

#### Bon de travail
- Format A4
- Informations complètes
- Checklist de travail
- Zone de notes technicien
- Signatures

#### Reçu de dépôt
- Format A4
- Conditions générales
- Estimation prix et délai
- Signatures client et atelier

#### Facture simplifiée
- Tableau des services/pièces
- Total TTC
- Statut de paiement

## 🎨 Interface utilisateur

### Codes couleur

- 🔴 **Rouge** : Réparations urgentes, en retard
- 🟢 **Vert** : Timer actif, réparations terminées
- 🟡 **Orange** : Timer en pause, en attente
- 🔵 **Bleu** : Informations générales

### Badges visuels

- ⚠️ **Urgent** : Indicateur de priorité
- ✅ **Payé** : Statut de paiement
- ⏰ **Temps restant** : Avant la date limite

### Vues disponibles

- **Kanban** : Vue en colonnes avec drag & drop
- **Liste** : Vue linéaire avec toutes les cartes

## 📊 Service SAV (savService)

### Gestion des timers

```typescript
// Démarrer un timer
savService.startTimer(repairId);

// Mettre en pause
savService.pauseTimer(repairId);

// Reprendre
savService.resumeTimer(repairId);

// Arrêter
savService.stopTimer(repairId);

// Récupérer un timer
const timer = savService.getTimer(repairId);

// Formater la durée
const formatted = savService.formatDuration(timer.totalDuration);
// Résultat: "02:15:30"
```

### Statistiques

```typescript
const stats = savService.calculateStats(repairs, repairStatuses);
// Retourne: {
//   totalRepairs,
//   newRepairs,
//   inProgressRepairs,
//   waitingPartsRepairs,
//   completedRepairs,
//   urgentRepairs,
//   overdueRepairs,
//   averageDuration,
//   completionRate
// }
```

### Logs d'actions

```typescript
savService.createLog(
  repairId,
  'status_change',
  userId,
  userName,
  'Statut changé vers: En cours'
);
```

## 🔧 Intégration

### Nouveaux types TypeScript

Ajoutés dans `src/types/index.ts` :
- `WorkTimer` : Gestion des timers de travail
- `RepairLog` : Historique des actions
- `PrintTemplate` : Templates d'impression
- `SAVStats` : Statistiques SAV

### Nouveaux composants

- `src/components/SAV/RepairCard.tsx` : Carte de réparation
- `src/components/SAV/QuickActions.tsx` : Actions rapides (SpeedDial)
- `src/components/SAV/RepairDetailsDialog.tsx` : Dialog détaillé
- `src/components/SAV/PrintTemplates.tsx` : Service d'impression

### Nouveaux services

- `src/services/savService.ts` : Service principal SAV

### Nouvelle page

- `src/pages/SAV/SAV.tsx` : Page principale

## 💡 Conseils d'utilisation

### Pour les réparateurs

1. **Démarrer la journée** :
   - Filtrer par votre nom pour voir vos réparations
   - Identifier les urgentes et en retard

2. **Travailler sur une réparation** :
   - Démarrer le timer au début
   - Utiliser pause lors des interruptions
   - Arrêter à la fin et noter les observations

3. **Changer de statut** :
   - Glisser-déposer la carte dans la bonne colonne
   - Ou utiliser les actions rapides

4. **Imprimer les documents** :
   - Étiquette au dépôt de l'appareil
   - Bon de travail pour le technicien
   - Reçu au client
   - Facture à la livraison

### Pour les gestionnaires

1. **Vue d'ensemble** :
   - Utiliser les statistiques en haut
   - Identifier les goulots d'étranglement

2. **Répartition du travail** :
   - Filtrer par technicien
   - Vérifier la charge de travail

3. **Alertes** :
   - Surveiller les réparations en retard
   - Prioriser les urgentes

## 🔄 Synchronisation

- Les timers sont conservés en mémoire locale
- Les changements de statut sont sauvegardés en base de données
- Les notes sont horodatées automatiquement
- Rafraîchissement auto toutes les 30 secondes

## 🎯 Raccourcis et astuces

- **Drag & drop** : Plus rapide que les boutons pour changer de statut
- **Clic sur carte** : Ouvre les détails complets
- **SpeedDial** : Actions rapides en bas à droite (si une réparation est sélectionnée)
- **Recherche** : Tape n'importe quelle info pour filtrer instantanément

## 🚧 Notes techniques

### Dépendances utilisées

- `@hello-pangea/dnd` : Drag and drop
- `jspdf` : Génération PDF
- `date-fns` : Gestion des dates
- `@mui/material` : Interface Material-UI
- `react-hot-toast` : Notifications

### Performance

- Lazy loading de la page principale
- Memoization des calculs de filtres et stats
- Mise à jour optimisée des timers
- Nettoyage automatique des intervalles

## 📝 TODO / Améliorations futures

- [ ] Persistance des timers en base de données
- [ ] Notifications push pour les réparations urgentes
- [ ] Export Excel/CSV des statistiques
- [ ] Historique complet des logs en base
- [ ] Photos avant/après dans les détails
- [ ] Signature électronique sur tablette
- [ ] Codes-barres scannables sur les étiquettes
- [ ] Vue calendrier avec timeline
- [ ] Gamification (badges, objectifs)

## 🐛 Dépannage

### Les timers ne s'affichent pas
- Vérifier que le composant est bien monté
- Vérifier la console pour les erreurs

### L'impression ne fonctionne pas
- Vérifier que les pop-ups sont autorisées
- Vérifier la console navigateur

### Le drag & drop ne fonctionne pas
- Vérifier que `@hello-pangea/dnd` est installé
- Vérifier qu'il n'y a pas de conflit avec d'autres drag & drop

## 📞 Support

Pour toute question ou problème, consulter :
- La documentation principale du projet
- Les types TypeScript pour l'auto-complétion
- Les commentaires dans le code source







