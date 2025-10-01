# 🎯 SOLUTION DÉFINITIVE ERREUR 406

## Problème
```
GET https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d13c66f5-7a1e-4099-abcc-feac8e291b17 406 (Not Acceptable)
```

## Causes identifiées
1. **Politiques RLS trop restrictives** ou en conflit
2. **Entrée manquante** dans la table `subscription_status`
3. **Contraintes de vérification** sur `subscription_type`
4. **Permissions insuffisantes** sur la table

## Solution complète

### 1. Exécuter le script SQL
```sql
-- Exécuter: SOLUTION_DEFINITIVE_406.sql
```

### 2. Vérifications automatiques
Le script effectue :
- ✅ Diagnostic complet de l'utilisateur
- ✅ Nettoyage des politiques RLS
- ✅ Création d'une politique permissive
- ✅ Création de l'entrée manquante
- ✅ Test de la requête originale
- ✅ Vérification des permissions

### 3. Résultat attendu
Après exécution, votre requête devrait fonctionner :
```javascript
// Cette requête devrait maintenant fonctionner
const { data, error } = await supabase
  .from('subscription_status')
  .select('is_active')
  .eq('user_id', 'd13c66f5-7a1e-4099-abcc-feac8e291b17')
  .single()
```

## Solutions alternatives si le problème persiste

### Option A: Requête REST directe avec en-têtes
```javascript
const response = await fetch(
  'https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d13c66f5-7a1e-4099-abcc-feac8e291b17',
  {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'apikey': 'YOUR_SUPABASE_ANON_KEY',
      'Authorization': 'Bearer YOUR_SUPABASE_ANON_KEY',
      'Prefer': 'return=minimal'
    }
  }
);
```

### Option B: Utiliser le client Supabase (recommandé)
```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://olrihggkxyksuofkesnk.supabase.co',
  'YOUR_SUPABASE_ANON_KEY'
)

// Requête optimisée
const { data, error } = await supabase
  .from('subscription_status')
  .select('is_active')
  .eq('user_id', 'd13c66f5-7a1e-4099-abcc-feac8e291b17')
  .maybeSingle() // Utiliser maybeSingle() au lieu de single()
```

### Option C: Vérification des en-têtes CORS
Si l'erreur persiste, vérifiez dans Supabase Dashboard :
1. **Settings > API**
2. **CORS origins** - Ajoutez votre domaine
3. **RLS policies** - Vérifiez que les politiques sont correctes

## Diagnostic avancé

### Vérifier les logs Supabase
1. Allez dans **Logs** dans le dashboard Supabase
2. Filtrez par `subscription_status`
3. Regardez les erreurs détaillées

### Tester avec Postman
```bash
GET https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d13c66f5-7a1e-4099-abcc-feac8e291b17
Headers:
- apikey: YOUR_SUPABASE_ANON_KEY
- Authorization: Bearer YOUR_SUPABASE_ANON_KEY
- Content-Type: application/json
```

## Prévention future

### 1. Créer un trigger automatique
```sql
-- Créer automatiquement une entrée subscription_status lors de l'inscription
CREATE OR REPLACE FUNCTION create_subscription_status_on_user_creation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.subscription_status (
        user_id, first_name, last_name, email, is_active, subscription_type, created_at, updated_at
    ) VALUES (
        NEW.id, 
        COALESCE(NEW.first_name, 'Utilisateur'),
        COALESCE(NEW.last_name, 'Anonyme'),
        NEW.email,
        false, -- Inactif par défaut
        'free',
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_subscription_status
    AFTER INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION create_subscription_status_on_user_creation();
```

### 2. Monitoring des erreurs
```javascript
// Ajouter un monitoring des erreurs 406
const checkSubscriptionStatus = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('subscription_status')
      .select('is_active')
      .eq('user_id', userId)
      .single();
    
    if (error) {
      console.error('Erreur subscription_status:', error);
      // Log l'erreur pour investigation
      return { is_active: false, error: error.message };
    }
    
    return data;
  } catch (err) {
    console.error('Erreur critique:', err);
    return { is_active: false, error: 'Erreur de connexion' };
  }
};
```

## Résumé
1. **Exécutez** `SOLUTION_DEFINITIVE_406.sql`
2. **Testez** votre requête originale
3. **Utilisez** le client Supabase pour éviter les problèmes d'en-têtes
4. **Configurez** un trigger automatique pour prévenir le problème
