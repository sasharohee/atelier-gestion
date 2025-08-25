# Guide de Correction - Erreur "Invalid Refresh Token: Refresh Token Not Found"

## Problème Identifié

L'erreur se produit lors de l'authentification Supabase avec le message :
```
AuthApiError: Invalid Refresh Token: Refresh Token Not Found
```

Cette erreur indique que le token de rafraîchissement stocké dans le navigateur est invalide, expiré ou corrompu.

## Cause Racine

1. **Token expiré** : Le token de rafraîchissement a dépassé sa durée de vie
2. **Données corrompues** : Le localStorage contient des données d'authentification corrompues
3. **Session invalide** : La session utilisateur n'est plus valide côté serveur
4. **Conflit de stockage** : Plusieurs clés de stockage pour l'authentification

## Solution Implémentée

### 1. Fonctions de Nettoyage dans `supabase.ts`

```typescript
// Fonction pour nettoyer l'état d'authentification
export const clearAuthState = () => {
  try {
    // Nettoyer le localStorage
    localStorage.removeItem('atelier-auth-token');
    localStorage.removeItem('supabase.auth.token');
    localStorage.removeItem('pendingSignupEmail');
    localStorage.removeItem('confirmationToken');
    localStorage.removeItem('pendingUserData');
    
    // Nettoyer sessionStorage
    sessionStorage.removeItem('atelier-auth-token');
    sessionStorage.removeItem('supabase.auth.token');
    
    console.log('🧹 État d\'authentification nettoyé');
  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
  }
};

// Fonction pour vérifier et corriger l'état d'authentification
export const checkAndFixAuthState = async () => {
  try {
    const { data: { user }, error } = await supabase.auth.getUser();
    
    if (error) {
      console.log('⚠️ Erreur d\'authentification détectée:', error.message);
      
      // Si c'est une erreur de token invalide, nettoyer et réinitialiser
      if (error.message.includes('Invalid Refresh Token') || 
          error.message.includes('Refresh Token Not Found')) {
        console.log('🔄 Token invalide détecté, nettoyage en cours...');
        clearAuthState();
        return false;
      }
    }
    
    return !!user;
  } catch (error) {
    console.error('❌ Erreur lors de la vérification de l\'authentification:', error);
    clearAuthState();
    return false;
  }
};
```

### 2. Amélioration du Hook `useAuth`

```typescript
export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState<string | null>(null);

  useEffect(() => {
    const getCurrentUser = async () => {
      try {
        // Vérifier et corriger l'état d'authentification
        const isAuthValid = await checkAndFixAuthState();
        
        if (!isAuthValid) {
          console.log('🔄 État d\'authentification invalide, nettoyage effectué');
          setUser(null);
          setLoading(false);
          return;
        }

        const { data: { user }, error } = await supabase.auth.getUser();
        
        if (error) {
          // Si c'est une erreur de token, nettoyer l'état
          if (error.message.includes('Invalid Refresh Token') || 
              error.message.includes('Refresh Token Not Found')) {
            console.log('🔄 Token invalide, nettoyage de l\'état...');
            clearAuthState();
            setUser(null);
            setAuthError('Session expirée. Veuillez vous reconnecter.');
          } else {
            setAuthError(error.message);
          }
        } else {
          setUser(user);
          setAuthError(null);
        }
      } catch (error) {
        setUser(null);
        setAuthError('Erreur inattendue lors de l\'authentification');
      } finally {
        setLoading(false);
      }
    };

    getCurrentUser();
  }, []);

  return {
    user,
    loading,
    authError,
    isAuthenticated: !!user,
    resetAuth
  };
};
```

### 3. Composant de Gestion d'Erreur `AuthErrorHandler`

