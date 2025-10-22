# Guide de Modification des URLs Personnalisées

## 📋 Vue d'ensemble

Le système de demandes de devis permet maintenant de **modifier, activer/désactiver et supprimer** les URLs personnalisées déjà créées. Cette fonctionnalité offre une flexibilité complète dans la gestion des URLs.

## 🔧 Fonctionnalités Ajoutées

### 1. **Modification d'URL**
- Changer le nom d'une URL personnalisée existante
- Validation en temps réel du nouveau format
- Vérification d'unicité automatique
- Avertissement sur l'impact du changement

### 2. **Activation/Désactivation**
- Activer ou désactiver une URL sans la supprimer
- Les URLs désactivées ne sont plus accessibles publiquement
- Possibilité de réactiver à tout moment

### 3. **Suppression d'URL**
- Supprimer définitivement une URL personnalisée
- Protection contre la suppression si des demandes y sont associées
- Confirmation obligatoire avant suppression

### 4. **Menu Contextuel**
- Interface intuitive avec menu déroulant
- Actions rapides : Modifier, Activer/Désactiver, Copier, Supprimer
- Icônes claires pour chaque action

## 🎯 Utilisation

### Accéder aux Actions

1. **Aller dans "Demandes de Devis"**
2. **Cliquer sur l'onglet "URLs Personnalisées"**
3. **Cliquer sur le bouton "⋮" (trois points)** à droite de chaque URL
4. **Choisir l'action souhaitée** dans le menu déroulant

### Modifier une URL

1. **Sélectionner "Modifier l'URL"** dans le menu
2. **Saisir la nouvelle URL** dans le champ
3. **Vérifier l'aperçu** de la nouvelle adresse
4. **Cliquer sur "Modifier"** pour confirmer

**⚠️ Important :** Modifier une URL rend l'ancienne URL inaccessible. Assurez-vous de communiquer le changement à vos clients.

### Activer/Désactiver une URL

1. **Sélectionner "Activer" ou "Désactiver"** selon le statut actuel
2. **L'URL change immédiatement de statut**
3. **Les URLs désactivées ne sont plus accessibles publiquement**

### Supprimer une URL

1. **Sélectionner "Supprimer"** dans le menu
2. **Confirmer la suppression** dans la boîte de dialogue
3. **L'URL est supprimée définitivement**

**⚠️ Protection :** Impossible de supprimer une URL si des demandes de devis y sont associées.

## 🔒 Sécurité et Validation

### Validation des URLs
- **Format** : Lettres, chiffres et tirets uniquement
- **Longueur** : Entre 3 et 50 caractères
- **Début/Fin** : Ne peut pas commencer ou finir par un tiret
- **Mots réservés** : Certains mots sont interdits (admin, api, etc.)
- **Unicité** : Chaque URL doit être unique

### Protection des Données
- **Vérification d'unicité** avant modification
- **Protection contre la suppression** si des demandes existent
- **Validation côté client et serveur**
- **Messages d'erreur explicites**

## 📊 Interface Utilisateur

### Affichage des URLs
```
🔗 localhost:3002/quote/repphone    [Actif]    [📋] [⋮]
   Créé le 01/12/2024
   Modifié le 02/12/2024
```

### Menu Contextuel
```
┌─────────────────────────┐
│ ✏️  Modifier l'URL      │
│ ⚡  Désactiver          │
│ 📋  Copier l'URL        │
│ 🗑️  Supprimer          │
└─────────────────────────┘
```

### Dialog de Modification
```
┌─────────────────────────────────────┐
│ Modifier l'URL personnalisée        │
├─────────────────────────────────────┤
│ URL personnalisée: [repphone-new]   │
│                                     │
│ ℹ️  L'URL sera accessible à:        │
│     localhost:3002/quote/      │
│     repphone-new                    │
│                                     │
│ ⚠️  Attention: Modifier l'URL       │
│     rendra l'ancienne URL           │
│     inaccessible.                   │
│                                     │
│ [Annuler] [Modifier]                │
└─────────────────────────────────────┘
```

## 🔄 Flux de Modification

### 1. Validation
```typescript
// Validation du format
const validation = quoteRequestValidator.validateCustomUrl(newUrl);
if (!validation.isValid) {
  showError(validation.errors.customUrl);
  return;
}
```

