-- Migration de correction des colonnes manquantes
-- Version: V3.5
-- Description: Ajout des colonnes manquantes dans les tables existantes

-- Ajouter la colonne workshop_id à la table users si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."users" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table clients si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."clients" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table repairs si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."repairs" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table appointments si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."appointments" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table parts si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."parts" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table expenses si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."expenses" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Ajouter la colonne workshop_id à la table quote_requests si elle n'existe pas
DO $$ BEGIN
    ALTER TABLE "public"."quote_requests" ADD COLUMN "workshop_id" UUID;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;
