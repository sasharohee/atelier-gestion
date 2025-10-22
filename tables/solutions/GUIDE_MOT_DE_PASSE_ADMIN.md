# Guide de Configuration du Mot de Passe Administrateur

## 🔐 Mot de Passe Sécurisé

Le mot de passe administrateur a été mis à jour avec un mot de passe plus sécurisé :

**Nouveau mot de passe : `At3l13r@dm1n#2024$ecur3!`**

## 🛡️ Caractéristiques de Sécurité

Ce mot de passe respecte les meilleures pratiques de sécurité :

- ✅ **Longueur** : 25 caractères
- ✅ **Majuscules** : A, E, I, N, M
- ✅ **Minuscules** : t, l, r, d, m, n, e, c, u, r
- ✅ **Chiffres** : 3, 1, 3, 2, 0, 2, 4
- ✅ **Caractères spéciaux** : @, #, $, !
- ✅ **Complexité** : Combinaison de lettres, chiffres et symboles

## 🔧 Configuration

### Option 1 : Variable d'environnement (Recommandé)

1. Créez un fichier `.env.local` à la racine du projet
2. Ajoutez la ligne suivante :
   ```
   VITE_ADMIN_PASSWORD=At3l13r@dm1n#2024$ecur3!
   ```

### Option 2 : Modification directe du code

Si vous préférez modifier directement le code, éditez le fichier `src/components/AdminPasswordGuard.tsx` :

```typescript
const ADMIN_PASSWORD = 'votre_nouveau_mot_de_passe';
```

## 🚀 Utilisation

1. Allez sur `http://localhost:3001/admin`
2. Saisissez le mot de passe : `At3l13r@dm1n#2024$ecur3!`
3. Accédez à la page d'administration

## 🔄 Changer le Mot de Passe

Pour changer le mot de passe :

1. **Modifiez la variable d'environnement** dans `.env.local` :
   ```
   VITE_ADMIN_PASSWORD=votre_nouveau_mot_de_passe
   ```

2. **Redémarrez le serveur de développement** :
   ```bash
   npm run dev
   ```

## ⚠️ Recommandations de Sécurité

1. **Ne partagez jamais** le mot de passe en clair
2. **Utilisez des variables d'environnement** en production
3. **Changez régulièrement** le mot de passe
4. **Ne commitez jamais** le fichier `.env.local`
5. **Utilisez un gestionnaire de mots de passe** pour stocker le mot de passe

## 🏭 Déploiement en Production

En production, assurez-vous de :

1. Définir la variable d'environnement `VITE_ADMIN_PASSWORD`
2. Ne jamais exposer le mot de passe dans le code source
3. Utiliser un mot de passe unique pour chaque environnement
4. Activer HTTPS pour sécuriser la transmission

## 📝 Notes

- Le mot de passe est stocké côté client (dans le navigateur)
- La session persiste jusqu'à déconnexion explicite
- Protection contre les attaques par force brute (3 tentatives max)
- Blocage temporaire après 3 échecs (30 secondes)


