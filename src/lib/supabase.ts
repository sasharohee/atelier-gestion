import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://wlqyrmntfxwdvkzzsujv.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Types pour les tables
export interface Client {
  id: string
  nom: string
  email: string
  telephone: string
  adresse: string
  created_at: string
  updated_at: string
}

export interface Produit {
  id: string
  nom: string
  description: string
  prix: number
  stock: number
  categorie: string
  created_at: string
  updated_at: string
}

export interface Service {
  id: string
  nom: string
  description: string
  prix: number
  duree_estimee: number
  created_at: string
  updated_at: string
}

export interface Reparation {
  id: string
  client_id: string
  appareil: string
  probleme: string
  statut: 'en_attente' | 'en_cours' | 'terminee' | 'annulee'
  date_creation: string
  date_fin_estimee: string
  date_fin_reelle?: string
  prix_estime: number
  prix_final?: number
  notes?: string
  created_at: string
  updated_at: string
}

export interface Piece {
  id: string
  nom: string
  description: string
  prix: number
  stock: number
  fournisseur: string
  created_at: string
  updated_at: string
}

export interface Commande {
  id: string
  client_id: string
  statut: 'en_attente' | 'confirmee' | 'en_preparation' | 'expediee' | 'livree' | 'annulee'
  total: number
  date_commande: string
  date_livraison_estimee?: string
  date_livraison_reelle?: string
  created_at: string
  updated_at: string
}

export interface CommandeProduit {
  id: string
  commande_id: string
  produit_id: string
  quantite: number
  prix_unitaire: number
  created_at: string
}
