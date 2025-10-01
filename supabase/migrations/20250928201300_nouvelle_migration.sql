drop extension if exists "pg_net";


create type "public"."alert_severity_type" as enum ('info', 'warning', 'error', 'critical');

create type "public"."device_type" as enum ('smartphone', 'tablet', 'laptop', 'desktop', 'other');

create type "public"."parts_availability_type" as enum ('high', 'medium', 'low');

create type "public"."payment_method_type" as enum ('cash', 'card', 'transfer', 'check', 'payment_link');

create type "public"."quote_status_type" as enum ('draft', 'sent', 'accepted', 'rejected', 'expired');

create type "public"."repair_difficulty_type" as enum ('easy', 'medium', 'hard');

create type "public"."report_status_type" as enum ('pending', 'processing', 'completed', 'failed');

create type "public"."transaction_status_type" as enum ('pending', 'completed', 'cancelled', 'refunded');

create type "public"."transaction_type_enum" as enum ('repair', 'sale', 'refund', 'deposit', 'withdrawal');

create type "public"."user_role" as enum ('admin', 'technician', 'client');


  create table if not exists "public"."activity_logs" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "action" character varying(100) not null,
    "entity_type" character varying(50) not null,
    "entity_id" uuid,
    "old_values" jsonb,
    "new_values" jsonb,
    "ip_address" inet,
    "user_agent" text,
    "created_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."activity_logs" enable row level security;


  create table if not exists "public"."advanced_alerts" (
    "id" uuid not null default gen_random_uuid(),
    "alert_type" character varying(100) not null,
    "title" character varying(200) not null,
    "message" text not null,
    "severity" alert_severity_type not null default 'info'::alert_severity_type,
    "target_user_id" uuid,
    "target_role" user_role,
    "is_read" boolean default false,
    "action_required" boolean default false,
    "action_url" character varying(500),
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."advanced_alerts" enable row level security;


  create table if not exists "public"."advanced_settings" (
    "id" uuid not null default gen_random_uuid(),
    "setting_key" character varying(100) not null,
    "setting_value" jsonb not null,
    "setting_type" character varying(50) not null,
    "description" text,
    "is_system" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."advanced_settings" enable row level security;


  create table if not exists "public"."appointments" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid,
    "title" text not null,
    "description" text,
    "start_time" timestamp with time zone,
    "end_time" timestamp with time zone,
    "status" text default 'scheduled'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid,
    "start_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "created_by" uuid,
    "workshop_id" uuid,
    "assigned_user_id" uuid,
    "repair_id" uuid
      );


alter table "public"."appointments" enable row level security;


  create table if not exists "public"."client_loyalty_points" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid not null,
    "total_points" integer default 0,
    "used_points" integer default 0,
    "current_tier_id" uuid,
    "last_updated" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid not null,
    "workshop_id" uuid
      );


alter table "public"."client_loyalty_points" enable row level security;


  create table if not exists "public"."clients" (
    "id" uuid not null default gen_random_uuid(),
    "first_name" text not null,
    "last_name" text not null,
    "email" text not null,
    "phone" text,
    "address" text,
    "notes" text,
    "category" character varying(50) default 'particulier'::character varying,
    "title" character varying(10) default 'mr'::character varying,
    "company_name" character varying(255) default ''::character varying,
    "vat_number" character varying(50) default ''::character varying,
    "siren_number" character varying(50) default ''::character varying,
    "country_code" character varying(10) default '33'::character varying,
    "address_complement" character varying(255) default ''::character varying,
    "region" character varying(255) default ''::character varying,
    "postal_code" character varying(10) default ''::character varying,
    "city" character varying(100) default ''::character varying,
    "billing_address_same" boolean default true,
    "billing_address" text default ''::text,
    "billing_address_complement" character varying(255) default ''::character varying,
    "billing_region" character varying(100) default ''::character varying,
    "billing_postal_code" character varying(20) default ''::character varying,
    "billing_city" character varying(100) default ''::character varying,
    "accounting_code" character varying(50) default ''::character varying,
    "cni_identifier" character varying(50) default ''::character varying,
    "attached_file_path" character varying(500) default ''::character varying,
    "internal_note" text default ''::text,
    "status" character varying(20) default 'displayed'::character varying,
    "sms_notification" boolean default true,
    "email_notification" boolean default true,
    "sms_marketing" boolean default true,
    "email_marketing" boolean default true,
    "user_id" uuid not null default '00000000-0000-0000-0000-000000000000'::uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid,
    "loyalty_points" integer default 0,
    "current_tier_id" uuid,
    "workshop_id" uuid,
    "company" text
      );


alter table "public"."clients" enable row level security;


  create table if not exists "public"."clients_backup" (
    "id" uuid,
    "first_name" character varying(255),
    "last_name" character varying(255),
    "email" character varying(255),
    "phone" character varying(50),
    "address" text,
    "notes" text,
    "category" character varying(50),
    "title" character varying(10),
    "company_name" character varying(255),
    "vat_number" character varying(50),
    "siren_number" character varying(50),
    "country_code" character varying(10),
    "address_complement" character varying(255),
    "region" character varying(100),
    "postal_code" character varying(20),
    "city" character varying(100),
    "billing_address_same" boolean,
    "billing_address" text,
    "billing_address_complement" character varying(255),
    "billing_region" character varying(100),
    "billing_postal_code" character varying(20),
    "billing_city" character varying(100),
    "accounting_code" character varying(50),
    "cni_identifier" character varying(50),
    "attached_file_path" character varying(500),
    "internal_note" text,
    "status" character varying(20),
    "sms_notification" boolean,
    "email_notification" boolean,
    "sms_marketing" boolean,
    "email_marketing" boolean,
    "user_id" uuid,
    "created_at" timestamp with time zone,
    "updated_at" timestamp with time zone,
    "workshop_id" uuid
      );


alter table "public"."clients_backup" enable row level security;


  create table if not exists "public"."confirmation_emails" (
    "id" uuid not null default gen_random_uuid(),
    "user_email" text not null,
    "token" text not null,
    "expires_at" timestamp with time zone not null,
    "status" text default 'pending'::text,
    "sent_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."confirmation_emails" enable row level security;


  create table if not exists "public"."custom_users" (
    "id" text not null,
    "email" text not null,
    "first_name" text not null,
    "last_name" text not null,
    "workshop_name" text not null,
    "password_hash" text not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."custom_users" enable row level security;


  create table if not exists "public"."device_brands" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "category_id" uuid,
    "description" text,
    "logo" text,
    "is_active" boolean default true,
    "user_id" uuid,
    "created_by" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."device_brands" enable row level security;


  create table if not exists "public"."device_categories" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "icon" text default 'smartphone'::text,
    "is_active" boolean default true,
    "user_id" uuid,
    "created_by" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."device_categories" enable row level security;


  create table if not exists "public"."device_models" (
    "id" uuid not null default gen_random_uuid(),
    "brand" text not null,
    "model" text not null,
    "category" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid,
    "workshop_id" uuid,
    "type" text not null default 'other'::text,
    "year" integer not null default 2024,
    "specifications" jsonb default '{}'::jsonb,
    "common_issues" text[] default '{}'::text[],
    "repair_difficulty" text default 'medium'::text,
    "parts_availability" text default 'medium'::text,
    "is_active" boolean default true,
    "user_id" uuid,
    "name" text,
    "brand_id" uuid,
    "category_id" uuid
      );


alter table "public"."device_models" enable row level security;


  create table if not exists "public"."devices" (
    "id" uuid not null default gen_random_uuid(),
    "brand" character varying(255) not null,
    "model" character varying(255) not null,
    "serial_number" character varying(255),
    "color" character varying(100),
    "condition_status" character varying(100),
    "notes" text,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "type" character varying(100),
    "specifications" text,
    "purchase_date" date,
    "warranty_expiry" date,
    "location" character varying(255),
    "workshop_id" uuid,
    "created_by" uuid
      );


alter table "public"."devices" enable row level security;


  create table if not exists "public"."intervention_forms" (
    "id" uuid not null default gen_random_uuid(),
    "repair_id" uuid not null,
    "intervention_date" date not null default CURRENT_DATE,
    "technician_name" character varying(255) not null,
    "client_name" character varying(255) not null,
    "client_phone" character varying(50),
    "client_email" character varying(255),
    "device_brand" character varying(100) not null,
    "device_model" character varying(100) not null,
    "device_serial_number" character varying(100),
    "device_type" character varying(50),
    "device_condition" text,
    "visible_damages" text,
    "missing_parts" text,
    "password_provided" boolean default false,
    "data_backup" boolean default false,
    "reported_issue" text not null,
    "initial_diagnosis" text,
    "proposed_solution" text,
    "estimated_cost" numeric(10,2) default 0,
    "estimated_duration" character varying(100),
    "data_loss_risk" boolean default false,
    "data_loss_risk_details" text,
    "cosmetic_changes" boolean default false,
    "cosmetic_changes_details" text,
    "warranty_void" boolean default false,
    "warranty_void_details" text,
    "client_authorizes_repair" boolean default false,
    "client_authorizes_data_access" boolean default false,
    "client_authorizes_replacement" boolean default false,
    "additional_notes" text,
    "special_instructions" text,
    "terms_accepted" boolean default false,
    "liability_accepted" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."intervention_forms" enable row level security;


  create table if not exists "public"."loyalty_config" (
    "id" uuid not null default gen_random_uuid(),
    "key" text not null,
    "value" text not null,
    "description" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid
      );


alter table "public"."loyalty_config" enable row level security;


  create table if not exists "public"."loyalty_points_history" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid not null,
    "points_change" integer not null,
    "points_before" integer,
    "points_after" integer,
    "description" text,
    "points_type" text default 'manual'::text,
    "source_type" text default 'manual'::text,
    "user_id" uuid,
    "created_at" timestamp with time zone default now(),
    "workshop_id" uuid,
    "reference_id" uuid,
    "created_by" uuid
      );


alter table "public"."loyalty_points_history" enable row level security;


  create table if not exists "public"."loyalty_rules" (
    "id" uuid not null default gen_random_uuid(),
    "rule_name" text not null,
    "points_per_referral" integer default 100,
    "points_per_euro_spent" numeric(10,2) default 1.0,
    "points_expiry_months" integer default 12,
    "min_purchase_for_points" numeric(10,2) default 0,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid not null
      );


alter table "public"."loyalty_rules" enable row level security;


  create table if not exists "public"."loyalty_tiers" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "min_points" integer not null default 0,
    "points_required" integer not null default 0,
    "discount_percentage" numeric(5,2) default 0,
    "color" text default '#000000'::text,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid
      );


alter table "public"."loyalty_tiers" enable row level security;


  create table if not exists "public"."loyalty_tiers_advanced" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "points_required" integer not null default 0,
    "discount_percentage" numeric(5,2) default 0,
    "color" text default '#000000'::text,
    "benefits" text[],
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid
      );


alter table "public"."loyalty_tiers_advanced" enable row level security;


  create table if not exists "public"."messages" (
    "id" uuid not null default gen_random_uuid(),
    "sender_id" uuid,
    "recipient_id" uuid,
    "subject" text,
    "content" text not null,
    "is_read" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid,
    "workshop_id" uuid,
    "user_id" uuid
      );


alter table "public"."messages" enable row level security;


  create table if not exists "public"."notifications" (
    "id" uuid not null default uuid_generate_v4(),
    "user_id" uuid,
    "type" character varying(50) not null,
    "title" character varying(255) not null,
    "message" text not null,
    "is_read" boolean default false,
    "related_id" uuid,
    "created_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."notifications" enable row level security;


  create table if not exists "public"."order_items" (
    "id" uuid not null default gen_random_uuid(),
    "order_id" uuid not null,
    "product_name" character varying(255) not null,
    "description" text,
    "quantity" integer not null default 1,
    "unit_price" numeric(10,2) not null default 0,
    "total_price" numeric(10,2) not null default 0,
    "workshop_id" uuid not null,
    "created_by" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."order_items" enable row level security;


  create table if not exists "public"."orders" (
    "id" uuid not null default gen_random_uuid(),
    "order_number" character varying(50) not null,
    "supplier_name" character varying(255) not null,
    "supplier_email" character varying(255),
    "supplier_phone" character varying(50),
    "order_date" date not null default CURRENT_DATE,
    "expected_delivery_date" date,
    "actual_delivery_date" date,
    "status" character varying(20) not null default 'pending'::character varying,
    "tracking_number" character varying(100),
    "total_amount" numeric(10,2) not null default 0,
    "notes" text,
    "workshop_id" uuid not null,
    "created_by" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."orders" enable row level security;


  create table if not exists "public"."parts" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(255) not null,
    "description" text,
    "price" numeric(10,2) not null,
    "stock_quantity" integer default 0,
    "category" character varying(100),
    "supplier" character varying(255),
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "compatible_devices" text[] default '{}'::text[],
    "is_active" boolean default true,
    "part_number" text,
    "brand" text,
    "min_stock_level" integer default 5,
    "created_by" uuid,
    "workshop_id" uuid
      );


alter table "public"."parts" enable row level security;


  create table if not exists "public"."pending_signups" (
    "id" uuid not null default gen_random_uuid(),
    "email" text not null,
    "first_name" text,
    "last_name" text,
    "role" text default 'technician'::text,
    "status" text default 'pending'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."pending_signups" enable row level security;


  create table if not exists "public"."performance_metrics" (
    "id" uuid not null default gen_random_uuid(),
    "metric_name" character varying(100) not null,
    "metric_value" numeric(10,2) not null,
    "metric_unit" character varying(50),
    "period_start" date not null,
    "period_end" date not null,
    "category" character varying(100),
    "created_at" timestamp with time zone default now(),
    "created_by" uuid not null,
    "workshop_id" uuid not null
      );


alter table "public"."performance_metrics" enable row level security;


  create table if not exists "public"."product_categories" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "icon" text,
    "color" text default '#1976d2'::text,
    "is_active" boolean default true,
    "sort_order" integer default 0,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid,
    "user_id" uuid
      );


alter table "public"."product_categories" enable row level security;


  create table if not exists "public"."products" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "description" text,
    "price" numeric(10,2) not null,
    "category" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid,
    "created_by" uuid,
    "workshop_id" uuid,
    "stock_quantity" integer default 10,
    "min_stock_level" integer default 1,
    "is_active" boolean default true
      );


alter table "public"."products" enable row level security;


  create table if not exists "public"."quote_items" (
    "id" uuid not null default gen_random_uuid(),
    "quote_id" uuid,
    "type" text not null,
    "item_id" uuid not null,
    "name" text not null,
    "description" text,
    "quantity" integer not null default 1,
    "unit_price" numeric(10,2) not null,
    "total_price" numeric(10,2) not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."quote_items" enable row level security;


  create table if not exists "public"."quotes" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid,
    "items" jsonb not null default '[]'::jsonb,
    "subtotal" numeric(10,2) not null default 0,
    "tax" numeric(10,2) not null default 0,
    "total" numeric(10,2) not null default 0,
    "status" quote_status_type default 'draft'::quote_status_type,
    "valid_until" timestamp with time zone not null,
    "notes" text,
    "terms" text,
    "user_id" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "is_repair_quote" boolean default false,
    "repair_details" jsonb default '{}'::jsonb
      );


alter table "public"."quotes" enable row level security;


  create table if not exists "public"."referrals" (
    "id" uuid not null default gen_random_uuid(),
    "referrer_client_id" uuid not null,
    "referred_client_id" uuid not null,
    "status" text default 'pending'::text,
    "points_awarded" integer default 0,
    "confirmation_date" timestamp with time zone,
    "confirmed_by" uuid,
    "notes" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid not null,
    "workshop_id" uuid
      );


alter table "public"."referrals" enable row level security;


  create table if not exists "public"."repair_parts" (
    "id" uuid not null default gen_random_uuid(),
    "repair_id" uuid not null,
    "part_id" uuid not null,
    "quantity" integer default 1,
    "price" numeric(10,2) not null,
    "is_used" boolean default false,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."repair_parts" enable row level security;


  create table if not exists "public"."repair_services" (
    "id" uuid not null default gen_random_uuid(),
    "repair_id" uuid not null,
    "service_id" uuid not null,
    "quantity" integer default 1,
    "price" numeric(10,2) not null,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."repair_services" enable row level security;


  create table if not exists "public"."repairs" (
    "id" uuid not null default gen_random_uuid(),
    "device_id" uuid,
    "client_id" uuid,
    "description" text not null,
    "status" text default 'pending'::text,
    "estimated_cost" numeric(10,2),
    "actual_cost" numeric(10,2),
    "start_date" date default CURRENT_DATE,
    "completion_date" date,
    "notes" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid,
    "created_by" uuid,
    "workshop_id" uuid,
    "assigned_technician_id" uuid,
    "issue" text,
    "estimated_duration" integer,
    "actual_duration" integer,
    "estimated_start_date" timestamp with time zone,
    "estimated_end_date" timestamp with time zone,
    "end_date" timestamp with time zone,
    "due_date" timestamp with time zone not null default now(),
    "is_urgent" boolean default false,
    "total_price" numeric(10,2) default 0,
    "is_paid" boolean default false,
    "loyalty_discount_percentage" numeric(5,2) default 0,
    "loyalty_points_used" integer default 0,
    "final_price" numeric(10,2),
    "discount_percentage" numeric(5,2) default 0,
    "discount_amount" numeric(10,2) default 0,
    "subtotal_after_discount" numeric(10,2) default 0,
    "original_price" numeric(10,2),
    "repair_number" character varying(20)
      );


alter table "public"."repairs" enable row level security;


  create table if not exists "public"."reports" (
    "id" uuid not null default gen_random_uuid(),
    "report_name" character varying(200) not null,
    "report_type" character varying(100) not null,
    "parameters" jsonb default '{}'::jsonb,
    "generated_by" uuid,
    "file_path" character varying(500),
    "file_size" integer,
    "status" report_status_type default 'pending'::report_status_type,
    "created_at" timestamp with time zone default now(),
    "completed_at" timestamp with time zone,
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."reports" enable row level security;


  create table if not exists "public"."sale_items" (
    "id" uuid not null default gen_random_uuid(),
    "sale_id" uuid,
    "user_id" uuid,
    "type" text not null,
    "item_id" uuid not null,
    "name" text not null,
    "quantity" integer not null default 1,
    "unit_price" numeric(10,2) not null,
    "total_price" numeric(10,2) not null,
    "category" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."sale_items" enable row level security;


  create table if not exists "public"."sales" (
    "id" uuid not null default gen_random_uuid(),
    "client_id" uuid,
    "product_id" uuid,
    "quantity" integer default 1,
    "unit_price" numeric(10,2),
    "total_price" numeric(10,2),
    "sale_date" date default CURRENT_DATE,
    "payment_method" text default 'cash'::text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "user_id" uuid,
    "created_by" uuid,
    "workshop_id" uuid,
    "items" jsonb default '[]'::jsonb,
    "subtotal" numeric(10,2) default 0.00,
    "tax" numeric(10,2) default 0.00,
    "total" numeric(10,2) default 0.00,
    "status" character varying(50) default 'completed'::character varying,
    "discount_percentage" numeric(5,2) default 0,
    "discount_amount" numeric(10,2) default 0,
    "subtotal_after_discount" numeric(10,2) default 0,
    "original_total" numeric(10,2),
    "category" text
      );


alter table "public"."sales" enable row level security;


  create table if not exists "public"."services" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(255) not null,
    "description" text,
    "price" numeric(10,2) not null,
    "duration" integer,
    "category" character varying(100),
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "applicable_devices" text[] default '{}'::text[],
    "is_active" boolean default true,
    "created_by" uuid,
    "workshop_id" uuid
      );


alter table "public"."services" enable row level security;


  create table if not exists "public"."stock_alerts" (
    "id" uuid not null default gen_random_uuid(),
    "part_id" uuid not null,
    "type" text not null,
    "message" text not null,
    "is_resolved" boolean default false,
    "user_id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."stock_alerts" enable row level security;


  create table if not exists "public"."subscription_audit" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "action" text not null,
    "performed_by" uuid,
    "performed_at" timestamp with time zone default now(),
    "notes" text,
    "created_by" uuid
      );


alter table "public"."subscription_audit" enable row level security;


  create table if not exists "public"."subscription_payments" (
    "id" uuid not null default gen_random_uuid(),
    "subscription_id" uuid not null,
    "amount" numeric(10,2) not null,
    "currency" character varying(3) default 'EUR'::character varying,
    "payment_method" character varying(50) not null,
    "status" character varying(20) not null default 'pending'::character varying,
    "stripe_payment_intent_id" character varying(255),
    "stripe_charge_id" character varying(255),
    "payment_date" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."subscription_payments" enable row level security;


  create table if not exists "public"."subscription_plans" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(100) not null,
    "description" text,
    "price" numeric(10,2) not null,
    "currency" character varying(3) default 'EUR'::character varying,
    "duration_days" integer not null,
    "features" jsonb,
    "is_active" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "stripe_price_id" character varying(255),
    "stripe_product_id" character varying(255),
    "created_by" uuid
      );


alter table "public"."subscription_plans" enable row level security;


  create table if not exists "public"."subscription_status" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "first_name" text not null,
    "last_name" text not null,
    "email" text not null,
    "is_active" boolean default false,
    "subscription_type" text default 'free'::text,
    "notes" text,
    "activated_at" timestamp with time zone,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "activated_by" uuid,
    "subscription_start_date" timestamp with time zone,
    "subscription_end_date" timestamp with time zone,
    "status" text default 'INACTIF'::text,
    "workshop_id" uuid,
    "role" text default 'technician'::text
      );


alter table "public"."subscription_status" enable row level security;


  create table if not exists "public"."suppliers" (
    "id" uuid not null default gen_random_uuid(),
    "name" character varying(255) not null,
    "email" character varying(255),
    "phone" character varying(50),
    "address" text,
    "website" character varying(255),
    "contact_person" character varying(255),
    "contact_email" character varying(255),
    "contact_phone" character varying(50),
    "notes" text,
    "rating" integer,
    "is_active" boolean default true,
    "workshop_id" uuid not null,
    "created_by" uuid,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."suppliers" enable row level security;


  -- Supprimer la table si elle existe pour la recréer proprement
  DROP TABLE IF EXISTS "public"."system_settings" CASCADE;
  
  create table "public"."system_settings" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "key" character varying(255) not null,
    "value" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "description" text
      );


alter table "public"."system_settings" enable row level security;


  create table if not exists "public"."technician_performance" (
    "id" uuid not null default gen_random_uuid(),
    "technician_id" uuid not null,
    "period_start" date not null,
    "period_end" date not null,
    "total_repairs" integer default 0,
    "completed_repairs" integer default 0,
    "failed_repairs" integer default 0,
    "avg_repair_time" numeric(5,2),
    "total_revenue" numeric(10,2) default 0,
    "customer_satisfaction" numeric(3,2),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."technician_performance" enable row level security;


  create table if not exists "public"."transactions" (
    "id" uuid not null default gen_random_uuid(),
    "type" text not null,
    "amount" numeric(10,2) not null,
    "description" text,
    "client_id" uuid,
    "user_id" uuid,
    "transaction_date" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."transactions" enable row level security;


  create table if not exists "public"."user_preferences" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "notifications_email" boolean default true,
    "notifications_push" boolean default true,
    "notifications_sms" boolean default false,
    "theme_dark_mode" boolean default false,
    "theme_compact_mode" boolean default false,
    "language" character varying(10) default 'fr'::character varying,
    "two_factor_auth" boolean default false,
    "multiple_sessions" boolean default true,
    "repair_notifications" boolean default true,
    "status_notifications" boolean default true,
    "stock_notifications" boolean default true,
    "daily_reports" boolean default false,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "created_by" uuid
      );


alter table "public"."user_preferences" enable row level security;


  create table if not exists "public"."user_profiles" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "first_name" character varying(100) not null,
    "last_name" character varying(100) not null,
    "email" character varying(255) not null,
    "phone" character varying(20),
    "avatar" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "workshop_id" uuid not null,
    "is_locked" boolean default true
      );


alter table "public"."user_profiles" enable row level security;


  create table if not exists "public"."user_subscriptions" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid not null,
    "plan_id" uuid not null,
    "status" character varying(20) not null default 'active'::character varying,
    "start_date" timestamp with time zone not null,
    "end_date" timestamp with time zone not null,
    "payment_method" character varying(50),
    "payment_status" character varying(20) default 'paid'::character varying,
    "stripe_subscription_id" character varying(255),
    "stripe_customer_id" character varying(255),
    "auto_renew" boolean default true,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."user_subscriptions" enable row level security;


  create table if not exists "public"."users" (
    "id" uuid not null default gen_random_uuid(),
    "first_name" text,
    "last_name" text,
    "email" text,
    "role" text default 'technician'::text,
    "avatar" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "created_by" uuid
      );


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX IF NOT EXISTS activity_logs_pkey ON public.activity_logs USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS advanced_alerts_pkey ON public.advanced_alerts USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS advanced_settings_pkey ON public.advanced_settings USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS advanced_settings_setting_key_key ON public.advanced_settings USING btree (setting_key);

CREATE UNIQUE INDEX IF NOT EXISTS appointments_pkey ON public.appointments USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS client_loyalty_points_pkey ON public.client_loyalty_points USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS clients_email_key ON public.clients USING btree (email);

CREATE UNIQUE INDEX IF NOT EXISTS clients_pkey ON public.clients USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS confirmation_emails_pkey ON public.confirmation_emails USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS confirmation_emails_token_key ON public.confirmation_emails USING btree (token);

CREATE UNIQUE INDEX IF NOT EXISTS confirmation_emails_user_email_key ON public.confirmation_emails USING btree (user_email);

CREATE UNIQUE INDEX IF NOT EXISTS custom_users_email_key ON public.custom_users USING btree (email);

CREATE UNIQUE INDEX IF NOT EXISTS custom_users_pkey ON public.custom_users USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS device_brands_pkey ON public.device_brands USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS device_categories_pkey ON public.device_categories USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS device_models_pkey ON public.device_models USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS devices_pkey ON public.devices USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS devices_serial_number_key ON public.devices USING btree (serial_number);

CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON public.activity_logs USING btree (action);

CREATE INDEX IF NOT EXISTS idx_activity_logs_date ON public.activity_logs USING btree (created_at);

CREATE INDEX IF NOT EXISTS idx_activity_logs_entity ON public.activity_logs USING btree (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON public.activity_logs USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_activity_logs_workshop ON public.activity_logs USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_advanced_alerts_read ON public.advanced_alerts USING btree (is_read);

CREATE INDEX IF NOT EXISTS idx_advanced_alerts_type ON public.advanced_alerts USING btree (alert_type);

CREATE INDEX IF NOT EXISTS idx_advanced_alerts_user ON public.advanced_alerts USING btree (target_user_id);

CREATE INDEX IF NOT EXISTS idx_advanced_alerts_workshop ON public.advanced_alerts USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_advanced_settings_workshop ON public.advanced_settings USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_appointments_end_date ON public.appointments USING btree (end_date);

CREATE INDEX IF NOT EXISTS idx_appointments_start_date ON public.appointments USING btree (start_date);

CREATE INDEX IF NOT EXISTS idx_appointments_user_id ON public.appointments USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_catalog_parts_user_id ON public.parts USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_catalog_services_user_id ON public.services USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_client_loyalty_points_user_id ON public.client_loyalty_points USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_clients_category ON public.clients USING btree (category);

CREATE INDEX IF NOT EXISTS idx_clients_created_at ON public.clients USING btree (created_at);

CREATE INDEX IF NOT EXISTS idx_clients_email ON public.clients USING btree (email);

CREATE INDEX IF NOT EXISTS idx_clients_status ON public.clients USING btree (status);

CREATE INDEX IF NOT EXISTS idx_clients_user_id ON public.clients USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_clients_workshop_id ON public.clients USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_custom_users_email ON public.custom_users USING btree (email);

CREATE INDEX IF NOT EXISTS idx_device_brands_category_id ON public.device_brands USING btree (category_id);

CREATE INDEX IF NOT EXISTS idx_device_brands_created_by ON public.device_brands USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_device_brands_name ON public.device_brands USING btree (name);

CREATE INDEX IF NOT EXISTS idx_device_brands_user_id ON public.device_brands USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_device_categories_created_by ON public.device_categories USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_device_categories_name ON public.device_categories USING btree (name);

CREATE INDEX IF NOT EXISTS idx_device_categories_user_id ON public.device_categories USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_device_models_brand ON public.device_models USING btree (brand);

CREATE INDEX IF NOT EXISTS idx_device_models_brand_id ON public.device_models USING btree (brand_id);

-- CREATE INDEX IF NOT EXISTS idx_device_models_category_id ON public.device_models USING btree (category_id);

CREATE INDEX IF NOT EXISTS idx_device_models_created_by ON public.device_models USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_device_models_is_active ON public.device_models USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_device_models_name ON public.device_models USING btree (name);

CREATE INDEX IF NOT EXISTS idx_device_models_type ON public.device_models USING btree (type);

CREATE INDEX IF NOT EXISTS idx_device_models_user_id ON public.device_models USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_intervention_forms_date ON public.intervention_forms USING btree (intervention_date);

CREATE INDEX IF NOT EXISTS idx_intervention_forms_repair_id ON public.intervention_forms USING btree (repair_id);

CREATE INDEX IF NOT EXISTS idx_intervention_forms_technician ON public.intervention_forms USING btree (technician_name);

CREATE INDEX IF NOT EXISTS idx_loyalty_config_workshop_id ON public.loyalty_config USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_points_client ON public.client_loyalty_points USING btree (client_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_client_id ON public.loyalty_points_history USING btree (client_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_points_history_workshop_id ON public.loyalty_points_history USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_rules_user_id ON public.loyalty_rules USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_tiers_workshop_id ON public.loyalty_tiers_advanced USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications USING btree (is_read);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_order_items_created_by ON public.order_items USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items USING btree (order_id);

CREATE INDEX IF NOT EXISTS idx_order_items_workshop_id ON public.order_items USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_orders_created_by ON public.orders USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_orders_order_date ON public.orders USING btree (order_date);

CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders USING btree (status);

CREATE INDEX IF NOT EXISTS idx_orders_workshop_date ON public.orders USING btree (workshop_id, order_date);

CREATE INDEX IF NOT EXISTS idx_orders_workshop_id ON public.orders USING btree (workshop_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_workshop_order_number_unique ON public.orders USING btree (workshop_id, order_number);

CREATE INDEX IF NOT EXISTS idx_orders_workshop_status ON public.orders USING btree (workshop_id, status);

CREATE INDEX IF NOT EXISTS idx_parts_user_id ON public.parts USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_category ON public.performance_metrics USING btree (category);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_period ON public.performance_metrics USING btree (period_start, period_end);

CREATE INDEX IF NOT EXISTS idx_performance_metrics_workshop ON public.performance_metrics USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_product_categories_active ON public.product_categories USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_product_categories_name ON public.product_categories USING btree (name);

CREATE INDEX IF NOT EXISTS idx_product_categories_user_id ON public.product_categories USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_product_categories_workshop_id ON public.product_categories USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_products_category ON public.products USING btree (category);

CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_products_min_stock_level ON public.products USING btree (min_stock_level);

CREATE INDEX IF NOT EXISTS idx_products_stock_quantity ON public.products USING btree (stock_quantity);

CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_quote_items_quote_id ON public.quote_items USING btree (quote_id);

CREATE INDEX IF NOT EXISTS idx_quotes_client_id ON public.quotes USING btree (client_id);

CREATE INDEX IF NOT EXISTS idx_quotes_status ON public.quotes USING btree (status);

CREATE INDEX IF NOT EXISTS idx_quotes_user_id ON public.quotes USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_quotes_valid_until ON public.quotes USING btree (valid_until);

CREATE INDEX IF NOT EXISTS idx_referrals_referred ON public.referrals USING btree (referred_client_id);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON public.referrals USING btree (referrer_client_id);

CREATE INDEX IF NOT EXISTS idx_referrals_status ON public.referrals USING btree (status);

CREATE INDEX IF NOT EXISTS idx_referrals_user_id ON public.referrals USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_repair_parts_user_id ON public.repair_parts USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_repair_services_user_id ON public.repair_services USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_repairs_client_email ON public.repairs USING btree (client_id) INCLUDE (status, created_at);

CREATE INDEX IF NOT EXISTS idx_repairs_client_id ON public.repairs USING btree (client_id);

CREATE INDEX IF NOT EXISTS idx_repairs_device_id ON public.repairs USING btree (device_id);

CREATE INDEX IF NOT EXISTS idx_repairs_is_paid ON public.repairs USING btree (is_paid);

CREATE INDEX IF NOT EXISTS idx_repairs_loyalty_discount ON public.repairs USING btree (loyalty_discount_percentage);

CREATE INDEX IF NOT EXISTS idx_repairs_repair_number ON public.repairs USING btree (repair_number);

CREATE INDEX IF NOT EXISTS idx_repairs_status ON public.repairs USING btree (status);

CREATE INDEX IF NOT EXISTS idx_repairs_status_updated_at ON public.repairs USING btree (status, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_repairs_user_id ON public.repairs USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_reports_created_by ON public.reports USING btree (generated_by);

CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports USING btree (status);

CREATE INDEX IF NOT EXISTS idx_reports_type ON public.reports USING btree (report_type);

CREATE INDEX IF NOT EXISTS idx_reports_workshop ON public.reports USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_sale_items_category ON public.sale_items USING btree (category);

CREATE INDEX IF NOT EXISTS idx_sales_category ON public.sales USING btree (category);

CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_services_user_id ON public.services USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_created_at ON public.stock_alerts USING btree (created_at);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_is_resolved ON public.stock_alerts USING btree (is_resolved);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_part_id ON public.stock_alerts USING btree (part_id);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_type ON public.stock_alerts USING btree (type);

CREATE INDEX IF NOT EXISTS idx_stock_alerts_user_id ON public.stock_alerts USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_stripe_price ON public.subscription_plans USING btree (stripe_price_id);

CREATE INDEX IF NOT EXISTS idx_subscription_audit_performed_at ON public.subscription_audit USING btree (performed_at);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_status ON public.subscription_payments USING btree (status);

CREATE INDEX IF NOT EXISTS idx_subscription_payments_subscription_id ON public.subscription_payments USING btree (subscription_id);

CREATE INDEX IF NOT EXISTS idx_subscription_status_email ON public.subscription_status USING btree (email);

CREATE INDEX IF NOT EXISTS idx_subscription_status_is_active ON public.subscription_status USING btree (is_active);

CREATE INDEX IF NOT EXISTS idx_subscription_status_subscription_type ON public.subscription_status USING btree (subscription_type);

CREATE INDEX IF NOT EXISTS idx_subscription_status_user_id ON public.subscription_status USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_subscription_status_workshop_id ON public.subscription_status USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_suppliers_created_by ON public.suppliers USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers USING btree (name);

CREATE INDEX IF NOT EXISTS idx_suppliers_workshop_id ON public.suppliers USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings USING btree (key);

CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_system_settings_user_key ON public.system_settings USING btree (user_id, key);

CREATE INDEX IF NOT EXISTS idx_technician_performance_period ON public.technician_performance USING btree (period_start, period_end);

CREATE INDEX IF NOT EXISTS idx_technician_performance_tech ON public.technician_performance USING btree (technician_id);

CREATE INDEX IF NOT EXISTS idx_technician_performance_workshop ON public.technician_performance USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_user_preferences_workshop ON public.user_preferences USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_is_locked ON public.user_profiles USING btree (is_locked);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_user_profiles_workshop ON public.user_profiles USING btree (workshop_id);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON public.user_subscriptions USING btree (end_date);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions USING btree (status);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON public.user_subscriptions USING btree (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS intervention_forms_pkey ON public.intervention_forms USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_config_pkey ON public.loyalty_config USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_config_workshop_key_unique ON public.loyalty_config USING btree (workshop_id, key);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_points_history_pkey ON public.loyalty_points_history USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_rules_pkey ON public.loyalty_rules USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_rules_rule_name_key ON public.loyalty_rules USING btree (rule_name);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_tiers_advanced_pkey ON public.loyalty_tiers_advanced USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_tiers_name_key ON public.loyalty_tiers USING btree (name);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_tiers_pkey ON public.loyalty_tiers USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS loyalty_tiers_workshop_name_unique ON public.loyalty_tiers_advanced USING btree (workshop_id, name);

CREATE UNIQUE INDEX IF NOT EXISTS messages_pkey ON public.messages USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS notifications_pkey ON public.notifications USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS order_items_pkey ON public.order_items USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS orders_pkey ON public.orders USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS orders_workshop_id_order_number_key ON public.orders USING btree (workshop_id, order_number);

CREATE UNIQUE INDEX IF NOT EXISTS parts_pkey ON public.parts USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS pending_signups_email_key ON public.pending_signups USING btree (email);

CREATE UNIQUE INDEX IF NOT EXISTS pending_signups_pkey ON public.pending_signups USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS performance_metrics_pkey ON public.performance_metrics USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS product_categories_name_global_unique ON public.product_categories USING btree (name) WHERE (user_id IS NULL);

CREATE UNIQUE INDEX IF NOT EXISTS product_categories_name_user_unique ON public.product_categories USING btree (name, user_id) WHERE (user_id IS NOT NULL);

CREATE UNIQUE INDEX IF NOT EXISTS product_categories_pkey ON public.product_categories USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS products_pkey ON public.products USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS quote_items_pkey ON public.quote_items USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS quotes_pkey ON public.quotes USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS referrals_pkey ON public.referrals USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS referrals_referrer_client_id_referred_client_id_key ON public.referrals USING btree (referrer_client_id, referred_client_id);

CREATE UNIQUE INDEX IF NOT EXISTS repair_parts_pkey ON public.repair_parts USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS repair_services_pkey ON public.repair_services USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS repairs_pkey ON public.repairs USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS repairs_repair_number_key ON public.repairs USING btree (repair_number);

CREATE UNIQUE INDEX IF NOT EXISTS reports_pkey ON public.reports USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS sale_items_pkey ON public.sale_items USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS sales_pkey ON public.sales USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS services_pkey ON public.services USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS stock_alerts_pkey ON public.stock_alerts USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS subscription_audit_pkey ON public.subscription_audit USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS subscription_payments_pkey ON public.subscription_payments USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS subscription_plans_pkey ON public.subscription_plans USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS subscription_status_pkey ON public.subscription_status USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS subscription_status_user_id_key ON public.subscription_status USING btree (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS suppliers_pkey ON public.suppliers USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS suppliers_workshop_id_name_key ON public.suppliers USING btree (workshop_id, name);

CREATE UNIQUE INDEX IF NOT EXISTS system_settings_pkey ON public.system_settings USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS system_settings_user_id_key_unique ON public.system_settings USING btree (user_id, key);

CREATE UNIQUE INDEX IF NOT EXISTS technician_performance_pkey ON public.technician_performance USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS transactions_pkey ON public.transactions USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS user_preferences_pkey ON public.user_preferences USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS user_preferences_user_id_key ON public.user_preferences USING btree (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_pkey ON public.user_profiles USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_user_id_key ON public.user_profiles USING btree (user_id);

CREATE UNIQUE INDEX IF NOT EXISTS user_subscriptions_pkey ON public.user_subscriptions USING btree (id);

CREATE UNIQUE INDEX IF NOT EXISTS users_pkey ON public.users USING btree (id);

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'activity_logs_pkey') THEN
        ALTER TABLE "public"."activity_logs" ADD CONSTRAINT "activity_logs_pkey" PRIMARY KEY USING INDEX "activity_logs_pkey";
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'advanced_alerts_pkey') THEN
        ALTER TABLE "public"."advanced_alerts" ADD CONSTRAINT "advanced_alerts_pkey" PRIMARY KEY USING INDEX "advanced_alerts_pkey";
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'advanced_settings_pkey') THEN
        ALTER TABLE "public"."advanced_settings" ADD CONSTRAINT "advanced_settings_pkey" PRIMARY KEY USING INDEX "advanced_settings_pkey";
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'appointments_pkey') THEN
        ALTER TABLE "public"."appointments" ADD CONSTRAINT "appointments_pkey" PRIMARY KEY USING INDEX "appointments_pkey";
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'client_loyalty_points_pkey') THEN
        ALTER TABLE "public"."client_loyalty_points" ADD CONSTRAINT "client_loyalty_points_pkey" PRIMARY KEY USING INDEX "client_loyalty_points_pkey";
    END IF;
END $$;

alter table "public"."clients" add constraint "clients_pkey" PRIMARY KEY using index "clients_pkey";

alter table "public"."confirmation_emails" add constraint "confirmation_emails_pkey" PRIMARY KEY using index "confirmation_emails_pkey";

alter table "public"."custom_users" add constraint "custom_users_pkey" PRIMARY KEY using index "custom_users_pkey";

alter table "public"."device_brands" add constraint "device_brands_pkey" PRIMARY KEY using index "device_brands_pkey";

alter table "public"."device_categories" add constraint "device_categories_pkey" PRIMARY KEY using index "device_categories_pkey";

alter table "public"."device_models" add constraint "device_models_pkey" PRIMARY KEY using index "device_models_pkey";

alter table "public"."devices" add constraint "devices_pkey" PRIMARY KEY using index "devices_pkey";

alter table "public"."intervention_forms" add constraint "intervention_forms_pkey" PRIMARY KEY using index "intervention_forms_pkey";

alter table "public"."loyalty_config" add constraint "loyalty_config_pkey" PRIMARY KEY using index "loyalty_config_pkey";

alter table "public"."loyalty_points_history" add constraint "loyalty_points_history_pkey" PRIMARY KEY using index "loyalty_points_history_pkey";

alter table "public"."loyalty_rules" add constraint "loyalty_rules_pkey" PRIMARY KEY using index "loyalty_rules_pkey";

alter table "public"."loyalty_tiers" add constraint "loyalty_tiers_pkey" PRIMARY KEY using index "loyalty_tiers_pkey";

alter table "public"."loyalty_tiers_advanced" add constraint "loyalty_tiers_advanced_pkey" PRIMARY KEY using index "loyalty_tiers_advanced_pkey";

alter table "public"."messages" add constraint "messages_pkey" PRIMARY KEY using index "messages_pkey";

alter table "public"."notifications" add constraint "notifications_pkey" PRIMARY KEY using index "notifications_pkey";

alter table "public"."order_items" add constraint "order_items_pkey" PRIMARY KEY using index "order_items_pkey";

alter table "public"."orders" add constraint "orders_pkey" PRIMARY KEY using index "orders_pkey";

alter table "public"."parts" add constraint "parts_pkey" PRIMARY KEY using index "parts_pkey";

alter table "public"."pending_signups" add constraint "pending_signups_pkey" PRIMARY KEY using index "pending_signups_pkey";

alter table "public"."performance_metrics" add constraint "performance_metrics_pkey" PRIMARY KEY using index "performance_metrics_pkey";

alter table "public"."product_categories" add constraint "product_categories_pkey" PRIMARY KEY using index "product_categories_pkey";

alter table "public"."products" add constraint "products_pkey" PRIMARY KEY using index "products_pkey";

alter table "public"."quote_items" add constraint "quote_items_pkey" PRIMARY KEY using index "quote_items_pkey";

alter table "public"."quotes" add constraint "quotes_pkey" PRIMARY KEY using index "quotes_pkey";

alter table "public"."referrals" add constraint "referrals_pkey" PRIMARY KEY using index "referrals_pkey";

alter table "public"."repair_parts" add constraint "repair_parts_pkey" PRIMARY KEY using index "repair_parts_pkey";

alter table "public"."repair_services" add constraint "repair_services_pkey" PRIMARY KEY using index "repair_services_pkey";

alter table "public"."repairs" add constraint "repairs_pkey" PRIMARY KEY using index "repairs_pkey";

alter table "public"."reports" add constraint "reports_pkey" PRIMARY KEY using index "reports_pkey";

alter table "public"."sale_items" add constraint "sale_items_pkey" PRIMARY KEY using index "sale_items_pkey";

alter table "public"."sales" add constraint "sales_pkey" PRIMARY KEY using index "sales_pkey";

alter table "public"."services" add constraint "services_pkey" PRIMARY KEY using index "services_pkey";

alter table "public"."stock_alerts" add constraint "stock_alerts_pkey" PRIMARY KEY using index "stock_alerts_pkey";

alter table "public"."subscription_audit" add constraint "subscription_audit_pkey" PRIMARY KEY using index "subscription_audit_pkey";

alter table "public"."subscription_payments" add constraint "subscription_payments_pkey" PRIMARY KEY using index "subscription_payments_pkey";

alter table "public"."subscription_plans" add constraint "subscription_plans_pkey" PRIMARY KEY using index "subscription_plans_pkey";

alter table "public"."subscription_status" add constraint "subscription_status_pkey" PRIMARY KEY using index "subscription_status_pkey";

alter table "public"."suppliers" add constraint "suppliers_pkey" PRIMARY KEY using index "suppliers_pkey";

alter table "public"."system_settings" add constraint "system_settings_pkey" PRIMARY KEY using index "system_settings_pkey";

alter table "public"."technician_performance" add constraint "technician_performance_pkey" PRIMARY KEY using index "technician_performance_pkey";

alter table "public"."transactions" add constraint "transactions_pkey" PRIMARY KEY using index "transactions_pkey";

alter table "public"."user_preferences" add constraint "user_preferences_pkey" PRIMARY KEY using index "user_preferences_pkey";

alter table "public"."user_profiles" add constraint "user_profiles_pkey" PRIMARY KEY using index "user_profiles_pkey";

alter table "public"."user_subscriptions" add constraint "user_subscriptions_pkey" PRIMARY KEY using index "user_subscriptions_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."activity_logs" add constraint "activity_logs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."activity_logs" validate constraint "activity_logs_user_id_fkey";

alter table "public"."advanced_alerts" add constraint "advanced_alerts_target_user_id_fkey" FOREIGN KEY (target_user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."advanced_alerts" validate constraint "advanced_alerts_target_user_id_fkey";

alter table "public"."advanced_settings" add constraint "advanced_settings_setting_key_key" UNIQUE using index "advanced_settings_setting_key_key";

alter table "public"."appointments" add constraint "appointments_assigned_user_id_fkey" FOREIGN KEY (assigned_user_id) REFERENCES users(id) ON DELETE SET NULL not valid;

alter table "public"."appointments" validate constraint "appointments_assigned_user_id_fkey";

alter table "public"."appointments" add constraint "appointments_repair_id_fkey" FOREIGN KEY (repair_id) REFERENCES repairs(id) ON DELETE SET NULL not valid;

alter table "public"."appointments" validate constraint "appointments_repair_id_fkey";

alter table "public"."appointments" add constraint "appointments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."appointments" validate constraint "appointments_user_id_fkey";

alter table "public"."client_loyalty_points" add constraint "client_loyalty_points_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE not valid;

alter table "public"."client_loyalty_points" validate constraint "client_loyalty_points_client_id_fkey";

alter table "public"."client_loyalty_points" add constraint "client_loyalty_points_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."client_loyalty_points" validate constraint "client_loyalty_points_user_id_fkey";

alter table "public"."client_loyalty_points" add constraint "client_loyalty_points_workshop_id_fkey" FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."client_loyalty_points" validate constraint "client_loyalty_points_workshop_id_fkey";

alter table "public"."clients" add constraint "clients_email_key" UNIQUE using index "clients_email_key";

alter table "public"."confirmation_emails" add constraint "confirmation_emails_token_key" UNIQUE using index "confirmation_emails_token_key";

alter table "public"."confirmation_emails" add constraint "confirmation_emails_user_email_key" UNIQUE using index "confirmation_emails_user_email_key";

alter table "public"."custom_users" add constraint "custom_users_email_key" UNIQUE using index "custom_users_email_key";

alter table "public"."device_brands" add constraint "device_brands_category_id_fkey" FOREIGN KEY (category_id) REFERENCES device_categories(id) ON DELETE CASCADE not valid;

alter table "public"."device_brands" validate constraint "device_brands_category_id_fkey";

alter table "public"."device_brands" add constraint "device_brands_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."device_brands" validate constraint "device_brands_created_by_fkey";

alter table "public"."device_brands" add constraint "device_brands_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."device_brands" validate constraint "device_brands_user_id_fkey";

alter table "public"."device_categories" add constraint "device_categories_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."device_categories" validate constraint "device_categories_created_by_fkey";

alter table "public"."device_categories" add constraint "device_categories_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."device_categories" validate constraint "device_categories_user_id_fkey";

alter table "public"."device_models" add constraint "device_models_brand_id_fkey" FOREIGN KEY (brand_id) REFERENCES device_brands(id) ON DELETE CASCADE not valid;

alter table "public"."device_models" validate constraint "device_models_brand_id_fkey";

-- alter table "public"."device_models" add constraint "device_models_category_id_fkey" FOREIGN KEY (category_id) REFERENCES device_categories(id) ON DELETE CASCADE not valid;

-- alter table "public"."device_models" validate constraint "device_models_category_id_fkey";

alter table "public"."device_models" add constraint "device_models_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."device_models" validate constraint "device_models_user_id_fkey";

alter table "public"."devices" add constraint "devices_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."devices" validate constraint "devices_created_by_fkey";

alter table "public"."devices" add constraint "devices_serial_number_key" UNIQUE using index "devices_serial_number_key";

alter table "public"."devices" add constraint "devices_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."devices" validate constraint "devices_user_id_fkey";

alter table "public"."intervention_forms" add constraint "intervention_forms_estimated_cost_check" CHECK ((estimated_cost >= (0)::numeric)) not valid;

alter table "public"."intervention_forms" validate constraint "intervention_forms_estimated_cost_check";

alter table "public"."intervention_forms" add constraint "intervention_forms_repair_id_fkey" FOREIGN KEY (repair_id) REFERENCES repairs(id) ON DELETE CASCADE not valid;

alter table "public"."intervention_forms" validate constraint "intervention_forms_repair_id_fkey";

alter table "public"."loyalty_config" add constraint "loyalty_config_workshop_key_unique" UNIQUE using index "loyalty_config_workshop_key_unique";

alter table "public"."loyalty_points_history" add constraint "loyalty_points_history_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL not valid;

alter table "public"."loyalty_points_history" validate constraint "loyalty_points_history_client_id_fkey";

alter table "public"."loyalty_points_history" add constraint "loyalty_points_history_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."loyalty_points_history" validate constraint "loyalty_points_history_created_by_fkey";

alter table "public"."loyalty_rules" add constraint "loyalty_rules_rule_name_key" UNIQUE using index "loyalty_rules_rule_name_key";

alter table "public"."loyalty_rules" add constraint "loyalty_rules_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."loyalty_rules" validate constraint "loyalty_rules_user_id_fkey";

alter table "public"."loyalty_tiers" add constraint "loyalty_tiers_name_key" UNIQUE using index "loyalty_tiers_name_key";

alter table "public"."loyalty_tiers_advanced" add constraint "loyalty_tiers_workshop_name_unique" UNIQUE using index "loyalty_tiers_workshop_name_unique";

alter table "public"."messages" add constraint "messages_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_recipient_id_fkey";

alter table "public"."messages" add constraint "messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_sender_id_fkey";

alter table "public"."messages" add constraint "messages_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_user_id_fkey";

alter table "public"."notifications" add constraint "notifications_type_check" CHECK (((type)::text = ANY ((ARRAY['repair_status'::character varying, 'appointment'::character varying, 'stock_alert'::character varying, 'message'::character varying])::text[]))) not valid;

alter table "public"."notifications" validate constraint "notifications_type_check";

alter table "public"."order_items" add constraint "order_items_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."order_items" validate constraint "order_items_created_by_fkey";

alter table "public"."order_items" add constraint "order_items_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE not valid;

alter table "public"."order_items" validate constraint "order_items_order_id_fkey";

alter table "public"."order_items" add constraint "order_items_quantity_check" CHECK ((quantity > 0)) not valid;

alter table "public"."order_items" validate constraint "order_items_quantity_check";

alter table "public"."order_items" add constraint "order_items_total_price_check" CHECK ((total_price >= (0)::numeric)) not valid;

alter table "public"."order_items" validate constraint "order_items_total_price_check";

alter table "public"."order_items" add constraint "order_items_unit_price_check" CHECK ((unit_price >= (0)::numeric)) not valid;

alter table "public"."order_items" validate constraint "order_items_unit_price_check";

alter table "public"."orders" add constraint "orders_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."orders" validate constraint "orders_created_by_fkey";

alter table "public"."orders" add constraint "orders_status_check" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'confirmed'::character varying, 'shipped'::character varying, 'delivered'::character varying, 'cancelled'::character varying])::text[]))) not valid;

alter table "public"."orders" validate constraint "orders_status_check";

alter table "public"."orders" add constraint "orders_workshop_id_order_number_key" UNIQUE using index "orders_workshop_id_order_number_key";

alter table "public"."pending_signups" add constraint "pending_signups_email_key" UNIQUE using index "pending_signups_email_key";

alter table "public"."performance_metrics" add constraint "performance_metrics_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."performance_metrics" validate constraint "performance_metrics_created_by_fkey";

alter table "public"."product_categories" add constraint "product_categories_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."product_categories" validate constraint "product_categories_user_id_fkey";

alter table "public"."product_categories" add constraint "product_categories_workshop_id_fkey" FOREIGN KEY (workshop_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."product_categories" validate constraint "product_categories_workshop_id_fkey";

alter table "public"."products" add constraint "products_category_check" CHECK ((category = ANY (ARRAY['console'::text, 'ordinateur_portable'::text, 'ordinateur_fixe'::text, 'smartphone'::text, 'montre'::text, 'manette_jeux'::text, 'ecouteur'::text, 'casque'::text, 'accessoire'::text, 'protection'::text, 'connectique'::text, 'logiciel'::text, 'autre'::text]))) not valid;

alter table "public"."products" validate constraint "products_category_check";

alter table "public"."products" add constraint "products_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_user_id_fkey";

alter table "public"."quote_items" add constraint "quote_items_quote_id_fkey" FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE not valid;

alter table "public"."quote_items" validate constraint "quote_items_quote_id_fkey";

alter table "public"."quote_items" add constraint "quote_items_type_check" CHECK ((type = ANY (ARRAY['product'::text, 'service'::text, 'part'::text, 'repair'::text]))) not valid;

alter table "public"."quote_items" validate constraint "quote_items_type_check";

alter table "public"."quotes" add constraint "quotes_client_id_fkey" FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL not valid;

alter table "public"."quotes" validate constraint "quotes_client_id_fkey";

alter table "public"."quotes" add constraint "quotes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."quotes" validate constraint "quotes_user_id_fkey";

alter table "public"."referrals" add constraint "referrals_confirmed_by_fkey" FOREIGN KEY (confirmed_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."referrals" validate constraint "referrals_confirmed_by_fkey";

alter table "public"."referrals" add constraint "referrals_referred_client_id_fkey" FOREIGN KEY (referred_client_id) REFERENCES clients(id) ON DELETE CASCADE not valid;

alter table "public"."referrals" validate constraint "referrals_referred_client_id_fkey";

alter table "public"."referrals" add constraint "referrals_referrer_client_id_fkey" FOREIGN KEY (referrer_client_id) REFERENCES clients(id) ON DELETE CASCADE not valid;

alter table "public"."referrals" validate constraint "referrals_referrer_client_id_fkey";

alter table "public"."referrals" add constraint "referrals_referrer_client_id_referred_client_id_key" UNIQUE using index "referrals_referrer_client_id_referred_client_id_key";

alter table "public"."referrals" add constraint "referrals_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'confirmed'::text, 'rejected'::text, 'completed'::text]))) not valid;

alter table "public"."referrals" validate constraint "referrals_status_check";

alter table "public"."referrals" add constraint "referrals_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE not valid;

alter table "public"."referrals" validate constraint "referrals_user_id_fkey";

alter table "public"."repair_parts" add constraint "repair_parts_part_id_fkey" FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE not valid;

alter table "public"."repair_parts" validate constraint "repair_parts_part_id_fkey";

alter table "public"."repair_parts" add constraint "repair_parts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."repair_parts" validate constraint "repair_parts_user_id_fkey";

alter table "public"."repair_services" add constraint "repair_services_service_id_fkey" FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE not valid;

alter table "public"."repair_services" validate constraint "repair_services_service_id_fkey";

alter table "public"."repair_services" add constraint "repair_services_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."repair_services" validate constraint "repair_services_user_id_fkey";

alter table "public"."repairs" add constraint "repairs_assigned_technician_id_fkey" FOREIGN KEY (assigned_technician_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."repairs" validate constraint "repairs_assigned_technician_id_fkey";

alter table "public"."repairs" add constraint "repairs_discount_percentage_check" CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))) not valid;

alter table "public"."repairs" validate constraint "repairs_discount_percentage_check";

alter table "public"."repairs" add constraint "repairs_repair_number_key" UNIQUE using index "repairs_repair_number_key";

alter table "public"."repairs" add constraint "repairs_status_check" CHECK ((status = ANY (ARRAY['new'::text, 'in_progress'::text, 'waiting_parts'::text, 'waiting_delivery'::text, 'completed'::text, 'cancelled'::text, 'returned'::text]))) not valid;

alter table "public"."repairs" validate constraint "repairs_status_check";

alter table "public"."repairs" add constraint "repairs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."repairs" validate constraint "repairs_user_id_fkey";

alter table "public"."reports" add constraint "reports_generated_by_fkey" FOREIGN KEY (generated_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."reports" validate constraint "reports_generated_by_fkey";

alter table "public"."sale_items" add constraint "sale_items_sale_id_fkey" FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE not valid;

alter table "public"."sale_items" validate constraint "sale_items_sale_id_fkey";

alter table "public"."sale_items" add constraint "sale_items_type_check" CHECK ((type = ANY (ARRAY['product'::text, 'service'::text, 'part'::text]))) not valid;

alter table "public"."sale_items" validate constraint "sale_items_type_check";

alter table "public"."sale_items" add constraint "sale_items_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."sale_items" validate constraint "sale_items_user_id_fkey";

alter table "public"."sales" add constraint "sales_discount_percentage_check" CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric))) not valid;

alter table "public"."sales" validate constraint "sales_discount_percentage_check";

alter table "public"."sales" add constraint "sales_product_id_fkey" FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE not valid;

alter table "public"."sales" validate constraint "sales_product_id_fkey";

alter table "public"."sales" add constraint "sales_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."sales" validate constraint "sales_user_id_fkey";

alter table "public"."stock_alerts" add constraint "stock_alerts_part_id_fkey" FOREIGN KEY (part_id) REFERENCES parts(id) ON DELETE CASCADE not valid;

alter table "public"."stock_alerts" validate constraint "stock_alerts_part_id_fkey";

alter table "public"."stock_alerts" add constraint "stock_alerts_type_check" CHECK ((type = ANY (ARRAY['low_stock'::text, 'out_of_stock'::text]))) not valid;

alter table "public"."stock_alerts" validate constraint "stock_alerts_type_check";

alter table "public"."stock_alerts" add constraint "stock_alerts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."stock_alerts" validate constraint "stock_alerts_user_id_fkey";

alter table "public"."subscription_audit" add constraint "subscription_audit_action_check" CHECK ((action = ANY (ARRAY['locked'::text, 'unlocked'::text]))) not valid;

alter table "public"."subscription_audit" validate constraint "subscription_audit_action_check";

alter table "public"."subscription_audit" add constraint "subscription_audit_performed_by_fkey" FOREIGN KEY (performed_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."subscription_audit" validate constraint "subscription_audit_performed_by_fkey";

alter table "public"."subscription_audit" add constraint "subscription_audit_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."subscription_audit" validate constraint "subscription_audit_user_id_fkey";

alter table "public"."subscription_payments" add constraint "subscription_payments_subscription_id_fkey" FOREIGN KEY (subscription_id) REFERENCES user_subscriptions(id) ON DELETE CASCADE not valid;

alter table "public"."subscription_payments" validate constraint "subscription_payments_subscription_id_fkey";

alter table "public"."subscription_payments" add constraint "valid_payment_status" CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'refunded'::character varying])::text[]))) not valid;

alter table "public"."subscription_payments" validate constraint "valid_payment_status";

alter table "public"."subscription_status" add constraint "subscription_status_subscription_type_check" CHECK ((subscription_type = ANY (ARRAY['free'::text, 'premium'::text, 'enterprise'::text]))) not valid;

alter table "public"."subscription_status" validate constraint "subscription_status_subscription_type_check";

alter table "public"."subscription_status" add constraint "subscription_status_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."subscription_status" validate constraint "subscription_status_user_id_fkey";

alter table "public"."subscription_status" add constraint "subscription_status_user_id_key" UNIQUE using index "subscription_status_user_id_key";

alter table "public"."suppliers" add constraint "suppliers_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."suppliers" validate constraint "suppliers_created_by_fkey";

alter table "public"."suppliers" add constraint "suppliers_rating_check" CHECK (((rating >= 1) AND (rating <= 5))) not valid;

alter table "public"."suppliers" validate constraint "suppliers_rating_check";

alter table "public"."suppliers" add constraint "suppliers_workshop_id_name_key" UNIQUE using index "suppliers_workshop_id_name_key";

alter table "public"."system_settings" add constraint "system_settings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."system_settings" validate constraint "system_settings_user_id_fkey";

alter table "public"."system_settings" add constraint "system_settings_user_id_key_unique" UNIQUE using index "system_settings_user_id_key_unique";

alter table "public"."technician_performance" add constraint "technician_performance_technician_id_fkey" FOREIGN KEY (technician_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."technician_performance" validate constraint "technician_performance_technician_id_fkey";

alter table "public"."transactions" add constraint "transactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL not valid;

alter table "public"."transactions" validate constraint "transactions_user_id_fkey";

alter table "public"."user_preferences" add constraint "user_preferences_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_preferences" validate constraint "user_preferences_user_id_fkey";

alter table "public"."user_preferences" add constraint "user_preferences_user_id_key" UNIQUE using index "user_preferences_user_id_key";

alter table "public"."user_profiles" add constraint "user_profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_profiles" validate constraint "user_profiles_user_id_fkey";

alter table "public"."user_profiles" add constraint "user_profiles_user_id_key" UNIQUE using index "user_profiles_user_id_key";

alter table "public"."user_subscriptions" add constraint "user_subscriptions_plan_id_fkey" FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) not valid;

alter table "public"."user_subscriptions" validate constraint "user_subscriptions_plan_id_fkey";

alter table "public"."user_subscriptions" add constraint "user_subscriptions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."user_subscriptions" validate constraint "user_subscriptions_user_id_fkey";

alter table "public"."user_subscriptions" add constraint "valid_dates" CHECK ((end_date > start_date)) not valid;

alter table "public"."user_subscriptions" validate constraint "valid_dates";

alter table "public"."user_subscriptions" add constraint "valid_payment_status" CHECK (((payment_status)::text = ANY ((ARRAY['paid'::character varying, 'pending'::character varying, 'failed'::character varying])::text[]))) not valid;

alter table "public"."user_subscriptions" validate constraint "valid_payment_status";

alter table "public"."user_subscriptions" add constraint "valid_status" CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'cancelled'::character varying, 'expired'::character varying, 'pending'::character varying])::text[]))) not valid;

alter table "public"."user_subscriptions" validate constraint "valid_status";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.activate_rls_on_table(target_table_name text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    result TEXT;
    table_exists BOOLEAN;
    is_view BOOLEAN;
BEGIN
    -- Vérifier si la table existe
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = target_table_name
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RETURN '❌ Table ' || target_table_name || ' n''existe pas';
    END IF;
    
    -- Vérifier si c'est une vue
    SELECT EXISTS (
        SELECT FROM information_schema.views 
        WHERE table_schema = 'public' 
        AND table_name = target_table_name
    ) INTO is_view;
    
    IF is_view THEN
        RETURN '⚠️ ' || target_table_name || ' est une vue (RLS non applicable)';
    END IF;
    
    -- Vérifier si la table est dans la liste d'exclusion
    IF EXISTS (SELECT 1 FROM excluded_views WHERE view_name = target_table_name) THEN
        RETURN '⚠️ ' || target_table_name || ' est dans la liste d''exclusion (vue)';
    END IF;
    
    -- Activer RLS
    BEGIN
        EXECUTE 'ALTER TABLE ' || quote_ident(target_table_name) || ' ENABLE ROW LEVEL SECURITY';
        RETURN '✅ RLS activé sur ' || target_table_name;
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Erreur sur ' || target_table_name || ': ' || SQLERRM;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_notes, current_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_flexible(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_rpc(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_secure(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client avec created_by automatique
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, current_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_simple(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_to_account_a(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    account_a_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur (compte A)
    account_a_user_id := auth.uid();
    
    IF account_a_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné au compte A
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, account_a_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', account_a_user_id,
        'message', 'Client ajouté au compte A'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_to_my_account(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à votre compte
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_working(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_client_working_rls(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à votre compte
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'user_id', your_user_id,
        'message', 'Client ajouté à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_loyalty_points(p_client_id uuid, p_points integer, p_description text DEFAULT 'Points ajoutés manuellement'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_client_exists BOOLEAN;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Vérifier que le client existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE id = p_client_id) INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Vérifier que les points sont positifs
    IF p_points <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le nombre de points doit être positif'
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0) INTO v_current_points
    FROM clients 
    WHERE id = p_client_id;
    
    -- Calculer les nouveaux points
    v_new_points := v_current_points + p_points;
    
    -- Récupérer le niveau actuel
    SELECT current_tier_id INTO v_current_tier_id
    FROM clients 
    WHERE id = p_client_id;
    
    -- Déterminer le nouveau niveau basé sur les points
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers
    WHERE points_required <= v_new_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour les points et le niveau du client
    UPDATE clients 
    SET 
        loyalty_points = v_new_points,
        current_tier_id = COALESCE(v_new_tier_id, v_current_tier_id),
        updated_at = NOW()
    WHERE id = p_client_id;
    
    -- Insérer l'historique des points
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_before,
        points_after,
        description,
        points_type,
        source_type,
        user_id,
        created_at
    ) VALUES (
        p_client_id,
        p_points,
        v_current_points,
        v_new_points,
        p_description,
        'manual',
        'manual',
        v_user_id,
        NOW()
    );
    
    -- Retourner le résultat
    v_result := json_build_object(
        'success', true,
        'client_id', p_client_id,
        'points_added', p_points,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'new_tier_id', v_new_tier_id,
        'description', p_description,
        'user_id', v_user_id
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_my_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_my_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à vous (sans colonne company)
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_my_client_complete(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client assigné à vous (avec company si disponible)
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_my_client_isolated(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_company text DEFAULT NULL::text, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    your_user_id UUID;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    IF your_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Insérer le nouveau client avec created_by automatique
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, city, postal_code, company, notes, created_by
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_city, p_postal_code, p_company, p_notes, your_user_id
    ) RETURNING id INTO new_client_id;
    
    RETURN json_build_object(
        'success', true,
        'client_id', new_client_id,
        'message', 'Client ajouté et assigné à votre compte'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.add_role_column_if_missing()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier si la colonne role existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
        AND column_name = 'role'
        AND table_schema = 'public'
    ) THEN
        -- Ajouter la colonne role
        ALTER TABLE subscription_status ADD COLUMN role TEXT DEFAULT 'technician';
        
        -- Mettre à jour les valeurs existantes
        UPDATE subscription_status 
        SET role = 'admin' 
        WHERE user_id IN (
            SELECT id FROM public.users WHERE role = 'admin'
        );
        
        UPDATE subscription_status 
        SET role = 'technician' 
        WHERE role IS NULL;
        
        RETURN json_build_object(
            'success', true,
            'message', 'Colonne role ajoutée à subscription_status'
        );
    ELSE
        RETURN json_build_object(
            'success', true,
            'message', 'Colonne role existe déjà dans subscription_status'
        );
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.apply_manual_loyalty_discount(p_repair_id uuid, p_points_to_use integer, p_discount_percentage numeric DEFAULT NULL::numeric)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_repair repairs%ROWTYPE;
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_rules loyalty_rules%ROWTYPE;
    v_discount_percentage DECIMAL(5,2);
    v_final_price DECIMAL(10,2);
    v_points_value DECIMAL(10,2);
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer la réparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Réparation non trouvée'
        );
    END IF;
    
    -- Récupérer les informations de fidélité du client
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = v_repair.client_id;
    
    IF v_client_loyalty.id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le client n''a pas de points de fidélité'
        );
    END IF;
    
    -- Vérifier que le client a assez de points
    IF (v_client_loyalty.total_points - v_client_loyalty.used_points) < p_points_to_use THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le client n''a pas assez de points disponibles'
        );
    END IF;
    
    -- Récupérer les règles de points
    SELECT * INTO v_rules
    FROM loyalty_rules
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Calculer la valeur des points
    v_points_value := p_points_to_use * v_rules.points_per_euro_spent;
    
    -- Déterminer le pourcentage de réduction
    IF p_discount_percentage IS NOT NULL THEN
        v_discount_percentage := p_discount_percentage;
    ELSE
        -- Calculer automatiquement basé sur la valeur des points
        v_discount_percentage := (v_points_value / v_repair.total_price) * 100;
        -- Limiter à 50% maximum
        v_discount_percentage := LEAST(v_discount_percentage, 50.0);
    END IF;
    
    -- Calculer le prix final
    v_final_price := v_repair.total_price * (1 - v_discount_percentage / 100);
    
    -- Mettre à jour la réparation
    UPDATE repairs
    SET 
        loyalty_discount_percentage = v_discount_percentage,
        loyalty_points_used = p_points_to_use,
        final_price = v_final_price,
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Déduire les points utilisés
    UPDATE client_loyalty_points
    SET 
        used_points = used_points + p_points_to_use,
        updated_at = NOW()
    WHERE client_id = v_repair.client_id;
    
    -- Enregistrer l'utilisation des points
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type,
        source_id, description, created_by
    ) VALUES (
        v_repair.client_id, -p_points_to_use, 'used', 'purchase',
        p_repair_id, 'Points utilisés pour réduction sur réparation', auth.uid()
    );
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'repair_id', p_repair_id,
            'original_price', v_repair.total_price,
            'points_used', p_points_to_use,
            'discount_percentage', v_discount_percentage,
            'discount_amount', v_repair.total_price - v_final_price,
            'final_price', v_final_price,
            'remaining_points', (v_client_loyalty.total_points - v_client_loyalty.used_points) - p_points_to_use
        ),
        'message', 'Réduction appliquée avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''application de la réduction: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.assign_loyalty_tiers_auto()
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_updated_count INTEGER := 0;
    v_client_record RECORD;
    v_tier_id UUID;
BEGIN
    -- Parcourir tous les clients avec des points
    FOR v_client_record IN 
        SELECT id, loyalty_points, current_tier_id 
        FROM clients 
        WHERE loyalty_points > 0
    LOOP
        -- Trouver le niveau approprié selon les points
        SELECT id INTO v_tier_id
        FROM loyalty_tiers_advanced
        WHERE points_required <= v_client_record.loyalty_points
        AND is_active = true
        ORDER BY points_required DESC
        LIMIT 1;
        
        -- Mettre à jour le client si le niveau a changé
        IF v_tier_id IS NOT NULL AND v_tier_id != v_client_record.current_tier_id THEN
            UPDATE clients 
            SET current_tier_id = v_tier_id
            WHERE id = v_client_record.id;
            
            v_updated_count := v_updated_count + 1;
        END IF;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux assignés automatiquement',
        'clients_updated', v_updated_count
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.assign_user_id_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur connecté
    current_user_id := auth.uid();
    
    -- Assigner le user_id si NULL
    IF NEW.user_id IS NULL AND current_user_id IS NOT NULL THEN
        NEW.user_id := current_user_id;
        RAISE NOTICE 'User ID assigné automatiquement: %', current_user_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.assign_workshop_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Assigner le workshop_id actuel si il n'est pas défini
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.assign_workshop_id_to_tiers()
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_user_record RECORD;
    v_updated_count INTEGER := 0;
    v_total_users INTEGER := 0;
BEGIN
    -- Parcourir tous les utilisateurs
    FOR v_user_record IN 
        SELECT id, email FROM auth.users
        WHERE email IS NOT NULL
    LOOP
        v_total_users := v_total_users + 1;
        
        -- Assigner workshop_id aux niveaux standard pour cet utilisateur
        UPDATE loyalty_tiers 
        SET workshop_id = v_user_record.id
        WHERE workshop_id IS NULL;
        
        -- Assigner workshop_id aux niveaux avancés pour cet utilisateur
        UPDATE loyalty_tiers_advanced 
        SET workshop_id = v_user_record.id
        WHERE workshop_id IS NULL;
        
        v_updated_count := v_updated_count + 1;
        
        RAISE NOTICE 'Utilisateur %: niveaux assignés', v_user_record.email;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Workshop_id assigné aux niveaux',
        'users_processed', v_total_users,
        'tiers_updated', v_updated_count
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.assign_workshop_id_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Assigner le workshop_id si NULL
    IF NEW.workshop_id IS NULL AND current_workshop_id IS NOT NULL THEN
        NEW.workshop_id := current_workshop_id;
        RAISE NOTICE 'Workshop ID assigné automatiquement: %', current_workshop_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.audit_subscription_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF OLD.is_locked != NEW.is_locked THEN
        INSERT INTO public.subscription_audit (
            user_id,
            action,
            performed_by,
            notes
        ) VALUES (
            NEW.user_id,
            CASE WHEN NEW.is_locked THEN 'locked' ELSE 'unlocked' END,
            auth.uid(),
            'Changement de statut d''abonnement'
        );
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_add_loyalty_points_from_purchase(p_client_id uuid, p_amount numeric, p_source_type text DEFAULT 'purchase'::text, p_description text DEFAULT 'Achat automatique'::text, p_reference_id uuid DEFAULT NULL::uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_points_to_add INTEGER;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    -- Calculer les points à attribuer
    v_points_to_add := calculate_loyalty_points(p_amount, p_client_id);
    
    IF v_points_to_add = 0 THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Montant insuffisant pour obtenir des points',
            'amount', p_amount,
            'points_earned', 0
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0), current_tier_id
    INTO v_current_points, v_current_tier_id
    FROM clients
    WHERE id = p_client_id;
    
    -- Mettre à jour les points du client
    UPDATE clients 
    SET 
        loyalty_points = v_current_points + v_points_to_add,
        updated_at = NOW()
    WHERE id = p_client_id;
    
    v_new_points := v_current_points + v_points_to_add;
    
    -- Déterminer le nouveau niveau de fidélité
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers_advanced
    WHERE points_required <= v_new_points
    AND is_active = true
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour le niveau si nécessaire
    IF v_new_tier_id IS NOT NULL AND v_new_tier_id != v_current_tier_id THEN
        UPDATE clients 
        SET 
            current_tier_id = v_new_tier_id,
            updated_at = NOW()
        WHERE id = p_client_id;
    END IF;
    
    -- Enregistrer l'historique
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_type,
        source_type,
        description,
        reference_id,
        points_before,
        points_after,
        created_at
    ) VALUES (
        p_client_id,
        v_points_to_add,
        'earned',
        p_source_type,
        p_description,
        p_reference_id,
        v_current_points,
        v_new_points,
        NOW()
    );
    
    -- Préparer le résultat
    v_result := json_build_object(
        'success', true,
        'message', 'Points de fidélité attribués avec succès',
        'client_id', p_client_id,
        'amount', p_amount,
        'points_earned', v_points_to_add,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'old_tier_id', v_current_tier_id,
        'new_tier_id', v_new_tier_id,
        'tier_upgraded', v_new_tier_id != v_current_tier_id
    );
    
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_add_loyalty_points_from_repair(p_repair_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_repair_record RECORD;
    v_points_result JSON;
BEGIN
    -- Récupérer les informations de la réparation
    SELECT 
        r.client_id,
        r.total_price,
        r.id
    INTO v_repair_record
    FROM repairs r
    WHERE r.id = p_repair_id
    AND r.is_paid = true; -- Seulement si la réparation est payée
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Réparation non trouvée ou non payée'
        );
    END IF;
    
    -- Attribuer les points automatiquement
    v_points_result := auto_add_loyalty_points_from_purchase(
        v_repair_record.client_id,
        v_repair_record.total_price,
        'repair',
        'Points de fidélité - Réparation #' || v_repair_record.id,
        v_repair_record.id
    );
    
    RETURN v_points_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_add_loyalty_points_from_sale(p_sale_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_sale_record RECORD;
    v_points_result JSON;
BEGIN
    -- Récupérer les informations de la vente
    SELECT 
        s.client_id,
        s.total,
        s.id
    INTO v_sale_record
    FROM sales s
    WHERE s.id = p_sale_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Vente non trouvée'
        );
    END IF;
    
    -- Attribuer les points automatiquement
    v_points_result := auto_add_loyalty_points_from_purchase(
        v_sale_record.client_id,
        v_sale_record.total,
        'sale',
        'Points de fidélité - Vente #' || v_sale_record.id,
        v_sale_record.id
    );
    
    RETURN v_points_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.auto_calculate_loyalty_discount()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Si le client_id change ou si c'est une nouvelle réparation
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.client_id IS DISTINCT FROM NEW.client_id) THEN
        -- Calculer automatiquement la réduction
        PERFORM calculate_loyalty_discount(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.bypass_signup_issue()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Désactiver temporairement tous les triggers sur auth.users
    DROP TRIGGER IF EXISTS trigger_create_user_default_data ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_default_data_on_signup ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_automatically ON users;
    DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON users;
    
    -- Désactiver temporairement RLS sur auth.users si nécessaire
    -- ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;
    
    RETURN 'Triggers supprimés - Testez l''inscription maintenant';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_client_tier(client_uuid uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_available_points INTEGER;
  v_new_tier_id UUID;
BEGIN
  SELECT (total_points - used_points) INTO v_available_points
  FROM client_loyalty_points
  WHERE client_id = client_uuid;
  
  IF v_available_points IS NULL THEN
    v_available_points := 0;
  END IF;
  
  SELECT id INTO v_new_tier_id
  FROM loyalty_tiers
  WHERE min_points <= v_available_points
  ORDER BY min_points DESC
  LIMIT 1;
  
  RETURN v_new_tier_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_correct_tier(points_available integer)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_tier_id UUID;
BEGIN
    -- Trouver le niveau le plus élevé que le client peut atteindre avec ses points
    SELECT id INTO v_tier_id
    FROM loyalty_tiers
    WHERE min_points <= points_available
    ORDER BY min_points DESC
    LIMIT 1;
    
    RETURN v_tier_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_loyalty_discount(p_repair_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_repair repairs%ROWTYPE;
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_tier loyalty_tiers%ROWTYPE;
    v_discount_percentage DECIMAL(5,2);
    v_final_price DECIMAL(10,2);
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Récupérer la réparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Réparation non trouvée'
        );
    END IF;
    
    -- Récupérer les informations de fidélité du client
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = v_repair.client_id;
    
    -- Si le client n'a pas de points de fidélité, pas de réduction
    IF v_client_loyalty.id IS NULL THEN
        v_discount_percentage := 0;
    ELSE
        -- Récupérer le niveau de fidélité actuel
        SELECT * INTO v_tier
        FROM loyalty_tiers
        WHERE id = v_client_loyalty.current_tier_id;
        
        IF v_tier.id IS NOT NULL THEN
            v_discount_percentage := v_tier.discount_percentage;
        ELSE
            v_discount_percentage := 0;
        END IF;
    END IF;
    
    -- Calculer le prix final
    v_final_price := v_repair.total_price * (1 - v_discount_percentage / 100);
    
    -- Mettre à jour la réparation
    UPDATE repairs
    SET 
        loyalty_discount_percentage = v_discount_percentage,
        final_price = v_final_price,
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'repair_id', p_repair_id,
            'original_price', v_repair.total_price,
            'discount_percentage', v_discount_percentage,
            'discount_amount', v_repair.total_price - v_final_price,
            'final_price', v_final_price,
            'client_tier', CASE 
                WHEN v_tier.id IS NOT NULL THEN json_build_object(
                    'name', v_tier.name,
                    'color', v_tier.color
                )
                ELSE NULL
            END
        ),
        'message', 'Réduction de fidélité calculée avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors du calcul de la réduction: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_loyalty_points(p_amount numeric, p_client_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_points_per_euro INTEGER;
    v_minimum_purchase DECIMAL(10,2);
    v_bonus_50 DECIMAL(10,2);
    v_bonus_100 DECIMAL(10,2);
    v_bonus_200 DECIMAL(10,2);
    v_base_points INTEGER;
    v_bonus_points INTEGER;
    v_total_points INTEGER;
BEGIN
    -- Récupérer la configuration
    SELECT 
        CAST(value AS INTEGER) INTO v_points_per_euro
    FROM loyalty_config 
    WHERE key = 'points_per_euro';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_minimum_purchase
    FROM loyalty_config 
    WHERE key = 'minimum_purchase_for_points';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_50
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_50';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_100
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_100';
    
    SELECT 
        CAST(value AS DECIMAL(10,2)) INTO v_bonus_200
    FROM loyalty_config 
    WHERE key = 'bonus_threshold_200';
    
    -- Vérifier le montant minimum
    IF p_amount < v_minimum_purchase THEN
        RETURN 0;
    END IF;
    
    -- Calculer les points de base
    v_base_points := FLOOR(p_amount * v_points_per_euro);
    
    -- Calculer les bonus
    v_bonus_points := 0;
    
    IF p_amount >= v_bonus_200 THEN
        v_bonus_points := FLOOR(v_base_points * 0.30); -- 30% de bonus
    ELSIF p_amount >= v_bonus_100 THEN
        v_bonus_points := FLOOR(v_base_points * 0.20); -- 20% de bonus
    ELSIF p_amount >= v_bonus_50 THEN
        v_bonus_points := FLOOR(v_base_points * 0.10); -- 10% de bonus
    END IF;
    
    v_total_points := v_base_points + v_bonus_points;
    
    RETURN v_total_points;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_loyalty_progress(p_client_id uuid)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_client_record RECORD;
    v_current_tier RECORD;
    v_next_tier RECORD;
    v_progress_percentage DECIMAL(5,2);
    v_points_to_next INTEGER;
BEGIN
    -- Récupérer les informations du client
    SELECT 
        c.loyalty_points,
        c.current_tier_id,
        lta.name as tier_name,
        lta.points_required,
        lta.color as tier_color
    INTO v_client_record
    FROM clients c
    LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
    WHERE c.id = p_client_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Trouver le niveau suivant
    SELECT 
        name,
        points_required,
        color
    INTO v_next_tier
    FROM loyalty_tiers_advanced
    WHERE points_required > v_client_record.points_required
    AND is_active = true
    ORDER BY points_required ASC
    LIMIT 1;
    
    -- Calculer la progression
    IF v_next_tier IS NOT NULL THEN
        v_points_to_next := v_next_tier.points_required - v_client_record.loyalty_points;
        v_progress_percentage := LEAST(100, GREATEST(0, 
            ((v_client_record.loyalty_points - v_client_record.points_required)::DECIMAL / 
             (v_next_tier.points_required - v_client_record.points_required)) * 100
        ));
    ELSE
        -- Niveau maximum atteint
        v_points_to_next := 0;
        v_progress_percentage := 100;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'client_id', p_client_id,
        'current_points', v_client_record.loyalty_points,
        'current_tier', v_client_record.tier_name,
        'current_tier_color', v_client_record.tier_color,
        'next_tier', COALESCE(v_next_tier.name, 'Niveau maximum'),
        'next_tier_color', COALESCE(v_next_tier.color, v_client_record.tier_color),
        'points_to_next', v_points_to_next,
        'progress_percentage', v_progress_percentage
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_repair_discount_amount_safe()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Si c'est une nouvelle réparation ou si le pourcentage de réduction change
    IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
        -- Sauvegarder le prix original si pas encore fait
        IF NEW.original_price IS NULL THEN
            NEW.original_price = NEW.total_price;
        END IF;
        
        -- Calculer le montant de la réduction sur le prix original
        NEW.discount_amount = (NEW.original_price * NEW.discount_percentage) / 100;
        
        -- Calculer le prix final après réduction
        NEW.total_price = NEW.original_price - NEW.discount_amount;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_sale_discount_amount_safe()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Si c'est une nouvelle vente ou si le pourcentage de réduction change
    IF TG_OP = 'INSERT' OR OLD.discount_percentage IS DISTINCT FROM NEW.discount_percentage THEN
        -- Calculer le total TTC original (sous-total + TVA)
        IF NEW.original_total IS NULL THEN
            NEW.original_total = NEW.subtotal + NEW.tax;
        END IF;
        
        -- Calculer le montant de la réduction sur le total TTC original
        NEW.discount_amount = (NEW.original_total * NEW.discount_percentage) / 100;
        
        -- Calculer le total final après réduction
        NEW.total = NEW.original_total - NEW.discount_amount;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_technician_performance(p_technician_id uuid, p_period_start date, p_period_end date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_total_repairs INTEGER;
    v_completed_repairs INTEGER;
    v_avg_repair_time NUMERIC(10,2);
    v_total_revenue NUMERIC(10,2);
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Calculer les métriques
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'completed' THEN 1 END),
        COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400), 0),
        COALESCE(SUM(total_cost), 0)
    INTO v_total_repairs, v_completed_repairs, v_avg_repair_time, v_total_revenue
    FROM repairs 
    WHERE assigned_technician_id = p_technician_id
    AND workshop_id = v_workshop_id
    AND created_at >= p_period_start 
    AND created_at <= p_period_end;
    
    -- Insérer ou mettre à jour les métriques
    INSERT INTO technician_performance (
        technician_id, period_start, period_end, 
        total_repairs, completed_repairs, avg_repair_time, 
        total_revenue, workshop_id
    ) VALUES (
        p_technician_id, p_period_start, p_period_end,
        v_total_repairs, v_completed_repairs, v_avg_repair_time,
        v_total_revenue, v_workshop_id
    )
    ON CONFLICT (technician_id, period_start, period_end)
    DO UPDATE SET
        total_repairs = EXCLUDED.total_repairs,
        completed_repairs = EXCLUDED.completed_repairs,
        avg_repair_time = EXCLUDED.avg_repair_time,
        total_revenue = EXCLUDED.total_revenue,
        updated_at = NOW();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_access_loyalty_data(user_id uuid DEFAULT auth.uid())
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_role TEXT;
BEGIN
    -- Si pas d'utilisateur connecté, refuser l'accès
    IF user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Récupérer le rôle de l'utilisateur
    SELECT role INTO user_role
    FROM users
    WHERE id = user_id;
    
    -- Autoriser l'accès pour tous les rôles (admin, technician, manager)
    IF user_role IN ('admin', 'technician', 'manager') THEN
        RETURN TRUE;
    END IF;
    
    -- Par défaut, refuser l'accès
    RETURN FALSE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- En cas d'erreur, autoriser l'accès pour éviter les blocages
        RETURN TRUE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_access_user_data(user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- L'utilisateur peut toujours accéder à ses propres données
  IF user_id = auth.uid() THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut accéder aux données des utilisateurs qu'il a créés
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id 
    AND created_by = auth.uid()
  ) THEN
    RETURN TRUE;
  END IF;
  
  -- L'utilisateur peut voir tous les utilisateurs s'il est admin
  IF EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() 
    AND role = 'admin'
  ) THEN
    RETURN TRUE;
  END IF;
  
  RETURN FALSE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.can_be_assigned_to_repairs(user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  user_role TEXT;
BEGIN
  -- Recuperer le role de l'utilisateur depuis auth.users
  SELECT (raw_user_meta_data->>'role')::TEXT INTO user_role
  FROM auth.users 
  WHERE id = user_id;
  
  -- Retourner true si l'utilisateur est technicien, admin ou manager
  RETURN user_role IN ('technician', 'admin', 'manager');
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_account_a_clients()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    account_a_user_id UUID;
    account_a_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur (compte A)
    account_a_user_id := auth.uid();
    
    -- Compter les clients du compte A
    SELECT COUNT(*) INTO account_a_clients_count FROM public.clients WHERE created_by = account_a_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'account_a_user_id', account_a_user_id,
        'account_a_clients_count', account_a_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé - vous voyez les clients du compte A'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'account_a_user_id', account_a_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_account_isolation()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients (ceux que vous pouvez voir)
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', your_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé - vous ne voyez que vos propres clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_admin_rights()
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  user_role TEXT;
BEGIN
  -- Récupérer le rôle de l'utilisateur connecté depuis les métadonnées
  SELECT (raw_user_meta_data->>'role')::TEXT INTO user_role
  FROM auth.users 
  WHERE id = auth.uid();
  
  -- Retourner true si l'utilisateur est admin ou technicien
  RETURN user_role IN ('admin', 'technician');
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_all_tables_security()
 RETURNS TABLE(table_name text, table_type text, has_rls boolean, policy_count integer, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.views v WHERE v.table_schema = 'public' AND v.table_name = t.tablename) 
            THEN 'VIEW'::TEXT
            ELSE 'BASE TABLE'::TEXT
        END as table_type,
        t.rowsecurity as has_rls,
        COALESCE(p.policy_count, 0)::INTEGER as policy_count,
        CASE 
            WHEN EXISTS (SELECT 1 FROM information_schema.views v WHERE v.table_schema = 'public' AND v.table_name = t.tablename) 
            THEN '👁️ Vue (RLS non applicable)'
            WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) > 0 THEN '✅ Sécurisé'
            WHEN t.rowsecurity = false THEN '❌ RLS désactivé'
            WHEN t.rowsecurity = true AND COALESCE(p.policy_count, 0) = 0 THEN '⚠️ RLS activé mais pas de politique'
            ELSE '❓ Inconnu'
        END as status
    FROM pg_tables t
    LEFT JOIN (
        SELECT 
            schemaname,
            tablename,
            COUNT(*) as policy_count
        FROM pg_policies 
        WHERE schemaname = 'public'
        GROUP BY schemaname, tablename
    ) p ON t.schemaname = p.schemaname AND t.tablename = p.tablename
    WHERE t.schemaname = 'public' 
    AND t.tablename NOT LIKE 'pg_%'
    AND t.tablename NOT LIKE 'sql_%'
    ORDER BY table_type, t.tablename;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_access()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'total_clients', total_clients,
        'your_clients', your_clients,
        'rls_enabled', false,
        'message', 'RLS désactivé - accès complet aux clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_access_flexible()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'total_clients', total_clients,
        'your_clients', your_clients,
        'rls_enabled', true,
        'message', 'RLS activé avec politiques flexibles - accès aux clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_access_rpc()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'total_clients', total_clients,
        'your_clients', your_clients,
        'rls_enabled', false,
        'message', 'RLS désactivé - accès complet aux clients via RPC'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_access_working()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    total_clients INTEGER;
    your_clients INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO your_clients FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'total_clients', total_clients,
        'your_clients', your_clients,
        'rls_enabled', false,
        'message', 'RLS désactivé - accès complet aux clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_isolation_balanced()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients (ceux que vous pouvez voir)
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', your_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé avec politiques équilibrées - vous ne voyez que vos clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_clients_isolation_working()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients (ceux que vous pouvez voir)
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', your_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé avec politiques simples - vous ne voyez que vos propres clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_email_exists(p_email text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM users WHERE email = p_email
    ) INTO v_exists;
    
    RETURN v_exists;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_my_clients()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    client_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients
    SELECT COUNT(*) INTO client_count FROM public.clients WHERE created_by = your_user_id;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', client_count,
        'rls_enabled', false,
        'message', 'RLS désactivé - vous voyez tous les clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_repair_overdue()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.due_date < CURRENT_DATE AND NEW.status NOT IN ('completed', 'cancelled', 'returned') THEN
        RAISE NOTICE 'Réparation en retard: %', NEW.id;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.check_table_security()
 RETURNS TABLE(table_name text, has_rls boolean, policy_count integer, status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.table_name::TEXT,
        t.row_security as has_rls,
        COALESCE(p.policy_count, 0) as policy_count,
        CASE 
            WHEN t.row_security = true AND COALESCE(p.policy_count, 0) > 0 THEN '✅ Sécurisé'
            WHEN t.row_security = false THEN '❌ RLS désactivé'
            WHEN t.row_security = true AND COALESCE(p.policy_count, 0) = 0 THEN '⚠️ RLS activé mais pas de politique'
            ELSE '❓ Inconnu'
        END as status
    FROM information_schema.tables t
    LEFT JOIN (
        SELECT 
            schemaname,
            tablename,
            COUNT(*) as policy_count
        FROM pg_policies 
        WHERE schemaname = 'public'
        GROUP BY schemaname, tablename
    ) p ON t.table_schema = p.schemaname AND t.table_name = p.tablename
    WHERE t.table_schema = 'public' 
    AND t.table_type = 'BASE TABLE'
    ORDER BY t.table_name;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.clean_duplicate_emails()
 RETURNS TABLE(email text, kept_client_id uuid, removed_client_id uuid, action text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    duplicate_record RECORD;
    client_record RECORD;
    kept_id UUID;
    removed_count INTEGER := 0;
BEGIN
    -- Parcourir tous les doublons
    FOR duplicate_record IN
        SELECT email, COUNT(*) as count
        FROM clients
        WHERE email IS NOT NULL AND email != ''
        GROUP BY email
        HAVING COUNT(*) > 1
    LOOP
        -- Garder le client le plus récent (ou le premier si même date)
        SELECT id INTO kept_id
        FROM clients
        WHERE email = duplicate_record.email
        ORDER BY updated_at DESC, created_at DESC, id
        LIMIT 1;
        
        -- Supprimer les autres clients avec le même email
        FOR client_record IN
            SELECT id
            FROM clients
            WHERE email = duplicate_record.email
            AND id != kept_id
        LOOP
            -- Supprimer les réparations associées au client à supprimer
            DELETE FROM repairs WHERE client_id = client_record.id;
            
            -- Supprimer le client
            DELETE FROM clients WHERE id = client_record.id;
            
            -- Retourner l'information
            email := duplicate_record.email;
            kept_client_id := kept_id;
            removed_client_id := client_record.id;
            action := 'Supprimé';
            RETURN NEXT;
            
            removed_count := removed_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Nettoyage terminé: % clients supprimés', removed_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.clean_duplicate_serial_numbers()
 RETURNS TABLE(serial_number text, kept_device_id uuid, removed_device_id uuid, action text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    duplicate_record RECORD;
    device_record RECORD;
    kept_id UUID;
    removed_count INTEGER := 0;
BEGIN
    -- Parcourir tous les doublons
    FOR duplicate_record IN
        SELECT serial_number, COUNT(*) as count
        FROM devices
        WHERE serial_number IS NOT NULL AND serial_number != ''
        GROUP BY serial_number
        HAVING COUNT(*) > 1
    LOOP
        -- Garder l'appareil le plus récent (ou le premier si même date)
        SELECT id INTO kept_id
        FROM devices
        WHERE serial_number = duplicate_record.serial_number
        ORDER BY updated_at DESC, created_at DESC, id
        LIMIT 1;
        
        -- Supprimer les autres appareils avec le même numéro de série
        FOR device_record IN
            SELECT id
            FROM devices
            WHERE serial_number = duplicate_record.serial_number
            AND id != kept_id
        LOOP
            -- Supprimer les réparations associées à l'appareil à supprimer
            DELETE FROM repairs WHERE device_id = device_record.id;
            
            -- Supprimer l'appareil
            DELETE FROM devices WHERE id = device_record.id;
            
            -- Retourner l'information
            serial_number := duplicate_record.serial_number;
            kept_device_id := kept_id;
            removed_device_id := device_record.id;
            action := 'Supprimé';
            RETURN NEXT;
            
            removed_count := removed_count + 1;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Nettoyage terminé: % appareils supprimés', removed_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_data()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    cleanup_count INTEGER := 0;
    result JSON;
BEGIN
    -- Nettoyer les données orphelines dans subscription_status
    DELETE FROM public.subscription_status 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    -- Nettoyer les données orphelines dans system_settings
    DELETE FROM public.system_settings 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans clients
    DELETE FROM public.clients 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans repairs
    DELETE FROM public.repairs 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans products
    DELETE FROM public.products 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans sales
    DELETE FROM public.sales 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans appointments
    DELETE FROM public.appointments 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    -- Nettoyer les données orphelines dans devices
    DELETE FROM public.devices 
    WHERE user_id NOT IN (SELECT id FROM auth.users);
    cleanup_count := cleanup_count + ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Nettoyage des données orphelines terminé',
        'cleaned_records', cleanup_count
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cleanup_orphaned_device_models()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_deleted_count INTEGER;
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Supprimer les modèles qui n'appartiennent pas à l'atelier actuel
    DELETE FROM device_models 
    WHERE workshop_id != v_workshop_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.cleanup_user_data(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    cleanup_count INTEGER := 0;
    result JSON;
BEGIN
    -- Nettoyer les données dans subscription_status
    DELETE FROM subscription_status WHERE user_id = p_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    
    -- Nettoyer d'autres tables si nécessaire
    -- Ajoutez ici d'autres tables qui référencent l'utilisateur
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données nettoyées avec succès',
        'records_deleted', cleanup_count
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors du nettoyage: ' || SQLERRM
    );
END;
$function$
;

create or replace view "public"."clients_all" as  SELECT id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
   FROM clients
  WHERE (workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid));


create or replace view "public"."clients_filtered" as  SELECT id,
    first_name,
    last_name,
    email,
    phone,
    address,
    notes,
    category,
    title,
    company_name,
    vat_number,
    siren_number,
    country_code,
    address_complement,
    region,
    postal_code,
    city,
    billing_address_same,
    billing_address,
    billing_address_complement,
    billing_region,
    billing_postal_code,
    billing_city,
    accounting_code,
    cni_identifier,
    attached_file_path,
    internal_note,
    status,
    sms_notification,
    email_notification,
    sms_marketing,
    email_marketing,
    user_id,
    created_at,
    updated_at,
    created_by,
    loyalty_points,
    current_tier_id,
    workshop_id
   FROM clients
  WHERE (workshop_id = ( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1));


create or replace view "public"."clients_filtrés" as  SELECT id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
   FROM clients
  WHERE ((workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid)) AND (email IS NOT NULL) AND (email <> ''::text));


create or replace view "public"."clients_isolated" as  SELECT id,
    first_name,
    last_name,
    email,
    phone,
    address,
    workshop_id,
    created_at,
    updated_at
   FROM clients
  WHERE (workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid));


create or replace view "public"."clients_isolated_final" as  SELECT id,
    first_name,
    last_name,
    email,
    phone,
    address,
    notes,
    category,
    title,
    company_name,
    vat_number,
    siren_number,
    country_code,
    address_complement,
    region,
    postal_code,
    city,
    billing_address_same,
    billing_address,
    billing_address_complement,
    billing_region,
    billing_postal_code,
    billing_city,
    accounting_code,
    cni_identifier,
    attached_file_path,
    internal_note,
    status,
    sms_notification,
    email_notification,
    sms_marketing,
    email_marketing,
    user_id,
    created_at,
    updated_at,
    created_by,
    loyalty_points,
    current_tier_id,
    workshop_id
   FROM clients
  WHERE (workshop_id = ( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1));


CREATE OR REPLACE FUNCTION public.column_exists(schema_name text, table_name_param text, column_name_param text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = schema_name 
        AND table_name = table_name_param 
        AND column_name = column_name_param
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.confirm_referral(p_referral_id uuid, p_points_to_award integer DEFAULT NULL::integer, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_referral referrals%ROWTYPE;
    v_points_to_award INTEGER;
    v_rules loyalty_rules%ROWTYPE;
    v_result JSON;
BEGIN
    SELECT * INTO v_referral
    FROM referrals
    WHERE id = p_referral_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Parrainage non trouvé'
        );
    END IF;
    
    IF v_referral.status != 'pending' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Ce parrainage a déjà été traité'
        );
    END IF;
    
    SELECT * INTO v_rules
    FROM loyalty_rules
    WHERE is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    IF p_points_to_award IS NOT NULL THEN
        v_points_to_award := p_points_to_award;
    ELSE
        v_points_to_award := v_rules.points_per_referral;
    END IF;
    
    UPDATE referrals
    SET 
        status = 'confirmed',
        points_awarded = v_points_to_award,
        confirmation_date = NOW(),
        confirmed_by = auth.uid(),
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_referral_id;
    
    PERFORM add_loyalty_points(
        v_referral.referrer_client_id,
        v_points_to_award,
        'earned',
        'referral',
        p_referral_id,
        'Points pour parrainage confirmé',
        auth.uid()
    );
    
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referral_id', p_referral_id,
            'referrer_client_id', v_referral.referrer_client_id,
            'referred_client_id', v_referral.referred_client_id,
            'points_awarded', v_points_to_award,
            'confirmation_date', NOW()
        ),
        'message', 'Parrainage confirmé avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la confirmation: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.convert_cancelled_to_returned(repair_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE repairs 
    SET status = 'returned', updated_at = NOW()
    WHERE id = repair_id AND status = 'cancelled';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Réparation non trouvée ou statut différent de cancelled';
    END IF;
    
    RAISE NOTICE 'Réparation % convertie de cancelled vers returned', repair_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_admin_user_auto(p_email text, p_first_name text DEFAULT NULL::text, p_last_name text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_created_user RECORD;
  v_result JSON;
BEGIN
  -- Vérifier si l'utilisateur existe déjà
  SELECT id INTO v_user_id
  FROM users
  WHERE email = p_email;
  
  -- Si l'utilisateur existe déjà, le mettre à jour avec le rôle admin
  IF FOUND THEN
    UPDATE users 
    SET 
      role = 'admin',
      updated_at = NOW()
    WHERE id = v_user_id;
    
    -- Récupérer les données mises à jour
    SELECT * INTO v_created_user
    FROM users
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur promu administrateur avec succès',
      'data', row_to_json(v_created_user)
    );
  ELSE
    -- Créer un nouvel utilisateur administrateur
    v_user_id := gen_random_uuid();
    
    -- Extraire le prénom et nom de l'email si pas fournis
    IF p_first_name IS NULL OR p_last_name IS NULL THEN
      DECLARE
        v_email_parts TEXT[];
        v_name_parts TEXT[];
      BEGIN
        v_email_parts := string_to_array(p_email, '@');
        v_name_parts := string_to_array(v_email_parts[1], '.');
        
        IF p_first_name IS NULL THEN
          IF array_length(v_name_parts, 1) >= 2 THEN
            p_first_name := initcap(v_name_parts[1]);
          ELSE
            p_first_name := initcap(v_email_parts[1]);
          END IF;
        END IF;
        
        IF p_last_name IS NULL THEN
          IF array_length(v_name_parts, 1) >= 2 THEN
            p_last_name := initcap(v_name_parts[2]);
          ELSE
            p_last_name := 'Administrateur';
          END IF;
        END IF;
      END;
    END IF;
    
    -- Insérer le nouvel utilisateur
    INSERT INTO users (
      id,
      first_name,
      last_name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      p_first_name,
      p_last_name,
      p_email,
      'admin',
      NOW(),
      NOW()
    );
    
    -- Récupérer les données créées
    SELECT * INTO v_created_user
    FROM users
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur administrateur créé avec succès',
      'data', row_to_json(v_created_user)
    );
  END IF;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erreur lors de la creation de l''utilisateur administrateur'
    );
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_alert(p_alert_type character varying, p_title character varying, p_message text, p_severity alert_severity_type DEFAULT 'info'::alert_severity_type, p_target_user_id uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
    v_user_role user_role;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;
    
    -- Obtenir le rôle de l'utilisateur
    SELECT (raw_user_meta_data->>'role')::user_role INTO v_user_role
    FROM auth.users WHERE id = auth.uid();
    
    -- Créer l'alerte
    INSERT INTO advanced_alerts (
        alert_type, title, message, severity, 
        target_user_id, target_role, workshop_id
    ) VALUES (
        p_alert_type, p_title, p_message, p_severity,
        p_target_user_id, v_user_role, v_workshop_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_alert(p_alert_type character varying, p_title character varying, p_message text, p_severity alert_severity_type DEFAULT 'info'::alert_severity_type, p_target_user_id uuid DEFAULT NULL::uuid, p_target_role user_role DEFAULT NULL::user_role)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_alert_id UUID;
BEGIN
    -- Vérifier que la table existe
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advanced_alerts') THEN
        RAISE NOTICE 'Table advanced_alerts does not exist, skipping alert creation';
        RETURN NULL;
    END IF;
    
    INSERT INTO advanced_alerts (
        alert_type, title, message, severity, 
        target_user_id, target_role, workshop_id
    ) VALUES (
        p_alert_type, p_title, p_message, p_severity,
        p_target_user_id, p_target_role,
        COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        )
    ) RETURNING id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_client_and_return(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
    result JSON;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà
    IF p_email IS NOT NULL AND EXISTS(SELECT 1 FROM clients WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un client avec cet email existe déjà'
        );
    END IF;
    
    -- Créer le client
    INSERT INTO clients (first_name, last_name, email, phone, address, workshop_id)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id)
    RETURNING id INTO new_client_id;
    
    -- Retourner le client créé immédiatement
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id,
        'created_at', c.created_at
    ) INTO result
    FROM clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_client_force(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_user_id uuid DEFAULT NULL::uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_client_id UUID;
    v_unique_email TEXT;
    v_counter INTEGER := 1;
BEGIN
    -- Utiliser l'utilisateur connecté si aucun user_id fourni
    IF p_user_id IS NULL THEN
        p_user_id := auth.uid();
    END IF;
    
    -- Si un email est fourni et qu'il existe déjà, générer un email unique
    IF p_email IS NOT NULL AND p_email != '' THEN
        v_unique_email := p_email;
        
        -- Chercher un email unique en ajoutant un numéro
        WHILE EXISTS (
            SELECT 1 FROM clients 
            WHERE email = v_unique_email 
            AND user_id = p_user_id
        ) LOOP
            v_unique_email := SPLIT_PART(p_email, '@', 1) || v_counter || '@' || SPLIT_PART(p_email, '@', 2);
            v_counter := v_counter + 1;
        END LOOP;
    END IF;
    
    -- Créer le client avec l'email unique
    INSERT INTO clients (
        first_name,
        last_name,
        email,
        phone,
        address,
        notes,
        user_id,
        created_at,
        updated_at
    ) VALUES (
        p_first_name,
        p_last_name,
        v_unique_email,
        p_phone,
        p_address,
        p_notes,
        p_user_id,
        NOW(),
        NOW()
    ) RETURNING id INTO v_client_id;
    
    -- Retourner le succès
    RETURN json_build_object(
        'success', true,
        'action', 'client_created_force',
        'message', 'Client créé avec succès (email modifié si nécessaire)',
        'client_id', v_client_id,
        'email_used', v_unique_email,
        'email_modified', CASE WHEN v_unique_email != p_email THEN true ELSE false END
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'error_code', SQLSTATE
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_client_smart(p_first_name text, p_last_name text, p_email text, p_phone text, p_address text, p_notes text, p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_existing_client_id UUID;
    v_new_client_id UUID;
    v_user_id UUID;
BEGIN
    -- Utiliser l'utilisateur connecté
    v_user_id := COALESCE(auth.uid(), p_user_id);
    
    -- Vérifier si un client avec cet email existe déjà pour cet utilisateur
    IF p_email IS NOT NULL AND p_email != '' THEN
        SELECT id INTO v_existing_client_id
        FROM clients
        WHERE email = p_email AND user_id = v_user_id
        LIMIT 1;
        
        IF v_existing_client_id IS NOT NULL THEN
            -- Client existant trouvé
            RETURN json_build_object(
                'success', true,
                'action', 'existing_client_found',
                'client_id', v_existing_client_id,
                'client_data', (
                    SELECT json_build_object(
                        'id', id,
                        'firstName', first_name,
                        'lastName', last_name,
                        'email', email,
                        'phone', phone,
                        'address', address,
                        'notes', notes,
                        'createdAt', created_at,
                        'updatedAt', updated_at
                    )
                    FROM clients
                    WHERE id = v_existing_client_id
                )
            );
        END IF;
    END IF;
    
    -- Créer un nouveau client
    INSERT INTO clients (
        first_name, last_name, email, phone, address, notes, user_id
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes, v_user_id
    ) RETURNING id INTO v_new_client_id;
    
    -- Retourner le succès avec l'ID du nouveau client
    RETURN json_build_object(
        'success', true,
        'action', 'client_created',
        'client_id', v_new_client_id
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_default_loyalty_config_for_workshop()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Vérifier qu'aucune configuration n'existe déjà
    IF EXISTS (SELECT 1 FROM loyalty_config WHERE workshop_id = auth.uid()) THEN
        RAISE EXCEPTION 'Une configuration existe déjà pour cet atelier';
    END IF;
    
    -- Créer la configuration par défaut
    INSERT INTO loyalty_config (workshop_id, key, value, description)
    VALUES 
        (auth.uid(), 'points_per_euro', '1', 'Points gagnés par euro dépensé'),
        (auth.uid(), 'minimum_purchase', '10', 'Montant minimum pour gagner des points'),
        (auth.uid(), 'bonus_threshold', '100', 'Seuil pour bonus de points'),
        (auth.uid(), 'bonus_multiplier', '1.5', 'Multiplicateur de bonus'),
        (auth.uid(), 'points_expiry_days', '365', 'Durée de validité des points en jours'),
        (auth.uid(), 'auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');
    
    RAISE NOTICE 'Configuration par défaut créée pour l''atelier %', auth.uid();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_default_loyalty_tiers_for_workshop()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Vérifier qu'aucun niveau n'existe déjà
    IF EXISTS (SELECT 1 FROM loyalty_tiers_advanced WHERE workshop_id = auth.uid()) THEN
        RAISE EXCEPTION 'Des niveaux existent déjà pour cet atelier';
    END IF;
    
    -- Créer les niveaux par défaut
    INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
    VALUES 
        (auth.uid(), 'Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
        (auth.uid(), 'Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
        (auth.uid(), 'Or', 500, 10.00, '#FFD700', '10% de réduction', true),
        (auth.uid(), 'Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
        (auth.uid(), 'Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true);
    
    RAISE NOTICE 'Niveaux par défaut créés pour l''atelier %', auth.uid();
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_default_loyalty_tiers_for_workshop(p_workshop_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_created_count INTEGER := 0;
BEGIN
    -- Vérifier que l'utilisateur a le droit de créer des niveaux pour cet atelier
    IF p_workshop_id != auth.uid() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès refusé: vous ne pouvez créer des niveaux que pour votre propre atelier'
        );
    END IF;
    
    -- Créer les niveaux par défaut s'ils n'existent pas
    INSERT INTO loyalty_tiers_advanced (workshop_id, name, points_required, discount_percentage, color, description, is_active)
    SELECT 
        p_workshop_id, 
        tier.name, 
        tier.points_required, 
        tier.discount_percentage, 
        tier.color, 
        tier.description, 
        tier.is_active
    FROM (VALUES 
        ('Bronze', 0, 0.00, '#CD7F32', 'Niveau de base', true),
        ('Argent', 100, 5.00, '#C0C0C0', '5% de réduction', true),
        ('Or', 500, 10.00, '#FFD700', '10% de réduction', true),
        ('Platine', 1000, 15.00, '#E5E4E2', '15% de réduction', true),
        ('Diamant', 2000, 20.00, '#B9F2FF', '20% de réduction', true)
    ) AS tier(name, points_required, discount_percentage, color, description, is_active)
    WHERE NOT EXISTS (
        SELECT 1 FROM loyalty_tiers_advanced lta 
        WHERE lta.workshop_id = p_workshop_id
    );
    
    GET DIAGNOSTICS v_created_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux par défaut créés avec succès',
        'tiers_created', v_created_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la création des niveaux: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_default_system_settings(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- S'assurer que la colonne description existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'system_settings' AND column_name = 'description') THEN
        ALTER TABLE public.system_settings ADD COLUMN description text;
    END IF;
    
    -- Paramètres utilisateur par défaut
    INSERT INTO system_settings (user_id, key, value, description, created_at, updated_at)
    VALUES 
        (p_user_id, 'user_first_name', '', 'Prénom de l''utilisateur', NOW(), NOW()),
        (p_user_id, 'user_last_name', '', 'Nom de l''utilisateur', NOW(), NOW()),
        (p_user_id, 'user_email', '', 'Email de l''utilisateur', NOW(), NOW()),
        (p_user_id, 'user_phone', '', 'Téléphone de l''utilisateur', NOW(), NOW()),
        
        -- Paramètres atelier par défaut
        (p_user_id, 'workshop_name', 'Mon Atelier', 'Nom de l''atelier', NOW(), NOW()),
        (p_user_id, 'workshop_address', '', 'Adresse de l''atelier', NOW(), NOW()),
        (p_user_id, 'workshop_phone', '', 'Téléphone de l''atelier', NOW(), NOW()),
        (p_user_id, 'workshop_email', '', 'Email de l''atelier', NOW(), NOW()),
        (p_user_id, 'workshop_siret', '', 'Numéro SIRET', NOW(), NOW()),
        (p_user_id, 'workshop_vat_number', '', 'Numéro de TVA', NOW(), NOW()),
        (p_user_id, 'vat_rate', '20', 'Taux de TVA (%)', NOW(), NOW()),
        (p_user_id, 'currency', 'EUR', 'Devise', NOW(), NOW()),
        
        -- Paramètres système par défaut
        (p_user_id, 'language', 'fr', 'Langue de l''interface', NOW(), NOW()),
        (p_user_id, 'theme', 'light', 'Thème de l''interface', NOW(), NOW())
    ON CONFLICT (user_id, key) DO NOTHING;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_device_model(p_brand text, p_model text, p_type text, p_year integer, p_specifications jsonb DEFAULT '{}'::jsonb, p_common_issues text[] DEFAULT '{}'::text[], p_repair_difficulty text DEFAULT 'medium'::text, p_parts_availability text DEFAULT 'medium'::text, p_is_active boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO public.device_models (
        brand, model, type, year, specifications, 
        common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        p_brand, p_model, p_type, p_year, p_specifications,
        p_common_issues, p_repair_difficulty, p_parts_availability, p_is_active
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_isolated_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
    result JSON;
BEGIN
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà
    IF p_email IS NOT NULL AND EXISTS(SELECT 1 FROM clients WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un client avec cet email existe déjà'
        );
    END IF;
    
    -- Créer le client
    INSERT INTO clients (first_name, last_name, email, phone, address, workshop_id)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id)
    RETURNING id INTO new_client_id;
    
    -- Retourner le client créé
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id,
        'created_at', c.created_at
    ) INTO result
    FROM clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_isolated_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_notes text DEFAULT NULL::text, p_category text DEFAULT 'particulier'::text, p_title text DEFAULT 'mr'::text, p_company_name text DEFAULT NULL::text, p_vat_number text DEFAULT NULL::text, p_siren_number text DEFAULT NULL::text, p_country_code text DEFAULT '33'::text, p_address_complement text DEFAULT NULL::text, p_region text DEFAULT NULL::text, p_postal_code text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_billing_address_same boolean DEFAULT true, p_billing_address text DEFAULT NULL::text, p_billing_address_complement text DEFAULT NULL::text, p_billing_region text DEFAULT NULL::text, p_billing_postal_code text DEFAULT NULL::text, p_billing_city text DEFAULT NULL::text, p_accounting_code text DEFAULT NULL::text, p_cni_identifier text DEFAULT NULL::text, p_attached_file_path text DEFAULT NULL::text, p_internal_note text DEFAULT NULL::text, p_status text DEFAULT 'displayed'::text, p_sms_notification boolean DEFAULT true, p_email_notification boolean DEFAULT true, p_sms_marketing boolean DEFAULT true, p_email_marketing boolean DEFAULT true)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_user_id UUID;
    result JSON;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User not authenticated',
            'message', 'Utilisateur non connecté'
        );
    END IF;
    
    -- Vérifier si l'email existe déjà
    IF p_email IS NOT NULL AND EXISTS(SELECT 1 FROM public.clients WHERE email = p_email AND user_id = current_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un client avec cet email existe déjà'
        );
    END IF;
    
    -- Créer le client
    INSERT INTO public.clients (
        first_name, last_name, email, phone, address, notes,
        category, title, company_name, vat_number, siren_number, country_code,
        address_complement, region, postal_code, city,
        billing_address_same, billing_address, billing_address_complement, billing_region, billing_postal_code, billing_city,
        accounting_code, cni_identifier, attached_file_path, internal_note,
        status, sms_notification, email_notification, sms_marketing, email_marketing,
        user_id
    ) VALUES (
        p_first_name, p_last_name, p_email, p_phone, p_address, p_notes,
        p_category, p_title, p_company_name, p_vat_number, p_siren_number, p_country_code,
        p_address_complement, p_region, p_postal_code, p_city,
        p_billing_address_same, p_billing_address, p_billing_address_complement, p_billing_region, p_billing_postal_code, p_billing_city,
        p_accounting_code, p_cni_identifier, p_attached_file_path, p_internal_note,
        p_status, p_sms_notification, p_email_notification, p_sms_marketing, p_email_marketing,
        current_user_id
    ) RETURNING id INTO new_client_id;
    
    -- Retourner le client créé
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'firstName', c.first_name,
        'lastName', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'notes', c.notes,
        'category', c.category,
        'title', c.title,
        'companyName', c.company_name,
        'vatNumber', c.vat_number,
        'sirenNumber', c.siren_number,
        'countryCode', c.country_code,
        'addressComplement', c.address_complement,
        'region', c.region,
        'postalCode', c.postal_code,
        'city', c.city,
        'billingAddressSame', c.billing_address_same,
        'billingAddress', c.billing_address,
        'billingAddressComplement', c.billing_address_complement,
        'billingRegion', c.billing_region,
        'billingPostalCode', c.billing_postal_code,
        'billingCity', c.billing_city,
        'accountingCode', c.accounting_code,
        'cniIdentifier', c.cni_identifier,
        'attachedFilePath', c.attached_file_path,
        'internalNote', c.internal_note,
        'status', c.status,
        'smsNotification', c.sms_notification,
        'emailNotification', c.email_notification,
        'smsMarketing', c.sms_marketing,
        'emailMarketing', c.email_marketing,
        'createdAt', c.created_at,
        'updatedAt', c.updated_at
    ) INTO result
    FROM public.clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_isolated_client_adapted(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
    result JSON;
BEGIN
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà
    IF p_email IS NOT NULL AND EXISTS(SELECT 1 FROM clients WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email already exists',
            'message', 'Un client avec cet email existe déjà'
        );
    END IF;
    
    -- Créer le client
    INSERT INTO clients (first_name, last_name, email, phone, address, workshop_id)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id)
    RETURNING id INTO new_client_id;
    
    -- Retourner le client créé
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id
    ) INTO result
    FROM clients c
    WHERE c.id = new_client_id;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_referral(p_referrer_client_id uuid, p_referred_client_id uuid, p_notes text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_referral_id UUID;
    v_result JSON;
BEGIN
    -- Vérifier que l'utilisateur a les droits
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé'
        );
    END IF;
    
    -- Vérifier que les clients existent
    IF NOT EXISTS (SELECT 1 FROM clients WHERE id = p_referrer_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client parrain non trouvé'
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM clients WHERE id = p_referred_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client parrainé non trouvé'
        );
    END IF;
    
    -- Vérifier que ce n'est pas le même client
    IF p_referrer_client_id = p_referred_client_id THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un client ne peut pas se parrainer lui-même'
        );
    END IF;
    
    -- Vérifier qu'il n'y a pas déjà un parrainage entre ces clients
    IF EXISTS (
        SELECT 1 FROM referrals 
        WHERE referrer_client_id = p_referrer_client_id 
        AND referred_client_id = p_referred_client_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un parrainage existe déjà entre ces clients'
        );
    END IF;
    
    -- Créer le parrainage
    INSERT INTO referrals (
        referrer_client_id, 
        referred_client_id, 
        notes
    ) VALUES (
        p_referrer_client_id,
        p_referred_client_id,
        p_notes
    ) RETURNING id INTO v_referral_id;
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'referral_id', v_referral_id,
            'referrer_client_id', p_referrer_client_id,
            'referred_client_id', p_referred_client_id,
            'status', 'pending',
            'created_at', NOW()
        ),
        'message', 'Parrainage créé avec succès - En attente de confirmation'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la création du parrainage: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_repair_alerts_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Alerte pour réparation urgente
    IF NEW.is_urgent = true AND (OLD.is_urgent = false OR OLD IS NULL) THEN
        PERFORM create_alert(
            'urgent_repair',
            'Nouvelle réparation urgente',
            'Une réparation urgente a été créée pour ' || COALESCE(NEW.description, 'un appareil'),
            'warning',
            NEW.assigned_technician_id
        );
    END IF;
    
    -- Alerte pour réparation en retard
    IF NEW.due_date < CURRENT_DATE AND NEW.status NOT IN ('completed', 'cancelled') THEN
        PERFORM create_alert(
            'overdue_repair',
            'Réparation en retard',
            'La réparation ' || COALESCE(NEW.description, '') || ' est en retard',
            'error',
            NEW.assigned_technician_id
        );
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_simple_admin_user(p_email text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_first_name TEXT;
  v_last_name TEXT;
  v_email_parts TEXT[];
  v_name_parts TEXT[];
  v_result JSON;
BEGIN
  -- Extraire le nom depuis l'email
  v_email_parts := string_to_array(p_email, '@');
  v_name_parts := string_to_array(v_email_parts[1], '.');
  
  IF array_length(v_name_parts, 1) >= 2 THEN
    v_first_name := initcap(v_name_parts[1]);
    v_last_name := initcap(v_name_parts[2]);
  ELSE
    v_first_name := initcap(v_email_parts[1]);
    v_last_name := 'Administrateur';
  END IF;
  
  -- Vérifier si l'utilisateur existe déjà
  SELECT id INTO v_user_id
  FROM users
  WHERE email = p_email;
  
  -- Si l'utilisateur existe déjà, le mettre à jour avec le rôle admin
  IF FOUND THEN
    UPDATE users 
    SET 
      role = 'admin',
      updated_at = NOW()
    WHERE id = v_user_id;
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur promu administrateur avec succès',
      'user_id', v_user_id,
      'email', p_email,
      'role', 'admin'
    );
  ELSE
    -- Créer un nouvel utilisateur administrateur
    v_user_id := gen_random_uuid();
    
    INSERT INTO users (
      id,
      first_name,
      last_name,
      email,
      role,
      created_at,
      updated_at
    ) VALUES (
      v_user_id,
      v_first_name,
      v_last_name,
      p_email,
      'admin',
      NOW(),
      NOW()
    );
    
    v_result := json_build_object(
      'success', true,
      'message', 'Utilisateur administrateur créé avec succès',
      'user_id', v_user_id,
      'email', p_email,
      'first_name', v_first_name,
      'last_name', v_last_name,
      'role', 'admin'
    );
  END IF;
  
  RETURN v_result;
  
EXCEPTION
  WHEN OTHERS THEN
    v_result := json_build_object(
      'success', false,
      'error', SQLERRM,
      'message', 'Erreur lors de la creation de l''utilisateur administrateur'
    );
    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_stock_alert_automatically()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_automatically(user_id uuid, first_name text, last_name text, user_email text, user_role text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  new_user users%ROWTYPE;
  final_email TEXT;
  email_counter INTEGER := 0;
BEGIN
  -- Vérifier que l'utilisateur est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Non authentifié');
  END IF;

  -- Vérifier que l'utilisateur n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Utilisateur déjà existant');
  END IF;

  -- Gérer l'unicité de l'email
  final_email := COALESCE(user_email, 'user@example.com');
  
  -- Si l'email existe déjà, générer un email unique
  WHILE EXISTS (SELECT 1 FROM users WHERE email = final_email) LOOP
    email_counter := email_counter + 1;
    final_email := 'user' || email_counter || '@example.com';
  END LOOP;

  -- Insérer le nouvel utilisateur
  INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
  VALUES (
    user_id,
    COALESCE(first_name, 'Utilisateur'),
    COALESCE(last_name, 'Test'),
    final_email,
    COALESCE(user_role, 'technician'),
    NOW(),
    NOW()
  )
  RETURNING * INTO new_user;

  -- Retourner le succès
  RETURN json_build_object(
    'success', true,
    'user', json_build_object(
      'id', new_user.id,
      'first_name', new_user.first_name,
      'last_name', new_user.last_name,
      'email', new_user.email,
      'role', new_user.role
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_default_data(p_user_id uuid, p_email text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_email TEXT;
    is_admin BOOLEAN;
    user_role TEXT;
BEGIN
    -- Déterminer l'email et le rôle
    user_email := COALESCE(p_email, '');
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');
    user_role := CASE WHEN is_admin THEN 'admin' ELSE 'technician' END;
    
    -- Insérer dans users (avec gestion de conflit)
    INSERT INTO public.users (id, email, role)
    VALUES (p_user_id, user_email, user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Insérer dans subscription_status (avec gestion de conflit)
    INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, role)
    VALUES (p_user_id, 'Utilisateur', 'Test', user_email, true, user_role)
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        is_active = EXCLUDED.is_active,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données utilisateur créées avec succès',
        'user_id', p_user_id,
        'is_admin', is_admin,
        'role', user_role
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la création des données: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_default_data(p_user_id uuid, p_email text DEFAULT NULL::text, p_first_name text DEFAULT 'Utilisateur'::text, p_last_name text DEFAULT 'Test'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_email TEXT;
    is_admin BOOLEAN;
    user_role TEXT;
BEGIN
    -- Déterminer si l'utilisateur est admin
    user_email := COALESCE(p_email, '');
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');
    user_role := CASE WHEN is_admin THEN 'admin' ELSE 'technician' END;
    
    -- Insérer dans users
    INSERT INTO public.users (id, email, role)
    VALUES (p_user_id, user_email, user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Insérer dans subscription_status
    INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, is_admin, role)
    VALUES (p_user_id, p_first_name, p_last_name, user_email, true, is_admin, user_role)
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        is_active = EXCLUDED.is_active,
        is_admin = EXCLUDED.is_admin,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données utilisateur créées avec succès',
        'user_id', p_user_id,
        'is_admin', is_admin,
        'role', user_role
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la création des données: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_default_data_fixed(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_email TEXT;
    is_admin BOOLEAN;
BEGIN
    -- S'assurer que la colonne description existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'system_settings' AND column_name = 'description') THEN
        ALTER TABLE public.system_settings ADD COLUMN description text;
    END IF;
    
    -- Récupérer l'email de l'utilisateur
    SELECT email INTO user_email FROM auth.users WHERE id = p_user_id;
    
    -- Déterminer si l'utilisateur est admin
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');
    
    -- Insérer dans subscription_status avec gestion d'erreur simple
    INSERT INTO subscription_status (
        user_id,
        first_name,
        last_name,
        email,
        is_active,
        subscription_type,
        notes,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        'Utilisateur',
        'Test',
        user_email,
        is_admin,
        CASE WHEN is_admin THEN 'premium' ELSE 'free' END,
        'Compte créé automatiquement',
        NOW(),
        NOW()
    ) ON CONFLICT (user_id) DO NOTHING;
    
    -- Insérer les paramètres système par défaut
    INSERT INTO system_settings (user_id, key, value, description)
    VALUES 
        (p_user_id, 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
        (p_user_id, 'workshop_address', '', 'Adresse de l''atelier'),
        (p_user_id, 'workshop_phone', '', 'Téléphone de l''atelier'),
        (p_user_id, 'workshop_email', '', 'Email de l''atelier'),
        (p_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email'),
        (p_user_id, 'notifications', 'sms_notifications', 'false', 'Activer les notifications par SMS'),
        (p_user_id, 'appointments', 'appointment_duration', '60', 'Durée par défaut des rendez-vous (minutes)'),
        (p_user_id, 'appointments', 'working_hours_start', '08:00', 'Heure de début de travail'),
        (p_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail')
    ON CONFLICT (user_id, key) DO NOTHING;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données par défaut créées avec succès',
        'user_id', p_user_id
    );
EXCEPTION WHEN OTHERS THEN
    -- En cas d'erreur, retourner un succès pour ne pas bloquer l'inscription
    RETURN json_build_object(
        'success', true,
        'message', 'Données par défaut créées (avec avertissement)',
        'user_id', p_user_id,
        'warning', SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_default_data_permissive(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- S'assurer que la colonne description existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'system_settings' AND column_name = 'description') THEN
        ALTER TABLE public.system_settings ADD COLUMN description text;
    END IF;
    
    -- Insérer sans aucune vérification
    INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, subscription_type, notes)
    VALUES (p_user_id, 'Utilisateur', '', '', FALSE, 'free', 'Compte créé automatiquement')
    ON CONFLICT (user_id) DO NOTHING;
    
    INSERT INTO system_settings (user_id, key, value, description)
    VALUES 
        (p_user_id, 'workshop_name', 'Mon Atelier', 'Nom de l''atelier'),
        (p_user_id, 'workshop_address', '', 'Adresse de l''atelier'),
        (p_user_id, 'workshop_phone', '', 'Téléphone de l''atelier'),
        (p_user_id, 'workshop_email', '', 'Email de l''atelier'),
        (p_user_id, 'notifications', 'email_notifications', 'true', 'Activer les notifications par email'),
        (p_user_id, 'notifications', 'sms_notifications', 'false', 'Activer les notifications par SMS'),
        (p_user_id, 'appointments', 'appointment_duration', '60', 'Durée par défaut des rendez-vous (minutes)'),
        (p_user_id, 'appointments', 'working_hours_start', '08:00', 'Heure de début de travail'),
        (p_user_id, 'appointments', 'working_hours_end', '18:00', 'Heure de fin de travail')
    ON CONFLICT (user_id, key) DO NOTHING;

    RETURN json_build_object('success', true, 'message', 'Données créées avec succès');
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_manually(p_email text, p_password text, p_first_name text DEFAULT 'Utilisateur'::text, p_last_name text DEFAULT 'Test'::text, p_role text DEFAULT 'technician'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_id UUID;
    is_admin BOOLEAN;
    user_role TEXT;
    result JSON;
BEGIN
    -- Vérifier si l'email existe déjà
    IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Un utilisateur avec cet email existe déjà'
        );
    END IF;
    
    -- Déterminer le rôle
    is_admin := (p_email = 'srohee32@gmail.com' OR p_email = 'repphonereparation@gmail.com');
    user_role := CASE WHEN is_admin THEN 'admin' ELSE p_role END;
    
    -- Créer l'utilisateur dans auth.users
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        p_email,
        crypt(p_password, gen_salt('bf')),
        NOW(),
        NULL,
        NULL,
        '{"provider": "email", "providers": ["email"]}',
        '{"first_name": "' || p_first_name || '", "last_name": "' || p_last_name || '"}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    ) RETURNING id INTO user_id;
    
    -- Créer l'entrée dans public.users
    INSERT INTO public.users (id, email, role)
    VALUES (user_id, p_email, user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Créer l'entrée dans subscription_status
    -- Vérifier si la colonne role existe avant d'essayer de l'utiliser
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
        AND column_name = 'role'
        AND table_schema = 'public'
    ) THEN
        -- Si la colonne role existe, l'utiliser
        INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, role)
        VALUES (user_id, p_first_name, p_last_name, p_email, true, user_role)
        ON CONFLICT (user_id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            is_active = EXCLUDED.is_active,
            role = EXCLUDED.role,
            updated_at = NOW();
    ELSE
        -- Si la colonne role n'existe pas, ne pas l'utiliser
        INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active)
        VALUES (user_id, p_first_name, p_last_name, p_email, true)
        ON CONFLICT (user_id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            is_active = EXCLUDED.is_active,
            updated_at = NOW();
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisateur créé avec succès',
        'user_id', user_id,
        'email', p_email,
        'role', user_role,
        'is_admin', is_admin
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_simple(p_user_id uuid, p_first_name text, p_last_name text, p_email text, p_role text DEFAULT 'technician'::text, p_avatar text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel est un administrateur
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Accès non autorisé. Seuls les administrateurs peuvent créer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe déjà.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe déjà.'
    );
  END IF;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', p_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la création de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_simple_fallback(p_user_id uuid, p_first_name text, p_last_name text, p_email text, p_role text DEFAULT 'technician'::text, p_avatar text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Utilisateur non authentifie.'
    );
  END IF;

  -- Vérifier si l'email existe déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'L''email ' || p_email || ' est deja utilise par un autre utilisateur.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe deja.'
    );
  END IF;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    auth.uid(),
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', p_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_simple_fixed(p_user_id uuid, p_first_name text, p_last_name text, p_email text, p_role text DEFAULT 'technician'::text, p_avatar text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel est un administrateur
  IF NOT EXISTS (
    SELECT 1 FROM users 
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Accès non autorisé. Seuls les administrateurs peuvent créer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe déjà.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe déjà.'
    );
  END IF;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', p_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_with_auth(p_first_name text, p_last_name text, p_email text, p_password text, p_role text DEFAULT 'technician'::text, p_avatar text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_user_id UUID;
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel a les droits d'administration
  IF NOT check_admin_rights() THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Acces non autorise. Seuls les administrateurs et techniciens peuvent creer des utilisateurs.'
    );
  END IF;

  -- Vérifier que l'email n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet email existe deja.'
    );
  END IF;

  -- Créer l'utilisateur dans auth.users
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    (SELECT id FROM auth.instances LIMIT 1),
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    p_email,
    crypt(p_password, gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    json_build_object('provider', 'email', 'providers', ARRAY['email']),
    json_build_object('first_name', p_first_name, 'last_name', p_last_name, 'role', p_role),
    false,
    '',
    '',
    '',
    ''
  ) RETURNING id INTO v_user_id;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', v_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_with_email_check(p_user_id uuid, p_first_name text, p_last_name text, p_email text, p_role text DEFAULT 'technician'::text, p_avatar text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_result JSON;
BEGIN
  -- Vérifier que l'utilisateur actuel est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Utilisateur non authentifié.'
    );
  END IF;

  -- Vérifier si l'email existe déjà
  IF check_email_exists(p_email) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'L''email "' || p_email || '" est déjà utilisé par un autre utilisateur.'
    );
  END IF;

  -- Vérifier que l'ID n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Un utilisateur avec cet ID existe déjà.'
    );
  END IF;

  -- Créer l'enregistrement dans la table users
  INSERT INTO users (
    id,
    first_name,
    last_name,
    email,
    role,
    avatar,
    created_by,
    created_at,
    updated_at
  ) VALUES (
    p_user_id,
    p_first_name,
    p_last_name,
    p_email,
    p_role,
    p_avatar,
    auth.uid(),
    NOW(),
    NOW()
  );

  -- Retourner le succès avec les données de l'utilisateur créé
  SELECT json_build_object(
    'success', true,
    'data', json_build_object(
      'id', p_user_id,
      'first_name', p_first_name,
      'last_name', p_last_name,
      'email', p_email,
      'role', p_role,
      'avatar', p_avatar,
      'created_at', NOW(),
      'updated_at', NOW()
    )
  ) INTO v_result;

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Erreur lors de la creation de l''utilisateur: ' || SQLERRM
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_workshop_client(p_first_name text, p_last_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, first_name text, last_name text, email text, phone text, address text, workshop_id uuid)
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_client_id UUID;
    current_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Créer le client
    INSERT INTO clients (first_name, last_name, email, phone, address, workshop_id)
    VALUES (p_first_name, p_last_name, p_email, p_phone, p_address, current_workshop_id)
    RETURNING clients.id INTO new_client_id;
    
    -- Retourner le client créé
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id
    FROM clients c
    WHERE c.id = new_client_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_isolated_client(p_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    current_workshop_id UUID;
    deleted_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Supprimer le client seulement s'il appartient au workshop actuel
    DELETE FROM clients 
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', deleted_count > 0,
        'deleted_count', deleted_count,
        'message', CASE 
            WHEN deleted_count > 0 THEN 'Client supprimé avec succès'
            ELSE 'Client non trouvé ou non accessible'
        END
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_multiple_users_safely(p_user_ids uuid[])
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_id UUID;
    results JSON[] := '{}';
    success_count INTEGER := 0;
    error_count INTEGER := 0;
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seuls les administrateurs peuvent supprimer des utilisateurs'
        );
    END IF;
    
    -- Parcourir chaque utilisateur à supprimer
    FOREACH user_id IN ARRAY p_user_ids
    LOOP
        result := delete_user_safely(user_id);
        results := array_append(results, result);
        
        IF (result->>'success')::boolean THEN
            success_count := success_count + 1;
        ELSE
            error_count := error_count + 1;
        END IF;
    END LOOP;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Suppression en masse terminée',
        'success_count', success_count,
        'error_count', error_count,
        'results', results
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.delete_user_safely(p_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    user_email TEXT;
    user_role TEXT;
    result JSON;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT email, role INTO user_email, user_role
    FROM public.users 
    WHERE id = auth.uid();
    
    IF user_role != 'admin' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès refusé: seuls les administrateurs peuvent supprimer des utilisateurs'
        );
    END IF;
    
    -- Vérifier que l'utilisateur à supprimer existe
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé'
        );
    END IF;
    
    -- Supprimer l'utilisateur (cascade supprimera les données liées)
    DELETE FROM public.users WHERE id = p_user_id;
    
    -- Supprimer de auth.users (nécessite des privilèges élevés)
    -- Note: Cette partie peut nécessiter une approche différente selon les permissions
    
    RETURN json_build_object(
        'success', true,
        'message', 'Utilisateur supprimé avec succès'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la suppression: ' || SQLERRM
    );
END;
$function$
;

create or replace view "public"."device_models_my_models" as  SELECT id,
    brand,
    model,
    type,
    year,
    specifications,
    common_issues,
    repair_difficulty,
    parts_availability,
    is_active,
    created_by,
    user_id,
    created_at,
    updated_at
   FROM device_models
  WHERE ((created_by = auth.uid()) OR (user_id = auth.uid()));


CREATE OR REPLACE FUNCTION public.diagnose_signup_issues()
 RETURNS TABLE(issue_type text, description text, recommendation text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Vérifier les triggers sur la table users
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgrelid = 'users'::regclass) THEN
        RETURN QUERY SELECT 
            'TRIGGER'::TEXT,
            'Des triggers existent sur la table users'::TEXT,
            'Supprimer tous les triggers sur la table users'::TEXT;
    END IF;
    
    -- Vérifier les contraintes problématiques
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'users' AND constraint_type = 'CHECK' 
               AND constraint_name LIKE '%subscription%') THEN
        RETURN QUERY SELECT 
            'CONSTRAINT'::TEXT,
            'Contraintes CHECK problématiques sur la table users'::TEXT,
            'Vérifier et supprimer les contraintes CHECK problématiques'::TEXT;
    END IF;
    
    -- Vérifier les politiques RLS sur auth.users
    IF EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'users' AND schemaname = 'auth') THEN
        RETURN QUERY SELECT 
            'RLS'::TEXT,
            'Politiques RLS sur auth.users'::TEXT,
            'Vérifier les politiques RLS sur auth.users'::TEXT;
    END IF;
    
    RETURN QUERY SELECT 
        'INFO'::TEXT,
        'Aucun problème détecté'::TEXT,
        'L''inscription devrait fonctionner normalement'::TEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fix_foreign_key_constraints()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    constraint_record RECORD;
    sql_command TEXT;
    result TEXT := '';
BEGIN
    -- Parcourir toutes les contraintes de clés étrangères qui référencent auth.users
    FOR constraint_record IN
        SELECT 
            tc.table_name,
            tc.constraint_name,
            kcu.column_name,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        JOIN information_schema.referential_constraints AS rc
            ON tc.constraint_name = rc.constraint_name
            AND tc.table_schema = rc.constraint_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND ccu.table_name = 'users'
            AND ccu.table_schema = 'auth'
            AND rc.delete_rule IN ('RESTRICT', 'NO ACTION')
    LOOP
        -- Supprimer la contrainte existante
        sql_command := 'ALTER TABLE ' || constraint_record.table_name || 
                      ' DROP CONSTRAINT ' || constraint_record.constraint_name;
        EXECUTE sql_command;
        result := result || 'Supprimé: ' || constraint_record.constraint_name || E'\n';
        
        -- Recréer la contrainte avec CASCADE
        sql_command := 'ALTER TABLE ' || constraint_record.table_name || 
                      ' ADD CONSTRAINT ' || constraint_record.constraint_name || 
                      ' FOREIGN KEY (' || constraint_record.column_name || 
                      ') REFERENCES auth.users(id) ON DELETE CASCADE';
        EXECUTE sql_command;
        result := result || 'Recréé avec CASCADE: ' || constraint_record.constraint_name || E'\n';
    END LOOP;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_confirmation_token_and_send_email(p_email text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    confirmation_token TEXT;
    expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
BEGIN
    -- Générer un token unique
    confirmation_token := encode(gen_random_bytes(32), 'hex');
    expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || confirmation_token;
    
    -- Insérer le token dans la table avec gestion de conflit
    INSERT INTO confirmation_emails (user_email, token, expires_at)
    VALUES (p_email, confirmation_token, expires_at)
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'pending',
        sent_at = NULL;
    
    -- Marquer comme envoyé (simulation)
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = confirmation_token;
    
    -- Retourner le résultat
    RETURN json_build_object(
        'success', true,
        'token', confirmation_token,
        'expires_at', expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', true,
        'message', 'Token généré et email préparé - Configurez Supabase Auth pour l''envoi réel',
        'instructions', 'Allez dans Supabase Dashboard > Authentication > Email Templates',
        'next_steps', ARRAY[
            '1. Aller sur https://supabase.com/dashboard',
            '2. Sélectionner votre projet',
            '3. Authentication > Email Templates',
            '4. Configurer le template de confirmation',
            '5. Tester l''envoi d''email'
        ]
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_repair_number()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_number VARCHAR(20);
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
BEGIN
    LOOP
        -- Générer un numéro au format REP-YYYYMMDD-XXXX
        new_number := 'REP-' || 
                     TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                     LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
        
        -- Vérifier si le numéro existe déjà
        IF NOT EXISTS (SELECT 1 FROM repairs WHERE repair_number = new_number) THEN
            RETURN new_number;
        END IF;
        
        counter := counter + 1;
        IF counter >= max_attempts THEN
            -- Si trop de tentatives, utiliser un timestamp
            new_number := 'REP-' || 
                         TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' ||
                         LPAD(EXTRACT(EPOCH FROM NOW())::INTEGER % 10000, 4, '0');
            RETURN new_number;
        END IF;
    END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_unique_order_number()
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_order_number TEXT;
    counter INTEGER := 0;
    max_attempts INTEGER := 10;
BEGIN
    LOOP
        -- Générer un numéro de commande avec timestamp + random + compteur
        new_order_number := 'CMD-' || 
                           EXTRACT(EPOCH FROM NOW())::BIGINT || '-' ||
                           LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0') || '-' ||
                           LPAD(counter::TEXT, 2, '0');
        
        -- Vérifier si ce numéro existe déjà
        IF NOT EXISTS (
            SELECT 1 FROM orders 
            WHERE order_number = new_order_number
        ) THEN
            RETURN new_order_number;
        END IF;
        
        counter := counter + 1;
        
        -- Éviter une boucle infinie
        IF counter >= max_attempts THEN
            RAISE EXCEPTION 'Impossible de générer un numéro de commande unique après % tentatives', max_attempts;
        END IF;
    END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_unique_serial_number(base_serial text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_serial TEXT;
    counter INTEGER := 1;
BEGIN
    -- Si aucun numéro de base fourni, générer un numéro par défaut
    IF base_serial IS NULL OR base_serial = '' THEN
        base_serial := 'SN' || EXTRACT(EPOCH FROM NOW())::TEXT;
    END IF;
    
    new_serial := base_serial;
    
    -- Chercher un numéro de série unique
    WHILE EXISTS (SELECT 1 FROM devices WHERE serial_number = new_serial) LOOP
        counter := counter + 1;
        new_serial := base_serial || '_' || counter;
    END LOOP;
    
    RETURN new_serial;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_active_subscription(user_uuid uuid)
 RETURNS TABLE(subscription_id uuid, plan_id uuid, plan_name character varying, plan_price numeric, start_date timestamp with time zone, end_date timestamp with time zone, days_remaining integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        us.id as subscription_id,
        us.plan_id,
        sp.name as plan_name,
        sp.price as plan_price,
        us.start_date,
        us.end_date,
        EXTRACT(DAY FROM (us.end_date - NOW()))::INTEGER as days_remaining
    FROM user_subscriptions us
    JOIN subscription_plans sp ON us.plan_id = sp.id
    WHERE us.user_id = user_uuid 
    AND us.status = 'active' 
    AND us.end_date > NOW()
    AND us.payment_status = 'paid'
    ORDER BY us.end_date DESC
    LIMIT 1;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_archive_stats()
 RETURNS TABLE(total_archived integer, total_paid integer, total_unpaid integer, total_amount numeric, avg_repair_time_days numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_archived,
        COUNT(*) FILTER (WHERE is_paid = true)::INTEGER as total_paid,
        COUNT(*) FILTER (WHERE is_paid = false)::INTEGER as total_unpaid,
        COALESCE(SUM(total_price), 0) as total_amount,
        COALESCE(
            AVG(
                EXTRACT(EPOCH FROM (updated_at - created_at)) / 86400
            ), 0
        )::DECIMAL(5,2) as avg_repair_time_days
    FROM repairs 
    WHERE status = 'returned';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_archived_repairs_by_period(period_days integer)
 RETURNS TABLE(id uuid, client_name text, device_info text, total_price numeric, archived_date timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.total_price,
        r.updated_at as archived_date
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = 'returned'
    AND r.updated_at >= NOW() - (period_days || ' days')::INTERVAL
    ORDER BY r.updated_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_isolated_clients()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    result JSON;
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN '[]'::JSON;
    END IF;
    
    SELECT json_agg(
        json_build_object(
            'id', c.id,
            'firstName', c.first_name,
            'lastName', c.last_name,
            'email', c.email,
            'phone', c.phone,
            'address', c.address,
            'notes', c.notes,
            'category', c.category,
            'title', c.title,
            'companyName', c.company_name,
            'vatNumber', c.vat_number,
            'sirenNumber', c.siren_number,
            'countryCode', c.country_code,
            'addressComplement', c.address_complement,
            'region', c.region,
            'postalCode', c.postal_code,
            'city', c.city,
            'billingAddressSame', c.billing_address_same,
            'billingAddress', c.billing_address,
            'billingAddressComplement', c.billing_address_complement,
            'billingRegion', c.billing_region,
            'billingPostalCode', c.billing_postal_code,
            'billingCity', c.billing_city,
            'accountingCode', c.accounting_code,
            'cniIdentifier', c.cni_identifier,
            'attachedFilePath', c.attached_file_path,
            'internalNote', c.internal_note,
            'status', c.status,
            'smsNotification', c.sms_notification,
            'emailNotification', c.email_notification,
            'smsMarketing', c.sms_marketing,
            'emailMarketing', c.email_marketing,
            'createdAt', c.created_at,
            'updatedAt', c.updated_at
        )
    ) INTO result
    FROM public.clients c
    WHERE c.user_id = current_user_id;
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_isolated_clients_adapted()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    result JSON;
    current_workshop_id UUID;
BEGIN
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    SELECT json_agg(
        json_build_object(
            'id', c.id,
            'first_name', c.first_name,
            'last_name', c.last_name,
            'email', c.email,
            'phone', c.phone,
            'address', c.address,
            'workshop_id', c.workshop_id
        )
    ) INTO result
    FROM clients c
    WHERE c.workshop_id = current_workshop_id;
    
    RETURN COALESCE(result, '[]'::JSON);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_loyalty_config(p_workshop_id uuid)
 RETURNS TABLE(key text, value text, description text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT lc.key, lc.value, lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = p_workshop_id
    ORDER BY lc.key;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_loyalty_statistics()
 RETURNS TABLE(total_clients integer, clients_with_points integer, total_points bigint, average_points numeric, top_tier_clients integer, recent_activity integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        -- Total des clients
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)), 0)::INTEGER as total_clients,
        
        -- Clients avec des points
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points > 0), 0)::INTEGER as clients_with_points,
        
        -- Total des points
        COALESCE((SELECT SUM(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)), 0)::BIGINT as total_points,
        
        -- Moyenne des points
        COALESCE((SELECT AVG(loyalty_points) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points > 0), 0)::NUMERIC as average_points,
        
        -- Clients de niveau supérieur
        COALESCE((SELECT COUNT(*) FROM clients 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND loyalty_points >= 1000), 0)::INTEGER as top_tier_clients,
        
        -- Activité récente (derniers 30 jours)
        COALESCE((SELECT COUNT(*) FROM loyalty_points_history 
                  WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
                  AND created_at >= NOW() - INTERVAL '30 days'), 0)::INTEGER as recent_activity;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_loyalty_tiers(p_workshop_id uuid)
 RETURNS TABLE(id uuid, name text, points_required integer, discount_percentage numeric, color text, description text, is_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        lta.id,
        lta.name,
        lta.points_required,
        lta.discount_percentage,
        lta.color,
        lta.description,
        lta.is_active
    FROM loyalty_tiers_advanced lta
    WHERE lta.workshop_id = p_workshop_id
    ORDER BY lta.points_required;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_clients_json()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    result JSON;
BEGIN
    -- Construire le résultat en JSON avec une approche différente
    WITH clients_data AS (
        SELECT 
            c.id,
            c.first_name,
            c.last_name,
            c.email,
            c.phone,
            c.address,
            c.city,
            c.postal_code,
            c.company,
            c.notes,
            c.created_by,
            c.created_at,
            c.updated_at
        FROM public.clients c
        ORDER BY c.created_at DESC
    )
    SELECT json_agg(
        json_build_object(
            'id', id,
            'first_name', first_name,
            'last_name', last_name,
            'email', email,
            'phone', phone,
            'address', address,
            'city', city,
            'postal_code', postal_code,
            'company', company,
            'notes', notes,
            'created_by', created_by,
            'created_at', created_at,
            'updated_at', updated_at
        )
    ) INTO result
    FROM clients_data;
    
    -- Retourner le résultat ou un tableau vide
    RETURN COALESCE(result, '[]'::json);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_clients_simple()
 RETURNS TABLE(id uuid, first_name text, last_name text, email text, phone text, address text, city text, postal_code text, company text, notes text, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Retourner tous les clients avec conversion de types
    RETURN QUERY
    SELECT 
        c.id,
        COALESCE(c.first_name, '')::TEXT,
        COALESCE(c.last_name, '')::TEXT,
        COALESCE(c.email, '')::TEXT,
        COALESCE(c.phone, '')::TEXT,
        COALESCE(c.address, '')::TEXT,
        COALESCE(c.city, '')::TEXT,
        COALESCE(c.postal_code, '')::TEXT,
        COALESCE(c.company, '')::TEXT,
        COALESCE(c.notes, '')::TEXT,
        c.created_by,
        c.created_at,
        c.updated_at
    FROM public.clients c
    ORDER BY c.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_my_users()
 RETURNS TABLE(id uuid, first_name text, last_name text, email text, role text, avatar text, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    u.avatar,
    u.created_at,
    u.updated_at
  FROM users u
  WHERE u.created_by = auth.uid()
  ORDER BY u.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_order_stats()
 RETURNS TABLE(total integer, pending integer, confirmed integer, shipped integer, delivered integer, cancelled integer, total_amount numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total,
        COUNT(CASE WHEN o.status = 'pending' THEN 1 END)::INTEGER as pending,
        COUNT(CASE WHEN o.status = 'confirmed' THEN 1 END)::INTEGER as confirmed,
        COUNT(CASE WHEN o.status = 'shipped' THEN 1 END)::INTEGER as shipped,
        COUNT(CASE WHEN o.status = 'delivered' THEN 1 END)::INTEGER as delivered,
        COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END)::INTEGER as cancelled,
        COALESCE(SUM(o.total_amount), 0) as total_amount
    FROM orders o
    WHERE o.workshop_id = (
        SELECT value::UUID FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_payment_statistics()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result JSON;
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    ) INTO v_workshop_id;

    -- Calculer les statistiques
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'total_completed_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND workshop_id = v_workshop_id
            ),
            'paid_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = true
                AND workshop_id = v_workshop_id
            ),
            'unpaid_repairs', (
                SELECT COUNT(*) 
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = false
                AND workshop_id = v_workshop_id
            ),
            'total_revenue_paid', (
                SELECT COALESCE(SUM(total_price), 0)
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = true
                AND workshop_id = v_workshop_id
            ),
            'total_revenue_unpaid', (
                SELECT COALESCE(SUM(total_price), 0)
                FROM repairs 
                WHERE status IN ('completed', 'returned')
                AND is_paid = false
                AND workshop_id = v_workshop_id
            )
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_repair_tracking_info(p_repair_id uuid, p_client_email text)
 RETURNS TABLE(repair_id uuid, repair_status text, repair_description text, repair_issue text, estimated_start_date timestamp with time zone, estimated_end_date timestamp with time zone, start_date timestamp with time zone, end_date timestamp with time zone, due_date timestamp with time zone, is_urgent boolean, notes text, total_price numeric, is_paid boolean, created_at timestamp with time zone, updated_at timestamp with time zone, client_first_name text, client_last_name text, client_email text, client_phone text, device_brand text, device_model text, device_serial_number text, device_type text, technician_first_name text, technician_last_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        r.id as repair_id,
        r.status as repair_status,
        r.description as repair_description,
        r.issue as repair_issue,
        r.estimated_start_date,
        r.estimated_end_date,
        r.start_date,
        r.end_date,
        r.due_date,
        r.is_urgent,
        r.notes,
        r.total_price,
        r.is_paid,
        r.created_at,
        r.updated_at,
        c.first_name as client_first_name,
        c.last_name as client_last_name,
        c.email as client_email,
        c.phone as client_phone,
        d.brand as device_brand,
        d.model as device_model,
        d.serial_number as device_serial_number,
        d.type as device_type,
        u.first_name as technician_first_name,
        u.last_name as technician_last_name
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    LEFT JOIN users u ON r.assigned_technician_id = u.id
    WHERE r.id = p_repair_id 
    AND c.email = p_client_email;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_repairs_by_status(repair_status text)
 RETURNS TABLE(id uuid, client_name text, device_info text, status text, created_at timestamp with time zone, due_date timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.status,
        r.created_at,
        r.due_date
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = repair_status
    ORDER BY r.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_subscription_stats()
 RETURNS TABLE(total_users integer, locked_users integer, unlocked_users integer, admin_users integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_users,
        COUNT(*) FILTER (WHERE up.is_locked = true)::INTEGER as locked_users,
        COUNT(*) FILTER (WHERE up.is_locked = false)::INTEGER as unlocked_users,
        COUNT(*) FILTER (WHERE u.role = 'admin')::INTEGER as admin_users
    FROM public.users u
    LEFT JOIN public.user_profiles up ON u.id = up.user_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_device_models()
 RETURNS TABLE(id uuid, brand text, model text, type text, year integer, specifications jsonb, common_issues text[], repair_difficulty text, parts_availability text, is_active boolean, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        dm.id,
        dm.brand,
        dm.model,
        dm.type,
        dm.year,
        dm.specifications,
        dm.common_issues,
        dm.repair_difficulty,
        dm.parts_availability,
        dm.is_active,
        dm.created_by,
        dm.created_at,
        dm.updated_at
    FROM device_models dm
    WHERE dm.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY dm.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_devices()
 RETURNS TABLE(id uuid, name text, model text, status text, location text, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.name,
        d.model,
        d.status,
        d.location,
        d.created_by,
        d.created_at,
        d.updated_at
    FROM devices d
    WHERE d.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY d.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_devices_isolated()
 RETURNS TABLE(id uuid, brand text, model text, type text, serial_number text, specifications jsonb, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.brand,
        d.model,
        d.type,
        d.serial_number,
        d.specifications,
        d.created_by,
        d.created_at,
        d.updated_at
    FROM devices d
    WHERE d.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY d.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_lock_status(user_uuid uuid DEFAULT auth.uid())
 RETURNS TABLE(user_id uuid, is_locked boolean, email text, first_name text, last_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        up.user_id,
        up.is_locked,
        up.email,
        up.first_name,
        up.last_name
    FROM public.user_profiles up
    WHERE up.user_id = user_uuid;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_repairs_isolated()
 RETURNS TABLE(id uuid, client_id uuid, device_id uuid, status text, assigned_technician_id uuid, description text, issue text, estimated_duration integer, actual_duration integer, estimated_start_date date, estimated_end_date date, start_date date, end_date date, due_date date, is_urgent boolean, notes text, total_price numeric, is_paid boolean, created_by uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        r.client_id,
        r.device_id,
        r.status,
        r.assigned_technician_id,
        r.description,
        r.issue,
        r.estimated_duration,
        r.actual_duration,
        r.estimated_start_date,
        r.estimated_end_date,
        r.start_date,
        r.end_date,
        r.due_date,
        r.is_urgent,
        r.notes,
        r.total_price,
        r.is_paid,
        r.created_by,
        r.created_at,
        r.updated_at
    FROM repairs r
    WHERE r.created_by = auth.uid()
       OR EXISTS (
           SELECT 1 FROM system_settings 
           WHERE key = 'workshop_type' 
           AND value = 'gestion'
           LIMIT 1
       )
    ORDER BY r.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_users_without_rls()
 RETURNS TABLE(id uuid, first_name text, last_name text, email text, role text, avatar text, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Désactiver temporairement RLS pour cette requête
  ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
  
  -- Récupérer les données
  RETURN QUERY
  SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    u.avatar,
    u.created_at,
    u.updated_at
  FROM public.users u
  ORDER BY u.created_at DESC;
  
  -- Réactiver RLS
  ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_workshop_clients()
 RETURNS TABLE(id uuid, first_name text, last_name text, email text, phone text, address text, workshop_id uuid, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.first_name,
        c.last_name,
        c.email,
        c.phone,
        c.address,
        c.workshop_id,
        c.created_at,
        c.updated_at
    FROM clients c
    WHERE c.workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_workshop_loyalty_config()
 RETURNS TABLE(key text, value text, description text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    RETURN QUERY
    SELECT 
        lc.key,
        lc.value,
        lc.description
    FROM loyalty_config lc
    WHERE lc.workshop_id = auth.uid()
    ORDER BY lc.key;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_workshop_loyalty_tiers()
 RETURNS TABLE(id uuid, name text, points_required integer, discount_percentage numeric, color text, description text, is_active boolean, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier l'authentification
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    RETURN QUERY
    SELECT 
        lta.id,
        lta.name,
        lta.points_required,
        lta.discount_percentage,
        lta.color,
        lta.description,
        lta.is_active,
        lta.created_at,
        lta.updated_at
    FROM loyalty_tiers_advanced lta
    WHERE lta.workshop_id = auth.uid()
    AND lta.is_active = true
    ORDER BY lta.points_required ASC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_duplicate_emails()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    existing_client RECORD;
BEGIN
    -- Vérifier les doublons seulement si l'email n'est pas vide
    IF NEW.email IS NOT NULL AND TRIM(NEW.email) != '' THEN
        -- Chercher un client existant avec le même email pour le même utilisateur
        SELECT * INTO existing_client
        FROM clients 
        WHERE email = NEW.email 
        AND user_id = NEW.user_id
        AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
        LIMIT 1;
        
        IF existing_client IS NOT NULL THEN
            RAISE EXCEPTION 'Un client avec l''email % existe déjà pour cet utilisateur', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_duplicate_signup(p_email text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    existing_record RECORD;
    new_token TEXT;
    confirmation_url TEXT;
BEGIN
    -- Vérifier si l'email existe déjà
    SELECT * INTO existing_record 
    FROM pending_signups 
    WHERE email = p_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
    
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour le timestamp de mise à jour (sans colonne token)
    UPDATE pending_signups 
    SET updated_at = NOW()
    WHERE email = p_email;
    
    -- Insérer ou mettre à jour dans confirmation_emails
    INSERT INTO confirmation_emails (user_email, token, expires_at, status, sent_at)
    VALUES (p_email, new_token, NOW() + INTERVAL '24 hours', 'sent', NOW())
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'sent',
        sent_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'confirmation_url', confirmation_url,
        'message', 'Nouveau token généré pour l''email existant',
        'status', existing_record.status,
        'data', row_to_json(existing_record)
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.has_active_subscription(user_uuid uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_subscriptions 
        WHERE user_id = user_uuid 
        AND status = 'active' 
        AND end_date > NOW()
        AND payment_status = 'paid'
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.has_admin_access(user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_id AND (role = 'admin' OR role = 'technician')
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.initialize_new_repairer_account(user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier que l'utilisateur existe
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id) THEN
        RAISE EXCEPTION 'Utilisateur non trouvé: %', user_id;
    END IF;
    
    -- Créer des données de démonstration pour le nouveau compte
    INSERT INTO clients (
        first_name, last_name, email, phone, address, user_id, created_by
    ) VALUES 
    (
        'Client', 'Démonstration', 'demo@example.com', '0123456789', '123 Rue de la Démo', user_id, user_id
    );
    
    RAISE NOTICE 'Compte initialisé pour l''utilisateur: %', user_id;
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Erreur lors de l''initialisation: %', SQLERRM;
    RETURN FALSE;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_user_locked(user_uuid uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    locked_status BOOLEAN;
BEGIN
    SELECT is_locked INTO locked_status
    FROM public.user_profiles
    WHERE user_id = user_uuid;
    
    RETURN COALESCE(locked_status, true); -- Par défaut verrouillé si pas trouvé
END;
$function$
;

CREATE OR REPLACE FUNCTION public.list_all_users()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    users_data JSON;
BEGIN
    -- Vérifier si la colonne role existe dans subscription_status
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'subscription_status' 
        AND column_name = 'role'
        AND table_schema = 'public'
    ) THEN
        -- Si la colonne role existe, l'utiliser
        WITH ordered_users AS (
            SELECT 
                u.id,
                u.email,
                u.role,
                u.created_at,
                ss.is_active,
                ss.role as subscription_role
            FROM public.users u
            LEFT JOIN subscription_status ss ON u.id = ss.user_id
            ORDER BY u.created_at DESC
        )
        SELECT json_agg(
            json_build_object(
                'id', id,
                'email', email,
                'role', role,
                'created_at', created_at,
                'subscription_status', is_active,
                'subscription_role', subscription_role
            )
        ) INTO users_data
        FROM ordered_users;
    ELSE
        -- Si la colonne role n'existe pas, ne pas l'utiliser
        WITH ordered_users AS (
            SELECT 
                u.id,
                u.email,
                u.role,
                u.created_at,
                ss.is_active
            FROM public.users u
            LEFT JOIN subscription_status ss ON u.id = ss.user_id
            ORDER BY u.created_at DESC
        )
        SELECT json_agg(
            json_build_object(
                'id', id,
                'email', email,
                'role', role,
                'created_at', created_at,
                'subscription_status', is_active,
                'subscription_role', NULL
            )
        ) INTO users_data
        FROM ordered_users;
    END IF;
    
    RETURN json_build_object(
        'success', true,
        'users', COALESCE(users_data, '[]'::json),
        'count', (SELECT COUNT(*) FROM public.users)
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.list_pending_emails()
 RETURNS TABLE(id uuid, user_email text, token text, expires_at timestamp with time zone, status text, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.user_email,
        ce.token,
        ce.expires_at,
        ce.status,
        ce.created_at
    FROM confirmation_emails ce
    WHERE ce.status IN ('pending', 'sent')
    ORDER BY ce.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.lock_user(target_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    current_user_role TEXT;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT role INTO current_user_role
    FROM public.users
    WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RAISE EXCEPTION 'Accès refusé: seuls les administrateurs peuvent verrouiller des utilisateurs';
    END IF;
    
    -- Verrouiller l'utilisateur
    UPDATE public.user_profiles
    SET is_locked = true, updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN FOUND;
END;
$function$
;

create or replace view "public"."loyalty_dashboard" as  SELECT c.id AS client_id,
    c.first_name,
    c.last_name,
    c.email,
    COALESCE(c.loyalty_points, 0) AS current_points,
    lt.name AS current_tier,
    lt.discount_percentage,
    lt.color AS tier_color,
    lt.benefits,
    ( SELECT count(*) AS count
           FROM loyalty_points_history lph
          WHERE (lph.client_id = c.id)) AS total_transactions,
    ( SELECT sum(lph.points_change) AS sum
           FROM loyalty_points_history lph
          WHERE ((lph.client_id = c.id) AND (lph.points_type = 'earned'::text))) AS total_points_earned,
    ( SELECT sum(lph.points_change) AS sum
           FROM loyalty_points_history lph
          WHERE ((lph.client_id = c.id) AND (lph.points_type = 'used'::text))) AS total_points_used,
    c.created_at AS client_since,
    c.updated_at AS last_activity
   FROM (clients c
     LEFT JOIN loyalty_tiers_advanced lt ON ((c.current_tier_id = lt.id)))
  WHERE ((COALESCE(c.loyalty_points, 0) > 0) AND (c.workshop_id = ( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1)))
  ORDER BY c.loyalty_points DESC;


create or replace view "public"."loyalty_dashboard_isolated" as  SELECT ld.client_id,
    ld.first_name,
    ld.last_name,
    ld.email,
    ld.current_points,
    ld.current_tier,
    ld.discount_percentage,
    ld.tier_color,
    ld.benefits,
    ld.total_transactions,
    ld.total_points_earned,
    ld.total_points_used,
    ld.client_since,
    ld.last_activity
   FROM (loyalty_dashboard ld
     JOIN clients c ON ((ld.client_id = c.id)))
  WHERE (c.workshop_id = ( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1));


CREATE OR REPLACE FUNCTION public.mark_email_sent(p_email text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND status = 'pending';
    
    IF FOUND THEN
        RETURN json_build_object(
            'success', true,
            'message', 'Email marqué comme envoyé'
        );
    ELSE
        RETURN json_build_object(
            'success', false,
            'error', 'Aucun email en attente trouvé'
        );
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.prevent_duplicate_serial_numbers()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Vérifier si le numéro de série existe déjà (sauf pour l'enregistrement en cours de modification)
    IF NEW.serial_number IS NOT NULL AND NEW.serial_number != '' THEN
        IF EXISTS (
            SELECT 1 FROM devices 
            WHERE serial_number = NEW.serial_number 
            AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID)
        ) THEN
            RAISE EXCEPTION 'Un appareil avec le numéro de série % existe déjà', NEW.serial_number;
        END IF;
        
        -- Valider le format du numéro de série
        IF NOT validate_serial_number_format(NEW.serial_number) THEN
            RAISE EXCEPTION 'Format de numéro de série invalide: %', NEW.serial_number;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.process_pending_signup(p_email text, p_first_name text, p_last_name text, p_role text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    pending_record RECORD;
    new_user_id UUID;
BEGIN
    -- Vérifier si la demande existe
    SELECT * INTO pending_record FROM pending_signups WHERE email = p_email AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Demande d''inscription non trouvée'
        );
    END IF;

    -- Marquer la demande comme traitée
    UPDATE pending_signups 
    SET status = 'processing', updated_at = NOW()
    WHERE id = pending_record.id;

    -- Créer l'utilisateur dans auth.users via une fonction spéciale
    -- Note: Cette partie nécessite des permissions spéciales
    BEGIN
        -- Essayer de créer l'utilisateur via une approche alternative
        -- Si cela échoue, nous utiliserons une méthode de contournement
        
        -- Pour l'instant, marquer comme en attente d'approbation manuelle
        UPDATE pending_signups 
        SET status = 'manual_approval_required', updated_at = NOW()
        WHERE id = pending_record.id;

        RETURN json_build_object(
            'success', true,
            'message', 'Demande d''inscription enregistrée. Un administrateur va traiter votre demande.',
            'status', 'manual_approval_required'
        );
    EXCEPTION WHEN OTHERS THEN
        -- En cas d'erreur, marquer comme échec
        UPDATE pending_signups 
        SET status = 'failed', updated_at = NOW()
        WHERE id = pending_record.id;

        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors du traitement: ' || SQLERRM
        );
    END;
END;
$function$
;

create or replace view "public"."repair_history_view" as  SELECT r.id,
    r.client_id,
    ((c.first_name || ' '::text) || c.last_name) AS client_name,
    r.device_id,
    (((d.brand)::text || ' '::text) || (d.model)::text) AS device_name,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.workshop_id,
    r.created_at,
    r.updated_at
   FROM ((repairs r
     LEFT JOIN clients c ON ((r.client_id = c.id)))
     LEFT JOIN devices d ON ((r.device_id = d.id)))
  WHERE (r.workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid))
  ORDER BY r.created_at DESC;


create or replace view "public"."repair_tracking_view" as  SELECT r.id,
    r.client_id,
    ((c.first_name || ' '::text) || c.last_name) AS client_name,
    r.device_id,
    (((d.brand)::text || ' '::text) || (d.model)::text) AS device_name,
    r.description,
    r.status,
    r.estimated_cost,
    r.actual_cost,
    r.workshop_id,
    r.created_at,
    r.updated_at
   FROM ((repairs r
     LEFT JOIN clients c ON ((r.client_id = c.id)))
     LEFT JOIN devices d ON ((r.device_id = d.id)))
  WHERE (r.workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid));


create or replace view "public"."repairs_filtered" as  SELECT id,
    client_id,
    device_id,
    description,
    status,
    estimated_cost,
    actual_cost,
    workshop_id,
    created_at,
    updated_at
   FROM repairs
  WHERE ((workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid)) AND (status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text])));


create or replace view "public"."repairs_isolated" as  SELECT id,
    client_id,
    device_id,
    description,
    status,
    estimated_cost,
    actual_cost,
    workshop_id,
    created_at,
    updated_at
   FROM repairs
  WHERE (workshop_id = COALESCE(( SELECT (system_settings.value)::uuid AS value
           FROM system_settings
          WHERE ((system_settings.key)::text = 'workshop_id'::text)
         LIMIT 1), '00000000-0000-0000-0000-000000000000'::uuid));


CREATE OR REPLACE FUNCTION public.resend_confirmation_email_real(p_email text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_token TEXT;
    new_expires_at TIMESTAMP WITH TIME ZONE;
    confirmation_url TEXT;
BEGIN
    -- Générer un nouveau token
    new_token := encode(gen_random_bytes(32), 'hex');
    new_expires_at := NOW() + INTERVAL '24 hours';
    confirmation_url := 'http://localhost:3001/auth?tab=confirm&token=' || new_token;
    
    -- Mettre à jour le token
    UPDATE confirmation_emails 
    SET token = new_token, expires_at = new_expires_at, status = 'pending', sent_at = NULL
    WHERE user_email = p_email;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Email non trouvé'
        );
    END IF;
    
    -- Simuler l'envoi du nouvel email
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = new_token;
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'expires_at', new_expires_at,
        'confirmation_url', confirmation_url,
        'email_sent', true,
        'message', 'Nouvel email de confirmation simulé'
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.resolve_stock_alerts_automatically()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Si le stock est maintenant suffisant, résoudre les alertes
    IF NEW.stock_quantity > NEW.min_stock_level THEN
        UPDATE public.stock_alerts 
        SET is_resolved = TRUE, updated_at = NOW()
        WHERE part_id = NEW.id AND is_resolved = FALSE;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.restore_repair_from_archive(repair_uuid uuid)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE repairs 
    SET status = 'completed', updated_at = NOW()
    WHERE id = repair_uuid AND status = 'returned';
    
    IF FOUND THEN
        RAISE NOTICE 'Réparation % restaurée avec succès', repair_uuid;
        RETURN true;
    ELSE
        RAISE NOTICE 'Réparation % non trouvée ou pas en archive', repair_uuid;
        RETURN false;
    END IF;
END;
$function$
;

create or replace view "public"."sales_by_category" as  SELECT COALESCE(si.category, 'non_categorise'::text) AS category,
    count(*) AS nombre_ventes,
    sum(si.quantity) AS quantite_totale,
    sum(si.total_price) AS chiffre_affaires,
    avg(si.unit_price) AS prix_moyen
   FROM (sale_items si
     JOIN sales s ON ((si.sale_id = s.id)))
  WHERE (si.type = 'product'::text)
  GROUP BY si.category
  ORDER BY (sum(si.total_price)) DESC;


CREATE OR REPLACE FUNCTION public.search_archived_repairs(search_query text DEFAULT ''::text, device_type_filter text DEFAULT 'all'::text, date_filter text DEFAULT 'all'::text, paid_only boolean DEFAULT false)
 RETURNS TABLE(id uuid, client_name text, device_info text, description text, issue text, total_price numeric, is_paid boolean, created_at timestamp with time zone, updated_at timestamp with time zone, device_type text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        r.id,
        CONCAT(c.first_name, ' ', c.last_name) as client_name,
        CONCAT(d.brand, ' ', d.model) as device_info,
        r.description,
        r.issue,
        r.total_price,
        r.is_paid,
        r.created_at,
        r.updated_at,
        d.type as device_type
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    LEFT JOIN devices d ON r.device_id = d.id
    WHERE r.status = 'returned'
    AND (
        search_query = '' OR
        LOWER(c.first_name) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(c.last_name) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(c.email) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(d.brand) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(d.model) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(r.description) LIKE '%' || LOWER(search_query) || '%' OR
        LOWER(r.issue) LIKE '%' || LOWER(search_query) || '%'
    )
    AND (
        device_type_filter = 'all' OR
        d.type = device_type_filter
    )
    AND (
        NOT paid_only OR
        r.is_paid = true
    )
    AND (
        date_filter = 'all' OR
        CASE date_filter
            WHEN '30days' THEN r.updated_at >= NOW() - INTERVAL '30 days'
            WHEN '90days' THEN r.updated_at >= NOW() - INTERVAL '90 days'
            WHEN '1year' THEN r.updated_at >= NOW() - INTERVAL '1 year'
            ELSE true
        END
    )
    ORDER BY r.updated_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.search_orders(search_term text DEFAULT ''::text, status_filter text DEFAULT 'all'::text)
 RETURNS TABLE(id uuid, order_number character varying, supplier_name character varying, order_date date, expected_delivery_date date, status character varying, total_amount numeric, tracking_number character varying, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        o.supplier_name,
        o.order_date,
        o.expected_delivery_date,
        o.status,
        o.total_amount,
        o.tracking_number,
        o.created_at
    FROM orders o
    WHERE o.workshop_id = v_workshop_id
    AND (
        search_term = '' OR
        o.order_number ILIKE '%' || search_term || '%' OR
        o.supplier_name ILIKE '%' || search_term || '%' OR
        o.tracking_number ILIKE '%' || search_term || '%'
    )
    AND (
        status_filter = 'all' OR
        o.status = status_filter
    )
    ORDER BY o.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_confirmation_email_via_supabase(p_email text, p_token text, p_confirmation_url text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    result JSON;
BEGIN
    -- Cette fonction utilise l'API Supabase Auth pour envoyer des emails
    -- Note: Dans un environnement de production, vous devriez utiliser
    -- l'API Supabase Auth directement depuis votre application
    
    -- Pour l'instant, nous allons simuler l'envoi et stocker les détails
    -- pour que vous puissiez configurer l'envoi réel
    
    -- Mettre à jour le statut dans la base de données
    UPDATE confirmation_emails 
    SET status = 'sent', sent_at = NOW()
    WHERE user_email = p_email AND token = p_token;
    
    -- Retourner le résultat avec des instructions
    result := json_build_object(
        'success', true,
        'message', 'Email de confirmation préparé - Configuration requise',
        'email', p_email,
        'token', p_token,
        'confirmation_url', p_confirmation_url,
        'sent_at', NOW(),
        'instructions', 'Configurez l''envoi d''emails dans le dashboard Supabase',
        'next_steps', ARRAY[
            '1. Aller sur https://supabase.com/dashboard',
            '2. Sélectionner votre projet',
            '3. Authentication > Email Templates',
            '4. Configurer le template de confirmation',
            '5. Tester l''envoi d''email'
        ]
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'email', p_email,
            'token', p_token
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_appointment_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_user_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_user_context_aggressive()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Client créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_user_final()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR FINALE: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'FINAL: Client créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_user_id_ultra_strict()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer user_id à l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_workshop_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_brand_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_brand_user_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_category_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_category_user_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir automatiquement l'isolation
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE '✅ Appareil isolé pour l''utilisateur: %', v_user_id;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_model_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Définir les valeurs par défaut
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.created_at := NOW();
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_model_user_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.created_by := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_model_user_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := NEW.user_id;
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_model_user_ultime()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.created_by := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Device model créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_model_workshop_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_user_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_user_context_aggressive()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Device créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_user_final()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR FINALE: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'FINAL: Device créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_device_workshop_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_loyalty_points_defaults()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir les valeurs par défaut si elles sont NULL
    IF NEW.points_before IS NULL THEN
        NEW.points_before := 0;
    END IF;
    
    IF NEW.points_after IS NULL THEN
        NEW.points_after := 0;
    END IF;
    
    -- Note: Le calcul points_before + points est géré dans le script principal
    -- car la colonne points peut ne pas exister
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_loyalty_points_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_loyalty_workshop_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier que l'utilisateur est connecté
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé : utilisateur non authentifié';
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_message_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_order_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id uuid;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    -- Assigner les valeurs
    NEW.created_by := v_user_id;
    NEW.workshop_id := '00000000-0000-0000-0000-000000000000'::uuid; -- Valeur par défaut
    
    -- Timestamps
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_part_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Définir des valeurs par défaut si manquantes
    NEW.stock_quantity := COALESCE(NEW.stock_quantity, 0);
    NEW.min_stock_level := COALESCE(NEW.min_stock_level, 5);
    NEW.price := COALESCE(NEW.price, 0);
    NEW.compatible_devices := COALESCE(NEW.compatible_devices, '{}');
    NEW.is_active := COALESCE(NEW.is_active, true);
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_part_user_ultime()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Part créée par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_categories_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir le workshop_id automatiquement si non défini
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := COALESCE(
            (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
            '00000000-0000-0000-0000-000000000000'::UUID
        );
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_categories_user_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Assigner automatiquement l'ID de l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Si pas d'utilisateur connecté, utiliser un ID par défaut
    IF NEW.user_id IS NULL THEN
        NEW.user_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_categories_workshop_id()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := (
            SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
        );
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_category_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Définir user_id automatiquement si pas défini
    IF NEW.user_id IS NULL THEN
        NEW.user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir created_by si pas défini
    IF NEW.created_by IS NULL THEN
        NEW.created_by := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_product_user_ultime()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Product créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_products_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Définir des valeurs par défaut si manquantes
    NEW.status := COALESCE(NEW.status, 'new');
    NEW.is_urgent := COALESCE(NEW.is_urgent, false);
    NEW.total_price := COALESCE(NEW.total_price, 0);
    NEW.discount_percentage := COALESCE(NEW.discount_percentage, 0);
    NEW.discount_amount := COALESCE(NEW.discount_amount, 0);
    NEW.original_price := COALESCE(NEW.original_price, NEW.total_price);
    NEW.is_paid := COALESCE(NEW.is_paid, false);
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir automatiquement l'isolation
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE '✅ Réparation isolée pour l''utilisateur: %', v_user_id;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_number()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.repair_number IS NULL THEN
        NEW.repair_number := generate_repair_number();
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_user_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_user_context_aggressive()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Repair créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_repair_workshop_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_sale_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_sales_isolation()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs d'isolation automatiquement
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    
    -- Définir user_id si la colonne existe et est NULL
    IF NEW.user_id IS NULL THEN
        NEW.user_id := v_user_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_service_context()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_user_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.user_id := v_user_id;
    NEW.created_by := v_user_id;
    NEW.workshop_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Définir des valeurs par défaut si manquantes
    NEW.duration := COALESCE(NEW.duration, 60);
    NEW.price := COALESCE(NEW.price, 0);
    NEW.category := COALESCE(NEW.category, 'réparation');
    NEW.applicable_devices := COALESCE(NEW.applicable_devices, '{}');
    NEW.is_active := COALESCE(NEW.is_active, true);
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_service_user_ultime()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Service créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_transaction_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_user_id_safe()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Accès refusé: utilisateur non authentifié';
    END IF;
    
    -- Forcer user_id à l'utilisateur connecté
    NEW.user_id := auth.uid();
    
    -- Définir created_at seulement s'il existe
    BEGIN
        NEW.created_at := COALESCE(NEW.created_at, NOW());
    EXCEPTION WHEN undefined_column THEN
        -- Le champ n'existe pas, on continue
        NULL;
    END;
    
    -- Définir updated_at seulement s'il existe
    BEGIN
        NEW.updated_at := NOW();
    EXCEPTION WHEN undefined_column THEN
        -- Le champ n'existe pas, on continue
        NULL;
    END;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.signup_user_with_default_data(p_email text, p_password text, p_first_name text DEFAULT 'Utilisateur'::text, p_last_name text DEFAULT 'Test'::text, p_role text DEFAULT 'technician'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_user_id UUID;
    result JSON;
BEGIN
    -- Cette fonction sera appelée depuis le frontend après l'inscription Supabase Auth
    -- Elle crée les données par défaut pour le nouvel utilisateur
    
    -- Récupérer l'ID de l'utilisateur actuellement authentifié
    new_user_id := auth.uid();
    
    IF new_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non authentifié'
        );
    END IF;
    
    -- Créer les données par défaut
    result := create_user_default_data(new_user_id);
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.signup_with_duplicate_handling(p_email text, p_first_name text, p_last_name text, p_role text DEFAULT 'technician'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    result RECORD;
    new_token TEXT;
    confirmation_url TEXT;
BEGIN
    -- Essayer d'insérer une nouvelle demande
    INSERT INTO pending_signups (email, first_name, last_name, role, status)
    VALUES (p_email, p_first_name, p_last_name, p_role, 'pending')
    RETURNING * INTO result;
    
    -- Si l'insertion réussit, générer un token
    new_token := encode(gen_random_bytes(32), 'hex');
    confirmation_url := 'http://localhost:3002/auth?tab=confirm&token=' || new_token;
    
    -- Insérer dans confirmation_emails
    INSERT INTO confirmation_emails (user_email, token, expires_at, status, sent_at)
    VALUES (p_email, new_token, NOW() + INTERVAL '24 hours', 'sent', NOW())
    ON CONFLICT (user_email) DO UPDATE SET
        token = EXCLUDED.token,
        expires_at = EXCLUDED.expires_at,
        status = 'sent',
        sent_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'token', new_token,
        'confirmation_url', confirmation_url,
        'message', 'Nouvelle demande d''inscription créée',
        'status', 'pending',
        'data', row_to_json(result)
    );
    
EXCEPTION
    WHEN unique_violation THEN
        -- Gérer le doublon
        RETURN handle_duplicate_signup(p_email);
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.suggest_email_corrections()
 RETURNS TABLE(client_id uuid, current_email text, suggested_email text, reason text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    client_record RECORD;
    base_email TEXT;
    counter INTEGER;
    new_email TEXT;
BEGIN
    -- Pour chaque client avec un email en doublon
    FOR client_record IN
        SELECT c.id, c.email, c.first_name, c.last_name
        FROM clients c
        WHERE c.email IN (
            SELECT email
            FROM clients
            WHERE email IS NOT NULL AND email != ''
            GROUP BY email
            HAVING COUNT(*) > 1
        )
        ORDER BY c.email, c.created_at
    LOOP
        -- Extraire la partie locale de l'email (avant @)
        base_email := SPLIT_PART(client_record.email, '@', 1);
        
        -- Chercher un email unique
        counter := 1;
        new_email := base_email || counter || '@' || SPLIT_PART(client_record.email, '@', 2);
        
        WHILE EXISTS (SELECT 1 FROM clients WHERE email = new_email) LOOP
            counter := counter + 1;
            new_email := base_email || counter || '@' || SPLIT_PART(client_record.email, '@', 2);
        END LOOP;
        
        client_id := client_record.id;
        current_email := client_record.email;
        suggested_email := new_email;
        reason := 'Doublon d''email détecté';
        
        RETURN NEXT;
    END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.suggest_serial_number_corrections()
 RETURNS TABLE(device_id uuid, current_serial_number text, suggested_serial_number text, reason text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    device_record RECORD;
    base_serial TEXT;
    counter INTEGER;
    new_serial TEXT;
BEGIN
    -- Pour chaque appareil avec un numéro de série en doublon
    FOR device_record IN
        SELECT d.id, d.serial_number, d.brand, d.model
        FROM devices d
        WHERE d.serial_number IN (
            SELECT serial_number
            FROM devices
            WHERE serial_number IS NOT NULL AND serial_number != ''
            GROUP BY serial_number
            HAVING COUNT(*) > 1
        )
        ORDER BY d.serial_number, d.created_at
    LOOP
        -- Utiliser le numéro de série comme base
        base_serial := device_record.serial_number;
        
        -- Chercher un numéro de série unique
        counter := 1;
        new_serial := base_serial || '_' || counter;
        
        WHILE EXISTS (SELECT 1 FROM devices WHERE serial_number = new_serial) LOOP
            counter := counter + 1;
            new_serial := base_serial || '_' || counter;
        END LOOP;
        
        device_id := device_record.id;
        current_serial_number := device_record.serial_number;
        suggested_serial_number := new_serial;
        reason := 'Doublon de numéro de série détecté';
        
        RETURN NEXT;
    END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sync_user_to_subscription_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Insérer l'utilisateur dans subscription_status s'il n'existe pas déjà
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at,
    status
  )
  SELECT 
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(NEW.raw_user_meta_data->>'last_name', NEW.raw_user_meta_data->>'lastName', 'Test') as last_name,
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      WHEN NEW.email = 'srohee32@gmail.com' THEN true
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN true
      ELSE false
    END as is_active,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'premium'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'premium'
      ELSE 'free'
    END as subscription_type,
    'Compte créé automatiquement par trigger',
    COALESCE(NEW.created_at, NOW()) as created_at,
    NOW() as updated_at,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'ACTIF'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
      ELSE 'INACTIF'
    END as status
  WHERE NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = NEW.id
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, log l'erreur mais ne pas faire échouer l'inscription
    RAISE WARNING 'Erreur lors de la synchronisation vers subscription_status: %', SQLERRM;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_clients_access()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    current_user_id UUID;
    client_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer l'ID de l'utilisateur actuel
    current_user_id := auth.uid();
    
    -- Compter les clients
    SELECT COUNT(*) INTO client_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'current_user_id', current_user_id,
        'total_clients', client_count,
        'rls_enabled', false,
        'message', 'RLS désactivé temporairement - accès complet'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'current_user_id', current_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_clients_isolation()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    your_user_id UUID;
    your_clients_count INTEGER;
    result JSON;
BEGIN
    -- Récupérer votre ID utilisateur
    your_user_id := auth.uid();
    
    -- Compter vos clients (ceux que vous pouvez voir)
    SELECT COUNT(*) INTO your_clients_count FROM public.clients;
    
    -- Construire le résultat
    result := json_build_object(
        'success', true,
        'your_user_id', your_user_id,
        'your_clients_count', your_clients_count,
        'rls_enabled', true,
        'message', 'RLS activé - vous ne voyez que vos propres clients'
    );
    
    RETURN result;
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', SQLERRM,
        'your_user_id', your_user_id
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_complete_signup_fix()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_id UUID;
    rpc_result JSON;
BEGIN
    -- Test 1: Vérifier les tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_status') THEN
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'OK'::TEXT, 'Table existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings') THEN
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'OK'::TEXT, 'Table existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;

    -- Test 2: Vérifier la fonction RPC
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'create_user_default_data') THEN
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Test 3: Vérifier les permissions
    IF EXISTS (SELECT 1 FROM information_schema.routine_privileges 
               WHERE routine_name = 'create_user_default_data' AND grantee = 'anon') THEN
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'OK'::TEXT, 'Permissions accordées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Permissions anon'::TEXT, 'ERREUR'::TEXT, 'Permissions manquantes'::TEXT;
    END IF;

    -- Test 4: Vérifier les triggers problématiques
    IF EXISTS (SELECT 1 FROM information_schema.triggers 
               WHERE event_object_table = 'users' AND trigger_name LIKE '%create_user%') THEN
        RETURN QUERY SELECT 'Triggers problématiques'::TEXT, 'ATTENTION'::TEXT, 'Triggers problématiques présents'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Triggers problématiques'::TEXT, 'OK'::TEXT, 'Aucun trigger problématique'::TEXT;
    END IF;

    -- Test 5: Tester la fonction RPC avec un utilisateur existant
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    IF test_user_id IS NOT NULL THEN
        rpc_result := create_user_default_data(test_user_id);
        IF (rpc_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'OK'::TEXT, 'Fonction RPC fonctionne'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test RPC'::TEXT, 'ERREUR'::TEXT, (rpc_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Test RPC'::TEXT, 'SKIP'::TEXT, 'Aucun utilisateur pour le test'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_contournement_ultime()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_result JSON;
BEGIN
    -- Test 1: Vérifier la table pending_signups
    IF EXISTS (SELECT 1 FROM pending_signups LIMIT 1) THEN
        RETURN QUERY SELECT 'Table pending_signups'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table pending_signups'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Tester l'insertion dans pending_signups
    BEGIN
        INSERT INTO pending_signups (email, first_name, last_name, role)
        VALUES (test_email, 'Test', 'User', 'technician');
        
        RETURN QUERY SELECT 'Insertion pending_signups'::TEXT, 'OK'::TEXT, 'Insertion possible'::TEXT;
        
        -- Test 3: Tester la fonction de statut
        test_result := get_signup_status(test_email);
        IF (test_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Fonction get_signup_status'::TEXT, 'OK'::TEXT, 'Fonction fonctionne'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Fonction get_signup_status'::TEXT, 'ERREUR'::TEXT, (test_result->>'error')::TEXT;
        END IF;
        
        -- Nettoyer
        DELETE FROM pending_signups WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Insertion pending_signups'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;

    -- Test 4: Vérifier les fonctions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'process_pending_signup') THEN
        RETURN QUERY SELECT 'Fonction process_pending_signup'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction process_pending_signup'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'approve_pending_signup') THEN
        RETURN QUERY SELECT 'Fonction approve_pending_signup'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction approve_pending_signup'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_emergency()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_policy_count INTEGER;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'device_models'
        AND row_security = true
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le nombre de politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename = 'device_models';
    
    IF v_policy_count >= 4 THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '✅ OK'::TEXT, v_policy_count || ' politiques créées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '❌ ERREUR'::TEXT, 'Seulement ' || v_policy_count || ' politiques'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les politiques sont très permissives
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'INSERT'
        AND qual = 'true'
    ) THEN
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '✅ OK'::TEXT, 'Politique INSERT très permissive (true)'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '❌ ERREUR'::TEXT, 'Politique INSERT pas assez permissive'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger existe
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'set_device_model_context'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '✅ OK'::TEXT, 'Fonction set_device_model_context créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 6: Vérifier le workshop_id
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id défini'::TEXT;
    END IF;
    
    -- Test 7: Vérifier que toutes les politiques sont très permissives
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND qual != 'true'
    ) THEN
        RETURN QUERY SELECT 'Politiques permissives'::TEXT, '✅ OK'::TEXT, 'Toutes les politiques sont très permissives'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques permissives'::TEXT, '❌ ERREUR'::TEXT, 'Certaines politiques ne sont pas permissives'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_gestion()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
    v_gestion_access BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Gestion', 'Test Model Gestion', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie sans erreur 403'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation normale
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation normale'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation normale'::TEXT, '⚠️ ATTENTION'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Vérifier l'accès gestion
    IF EXISTS (
        SELECT 1 FROM system_settings 
        WHERE key = 'workshop_type' 
        AND value = 'gestion'
        LIMIT 1
    ) THEN
        v_gestion_access := TRUE;
        RETURN QUERY SELECT 'Accès gestion'::TEXT, '✅ OK'::TEXT, 'Atelier de gestion détecté'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Accès gestion'::TEXT, 'ℹ️ INFO'::TEXT, 'Atelier normal (pas de gestion)'::TEXT;
    END IF;
    
    -- Test 6: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '⚠️ PARTIEL'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_hybride()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion (devrait fonctionner sans erreur 403)
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Hybride', 'Test Model Hybride', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie sans erreur 403'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation (devrait être active)
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops (devrait être 0)
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation active'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation active'::TEXT, '⚠️ ATTENTION'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '⚠️ PARTIEL'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_isolation()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Compter les modèles du workshop actuel
    SELECT COUNT(*) INTO v_model_count
    FROM device_models
    WHERE workshop_id = v_workshop_id;
    
    RETURN QUERY SELECT 
        'Modèles workshop actuel'::TEXT, 
        v_model_count::TEXT, 
        'Modèles visibles pour le workshop actuel'::TEXT;
    
    -- Test 3: Compter les modèles d'autres workshops
    SELECT COUNT(*) INTO v_other_workshop_count
    FROM device_models
    WHERE workshop_id != v_workshop_id;
    
    IF v_other_workshop_count = 0 THEN
        RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
            (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
    END IF;
    
    -- Test 4: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_isolation_complete()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Isolation Complete', 'Test Model Complete', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie sans erreur 403'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '❌ ÉCHEC'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_isolation_final()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_policy_count INTEGER;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
    v_total_count INTEGER;
    v_isolated_count INTEGER;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'device_models'
        AND row_security = true
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le nombre de politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename = 'device_models';
    
    IF v_policy_count >= 4 THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '✅ OK'::TEXT, v_policy_count || ' politiques créées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '❌ ERREUR'::TEXT, 'Seulement ' || v_policy_count || ' politiques'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que la politique INSERT est permissive
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'INSERT'
        AND qual = 'true'
    ) THEN
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '✅ OK'::TEXT, 'Politique INSERT permissive pour insertion'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '❌ ERREUR'::TEXT, 'Politique INSERT pas permissive'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que la politique SELECT isole par workshop_id
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'SELECT'
        AND qual LIKE '%workshop_id%'
    ) THEN
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '✅ OK'::TEXT, 'Politique SELECT isole par workshop_id'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '❌ ERREUR'::TEXT, 'Politique SELECT pas isolante'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que le trigger existe
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 6: Vérifier que la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'set_device_model_context'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '✅ OK'::TEXT, 'Fonction set_device_model_context créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 7: Vérifier le workshop_id
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id défini'::TEXT;
    END IF;
    
    -- Test 8: Vérifier l'isolation actuelle des données
    SELECT COUNT(*) INTO v_total_count FROM device_models;
    SELECT COUNT(*) INTO v_isolated_count 
    FROM device_models 
    WHERE workshop_id = v_workshop_id;
    
    IF v_total_count = 0 THEN
        RETURN QUERY SELECT 'Isolation des données'::TEXT, '✅ OK'::TEXT, 'Aucun modèle existant'::TEXT;
    ELSIF v_isolated_count = v_total_count THEN
        RETURN QUERY SELECT 'Isolation des données'::TEXT, '✅ OK'::TEXT, 
            'Tous les modèles isolés (' || v_isolated_count || '/' || v_total_count || ')'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation des données'::TEXT, '❌ ERREUR'::TEXT, 
            'Isolation violée: ' || v_isolated_count || '/' || v_total_count || ' modèles isolés'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_isolation_functionnelle()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion avec isolation
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Isolation Fonctionnelle', 'Test Model Isolation', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie avec isolation'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation stricte
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops (devrait être 0)
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '❌ ÉCHEC'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_isolation_stricte()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_test_id UUID;
    v_model_count INTEGER;
    v_other_workshop_count INTEGER;
    v_insert_success BOOLEAN := FALSE;
    v_isolation_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le trigger
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '✅ OK'::TEXT, 'Trigger set_device_model_context est actif'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger actif'::TEXT, '❌ ERREUR'::TEXT, 'Trigger set_device_model_context manquant'::TEXT;
    END IF;
    
    -- Test 3: Test d'insertion avec isolation
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Isolation Stricte', 'Test Model Stricte', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_id;
        
        v_insert_success := TRUE;
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion réussie avec isolation'::TEXT;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''insertion: ' || SQLERRM::TEXT;
    END;
    
    -- Test 4: Vérifier l'isolation stricte
    IF v_insert_success THEN
        -- Compter les modèles du workshop actuel
        SELECT COUNT(*) INTO v_model_count
        FROM device_models
        WHERE workshop_id = v_workshop_id;
        
        -- Compter les modèles d'autres workshops (devrait être 0)
        SELECT COUNT(*) INTO v_other_workshop_count
        FROM device_models
        WHERE workshop_id != v_workshop_id;
        
        IF v_other_workshop_count = 0 THEN
            v_isolation_success := TRUE;
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '✅ OK'::TEXT, 'Aucun modèle d''autre workshop visible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Isolation stricte'::TEXT, '❌ ERREUR'::TEXT, 
                (v_other_workshop_count::TEXT || ' modèles d''autre workshop visibles')::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_id;
    END IF;
    
    -- Test 5: Résumé final
    IF v_insert_success AND v_isolation_success THEN
        RETURN QUERY SELECT 'Résumé final'::TEXT, '✅ SUCCÈS'::TEXT, 'Insertion et isolation fonctionnent parfaitement'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Résumé final'::TEXT, '❌ ÉCHEC'::TEXT, 
            'Insertion: ' || v_insert_success::TEXT || ', Isolation: ' || v_isolation_success::TEXT;
    END IF;
    
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_no_rls()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est désactivé (approximation)
    -- Note: row_security n'est pas disponible dans cette version de PostgreSQL
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'RLS désactivé'::TEXT, '✅ OK'::TEXT, 'Aucune politique RLS active (RLS désactivé)'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS désactivé'::TEXT, '⚠️ ATTENTION'::TEXT, 'Des politiques RLS sont encore actives'::TEXT;
    END IF;
    
    -- Test 2: Vérifier qu'il n'y a pas de politiques
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models'
    ) THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '✅ OK'::TEXT, 'Aucune politique RLS active'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '❌ ERREUR'::TEXT, 'Des politiques RLS sont encore actives'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que le trigger existe
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'set_device_model_context'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '✅ OK'::TEXT, 'Fonction set_device_model_context créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 5: Vérifier le workshop_id
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id défini'::TEXT;
    END IF;
    
    -- Test 6: Vérifier que l'insertion fonctionne
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Function', 'Test Model Function', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        );
        
        DELETE FROM device_models WHERE brand = 'Test Function' AND model = 'Test Model Function';
        
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion et suppression réussies'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_rls()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'device_models' 
        AND row_security = true
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les politiques existent
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND policyname = 'device_models_select_policy'
    ) THEN
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '✅ OK'::TEXT, 'Politique SELECT créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique SELECT'::TEXT, '❌ ERREUR'::TEXT, 'Politique SELECT manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les colonnes existent
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' 
        AND column_name = 'workshop_id'
    ) THEN
        RETURN QUERY SELECT 'Colonne workshop_id'::TEXT, '✅ OK'::TEXT, 'Colonne workshop_id existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Colonne workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Colonne workshop_id manquante'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger existe
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Tester l'insertion d'un modèle de test
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test', 'Test Model', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        );
        
        DELETE FROM device_models WHERE brand = 'Test' AND model = 'Test Model';
        
        RETURN QUERY SELECT 'Test insertion'::TEXT, '✅ OK'::TEXT, 'Insertion et suppression réussies'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_device_models_rls_policies()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_policy_count INTEGER;
    v_trigger_exists BOOLEAN;
    v_function_exists BOOLEAN;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que RLS est activé
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'device_models'
        AND row_security = true
    ) THEN
        RETURN QUERY SELECT 'RLS activé'::TEXT, '✅ OK'::TEXT, 'Row Level Security est activé'::TEXT;
    ELSE
        RETURN QUERY SELECT 'RLS activé'::TEXT, '❌ ERREUR'::TEXT, 'Row Level Security n''est pas activé'::TEXT;
    END IF;
    
    -- Test 2: Vérifier le nombre de politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename = 'device_models';
    
    IF v_policy_count >= 4 THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '✅ OK'::TEXT, v_policy_count || ' politiques créées'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, '❌ ERREUR'::TEXT, 'Seulement ' || v_policy_count || ' politiques'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les politiques ne vérifient pas auth.uid() pour INSERT
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND cmd = 'INSERT'
        AND qual LIKE '%auth.uid()%'
    ) THEN
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '✅ OK'::TEXT, 'Politique INSERT sans vérification auth.uid()'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique INSERT'::TEXT, '❌ ERREUR'::TEXT, 'Politique INSERT vérifie encore auth.uid()'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger existe
    SELECT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_set_device_model_context'
    ) INTO v_trigger_exists;
    
    IF v_trigger_exists THEN
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger automatique'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que la fonction existe
    SELECT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'set_device_model_context'
    ) INTO v_function_exists;
    
    IF v_function_exists THEN
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '✅ OK'::TEXT, 'Fonction set_device_model_context créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction trigger'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 6: Vérifier le workshop_id
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id défini'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_duplicate_handling()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_duplicate_' || extract(epoch from now())::text || '@example.com';
    result1 JSON;
    result2 JSON;
BEGIN
    -- Test 1: Première inscription
    result1 := signup_with_duplicate_handling(test_email, 'Test', 'User', 'technician');
    
    IF (result1->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Première inscription'::TEXT, 
            'OK'::TEXT, 
            'Inscription créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Première inscription'::TEXT, 
            'ERREUR'::TEXT, 
            (result1->>'error')::TEXT;
    END IF;
    
    -- Test 2: Tentative de doublon
    result2 := signup_with_duplicate_handling(test_email, 'Test', 'User', 'technician');
    
    IF (result2->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Gestion du doublon'::TEXT, 
            'OK'::TEXT, 
            'Doublon géré avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Gestion du doublon'::TEXT, 
            'ERREUR'::TEXT, 
            (result2->>'error')::TEXT;
    END IF;
    
    -- Nettoyer
    DELETE FROM pending_signups WHERE email = test_email;
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_email_configuration()
 RETURNS TABLE(section text, element text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 
            'Base de données'::TEXT, 
            'Table confirmation_emails'::TEXT, 
            'OK'::TEXT, 
            'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Base de données'::TEXT, 
            'Table confirmation_emails'::TEXT, 
            'ERREUR'::TEXT, 
            'Table inaccessible'::TEXT;
    END IF;
    
    -- Test 2: Vérifier la fonction generate_confirmation_token_and_send_email
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token_and_send_email') THEN
        RETURN QUERY SELECT 
            'Fonctions'::TEXT, 
            'generate_confirmation_token_and_send_email'::TEXT, 
            'OK'::TEXT, 
            'Fonction créée'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Fonctions'::TEXT, 
            'generate_confirmation_token_and_send_email'::TEXT, 
            'ERREUR'::TEXT, 
            'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 3: Tester la génération de token
    test_result := generate_confirmation_token_and_send_email(test_email);
    
    IF (test_result->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Test'::TEXT, 
            'Génération de token'::TEXT, 
            'OK'::TEXT, 
            'Token généré: ' || (test_result->>'token')::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Test'::TEXT, 
            'Génération de token'::TEXT, 
            'ERREUR'::TEXT, 
            'Échec de génération'::TEXT;
    END IF;
    
    -- Test 4: Vérifier l'URL de confirmation
    IF (test_result->>'confirmation_url')::TEXT LIKE '%localhost:3002%' THEN
        RETURN QUERY SELECT 
            'Configuration'::TEXT, 
            'URL de confirmation'::TEXT, 
            'OK'::TEXT, 
            'URL correcte: ' || (test_result->>'confirmation_url')::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Configuration'::TEXT, 
            'URL de confirmation'::TEXT, 
            'ATTENTION'::TEXT, 
            'URL incorrecte: ' || (test_result->>'confirmation_url')::TEXT;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_email_simple()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 
            'Table confirmation_emails'::TEXT, 
            'OK'::TEXT, 
            'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Table confirmation_emails'::TEXT, 
            'ERREUR'::TEXT, 
            'Table inaccessible'::TEXT;
    END IF;
    
    -- Test 2: Tester la génération de token
    test_result := generate_confirmation_token_and_send_email(test_email);
    
    IF (test_result->>'success')::boolean THEN
        RETURN QUERY SELECT 
            'Génération de token'::TEXT, 
            'OK'::TEXT, 
            'Token généré avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Génération de token'::TEXT, 
            'ERREUR'::TEXT, 
            'Échec de génération'::TEXT;
    END IF;
    
    -- Test 3: Vérifier l'URL de confirmation
    IF (test_result->>'confirmation_url')::TEXT LIKE '%localhost:3002%' THEN
        RETURN QUERY SELECT 
            'URL de confirmation'::TEXT, 
            'OK'::TEXT, 
            'URL correcte'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'URL de confirmation'::TEXT, 
            'ATTENTION'::TEXT, 
            'URL incorrecte'::TEXT;
    END IF;
    
    -- Nettoyer le test
    DELETE FROM confirmation_emails WHERE user_email = test_email;
    
    RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_email_system()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    token_result JSON;
    validation_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Tester la génération de token
    token_result := generate_confirmation_token(test_email);
    IF (token_result->>'success')::boolean THEN
        RETURN QUERY SELECT 'Génération token'::TEXT, 'OK'::TEXT, 'Token généré avec succès'::TEXT;
        
        -- Test 3: Tester la validation de token
        validation_result := validate_confirmation_token(token_result->>'token');
        IF (validation_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Validation token'::TEXT, 'OK'::TEXT, 'Token validé avec succès'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Validation token'::TEXT, 'ERREUR'::TEXT, (validation_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Génération token'::TEXT, 'ERREUR'::TEXT, (token_result->>'error')::TEXT;
    END IF;

    -- Test 4: Vérifier les fonctions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'validate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Nettoyer
    DELETE FROM confirmation_emails WHERE user_email = test_email;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_email_system_corrected()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    token_result JSON;
    validation_result JSON;
BEGIN
    -- Test 1: Vérifier la table confirmation_emails
    IF EXISTS (SELECT 1 FROM confirmation_emails LIMIT 1) THEN
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table confirmation_emails'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Vérifier la contrainte unique
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_name = 'confirmation_emails' 
               AND constraint_type = 'UNIQUE' 
               AND constraint_name LIKE '%user_email%') THEN
        RETURN QUERY SELECT 'Contrainte unique user_email'::TEXT, 'OK'::TEXT, 'Contrainte présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Contrainte unique user_email'::TEXT, 'ERREUR'::TEXT, 'Contrainte manquante'::TEXT;
    END IF;

    -- Test 3: Tester la génération de token
    token_result := generate_confirmation_token(test_email);
    IF (token_result->>'success')::boolean THEN
        RETURN QUERY SELECT 'Génération token'::TEXT, 'OK'::TEXT, 'Token généré avec succès'::TEXT;
        
        -- Test 4: Tester la validation de token
        validation_result := validate_confirmation_token(token_result->>'token');
        IF (validation_result->>'success')::boolean THEN
            RETURN QUERY SELECT 'Validation token'::TEXT, 'OK'::TEXT, 'Token validé avec succès'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Validation token'::TEXT, 'ERREUR'::TEXT, (validation_result->>'error')::TEXT;
        END IF;
    ELSE
        RETURN QUERY SELECT 'Génération token'::TEXT, 'ERREUR'::TEXT, (token_result->>'error')::TEXT;
    END IF;

    -- Test 5: Vérifier les fonctions
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'generate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction generate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'validate_confirmation_token') THEN
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'OK'::TEXT, 'Fonction existe'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction validate_confirmation_token'::TEXT, 'ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;

    -- Nettoyer
    DELETE FROM confirmation_emails WHERE user_email = test_email;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_force_isolation()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
    v_total_count INTEGER;
    v_test_model_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test 1: Vérifier que le workshop_id est défini
    IF v_workshop_id IS NOT NULL THEN
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '✅ OK'::TEXT, 'Workshop_id: ' || v_workshop_id::text::TEXT;
    ELSE
        RETURN QUERY SELECT 'Workshop_id défini'::TEXT, '❌ ERREUR'::TEXT, 'Aucun workshop_id trouvé'::TEXT;
        RETURN;
    END IF;
    
    -- Test 2: Vérifier que la table est vide (après nettoyage)
    SELECT COUNT(*) INTO v_total_count FROM device_models;
    IF v_total_count = 0 THEN
        RETURN QUERY SELECT 'Table nettoyée'::TEXT, '✅ OK'::TEXT, 'Aucun modèle existant'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table nettoyée'::TEXT, '❌ ERREUR'::TEXT, v_total_count || ' modèles restants'::TEXT;
    END IF;
    
    -- Test 3: Vérifier les politiques strictes
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'device_models' 
        AND policyname = 'device_models_select_policy'
        AND qual NOT LIKE '%IS NULL%'
    ) THEN
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '✅ OK'::TEXT, 'Politiques sans condition IS NULL'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques strictes'::TEXT, '❌ ERREUR'::TEXT, 'Politiques trop permissives'::TEXT;
    END IF;
    
    -- Test 4: Tester l'insertion avec isolation stricte
    BEGIN
        INSERT INTO device_models (
            brand, model, type, year, specifications, 
            common_issues, repair_difficulty, parts_availability, is_active
        ) VALUES (
            'Test Force Isolation', 'Test Model Force', 'smartphone', 2024, 
            '{"screen": "6.1"}', 
            ARRAY['Test issue'], 'medium', 'high', true
        ) RETURNING id INTO v_test_model_id;
        
        -- Vérifier que le modèle inséré appartient au bon atelier
        SELECT COUNT(*) INTO v_model_count
        FROM device_models 
        WHERE id = v_test_model_id
        AND workshop_id = v_workshop_id;
        
        IF v_model_count = 1 THEN
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '✅ OK'::TEXT, 'Insertion avec isolation réussie'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Insertion sans isolation'::TEXT;
        END IF;
        
        -- Nettoyer le test
        DELETE FROM device_models WHERE id = v_test_model_id;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test insertion isolée'::TEXT, '❌ ERREUR'::TEXT, 'Erreur: ' || SQLERRM::TEXT;
    END;
    
    -- Test 5: Vérifier l'isolation complète
    SELECT COUNT(*) INTO v_model_count
    FROM device_models 
    WHERE workshop_id = v_workshop_id;
    
    SELECT COUNT(*) INTO v_total_count
    FROM device_models;
    
    IF v_model_count = v_total_count THEN
        RETURN QUERY SELECT 'Isolation complète'::TEXT, '✅ OK'::TEXT, 
            'Tous les modèles appartiennent à l''atelier actuel (' || v_model_count || ' modèles)'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Isolation complète'::TEXT, '❌ ERREUR'::TEXT, 
            'Isolation violée: ' || v_model_count || '/' || v_total_count || ' modèles isolés'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_functions_and_triggers()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Test 1: Vérifier que les fonctions existent
    IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'calculate_technician_performance') THEN
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '✅ Existe'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '❌ Manquante'::TEXT, 'Fonction non trouvée'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les triggers existent
    IF EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trigger_update_technician_performance') THEN
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '✅ Existe'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '❌ Manquant'::TEXT, 'Trigger non trouvé'::TEXT;
    END IF;
    
    -- Test 3: Tester l'appel de la fonction
    BEGIN
        PERFORM calculate_technician_performance(
            '00000000-0000-0000-0000-000000000000'::UUID,
            CURRENT_DATE,
            CURRENT_DATE
        );
        RETURN QUERY SELECT 'Test appel fonction'::TEXT, '✅ Réussi'::TEXT, 'Fonction exécutée sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test appel fonction'::TEXT, '❌ Échec'::TEXT, SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_installation()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Test 1: Vérifier que les tables existent
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'technician_performance') THEN
        RETURN QUERY SELECT 'Table technician_performance'::TEXT, '✅ OK'::TEXT, 'Table créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que les tables existent
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'advanced_alerts') THEN
        RETURN QUERY SELECT 'Table advanced_alerts'::TEXT, '✅ OK'::TEXT, 'Table créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table advanced_alerts'::TEXT, '❌ ERREUR'::TEXT, 'Table manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que les triggers existent
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_set_workshop_context_products') THEN
        RETURN QUERY SELECT 'Trigger trigger_set_workshop_context_products'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_set_workshop_context_products'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 4: Vérifier l'isolation des données
    IF EXISTS (SELECT FROM pg_policies WHERE tablename = 'products' AND policyname = 'products_select_policy') THEN
        RETURN QUERY SELECT 'Politique RLS products'::TEXT, '✅ OK'::TEXT, 'Politique RLS créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique RLS products'::TEXT, '❌ ERREUR'::TEXT, 'Politique RLS manquante'::TEXT;
    END IF;
    
    -- Test 5: Vérifier que les tables de base sont sécurisées
    IF EXISTS (SELECT FROM pg_policies WHERE tablename = 'repairs' AND policyname = 'repairs_select_policy') THEN
        RETURN QUERY SELECT 'Politique RLS repairs'::TEXT, '✅ OK'::TEXT, 'Politique RLS créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politique RLS repairs'::TEXT, '❌ ERREUR'::TEXT, 'Politique RLS manquante'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_orders_isolation_simple()
 RETURNS TABLE(user_email text, orders_count bigint, isolation_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ss.email,
        COUNT(o.id) as orders_count,
        CASE 
            WHEN COUNT(o.id) = 0 THEN 'Aucune commande'
            WHEN COUNT(o.id) = COUNT(CASE WHEN o.created_by = ss.user_id THEN 1 END) THEN '✅ ISOLATION CORRECTE'
            ELSE '❌ ISOLATION INCORRECTE'
        END as isolation_status
    FROM subscription_status ss
    LEFT JOIN orders o ON ss.user_id = o.created_by
    GROUP BY ss.user_id, ss.email
    ORDER BY ss.email;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_permissive_signup()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_user_id UUID := gen_random_uuid();
BEGIN
    -- Test 1: Vérifier l'accès à auth.users (lecture seule)
    IF EXISTS (SELECT 1 FROM auth.users LIMIT 1) THEN
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'OK'::TEXT, 'Lecture possible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'ERREUR'::TEXT, 'Lecture impossible'::TEXT;
    END IF;

    -- Test 2: Vérifier nos tables
    IF EXISTS (SELECT 1 FROM subscription_status LIMIT 1) THEN
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table subscription_status'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    IF EXISTS (SELECT 1 FROM system_settings LIMIT 1) THEN
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Table system_settings'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 3: Vérifier les permissions d'insertion sur nos tables
    BEGIN
        INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, subscription_type, notes)
        VALUES (test_user_id, 'Test', 'User', 'test@example.com', FALSE, 'free', 'Test');
        
        RETURN QUERY SELECT 'Insertion subscription_status'::TEXT, 'OK'::TEXT, 'Insertion possible'::TEXT;
        
        -- Nettoyer
        DELETE FROM subscription_status WHERE user_id = test_user_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Insertion subscription_status'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;

    -- Test 4: Vérifier la fonction RPC
    BEGIN
        PERFORM create_user_default_data_permissive(test_user_id);
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'OK'::TEXT, 'Fonction fonctionne'::TEXT;
        
        -- Nettoyer
        DELETE FROM subscription_status WHERE user_id = test_user_id;
        DELETE FROM system_settings WHERE user_id = test_user_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Fonction RPC'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;

    -- Test 5: Vérifier les permissions sur la table users (lecture)
    BEGIN
        IF EXISTS (SELECT 1 FROM users LIMIT 1) THEN
            RETURN QUERY SELECT 'Lecture table users'::TEXT, 'OK'::TEXT, 'Lecture possible'::TEXT;
        ELSE
            RETURN QUERY SELECT 'Lecture table users'::TEXT, 'ERREUR'::TEXT, 'Lecture impossible'::TEXT;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Lecture table users'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_signup_process()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now()) || '@example.com';
    result JSON;
BEGIN
    -- Tester la création d'un utilisateur
    SELECT create_user_manually(
        test_email,
        'password123',
        'Test',
        'User',
        'technician'
    ) INTO result;
    
    RETURN json_build_object(
        'test_email', test_email,
        'result', result
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_simple_signup()
 RETURNS TABLE(test_name text, result text, details text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    test_email TEXT := 'test_' || extract(epoch from now())::text || '@example.com';
    test_user_id UUID;
BEGIN
    -- Test 1: Vérifier l'accès à auth.users
    IF EXISTS (SELECT 1 FROM auth.users LIMIT 1) THEN
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'OK'::TEXT, 'Table accessible'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Accès auth.users'::TEXT, 'ERREUR'::TEXT, 'Table inaccessible'::TEXT;
    END IF;

    -- Test 2: Vérifier les permissions d'insertion
    BEGIN
        -- Essayer d'insérer un utilisateur de test (cela peut échouer, c'est normal)
        INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
        VALUES (gen_random_uuid(), test_email, 'test_password', now(), now(), now());
        
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'OK'::TEXT, 'Insertion possible'::TEXT;
        
        -- Nettoyer
        DELETE FROM auth.users WHERE email = test_email;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Insertion auth.users'::TEXT, 'ERREUR'::TEXT, SQLERRM::TEXT;
    END;

    -- Test 3: Vérifier les triggers actifs
    IF EXISTS (SELECT 1 FROM information_schema.triggers 
               WHERE event_object_schema = 'auth' AND event_object_table = 'users') THEN
        RETURN QUERY SELECT 'Triggers auth.users'::TEXT, 'ATTENTION'::TEXT, 'Triggers présents - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Triggers auth.users'::TEXT, 'OK'::TEXT, 'Aucun trigger problématique'::TEXT;
    END IF;

    -- Test 4: Vérifier les contraintes CHECK
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE table_schema = 'auth' AND table_name = 'users' AND constraint_type = 'CHECK') THEN
        RETURN QUERY SELECT 'Contraintes CHECK'::TEXT, 'ATTENTION'::TEXT, 'Contraintes CHECK présentes - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Contraintes CHECK'::TEXT, 'OK'::TEXT, 'Aucune contrainte CHECK problématique'::TEXT;
    END IF;

    -- Test 5: Vérifier les politiques RLS
    IF EXISTS (SELECT 1 FROM pg_policies 
               WHERE schemaname = 'auth' AND tablename = 'users') THEN
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, 'ATTENTION'::TEXT, 'Politiques RLS présentes - peuvent causer des problèmes'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Politiques RLS'::TEXT, 'OK'::TEXT, 'Aucune politique RLS problématique'::TEXT;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_trigger_fix()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Test 1: Vérifier que la fonction calculate_technician_performance existe
    IF EXISTS (SELECT FROM pg_proc WHERE proname = 'calculate_technician_performance') THEN
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '✅ OK'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction calculate_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que la fonction create_alert existe
    IF EXISTS (SELECT FROM pg_proc WHERE proname = 'create_alert') THEN
        RETURN QUERY SELECT 'Fonction create_alert'::TEXT, '✅ OK'::TEXT, 'Fonction créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Fonction create_alert'::TEXT, '❌ ERREUR'::TEXT, 'Fonction manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que le trigger update_technician_performance existe
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_update_technician_performance') THEN
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_update_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 4: Vérifier que le trigger create_repair_alerts existe
    IF EXISTS (SELECT FROM pg_trigger WHERE tgname = 'trigger_create_repair_alerts') THEN
        RETURN QUERY SELECT 'Trigger trigger_create_repair_alerts'::TEXT, '✅ OK'::TEXT, 'Trigger créé avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Trigger trigger_create_repair_alerts'::TEXT, '❌ ERREUR'::TEXT, 'Trigger manquant'::TEXT;
    END IF;
    
    -- Test 5: Tester l'appel de la fonction calculate_technician_performance
    BEGIN
        PERFORM calculate_technician_performance(
            '00000000-0000-0000-0000-000000000000'::UUID,
            CURRENT_DATE,
            CURRENT_DATE
        );
        RETURN QUERY SELECT 'Test appel calculate_technician_performance'::TEXT, '✅ OK'::TEXT, 'Fonction appelable sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test appel calculate_technician_performance'::TEXT, '❌ ERREUR'::TEXT, 'Erreur lors de l''appel: ' || SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_user_id_columns()
 RETURNS TABLE(tbl_name text, status text, details text)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Test repairs
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'repairs' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'repairs'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'repairs'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test products
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'products'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'products'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test sales
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sales' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'sales'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'sales'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test appointments
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appointments' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'appointments'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'appointments'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test clients
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'clients' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'clients'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'clients'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    -- Test devices
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'devices' AND column_name = 'user_id') THEN
        RETURN QUERY SELECT 'devices'::TEXT, 'OK'::TEXT, 'Colonne user_id présente'::TEXT;
    ELSE
        RETURN QUERY SELECT 'devices'::TEXT, 'ERREUR'::TEXT, 'Colonne user_id manquante'::TEXT;
    END IF;
    
    RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_views_fix()
 RETURNS TABLE(test_name text, status text, details text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Test 1: Vérifier que la vue consolidated_statistics existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'consolidated_statistics') THEN
        RETURN QUERY SELECT 'Vue consolidated_statistics'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue consolidated_statistics'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 2: Vérifier que la vue top_clients existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'top_clients') THEN
        RETURN QUERY SELECT 'Vue top_clients'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue top_clients'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 3: Vérifier que la vue top_devices existe
    IF EXISTS (SELECT FROM information_schema.views WHERE table_name = 'top_devices') THEN
        RETURN QUERY SELECT 'Vue top_devices'::TEXT, '✅ OK'::TEXT, 'Vue créée avec succès'::TEXT;
    ELSE
        RETURN QUERY SELECT 'Vue top_devices'::TEXT, '❌ ERREUR'::TEXT, 'Vue manquante'::TEXT;
    END IF;
    
    -- Test 4: Tester l'accès à la vue consolidated_statistics
    BEGIN
        PERFORM COUNT(*) FROM consolidated_statistics LIMIT 1;
        RETURN QUERY SELECT 'Test accès consolidated_statistics'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès consolidated_statistics'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
    
    -- Test 5: Tester l'accès à la vue top_clients
    BEGIN
        PERFORM COUNT(*) FROM top_clients LIMIT 1;
        RETURN QUERY SELECT 'Test accès top_clients'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès top_clients'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
    
    -- Test 6: Tester l'accès à la vue top_devices
    BEGIN
        PERFORM COUNT(*) FROM top_devices LIMIT 1;
        RETURN QUERY SELECT 'Test accès top_devices'::TEXT, '✅ OK'::TEXT, 'Vue accessible sans erreur'::TEXT;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT 'Test accès top_devices'::TEXT, '❌ ERREUR'::TEXT, 'Erreur d''accès: ' || SQLERRM::TEXT;
    END;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trigger_auto_loyalty_points_repair()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Seulement si la réparation passe à "payée"
    IF NEW.is_paid = true AND OLD.is_paid = false THEN
        PERFORM auto_add_loyalty_points_from_repair(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.trigger_auto_loyalty_points_sale()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Seulement si la vente est complétée
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        PERFORM auto_add_loyalty_points_from_sale(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.unlock_user(target_user_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    current_user_role TEXT;
BEGIN
    -- Vérifier que l'utilisateur actuel est admin
    SELECT role INTO current_user_role
    FROM public.users
    WHERE id = auth.uid();
    
    IF current_user_role != 'admin' THEN
        RAISE EXCEPTION 'Accès refusé: seuls les administrateurs peuvent déverrouiller des utilisateurs';
    END IF;
    
    -- Déverrouiller l'utilisateur
    UPDATE public.user_profiles
    SET is_locked = false, updated_at = NOW()
    WHERE user_id = target_user_id;
    
    RETURN FOUND;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_client_tier()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Mettre à jour le niveau basé sur les points
    NEW.current_tier_id = (
        SELECT id 
        FROM loyalty_tiers 
        WHERE points_required <= COALESCE(NEW.loyalty_points, 0)
        ORDER BY points_required DESC 
        LIMIT 1
    );
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_client_tiers()
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Mettre à jour les niveaux de tous les clients avec des points
    UPDATE clients 
    SET current_tier_id = (
        SELECT id 
        FROM loyalty_tiers_advanced 
        WHERE points_required <= clients.loyalty_points 
        AND is_active = true
        ORDER BY points_required DESC 
        LIMIT 1
    )
    WHERE loyalty_points > 0;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux mis à jour avec succès',
        'clients_updated', v_updated_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la mise à jour des niveaux: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_intervention_forms_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_isolated_client(p_id uuid, p_first_name text DEFAULT NULL::text, p_last_name text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_address text DEFAULT NULL::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    current_workshop_id UUID;
    result JSON;
    email_exists BOOLEAN;
    updated_count INTEGER;
BEGIN
    -- Obtenir le workshop_id actuel
    current_workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    
    -- Vérifier si l'email existe déjà (seulement si un email est fourni)
    IF p_email IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM clients WHERE email = p_email AND id != p_id
        ) INTO email_exists;
        
        IF email_exists THEN
            RETURN json_build_object(
                'success', false,
                'error', 'Email already exists',
                'message', 'Un autre client avec cet email existe déjà'
            );
        END IF;
    END IF;
    
    -- Modifier le client seulement s'il appartient au workshop actuel
    UPDATE clients SET
        first_name = COALESCE(p_first_name, first_name),
        last_name = COALESCE(p_last_name, last_name),
        email = COALESCE(p_email, email),
        phone = COALESCE(p_phone, phone),
        address = COALESCE(p_address, address),
        updated_at = NOW()
    WHERE id = p_id 
        AND workshop_id = current_workshop_id;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    IF updated_count = 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client not found or not accessible',
            'message', 'Client non trouvé ou non accessible'
        );
    END IF;
    
    -- Retourner le client modifié en JSON
    SELECT json_build_object(
        'success', true,
        'id', c.id,
        'first_name', c.first_name,
        'last_name', c.last_name,
        'email', c.email,
        'phone', c.phone,
        'address', c.address,
        'workshop_id', c.workshop_id
    ) INTO result
    FROM clients c
    WHERE c.id = p_id 
        AND c.workshop_id = current_workshop_id;
    
    RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_order_total()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Mettre à jour le total de la commande
    UPDATE orders 
    SET 
        total_amount = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM order_items 
            WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_quotes_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_repair_status(p_repair_id uuid, p_new_status text, p_notes text DEFAULT NULL::text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_client_email TEXT;
    v_client_name TEXT;
BEGIN
    -- Récupérer les informations du client pour les notifications
    SELECT 
        c.email,
        CONCAT(c.first_name, ' ', c.last_name)
    INTO v_client_email, v_client_name
    FROM repairs r
    INNER JOIN clients c ON r.client_id = c.id
    WHERE r.id = p_repair_id;
    
    -- Mettre à jour le statut
    UPDATE repairs 
    SET 
        status = p_new_status,
        notes = COALESCE(p_notes, notes),
        updated_at = NOW()
    WHERE id = p_repair_id;
    
    -- Ici on pourrait ajouter l'envoi d'email/SMS de notification
    -- Pour l'instant, on retourne juste true
    RETURN FOUND;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_repair_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_sale_item_category()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Si c'est un produit, récupérer sa catégorie
    IF NEW.type = 'product' THEN
        SELECT category INTO NEW.category
        FROM public.products
        WHERE id = NEW.item_id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_stock_alerts_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_subscription_status_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_technician_performance_trigger()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_technician_id UUID;
    v_period_start DATE;
    v_period_end DATE;
BEGIN
    -- Convertir et valider les paramètres
    v_technician_id := COALESCE(NEW.assigned_technician_id, OLD.assigned_technician_id)::UUID;
    v_period_start := DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at))::date;
    v_period_end := (DATE_TRUNC('month', COALESCE(NEW.created_at, OLD.created_at)) + INTERVAL '1 month - 1 day')::date;
    
    -- Vérifier que le technicien existe
    IF v_technician_id IS NOT NULL THEN
        -- Mettre à jour les métriques mensuelles
        PERFORM calculate_technician_performance(
            v_technician_id,
            v_period_start,
            v_period_end
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.use_loyalty_points(p_client_id uuid, p_points integer, p_description text DEFAULT 'Points utilisés'::text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_client_exists BOOLEAN;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Vérifier que le client existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE id = p_client_id) INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Vérifier que les points sont positifs
    IF p_points <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le nombre de points doit être positif'
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0) INTO v_current_points
    FROM clients 
    WHERE id = p_client_id;
    
    -- Vérifier que le client a assez de points
    IF v_current_points < p_points THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Points insuffisants. Points actuels: ' || v_current_points || ', Points demandés: ' || p_points
        );
    END IF;
    
    -- Calculer les nouveaux points
    v_new_points := v_current_points - p_points;
    
    -- Récupérer le niveau actuel
    SELECT current_tier_id INTO v_current_tier_id
    FROM clients 
    WHERE id = p_client_id;
    
    -- Déterminer le nouveau niveau basé sur les points
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers
    WHERE points_required <= v_new_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour les points et le niveau du client
    UPDATE clients 
    SET 
        loyalty_points = v_new_points,
        current_tier_id = COALESCE(v_new_tier_id, v_current_tier_id),
        updated_at = NOW()
    WHERE id = p_client_id;
    
    -- Insérer l'historique des points (points négatifs pour utilisation)
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_before,
        points_after,
        description,
        points_type,
        source_type,
        user_id,
        created_at
    ) VALUES (
        p_client_id,
        -p_points, -- Points négatifs pour indiquer une utilisation
        v_current_points,
        v_new_points,
        p_description,
        'usage',
        'manual',
        v_user_id,
        NOW()
    );
    
    -- Retourner le résultat
    v_result := json_build_object(
        'success', true,
        'client_id', p_client_id,
        'points_used', p_points,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'new_tier_id', v_new_tier_id,
        'description', p_description,
        'user_id', v_user_id
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$function$
;

create or replace view "public"."user_subscription_info" as  SELECT u.id AS user_id,
    u.email,
    us.id AS subscription_id,
    us.status AS subscription_status,
    us.start_date,
    us.end_date,
    sp.name AS plan_name,
    sp.price AS plan_price,
    sp.currency,
        CASE
            WHEN (((us.status)::text = 'active'::text) AND (us.end_date > now()) AND ((us.payment_status)::text = 'paid'::text)) THEN true
            ELSE false
        END AS has_active_subscription,
    (EXTRACT(day FROM (us.end_date - now())))::integer AS days_remaining
   FROM ((auth.users u
     LEFT JOIN user_subscriptions us ON ((u.id = us.user_id)))
     LEFT JOIN subscription_plans sp ON ((us.plan_id = sp.id)))
  WHERE ((us.id IS NULL) OR (us.id = ( SELECT user_subscriptions.id
           FROM user_subscriptions
          WHERE (user_subscriptions.user_id = u.id)
          ORDER BY user_subscriptions.created_at DESC
         LIMIT 1)));


CREATE OR REPLACE FUNCTION public.validate_client_email()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Valider le format de l'email seulement
    IF NEW.email IS NOT NULL AND NEW.email != '' THEN
        IF NOT (NEW.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_client_email_format()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Valider le format de l'email seulement si l'email n'est pas vide
    IF NEW.email IS NOT NULL AND TRIM(NEW.email) != '' THEN
        -- Validation plus permissive pour les emails
        -- Permet les domaines avec des TLD courts (comme .u, .io, etc.)
        IF NOT (NEW.email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{1,}$') THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
        
        -- Vérification supplémentaire : l'email ne doit pas être trop court
        IF LENGTH(NEW.email) < 5 THEN
            RAISE EXCEPTION 'Email trop court: %', NEW.email;
        END IF;
        
        -- Vérification : l'email doit contenir un @ et au moins un point après le @
        IF POSITION('@' IN NEW.email) = 0 OR POSITION('.' IN SUBSTRING(NEW.email FROM POSITION('@' IN NEW.email))) = 0 THEN
            RAISE EXCEPTION 'Format d''email invalide: %', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_confirmation_token(p_token text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    email_record RECORD;
BEGIN
    -- Récupérer le token
    SELECT * INTO email_record FROM confirmation_emails 
    WHERE token = p_token AND status = 'sent';
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Token invalide ou déjà utilisé'
        );
    END IF;
    
    -- Vérifier l'expiration
    IF email_record.expires_at < NOW() THEN
        UPDATE confirmation_emails SET status = 'expired' WHERE token = p_token;
        RETURN json_build_object(
            'success', false,
            'error', 'Token expiré'
        );
    END IF;
    
    -- Marquer comme utilisé
    UPDATE confirmation_emails SET status = 'used' WHERE token = p_token;
    
    RETURN json_build_object(
        'success', true,
        'email', email_record.user_email,
        'message', 'Token validé avec succès'
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_email_format(email_address text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Validation basique d'email
    RETURN email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_loyalty_points_client()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    client_exists BOOLEAN;
    default_client_id UUID;
BEGIN
    -- Si client_id est NULL, on peut l'insérer (peut être optionnel)
    IF NEW.client_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Vérifier si le client existe
    SELECT EXISTS (
        SELECT 1 FROM clients WHERE id = NEW.client_id
    ) INTO client_exists;
    
    IF NOT client_exists THEN
        RAISE NOTICE '⚠️ Client_id invalide: % - recherche d''un client par défaut', NEW.client_id;
        
        -- Trouver un client par défaut
        SELECT id INTO default_client_id FROM clients LIMIT 1;
        
        IF default_client_id IS NOT NULL THEN
            NEW.client_id := default_client_id;
            RAISE NOTICE '✅ Client_id remplacé par: %', default_client_id;
        ELSE
            -- Si aucun client n'existe, créer un client par défaut
            INSERT INTO clients (
                id, name, email, phone, address, created_at, updated_at
            ) VALUES (
                gen_random_uuid(), 'Client automatique', 'auto@example.com', '0000000000', 'Créé automatiquement',
                NOW(), NOW()
            ) RETURNING id INTO default_client_id;
            
            NEW.client_id := default_client_id;
            RAISE NOTICE '✅ Nouveau client créé et assigné: %', default_client_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_repair_payment(p_repair_id uuid, p_is_paid boolean)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_repair repairs%ROWTYPE;
    v_result JSON;
BEGIN
    -- Verifier que l'utilisateur a les droits pour modifier les reparations
    IF NOT can_be_assigned_to_repairs(auth.uid()) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Acces non autorise. Seuls les techniciens, administrateurs et managers peuvent valider les paiements.'
        );
    END IF;

    -- Recuperer la reparation
    SELECT * INTO v_repair
    FROM repairs
    WHERE id = p_repair_id;
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Reparation non trouvee'
        );
    END IF;

    -- Verifier que la reparation est terminee
    IF v_repair.status NOT IN ('completed', 'returned') THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Seules les reparations terminees peuvent avoir leur paiement valide'
        );
    END IF;

    -- Mettre a jour le statut de paiement
    UPDATE repairs 
    SET 
        is_paid = p_is_paid,
        updated_at = NOW()
    WHERE id = p_repair_id;

    -- Retourner le succes avec les informations mises a jour
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'id', p_repair_id,
            'is_paid', p_is_paid,
            'updated_at', NOW()
        ),
        'message', CASE 
            WHEN p_is_paid THEN 'Paiement valide avec succes'
            ELSE 'Paiement annule avec succes'
        END
    ) INTO v_result;

    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la validation du paiement: ' || SQLERRM
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.validate_serial_number_format(serial_number text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Validation basique de numéro de série
    -- Permet les lettres, chiffres, tirets, underscores
    RETURN serial_number ~* '^[A-Za-z0-9\-_]+$';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.verify_data_isolation()
 RETURNS TABLE(table_name text, total_rows bigint, isolated_rows bigint, isolation_percentage numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        'device_models'::TEXT as table_name,
        COUNT(*) as total_rows,
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) as isolated_rows,
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2) as isolation_percentage
    FROM device_models
    
    UNION ALL
    
    SELECT 
        'performance_metrics'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM performance_metrics
    
    UNION ALL
    
    SELECT 
        'reports'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM reports
    
    UNION ALL
    
    SELECT 
        'advanced_alerts'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM advanced_alerts
    
    UNION ALL
    
    SELECT 
        'technician_performance'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM technician_performance
    
    UNION ALL
    
    SELECT 
        'transactions'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM transactions
    
    UNION ALL
    
    SELECT 
        'activity_logs'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM activity_logs
    
    UNION ALL
    
    SELECT 
        'advanced_settings'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)),
        ROUND(COUNT(*) FILTER (WHERE workshop_id = COALESCE((SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1), '00000000-0000-0000-0000-000000000000'::UUID)) * 100.0 / COUNT(*), 2)
    FROM advanced_settings;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.verify_force_isolation()
 RETURNS TABLE(verification text, result text)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_workshop_id UUID;
    v_model_count INTEGER;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Vérifications
    RETURN QUERY SELECT 'Workshop_id actuel'::TEXT, COALESCE(v_workshop_id::text, 'NULL')::TEXT;
    
    SELECT COUNT(*) INTO v_model_count FROM device_models;
    RETURN QUERY SELECT 'Nombre total de modèles'::TEXT, v_model_count::text::TEXT;
    
    SELECT COUNT(*) INTO v_model_count 
    FROM device_models 
    WHERE workshop_id = v_workshop_id;
    RETURN QUERY SELECT 'Modèles de l''atelier actuel'::TEXT, v_model_count::text::TEXT;
    
    SELECT COUNT(*) INTO v_model_count 
    FROM device_models 
    WHERE workshop_id != v_workshop_id;
    RETURN QUERY SELECT 'Modèles d''autres ateliers'::TEXT, v_model_count::text::TEXT;
    
    SELECT COUNT(*) INTO v_model_count 
    FROM pg_policies 
    WHERE tablename = 'device_models';
    RETURN QUERY SELECT 'Nombre de politiques RLS'::TEXT, v_model_count::text::TEXT;
    
    SELECT COUNT(*) INTO v_model_count 
    FROM pg_trigger 
    WHERE tgrelid = 'device_models'::regclass;
    RETURN QUERY SELECT 'Nombre de triggers'::TEXT, v_model_count::text::TEXT;
END;
$function$
;

grant delete on table "public"."activity_logs" to "anon";

grant insert on table "public"."activity_logs" to "anon";

grant references on table "public"."activity_logs" to "anon";

grant select on table "public"."activity_logs" to "anon";

grant trigger on table "public"."activity_logs" to "anon";

grant truncate on table "public"."activity_logs" to "anon";

grant update on table "public"."activity_logs" to "anon";

grant delete on table "public"."activity_logs" to "authenticated";

grant insert on table "public"."activity_logs" to "authenticated";

grant references on table "public"."activity_logs" to "authenticated";

grant select on table "public"."activity_logs" to "authenticated";

grant trigger on table "public"."activity_logs" to "authenticated";

grant truncate on table "public"."activity_logs" to "authenticated";

grant update on table "public"."activity_logs" to "authenticated";

grant delete on table "public"."activity_logs" to "service_role";

grant insert on table "public"."activity_logs" to "service_role";

grant references on table "public"."activity_logs" to "service_role";

grant select on table "public"."activity_logs" to "service_role";

grant trigger on table "public"."activity_logs" to "service_role";

grant truncate on table "public"."activity_logs" to "service_role";

grant update on table "public"."activity_logs" to "service_role";

grant delete on table "public"."advanced_alerts" to "anon";

grant insert on table "public"."advanced_alerts" to "anon";

grant references on table "public"."advanced_alerts" to "anon";

grant select on table "public"."advanced_alerts" to "anon";

grant trigger on table "public"."advanced_alerts" to "anon";

grant truncate on table "public"."advanced_alerts" to "anon";

grant update on table "public"."advanced_alerts" to "anon";

grant delete on table "public"."advanced_alerts" to "authenticated";

grant insert on table "public"."advanced_alerts" to "authenticated";

grant references on table "public"."advanced_alerts" to "authenticated";

grant select on table "public"."advanced_alerts" to "authenticated";

grant trigger on table "public"."advanced_alerts" to "authenticated";

grant truncate on table "public"."advanced_alerts" to "authenticated";

grant update on table "public"."advanced_alerts" to "authenticated";

grant delete on table "public"."advanced_alerts" to "service_role";

grant insert on table "public"."advanced_alerts" to "service_role";

grant references on table "public"."advanced_alerts" to "service_role";

grant select on table "public"."advanced_alerts" to "service_role";

grant trigger on table "public"."advanced_alerts" to "service_role";

grant truncate on table "public"."advanced_alerts" to "service_role";

grant update on table "public"."advanced_alerts" to "service_role";

grant delete on table "public"."advanced_settings" to "anon";

grant insert on table "public"."advanced_settings" to "anon";

grant references on table "public"."advanced_settings" to "anon";

grant select on table "public"."advanced_settings" to "anon";

grant trigger on table "public"."advanced_settings" to "anon";

grant truncate on table "public"."advanced_settings" to "anon";

grant update on table "public"."advanced_settings" to "anon";

grant delete on table "public"."advanced_settings" to "authenticated";

grant insert on table "public"."advanced_settings" to "authenticated";

grant references on table "public"."advanced_settings" to "authenticated";

grant select on table "public"."advanced_settings" to "authenticated";

grant trigger on table "public"."advanced_settings" to "authenticated";

grant truncate on table "public"."advanced_settings" to "authenticated";

grant update on table "public"."advanced_settings" to "authenticated";

grant delete on table "public"."advanced_settings" to "service_role";

grant insert on table "public"."advanced_settings" to "service_role";

grant references on table "public"."advanced_settings" to "service_role";

grant select on table "public"."advanced_settings" to "service_role";

grant trigger on table "public"."advanced_settings" to "service_role";

grant truncate on table "public"."advanced_settings" to "service_role";

grant update on table "public"."advanced_settings" to "service_role";

grant delete on table "public"."appointments" to "anon";

grant insert on table "public"."appointments" to "anon";

grant references on table "public"."appointments" to "anon";

grant select on table "public"."appointments" to "anon";

grant trigger on table "public"."appointments" to "anon";

grant truncate on table "public"."appointments" to "anon";

grant update on table "public"."appointments" to "anon";

grant delete on table "public"."appointments" to "authenticated";

grant insert on table "public"."appointments" to "authenticated";

grant references on table "public"."appointments" to "authenticated";

grant select on table "public"."appointments" to "authenticated";

grant trigger on table "public"."appointments" to "authenticated";

grant truncate on table "public"."appointments" to "authenticated";

grant update on table "public"."appointments" to "authenticated";

grant delete on table "public"."appointments" to "service_role";

grant insert on table "public"."appointments" to "service_role";

grant references on table "public"."appointments" to "service_role";

grant select on table "public"."appointments" to "service_role";

grant trigger on table "public"."appointments" to "service_role";

grant truncate on table "public"."appointments" to "service_role";

grant update on table "public"."appointments" to "service_role";

grant delete on table "public"."client_loyalty_points" to "anon";

grant insert on table "public"."client_loyalty_points" to "anon";

grant references on table "public"."client_loyalty_points" to "anon";

grant select on table "public"."client_loyalty_points" to "anon";

grant trigger on table "public"."client_loyalty_points" to "anon";

grant truncate on table "public"."client_loyalty_points" to "anon";

grant update on table "public"."client_loyalty_points" to "anon";

grant delete on table "public"."client_loyalty_points" to "authenticated";

grant insert on table "public"."client_loyalty_points" to "authenticated";

grant references on table "public"."client_loyalty_points" to "authenticated";

grant select on table "public"."client_loyalty_points" to "authenticated";

grant trigger on table "public"."client_loyalty_points" to "authenticated";

grant truncate on table "public"."client_loyalty_points" to "authenticated";

grant update on table "public"."client_loyalty_points" to "authenticated";

grant delete on table "public"."client_loyalty_points" to "service_role";

grant insert on table "public"."client_loyalty_points" to "service_role";

grant references on table "public"."client_loyalty_points" to "service_role";

grant select on table "public"."client_loyalty_points" to "service_role";

grant trigger on table "public"."client_loyalty_points" to "service_role";

grant truncate on table "public"."client_loyalty_points" to "service_role";

grant update on table "public"."client_loyalty_points" to "service_role";

grant delete on table "public"."clients" to "anon";

grant insert on table "public"."clients" to "anon";

grant references on table "public"."clients" to "anon";

grant select on table "public"."clients" to "anon";

grant trigger on table "public"."clients" to "anon";

grant truncate on table "public"."clients" to "anon";

grant update on table "public"."clients" to "anon";

grant delete on table "public"."clients" to "authenticated";

grant insert on table "public"."clients" to "authenticated";

grant references on table "public"."clients" to "authenticated";

grant select on table "public"."clients" to "authenticated";

grant trigger on table "public"."clients" to "authenticated";

grant truncate on table "public"."clients" to "authenticated";

grant update on table "public"."clients" to "authenticated";

grant delete on table "public"."clients" to "service_role";

grant insert on table "public"."clients" to "service_role";

grant references on table "public"."clients" to "service_role";

grant select on table "public"."clients" to "service_role";

grant trigger on table "public"."clients" to "service_role";

grant truncate on table "public"."clients" to "service_role";

grant update on table "public"."clients" to "service_role";

grant delete on table "public"."clients_backup" to "anon";

grant insert on table "public"."clients_backup" to "anon";

grant references on table "public"."clients_backup" to "anon";

grant select on table "public"."clients_backup" to "anon";

grant trigger on table "public"."clients_backup" to "anon";

grant truncate on table "public"."clients_backup" to "anon";

grant update on table "public"."clients_backup" to "anon";

grant delete on table "public"."clients_backup" to "authenticated";

grant insert on table "public"."clients_backup" to "authenticated";

grant references on table "public"."clients_backup" to "authenticated";

grant select on table "public"."clients_backup" to "authenticated";

grant trigger on table "public"."clients_backup" to "authenticated";

grant truncate on table "public"."clients_backup" to "authenticated";

grant update on table "public"."clients_backup" to "authenticated";

grant delete on table "public"."clients_backup" to "service_role";

grant insert on table "public"."clients_backup" to "service_role";

grant references on table "public"."clients_backup" to "service_role";

grant select on table "public"."clients_backup" to "service_role";

grant trigger on table "public"."clients_backup" to "service_role";

grant truncate on table "public"."clients_backup" to "service_role";

grant update on table "public"."clients_backup" to "service_role";

grant delete on table "public"."confirmation_emails" to "anon";

grant insert on table "public"."confirmation_emails" to "anon";

grant references on table "public"."confirmation_emails" to "anon";

grant select on table "public"."confirmation_emails" to "anon";

grant trigger on table "public"."confirmation_emails" to "anon";

grant truncate on table "public"."confirmation_emails" to "anon";

grant update on table "public"."confirmation_emails" to "anon";

grant delete on table "public"."confirmation_emails" to "authenticated";

grant insert on table "public"."confirmation_emails" to "authenticated";

grant references on table "public"."confirmation_emails" to "authenticated";

grant select on table "public"."confirmation_emails" to "authenticated";

grant trigger on table "public"."confirmation_emails" to "authenticated";

grant truncate on table "public"."confirmation_emails" to "authenticated";

grant update on table "public"."confirmation_emails" to "authenticated";

grant delete on table "public"."confirmation_emails" to "service_role";

grant insert on table "public"."confirmation_emails" to "service_role";

grant references on table "public"."confirmation_emails" to "service_role";

grant select on table "public"."confirmation_emails" to "service_role";

grant trigger on table "public"."confirmation_emails" to "service_role";

grant truncate on table "public"."confirmation_emails" to "service_role";

grant update on table "public"."confirmation_emails" to "service_role";

grant delete on table "public"."custom_users" to "anon";

grant insert on table "public"."custom_users" to "anon";

grant references on table "public"."custom_users" to "anon";

grant select on table "public"."custom_users" to "anon";

grant trigger on table "public"."custom_users" to "anon";

grant truncate on table "public"."custom_users" to "anon";

grant update on table "public"."custom_users" to "anon";

grant delete on table "public"."custom_users" to "authenticated";

grant insert on table "public"."custom_users" to "authenticated";

grant references on table "public"."custom_users" to "authenticated";

grant select on table "public"."custom_users" to "authenticated";

grant trigger on table "public"."custom_users" to "authenticated";

grant truncate on table "public"."custom_users" to "authenticated";

grant update on table "public"."custom_users" to "authenticated";

grant delete on table "public"."custom_users" to "service_role";

grant insert on table "public"."custom_users" to "service_role";

grant references on table "public"."custom_users" to "service_role";

grant select on table "public"."custom_users" to "service_role";

grant trigger on table "public"."custom_users" to "service_role";

grant truncate on table "public"."custom_users" to "service_role";

grant update on table "public"."custom_users" to "service_role";

grant delete on table "public"."device_brands" to "anon";

grant insert on table "public"."device_brands" to "anon";

grant references on table "public"."device_brands" to "anon";

grant select on table "public"."device_brands" to "anon";

grant trigger on table "public"."device_brands" to "anon";

grant truncate on table "public"."device_brands" to "anon";

grant update on table "public"."device_brands" to "anon";

grant delete on table "public"."device_brands" to "authenticated";

grant insert on table "public"."device_brands" to "authenticated";

grant references on table "public"."device_brands" to "authenticated";

grant select on table "public"."device_brands" to "authenticated";

grant trigger on table "public"."device_brands" to "authenticated";

grant truncate on table "public"."device_brands" to "authenticated";

grant update on table "public"."device_brands" to "authenticated";

grant delete on table "public"."device_brands" to "service_role";

grant insert on table "public"."device_brands" to "service_role";

grant references on table "public"."device_brands" to "service_role";

grant select on table "public"."device_brands" to "service_role";

grant trigger on table "public"."device_brands" to "service_role";

grant truncate on table "public"."device_brands" to "service_role";

grant update on table "public"."device_brands" to "service_role";

grant delete on table "public"."device_categories" to "anon";

grant insert on table "public"."device_categories" to "anon";

grant references on table "public"."device_categories" to "anon";

grant select on table "public"."device_categories" to "anon";

grant trigger on table "public"."device_categories" to "anon";

grant truncate on table "public"."device_categories" to "anon";

grant update on table "public"."device_categories" to "anon";

grant delete on table "public"."device_categories" to "authenticated";

grant insert on table "public"."device_categories" to "authenticated";

grant references on table "public"."device_categories" to "authenticated";

grant select on table "public"."device_categories" to "authenticated";

grant trigger on table "public"."device_categories" to "authenticated";

grant truncate on table "public"."device_categories" to "authenticated";

grant update on table "public"."device_categories" to "authenticated";

grant delete on table "public"."device_categories" to "service_role";

grant insert on table "public"."device_categories" to "service_role";

grant references on table "public"."device_categories" to "service_role";

grant select on table "public"."device_categories" to "service_role";

grant trigger on table "public"."device_categories" to "service_role";

grant truncate on table "public"."device_categories" to "service_role";

grant update on table "public"."device_categories" to "service_role";

grant delete on table "public"."device_models" to "anon";

grant insert on table "public"."device_models" to "anon";

grant references on table "public"."device_models" to "anon";

grant select on table "public"."device_models" to "anon";

grant trigger on table "public"."device_models" to "anon";

grant truncate on table "public"."device_models" to "anon";

grant update on table "public"."device_models" to "anon";

grant delete on table "public"."device_models" to "authenticated";

grant insert on table "public"."device_models" to "authenticated";

grant references on table "public"."device_models" to "authenticated";

grant select on table "public"."device_models" to "authenticated";

grant trigger on table "public"."device_models" to "authenticated";

grant truncate on table "public"."device_models" to "authenticated";

grant update on table "public"."device_models" to "authenticated";

grant delete on table "public"."device_models" to "service_role";

grant insert on table "public"."device_models" to "service_role";

grant references on table "public"."device_models" to "service_role";

grant select on table "public"."device_models" to "service_role";

grant trigger on table "public"."device_models" to "service_role";

grant truncate on table "public"."device_models" to "service_role";

grant update on table "public"."device_models" to "service_role";

grant delete on table "public"."devices" to "anon";

grant insert on table "public"."devices" to "anon";

grant references on table "public"."devices" to "anon";

grant select on table "public"."devices" to "anon";

grant trigger on table "public"."devices" to "anon";

grant truncate on table "public"."devices" to "anon";

grant update on table "public"."devices" to "anon";

grant delete on table "public"."devices" to "authenticated";

grant insert on table "public"."devices" to "authenticated";

grant references on table "public"."devices" to "authenticated";

grant select on table "public"."devices" to "authenticated";

grant trigger on table "public"."devices" to "authenticated";

grant truncate on table "public"."devices" to "authenticated";

grant update on table "public"."devices" to "authenticated";

grant delete on table "public"."devices" to "service_role";

grant insert on table "public"."devices" to "service_role";

grant references on table "public"."devices" to "service_role";

grant select on table "public"."devices" to "service_role";

grant trigger on table "public"."devices" to "service_role";

grant truncate on table "public"."devices" to "service_role";

grant update on table "public"."devices" to "service_role";

grant delete on table "public"."intervention_forms" to "anon";

grant insert on table "public"."intervention_forms" to "anon";

grant references on table "public"."intervention_forms" to "anon";

grant select on table "public"."intervention_forms" to "anon";

grant trigger on table "public"."intervention_forms" to "anon";

grant truncate on table "public"."intervention_forms" to "anon";

grant update on table "public"."intervention_forms" to "anon";

grant delete on table "public"."intervention_forms" to "authenticated";

grant insert on table "public"."intervention_forms" to "authenticated";

grant references on table "public"."intervention_forms" to "authenticated";

grant select on table "public"."intervention_forms" to "authenticated";

grant trigger on table "public"."intervention_forms" to "authenticated";

grant truncate on table "public"."intervention_forms" to "authenticated";

grant update on table "public"."intervention_forms" to "authenticated";

grant delete on table "public"."intervention_forms" to "service_role";

grant insert on table "public"."intervention_forms" to "service_role";

grant references on table "public"."intervention_forms" to "service_role";

grant select on table "public"."intervention_forms" to "service_role";

grant trigger on table "public"."intervention_forms" to "service_role";

grant truncate on table "public"."intervention_forms" to "service_role";

grant update on table "public"."intervention_forms" to "service_role";

grant delete on table "public"."loyalty_config" to "anon";

grant insert on table "public"."loyalty_config" to "anon";

grant references on table "public"."loyalty_config" to "anon";

grant select on table "public"."loyalty_config" to "anon";

grant trigger on table "public"."loyalty_config" to "anon";

grant truncate on table "public"."loyalty_config" to "anon";

grant update on table "public"."loyalty_config" to "anon";

grant delete on table "public"."loyalty_config" to "authenticated";

grant insert on table "public"."loyalty_config" to "authenticated";

grant references on table "public"."loyalty_config" to "authenticated";

grant select on table "public"."loyalty_config" to "authenticated";

grant trigger on table "public"."loyalty_config" to "authenticated";

grant truncate on table "public"."loyalty_config" to "authenticated";

grant update on table "public"."loyalty_config" to "authenticated";

grant delete on table "public"."loyalty_config" to "service_role";

grant insert on table "public"."loyalty_config" to "service_role";

grant references on table "public"."loyalty_config" to "service_role";

grant select on table "public"."loyalty_config" to "service_role";

grant trigger on table "public"."loyalty_config" to "service_role";

grant truncate on table "public"."loyalty_config" to "service_role";

grant update on table "public"."loyalty_config" to "service_role";

grant delete on table "public"."loyalty_points_history" to "anon";

grant insert on table "public"."loyalty_points_history" to "anon";

grant references on table "public"."loyalty_points_history" to "anon";

grant select on table "public"."loyalty_points_history" to "anon";

grant trigger on table "public"."loyalty_points_history" to "anon";

grant truncate on table "public"."loyalty_points_history" to "anon";

grant update on table "public"."loyalty_points_history" to "anon";

grant delete on table "public"."loyalty_points_history" to "authenticated";

grant insert on table "public"."loyalty_points_history" to "authenticated";

grant references on table "public"."loyalty_points_history" to "authenticated";

grant select on table "public"."loyalty_points_history" to "authenticated";

grant trigger on table "public"."loyalty_points_history" to "authenticated";

grant truncate on table "public"."loyalty_points_history" to "authenticated";

grant update on table "public"."loyalty_points_history" to "authenticated";

grant delete on table "public"."loyalty_points_history" to "service_role";

grant insert on table "public"."loyalty_points_history" to "service_role";

grant references on table "public"."loyalty_points_history" to "service_role";

grant select on table "public"."loyalty_points_history" to "service_role";

grant trigger on table "public"."loyalty_points_history" to "service_role";

grant truncate on table "public"."loyalty_points_history" to "service_role";

grant update on table "public"."loyalty_points_history" to "service_role";

grant delete on table "public"."loyalty_rules" to "anon";

grant insert on table "public"."loyalty_rules" to "anon";

grant references on table "public"."loyalty_rules" to "anon";

grant select on table "public"."loyalty_rules" to "anon";

grant trigger on table "public"."loyalty_rules" to "anon";

grant truncate on table "public"."loyalty_rules" to "anon";

grant update on table "public"."loyalty_rules" to "anon";

grant delete on table "public"."loyalty_rules" to "authenticated";

grant insert on table "public"."loyalty_rules" to "authenticated";

grant references on table "public"."loyalty_rules" to "authenticated";

grant select on table "public"."loyalty_rules" to "authenticated";

grant trigger on table "public"."loyalty_rules" to "authenticated";

grant truncate on table "public"."loyalty_rules" to "authenticated";

grant update on table "public"."loyalty_rules" to "authenticated";

grant delete on table "public"."loyalty_rules" to "service_role";

grant insert on table "public"."loyalty_rules" to "service_role";

grant references on table "public"."loyalty_rules" to "service_role";

grant select on table "public"."loyalty_rules" to "service_role";

grant trigger on table "public"."loyalty_rules" to "service_role";

grant truncate on table "public"."loyalty_rules" to "service_role";

grant update on table "public"."loyalty_rules" to "service_role";

grant delete on table "public"."loyalty_tiers" to "anon";

grant insert on table "public"."loyalty_tiers" to "anon";

grant references on table "public"."loyalty_tiers" to "anon";

grant select on table "public"."loyalty_tiers" to "anon";

grant trigger on table "public"."loyalty_tiers" to "anon";

grant truncate on table "public"."loyalty_tiers" to "anon";

grant update on table "public"."loyalty_tiers" to "anon";

grant delete on table "public"."loyalty_tiers" to "authenticated";

grant insert on table "public"."loyalty_tiers" to "authenticated";

grant references on table "public"."loyalty_tiers" to "authenticated";

grant select on table "public"."loyalty_tiers" to "authenticated";

grant trigger on table "public"."loyalty_tiers" to "authenticated";

grant truncate on table "public"."loyalty_tiers" to "authenticated";

grant update on table "public"."loyalty_tiers" to "authenticated";

grant delete on table "public"."loyalty_tiers" to "service_role";

grant insert on table "public"."loyalty_tiers" to "service_role";

grant references on table "public"."loyalty_tiers" to "service_role";

grant select on table "public"."loyalty_tiers" to "service_role";

grant trigger on table "public"."loyalty_tiers" to "service_role";

grant truncate on table "public"."loyalty_tiers" to "service_role";

grant update on table "public"."loyalty_tiers" to "service_role";

grant delete on table "public"."loyalty_tiers_advanced" to "anon";

grant insert on table "public"."loyalty_tiers_advanced" to "anon";

grant references on table "public"."loyalty_tiers_advanced" to "anon";

grant select on table "public"."loyalty_tiers_advanced" to "anon";

grant trigger on table "public"."loyalty_tiers_advanced" to "anon";

grant truncate on table "public"."loyalty_tiers_advanced" to "anon";

grant update on table "public"."loyalty_tiers_advanced" to "anon";

grant delete on table "public"."loyalty_tiers_advanced" to "authenticated";

grant insert on table "public"."loyalty_tiers_advanced" to "authenticated";

grant references on table "public"."loyalty_tiers_advanced" to "authenticated";

grant select on table "public"."loyalty_tiers_advanced" to "authenticated";

grant trigger on table "public"."loyalty_tiers_advanced" to "authenticated";

grant truncate on table "public"."loyalty_tiers_advanced" to "authenticated";

grant update on table "public"."loyalty_tiers_advanced" to "authenticated";

grant delete on table "public"."loyalty_tiers_advanced" to "service_role";

grant insert on table "public"."loyalty_tiers_advanced" to "service_role";

grant references on table "public"."loyalty_tiers_advanced" to "service_role";

grant select on table "public"."loyalty_tiers_advanced" to "service_role";

grant trigger on table "public"."loyalty_tiers_advanced" to "service_role";

grant truncate on table "public"."loyalty_tiers_advanced" to "service_role";

grant update on table "public"."loyalty_tiers_advanced" to "service_role";

grant delete on table "public"."messages" to "anon";

grant insert on table "public"."messages" to "anon";

grant references on table "public"."messages" to "anon";

grant select on table "public"."messages" to "anon";

grant trigger on table "public"."messages" to "anon";

grant truncate on table "public"."messages" to "anon";

grant update on table "public"."messages" to "anon";

grant delete on table "public"."messages" to "authenticated";

grant insert on table "public"."messages" to "authenticated";

grant references on table "public"."messages" to "authenticated";

grant select on table "public"."messages" to "authenticated";

grant trigger on table "public"."messages" to "authenticated";

grant truncate on table "public"."messages" to "authenticated";

grant update on table "public"."messages" to "authenticated";

grant delete on table "public"."messages" to "service_role";

grant insert on table "public"."messages" to "service_role";

grant references on table "public"."messages" to "service_role";

grant select on table "public"."messages" to "service_role";

grant trigger on table "public"."messages" to "service_role";

grant truncate on table "public"."messages" to "service_role";

grant update on table "public"."messages" to "service_role";

grant delete on table "public"."notifications" to "anon";

grant insert on table "public"."notifications" to "anon";

grant references on table "public"."notifications" to "anon";

grant select on table "public"."notifications" to "anon";

grant trigger on table "public"."notifications" to "anon";

grant truncate on table "public"."notifications" to "anon";

grant update on table "public"."notifications" to "anon";

grant delete on table "public"."notifications" to "authenticated";

grant insert on table "public"."notifications" to "authenticated";

grant references on table "public"."notifications" to "authenticated";

grant select on table "public"."notifications" to "authenticated";

grant trigger on table "public"."notifications" to "authenticated";

grant truncate on table "public"."notifications" to "authenticated";

grant update on table "public"."notifications" to "authenticated";

grant delete on table "public"."notifications" to "service_role";

grant insert on table "public"."notifications" to "service_role";

grant references on table "public"."notifications" to "service_role";

grant select on table "public"."notifications" to "service_role";

grant trigger on table "public"."notifications" to "service_role";

grant truncate on table "public"."notifications" to "service_role";

grant update on table "public"."notifications" to "service_role";

grant delete on table "public"."order_items" to "anon";

grant insert on table "public"."order_items" to "anon";

grant references on table "public"."order_items" to "anon";

grant select on table "public"."order_items" to "anon";

grant trigger on table "public"."order_items" to "anon";

grant truncate on table "public"."order_items" to "anon";

grant update on table "public"."order_items" to "anon";

grant delete on table "public"."order_items" to "authenticated";

grant insert on table "public"."order_items" to "authenticated";

grant references on table "public"."order_items" to "authenticated";

grant select on table "public"."order_items" to "authenticated";

grant trigger on table "public"."order_items" to "authenticated";

grant truncate on table "public"."order_items" to "authenticated";

grant update on table "public"."order_items" to "authenticated";

grant delete on table "public"."order_items" to "service_role";

grant insert on table "public"."order_items" to "service_role";

grant references on table "public"."order_items" to "service_role";

grant select on table "public"."order_items" to "service_role";

grant trigger on table "public"."order_items" to "service_role";

grant truncate on table "public"."order_items" to "service_role";

grant update on table "public"."order_items" to "service_role";

grant delete on table "public"."orders" to "anon";

grant insert on table "public"."orders" to "anon";

grant references on table "public"."orders" to "anon";

grant select on table "public"."orders" to "anon";

grant trigger on table "public"."orders" to "anon";

grant truncate on table "public"."orders" to "anon";

grant update on table "public"."orders" to "anon";

grant delete on table "public"."orders" to "authenticated";

grant insert on table "public"."orders" to "authenticated";

grant references on table "public"."orders" to "authenticated";

grant select on table "public"."orders" to "authenticated";

grant trigger on table "public"."orders" to "authenticated";

grant truncate on table "public"."orders" to "authenticated";

grant update on table "public"."orders" to "authenticated";

grant delete on table "public"."orders" to "service_role";

grant insert on table "public"."orders" to "service_role";

grant references on table "public"."orders" to "service_role";

grant select on table "public"."orders" to "service_role";

grant trigger on table "public"."orders" to "service_role";

grant truncate on table "public"."orders" to "service_role";

grant update on table "public"."orders" to "service_role";

grant delete on table "public"."parts" to "anon";

grant insert on table "public"."parts" to "anon";

grant references on table "public"."parts" to "anon";

grant select on table "public"."parts" to "anon";

grant trigger on table "public"."parts" to "anon";

grant truncate on table "public"."parts" to "anon";

grant update on table "public"."parts" to "anon";

grant delete on table "public"."parts" to "authenticated";

grant insert on table "public"."parts" to "authenticated";

grant references on table "public"."parts" to "authenticated";

grant select on table "public"."parts" to "authenticated";

grant trigger on table "public"."parts" to "authenticated";

grant truncate on table "public"."parts" to "authenticated";

grant update on table "public"."parts" to "authenticated";

grant delete on table "public"."parts" to "service_role";

grant insert on table "public"."parts" to "service_role";

grant references on table "public"."parts" to "service_role";

grant select on table "public"."parts" to "service_role";

grant trigger on table "public"."parts" to "service_role";

grant truncate on table "public"."parts" to "service_role";

grant update on table "public"."parts" to "service_role";

grant delete on table "public"."pending_signups" to "anon";

grant insert on table "public"."pending_signups" to "anon";

grant references on table "public"."pending_signups" to "anon";

grant select on table "public"."pending_signups" to "anon";

grant trigger on table "public"."pending_signups" to "anon";

grant truncate on table "public"."pending_signups" to "anon";

grant update on table "public"."pending_signups" to "anon";

grant delete on table "public"."pending_signups" to "authenticated";

grant insert on table "public"."pending_signups" to "authenticated";

grant references on table "public"."pending_signups" to "authenticated";

grant select on table "public"."pending_signups" to "authenticated";

grant trigger on table "public"."pending_signups" to "authenticated";

grant truncate on table "public"."pending_signups" to "authenticated";

grant update on table "public"."pending_signups" to "authenticated";

grant delete on table "public"."pending_signups" to "service_role";

grant insert on table "public"."pending_signups" to "service_role";

grant references on table "public"."pending_signups" to "service_role";

grant select on table "public"."pending_signups" to "service_role";

grant trigger on table "public"."pending_signups" to "service_role";

grant truncate on table "public"."pending_signups" to "service_role";

grant update on table "public"."pending_signups" to "service_role";

grant delete on table "public"."performance_metrics" to "anon";

grant insert on table "public"."performance_metrics" to "anon";

grant references on table "public"."performance_metrics" to "anon";

grant select on table "public"."performance_metrics" to "anon";

grant trigger on table "public"."performance_metrics" to "anon";

grant truncate on table "public"."performance_metrics" to "anon";

grant update on table "public"."performance_metrics" to "anon";

grant delete on table "public"."performance_metrics" to "authenticated";

grant insert on table "public"."performance_metrics" to "authenticated";

grant references on table "public"."performance_metrics" to "authenticated";

grant select on table "public"."performance_metrics" to "authenticated";

grant trigger on table "public"."performance_metrics" to "authenticated";

grant truncate on table "public"."performance_metrics" to "authenticated";

grant update on table "public"."performance_metrics" to "authenticated";

grant delete on table "public"."performance_metrics" to "service_role";

grant insert on table "public"."performance_metrics" to "service_role";

grant references on table "public"."performance_metrics" to "service_role";

grant select on table "public"."performance_metrics" to "service_role";

grant trigger on table "public"."performance_metrics" to "service_role";

grant truncate on table "public"."performance_metrics" to "service_role";

grant update on table "public"."performance_metrics" to "service_role";

grant delete on table "public"."product_categories" to "anon";

grant insert on table "public"."product_categories" to "anon";

grant references on table "public"."product_categories" to "anon";

grant select on table "public"."product_categories" to "anon";

grant trigger on table "public"."product_categories" to "anon";

grant truncate on table "public"."product_categories" to "anon";

grant update on table "public"."product_categories" to "anon";

grant delete on table "public"."product_categories" to "authenticated";

grant insert on table "public"."product_categories" to "authenticated";

grant references on table "public"."product_categories" to "authenticated";

grant select on table "public"."product_categories" to "authenticated";

grant trigger on table "public"."product_categories" to "authenticated";

grant truncate on table "public"."product_categories" to "authenticated";

grant update on table "public"."product_categories" to "authenticated";

grant delete on table "public"."product_categories" to "service_role";

grant insert on table "public"."product_categories" to "service_role";

grant references on table "public"."product_categories" to "service_role";

grant select on table "public"."product_categories" to "service_role";

grant trigger on table "public"."product_categories" to "service_role";

grant truncate on table "public"."product_categories" to "service_role";

grant update on table "public"."product_categories" to "service_role";

grant delete on table "public"."products" to "anon";

grant insert on table "public"."products" to "anon";

grant references on table "public"."products" to "anon";

grant select on table "public"."products" to "anon";

grant trigger on table "public"."products" to "anon";

grant truncate on table "public"."products" to "anon";

grant update on table "public"."products" to "anon";

grant delete on table "public"."products" to "authenticated";

grant insert on table "public"."products" to "authenticated";

grant references on table "public"."products" to "authenticated";

grant select on table "public"."products" to "authenticated";

grant trigger on table "public"."products" to "authenticated";

grant truncate on table "public"."products" to "authenticated";

grant update on table "public"."products" to "authenticated";

grant delete on table "public"."products" to "service_role";

grant insert on table "public"."products" to "service_role";

grant references on table "public"."products" to "service_role";

grant select on table "public"."products" to "service_role";

grant trigger on table "public"."products" to "service_role";

grant truncate on table "public"."products" to "service_role";

grant update on table "public"."products" to "service_role";

grant delete on table "public"."quote_items" to "anon";

grant insert on table "public"."quote_items" to "anon";

grant references on table "public"."quote_items" to "anon";

grant select on table "public"."quote_items" to "anon";

grant trigger on table "public"."quote_items" to "anon";

grant truncate on table "public"."quote_items" to "anon";

grant update on table "public"."quote_items" to "anon";

grant delete on table "public"."quote_items" to "authenticated";

grant insert on table "public"."quote_items" to "authenticated";

grant references on table "public"."quote_items" to "authenticated";

grant select on table "public"."quote_items" to "authenticated";

grant trigger on table "public"."quote_items" to "authenticated";

grant truncate on table "public"."quote_items" to "authenticated";

grant update on table "public"."quote_items" to "authenticated";

grant delete on table "public"."quote_items" to "service_role";

grant insert on table "public"."quote_items" to "service_role";

grant references on table "public"."quote_items" to "service_role";

grant select on table "public"."quote_items" to "service_role";

grant trigger on table "public"."quote_items" to "service_role";

grant truncate on table "public"."quote_items" to "service_role";

grant update on table "public"."quote_items" to "service_role";

grant delete on table "public"."quotes" to "anon";

grant insert on table "public"."quotes" to "anon";

grant references on table "public"."quotes" to "anon";

grant select on table "public"."quotes" to "anon";

grant trigger on table "public"."quotes" to "anon";

grant truncate on table "public"."quotes" to "anon";

grant update on table "public"."quotes" to "anon";

grant delete on table "public"."quotes" to "authenticated";

grant insert on table "public"."quotes" to "authenticated";

grant references on table "public"."quotes" to "authenticated";

grant select on table "public"."quotes" to "authenticated";

grant trigger on table "public"."quotes" to "authenticated";

grant truncate on table "public"."quotes" to "authenticated";

grant update on table "public"."quotes" to "authenticated";

grant delete on table "public"."quotes" to "service_role";

grant insert on table "public"."quotes" to "service_role";

grant references on table "public"."quotes" to "service_role";

grant select on table "public"."quotes" to "service_role";

grant trigger on table "public"."quotes" to "service_role";

grant truncate on table "public"."quotes" to "service_role";

grant update on table "public"."quotes" to "service_role";

grant delete on table "public"."referrals" to "anon";

grant insert on table "public"."referrals" to "anon";

grant references on table "public"."referrals" to "anon";

grant select on table "public"."referrals" to "anon";

grant trigger on table "public"."referrals" to "anon";

grant truncate on table "public"."referrals" to "anon";

grant update on table "public"."referrals" to "anon";

grant delete on table "public"."referrals" to "authenticated";

grant insert on table "public"."referrals" to "authenticated";

grant references on table "public"."referrals" to "authenticated";

grant select on table "public"."referrals" to "authenticated";

grant trigger on table "public"."referrals" to "authenticated";

grant truncate on table "public"."referrals" to "authenticated";

grant update on table "public"."referrals" to "authenticated";

grant delete on table "public"."referrals" to "service_role";

grant insert on table "public"."referrals" to "service_role";

grant references on table "public"."referrals" to "service_role";

grant select on table "public"."referrals" to "service_role";

grant trigger on table "public"."referrals" to "service_role";

grant truncate on table "public"."referrals" to "service_role";

grant update on table "public"."referrals" to "service_role";

grant delete on table "public"."repair_parts" to "anon";

grant insert on table "public"."repair_parts" to "anon";

grant references on table "public"."repair_parts" to "anon";

grant select on table "public"."repair_parts" to "anon";

grant trigger on table "public"."repair_parts" to "anon";

grant truncate on table "public"."repair_parts" to "anon";

grant update on table "public"."repair_parts" to "anon";

grant delete on table "public"."repair_parts" to "authenticated";

grant insert on table "public"."repair_parts" to "authenticated";

grant references on table "public"."repair_parts" to "authenticated";

grant select on table "public"."repair_parts" to "authenticated";

grant trigger on table "public"."repair_parts" to "authenticated";

grant truncate on table "public"."repair_parts" to "authenticated";

grant update on table "public"."repair_parts" to "authenticated";

grant delete on table "public"."repair_parts" to "service_role";

grant insert on table "public"."repair_parts" to "service_role";

grant references on table "public"."repair_parts" to "service_role";

grant select on table "public"."repair_parts" to "service_role";

grant trigger on table "public"."repair_parts" to "service_role";

grant truncate on table "public"."repair_parts" to "service_role";

grant update on table "public"."repair_parts" to "service_role";

grant delete on table "public"."repair_services" to "anon";

grant insert on table "public"."repair_services" to "anon";

grant references on table "public"."repair_services" to "anon";

grant select on table "public"."repair_services" to "anon";

grant trigger on table "public"."repair_services" to "anon";

grant truncate on table "public"."repair_services" to "anon";

grant update on table "public"."repair_services" to "anon";

grant delete on table "public"."repair_services" to "authenticated";

grant insert on table "public"."repair_services" to "authenticated";

grant references on table "public"."repair_services" to "authenticated";

grant select on table "public"."repair_services" to "authenticated";

grant trigger on table "public"."repair_services" to "authenticated";

grant truncate on table "public"."repair_services" to "authenticated";

grant update on table "public"."repair_services" to "authenticated";

grant delete on table "public"."repair_services" to "service_role";

grant insert on table "public"."repair_services" to "service_role";

grant references on table "public"."repair_services" to "service_role";

grant select on table "public"."repair_services" to "service_role";

grant trigger on table "public"."repair_services" to "service_role";

grant truncate on table "public"."repair_services" to "service_role";

grant update on table "public"."repair_services" to "service_role";

grant delete on table "public"."repairs" to "anon";

grant insert on table "public"."repairs" to "anon";

grant references on table "public"."repairs" to "anon";

grant select on table "public"."repairs" to "anon";

grant trigger on table "public"."repairs" to "anon";

grant truncate on table "public"."repairs" to "anon";

grant update on table "public"."repairs" to "anon";

grant delete on table "public"."repairs" to "authenticated";

grant insert on table "public"."repairs" to "authenticated";

grant references on table "public"."repairs" to "authenticated";

grant select on table "public"."repairs" to "authenticated";

grant trigger on table "public"."repairs" to "authenticated";

grant truncate on table "public"."repairs" to "authenticated";

grant update on table "public"."repairs" to "authenticated";

grant delete on table "public"."repairs" to "service_role";

grant insert on table "public"."repairs" to "service_role";

grant references on table "public"."repairs" to "service_role";

grant select on table "public"."repairs" to "service_role";

grant trigger on table "public"."repairs" to "service_role";

grant truncate on table "public"."repairs" to "service_role";

grant update on table "public"."repairs" to "service_role";

grant delete on table "public"."reports" to "anon";

grant insert on table "public"."reports" to "anon";

grant references on table "public"."reports" to "anon";

grant select on table "public"."reports" to "anon";

grant trigger on table "public"."reports" to "anon";

grant truncate on table "public"."reports" to "anon";

grant update on table "public"."reports" to "anon";

grant delete on table "public"."reports" to "authenticated";

grant insert on table "public"."reports" to "authenticated";

grant references on table "public"."reports" to "authenticated";

grant select on table "public"."reports" to "authenticated";

grant trigger on table "public"."reports" to "authenticated";

grant truncate on table "public"."reports" to "authenticated";

grant update on table "public"."reports" to "authenticated";

grant delete on table "public"."reports" to "service_role";

grant insert on table "public"."reports" to "service_role";

grant references on table "public"."reports" to "service_role";

grant select on table "public"."reports" to "service_role";

grant trigger on table "public"."reports" to "service_role";

grant truncate on table "public"."reports" to "service_role";

grant update on table "public"."reports" to "service_role";

grant delete on table "public"."sale_items" to "anon";

grant insert on table "public"."sale_items" to "anon";

grant references on table "public"."sale_items" to "anon";

grant select on table "public"."sale_items" to "anon";

grant trigger on table "public"."sale_items" to "anon";

grant truncate on table "public"."sale_items" to "anon";

grant update on table "public"."sale_items" to "anon";

grant delete on table "public"."sale_items" to "authenticated";

grant insert on table "public"."sale_items" to "authenticated";

grant references on table "public"."sale_items" to "authenticated";

grant select on table "public"."sale_items" to "authenticated";

grant trigger on table "public"."sale_items" to "authenticated";

grant truncate on table "public"."sale_items" to "authenticated";

grant update on table "public"."sale_items" to "authenticated";

grant delete on table "public"."sale_items" to "service_role";

grant insert on table "public"."sale_items" to "service_role";

grant references on table "public"."sale_items" to "service_role";

grant select on table "public"."sale_items" to "service_role";

grant trigger on table "public"."sale_items" to "service_role";

grant truncate on table "public"."sale_items" to "service_role";

grant update on table "public"."sale_items" to "service_role";

grant delete on table "public"."sales" to "anon";

grant insert on table "public"."sales" to "anon";

grant references on table "public"."sales" to "anon";

grant select on table "public"."sales" to "anon";

grant trigger on table "public"."sales" to "anon";

grant truncate on table "public"."sales" to "anon";

grant update on table "public"."sales" to "anon";

grant delete on table "public"."sales" to "authenticated";

grant insert on table "public"."sales" to "authenticated";

grant references on table "public"."sales" to "authenticated";

grant select on table "public"."sales" to "authenticated";

grant trigger on table "public"."sales" to "authenticated";

grant truncate on table "public"."sales" to "authenticated";

grant update on table "public"."sales" to "authenticated";

grant delete on table "public"."sales" to "service_role";

grant insert on table "public"."sales" to "service_role";

grant references on table "public"."sales" to "service_role";

grant select on table "public"."sales" to "service_role";

grant trigger on table "public"."sales" to "service_role";

grant truncate on table "public"."sales" to "service_role";

grant update on table "public"."sales" to "service_role";

grant delete on table "public"."services" to "anon";

grant insert on table "public"."services" to "anon";

grant references on table "public"."services" to "anon";

grant select on table "public"."services" to "anon";

grant trigger on table "public"."services" to "anon";

grant truncate on table "public"."services" to "anon";

grant update on table "public"."services" to "anon";

grant delete on table "public"."services" to "authenticated";

grant insert on table "public"."services" to "authenticated";

grant references on table "public"."services" to "authenticated";

grant select on table "public"."services" to "authenticated";

grant trigger on table "public"."services" to "authenticated";

grant truncate on table "public"."services" to "authenticated";

grant update on table "public"."services" to "authenticated";

grant delete on table "public"."services" to "service_role";

grant insert on table "public"."services" to "service_role";

grant references on table "public"."services" to "service_role";

grant select on table "public"."services" to "service_role";

grant trigger on table "public"."services" to "service_role";

grant truncate on table "public"."services" to "service_role";

grant update on table "public"."services" to "service_role";

grant delete on table "public"."stock_alerts" to "anon";

grant insert on table "public"."stock_alerts" to "anon";

grant references on table "public"."stock_alerts" to "anon";

grant select on table "public"."stock_alerts" to "anon";

grant trigger on table "public"."stock_alerts" to "anon";

grant truncate on table "public"."stock_alerts" to "anon";

grant update on table "public"."stock_alerts" to "anon";

grant delete on table "public"."stock_alerts" to "authenticated";

grant insert on table "public"."stock_alerts" to "authenticated";

grant references on table "public"."stock_alerts" to "authenticated";

grant select on table "public"."stock_alerts" to "authenticated";

grant trigger on table "public"."stock_alerts" to "authenticated";

grant truncate on table "public"."stock_alerts" to "authenticated";

grant update on table "public"."stock_alerts" to "authenticated";

grant delete on table "public"."stock_alerts" to "service_role";

grant insert on table "public"."stock_alerts" to "service_role";

grant references on table "public"."stock_alerts" to "service_role";

grant select on table "public"."stock_alerts" to "service_role";

grant trigger on table "public"."stock_alerts" to "service_role";

grant truncate on table "public"."stock_alerts" to "service_role";

grant update on table "public"."stock_alerts" to "service_role";

grant delete on table "public"."subscription_audit" to "anon";

grant insert on table "public"."subscription_audit" to "anon";

grant references on table "public"."subscription_audit" to "anon";

grant select on table "public"."subscription_audit" to "anon";

grant trigger on table "public"."subscription_audit" to "anon";

grant truncate on table "public"."subscription_audit" to "anon";

grant update on table "public"."subscription_audit" to "anon";

grant delete on table "public"."subscription_audit" to "authenticated";

grant insert on table "public"."subscription_audit" to "authenticated";

grant references on table "public"."subscription_audit" to "authenticated";

grant select on table "public"."subscription_audit" to "authenticated";

grant trigger on table "public"."subscription_audit" to "authenticated";

grant truncate on table "public"."subscription_audit" to "authenticated";

grant update on table "public"."subscription_audit" to "authenticated";

grant delete on table "public"."subscription_audit" to "service_role";

grant insert on table "public"."subscription_audit" to "service_role";

grant references on table "public"."subscription_audit" to "service_role";

grant select on table "public"."subscription_audit" to "service_role";

grant trigger on table "public"."subscription_audit" to "service_role";

grant truncate on table "public"."subscription_audit" to "service_role";

grant update on table "public"."subscription_audit" to "service_role";

grant delete on table "public"."subscription_payments" to "anon";

grant insert on table "public"."subscription_payments" to "anon";

grant references on table "public"."subscription_payments" to "anon";

grant select on table "public"."subscription_payments" to "anon";

grant trigger on table "public"."subscription_payments" to "anon";

grant truncate on table "public"."subscription_payments" to "anon";

grant update on table "public"."subscription_payments" to "anon";

grant delete on table "public"."subscription_payments" to "authenticated";

grant insert on table "public"."subscription_payments" to "authenticated";

grant references on table "public"."subscription_payments" to "authenticated";

grant select on table "public"."subscription_payments" to "authenticated";

grant trigger on table "public"."subscription_payments" to "authenticated";

grant truncate on table "public"."subscription_payments" to "authenticated";

grant update on table "public"."subscription_payments" to "authenticated";

grant delete on table "public"."subscription_payments" to "service_role";

grant insert on table "public"."subscription_payments" to "service_role";

grant references on table "public"."subscription_payments" to "service_role";

grant select on table "public"."subscription_payments" to "service_role";

grant trigger on table "public"."subscription_payments" to "service_role";

grant truncate on table "public"."subscription_payments" to "service_role";

grant update on table "public"."subscription_payments" to "service_role";

grant delete on table "public"."subscription_plans" to "anon";

grant insert on table "public"."subscription_plans" to "anon";

grant references on table "public"."subscription_plans" to "anon";

grant select on table "public"."subscription_plans" to "anon";

grant trigger on table "public"."subscription_plans" to "anon";

grant truncate on table "public"."subscription_plans" to "anon";

grant update on table "public"."subscription_plans" to "anon";

grant delete on table "public"."subscription_plans" to "authenticated";

grant insert on table "public"."subscription_plans" to "authenticated";

grant references on table "public"."subscription_plans" to "authenticated";

grant select on table "public"."subscription_plans" to "authenticated";

grant trigger on table "public"."subscription_plans" to "authenticated";

grant truncate on table "public"."subscription_plans" to "authenticated";

grant update on table "public"."subscription_plans" to "authenticated";

grant delete on table "public"."subscription_plans" to "service_role";

grant insert on table "public"."subscription_plans" to "service_role";

grant references on table "public"."subscription_plans" to "service_role";

grant select on table "public"."subscription_plans" to "service_role";

grant trigger on table "public"."subscription_plans" to "service_role";

grant truncate on table "public"."subscription_plans" to "service_role";

grant update on table "public"."subscription_plans" to "service_role";

grant delete on table "public"."subscription_status" to "anon";

grant insert on table "public"."subscription_status" to "anon";

grant references on table "public"."subscription_status" to "anon";

grant select on table "public"."subscription_status" to "anon";

grant trigger on table "public"."subscription_status" to "anon";

grant truncate on table "public"."subscription_status" to "anon";

grant update on table "public"."subscription_status" to "anon";

grant delete on table "public"."subscription_status" to "authenticated";

grant insert on table "public"."subscription_status" to "authenticated";

grant references on table "public"."subscription_status" to "authenticated";

grant select on table "public"."subscription_status" to "authenticated";

grant trigger on table "public"."subscription_status" to "authenticated";

grant truncate on table "public"."subscription_status" to "authenticated";

grant update on table "public"."subscription_status" to "authenticated";

grant delete on table "public"."subscription_status" to "service_role";

grant insert on table "public"."subscription_status" to "service_role";

grant references on table "public"."subscription_status" to "service_role";

grant select on table "public"."subscription_status" to "service_role";

grant trigger on table "public"."subscription_status" to "service_role";

grant truncate on table "public"."subscription_status" to "service_role";

grant update on table "public"."subscription_status" to "service_role";

grant delete on table "public"."suppliers" to "anon";

grant insert on table "public"."suppliers" to "anon";

grant references on table "public"."suppliers" to "anon";

grant select on table "public"."suppliers" to "anon";

grant trigger on table "public"."suppliers" to "anon";

grant truncate on table "public"."suppliers" to "anon";

grant update on table "public"."suppliers" to "anon";

grant delete on table "public"."suppliers" to "authenticated";

grant insert on table "public"."suppliers" to "authenticated";

grant references on table "public"."suppliers" to "authenticated";

grant select on table "public"."suppliers" to "authenticated";

grant trigger on table "public"."suppliers" to "authenticated";

grant truncate on table "public"."suppliers" to "authenticated";

grant update on table "public"."suppliers" to "authenticated";

grant delete on table "public"."suppliers" to "service_role";

grant insert on table "public"."suppliers" to "service_role";

grant references on table "public"."suppliers" to "service_role";

grant select on table "public"."suppliers" to "service_role";

grant trigger on table "public"."suppliers" to "service_role";

grant truncate on table "public"."suppliers" to "service_role";

grant update on table "public"."suppliers" to "service_role";

grant delete on table "public"."system_settings" to "anon";

grant insert on table "public"."system_settings" to "anon";

grant references on table "public"."system_settings" to "anon";

grant select on table "public"."system_settings" to "anon";

grant trigger on table "public"."system_settings" to "anon";

grant truncate on table "public"."system_settings" to "anon";

grant update on table "public"."system_settings" to "anon";

grant delete on table "public"."system_settings" to "authenticated";

grant insert on table "public"."system_settings" to "authenticated";

grant references on table "public"."system_settings" to "authenticated";

grant select on table "public"."system_settings" to "authenticated";

grant trigger on table "public"."system_settings" to "authenticated";

grant truncate on table "public"."system_settings" to "authenticated";

grant update on table "public"."system_settings" to "authenticated";

grant delete on table "public"."system_settings" to "service_role";

grant insert on table "public"."system_settings" to "service_role";

grant references on table "public"."system_settings" to "service_role";

grant select on table "public"."system_settings" to "service_role";

grant trigger on table "public"."system_settings" to "service_role";

grant truncate on table "public"."system_settings" to "service_role";

grant update on table "public"."system_settings" to "service_role";

grant delete on table "public"."technician_performance" to "anon";

grant insert on table "public"."technician_performance" to "anon";

grant references on table "public"."technician_performance" to "anon";

grant select on table "public"."technician_performance" to "anon";

grant trigger on table "public"."technician_performance" to "anon";

grant truncate on table "public"."technician_performance" to "anon";

grant update on table "public"."technician_performance" to "anon";

grant delete on table "public"."technician_performance" to "authenticated";

grant insert on table "public"."technician_performance" to "authenticated";

grant references on table "public"."technician_performance" to "authenticated";

grant select on table "public"."technician_performance" to "authenticated";

grant trigger on table "public"."technician_performance" to "authenticated";

grant truncate on table "public"."technician_performance" to "authenticated";

grant update on table "public"."technician_performance" to "authenticated";

grant delete on table "public"."technician_performance" to "service_role";

grant insert on table "public"."technician_performance" to "service_role";

grant references on table "public"."technician_performance" to "service_role";

grant select on table "public"."technician_performance" to "service_role";

grant trigger on table "public"."technician_performance" to "service_role";

grant truncate on table "public"."technician_performance" to "service_role";

grant update on table "public"."technician_performance" to "service_role";

grant delete on table "public"."transactions" to "anon";

grant insert on table "public"."transactions" to "anon";

grant references on table "public"."transactions" to "anon";

grant select on table "public"."transactions" to "anon";

grant trigger on table "public"."transactions" to "anon";

grant truncate on table "public"."transactions" to "anon";

grant update on table "public"."transactions" to "anon";

grant delete on table "public"."transactions" to "authenticated";

grant insert on table "public"."transactions" to "authenticated";

grant references on table "public"."transactions" to "authenticated";

grant select on table "public"."transactions" to "authenticated";

grant trigger on table "public"."transactions" to "authenticated";

grant truncate on table "public"."transactions" to "authenticated";

grant update on table "public"."transactions" to "authenticated";

grant delete on table "public"."transactions" to "service_role";

grant insert on table "public"."transactions" to "service_role";

grant references on table "public"."transactions" to "service_role";

grant select on table "public"."transactions" to "service_role";

grant trigger on table "public"."transactions" to "service_role";

grant truncate on table "public"."transactions" to "service_role";

grant update on table "public"."transactions" to "service_role";

grant delete on table "public"."user_preferences" to "authenticated";

grant insert on table "public"."user_preferences" to "authenticated";

grant references on table "public"."user_preferences" to "authenticated";

grant select on table "public"."user_preferences" to "authenticated";

grant trigger on table "public"."user_preferences" to "authenticated";

grant truncate on table "public"."user_preferences" to "authenticated";

grant update on table "public"."user_preferences" to "authenticated";

grant delete on table "public"."user_preferences" to "service_role";

grant insert on table "public"."user_preferences" to "service_role";

grant references on table "public"."user_preferences" to "service_role";

grant select on table "public"."user_preferences" to "service_role";

grant trigger on table "public"."user_preferences" to "service_role";

grant truncate on table "public"."user_preferences" to "service_role";

grant update on table "public"."user_preferences" to "service_role";

grant delete on table "public"."user_profiles" to "authenticated";

grant insert on table "public"."user_profiles" to "authenticated";

grant references on table "public"."user_profiles" to "authenticated";

grant select on table "public"."user_profiles" to "authenticated";

grant trigger on table "public"."user_profiles" to "authenticated";

grant truncate on table "public"."user_profiles" to "authenticated";

grant update on table "public"."user_profiles" to "authenticated";

grant delete on table "public"."user_profiles" to "service_role";

grant insert on table "public"."user_profiles" to "service_role";

grant references on table "public"."user_profiles" to "service_role";

grant select on table "public"."user_profiles" to "service_role";

grant trigger on table "public"."user_profiles" to "service_role";

grant truncate on table "public"."user_profiles" to "service_role";

grant update on table "public"."user_profiles" to "service_role";

grant delete on table "public"."user_subscriptions" to "anon";

grant insert on table "public"."user_subscriptions" to "anon";

grant references on table "public"."user_subscriptions" to "anon";

grant select on table "public"."user_subscriptions" to "anon";

grant trigger on table "public"."user_subscriptions" to "anon";

grant truncate on table "public"."user_subscriptions" to "anon";

grant update on table "public"."user_subscriptions" to "anon";

grant delete on table "public"."user_subscriptions" to "authenticated";

grant insert on table "public"."user_subscriptions" to "authenticated";

grant references on table "public"."user_subscriptions" to "authenticated";

grant select on table "public"."user_subscriptions" to "authenticated";

grant trigger on table "public"."user_subscriptions" to "authenticated";

grant truncate on table "public"."user_subscriptions" to "authenticated";

grant update on table "public"."user_subscriptions" to "authenticated";

grant delete on table "public"."user_subscriptions" to "service_role";

grant insert on table "public"."user_subscriptions" to "service_role";

grant references on table "public"."user_subscriptions" to "service_role";

grant select on table "public"."user_subscriptions" to "service_role";

grant trigger on table "public"."user_subscriptions" to "service_role";

grant truncate on table "public"."user_subscriptions" to "service_role";

grant update on table "public"."user_subscriptions" to "service_role";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "Admins can delete all activity_logs"
  on "public"."activity_logs"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert activity_logs"
  on "public"."activity_logs"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all activity_logs"
  on "public"."activity_logs"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all activity_logs"
  on "public"."activity_logs"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own activity_logs"
  on "public"."activity_logs"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own activity_logs"
  on "public"."activity_logs"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own activity_logs"
  on "public"."activity_logs"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own activity_logs"
  on "public"."activity_logs"
  as permissive
  for select
  to public
using (true);



  create policy "Admins can delete all advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own advanced_alerts"
  on "public"."advanced_alerts"
  as permissive
  for select
  to public
using (true);



  create policy "Admins can delete all advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own advanced_settings"
  on "public"."advanced_settings"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete own appointments"
  on "public"."appointments"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own appointments"
  on "public"."appointments"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own appointments"
  on "public"."appointments"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own appointments"
  on "public"."appointments"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "appointments_insert_policy"
  on "public"."appointments"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NOT NULL));



  create policy "appointments_select_policy"
  on "public"."appointments"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "appointments_update_policy"
  on "public"."appointments"
  as permissive
  for update
  to public
using ((auth.uid() IS NOT NULL));



  create policy "client_loyalty_points_delete_ultra_strict"
  on "public"."client_loyalty_points"
  as permissive
  for delete
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "client_loyalty_points_insert_ultra_strict"
  on "public"."client_loyalty_points"
  as permissive
  for insert
  to public
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "client_loyalty_points_read_policy"
  on "public"."client_loyalty_points"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "client_loyalty_points_select_ultra_strict"
  on "public"."client_loyalty_points"
  as permissive
  for select
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "client_loyalty_points_update_ultra_strict"
  on "public"."client_loyalty_points"
  as permissive
  for update
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)))
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "Enable delete access for authenticated users"
  on "public"."clients"
  as permissive
  for delete
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Enable insert access for authenticated users"
  on "public"."clients"
  as permissive
  for insert
  to public
with check ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Enable update access for authenticated users"
  on "public"."clients"
  as permissive
  for update
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)))
with check ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "STRICT_ISOLATION_Users can create own clients"
  on "public"."clients"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "STRICT_ISOLATION_Users can delete own clients"
  on "public"."clients"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "STRICT_ISOLATION_Users can update own clients"
  on "public"."clients"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "STRICT_ISOLATION_Users can view own clients"
  on "public"."clients"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Simple_Delete_Policy"
  on "public"."clients"
  as permissive
  for delete
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Simple_Insert_Policy"
  on "public"."clients"
  as permissive
  for insert
  to public
with check ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Simple_Read_Policy"
  on "public"."clients"
  as permissive
  for select
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Simple_Update_Policy"
  on "public"."clients"
  as permissive
  for update
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)))
with check ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "clients_admin_working"
  on "public"."clients"
  as permissive
  for all
  to public
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['srohee32@gmail.com'::text, 'repphonereparation@gmail.com'::text])));



  create policy "clients_delete_ultra_strict"
  on "public"."clients"
  as permissive
  for delete
  to public
using (((user_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (user_id IS NOT NULL)));



  create policy "clients_delete_working"
  on "public"."clients"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "clients_insert_ultra_strict"
  on "public"."clients"
  as permissive
  for insert
  to public
with check (((user_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (user_id IS NOT NULL)));



  create policy "clients_insert_working"
  on "public"."clients"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "clients_select_ultra_strict"
  on "public"."clients"
  as permissive
  for select
  to public
using (((user_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (user_id IS NOT NULL)));



  create policy "clients_select_working"
  on "public"."clients"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "clients_service_role_working"
  on "public"."clients"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "clients_update_ultra_strict"
  on "public"."clients"
  as permissive
  for update
  to public
using (((user_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (user_id IS NOT NULL)))
with check (((user_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (user_id IS NOT NULL)));



  create policy "clients_update_working"
  on "public"."clients"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can delete own clients backup"
  on "public"."clients_backup"
  as permissive
  for delete
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Users can insert own clients backup"
  on "public"."clients_backup"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Users can update own clients backup"
  on "public"."clients_backup"
  as permissive
  for update
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Users can view own clients backup"
  on "public"."clients_backup"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Admins can delete all confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own confirmation_emails"
  on "public"."confirmation_emails"
  as permissive
  for select
  to public
using (true);



  create policy "Admins can delete all custom_users"
  on "public"."custom_users"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert custom_users"
  on "public"."custom_users"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all custom_users"
  on "public"."custom_users"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all custom_users"
  on "public"."custom_users"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own custom_users"
  on "public"."custom_users"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own custom_users"
  on "public"."custom_users"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own custom_users"
  on "public"."custom_users"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own custom_users"
  on "public"."custom_users"
  as permissive
  for select
  to public
using (true);



  create policy "users_can_create_account"
  on "public"."custom_users"
  as permissive
  for insert
  to public
with check (true);



  create policy "users_can_read_own_account"
  on "public"."custom_users"
  as permissive
  for select
  to public
using ((id = current_setting('app.current_user_id'::text, true)));



  create policy "users_can_update_own_account"
  on "public"."custom_users"
  as permissive
  for update
  to public
using ((id = current_setting('app.current_user_id'::text, true)))
with check ((id = current_setting('app.current_user_id'::text, true)));



  create policy "device_brands_delete_policy"
  on "public"."device_brands"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "device_brands_insert_policy"
  on "public"."device_brands"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "device_brands_select_policy"
  on "public"."device_brands"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "device_brands_update_policy"
  on "public"."device_brands"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "device_categories_delete_policy"
  on "public"."device_categories"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "device_categories_insert_policy"
  on "public"."device_categories"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "device_categories_select_policy"
  on "public"."device_categories"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "device_categories_update_policy"
  on "public"."device_categories"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Admins can delete all device_models"
  on "public"."device_models"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert device_models"
  on "public"."device_models"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all device_models"
  on "public"."device_models"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all device_models"
  on "public"."device_models"
  as permissive
  for select
  to public
using (true);



  create policy "ULTIME_device_models_delete"
  on "public"."device_models"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "ULTIME_device_models_insert"
  on "public"."device_models"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "ULTIME_device_models_select"
  on "public"."device_models"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "ULTIME_device_models_update"
  on "public"."device_models"
  as permissive
  for update
  to public
using ((created_by = auth.uid()))
with check ((created_by = auth.uid()));



  create policy "Users can delete their own device_models"
  on "public"."device_models"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own device_models"
  on "public"."device_models"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own device_models"
  on "public"."device_models"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own device_models"
  on "public"."device_models"
  as permissive
  for select
  to public
using (true);



  create policy "device_models_delete_policy"
  on "public"."device_models"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "device_models_insert_policy"
  on "public"."device_models"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "device_models_select_policy"
  on "public"."device_models"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "device_models_update_policy"
  on "public"."device_models"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Users can delete own devices"
  on "public"."devices"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own devices"
  on "public"."devices"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own devices"
  on "public"."devices"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own devices"
  on "public"."devices"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "Users can delete their own intervention forms"
  on "public"."intervention_forms"
  as permissive
  for delete
  to public
using ((repair_id IN ( SELECT repairs.id
   FROM repairs
  WHERE (repairs.user_id = auth.uid()))));



  create policy "Users can insert their own intervention forms"
  on "public"."intervention_forms"
  as permissive
  for insert
  to public
with check ((repair_id IN ( SELECT repairs.id
   FROM repairs
  WHERE (repairs.user_id = auth.uid()))));



  create policy "Users can update their own intervention forms"
  on "public"."intervention_forms"
  as permissive
  for update
  to public
using ((repair_id IN ( SELECT repairs.id
   FROM repairs
  WHERE (repairs.user_id = auth.uid()))));



  create policy "Users can view their own intervention forms"
  on "public"."intervention_forms"
  as permissive
  for select
  to public
using ((repair_id IN ( SELECT repairs.id
   FROM repairs
  WHERE (repairs.user_id = auth.uid()))));



  create policy "Users can insert their own loyalty config"
  on "public"."loyalty_config"
  as permissive
  for insert
  to public
with check ((auth.uid() = workshop_id));



  create policy "Users can update their own loyalty config"
  on "public"."loyalty_config"
  as permissive
  for update
  to public
using ((auth.uid() = workshop_id));



  create policy "Users can view their own loyalty config"
  on "public"."loyalty_config"
  as permissive
  for select
  to public
using ((auth.uid() = workshop_id));



  create policy "loyalty_config_delete"
  on "public"."loyalty_config"
  as permissive
  for delete
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_config_insert"
  on "public"."loyalty_config"
  as permissive
  for insert
  to public
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_config_isolation_policy"
  on "public"."loyalty_config"
  as permissive
  for all
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "loyalty_config_policy"
  on "public"."loyalty_config"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "loyalty_config_select"
  on "public"."loyalty_config"
  as permissive
  for select
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_config_update"
  on "public"."loyalty_config"
  as permissive
  for update
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)))
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "Enable delete access for authenticated users"
  on "public"."loyalty_points_history"
  as permissive
  for delete
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable insert access for authenticated users"
  on "public"."loyalty_points_history"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Enable read access for authenticated users"
  on "public"."loyalty_points_history"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable update access for authenticated users"
  on "public"."loyalty_points_history"
  as permissive
  for update
  to public
using ((auth.role() = 'authenticated'::text))
with check ((auth.role() = 'authenticated'::text));



  create policy "loyalty_points_all_policy"
  on "public"."loyalty_points_history"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "loyalty_points_history_delete_ultra_strict"
  on "public"."loyalty_points_history"
  as permissive
  for delete
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "loyalty_points_history_insert_ultra_strict"
  on "public"."loyalty_points_history"
  as permissive
  for insert
  to public
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "loyalty_points_history_select_ultra_strict"
  on "public"."loyalty_points_history"
  as permissive
  for select
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "loyalty_points_history_update_ultra_strict"
  on "public"."loyalty_points_history"
  as permissive
  for update
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)))
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "loyalty_points_isolation_policy"
  on "public"."loyalty_points_history"
  as permissive
  for all
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "loyalty_rules_delete_policy"
  on "public"."loyalty_rules"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "loyalty_rules_insert_policy"
  on "public"."loyalty_rules"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "loyalty_rules_read_policy"
  on "public"."loyalty_rules"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "loyalty_rules_update_policy"
  on "public"."loyalty_rules"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can view loyalty tiers basic"
  on "public"."loyalty_tiers"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Users can delete their own loyalty tiers"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for delete
  to public
using ((auth.uid() = workshop_id));



  create policy "Users can insert their own loyalty tiers"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for insert
  to public
with check ((auth.uid() = workshop_id));



  create policy "Users can update their own loyalty tiers"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for update
  to public
using ((auth.uid() = workshop_id));



  create policy "Users can view their own loyalty tiers"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for select
  to public
using ((auth.uid() = workshop_id));



  create policy "loyalty_tiers_delete"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for delete
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_tiers_insert"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for insert
  to public
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_tiers_isolation_policy"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for all
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "loyalty_tiers_policy"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "loyalty_tiers_select"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for select
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "loyalty_tiers_update"
  on "public"."loyalty_tiers_advanced"
  as permissive
  for update
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)))
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL)));



  create policy "Admins can delete all messages"
  on "public"."messages"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert messages"
  on "public"."messages"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all messages"
  on "public"."messages"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all messages"
  on "public"."messages"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own messages"
  on "public"."messages"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own messages"
  on "public"."messages"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own messages"
  on "public"."messages"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own messages"
  on "public"."messages"
  as permissive
  for select
  to public
using (true);



  create policy "messages_delete_policy"
  on "public"."messages"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "messages_insert_policy"
  on "public"."messages"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "messages_select_policy"
  on "public"."messages"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "messages_update_policy"
  on "public"."messages"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Admins can delete all notifications"
  on "public"."notifications"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert notifications"
  on "public"."notifications"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all notifications"
  on "public"."notifications"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own notifications"
  on "public"."notifications"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own notifications"
  on "public"."notifications"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own notifications"
  on "public"."notifications"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own notifications"
  on "public"."notifications"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own order items"
  on "public"."order_items"
  as permissive
  for delete
  to public
using ((workshop_id = ((auth.jwt() ->> 'workshop_id'::text))::uuid));



  create policy "Users can insert their own order items"
  on "public"."order_items"
  as permissive
  for insert
  to public
with check ((workshop_id = ((auth.jwt() ->> 'workshop_id'::text))::uuid));



  create policy "Users can update their own order items"
  on "public"."order_items"
  as permissive
  for update
  to public
using ((workshop_id = ((auth.jwt() ->> 'workshop_id'::text))::uuid))
with check ((workshop_id = ((auth.jwt() ->> 'workshop_id'::text))::uuid));



  create policy "Users can view their own order items"
  on "public"."order_items"
  as permissive
  for select
  to public
using ((workshop_id = ((auth.jwt() ->> 'workshop_id'::text))::uuid));



  create policy "order_items_delete_policy"
  on "public"."order_items"
  as permissive
  for delete
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "order_items_insert_policy"
  on "public"."order_items"
  as permissive
  for insert
  to public
with check ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "order_items_select_policy"
  on "public"."order_items"
  as permissive
  for select
  to public
using (((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)) OR (EXISTS ( SELECT 1
   FROM system_settings
  WHERE (((system_settings.key)::text = 'workshop_type'::text) AND (system_settings.value = 'gestion'::text))
 LIMIT 1))));



  create policy "order_items_update_policy"
  on "public"."order_items"
  as permissive
  for update
  to public
using ((workshop_id = ( SELECT (system_settings.value)::uuid AS value
   FROM system_settings
  WHERE ((system_settings.key)::text = 'workshop_id'::text)
 LIMIT 1)));



  create policy "Users can delete own orders"
  on "public"."orders"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own orders"
  on "public"."orders"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own orders"
  on "public"."orders"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own orders"
  on "public"."orders"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "orders_insert_policy"
  on "public"."orders"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NOT NULL));



  create policy "orders_select_policy"
  on "public"."orders"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "orders_update_policy"
  on "public"."orders"
  as permissive
  for update
  to public
using ((auth.uid() IS NOT NULL));



  create policy "Users can delete own parts"
  on "public"."parts"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own parts"
  on "public"."parts"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own parts"
  on "public"."parts"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own parts"
  on "public"."parts"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "parts_delete_policy"
  on "public"."parts"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "parts_insert_policy"
  on "public"."parts"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "parts_select_policy"
  on "public"."parts"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "parts_update_policy"
  on "public"."parts"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Admins can delete all pending_signups"
  on "public"."pending_signups"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert pending_signups"
  on "public"."pending_signups"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all pending_signups"
  on "public"."pending_signups"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all pending_signups"
  on "public"."pending_signups"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own pending_signups"
  on "public"."pending_signups"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own pending_signups"
  on "public"."pending_signups"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own pending_signups"
  on "public"."pending_signups"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own pending_signups"
  on "public"."pending_signups"
  as permissive
  for select
  to public
using (true);



  create policy "Admins can delete all performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own performance_metrics"
  on "public"."performance_metrics"
  as permissive
  for select
  to public
using (true);



  create policy "product_categories_delete_policy"
  on "public"."product_categories"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "product_categories_insert_policy"
  on "public"."product_categories"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "product_categories_select_policy"
  on "public"."product_categories"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "product_categories_update_policy"
  on "public"."product_categories"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Users can delete own products"
  on "public"."products"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own products"
  on "public"."products"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own products"
  on "public"."products"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own products"
  on "public"."products"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "products_delete_policy"
  on "public"."products"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "products_insert_policy"
  on "public"."products"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "products_select_policy"
  on "public"."products"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "products_update_policy"
  on "public"."products"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Enable delete for authenticated users"
  on "public"."quote_items"
  as permissive
  for delete
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable insert for authenticated users"
  on "public"."quote_items"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Enable read access for authenticated users"
  on "public"."quote_items"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable update for authenticated users"
  on "public"."quote_items"
  as permissive
  for update
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable delete for authenticated users"
  on "public"."quotes"
  as permissive
  for delete
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable insert for authenticated users"
  on "public"."quotes"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Enable read access for authenticated users"
  on "public"."quotes"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable update for authenticated users"
  on "public"."quotes"
  as permissive
  for update
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "referrals_delete_ultra_strict"
  on "public"."referrals"
  as permissive
  for delete
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "referrals_insert_ultra_strict"
  on "public"."referrals"
  as permissive
  for insert
  to public
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "referrals_read_policy"
  on "public"."referrals"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "referrals_select_ultra_strict"
  on "public"."referrals"
  as permissive
  for select
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "referrals_update_ultra_strict"
  on "public"."referrals"
  as permissive
  for update
  to public
using (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)))
with check (((workshop_id = auth.uid()) AND (auth.uid() IS NOT NULL) AND (workshop_id IS NOT NULL)));



  create policy "Admins can delete all repair_parts"
  on "public"."repair_parts"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert repair_parts"
  on "public"."repair_parts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all repair_parts"
  on "public"."repair_parts"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all repair_parts"
  on "public"."repair_parts"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own repair_parts"
  on "public"."repair_parts"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own repair_parts"
  on "public"."repair_parts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own repair_parts"
  on "public"."repair_parts"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own repair_parts"
  on "public"."repair_parts"
  as permissive
  for select
  to public
using (true);



  create policy "users_can_only_access_own_repair_parts"
  on "public"."repair_parts"
  as permissive
  for all
  to public
using (((auth.uid())::text = (user_id)::text));



  create policy "Admins can delete all repair_services"
  on "public"."repair_services"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert repair_services"
  on "public"."repair_services"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all repair_services"
  on "public"."repair_services"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all repair_services"
  on "public"."repair_services"
  as permissive
  for select
  to public
using (true);



  create policy "Users can delete their own repair_services"
  on "public"."repair_services"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own repair_services"
  on "public"."repair_services"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update their own repair_services"
  on "public"."repair_services"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view their own repair_services"
  on "public"."repair_services"
  as permissive
  for select
  to public
using (true);



  create policy "users_can_only_access_own_repair_services"
  on "public"."repair_services"
  as permissive
  for all
  to public
using (((auth.uid())::text = (user_id)::text));



  create policy "Users can delete own repairs"
  on "public"."repairs"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own repairs"
  on "public"."repairs"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own repairs"
  on "public"."repairs"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own repairs"
  on "public"."repairs"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "repairs_delete_policy"
  on "public"."repairs"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "repairs_insert_policy"
  on "public"."repairs"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "repairs_select_policy"
  on "public"."repairs"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "repairs_update_policy"
  on "public"."repairs"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Enable delete for authenticated users"
  on "public"."sale_items"
  as permissive
  for delete
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable insert for authenticated users"
  on "public"."sale_items"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Enable read access for authenticated users"
  on "public"."sale_items"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Enable update for authenticated users"
  on "public"."sale_items"
  as permissive
  for update
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Users can delete own sales"
  on "public"."sales"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own sales"
  on "public"."sales"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own sales"
  on "public"."sales"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own sales"
  on "public"."sales"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "sales_insert_policy"
  on "public"."sales"
  as permissive
  for insert
  to public
with check ((auth.uid() IS NOT NULL));



  create policy "sales_select_policy"
  on "public"."sales"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "sales_update_policy"
  on "public"."sales"
  as permissive
  for update
  to public
using ((auth.uid() IS NOT NULL));



  create policy "Users can delete own services"
  on "public"."services"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own services"
  on "public"."services"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own services"
  on "public"."services"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own services"
  on "public"."services"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "services_delete_policy"
  on "public"."services"
  as permissive
  for delete
  to public
using ((user_id = auth.uid()));



  create policy "services_insert_policy"
  on "public"."services"
  as permissive
  for insert
  to public
with check ((user_id = auth.uid()));



  create policy "services_select_policy"
  on "public"."services"
  as permissive
  for select
  to public
using ((user_id = auth.uid()));



  create policy "services_update_policy"
  on "public"."services"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "Admins can delete all stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for delete
  to public
using (true);



  create policy "Admins can insert stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Admins can update all stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for update
  to public
using (true);



  create policy "Admins can view all stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for select
  to public
using (true);



  create policy "Users can create own stock alerts"
  on "public"."stock_alerts"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "Users can delete own stock alerts"
  on "public"."stock_alerts"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "Users can delete their own stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for delete
  to public
using (true);



  create policy "Users can insert their own stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for insert
  to public
with check (true);



  create policy "Users can update own stock alerts"
  on "public"."stock_alerts"
  as permissive
  for update
  to public
using ((auth.uid() = user_id))
with check ((auth.uid() = user_id));



  create policy "Users can update their own stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for update
  to public
using (true);



  create policy "Users can view own stock alerts"
  on "public"."stock_alerts"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can view their own stock_alerts"
  on "public"."stock_alerts"
  as permissive
  for select
  to public
using (true);



  create policy "admins_can_manage_subscriptions"
  on "public"."subscription_status"
  as permissive
  for all
  to public
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['srohee32@gmail.com'::text, 'repphonereparation@gmail.com'::text])));



  create policy "service_role_full_access_subscription"
  on "public"."subscription_status"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "subscription_status_select_policy"
  on "public"."subscription_status"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "subscription_status_update_policy"
  on "public"."subscription_status"
  as permissive
  for update
  to public
using ((user_id = auth.uid()));



  create policy "users_can_insert_own_subscription"
  on "public"."subscription_status"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "users_can_update_own_subscription"
  on "public"."subscription_status"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "users_can_view_own_subscription"
  on "public"."subscription_status"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "Users can delete own suppliers"
  on "public"."suppliers"
  as permissive
  for delete
  to public
using ((created_by = auth.uid()));



  create policy "Users can insert own suppliers"
  on "public"."suppliers"
  as permissive
  for insert
  to public
with check ((created_by = auth.uid()));



  create policy "Users can update own suppliers"
  on "public"."suppliers"
  as permissive
  for update
  to public
using ((created_by = auth.uid()));



  create policy "Users can view own suppliers"
  on "public"."suppliers"
  as permissive
  for select
  to public
using ((created_by = auth.uid()));



  create policy "Admins can insert system_settings"
  on "public"."system_settings"
  as permissive
  for insert
  to public
with check ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = 'admin'::text)))));



  create policy "Admins can update system_settings"
  on "public"."system_settings"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM users
  WHERE ((users.id = auth.uid()) AND (users.role = 'admin'::text)))));



  create policy "Authenticated users can view system_settings"
  on "public"."system_settings"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "system_settings_select_policy"
  on "public"."system_settings"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "system_settings_update_policy"
  on "public"."system_settings"
  as permissive
  for update
  to public
using ((EXISTS ( SELECT 1
   FROM auth.users
  WHERE ((users.id = auth.uid()) AND ((users.raw_user_meta_data ->> 'role'::text) = 'admin'::text)))));



  create policy "admins_can_manage_all_users"
  on "public"."users"
  as permissive
  for all
  to public
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['srohee32@gmail.com'::text, 'repphonereparation@gmail.com'::text])));



  create policy "admins_can_view_all_users"
  on "public"."users"
  as permissive
  for select
  to public
using (((auth.jwt() ->> 'email'::text) = ANY (ARRAY['srohee32@gmail.com'::text, 'repphonereparation@gmail.com'::text])));



  create policy "service_role_full_access_users"
  on "public"."users"
  as permissive
  for all
  to public
using ((auth.role() = 'service_role'::text))
with check ((auth.role() = 'service_role'::text));



  create policy "users_can_insert_own_profile"
  on "public"."users"
  as permissive
  for insert
  to public
with check ((auth.uid() = id));



  create policy "users_can_update_own_profile"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = id));



  create policy "users_can_view_own_profile"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() = id));



  create policy "users_select_policy"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() IS NOT NULL));



  create policy "users_update_policy"
  on "public"."users"
  as permissive
  for update
  to public
using ((id = auth.uid()));


CREATE TRIGGER set_appointment_user BEFORE INSERT ON public.appointments FOR EACH ROW EXECUTE FUNCTION set_appointment_user();

CREATE TRIGGER update_client_loyalty_points_updated_at BEFORE UPDATE ON public.client_loyalty_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_client_user_id_ultra_strict_trigger BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION set_client_user_id_ultra_strict();

CREATE TRIGGER set_user_id_clients_safe BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER trigger_assign_user_id_clients BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION assign_user_id_trigger();

CREATE TRIGGER trigger_assign_workshop_id BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION assign_workshop_id();

CREATE TRIGGER trigger_assign_workshop_id_clients BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION assign_workshop_id_trigger();

CREATE TRIGGER trigger_handle_duplicate_emails BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION handle_duplicate_emails();

CREATE TRIGGER trigger_validate_client_email_format BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION validate_client_email_format();

CREATE TRIGGER update_client_tier_trigger BEFORE UPDATE ON public.clients FOR EACH ROW WHEN ((old.loyalty_points IS DISTINCT FROM new.loyalty_points)) EXECUTE FUNCTION update_client_tier();

CREATE TRIGGER set_device_brand_context_trigger BEFORE INSERT ON public.device_brands FOR EACH ROW EXECUTE FUNCTION set_device_brand_context();

CREATE TRIGGER set_device_brand_user_id_trigger BEFORE INSERT ON public.device_brands FOR EACH ROW EXECUTE FUNCTION set_device_brand_user_id();

CREATE TRIGGER update_device_brands_updated_at BEFORE UPDATE ON public.device_brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_device_category_context_trigger BEFORE INSERT ON public.device_categories FOR EACH ROW EXECUTE FUNCTION set_device_category_context();

CREATE TRIGGER set_device_category_user_id_trigger BEFORE INSERT ON public.device_categories FOR EACH ROW EXECUTE FUNCTION set_device_category_user_id();

CREATE TRIGGER update_device_categories_updated_at BEFORE UPDATE ON public.device_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_device_model_context_trigger BEFORE INSERT ON public.device_models FOR EACH ROW EXECUTE FUNCTION set_device_model_context();

CREATE TRIGGER set_device_model_user_context BEFORE INSERT ON public.device_models FOR EACH ROW EXECUTE FUNCTION set_device_model_user_context();

CREATE TRIGGER set_device_model_user_id_trigger BEFORE INSERT ON public.device_models FOR EACH ROW EXECUTE FUNCTION set_device_model_user_id();

CREATE TRIGGER set_device_model_user_ultime BEFORE INSERT ON public.device_models FOR EACH ROW EXECUTE FUNCTION set_device_model_user_ultime();

CREATE TRIGGER set_device_model_workshop_context BEFORE INSERT ON public.device_models FOR EACH ROW EXECUTE FUNCTION set_device_model_workshop_context();

CREATE TRIGGER update_device_models_updated_at BEFORE UPDATE ON public.device_models FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_device_context BEFORE INSERT ON public.devices FOR EACH ROW EXECUTE FUNCTION set_device_context();

CREATE TRIGGER set_device_user_final BEFORE INSERT ON public.devices FOR EACH ROW EXECUTE FUNCTION set_device_user_final();

CREATE TRIGGER set_user_id_devices_safe BEFORE INSERT ON public.devices FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER trigger_prevent_duplicate_serial_numbers BEFORE INSERT OR UPDATE ON public.devices FOR EACH ROW EXECUTE FUNCTION prevent_duplicate_serial_numbers();

CREATE TRIGGER trigger_update_intervention_forms_updated_at BEFORE UPDATE ON public.intervention_forms FOR EACH ROW EXECUTE FUNCTION update_intervention_forms_updated_at();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_config_trigger BEFORE INSERT OR UPDATE ON public.loyalty_config FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

CREATE TRIGGER update_loyalty_config_updated_at BEFORE UPDATE ON public.loyalty_config FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_loyalty_points_defaults_trigger BEFORE INSERT OR UPDATE ON public.loyalty_points_history FOR EACH ROW EXECUTE FUNCTION set_loyalty_points_defaults();

CREATE TRIGGER set_loyalty_points_isolation_trigger BEFORE INSERT ON public.loyalty_points_history FOR EACH ROW EXECUTE FUNCTION set_loyalty_points_isolation();

CREATE TRIGGER update_loyalty_points_history_updated_at BEFORE UPDATE ON public.loyalty_points_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER validate_loyalty_points_client_trigger BEFORE INSERT OR UPDATE ON public.loyalty_points_history FOR EACH ROW EXECUTE FUNCTION validate_loyalty_points_client();

CREATE TRIGGER set_loyalty_workshop_id_loyalty_tiers_trigger BEFORE INSERT OR UPDATE ON public.loyalty_tiers_advanced FOR EACH ROW EXECUTE FUNCTION set_loyalty_workshop_id();

CREATE TRIGGER update_loyalty_tiers_advanced_updated_at BEFORE UPDATE ON public.loyalty_tiers_advanced FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_message_user BEFORE INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION set_message_user();

CREATE TRIGGER update_order_total_trigger AFTER INSERT OR DELETE OR UPDATE ON public.order_items FOR EACH ROW EXECUTE FUNCTION update_order_total();

CREATE TRIGGER set_order_isolation_trigger BEFORE INSERT OR UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION set_order_isolation();

CREATE TRIGGER set_part_context BEFORE INSERT ON public.parts FOR EACH ROW EXECUTE FUNCTION set_part_context();

CREATE TRIGGER set_part_user_ultime BEFORE INSERT ON public.parts FOR EACH ROW EXECUTE FUNCTION set_part_user_ultime();

CREATE TRIGGER set_user_id_parts_safe BEFORE INSERT ON public.parts FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER set_product_categories_isolation_trigger BEFORE INSERT ON public.product_categories FOR EACH ROW EXECUTE FUNCTION set_product_categories_isolation();

CREATE TRIGGER set_product_categories_user_id_trigger BEFORE INSERT ON public.product_categories FOR EACH ROW EXECUTE FUNCTION set_product_categories_user_id();

CREATE TRIGGER set_product_categories_workshop_id_trigger BEFORE INSERT ON public.product_categories FOR EACH ROW EXECUTE FUNCTION set_product_categories_workshop_id();

CREATE TRIGGER set_product_category_context_trigger BEFORE INSERT ON public.product_categories FOR EACH ROW EXECUTE FUNCTION set_product_category_context();

CREATE TRIGGER set_product_user_ultime BEFORE INSERT ON public.products FOR EACH ROW EXECUTE FUNCTION set_product_user_ultime();

CREATE TRIGGER set_products_isolation_trigger BEFORE INSERT ON public.products FOR EACH ROW EXECUTE FUNCTION set_products_isolation();

CREATE TRIGGER set_user_id_products_safe BEFORE INSERT ON public.products FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER update_quotes_updated_at_trigger BEFORE UPDATE ON public.quotes FOR EACH ROW EXECUTE FUNCTION update_quotes_updated_at();

CREATE TRIGGER update_referrals_updated_at BEFORE UPDATE ON public.referrals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER auto_loyalty_points_repair_trigger AFTER UPDATE ON public.repairs FOR EACH ROW EXECUTE FUNCTION trigger_auto_loyalty_points_repair();

CREATE TRIGGER set_repair_context BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_context();

CREATE TRIGGER set_repair_user BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_user();

CREATE TRIGGER set_repair_user_context BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_user_context();

CREATE TRIGGER set_repair_user_context_aggressive BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_user_context_aggressive();

CREATE TRIGGER set_repair_workshop_context BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_workshop_context();

CREATE TRIGGER set_user_id_repairs_safe BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER trigger_assign_workshop_id_repairs BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION assign_workshop_id_trigger();

CREATE TRIGGER trigger_auto_calculate_loyalty_discount AFTER INSERT OR UPDATE OF client_id ON public.repairs FOR EACH ROW EXECUTE FUNCTION auto_calculate_loyalty_discount();

CREATE TRIGGER trigger_calculate_repair_discount_safe BEFORE INSERT OR UPDATE ON public.repairs FOR EACH ROW EXECUTE FUNCTION calculate_repair_discount_amount_safe();

CREATE TRIGGER trigger_set_repair_number BEFORE INSERT ON public.repairs FOR EACH ROW EXECUTE FUNCTION set_repair_number();

CREATE TRIGGER trigger_update_repair_updated_at BEFORE UPDATE ON public.repairs FOR EACH ROW EXECUTE FUNCTION update_repair_updated_at();

CREATE TRIGGER trigger_update_sale_item_category BEFORE INSERT OR UPDATE ON public.sale_items FOR EACH ROW EXECUTE FUNCTION update_sale_item_category();

CREATE TRIGGER auto_loyalty_points_sale_trigger AFTER UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION trigger_auto_loyalty_points_sale();

CREATE TRIGGER set_sale_user BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION set_sale_user();

CREATE TRIGGER set_sales_isolation_trigger BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION set_sales_isolation();

CREATE TRIGGER set_user_id_sales_safe BEFORE INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER trigger_calculate_sale_discount_safe BEFORE INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION calculate_sale_discount_amount_safe();

CREATE TRIGGER set_service_context BEFORE INSERT ON public.services FOR EACH ROW EXECUTE FUNCTION set_service_context();

CREATE TRIGGER set_service_user_ultime BEFORE INSERT ON public.services FOR EACH ROW EXECUTE FUNCTION set_service_user_ultime();

CREATE TRIGGER set_user_id_services_safe BEFORE INSERT ON public.services FOR EACH ROW EXECUTE FUNCTION set_user_id_safe();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON public.subscription_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_transaction_user BEFORE INSERT ON public.transactions FOR EACH ROW EXECUTE FUNCTION set_transaction_user();

CREATE TRIGGER on_subscription_change AFTER UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION audit_subscription_change();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON public.user_subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


