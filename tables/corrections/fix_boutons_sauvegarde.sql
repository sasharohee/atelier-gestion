-- FIX BOUTONS DE SAUVEGARDE
-- Script simple pour corriger les boutons de sauvegarde

-- 1. VÉRIFIER SI L'UTILISATEUR ACTUEL A DES PARAMÈTRES
SELECT 
    'Vérification' as action,
    COUNT(*) as settings_count
FROM public.system_settings 
WHERE user_id = auth.uid();

-- 2. CRÉER LES PARAMÈTRES SI IL N'Y EN A PAS
INSERT INTO public.system_settings (user_id, key, value, description, category) 
SELECT 
  auth.uid() as user_id,
  key,
  value,
  description,
  category
FROM (
  VALUES
    ('workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
    ('workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
    ('workshop_phone', '01 23 45 67 89', 'Téléphone de contact', 'general'),
    ('workshop_email', 'contact@atelier.fr', 'Email de contact', 'general'),
    ('vat_rate', '20', 'Taux de TVA', 'billing'),
    ('currency', 'EUR', 'Devise', 'billing'),
    ('invoice_prefix', 'FACT-', 'Préfixe facture', 'billing'),
    ('date_format', 'dd/MM/yyyy', 'Format de date', 'billing'),
    ('auto_backup', 'true', 'Sauvegarde automatique', 'system'),
    ('notifications', 'true', 'Notifications', 'system'),
    ('backup_frequency', 'daily', 'Fréquence sauvegarde', 'system'),
    ('max_file_size', '10', 'Taille max fichiers', 'system')
) AS defaults(key, value, description, category)
WHERE NOT EXISTS (
  SELECT 1 FROM public.system_settings 
  WHERE user_id = auth.uid() AND key = defaults.key
);

-- 3. VÉRIFICATION FINALE
SELECT 
    'Fix terminé' as status,
    COUNT(*) as total_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
