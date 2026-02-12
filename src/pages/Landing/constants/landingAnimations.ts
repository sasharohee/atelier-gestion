import { useEffect, useRef, useState } from 'react';

// Keyframes CSS injectés dynamiquement (scopés à la landing)
const LANDING_KEYFRAMES = `
  @keyframes landing-float {
    0%, 100% { transform: translate3d(0, 0, 0); }
    50% { transform: translate3d(0, -12px, 0); }
  }
  @keyframes landing-pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }
  @keyframes landing-shimmer {
    0% { background-position: -200% center; }
    100% { background-position: 200% center; }
  }
  @keyframes landing-fadeInUp {
    from { opacity: 0; transform: translateY(30px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes landing-borderRotate {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
  }
  @keyframes landing-glow {
    0%, 100% { box-shadow: 0 0 20px rgba(245, 158, 11, 0.1); }
    50% { box-shadow: 0 0 30px rgba(245, 158, 11, 0.2); }
  }
`;

/**
 * Injecte les keyframes CSS pour la landing page.
 * À appeler une fois dans le composant Landing principal.
 */
export function useLandingAnimations() {
  useEffect(() => {
    const style = document.createElement('style');
    style.id = 'landing-animations';
    style.textContent = LANDING_KEYFRAMES;
    document.head.appendChild(style);
    return () => {
      const el = document.getElementById('landing-animations');
      if (el) document.head.removeChild(el);
    };
  }, []);
}

/**
 * Hook IntersectionObserver pour déclencher les animations au scroll.
 * Retourne une ref à attacher à l'élément et un booléen `isVisible`.
 */
export function useScrollAnimation(threshold = 0.15) {
  const ref = useRef<HTMLDivElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.unobserve(el);
        }
      },
      { threshold }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [threshold]);

  return { ref, isVisible };
}

// Styles d'animation réutilisables
export const animations = {
  float: 'landing-float 6s ease-in-out infinite',
  pulse: 'landing-pulse 3s ease-in-out infinite',
  shimmer: 'landing-shimmer 3s linear infinite',
  glow: 'landing-glow 3s ease-in-out infinite',
  borderRotate: 'landing-borderRotate 4s ease infinite',
  fadeInUp: (delay = 0) => ({
    animation: `landing-fadeInUp 0.6s ease-out ${delay}s both`,
  }),
} as const;
