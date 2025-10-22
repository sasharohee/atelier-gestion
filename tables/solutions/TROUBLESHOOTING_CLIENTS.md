# Guide de Dépannage - Section Clients

## Problème : La section clients ne fonctionne plus

### Symptômes
- La page clients affiche "Aucun client trouvé"
- Les données ne se chargent pas
- Erreurs dans la console

### Solutions

#### 1. Vérification des données de démonstration

**Étape 1 : Vérifier si les données existent**
```javascript
// Dans la console du navigateur
console.log('Clients dans le store:', window.store?.getState()?.clients);
```

**Étape 2 : Forcer le chargement des données**
1. Aller sur le Dashboard
2. Cliquer sur "Charger les données de démonstration"
3. Attendre la confirmation
4. Aller dans Catalogue > Clients

#### 2. Test de la connexion Supabase

**Étape 1 : Vérifier la connexion**
1. Aller sur le Dashboard
2. Regarder la section "Test de connexion Supabase"
3. Vérifier que la connexion est verte

**Étape 2 : Tester manuellement**
```javascript
// Dans la console
import('./src/services/demoDataService.ts').then(({ demoDataService }) => {
  demoDataService.ensureDemoData();
});
```

#### 3. Debug de la page Clients

**Étape 1 : Utiliser le bouton Debug**
1. Aller dans Catalogue > Clients
2. Cliquer sur le bouton "Debug"
3. Vérifier le nombre de clients affiché

**Étape 2 : Vérifier les logs**
```javascript
// Dans la console
console.log('État des clients:', clients);
console.log('Nombre de clients:', clients.length);
```

#### 4. Réinitialisation complète

**Étape 1 : Nettoyer le cache**
```javascript
// Dans la console
localStorage.clear();
sessionStorage.clear();
```

**Étape 2 : Recharger la page**
```javascript
window.location.reload();
```

#### 5. Vérification de la base de données

**Étape 1 : Vérifier les tables Supabase**
1. Aller dans votre projet Supabase
2. Vérifier que la table `clients` existe
3. Vérifier qu'elle contient des données

**Étape 2 : Vérifier les permissions**
1. Aller dans Authentication > Policies
2. Vérifier que les politiques permettent la lecture

### Outils de diagnostic

#### Composant AppStatus
Le composant AppStatus sur le Dashboard affiche l'état de toutes les données :
- ✅ Vert : Données présentes
- ❌ Rouge : Données manquantes

#### Boutons de test
- **Dashboard** : "Charger les données de démonstration"
- **Dashboard** : "Test Clients"
- **Clients** : "Debug"

#### Console de debug
```javascript
// Vérifier l'état du store
console.log('Store complet:', window.store?.getState());

// Vérifier les clients spécifiquement
console.log('Clients:', window.store?.getState()?.clients);

// Forcer le rechargement
window.store?.getState()?.loadClients();
```

### Causes possibles

1. **Données non chargées** : Les données de démonstration n'ont pas été chargées
2. **Erreur de connexion** : Problème avec Supabase
3. **Erreur de transformation** : Les données ne sont pas correctement transformées
4. **Cache corrompu** : Le cache local contient des données invalides
5. **Permissions** : Problème de permissions dans Supabase

### Prévention

1. **Toujours vérifier AppStatus** avant de signaler un problème
2. **Utiliser les boutons de test** pour diagnostiquer
3. **Vérifier la console** pour les erreurs
4. **Tester la connexion Supabase** régulièrement

### Support

Si le problème persiste :
1. Vérifier les logs dans la console
2. Tester avec les boutons de debug
3. Vérifier la connexion Supabase
4. Consulter le fichier `src/services/demoDataService.ts`
