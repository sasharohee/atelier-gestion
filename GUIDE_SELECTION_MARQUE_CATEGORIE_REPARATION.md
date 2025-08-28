# Guide : Sélection de Marque et Catégorie lors de la Création de Réparation

## 🎯 Fonctionnalité ajoutée

Lors de la création d'une nouvelle réparation, il est maintenant possible de filtrer les appareils par marque et catégorie pour faciliter la sélection de l'appareil concerné.

## 🔧 Fonctionnalités implémentées

### 1. Filtres de sélection
- **Filtre par marque** : Sélectionner une marque spécifique (Apple, Samsung, etc.)
- **Filtre par catégorie** : Sélectionner un type d'appareil (Smartphone, Tablette, etc.)
- **Filtrage combiné** : Les deux filtres fonctionnent ensemble

### 2. Interface utilisateur améliorée
- **Sélecteurs déroulants** pour marque et catégorie
- **Liste d'appareils filtrée** en temps réel
- **Réinitialisation automatique** de la sélection d'appareil lors du changement de filtre
- **Message informatif** quand aucun appareil ne correspond aux filtres

## 📍 Implémentation

### 1. États ajoutés

**Fichier :** `src/pages/Kanban/Kanban.tsx`

```typescript
// États pour la sélection de marque et catégorie
const [selectedBrand, setSelectedBrand] = useState('');
const [selectedCategory, setSelectedCategory] = useState('');
```

### 2. Fonctions utilitaires

```typescript
// Fonctions utilitaires pour obtenir les marques et catégories uniques
const getUniqueBrands = () => {
  const brands = devices.map(device => device.brand);
  return [...new Set(brands)].sort();
};

const getUniqueCategories = () => {
  const categories = devices.map(device => device.type);
  return [...new Set(categories)].sort();
};

const getFilteredDevices = () => {
  return devices.filter(device => {
    const brandMatch = !selectedBrand || device.brand === selectedBrand;
    const categoryMatch = !selectedCategory || device.type === selectedCategory;
    return brandMatch && categoryMatch;
  });
};
```

### 3. Interface utilisateur

**Sélecteur de marque :**
```typescript
<FormControl fullWidth>
  <InputLabel>Marque</InputLabel>
  <Select 
    label="Marque"
    value={selectedBrand}
    onChange={(e) => {
      setSelectedBrand(e.target.value);
      setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection d'appareil
    }}
  >
    <MenuItem value="">Toutes les marques</MenuItem>
    {getUniqueBrands().map((brand) => (
      <MenuItem key={brand} value={brand}>
        {brand}
      </MenuItem>
    ))}
  </Select>
</FormControl>
```

**Sélecteur de catégorie :**
```typescript
<FormControl fullWidth>
  <InputLabel>Catégorie</InputLabel>
  <Select 
    label="Catégorie"
    value={selectedCategory}
    onChange={(e) => {
      setSelectedCategory(e.target.value);
      setNewRepair(prev => ({ ...prev, deviceId: '' })); // Réinitialiser la sélection d'appareil
    }}
  >
    <MenuItem value="">Toutes les catégories</MenuItem>
    <MenuItem value="smartphone">Smartphone</MenuItem>
    <MenuItem value="tablet">Tablette</MenuItem>
    <MenuItem value="laptop">Ordinateur portable</MenuItem>
    <MenuItem value="desktop">Ordinateur fixe</MenuItem>
    <MenuItem value="other">Autre</MenuItem>
  </Select>
</FormControl>
```

**Sélecteur d'appareil filtré :**
```typescript
<FormControl fullWidth>
  <InputLabel>Appareil *</InputLabel>
  <Select 
    label="Appareil *"
    value={newRepair.deviceId || ''}
    onChange={(e) => handleNewRepairChange('deviceId', e.target.value)}
    disabled={getFilteredDevices().length === 0}
  >
    {getFilteredDevices().map((device) => (
      <MenuItem key={device.id} value={device.id}>
        {device.brand} {device.model}
      </MenuItem>
    ))}
  </Select>
  {getFilteredDevices().length === 0 && (
    <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
      Aucun appareil trouvé avec les filtres sélectionnés
    </Typography>
  )}
</FormControl>
```

