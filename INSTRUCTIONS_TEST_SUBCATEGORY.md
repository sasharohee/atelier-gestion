# Instructions pour tester les sous-catégories

## 1. Videz le cache du navigateur
Appuyez sur :
- Windows/Linux : Ctrl + Shift + Delete
- Mac : Cmd + Shift + Delete

Sélectionnez "Images et fichiers en cache" puis "Effacer les données"

## 2. Rechargez l'application en mode hard refresh
- Windows/Linux : Ctrl + Shift + R
- Mac : Cmd + Shift + R

## 3. Ouvrez la console du navigateur
- Windows/Linux : F12
- Mac : Cmd + Option + I

## 4. Testez la modification d'un produit
1. Allez dans Catalogue > Produits
2. Cliquez sur l'icône ✏️ (Modifier) d'un produit
3. Le champ "Sous-catégorie" devrait maintenant apparaître
4. Tapez une sous-catégorie (ex: "Câbles iPhone")
5. Cliquez sur "Modifier"

## 5. Vérifiez les logs dans la console
Vous devriez voir :
```
📝 handleSubmit - formData complet: {...}
📝 handleSubmit - subcategory value: "Câbles iPhone"
📝 handleSubmit - updateData avant envoi: {...}
🔍 productService.update - Données reçues: {...}
🔍 productService.update - Données DB: {...}
```

## 6. Si le champ n'apparaît toujours pas
1. Vérifiez que l'application a bien été recompilée
2. Vérifiez que la colonne existe dans Supabase
3. Partagez les logs de la console