### 2. Vérification d'Unicité
```typescript
// Vérifier que l'URL n'est pas déjà utilisée
const existingUrl = await supabase
  .from('technician_custom_urls')
  .select('id')
  .eq('custom_url', newUrl)
  .neq('id', currentUrlId)
  .single();
```

### 3. Mise à Jour
```typescript
// Mettre à jour en base de données
const { error } = await supabase
  .from('technician_custom_urls')
  .update({ 
    custom_url: newUrl,
    updated_at: new Date().toISOString()
  })
  .eq('id', urlId);
```

## 🚨 Gestion des Erreurs

### Erreurs Courantes

#### URL Déjà Utilisée
```
❌ Cette URL est déjà utilisée
```
**Solution :** Choisir une autre URL ou modifier l'URL existante.

#### Format Invalide
```
❌ L'URL ne peut contenir que des lettres, chiffres et tirets
```
**Solution :** Vérifier le format et supprimer les caractères spéciaux.

#### URL Trop Courte/Longue
```
❌ L'URL doit contenir entre 3 et 50 caractères
```
**Solution :** Ajuster la longueur de l'URL.

#### Impossible de Supprimer
```
❌ Impossible de supprimer cette URL (des demandes y sont associées)
```
**Solution :** Désactiver l'URL au lieu de la supprimer.

## 📈 Bonnes Pratiques

### 1. **Communication des Changements**
- Informer les clients avant de modifier une URL
- Mettre à jour les supports de communication (cartes de visite, site web)
- Utiliser des redirections temporaires si possible

### 2. **Gestion des URLs**
- Utiliser des noms mémorables et cohérents
- Éviter les changements fréquents
- Garder une trace des modifications

### 3. **Sécurité**
- Ne pas utiliser d'informations personnelles dans les URLs
- Éviter les mots trop génériques
- Tester les nouvelles URLs avant de les communiquer

## 🔧 API et Services

### Méthodes Ajoutées

#### `updateCustomUrl(urlId, newCustomUrl)`
```typescript
const success = await quoteRequestService.updateCustomUrl(
  'url-id', 
  'nouvelle-url'
);
```

#### `updateCustomUrlStatus(urlId, isActive)`
```typescript
const success = await quoteRequestService.updateCustomUrlStatus(
  'url-id', 
  false // désactiver
);
```

#### `deleteCustomUrl(urlId)`
```typescript
const success = await quoteRequestService.deleteCustomUrl('url-id');
```

### Validation
```typescript
import { quoteRequestValidator } from '../utils/quoteRequestValidation';

const validation = quoteRequestValidator.validateCustomUrl('nouvelle-url');
if (!validation.isValid) {
  console.error(validation.errors);
}
```

## 🧪 Tests

### Scénarios de Test

1. **Modification d'URL valide**
   - Créer une URL
   - La modifier avec un nouveau nom valide
   - Vérifier que l'ancienne URL n'est plus accessible
   - Vérifier que la nouvelle URL fonctionne

2. **Tentative de modification avec URL existante**
   - Essayer de modifier une URL avec un nom déjà utilisé
   - Vérifier que l'erreur est affichée
   - Vérifier que l'URL n'est pas modifiée

3. **Activation/Désactivation**
   - Désactiver une URL active
   - Vérifier qu'elle n'est plus accessible publiquement
   - La réactiver
   - Vérifier qu'elle redevient accessible

4. **Suppression avec demandes associées**
   - Créer des demandes de devis pour une URL
   - Essayer de supprimer l'URL
   - Vérifier que la suppression est bloquée

## 📝 Changelog

### Version 1.1.0 - Modification des URLs
- ✅ Ajout de la modification d'URLs personnalisées
- ✅ Ajout de l'activation/désactivation d'URLs
- ✅ Ajout de la suppression d'URLs (avec protection)
- ✅ Interface utilisateur améliorée avec menu contextuel
- ✅ Validation complète côté client et serveur
- ✅ Messages d'erreur explicites
- ✅ Protection contre la suppression d'URLs avec demandes

---

**Version** : 1.1.0  
**Date** : Décembre 2024  
**Auteur** : Équipe Atelier Gestion