## 🎨 Interface utilisateur

### Disposition des champs
- **Marque** : Sélecteur déroulant (4 colonnes)
- **Catégorie** : Sélecteur déroulant (4 colonnes)
- **Appareil** : Sélecteur déroulant filtré (4 colonnes)

### Comportement des filtres
1. **Sélection de marque** : Filtre les appareils par marque
2. **Sélection de catégorie** : Filtre les appareils par type
3. **Filtrage combiné** : Applique les deux filtres simultanément
4. **Réinitialisation** : Change la sélection d'appareil lors du changement de filtre

## 🔍 Cas d'usage

### Scénario 1 : Recherche par marque
1. **Sélectionner** "Apple" dans le filtre marque
2. **Résultat** : Seuls les appareils Apple apparaissent dans la liste
3. **Sélectionner** l'appareil souhaité

### Scénario 2 : Recherche par catégorie
1. **Sélectionner** "Smartphone" dans le filtre catégorie
2. **Résultat** : Seuls les smartphones apparaissent dans la liste
3. **Sélectionner** l'appareil souhaité

### Scénario 3 : Recherche combinée
1. **Sélectionner** "Apple" et "Smartphone"
2. **Résultat** : Seuls les iPhones apparaissent dans la liste
3. **Sélectionner** l'iPhone souhaité

### Scénario 4 : Aucun résultat
1. **Sélectionner** des filtres trop restrictifs
2. **Résultat** : Message "Aucun appareil trouvé avec les filtres sélectionnés"
3. **Solution** : Ajuster les filtres ou créer un nouvel appareil

## ✅ Avantages

### 1. Facilité de sélection
- **Recherche rapide** dans de grandes listes d'appareils
- **Filtrage intuitif** par marque et type
- **Réduction des erreurs** de sélection

### 2. Expérience utilisateur améliorée
- **Interface claire** avec filtres visibles
- **Feedback immédiat** lors du filtrage
- **Réinitialisation automatique** pour éviter les incohérences

### 3. Flexibilité
- **Filtres optionnels** : Peut être utilisé partiellement
- **Combinaison de filtres** : Recherche précise
- **Réinitialisation facile** : Bouton "Toutes les marques/catégories"

## 🧪 Tests recommandés

### Test 1 : Filtrage par marque
1. Ouvrir le formulaire de nouvelle réparation
2. Sélectionner une marque spécifique
3. Vérifier que seuls les appareils de cette marque apparaissent

### Test 2 : Filtrage par catégorie
1. Sélectionner une catégorie spécifique
2. Vérifier que seuls les appareils de cette catégorie apparaissent

### Test 3 : Filtrage combiné
1. Sélectionner marque ET catégorie
2. Vérifier que seuls les appareils correspondants apparaissent

### Test 4 : Réinitialisation
1. Changer les filtres
2. Vérifier que la sélection d'appareil se réinitialise
3. Vérifier que les filtres se réinitialisent lors de la fermeture

### Test 5 : Aucun résultat
1. Sélectionner des filtres incompatibles
2. Vérifier l'affichage du message d'information
3. Vérifier que le sélecteur d'appareil est désactivé

## 📝 Notes importantes

### Comportement attendu
- **Filtrage en temps réel** : Les résultats se mettent à jour immédiatement
- **Réinitialisation automatique** : La sélection d'appareil se vide lors du changement de filtre
- **Validation** : Le sélecteur d'appareil est désactivé si aucun résultat

### Compatibilité
- ✅ Compatible avec l'architecture existante
- ✅ Pas d'impact sur les autres fonctionnalités
- ✅ Maintient la validation des champs obligatoires

### Évolutions possibles
- **Recherche textuelle** : Ajouter un champ de recherche libre
- **Favoris** : Marquer certains appareils comme favoris
- **Historique** : Garder un historique des sélections récentes
- **Suggestions** : Proposer des appareils basés sur le client

## 🎯 Résultat final

Après l'implémentation de cette fonctionnalité :
- ✅ Sélection d'appareil facilitée par filtres
- ✅ Interface utilisateur intuitive et claire
- ✅ Réduction des erreurs de sélection
- ✅ Expérience utilisateur améliorée
- ✅ Flexibilité dans la recherche d'appareils
