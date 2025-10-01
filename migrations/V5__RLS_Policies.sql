-- Migration des politiques RLS (Row Level Security)
-- Version: V5
-- Description: Configuration des politiques de sécurité au niveau des lignes

-- Politiques RLS pour la table clients
CREATE POLICY "Clients can view their own workshop data" ON "public"."clients"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Clients can insert their own workshop data" ON "public"."clients"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Clients can update their own workshop data" ON "public"."clients"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Clients can delete their own workshop data" ON "public"."clients"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table repairs
CREATE POLICY "Repairs can view their own workshop data" ON "public"."repairs"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Repairs can insert their own workshop data" ON "public"."repairs"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Repairs can update their own workshop data" ON "public"."repairs"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Repairs can delete their own workshop data" ON "public"."repairs"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table appointments
CREATE POLICY "Appointments can view their own workshop data" ON "public"."appointments"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Appointments can insert their own workshop data" ON "public"."appointments"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Appointments can update their own workshop data" ON "public"."appointments"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Appointments can delete their own workshop data" ON "public"."appointments"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table parts
CREATE POLICY "Parts can view their own workshop data" ON "public"."parts"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Parts can insert their own workshop data" ON "public"."parts"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Parts can update their own workshop data" ON "public"."parts"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Parts can delete their own workshop data" ON "public"."parts"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table expenses
CREATE POLICY "Expenses can view their own workshop data" ON "public"."expenses"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Expenses can insert their own workshop data" ON "public"."expenses"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Expenses can update their own workshop data" ON "public"."expenses"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Expenses can delete their own workshop data" ON "public"."expenses"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table users
CREATE POLICY "Users can view their own workshop data" ON "public"."users"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Users can insert their own workshop data" ON "public"."users"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Users can update their own workshop data" ON "public"."users"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Users can delete their own workshop data" ON "public"."users"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table workshops
CREATE POLICY "Workshops can view their own data" ON "public"."workshops"
    FOR SELECT USING (id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Workshops can insert their own data" ON "public"."workshops"
    FOR INSERT WITH CHECK (id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Workshops can update their own data" ON "public"."workshops"
    FOR UPDATE USING (id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Workshops can delete their own data" ON "public"."workshops"
    FOR DELETE USING (id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table activity_logs
CREATE POLICY "Activity logs can view their own workshop data" ON "public"."activity_logs"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Activity logs can insert their own workshop data" ON "public"."activity_logs"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politiques RLS pour la table quote_requests
CREATE POLICY "Quote requests can view their own workshop data" ON "public"."quote_requests"
    FOR SELECT USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Quote requests can insert their own workshop data" ON "public"."quote_requests"
    FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Quote requests can update their own workshop data" ON "public"."quote_requests"
    FOR UPDATE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

CREATE POLICY "Quote requests can delete their own workshop data" ON "public"."quote_requests"
    FOR DELETE USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);
