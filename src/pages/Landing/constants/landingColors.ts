// Palette navy/gold scopée uniquement à la landing page
// Ne modifie PAS le thème global de l'application

export const colors = {
  // Navy backgrounds
  navy: {
    deep: '#0f172a',
    dark: '#1e293b',
    medium: '#334155',
    light: '#475569',
    darker: '#0b1120',
  },

  // Gold accents
  gold: {
    primary: '#f59e0b',
    light: '#fbbf24',
    dark: '#d97706',
    subtle: 'rgba(245, 158, 11, 0.15)',
    glow: 'rgba(245, 158, 11, 0.3)',
  },

  // Text
  text: {
    white: '#ffffff',
    light: '#e2e8f0',
    muted: '#94a3b8',
    dim: '#64748b',
  },

  // Glass effects
  glass: {
    bg: 'rgba(30, 41, 59, 0.5)',
    bgSolid: 'rgba(30, 41, 59, 0.8)',
    border: 'rgba(148, 163, 184, 0.1)',
    borderHover: 'rgba(245, 158, 11, 0.3)',
  },
} as const;

// Gradients réutilisables
export const gradients = {
  gold: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
  goldText: 'linear-gradient(135deg, #fbbf24, #f59e0b, #d97706)',
  navyBg: 'linear-gradient(180deg, #0f172a 0%, #1e293b 100%)',
  heroMesh: `
    radial-gradient(ellipse at 20% 50%, rgba(245, 158, 11, 0.08) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(59, 130, 246, 0.06) 0%, transparent 50%),
    radial-gradient(ellipse at 50% 80%, rgba(139, 92, 246, 0.05) 0%, transparent 50%)
  `,
  borderAnimated: 'linear-gradient(135deg, #f59e0b, #3b82f6, #8b5cf6, #f59e0b)',
  footerLine: 'linear-gradient(90deg, transparent, #f59e0b, transparent)',
} as const;

// Styles glass-morphism
export const glassCard = {
  background: colors.glass.bg,
  backdropFilter: 'blur(12px)',
  border: `1px solid ${colors.glass.border}`,
  borderRadius: '16px',
} as const;

export const glassCardHover = {
  borderColor: colors.glass.borderHover,
  boxShadow: `0 8px 32px ${colors.gold.glow}`,
} as const;
