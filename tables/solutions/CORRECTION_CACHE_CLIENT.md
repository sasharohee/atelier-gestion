# 🔧 CORRECTION CACHE CLIENT - ERREUR JWT 403

## 🚨 **Problème identifié**
L'erreur `User from sub claim in JWT does not exist` avec des erreurs 403 (Forbidden) indique que le token JWT côté client est corrompu ou invalide.

## 🛠️ **Solutions à appliquer**

### 1. **Exécuter le script SQL** (PRIORITÉ 1)
Exécutez le script `CORRECTION_ERREUR_JWT_403.sql` dans l'éditeur SQL de Supabase.

### 2. **Nettoyer le cache côté client** (PRIORITÉ 2)

#### **Option A : Nettoyage complet du navigateur**
1. Ouvrez les **Outils de développement** (F12)
2. Allez dans l'onglet **Application** (ou **Storage**)
3. Dans la section **Local Storage**, supprimez toutes les clés liées à Supabase
4. Dans la section **Session Storage**, supprimez toutes les clés liées à Supabase
5. Dans la section **Cookies**, supprimez tous les cookies du domaine Supabase
6. **Rafraîchir la page** (Ctrl+F5 ou Cmd+Shift+R)

#### **Option B : Nettoyage via console**
Ouvrez la console du navigateur et exécutez :
```javascript
// Nettoyer le localStorage
Object.keys(localStorage).forEach(key => {
  if (key.includes('supabase') || key.includes('sb-')) {
    localStorage.removeItem(key);
  }
});

// Nettoyer le sessionStorage
Object.keys(sessionStorage).forEach(key => {
  if (key.includes('supabase') || key.includes('sb-')) {
    sessionStorage.removeItem(key);
  }
});

// Forcer la déconnexion
if (window.supabase) {
  window.supabase.auth.signOut();
}

// Recharger la page
window.location.reload();
```

#### **Option C : Mode incognito**
1. Ouvrez un **nouvel onglet en mode incognito/privé**
2. Naviguez vers votre application
3. Testez la connexion avec `sasha4@yopmail.com`

### 3. **Vérifier la configuration Supabase**

#### **Vérifier les variables d'environnement**
Assurez-vous que les variables suivantes sont correctes :
```env
VITE_SUPABASE_URL=https://olrihggkxyksuofkesnk.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### **Vérifier la configuration Supabase**
Dans `src/lib/supabase.ts`, vérifiez que la configuration est correcte :
```typescript
const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true
    }
  }
);
```

## 🧪 **Test après correction**

1. **Exécutez le script SQL** `CORRECTION_ERREUR_JWT_403.sql`
2. **Nettoyez le cache** du navigateur (Option A, B ou C)
3. **Reconnectez-vous** avec `sasha4@yopmail.com`
4. **Vérifiez** que l'utilisateur apparaît dans `subscription_status`

## 🔍 **Diagnostic supplémentaire**

Si le problème persiste, vérifiez dans la console du navigateur :
- Les erreurs de réseau (onglet Network)
- Les cookies et tokens (onglet Application)
- Les logs d'authentification Supabase

## 📋 **Ordre d'exécution**

1. ✅ **Script SQL** : `CORRECTION_ERREUR_JWT_403.sql`
2. ✅ **Nettoyage cache** : Option A, B ou C
3. ✅ **Test reconnexion** : Se reconnecter avec `sasha4@yopmail.com`
4. ✅ **Vérification** : L'utilisateur doit apparaître dans `subscription_status`

## 🎯 **Résultat attendu**

Après ces corrections :
- ✅ Plus d'erreurs 403 (Forbidden)
- ✅ Plus d'erreurs "User from sub claim in JWT does not exist"
- ✅ L'utilisateur peut se connecter normalement
- ✅ L'utilisateur apparaît dans `subscription_status`
- ✅ L'application fonctionne correctement
