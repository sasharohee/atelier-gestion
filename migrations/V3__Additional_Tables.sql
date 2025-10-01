-- Migration des tables supplémentaires
-- Version: V3
-- Description: Ajout des tables restantes de la structure de production

-- Table des dépenses
CREATE TABLE IF NOT EXISTS "public"."expenses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "amount" DECIMAL(10,2) NOT NULL,
    "description" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "date" DATE NOT NULL,
    "receipt_url" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;

-- Table des catégories de dépenses
CREATE TABLE IF NOT EXISTS "public"."expense_categories" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "description" TEXT,
    "color" TEXT DEFAULT '#3B82F6',
    "is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."expense_categories" ENABLE ROW LEVEL SECURITY;

-- Table des niveaux de fidélité
CREATE TABLE IF NOT EXISTS "public"."loyalty_tiers" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "min_points" INTEGER NOT NULL,
    "max_points" INTEGER,
    "discount_percentage" DECIMAL(5,2) DEFAULT 0,
    "benefits" TEXT[],
    "color" TEXT DEFAULT '#3B82F6',
    "is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."loyalty_tiers" ENABLE ROW LEVEL SECURITY;

-- Table des pièces détachées
CREATE TABLE IF NOT EXISTS "public"."parts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "part_number" TEXT,
    "brand" TEXT,
    "model" TEXT,
    "price" DECIMAL(10,2),
    "stock_quantity" INTEGER DEFAULT 0,
    "min_stock_level" INTEGER DEFAULT 0,
    "supplier" TEXT,
    "description" TEXT,
    "is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."parts" ENABLE ROW LEVEL SECURITY;

-- Table des demandes de devis
CREATE TABLE IF NOT EXISTS "public"."quote_requests" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID NOT NULL,
    "device_id" UUID,
    "description" TEXT NOT NULL,
    "estimated_price" DECIMAL(10,2),
    "status" quote_status_type DEFAULT 'draft'::quote_status_type,
    "valid_until" DATE,
    "notes" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."quote_requests" ENABLE ROW LEVEL SECURITY;

-- Table des réparations
CREATE TABLE IF NOT EXISTS "public"."repairs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "client_id" UUID NOT NULL,
    "device_id" UUID,
    "description" TEXT NOT NULL,
    "status" TEXT DEFAULT 'pending',
    "estimated_price" DECIMAL(10,2),
    "final_price" DECIMAL(10,2),
    "start_date" DATE,
    "end_date" DATE,
    "notes" TEXT,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID NOT NULL,
    "workshop_id" UUID NOT NULL,
    "created_by" UUID
);

ALTER TABLE "public"."repairs" ENABLE ROW LEVEL SECURITY;

-- Table des paramètres système
CREATE TABLE IF NOT EXISTS "public"."system_settings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "key" TEXT NOT NULL UNIQUE,
    "value" JSONB NOT NULL,
    "description" TEXT,
    "is_public" BOOLEAN DEFAULT FALSE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "user_id" UUID,
    "workshop_id" UUID,
    "created_by" UUID
);

ALTER TABLE "public"."system_settings" ENABLE ROW LEVEL SECURITY;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "first_name" TEXT,
    "last_name" TEXT,
    "email" TEXT UNIQUE NOT NULL,
    "role" user_role DEFAULT 'technician'::user_role,
    "avatar" TEXT,
    "phone" TEXT,
    "is_active" BOOLEAN DEFAULT TRUE,
    "last_login" TIMESTAMP WITH TIME ZONE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "workshop_id" UUID,
    "created_by" UUID
);

ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

-- Table des ateliers
CREATE TABLE IF NOT EXISTS "public"."workshops" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "address" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "website" TEXT,
    "logo" TEXT,
    "settings" JSONB DEFAULT '{}'::JSONB,
    "is_active" BOOLEAN DEFAULT TRUE,
    "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "created_by" UUID
);

ALTER TABLE "public"."workshops" ENABLE ROW LEVEL SECURITY;
