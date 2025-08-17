# 🚀 Guide de déploiement sur GitHub

## Étape 1 : Créer un repository GitHub

1. **Allez sur GitHub.com** et connectez-vous à votre compte
2. **Cliquez sur "New repository"** (bouton vert)
3. **Configurez le repository :**
   - **Repository name :** `atelier-gestion`
   - **Description :** `Application de gestion d'atelier de réparation inspirée de Laast.io`
   - **Public** ou **Private** (selon votre préférence)
   - **Ne pas initialiser** avec README, .gitignore ou licence
4. **Cliquez sur "Create repository"**

## Étape 2 : Connecter votre projet local

Une fois le repository créé, GitHub vous donnera des commandes. Utilisez celles-ci :

```bash
# Remplacez [VOTRE_USERNAME] par votre nom d'utilisateur GitHub
git remote add origin https://github.com/[VOTRE_USERNAME]/atelier-gestion.git
git push -u origin main
```

## Étape 3 : Configurer GitHub Pages

1. **Allez dans les paramètres du repository** (onglet "Settings")
2. **Scrollez jusqu'à "Pages"** dans le menu de gauche
3. **Dans "Source", sélectionnez :**
   - **Deploy from a branch**
   - **Branch :** `gh-pages`
   - **Folder :** `/ (root)`
4. **Cliquez sur "Save"**

## Étape 4 : Activer GitHub Actions

1. **Allez dans l'onglet "Actions"** de votre repository
2. **Le workflow de déploiement devrait apparaître automatiquement**
3. **Si ce n'est pas le cas, cliquez sur "New workflow" et sélectionnez "Deploy to GitHub Pages"**

## Étape 5 : Personnaliser l'URL

1. **Modifiez le fichier `package.json`** et remplacez `[VOTRE_USERNAME]` par votre nom d'utilisateur GitHub :

```json
{
  "homepage": "https://[VOTRE_USERNAME].github.io/atelier-gestion"
}
```

2. **Committez et poussez les changements :**

```bash
git add package.json
git commit -m "Mise à jour de l'URL GitHub Pages"
git push
```

## Étape 6 : Vérifier le déploiement

1. **Allez dans l'onglet "Actions"** pour voir le statut du déploiement
2. **Une fois terminé, votre application sera accessible à :**
   `https://[VOTRE_USERNAME].github.io/atelier-gestion`

## 🔧 Configuration avancée

### Variables d'environnement (optionnel)

Si vous voulez ajouter des variables d'environnement :

1. **Créez un fichier `.env`** à la racine du projet
2. **Ajoutez vos variables :**

```env
REACT_APP_API_URL=https://votre-api.com
REACT_APP_APP_NAME=Atelier Gestion
```

3. **Ajoutez le fichier au repository :**

```bash
git add .env
git commit -m "Ajout des variables d'environnement"
git push
```

### Domaine personnalisé (optionnel)

Pour utiliser un domaine personnalisé :

1. **Dans les paramètres GitHub Pages, ajoutez votre domaine**
2. **Créez un fichier `CNAME`** dans le dossier `public/` avec votre domaine
3. **Configurez votre DNS** pour pointer vers GitHub Pages

## 🐛 Résolution de problèmes

### Erreur de build

Si le build échoue :

1. **Vérifiez les logs** dans l'onglet "Actions"
2. **Testez localement :** `npm run build`
3. **Corrigez les erreurs** et poussez à nouveau

### Page 404

Si vous obtenez une page 404 :

1. **Vérifiez que GitHub Pages est activé**
2. **Attendez quelques minutes** après le push
3. **Vérifiez l'URL** dans les paramètres GitHub Pages

### Problèmes de routing

Si les routes ne fonctionnent pas :

1. **Vérifiez que les fichiers `404.html` et le script de redirection sont présents**
2. **Testez avec des routes simples** d'abord

## 📱 Accès à l'application

Une fois déployée, votre application sera accessible à :
- **URL principale :** `https://[VOTRE_USERNAME].github.io/atelier-gestion`
- **Dashboard :** `https://[VOTRE_USERNAME].github.io/atelier-gestion/dashboard`
- **Kanban :** `https://[VOTRE_USERNAME].github.io/atelier-gestion/kanban`
- **Etc...**

## 🔄 Mises à jour

Pour mettre à jour l'application :

```bash
# Faites vos modifications
git add .
git commit -m "Description des changements"
git push origin main
```

Le déploiement se fera automatiquement via GitHub Actions.

---

**🎉 Félicitations ! Votre application est maintenant déployée sur GitHub Pages !**
