# 🧹 Guide de nettoyage - Site vierge prêt à l'emploi

## Objectif
Remettre le site complètement à zéro, sans aucune donnée de test, pour qu'il soit prêt à l'emploi.

## Méthodes de nettoyage

### 1. Via l'interface web (Recommandé)
1. Aller sur le tableau de bord (`/dashboard`)
2. Descendre jusqu'à la section "Outils d'administration"
3. Cliquer sur le bouton "🧹 Nettoyer toutes les données"
4. Confirmer l'action dans la popup
5. Attendre la confirmation de nettoyage

### 2. Via la console SQL (Supabase)
1. Aller dans votre projet Supabase
2. Ouvrir l'éditeur SQL
3. Exécuter le script `clean_database.sql`
4. Vérifier que toutes les tables sont vides

### 3. Via l'API (Programmatique)
```javascript
import { demoDataService } from './services/demoDataService';

// Nettoyer toutes les données
await demoDataService.clearAllData();
```

## Vérification du nettoyage

Après le nettoyage, le site doit afficher :
- ✅ 0 clients
- ✅ 0 appareils  
- ✅ 0 réparations
- ✅ 0 rendez-vous
- ✅ 0 ventes
- ✅ 0 services
- ✅ 0 pièces
- ✅ 0 produits
- ✅ 0 messages

## Sections du tableau de bord après nettoyage

### Statistiques principales
- Réparations actives : 0
- Réparations terminées : 0
- Rendez-vous aujourd'hui : 0
- Chiffre d'affaires : 0 €

### Statistiques Kanban
- Nouvelles : 0
- En cours : 0
- En attente : 0
- Livraison : 0
- Terminées : 0
- Urgentes : 0

### État du Kanban
- Toutes les colonnes affichent 0 réparations
- Message : "Aucune tâche en attente ! Toutes les réparations sont à jour."

### Réparations récentes
- Section masquée (car aucune réparation)

## Avantages du site vierge

1. **Performance optimale** : Pas de données inutiles
2. **Interface propre** : Aucune confusion avec des données de test
3. **Prêt à l'emploi** : Prêt pour de vraies données clients
4. **Sécurité** : Pas de données sensibles de test
5. **Maintenance facile** : Base de données légère

## Remarques importantes

⚠️ **ATTENTION** : Le nettoyage est irréversible. Toutes les données seront définitivement supprimées.

✅ **Recommandé** : Faire une sauvegarde avant le nettoyage si vous avez des données importantes.

🔄 **Après nettoyage** : Le site est immédiatement utilisable pour ajouter de vraies données clients.
