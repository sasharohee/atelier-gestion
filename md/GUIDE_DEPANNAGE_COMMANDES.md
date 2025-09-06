# 🔧 Guide de Dépannage - Création de Commandes

## 🚨 Problème Identifié
Les nouvelles commandes ne s'ajoutent pas à la liste après création.

## 🔍 Diagnostic

### 1. **Vérifier les Tables SQL**
Exécutez le script de diagnostic dans Supabase SQL Editor :

```sql
-- Copiez le contenu du fichier tables/diagnostic_commandes.sql
-- Exécutez-le dans l'éditeur SQL de Supabase
```

### 2. **Vérifier la Console du Navigateur**
1. Ouvrez les outils de développement (F12)
2. Allez dans l'onglet "Console"
3. Créez une nouvelle commande
4. Vérifiez s'il y a des erreurs

### 3. **Vérifier l'Authentification**
Assurez-vous que vous êtes connecté à l'application.

## 🛠️ Solutions

### Solution 1 : Déployer les Tables SQL

Si les tables n'existent pas :

1. **Aller sur Supabase Dashboard**
   - [https://supabase.com/dashboard](https://supabase.com/dashboard)
   - Sélectionner votre projet

2. **Ouvrir SQL Editor**
   - Cliquer sur "SQL Editor" dans le menu
   - Créer une nouvelle requête

3. **Exécuter le Script de Création**
   ```sql
   -- Copier le contenu de tables/creation_tables_commandes_isolation.sql
   -- Cliquer sur "Run"
   ```

4. **Vérifier le Déploiement**
   ```sql
   -- Copier le contenu de tables/verification_isolation_commandes.sql
   -- Cliquer sur "Run"
   ```

### Solution 2 : Vérifier les Politiques RLS

Si les tables existent mais les commandes ne s'affichent pas :

1. **Vérifier le Workshop ID**
   ```sql
   SELECT key, value FROM system_settings WHERE key = 'workshop_id';
   ```

2. **Vérifier les Politiques RLS**
   ```sql
   SELECT tablename, policyname, cmd, qual 
   FROM pg_policies 
   WHERE tablename = 'orders';
   ```

3. **Recréer les Politiques si Nécessaire**
   ```sql
   -- Supprimer les anciennes politiques
   DROP POLICY IF EXISTS orders_select_policy ON orders;
   DROP POLICY IF EXISTS orders_insert_policy ON orders;
   DROP POLICY IF EXISTS orders_update_policy ON orders;
   DROP POLICY IF EXISTS orders_delete_policy ON orders;
   
   -- Recréer les politiques
   CREATE POLICY orders_select_policy ON orders
       FOR SELECT USING (
           workshop_id = (
               SELECT value::UUID FROM system_settings 
               WHERE key = 'workshop_id' 
               LIMIT 1
           )
       );
   
   CREATE POLICY orders_insert_policy ON orders
       FOR INSERT WITH CHECK (
           workshop_id = (
               SELECT value::UUID FROM system_settings 
               WHERE key = 'workshop_id' 
               LIMIT 1
           )
       );
   ```

### Solution 3 : Vérifier les Triggers

Si les triggers d'isolation ne fonctionnent pas :

1. **Vérifier les Triggers**
   ```sql
   SELECT trigger_name, event_object_table 
   FROM information_schema.triggers 
   WHERE event_object_table = 'orders';
   ```

2. **Recréer les Triggers si Nécessaire**
   ```sql
   -- Supprimer les anciens triggers
   DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
   
   -- Recréer le trigger
   CREATE TRIGGER set_order_isolation_trigger
       BEFORE INSERT ON orders
       FOR EACH ROW
       EXECUTE FUNCTION set_order_isolation();
   ```

### Solution 4 : Test Manuel

Pour tester si l'insertion fonctionne :

1. **Test Direct dans SQL**
   ```sql
   INSERT INTO orders (
       order_number,
       supplier_name,
       supplier_email,
       order_date,
       status,
       total_amount,
       notes
   ) VALUES (
       'TEST-001',
       'Fournisseur Test',
       'test@example.com',
       CURRENT_DATE,
       'pending',
       0,
       'Test manuel'
   );
   ```

2. **Vérifier l'Insertion**
   ```sql
   SELECT * FROM orders WHERE order_number = 'TEST-001';
   ```

## 🔧 Corrections du Code

### 1. **Vérifier le Service**

Le service a été mis à jour pour utiliser Supabase au lieu des données mock. Vérifiez que le fichier `src/services/orderService.ts` contient bien :

```typescript
import { supabase } from '../lib/supabase';
```

### 2. **Vérifier les Imports**

Assurez-vous que tous les imports sont corrects :

```typescript
// Dans OrderTracking.tsx
import orderService from '../../../services/orderService';
```

### 3. **Vérifier la Gestion d'Erreurs**

Ajoutez des logs pour déboguer :

```typescript
const handleSaveOrder = async (updatedOrder: Order) => {
  try {
    console.log('🔄 Sauvegarde de la commande...', updatedOrder);
    
    if (updatedOrder.id) {
      const result = await orderService.updateOrder(updatedOrder.id, updatedOrder);
      console.log('✅ Commande mise à jour:', result);
    } else {
      const newOrder = await orderService.createOrder(updatedOrder);
      console.log('✅ Nouvelle commande créée:', newOrder);
    }
    
    // Recharger les commandes
    await loadOrders();
    
  } catch (error) {
    console.error('❌ Erreur lors de la sauvegarde:', error);
    // Afficher une notification d'erreur
  }
};
```

## 🧪 Tests de Validation

### Test 1 : Création Simple
1. Créer une commande avec seulement :
   - Numéro de commande
   - Nom du fournisseur
   - Date de commande
2. Vérifier qu'elle apparaît dans la liste

### Test 2 : Création Complète
1. Créer une commande avec tous les champs
2. Ajouter des articles
3. Vérifier que le total se calcule

### Test 3 : Modification
1. Modifier une commande existante
2. Vérifier que les changements sont sauvegardés

### Test 4 : Suppression
1. Supprimer une commande
2. Vérifier qu'elle disparaît de la liste

## 📋 Checklist de Résolution

- [ ] Tables SQL créées dans Supabase
- [ ] Politiques RLS configurées
- [ ] Triggers d'isolation fonctionnels
- [ ] Workshop ID configuré
- [ ] Service mis à jour pour utiliser Supabase
- [ ] Imports corrects dans le code
- [ ] Gestion d'erreurs ajoutée
- [ ] Tests de validation passés

## 🆘 Si le Problème Persiste

### 1. **Vérifier les Logs Supabase**
- Aller dans Supabase Dashboard
- Cliquer sur "Logs" dans le menu
- Vérifier les erreurs SQL

### 2. **Vérifier l'Authentification**
- S'assurer que l'utilisateur est connecté
- Vérifier que le token d'authentification est valide

### 3. **Vérifier les Permissions**
- Vérifier que l'utilisateur a les bonnes permissions
- Vérifier que les politiques RLS permettent l'accès

### 4. **Contacter le Support**
Si le problème persiste, fournir :
- Les logs d'erreur de la console
- Le résultat du script de diagnostic
- Les étapes pour reproduire le problème

## 🎯 Résultat Attendu

Après application des corrections :
- ✅ Les nouvelles commandes s'ajoutent à la liste
- ✅ Les modifications sont sauvegardées
- ✅ Les suppressions fonctionnent
- ✅ L'isolation des données fonctionne
- ✅ Les statistiques se mettent à jour

