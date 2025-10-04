-- Script pour corriger le code de service des dépenses
-- Ce script ne fait que des commentaires car les modifications doivent être faites dans le code

-- ATTENTION: Ce fichier contient les modifications à apporter au code
-- Les modifications doivent être faites dans src/services/supabaseService.ts

-- 1. MODIFICATION DE LA FONCTION getAll() dans expenseService
-- REMPLACER:
-- .select(`
--   *,
--   category:expense_categories(*)
-- `)

-- PAR:
-- .select('*')

-- 2. MODIFICATION DE LA FONCTION getById() dans expenseService  
-- REMPLACER:
-- .select(`
--   *,
--   category:expense_categories(*)
-- `)

-- PAR:
-- .select('*')

-- 3. MODIFICATION DE LA FONCTION create() dans expenseService
-- SUPPRIMER toute la logique de création de catégorie et remplacer par:
-- category_id: null

-- 4. MODIFICATION DE LA FONCTION update() dans expenseService
-- REMPLACER:
-- .select(`
--   *,
--   category:expense_categories(*)
-- `)

-- PAR:
-- .select('*')

-- 5. MODIFICATION DE LA FONCTION getStats() dans expenseService
-- REMPLACER:
-- .select(`
--   amount,
--   status,
--   expense_date,
--   category:expense_categories(name)
-- `)

-- PAR:
-- .select(`
--   amount,
--   status,
--   expense_date
-- `)

-- 6. SUPPRIMER LES RÉFÉRENCES AUX CATÉGORIES DANS LES DONNÉES CONVERTIES
-- Supprimer toutes les références à expense.category dans les fonctions de conversion

-- 7. MODIFIER LES TYPES TypeScript
-- Supprimer la propriété category de l'interface Expense

-- 8. MODIFIER LES COMPOSANTS REACT
-- Supprimer l'affichage des catégories dans les composants
