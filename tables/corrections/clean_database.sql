-- Script pour nettoyer complètement la base de données
-- ATTENTION : Ce script supprime TOUTES les données de toutes les tables
-- À utiliser uniquement pour remettre le site à zéro

-- Désactiver temporairement les contraintes de clés étrangères
SET session_replication_role = replica;

-- Supprimer toutes les données dans l'ordre pour éviter les erreurs de contraintes
DELETE FROM repair_parts;
DELETE FROM repair_services;
DELETE FROM sale_items;
DELETE FROM sales;
DELETE FROM repairs;
DELETE FROM appointments;
DELETE FROM messages;
DELETE FROM devices;
DELETE FROM clients;
DELETE FROM parts;
DELETE FROM services;
DELETE FROM products;

-- Réactiver les contraintes de clés étrangères
SET session_replication_role = DEFAULT;

-- Vérifier que toutes les tables sont vides
SELECT 
  'clients' as table_name, COUNT(*) as count FROM clients
UNION ALL
SELECT 'devices', COUNT(*) FROM devices
UNION ALL
SELECT 'repairs', COUNT(*) FROM repairs
UNION ALL
SELECT 'appointments', COUNT(*) FROM appointments
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'services', COUNT(*) FROM services
UNION ALL
SELECT 'parts', COUNT(*) FROM parts
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'messages', COUNT(*) FROM messages;

-- Message de confirmation
SELECT '✅ Base de données nettoyée avec succès. Site vierge prêt à l''emploi.' as status;