```typescript
export const AuthErrorHandler: React.FC<AuthErrorHandlerProps> = ({ children }) => {
  const { authError, resetAuth, loading } = useAuth();

  if (!authError) {
    return <>{children}</>;
  }

  const handleReset = async () => {
    await resetAuth();
  };

  return (
    <Box sx={{ /* styles */ }}>
      <Paper elevation={24}>
        <Alert severity="error">
          <AlertTitle>Erreur d'Authentification</AlertTitle>
          {authError}
        </Alert>
        
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button
            variant="contained"
            onClick={handleReset}
            disabled={loading}
            startIcon={<Refresh />}
          >
            {loading ? 'Réinitialisation...' : 'Réinitialiser'}
          </Button>

          <Button
            variant="outlined"
            onClick={() => window.location.href = '/auth'}
            startIcon={<Login />}
          >
            Se Connecter
          </Button>
        </Box>
      </Paper>
    </Box>
  );
};
```

## Flux de Fonctionnement

### 1. Détection Automatique
- Le hook `useAuth` vérifie automatiquement l'état d'authentification
- Si une erreur de token est détectée, le nettoyage est effectué automatiquement

### 2. Nettoyage des Données
- Suppression de toutes les clés d'authentification du localStorage
- Suppression des données de session
- Nettoyage des données en attente

### 3. Interface Utilisateur
- Affichage d'une modal d'erreur avec options de résolution
- Bouton "Réinitialiser" pour nettoyer et recharger
- Bouton "Se Connecter" pour aller à la page d'authentification

## Tests Recommandés

### Test 1 : Simulation d'Erreur de Token
```javascript
// Dans la console du navigateur
localStorage.setItem('atelier-auth-token', 'invalid-token');
window.location.reload();
```

### Test 2 : Nettoyage Manuel
```javascript
// Nettoyer manuellement l'état
localStorage.clear();
sessionStorage.clear();
window.location.reload();
```

### Test 3 : Vérification de la Détection
```javascript
// Vérifier que l'erreur est détectée
const { checkAndFixAuthState } = await import('./lib/supabase');
const result = await checkAndFixAuthState();
console.log('État d\'authentification:', result);
```

## Vérification de la Correction

### 1. Vérifier les Logs
```javascript
// Dans la console du navigateur
// Devrait afficher :
// ⚠️ Erreur d'authentification détectée: Invalid Refresh Token
// 🔄 Token invalide détecté, nettoyage en cours...
// 🧹 État d'authentification nettoyé
```

### 2. Vérifier l'Interface
- [ ] Modal d'erreur s'affiche correctement
- [ ] Bouton "Réinitialiser" fonctionne
- [ ] Bouton "Se Connecter" redirige vers `/auth`
- [ ] L'erreur disparaît après réinitialisation

### 3. Vérifier le Nettoyage
```javascript
// Vérifier que le localStorage est nettoyé
console.log('localStorage:', Object.keys(localStorage));
console.log('sessionStorage:', Object.keys(sessionStorage));
```

## Prévention Future

### 1. Configuration Supabase Améliorée
```typescript
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    storageKey: 'atelier-auth-token',
    // Ajouter une durée de session plus courte pour éviter les tokens expirés
    flowType: 'pkce'
  }
});
```

### 2. Surveillance Continue
```typescript
// Ajouter une surveillance périodique de l'état d'authentification
useEffect(() => {
  const interval = setInterval(async () => {
    const isValid = await checkAndFixAuthState();
    if (!isValid && user) {
      setAuthError('Session expirée. Veuillez vous reconnecter.');
    }
  }, 5 * 60 * 1000); // Vérifier toutes les 5 minutes

  return () => clearInterval(interval);
}, [user]);
```

### 3. Gestion des Erreurs Réseau
```typescript
// Ajouter une gestion des erreurs de réseau
const handleNetworkError = (error: any) => {
  if (error.message.includes('Network Error')) {
    setAuthError('Erreur de connexion. Vérifiez votre connexion internet.');
  }
};
```

## Résolution Complète

La correction implémentée résout le problème en :

1. **Détectant automatiquement** les erreurs de token invalide
2. **Nettoyant automatiquement** l'état d'authentification corrompu
3. **Affichant une interface claire** pour guider l'utilisateur
4. **Permettant une récupération facile** via les boutons d'action

L'utilisateur peut maintenant résoudre facilement les problèmes d'authentification sans avoir à vider manuellement le cache du navigateur.
