import { createClient } from '@supabase/supabase-js';

// Client Supabase Admin avec service_role key (bypass RLS)
// Ce client voit TOUS les utilisateurs sans restriction Row Level Security
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://wlqyrmntfxwdvkzzsujv.supabase.co';
const supabaseServiceRoleKey = import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseServiceRoleKey) {
  console.warn('⚠️ VITE_SUPABASE_SERVICE_ROLE_KEY non configurée. Le panneau Super Admin ne fonctionnera pas correctement.');
}

export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey || '', {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
  db: {
    schema: 'public',
  },
  global: {
    headers: {
      'X-Client-Info': 'atelier-super-admin',
    },
  },
});
