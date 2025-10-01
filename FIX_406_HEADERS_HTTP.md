# 🔧 CORRECTION ERREUR 406 - EN-TÊTES HTTP

## Problème identifié
L'erreur 406 (Not Acceptable) sur la requête Supabase peut être causée par des en-têtes HTTP manquants ou incorrects.

## Solution 1: En-têtes HTTP requis

### Pour les requêtes REST API Supabase, ajoutez ces en-têtes :

```javascript
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'apikey': 'YOUR_SUPABASE_ANON_KEY',
  'Authorization': 'Bearer YOUR_SUPABASE_ANON_KEY',
  'Prefer': 'return=minimal'
};
```

### Exemple de requête corrigée :

```javascript
// Au lieu de :
fetch('https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d4535dc5-9797-48f8-9c60-844ab6468ff8')

// Utilisez :
fetch('https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.d4535dc5-9797-48f8-9c60-844ab6468ff8', {
  method: 'GET',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'apikey': 'YOUR_SUPABASE_ANON_KEY',
    'Authorization': 'Bearer YOUR_SUPABASE_ANON_KEY'
  }
})
```

## Solution 2: Utiliser le client Supabase (Recommandé)

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://olrihggkxyksuofkesnk.supabase.co',
  'YOUR_SUPABASE_ANON_KEY'
)

// Requête corrigée
const { data, error } = await supabase
  .from('subscription_status')
  .select('is_active')
  .eq('user_id', 'd4535dc5-9797-48f8-9c60-844ab6468ff8')
  .single()
```

## Solution 3: Vérification des permissions

1. **Vérifiez que l'utilisateur est authentifié**
2. **Vérifiez les politiques RLS**
3. **Vérifiez que l'entrée existe dans la table**

## Solution 4: Format de requête alternatif

```javascript
// Format alternatif avec paramètres encodés
const userId = encodeURIComponent('d4535dc5-9797-48f8-9c60-844ab6468ff8')
const url = `https://olrihggkxyksuofkesnk.supabase.co/rest/v1/subscription_status?select=is_active&user_id=eq.${userId}`
```

## Diagnostic

Si l'erreur persiste après ces corrections :

1. **Exécutez le script SQL** `FIX_406_ERROR_SUBSCRIPTION_STATUS.sql`
2. **Vérifiez les logs Supabase** dans le dashboard
3. **Testez avec Postman** ou un autre client HTTP
4. **Vérifiez la configuration CORS** dans Supabase

## En-têtes de débogage

Ajoutez ces en-têtes pour plus d'informations :

```javascript
const debugHeaders = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'apikey': 'YOUR_SUPABASE_ANON_KEY',
  'Authorization': 'Bearer YOUR_SUPABASE_ANON_KEY',
  'X-Client-Info': 'supabase-js-web',
  'User-Agent': 'supabase-js/2.0.0'
}
```
