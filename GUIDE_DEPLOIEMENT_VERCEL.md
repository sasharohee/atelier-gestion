# Guide de Déploiement Vercel - Atelier Gestion

## ✅ Configuration Corrigée

Votre application a été configurée pour fonctionner correctement sur Vercel. Voici les modifications apportées :

### 1. Configuration Vercel Simplifiée (`vercel.json`)
```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "buildCommand": "npm run build",
  "outputDirectory": "dist"
}
```

### 2. Configuration Vite Optimisée (`vite.config.ts`)
- Sourcemaps désactivées en production
- Chunking optimisé pour réduire la taille des bundles
- Configuration des dépendances optimisées

### 3. Package.json Corrigé
- Vite déplacé dans les dependencies
- Script `vercel-build` ajouté
- Configuration optimisée pour la production

## 🚀 Étapes de Déploiement

### Étape 1 : Variables d'Environnement Vercel

1. Aller sur [vercel.com](https://vercel.com)
2. Sélectionner votre projet
3. Aller dans **Settings** > **Environment Variables**
4. Ajouter les variables suivantes :

```
VITE_SUPABASE_URL = https://wlqyrmntfxwdvkzzsujv.supabase.co
VITE_SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8
```

### Étape 2 : Configuration Supabase

1. Aller sur [supabase.com](https://supabase.com)
2. Sélectionner votre projet
3. Aller dans **Settings** > **API**
4. Dans **Additional Allowed Origins**, ajouter votre domaine Vercel :
   ```
   https://votre-projet.vercel.app
   https://votre-projet.vercel.app/*
   ```

### Étape 3 : Déploiement

#### Option A : Via GitHub (Recommandé)
1. Pousser vos modifications sur GitHub
2. Vercel se redéploiera automatiquement

#### Option B : Via Vercel CLI
```bash
# Installer Vercel CLI
npm i -g vercel

# Se connecter
vercel login

# Déployer
vercel --prod
```

## 🔍 Diagnostic et Tests

### Test Local de Production
```bash
# Build de production
npm run build

# Tester le build
npm run preview
```

### Script de Diagnostic
```bash
# Exécuter le diagnostic
node diagnostic-vercel.js
```

## 🐛 Résolution des Problèmes

### Problème 1 : Erreur 404
**Cause :** Problème de routing
**Solution :** Vérifier que `vercel.json` est correctement configuré

### Problème 2 : Erreur de Build
**Cause :** Variables d'environnement manquantes
**Solution :** Vérifier les variables dans Vercel Dashboard

### Problème 3 : Erreur CORS
**Cause :** Domaine non autorisé dans Supabase
**Solution :** Ajouter le domaine Vercel dans Supabase

### Problème 4 : Erreur de Connexion Supabase
**Cause :** Variables d'environnement incorrectes
**Solution :** Vérifier les clés Supabase

## 📊 Monitoring

### Vérifier les Logs Vercel
```bash
# Voir les logs en temps réel
vercel logs

# Voir les logs d'un déploiement spécifique
vercel logs --deployment-url=https://votre-projet.vercel.app
```

### Vérifier les Performances
1. Aller dans Vercel Dashboard
2. Sélectionner votre projet
3. Aller dans **Analytics** pour voir les performances

## 🔧 Optimisations Supplémentaires

### 1. Optimisation des Images
- Utiliser des formats modernes (WebP, AVIF)
- Optimiser la taille des images
- Utiliser le lazy loading

### 2. Optimisation du Code
- Utiliser le code splitting
- Optimiser les imports
- Minimiser les bundles

### 3. Cache et Performance
- Configurer les headers de cache
- Utiliser le CDN Vercel
- Optimiser les requêtes API

## 📱 Test sur Mobile

Après déploiement, tester sur :
- [ ] Desktop (Chrome, Firefox, Safari)
- [ ] Mobile (iOS Safari, Android Chrome)
- [ ] Tablette (iPad, Android)

## 🆘 Support

Si les problèmes persistent :

1. **Vérifier les logs Vercel** : `vercel logs`
2. **Tester en local** : `npm run preview`
3. **Vérifier Supabase** : Dashboard Supabase
4. **Contacter le support** : Support Vercel

## ✅ Checklist de Déploiement

- [ ] Variables d'environnement configurées
- [ ] Domaine autorisé dans Supabase
- [ ] Build local réussi
- [ ] Déploiement Vercel réussi
- [ ] Test de l'application
- [ ] Test sur mobile
- [ ] Vérification des performances

## 🎉 Déploiement Réussi !

Votre application Atelier Gestion est maintenant prête pour la production sur Vercel !
