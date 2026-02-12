// Service frontend pour l'intégration Stripe
import { supabase } from '../lib/supabase';

export interface CreateCheckoutSessionParams {
  priceId: string;
  successUrl?: string;
  cancelUrl?: string;
}

export interface CreateCheckoutSessionResponse {
  sessionId: string;
  url: string;
}

export interface StripeServiceError {
  message: string;
  code?: string;
}

/**
 * Crée une session Stripe Checkout pour l'abonnement
 * @param params Paramètres de la session Checkout
 * @returns URL de redirection vers Stripe Checkout
 */
export const createCheckoutSession = async (
  params: CreateCheckoutSessionParams
): Promise<{ success: boolean; data?: CreateCheckoutSessionResponse; error?: string }> => {
  try {
    // Récupérer le token d'authentification
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError || !session) {
      return {
        success: false,
        error: 'Vous devez être connecté pour créer une session de paiement'
      };
    }

    // Appeler l'Edge Function stripe-checkout
    const { data, error } = await supabase.functions.invoke('stripe-checkout', {
      body: {
        priceId: params.priceId,
        successUrl: params.successUrl || `${window.location.origin}/app/subscription-blocked?checkout=success`,
        cancelUrl: params.cancelUrl || `${window.location.origin}/app/subscription-blocked?checkout=cancelled`,
      },
      headers: {
        Authorization: `Bearer ${session.access_token}`,
      },
    });

    if (error) {
      console.error('Erreur lors de la création de la session Checkout:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la création de la session de paiement'
      };
    }

    // Erreur retournée par l'Edge Function (ex. clé Stripe manquante côté Supabase)
    if (data?.error) {
      console.error('Erreur Edge Function stripe-checkout:', data.error);
      return {
        success: false,
        error: typeof data.error === 'string' ? data.error : 'Erreur serveur Stripe. Vérifiez la configuration Supabase (secrets Edge Function).'
      };
    }

    if (!data || !data.url) {
      return {
        success: false,
        error: 'Réponse invalide du serveur'
      };
    }

    return {
      success: true,
      data: {
        sessionId: data.sessionId,
        url: data.url,
      }
    };
  } catch (error) {
    console.error('Exception lors de la création de la session Checkout:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Erreur inattendue'
    };
  }
};

/**
 * Redirige l'utilisateur vers Stripe Checkout
 * @param priceId ID du prix Stripe (mensuel ou annuel)
 * @param successUrl URL de redirection en cas de succès
 * @param cancelUrl URL de redirection en cas d'annulation
 */
export const redirectToCheckout = async (
  priceId: string,
  successUrl?: string,
  cancelUrl?: string
): Promise<void> => {
  const result = await createCheckoutSession({
    priceId,
    successUrl,
    cancelUrl,
  });

  if (!result.success || !result.data) {
    throw new Error(result.error || 'Impossible de créer la session de paiement');
  }

  // Rediriger vers Stripe Checkout
  window.location.href = result.data.url;
};

/**
 * Vérifie si le paiement a réussi en vérifiant les paramètres URL
 * @returns true si le paiement a réussi
 */
export const checkPaymentSuccess = (): boolean => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('checkout') === 'success';
};

/**
 * Vérifie si le paiement a été annulé
 * @returns true si le paiement a été annulé
 */
export const checkPaymentCancelled = (): boolean => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('checkout') === 'cancelled';
};

