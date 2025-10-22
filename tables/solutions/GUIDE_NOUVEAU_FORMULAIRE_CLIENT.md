# Guide du Nouveau Formulaire de Client

## 🎯 Vue d'ensemble

Le formulaire de création et de modification de client a été entièrement repensé pour offrir une expérience utilisateur moderne et professionnelle, avec un design sobre et organisé en onglets.

## 📋 Fonctionnalités

### 🎨 Design moderne
- **Interface en onglets** : Organisation claire des informations
- **Design sobre** : Couleurs grises cohérentes avec la navigation
- **Validation en temps réel** : Vérification des emails dupliqués
- **Responsive** : Adaptation à tous les écrans

### 📝 Champs disponibles

#### Onglet 1 : Détails Client
- **Catégorie Client** : Particulier, Professionnel, Entreprise, Association
- **Titre** : M., Mme, Mlle, Dr
- **Prénom et Nom** : Champs obligatoires
- **Informations entreprise** : Nom société, N° TVA, N° SIREN
- **Contact** : Email, Indicatif pays, Mobile

#### Onglet 2 : Détails Adresse
- **Adresse complète** : Adresse, Complément, Région, Code postal, Ville
- **Adresse de facturation** : Optionnelle, peut être identique à l'adresse de résidence
- **Champs conditionnels** : Apparaissent si l'adresse de facturation est différente

#### Onglet 3 : Autres informations
- **Code Comptable** et **Identifiant CNI**
- **Attachement de fichier** : Bouton de téléchargement
- **Note Interne** : Zone de texte multiligne
- **Statut** : Affiché/Masqué
- **Préférences Notifications** : SMS/Email
- **Préférences Marketing** : SMS/Email

## 🔧 Installation et Configuration

### 1. Mise à jour de la base de données

Exécutez le script SQL pour étendre la table clients :

```bash
# Option 1 : Utiliser le script automatique
./update_database.sh

# Option 2 : Exécuter manuellement le script SQL
psql votre_url_supabase -f tables/extend_clients_table.sql
```

### 2. Vérification des nouveaux champs

Le script ajoute automatiquement les colonnes suivantes à la table `clients` :

#### Informations personnelles et entreprise
- `category` (TEXT) - Catégorie du client
- `title` (TEXT) - Titre de civilité
- `company_name` (TEXT) - Nom de l'entreprise
- `vat_number` (TEXT) - Numéro de TVA
- `siren_number` (TEXT) - Numéro SIREN
- `country_code` (TEXT) - Code pays téléphone

#### Adresse détaillée
- `address_complement` (TEXT) - Complément d'adresse
- `region` (TEXT) - Région/Département
- `postal_code` (TEXT) - Code postal
- `city` (TEXT) - Ville

#### Adresse de facturation
- `billing_address_same` (BOOLEAN) - Adresse identique
- `billing_address` (TEXT) - Adresse de facturation
- `billing_address_complement` (TEXT) - Complément
- `billing_region` (TEXT) - Région de facturation
- `billing_postal_code` (TEXT) - Code postal de facturation
- `billing_city` (TEXT) - Ville de facturation

#### Informations complémentaires
- `accounting_code` (TEXT) - Code comptable
- `cni_identifier` (TEXT) - Identifiant CNI
- `attached_file_path` (TEXT) - Chemin fichier joint
- `internal_note` (TEXT) - Note interne

#### Préférences
- `status` (TEXT) - Statut du client
- `sms_notification` (BOOLEAN) - Notifications SMS
- `email_notification` (BOOLEAN) - Notifications email
- `sms_marketing` (BOOLEAN) - Marketing SMS
- `email_marketing` (BOOLEAN) - Marketing email

## 🚀 Utilisation

### Création d'un nouveau client

1. **Page Clients** : Cliquer sur "Nouveau client"
2. **Suivi des Réparations** : Onglet "Nouveau client" dans la création de réparation
3. **Remplir les onglets** dans l'ordre souhaité
4. **Validation** : Le bouton "Créer" s'active quand les champs obligatoires sont remplis

### Modification d'un client existant

1. **Page Clients** : Cliquer sur l'icône "Modifier" (crayon)
2. **Formulaire pré-rempli** avec les données existantes
3. **Modifier** les champs souhaités
4. **Sauvegarder** avec le bouton "Modifier"

## 🔍 Validation et Sécurité

### Validation automatique
- **Email unique** : Vérification en temps réel
- **Champs obligatoires** : Prénom, Nom, Email, Mobile
- **Format email** : Validation du format
- **Téléphone** : Gestion automatique de l'indicatif pays

### Gestion des erreurs
- **Messages d'erreur** clairs et explicites
- **Prévention des doublons** : Email déjà utilisé
- **Sauvegarde sécurisée** : Toutes les données sont validées

## 📊 Affichage des données

### Table des clients
Les nouveaux champs sont automatiquement disponibles dans :
- **Liste des clients** : Affichage des informations principales
- **Détails client** : Toutes les informations complètes
- **Recherche et filtres** : Basés sur les nouveaux champs

### Intégration
- **Réparations** : Sélection automatique du client créé
- **Factures** : Utilisation des adresses de facturation
- **Notifications** : Respect des préférences client

## 🛠️ Maintenance

### Sauvegarde
- **Données existantes** : Préservées lors de la mise à jour
- **Compatibilité** : Anciens clients fonctionnent toujours
- **Migration** : Progressive et sécurisée

### Performance
- **Index optimisés** : Sur les champs de recherche fréquents
- **Requêtes optimisées** : Chargement rapide des données
- **Cache intelligent** : Réduction des appels à la base

## 🎨 Personnalisation

### Couleurs
- **Gris principal** : `#6b7280`
- **Gris foncé** : `#4b5563`
- **Bouton d'action** : Teal `#00bcd4`

### Styles
- **Bordures arrondies** : Design moderne
- **Ombres subtiles** : Profondeur visuelle
- **Espacement cohérent** : Lisibilité optimale

## 📞 Support

En cas de problème :
1. **Vérifier** que le script SQL a été exécuté
2. **Contrôler** les variables d'environnement Supabase
3. **Consulter** les logs de la console
4. **Tester** avec un client simple d'abord

---

*Ce guide sera mis à jour au fur et à mesure des améliorations du formulaire.*
