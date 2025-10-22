# Correction du problème de création de rendez-vous

## Problème identifié

L'erreur `invalid input syntax for type uuid: ""` se produit car l'application envoie des chaînes vides (`""`) pour les champs optionnels qui attendent des UUID ou `null`.

De plus, les composants MUI Select affichent des avertissements car ils reçoivent des valeurs `null` au lieu de chaînes vides (`""`).

## Solutions appliquées

### 1. Correction du service Supabase

Le fichier `src/services/supabaseService.ts` a été modifié pour :

- **Méthode `create`** : Convertir les chaînes vides en `null` avant l'envoi à la base de données
- **Méthode `update`** : Gérer les valeurs vides de la même manière
- **Méthode `getAll`** : Convertir les données de la base vers l'application
- **Méthode `getById`** : Convertir les données de la base vers l'application

### 2. Correction du composant Calendar

Le fichier `src/pages/Calendar/Calendar.tsx` a été modifié pour :

- **Interface utilisateur** : Utiliser des chaînes vides (`""`) pour les composants Select (MUI préfère cela)
- **Envoi à Supabase** : Convertir les chaînes vides en `null` avant l'envoi
- **Affichage** : Convertir les valeurs `null` en chaînes vides pour l'interface

### 3. Script SQL de correction

Le fichier `fix_appointments_table.sql` a été créé pour :

- Créer la table `appointments` si elle n'existe pas
- Ajouter toutes les colonnes manquantes
- S'assurer que les colonnes de clés étrangères acceptent `NULL`
- Configurer les politiques RLS

## Étapes pour résoudre le problème

### Étape 1 : Exécuter le script SQL

1. Ouvrez l'éditeur SQL de Supabase
2. Copiez et exécutez le contenu du fichier `fix_appointments_table.sql`
3. Vérifiez que le message "Table appointments corrigée avec succès !" s'affiche

### Étape 2 : Redémarrer l'application

1. Arrêtez le serveur de développement (Ctrl+C)
2. Relancez l'application : `npm run dev`

### Étape 3 : Tester la création de rendez-vous

1. Allez dans la page Calendrier
2. Cliquez sur "Nouveau rendez-vous"
3. Remplissez le formulaire (les champs optionnels peuvent rester vides)
4. Cliquez sur "Créer"

## Vérification

Après ces corrections, vous devriez pouvoir :

- ✅ Créer des rendez-vous sans erreur
- ✅ Laisser les champs optionnels vides
- ✅ Assigner un utilisateur, client ou réparation si nécessaire
- ✅ Modifier et supprimer des rendez-vous
- ✅ Plus d'avertissements MUI dans la console

## Détails techniques

### Gestion des valeurs dans l'interface utilisateur
```typescript
// Interface utilisateur : chaînes vides pour MUI Select
const [formData, setFormData] = useState({
  clientId: '',
  repairId: '',
  assignedUserId: '',
});
```

### Conversion pour l'envoi à Supabase
```typescript
// Conversion des chaînes vides en null pour la base de données
const convertEmptyToNull = (value: string) => value.trim() === '' ? null : value;

const newAppointment = {
  clientId: convertEmptyToNull(formData.clientId),
  repairId: convertEmptyToNull(formData.repairId),
  assignedUserId: convertEmptyToNull(formData.assignedUserId),
};
```

### Gestion des valeurs dans le service Supabase
```typescript
// Service : conversion des chaînes vides en null
client_id: appointment.clientId && appointment.clientId.trim() !== '' ? appointment.clientId : null
```

### Affichage des données existantes
```typescript
// Conversion des valeurs null en chaînes vides pour l'affichage
clientId: extendedProps.appointment.clientId || '',
```

Cette approche garantit que :
- L'interface utilisateur utilise des chaînes vides (compatible MUI)
- La base de données reçoit des valeurs `null` (compatible PostgreSQL)
- Les données existantes s'affichent correctement
