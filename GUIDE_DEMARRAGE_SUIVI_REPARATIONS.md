# Guide de Démarrage - Suivi des Réparations

## 🚀 Démarrage rapide

### 1. Configuration de la base de données

1. **Ouvrez votre projet Supabase**
2. **Allez dans l'éditeur SQL**
3. **Exécutez le script** `setup_repair_tracking.sql`
4. **Vérifiez que les fonctions sont créées** :
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_name IN ('get_repair_tracking_info', 'get_client_repair_history', 'update_repair_status');
   ```

### 2. Démarrage de l'application

```bash
# Dans le terminal, à la racine du projet
npm run dev
```

L'application devrait démarrer sur `http://localhost:3002`

### 3. Test de la fonctionnalité

#### Option A : Via la page d'accueil
1. **Ouvrez** `http://localhost:3002`
2. **Cliquez sur** "Suivre ma Réparation" (bouton en haut à droite)
3. **Ou cliquez sur** "Suivre ma Réparation" dans la section principale

#### Option B : Accès direct
1. **Page de suivi** : `http://localhost:3002/repair-tracking`
2. **Page d'historique** : `http://localhost:3002/repair-history`

### 4. Création de données de test

Si vous n'avez pas encore de réparations dans votre base de données, exécutez ce script SQL dans Supabase :

```sql
-- Créer un client de test
INSERT INTO clients (first_name, last_name, email, phone) 
VALUES ('Jean', 'Dupont', 'jean.dupont@test.com', '0123456789')
ON CONFLICT (email) DO NOTHING;

-- Créer un appareil de test
INSERT INTO devices (brand, model, serial_number, type) 
VALUES ('Apple', 'iPhone 12', 'TEST123456', 'smartphone')
ON CONFLICT (serial_number) DO NOTHING;

-- Créer une réparation de test
INSERT INTO repairs (
    client_id, 
    device_id, 
    status, 
    description, 
    issue, 
    estimated_duration, 
    due_date, 
    is_urgent, 
    notes, 
    total_price, 
    is_paid
) 
SELECT 
    c.id,
    d.id,
    'in_progress',
    'Écran cassé, remplacement nécessaire',
    'Écran LCD endommagé suite à une chute',
    120,
    NOW() + INTERVAL '7 days',
    false,
    'Pièces commandées, réparation prévue dans 2 jours',
    89.99,
    false
FROM clients c, devices d 
WHERE c.email = 'jean.dupont@test.com' 
AND d.serial_number = 'TEST123456';
```

### 5. Test avec les données

1. **Allez sur** la page de suivi des réparations
2. **Saisissez** :
   - Email : `jean.dupont@test.com`
   - Numéro de réparation : (copiez l'ID de la réparation créée)
3. **Cliquez sur** "Rechercher"
4. **Vérifiez** que les informations s'affichent correctement

## 🔧 Dépannage

### Erreur 500 lors du chargement des pages

**Cause** : Erreurs de compilation TypeScript
**Solution** :
```bash
# Vérifiez la compilation
npm run build

# Si des erreurs, corrigez-les puis redémarrez
npm run dev
```

### Erreur "Aucune réparation trouvée"

**Cause** : Données de test non créées ou email/ID incorrect
**Solution** :
1. Vérifiez que les données de test existent dans Supabase
2. Vérifiez l'email et l'ID de réparation saisis
3. Exécutez le script de création de données de test

### Erreur de connexion à Supabase

**Cause** : Variables d'environnement manquantes
**Solution** :
1. Vérifiez le fichier `.env`
2. Assurez-vous que `VITE_SUPABASE_URL` et `VITE_SUPABASE_ANON_KEY` sont définis
3. Redémarrez le serveur de développement

## 📱 Fonctionnalités disponibles

### Page de suivi (`/repair-tracking`)
- ✅ Recherche par email et numéro de réparation
- ✅ Affichage du statut avec indicateurs visuels
- ✅ Informations détaillées (description, problème, appareil)
- ✅ Dates importantes (création, début, fin, échéance)
- ✅ Informations financières (prix, paiement)
- ✅ Notes du technicien
- ✅ Lien vers l'historique

### Page d'historique (`/repair-history`)
- ✅ Recherche par email uniquement
- ✅ Liste de toutes les réparations
- ✅ Tableau avec statuts et prix
- ✅ Vue détaillée de chaque réparation
- ✅ Navigation vers le suivi individuel

## 🎯 Prochaines étapes

1. **Testez** toutes les fonctionnalités
2. **Personnalisez** l'interface selon vos besoins
3. **Ajoutez** des notifications par email/SMS
4. **Intégrez** un système de QR codes
5. **Développez** une application mobile

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs du serveur de développement
2. Consultez la console du navigateur (F12)
3. Vérifiez les logs Supabase
4. Consultez la documentation complète dans `md/REPAIR_TRACKING_FEATURE.md`

---

**Bon développement ! 🚀**
