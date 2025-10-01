-- Migration initiale basée sur la structure de production
-- Version: V1
-- Description: Création du schéma initial de l'atelier

-- Suppression des extensions si elles existent
DROP EXTENSION IF EXISTS "pg_net";

-- Création des types énumérés (avec vérification d'existence)
DO $$ BEGIN
    CREATE TYPE "public"."alert_severity_type" AS ENUM ('info', 'warning', 'error', 'critical');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."device_type" AS ENUM ('smartphone', 'tablet', 'laptop', 'desktop', 'other');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."parts_availability_type" AS ENUM ('high', 'medium', 'low');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."payment_method_type" AS ENUM ('cash', 'card', 'transfer', 'check', 'payment_link');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."quote_status_type" AS ENUM ('draft', 'sent', 'accepted', 'rejected', 'expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."repair_difficulty_type" AS ENUM ('easy', 'medium', 'hard');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."report_status_type" AS ENUM ('pending', 'processing', 'completed', 'failed');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."transaction_status_type" AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."transaction_type_enum" AS ENUM ('repair', 'sale', 'refund', 'deposit', 'withdrawal');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "public"."user_role" AS ENUM ('admin', 'technician', 'client');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Table des logs d'activité
CREATE TABLE IF NOT EXISTS "public"."activity_logs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_id" UUID,
    "action" CHARACTER VARYING(100) NOT NULL,
    "entity_type" CHARACTER VARYING(50) NOT NULL,
    "entity_id" UUID,
    "old_values" JSONB,
    "new_values" JSONB,
    "ip_address" INET,
    "user_agent" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."activity_logs" ENABLE ROW LEVEL SECURITY;

-- Table des alertes avancées
CREATE TABLE IF NOT EXISTS "public"."advanced_alerts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "alert_type" CHARACTER VARYING(100) NOT NULL,
    "title" CHARACTER VARYING(200) NOT NULL,
    "message" TEXT NOT NULL,
    "severity" alert_severity_type NOT NULL DEFAULT 'info'::alert_severity_type,
    "target_user_id" UUID,
    "target_role" user_role,
    "is_read" BOOLEAN DEFAULT FALSE,
    "action_required" BOOLEAN DEFAULT FALSE,
    "action_url" CHARACTER VARYING(500),
    "expires_at" TIMESTAMP WITH TIME ZONE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."advanced_alerts" ENABLE ROW LEVEL SECURITY;

-- Table des paramètres avancés
CREATE TABLE IF NOT EXISTS "public"."advanced_settings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "setting_key" CHARACTER VARYING(100) NOT NULL,
    "setting_value" JSONB NOT NULL,
    "setting_type" CHARACTER VARYING(50) NOT NULL,
    "description" TEXT,
    "is_system" BOOLEAN DEFAULT FALSE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."advanced_settings" ENABLE ROW LEVEL SECURITY;

-- Table des rendez-vous
CREATE TABLE IF NOT EXISTS "public"."appointments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "start_time" TIMESTAMP WITH TIME ZONE,
    "end_time" TIMESTAMP WITH TIME ZONE,
    "status" TEXT DEFAULT 'scheduled'::TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID,
    "start_date" TIMESTAMP WITH TIME ZONE,
    "end_date" TIMESTAMP WITH TIME ZONE,
    "created_by" UUID,
    "workshop_id" UUID,
    "assigned_user_id" UUID,
    "repair_id" UUID
);

ALTER TABLE "public"."appointments" ENABLE ROW LEVEL SECURITY;