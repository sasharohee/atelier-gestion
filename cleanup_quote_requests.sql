-- Script de nettoyage pour les tables des demandes de devis
-- ATTENTION: Ce script supprime TOUTES les données des tables quote requests
-- À utiliser uniquement si vous voulez repartir de zéro

-- Supprimer les tables dans l'ordre inverse de création (pour éviter les erreurs de contraintes)
DROP TABLE IF EXISTS public.quote_request_attachments CASCADE;
DROP TABLE IF EXISTS public.quote_requests CASCADE;
DROP TABLE IF EXISTS public.technician_custom_urls CASCADE;
DROP TABLE IF EXISTS public.user_profiles CASCADE;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS public.get_quote_request_stats(UUID);
DROP FUNCTION IF EXISTS public.generate_quote_request_number();

-- Supprimer les politiques RLS (si elles existent encore)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable update for own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Enable delete for own profile" ON public.user_profiles;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.technician_custom_urls;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.technician_custom_urls;
DROP POLICY IF EXISTS "Enable update for own URLs" ON public.technician_custom_urls;
DROP POLICY IF EXISTS "Enable delete for own URLs" ON public.technician_custom_urls;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.quote_requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.quote_requests;
DROP POLICY IF EXISTS "Enable update for own requests" ON public.quote_requests;
DROP POLICY IF EXISTS "Enable delete for own requests" ON public.quote_requests;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.quote_request_attachments;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.quote_request_attachments;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.quote_request_attachments;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.quote_request_attachments;

-- Supprimer les triggers (si ils existent encore)
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS update_technician_custom_urls_updated_at ON public.technician_custom_urls;
DROP TRIGGER IF EXISTS update_quote_requests_updated_at ON public.quote_requests;

-- Supprimer la fonction trigger
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Supprimer les index (si ils existent encore)
DROP INDEX IF EXISTS idx_quote_requests_technician_id;
DROP INDEX IF EXISTS idx_quote_requests_status;
DROP INDEX IF EXISTS idx_quote_requests_created_at;
DROP INDEX IF EXISTS idx_quote_requests_custom_url;
DROP INDEX IF EXISTS idx_technician_custom_urls_technician_id;
DROP INDEX IF EXISTS idx_technician_custom_urls_custom_url;
DROP INDEX IF EXISTS idx_user_profiles_user_id;

COMMIT;
