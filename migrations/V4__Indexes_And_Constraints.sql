-- Migration des index et contraintes
-- Version: V4
-- Description: Ajout des index et contraintes pour optimiser les performances

-- Index pour la table clients
CREATE INDEX IF NOT EXISTS "idx_clients_email" ON "public"."clients" ("email");
CREATE INDEX IF NOT EXISTS "idx_clients_workshop_id" ON "public"."clients" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_clients_created_at" ON "public"."clients" ("created_at");

-- Index pour la table repairs
CREATE INDEX IF NOT EXISTS "idx_repairs_client_id" ON "public"."repairs" ("client_id");
CREATE INDEX IF NOT EXISTS "idx_repairs_workshop_id" ON "public"."repairs" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_repairs_status" ON "public"."repairs" ("status");
CREATE INDEX IF NOT EXISTS "idx_repairs_created_at" ON "public"."repairs" ("created_at");

-- Index pour la table appointments
CREATE INDEX IF NOT EXISTS "idx_appointments_client_id" ON "public"."appointments" ("client_id");
CREATE INDEX IF NOT EXISTS "idx_appointments_workshop_id" ON "public"."appointments" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_appointments_start_time" ON "public"."appointments" ("start_time");

-- Index pour la table parts
CREATE INDEX IF NOT EXISTS "idx_parts_workshop_id" ON "public"."parts" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_parts_name" ON "public"."parts" ("name");
CREATE INDEX IF NOT EXISTS "idx_parts_part_number" ON "public"."parts" ("part_number");

-- Index pour la table expenses
CREATE INDEX IF NOT EXISTS "idx_expenses_workshop_id" ON "public"."expenses" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_expenses_date" ON "public"."expenses" ("date");
CREATE INDEX IF NOT EXISTS "idx_expenses_category" ON "public"."expenses" ("category");

-- Index pour la table users
CREATE INDEX IF NOT EXISTS "idx_users_email" ON "public"."users" ("email");
CREATE INDEX IF NOT EXISTS "idx_users_workshop_id" ON "public"."users" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_users_role" ON "public"."users" ("role");

-- Index pour la table activity_logs
CREATE INDEX IF NOT EXISTS "idx_activity_logs_user_id" ON "public"."activity_logs" ("user_id");
CREATE INDEX IF NOT EXISTS "idx_activity_logs_workshop_id" ON "public"."activity_logs" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_activity_logs_created_at" ON "public"."activity_logs" ("created_at");

-- Index pour la table quote_requests
CREATE INDEX IF NOT EXISTS "idx_quote_requests_client_id" ON "public"."quote_requests" ("client_id");
CREATE INDEX IF NOT EXISTS "idx_quote_requests_workshop_id" ON "public"."quote_requests" ("workshop_id");
CREATE INDEX IF NOT EXISTS "idx_quote_requests_status" ON "public"."quote_requests" ("status");

-- Contraintes de clés étrangères (si elles n'existent pas déjà)
-- Note: Ces contraintes peuvent échouer si les tables référencées n'existent pas encore
-- ou si les données ne respectent pas les contraintes

-- Contrainte pour clients -> workshops
-- ALTER TABLE "public"."clients" ADD CONSTRAINT "fk_clients_workshop_id" 
-- FOREIGN KEY ("workshop_id") REFERENCES "public"."workshops"("id") ON DELETE CASCADE;

-- Contrainte pour repairs -> clients
-- ALTER TABLE "public"."repairs" ADD CONSTRAINT "fk_repairs_client_id" 
-- FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE CASCADE;

-- Contrainte pour repairs -> workshops
-- ALTER TABLE "public"."repairs" ADD CONSTRAINT "fk_repairs_workshop_id" 
-- FOREIGN KEY ("workshop_id") REFERENCES "public"."workshops"("id") ON DELETE CASCADE;

-- Contrainte pour appointments -> clients
-- ALTER TABLE "public"."appointments" ADD CONSTRAINT "fk_appointments_client_id" 
-- FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id") ON DELETE CASCADE;

-- Contrainte pour appointments -> workshops
-- ALTER TABLE "public"."appointments" ADD CONSTRAINT "fk_appointments_workshop_id" 
-- FOREIGN KEY ("workshop_id") REFERENCES "public"."workshops"("id") ON DELETE CASCADE;

-- Contrainte pour users -> workshops
-- ALTER TABLE "public"."users" ADD CONSTRAINT "fk_users_workshop_id" 
-- FOREIGN KEY ("workshop_id") REFERENCES "public"."workshops"("id") ON DELETE CASCADE;
