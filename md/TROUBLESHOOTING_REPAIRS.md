# Guide de dépannage - Création de réparations

## 🚨 Problème : La création de réparations ne fonctionne pas

### 🔍 Diagnostic

#### 1. **Vérifier les tables Supabase**
```bash
# Exécuter le script de vérification
node check-supabase-tables.js
```

#### 2. **Vérifier la console du navigateur**
- Ouvrir les outils de développement (F12)
- Aller dans l'onglet "Console"
- Essayer de créer une réparation
- Noter les erreurs affichées

#### 3. **Vérifier les variables d'environnement**
```bash
# Vérifier que ces variables sont définies
echo $VITE_SUPABASE_URL
echo $VITE_SUPABASE_ANON_KEY
```

### 🛠️ Solutions

#### **Solution 1 : Tables manquantes dans Supabase**

1. **Accéder à Supabase Dashboard**
   - Aller sur https://supabase.com/dashboard
   - Sélectionner votre projet

2. **Exécuter le script SQL**
   - Aller dans "SQL Editor"
   - Copier le contenu de `database_setup.sql`
   - Exécuter le script

3. **Vérifier les tables créées**
   - Aller dans "Table Editor"
   - Vérifier que toutes les tables existent :
     - `users`
     - `clients`
     - `devices`
     - `repairs`
     - `parts`
     - `products`
     - `sales`
     - `appointments`

#### **Solution 2 : Problème de RLS (Row Level Security)**

1. **Vérifier les politiques RLS**
   ```sql
   -- Dans Supabase SQL Editor
   SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
   FROM pg_policies 
   WHERE schemaname = 'public';
   ```

2. **Recréer les politiques si nécessaire**
   ```sql
   -- Activer RLS pour toutes les tables
   ALTER TABLE public.repairs ENABLE ROW LEVEL SECURITY;
   
   -- Créer une politique pour permettre l'insertion
   CREATE POLICY "Enable insert for authenticated users" 
   ON public.repairs FOR INSERT 
   WITH CHECK (auth.role() = 'authenticated');
   ```

#### **Solution 3 : Problème de données de démonstration**

1. **Charger les données de démonstration**
   - Aller dans le Dashboard
   - Cliquer sur "Charger les données de démonstration"
   - Attendre la confirmation

2. **Vérifier qu'il y a des clients et appareils**
   - Aller dans "Catalogue" > "Clients"
   - Aller dans "Catalogue" > "Appareils"
   - S'assurer qu'il y a des données

#### **Solution 4 : Problème de format de données**

1. **Vérifier le format des dates**
   - Les dates doivent être au format ISO
   - Exemple : `2024-01-15`

2. **Vérifier les types de données**
   - `totalPrice` doit être un nombre
   - `isUrgent` doit être un booléen
   - `status` doit correspondre aux statuts existants

### 🧪 Test de la fonctionnalité

#### **Étape 1 : Test de base**
1. Ouvrir l'application sur `http://localhost:3004`
2. Aller dans "Kanban"
3. Cliquer sur "Nouvelle réparation"
4. Remplir le formulaire avec des données valides
5. Cliquer sur "Créer"

#### **Étape 2 : Vérification**
1. ✅ Le dialogue se ferme
2. ✅ Un message de succès s'affiche
3. ✅ La réparation apparaît dans la colonne "Nouvelles"
4. ✅ La réparation est visible dans le Dashboard

### 📋 Checklist de vérification

- [ ] Tables Supabase créées
- [ ] Politiques RLS configurées
- [ ] Variables d'environnement définies
- [ ] Données de démonstration chargées
- [ ] Clients et appareils disponibles
- [ ] Connexion Supabase fonctionnelle
- [ ] Console sans erreurs

### 🚨 Erreurs courantes

#### **Erreur : "relation does not exist"**
- **Cause** : Table manquante dans Supabase
- **Solution** : Exécuter `database_setup.sql`

#### **Erreur : "permission denied"**
- **Cause** : Politique RLS trop restrictive
- **Solution** : Vérifier/créer les politiques d'insertion

#### **Erreur : "invalid input syntax"**
- **Cause** : Format de données incorrect
- **Solution** : Vérifier les types de données

#### **Erreur : "foreign key constraint"**
- **Cause** : Client ou appareil inexistant
- **Solution** : Charger les données de démonstration

### 📞 Support

Si le problème persiste :
1. Vérifier les logs dans la console du navigateur
2. Vérifier les logs Supabase dans le dashboard
3. Tester avec des données minimales
4. Vérifier la connexion réseau
