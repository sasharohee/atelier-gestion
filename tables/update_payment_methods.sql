-- =====================================================
-- MISE À JOUR DES MOYENS DE PAIEMENT
-- Ajout de "Chèque" et "Liens paiement"
-- =====================================================

-- 1. Mettre à jour le type ENUM payment_method_type s'il existe
DO $$ 
BEGIN
    -- Vérifier si le type existe
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method_type') THEN
        -- Supprimer le type existant et le recréer avec les nouvelles valeurs
        DROP TYPE payment_method_type CASCADE;
    END IF;
    
    -- Créer le nouveau type avec toutes les valeurs
    CREATE TYPE payment_method_type AS ENUM ('cash', 'card', 'transfer', 'check', 'payment_link');
    
EXCEPTION
    WHEN duplicate_object THEN 
        RAISE NOTICE 'Le type payment_method_type existe déjà';
    WHEN OTHERS THEN
        RAISE NOTICE 'Erreur lors de la création du type: %', SQLERRM;
END $$;

-- 2. Vérifier si la colonne payment_method existe dans la table sales
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'sales' 
        AND column_name = 'payment_method'
    ) THEN
        -- Ajouter la colonne si elle n'existe pas
        ALTER TABLE public.sales ADD COLUMN payment_method TEXT DEFAULT 'cash';
        RAISE NOTICE 'Colonne payment_method ajoutée à la table sales';
    ELSE
        RAISE NOTICE 'La colonne payment_method existe déjà dans la table sales';
    END IF;
END $$;

-- 3. Mettre à jour les valeurs existantes si nécessaire
-- Convertir 'bank_transfer' en 'transfer' et 'other' en 'payment_link'
UPDATE public.sales 
SET payment_method = 'transfer' 
WHERE payment_method = 'bank_transfer';

UPDATE public.sales 
SET payment_method = 'payment_link' 
WHERE payment_method = 'other';

-- 4. Vérification finale
SELECT 
    'VÉRIFICATION DES MOYENS DE PAIEMENT' as test,
    payment_method,
    COUNT(*) as nombre_ventes
FROM public.sales 
GROUP BY payment_method 
ORDER BY nombre_ventes DESC;

-- 5. Afficher les valeurs possibles du type ENUM
SELECT 
    'VALEURS DISPONIBLES' as info,
    enumlabel as moyen_paiement
FROM pg_enum 
WHERE enumtypid = (SELECT oid FROM pg_type WHERE typname = 'payment_method_type')
ORDER BY enumsortorder;

-- 6. Message de confirmation
SELECT 
    'MISE À JOUR TERMINÉE' as status,
    'Les moyens de paiement ont été mis à jour avec succès.' as message,
    'Nouveaux moyens disponibles: Espèces, Carte, Virement, Chèque, Liens paiement' as details;
