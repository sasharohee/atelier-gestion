# Déploiement de l'Edge Function Stripe Portal

## 🚀 Déploiement

Pour activer la gestion d'abonnement depuis la page dédiée, déployez la nouvelle Edge Function :

```bash
supabase functions deploy stripe-portal
```

## ✅ Vérification

Après le déploiement, vérifiez que la fonction est bien déployée dans :
- Supabase Dashboard > Edge Functions

## 📝 Utilisation

Une fois déployée, les utilisateurs pourront :
1. Accéder à la page "Abonnement" depuis le menu de navigation (en dessous de Réglages)
2. Voir leur statut d'abonnement actuel
3. Cliquer sur "Gérer mon abonnement" pour accéder au portail client Stripe
4. Dans le portail Stripe, ils pourront :
   - Modifier leur plan d'abonnement
   - Consulter leurs factures
   - Mettre à jour leur méthode de paiement
   - Annuler leur abonnement

