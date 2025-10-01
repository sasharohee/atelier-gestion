# 🔧 Guide de Correction - Erreur 403 Forbidden

## 🚨 Problème Identifié

**Erreur** : `403 (Forbidden)` lors de la création d'URLs personnalisées
**Message** : `new row violates row-level security policy for table "technician_custom_urls"`

## 🔍 Cause du Problème

L'erreur indique que les **politiques RLS (Row Level Security)** empêchent la création d'URLs personnalisées. Cela peut être dû à :

1. **Utilisateur non authentifié** : L'utilisateur n'est pas connecté
2. **Politiques RLS trop restrictives** : Les politiques bloquent l'insertion
3. **Problème de session** : La session Supabase a expiré
4. **Configuration RLS incorrecte** : Les politiques ne sont pas bien configurées

## ✅ Solutions

### Solution 1: Corriger les Politiques RLS (Recommandée)

1. **Ouvrir le dashboard Supabase**
2. **Aller dans l'éditeur SQL**
3. **Exécuter le script** `FIX_RLS_QUOTE_REQUESTS.sql`

Ce script :
- ✅ Supprime les anciennes politiques conflictuelles
- ✅ Crée des politiques plus permissives
- ✅ Ajoute des politiques de test temporaires
- ✅ Permet toutes les opérations pour tester

### Solution 2: Désactiver Temporairement RLS

Si la solution 1 ne fonctionne pas, désactiver temporairement RLS :

```sql
-- Désactiver RLS temporairement
ALTER TABLE technician_custom_urls DISABLE ROW LEVEL SECURITY;
ALTER TABLE quote_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE quote_request_attachments DISABLE ROW LEVEL SECURITY;
```

⚠️ **Attention** : Cette solution désactive la sécurité. À utiliser uniquement pour tester.

### Solution 3: Vérifier l'Authentification

1. **Exécuter le script de diagnostic** `DIAGNOSTIC_AUTH_QUOTE_REQUESTS.sql`
2. **Vérifier que l'utilisateur est connecté** :
   - Aller dans la console du navigateur
   - Vérifier que `auth.uid()` retourne un UUID
   - Vérifier que la session n'a pas expiré

## 🧪 Tests de Vérification

### Test 1: Vérifier l'Authentification
```javascript
// Dans la console du navigateur
import { supabase } from './src/lib/supabase';

// Vérifier l'utilisateur connecté
const { data: { user } } = await supabase.auth.getUser();
console.log('Utilisateur connecté:', user);

// Vérifier la session
const { data: { session } } = await supabase.auth.getSession();
console.log('Session active:', session);
```

### Test 2: Tester la Création d'URL
1. **Aller dans "Demandes de Devis"**
2. **Cliquer sur "Ajouter une URL"**
3. **Saisir un nom d'URL** (ex: "test-123")
4. **Cliquer sur "Ajouter"**
5. **Vérifier qu'aucune erreur 403 n'apparaît**

### Test 3: Vérifier les Politiques RLS
```sql
-- Vérifier les politiques actives
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'technician_custom_urls';
```

## 🔧 Corrections Spécifiques

### 1. **Politiques RLS Corrigées**
```sql
-- Politique pour la création d'URLs
CREATE POLICY "technician_custom_urls_insert_own" ON technician_custom_urls
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

-- Politique de test (plus permissive)
CREATE POLICY "test_technician_custom_urls_all" ON technician_custom_urls
    FOR ALL USING (true) WITH CHECK (true);
```

### 2. **Vérification de l'Authentification**
```typescript
// Dans le service, ajouter une vérification
static async createCustomUrl(technicianId: string, customUrl: string): Promise<any> {
  try {
    // Vérifier que l'utilisateur est authentifié
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      console.error('Utilisateur non authentifié:', authError);
      return null;
    }
    
    if (user.id !== technicianId) {
      console.error('ID utilisateur ne correspond pas');
      return null;
    }
    
    // Continuer avec la création...
  } catch (error) {
    console.error('Erreur lors de la création de l\'URL:', error);
    return null;
  }
}
```

## 📊 Diagnostic Avancé

### Vérifier les Logs Supabase
1. **Aller dans le dashboard Supabase**
2. **Logs > API Logs**
3. **Chercher les erreurs 403**
4. **Analyser les détails de l'erreur**

### Vérifier les Variables d'Environnement
```bash
# Vérifier que les variables sont correctes
echo $VITE_SUPABASE_URL
echo $VITE_SUPABASE_ANON_KEY
```

## ✅ Résultat Attendu

Après correction :
- ✅ **Aucune erreur 403** lors de la création d'URLs
- ✅ **URLs créées avec succès** dans la base de données
- ✅ **Politiques RLS fonctionnelles** et sécurisées
- ✅ **Flux complet opérationnel**

## 🚨 Solutions d'Urgence

Si rien ne fonctionne :

1. **Désactiver complètement RLS** (temporaire)
2. **Utiliser un utilisateur admin** pour créer les URLs
3. **Vérifier la configuration Supabase** dans le dashboard

## 📝 Notes Importantes

- **Sécurité** : Réactiver RLS après les tests
- **Backup** : Sauvegarder les données avant les modifications
- **Logs** : Surveiller les logs pour d'autres erreurs
- **Performance** : Les politiques RLS peuvent impacter les performances
