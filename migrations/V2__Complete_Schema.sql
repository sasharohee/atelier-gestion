-- Migration complète basée sur la structure de production
-- Version: V2
-- Description: Ajout de toutes les tables manquantes

-- Table des points de fidélité clients
CREATE TABLE IF NOT EXISTS "public"."client_loyalty_points" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID NOT NULL,
    "total_points" INTEGER DEFAULT 0,
    "used_points" INTEGER DEFAULT 0,
    "current_tier_id" UUID,
    "last_updated" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID
);

ALTER TABLE "public"."client_loyalty_points" ENABLE ROW LEVEL SECURITY;

-- Table des clients (version complète)
CREATE TABLE IF NOT EXISTS "public"."clients" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "phone" TEXT,
    "address" TEXT,
    "notes" TEXT,
    "category" CHARACTER VARYING(50) DEFAULT 'particulier'::CHARACTER VARYING,
    "title" CHARACTER VARYING(10) DEFAULT 'mr'::CHARACTER VARYING,
    "company_name" CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
    "vat_number" CHARACTER VARYING(50) DEFAULT ''::CHARACTER VARYING,
    "siren_number" CHARACTER VARYING(50) DEFAULT ''::CHARACTER VARYING,
    "country_code" CHARACTER VARYING(10) DEFAULT '33'::CHARACTER VARYING,
    "address_complement" CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
    "region" CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
    "postal_code" CHARACTER VARYING(10) DEFAULT ''::CHARACTER VARYING,
    "city" CHARACTER VARYING(100) DEFAULT ''::CHARACTER VARYING,
    "billing_address_same" BOOLEAN DEFAULT TRUE,
    "billing_address" TEXT DEFAULT ''::TEXT,
    "billing_address_complement" CHARACTER VARYING(255) DEFAULT ''::CHARACTER VARYING,
    "billing_region" CHARACTER VARYING(100) DEFAULT ''::CHARACTER VARYING,
    "billing_postal_code" CHARACTER VARYING(20) DEFAULT ''::CHARACTER VARYING,
    "billing_city" CHARACTER VARYING(100) DEFAULT ''::CHARACTER VARYING,
    "accounting_code" CHARACTER VARYING(50) DEFAULT ''::CHARACTER VARYING,
    "cni_identifier" CHARACTER VARYING(50) DEFAULT ''::CHARACTER VARYING,
    "attached_file_path" CHARACTER VARYING(500) DEFAULT ''::CHARACTER VARYING,
    "internal_note" TEXT DEFAULT ''::TEXT,
    "status" CHARACTER VARYING(20) DEFAULT 'displayed'::CHARACTER VARYING,
    "sms_notification" BOOLEAN DEFAULT TRUE,
    "email_notification" BOOLEAN DEFAULT TRUE,
    "sms_marketing" BOOLEAN DEFAULT TRUE,
    "email_marketing" BOOLEAN DEFAULT TRUE,
    "user_id" UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::UUID,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_by" UUID,
    "loyalty_points" INTEGER DEFAULT 0,
    "current_tier_id" UUID,
    "workshop_id" UUID,
    "company" TEXT
);

ALTER TABLE "public"."clients" ENABLE ROW LEVEL SECURITY;

-- Table de sauvegarde des clients
CREATE TABLE IF NOT EXISTS "public"."clients_backup" (
    "id" UUID,
    "first_name" CHARACTER VARYING(255),
    "last_name" CHARACTER VARYING(255),
    "email" CHARACTER VARYING(255),
    "phone" CHARACTER VARYING(50),
    "address" TEXT,
    "notes" TEXT,
    "category" CHARACTER VARYING(50),
    "title" CHARACTER VARYING(10),
    "company_name" CHARACTER VARYING(255),
    "vat_number" CHARACTER VARYING(50),
    "siren_number" CHARACTER VARYING(50),
    "country_code" CHARACTER VARYING(10),
    "address_complement" CHARACTER VARYING(255),
    "region" CHARACTER VARYING(100),
    "postal_code" CHARACTER VARYING(20),
    "city" CHARACTER VARYING(100),
    "billing_address_same" BOOLEAN,
    "billing_address" TEXT,
    "billing_address_complement" CHARACTER VARYING(255),
    "billing_region" CHARACTER VARYING(100),
    "billing_postal_code" CHARACTER VARYING(20),
    "billing_city" CHARACTER VARYING(100),
    "accounting_code" CHARACTER VARYING(50),
    "cni_identifier" CHARACTER VARYING(50),
    "attached_file_path" CHARACTER VARYING(500),
    "internal_note" TEXT,
    "status" CHARACTER VARYING(20),
    "sms_notification" BOOLEAN,
    "email_notification" BOOLEAN,
    "sms_marketing" BOOLEAN,
    "email_marketing" BOOLEAN,
    "user_id" UUID,
    "created_at" TIMESTAMP WITH TIME ZONE,
    "updated_at" TIMESTAMP WITH TIME ZONE,
    "workshop_id" UUID
);

ALTER TABLE "public"."clients_backup" ENABLE ROW LEVEL SECURITY;

-- Table des emails de confirmation
CREATE TABLE IF NOT EXISTS "public"."confirmation_emails" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "user_email" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMP WITH TIME ZONE NOT NULL,
    "status" TEXT DEFAULT 'pending'::TEXT,
    "sent_at" TIMESTAMP WITH TIME ZONE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_by" UUID
);

ALTER TABLE "public"."confirmation_emails" ENABLE ROW LEVEL SECURITY;

-- Table des utilisateurs personnalisés
CREATE TABLE IF NOT EXISTS "public"."custom_users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "workshop_name" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_by" UUID
);

ALTER TABLE "public"."custom_users" ENABLE ROW LEVEL SECURITY;

-- Table des marques d'appareils
CREATE TABLE IF NOT EXISTS "public"."device_brands" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "category_id" UUID,
    "description" TEXT,
    "logo" TEXT,
    "is_active" BOOLEAN DEFAULT TRUE,
    "user_id" UUID,
    "created_by" UUID,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE "public"."device_brands" ENABLE ROW LEVEL SECURITY;

-- Table des catégories d'appareils
CREATE TABLE IF NOT EXISTS "public"."device_categories" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "description" TEXT,
    "icon" TEXT DEFAULT 'smartphone'::TEXT,
    "is_active" BOOLEAN DEFAULT TRUE,
    "user_id" UUID,
    "created_by" UUID,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE "public"."device_categories" ENABLE ROW LEVEL SECURITY;

-- Table des modèles d'appareils
CREATE TABLE IF NOT EXISTS "public"."device_models" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "category" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_by" UUID,
    "workshop_id" UUID,
    "type" TEXT NOT NULL DEFAULT 'other'::TEXT,
    "year" INTEGER NOT NULL DEFAULT 2024,
    "specifications" JSONB DEFAULT '{}'::JSONB,
    "common_issues" TEXT[] DEFAULT '{}'::TEXT[],
    "repair_difficulty" TEXT DEFAULT 'medium'::TEXT,
    "parts_availability" TEXT DEFAULT 'medium'::TEXT,
    "is_active" BOOLEAN DEFAULT TRUE,
    "user_id" UUID,
    "name" TEXT,
    "brand_id" UUID,
    "category_id" UUID
);

ALTER TABLE "public"."device_models" ENABLE ROW LEVEL SECURITY;
