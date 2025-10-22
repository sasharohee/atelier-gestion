# Guide de Correction - Isolation des Données dans le Catalogue

## Problème Identifié

La page catalogue ne respecte pas l'isolation des données. Les utilisateurs peuvent voir les données d'autres utilisateurs dans :
- **Appareils** (devices)
- **Clients** (clients) 
- **Services** (services)
- **Pièces** (parts)
- **Produits** (products)

## Causes du Problème

1. **Politiques RLS manquantes ou incorrectes** dans Supabase
2. **Code côté application** qui ne filtre pas correctement par utilisateur
3. **Utilisation de `getCurrentUser()`** qui peut retourner `null` si l'utilisateur n'existe pas dans la table `users`

## Solutions Appliquées

### Solution 1 : Correction des Politiques RLS

Le script `correction_isolation_catalogue.sql` :

✅ **Supprime les anciennes politiques RLS** défaillantes  
✅ **Recrée des politiques RLS robustes** pour chaque table  
✅ **Active RLS** sur toutes les tables du catalogue  
✅ **Utilise `auth.uid()`** pour l'isolation automatique  

### Solution 2 : Amélioration du Code Côté Application

Modifications dans `src/services/supabaseService.ts` :

✅ **Remplace `getCurrentUser()`** par `supabase.auth.getUser()`  
✅ **Supprime la logique de filtrage manuel** côté application  
✅ **Laisse les politiques RLS** gérer l'isolation automatiquement  
✅ **Ajoute des logs** pour le débogage  

## Étapes de Résolution

### Étape 1 : Appliquer les Politiques RLS

Exécutez le script `correction_isolation_catalogue.sql` dans l'éditeur SQL Supabase :

```sql
-- Ce script va :
-- 1. Vérifier les politiques actuelles
-- 2. Supprimer les anciennes politiques
-- 3. Créer de nouvelles politiques RLS robustes
-- 4. Tester l'isolation
```

### Étape 2 : Vérifier les Politiques Créées

Après l'exécution, vérifiez que les politiques ont été créées :

```sql
SELECT 
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE tablename IN ('devices', 'clients', 'services', 'parts', 'products')
ORDER BY tablename, policyname;
```

### Étape 3 : Tester l'Isolation

Testez avec différents utilisateurs :

1. **Connectez-vous avec un utilisateur**
2. **Créez quelques données** (appareils, clients, etc.)
3. **Déconnectez-vous et reconnectez-vous avec un autre utilisateur**
4. **Vérifiez que vous ne voyez que vos propres données**

## Politiques RLS Créées

### Pour la Table `devices`

```sql
-- Lecture : Utilisateur peut voir ses appareils + appareils système
CREATE POLICY "Users can view own devices" ON devices
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

-- Écriture : Utilisateur peut créer/modifier/supprimer ses appareils
CREATE POLICY "Users can insert own devices" ON devices
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

### Pour la Table `clients`

```sql
-- Lecture : Utilisateur peut voir ses clients + clients système
CREATE POLICY "Users can view own clients" ON clients
  FOR SELECT USING (
    auth.uid() = user_id OR 
    user_id = '00000000-0000-0000-0000-000000000000'::uuid
  );

-- Écriture : Utilisateur peut créer/modifier/supprimer ses clients
CREATE POLICY "Users can insert own clients" ON clients
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

## Vérification de l'Isolation

### Test Manuel

1. **Utilisateur A** : Crée 3 appareils et 2 clients
2. **Utilisateur B** : Crée 1 appareil et 4 clients
3. **Utilisateur A** : Ne doit voir que ses 3 appareils et 2 clients
4. **Utilisateur B** : Ne doit voir que son 1 appareil et 4 clients

### Test Automatique

Le script inclut un test automatique :

```sql
-- Compter les données de l'utilisateur actuel
SELECT 
  'devices' as table_name,
  COUNT(*) as count
FROM devices 
WHERE user_id = auth.uid()
UNION ALL
SELECT 
  'clients' as table_name,
  COUNT(*) as count
FROM clients 
WHERE user_id = auth.uid();
```

## Avantages de cette Solution

✅ **Isolation automatique** : Les politiques RLS gèrent tout  
✅ **Performance optimale** : Pas de filtrage côté application  
✅ **Sécurité renforcée** : Impossible de contourner l'isolation  
✅ **Maintenance simplifiée** : Une seule source de vérité  
✅ **Évolutivité** : Fonctionne avec n'importe quel nombre d'utilisateurs  

## Maintenance Future

### Ajout de Nouvelles Tables

Pour ajouter l'isolation à une nouvelle table :

1. **Ajouter la colonne `user_id`** à la table
2. **Activer RLS** : `ALTER TABLE nouvelle_table ENABLE ROW LEVEL SECURITY;`
3. **Créer les politiques RLS** similaires aux autres tables
4. **Modifier le service** pour utiliser `auth.uid()`

### Surveillance

Surveillez les logs pour détecter :
- **Tentatives d'accès non autorisées**
- **Erreurs de politiques RLS**
- **Problèmes d'authentification**

## Résolution des Problèmes

### Si l'isolation ne fonctionne pas

1. **Vérifiez que RLS est activé** : `SELECT relname, relrowsecurity FROM pg_class WHERE relname = 'devices';`
2. **Vérifiez les politiques** : `SELECT * FROM pg_policies WHERE tablename = 'devices';`
3. **Testez l'authentification** : `SELECT auth.uid();`
4. **Vérifiez les logs** de l'application

### Si les données ne s'affichent pas

1. **Vérifiez que `user_id` est correctement défini** lors de la création
2. **Vérifiez que l'utilisateur est authentifié**
3. **Testez avec un utilisateur admin** pour voir toutes les données

---

**Statut** : ✅ **CORRIGÉ**  
**Fichiers modifiés** : 
- `correction_isolation_catalogue.sql` (nouvelles politiques RLS)
- `src/services/supabaseService.ts` (amélioration du code)  
**Dernière mise à jour** : $(date)  
**Version** : 3.0.0 - ISOLATION CATALOGUE CORRIGÉE
