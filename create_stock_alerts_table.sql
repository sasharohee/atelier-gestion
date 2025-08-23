-- CRÉATION DE LA TABLE STOCK_ALERTS
-- Table pour gérer les alertes de stock avec isolation des utilisateurs

-- ============================================================================
-- 1. CRÉATION DE LA TABLE STOCK_ALERTS
-- ============================================================================

-- Supprimer la table si elle existe déjà
DROP TABLE IF EXISTS public.stock_alerts CASCADE;

-- Créer la table stock_alerts
CREATE TABLE public.stock_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    part_id UUID NOT NULL REFERENCES public.parts(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('low_stock', 'out_of_stock')),
    message TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- 2. CRÉATION DES INDEX
-- ============================================================================

-- Index pour les performances
CREATE INDEX idx_stock_alerts_user_id ON public.stock_alerts(user_id);
CREATE INDEX idx_stock_alerts_part_id ON public.stock_alerts(part_id);
CREATE INDEX idx_stock_alerts_type ON public.stock_alerts(type);
CREATE INDEX idx_stock_alerts_is_resolved ON public.stock_alerts(is_resolved);
CREATE INDEX idx_stock_alerts_created_at ON public.stock_alerts(created_at);

-- ============================================================================
-- 3. ACTIVATION DE RLS
-- ============================================================================

-- Activer Row Level Security
ALTER TABLE public.stock_alerts ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. CRÉATION DES POLITIQUES RLS
-- ============================================================================

-- Politique pour voir ses propres alertes
CREATE POLICY "Users can view own stock alerts" ON public.stock_alerts 
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour créer ses propres alertes
CREATE POLICY "Users can create own stock alerts" ON public.stock_alerts 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour mettre à jour ses propres alertes
CREATE POLICY "Users can update own stock alerts" ON public.stock_alerts 
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Politique pour supprimer ses propres alertes
CREATE POLICY "Users can delete own stock alerts" ON public.stock_alerts 
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================================================
-- 5. FONCTION POUR MISE À JOUR AUTOMATIQUE
-- ============================================================================

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_stock_alerts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER trigger_update_stock_alerts_updated_at
    BEFORE UPDATE ON public.stock_alerts
    FOR EACH ROW
    EXECUTE FUNCTION update_stock_alerts_updated_at();

-- ============================================================================
-- 6. FONCTION POUR CRÉER DES ALERTES AUTOMATIQUES
-- ============================================================================

-- Fonction pour créer automatiquement des alertes de stock
CREATE OR REPLACE FUNCTION create_stock_alert_automatically()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Obtenir l'ID de l'utilisateur connecté
    current_user_id := auth.uid();
    
    -- Si aucun utilisateur connecté, utiliser l'utilisateur du système
    IF current_user_id IS NULL THEN
        current_user_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;
    
    -- Créer une alerte de rupture de stock si le stock est à 0
    IF NEW.stock_quantity <= 0 THEN
        INSERT INTO public.stock_alerts (part_id, type, message, user_id)
        VALUES (NEW.id, 'out_of_stock', 'Rupture de stock pour ' || NEW.name, current_user_id)
        ON CONFLICT DO NOTHING;
    -- Créer une alerte de stock faible si le stock est inférieur au seuil minimum
    ELSIF NEW.stock_quantity <= NEW.min_stock_level THEN
        INSERT INTO public.stock_alerts (part_id, type, message, user_id)
        VALUES (NEW.id, 'low_stock', 'Stock faible pour ' || NEW.name, current_user_id)
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour créer automatiquement des alertes lors de l'insertion
CREATE TRIGGER trigger_create_stock_alert_on_insert
    AFTER INSERT ON public.parts
    FOR EACH ROW
    EXECUTE FUNCTION create_stock_alert_automatically();

-- Trigger pour créer automatiquement des alertes lors de la mise à jour
CREATE TRIGGER trigger_create_stock_alert_on_update
    AFTER UPDATE ON public.parts
    FOR EACH ROW
    EXECUTE FUNCTION create_stock_alert_automatically();

-- ============================================================================
-- 7. FONCTION POUR RÉSOUDRE LES ALERTES AUTOMATIQUEMENT
-- ============================================================================

-- Fonction pour résoudre automatiquement les alertes quand le stock est suffisant
CREATE OR REPLACE FUNCTION resolve_stock_alerts_automatically()
RETURNS TRIGGER AS $$
BEGIN
    -- Si le stock est maintenant suffisant, résoudre les alertes
    IF NEW.stock_quantity > NEW.min_stock_level THEN
        UPDATE public.stock_alerts 
        SET is_resolved = TRUE, updated_at = NOW()
        WHERE part_id = NEW.id AND is_resolved = FALSE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour résoudre automatiquement les alertes
CREATE TRIGGER trigger_resolve_stock_alerts
    AFTER UPDATE ON public.parts
    FOR EACH ROW
    EXECUTE FUNCTION resolve_stock_alerts_automatically();

-- ============================================================================
-- 8. VÉRIFICATION FINALE
-- ============================================================================

-- Vérifier que la table a été créée
SELECT 
    'VÉRIFICATION TABLE STOCK_ALERTS' as section,
    COUNT(*) as nombre_colonnes
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'stock_alerts';

-- Vérifier les politiques RLS
SELECT 
    'POLITIQUES RLS STOCK_ALERTS' as section,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'stock_alerts'
ORDER BY policyname;

-- Vérifier les triggers
SELECT 
    'TRIGGERS STOCK_ALERTS' as section,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'stock_alerts'
ORDER BY trigger_name;

-- ============================================================================
-- 9. MESSAGE DE CONFIRMATION
-- ============================================================================

SELECT 
    '🎉 TABLE STOCK_ALERTS CRÉÉE' as status,
    'La table stock_alerts a été créée avec isolation des utilisateurs' as message,
    'Les alertes seront créées automatiquement lors de la gestion des pièces' as action;
