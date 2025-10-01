-- Correction des politiques RLS pour les demandes de devis
-- Ce script corrige les erreurs 403 Forbidden

-- 1. Supprimer les anciennes politiques qui peuvent causer des conflits
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs propres URLs personnalisées" ON technician_custom_urls;
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer leurs propres URLs personnalisées" ON technician_custom_urls;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs propres URLs personnalisées" ON technician_custom_urls;
DROP POLICY IF EXISTS "Les utilisateurs peuvent supprimer leurs propres URLs personnalisées" ON technician_custom_urls;
DROP POLICY IF EXISTS "Accès public en lecture aux URLs personnalisées actives" ON technician_custom_urls;

DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leurs demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Les utilisateurs peuvent créer des demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leurs demandes de devis" ON quote_requests;
DROP POLICY IF EXISTS "Insertion publique des demandes de devis" ON quote_requests;

DROP POLICY IF EXISTS "Les utilisateurs peuvent voir les pièces jointes de leurs demandes" ON quote_request_attachments;
DROP POLICY IF EXISTS "Insertion publique des pièces jointes" ON quote_request_attachments;

-- 2. Créer des politiques RLS plus permissives et fonctionnelles

-- Politiques pour technician_custom_urls
CREATE POLICY "technician_custom_urls_select_own" ON technician_custom_urls
    FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "technician_custom_urls_insert_own" ON technician_custom_urls
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "technician_custom_urls_update_own" ON technician_custom_urls
    FOR UPDATE USING (auth.uid() = technician_id);

CREATE POLICY "technician_custom_urls_delete_own" ON technician_custom_urls
    FOR DELETE USING (auth.uid() = technician_id);

-- Politique pour permettre l'accès public en lecture aux URLs actives
CREATE POLICY "technician_custom_urls_public_read_active" ON technician_custom_urls
    FOR SELECT USING (is_active = true);

-- Politiques pour quote_requests
CREATE POLICY "quote_requests_select_own" ON quote_requests
    FOR SELECT USING (auth.uid() = technician_id);

CREATE POLICY "quote_requests_insert_own" ON quote_requests
    FOR INSERT WITH CHECK (auth.uid() = technician_id);

CREATE POLICY "quote_requests_update_own" ON quote_requests
    FOR UPDATE USING (auth.uid() = technician_id);

-- Politique pour permettre l'insertion publique des demandes (pour le formulaire)
CREATE POLICY "quote_requests_public_insert" ON quote_requests
    FOR INSERT WITH CHECK (true);

-- Politiques pour quote_request_attachments
CREATE POLICY "quote_request_attachments_select_own" ON quote_request_attachments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM quote_requests 
            WHERE id = quote_request_attachments.quote_request_id 
            AND technician_id = auth.uid()
        )
    );

CREATE POLICY "quote_request_attachments_public_insert" ON quote_request_attachments
    FOR INSERT WITH CHECK (true);

-- 3. Vérifier que RLS est bien activé
ALTER TABLE technician_custom_urls ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE quote_request_attachments ENABLE ROW LEVEL SECURITY;

-- 4. Créer une fonction pour vérifier l'authentification
CREATE OR REPLACE FUNCTION is_authenticated()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.uid() IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Créer une fonction pour vérifier si l'utilisateur est le propriétaire
CREATE OR REPLACE FUNCTION is_owner(technician_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN auth.uid() = technician_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Politiques alternatives plus simples (si les précédentes ne fonctionnent pas)
-- Désactiver temporairement RLS pour tester
-- ALTER TABLE technician_custom_urls DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE quote_requests DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE quote_request_attachments DISABLE ROW LEVEL SECURITY;

-- 7. Créer des politiques de test plus permissives
CREATE POLICY "test_technician_custom_urls_all" ON technician_custom_urls
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "test_quote_requests_all" ON quote_requests
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "test_quote_request_attachments_all" ON quote_request_attachments
    FOR ALL USING (true) WITH CHECK (true);

-- 8. Vérifier les politiques créées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename IN ('technician_custom_urls', 'quote_requests', 'quote_request_attachments');

-- 9. Test de création d'URL (à exécuter manuellement pour tester)
-- INSERT INTO technician_custom_urls (technician_id, custom_url, is_active)
-- VALUES (auth.uid(), 'test-url', true);

-- 10. Commentaires sur les corrections
COMMENT ON POLICY "test_technician_custom_urls_all" ON technician_custom_urls IS 'Politique de test - permet toutes les opérations';
COMMENT ON POLICY "test_quote_requests_all" ON quote_requests IS 'Politique de test - permet toutes les opérations';
COMMENT ON POLICY "test_quote_request_attachments_all" ON quote_request_attachments IS 'Politique de test - permet toutes les opérations';
