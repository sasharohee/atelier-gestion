import { supabase } from '../lib/supabase'
import type { Client, Produit, Service, Reparation, Piece, Commande, CommandeProduit } from '../lib/supabase'

// Service pour les clients
export const clientService = {
  async getAll(): Promise<Client[]> {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Client | null> {
    const { data, error } = await supabase
      .from('clients')
      .select('*')
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(client: Omit<Client, 'id' | 'created_at' | 'updated_at'>): Promise<Client> {
    const { data, error } = await supabase
      .from('clients')
      .insert([client])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Client>): Promise<Client> {
    const { data, error } = await supabase
      .from('clients')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('clients')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  }
}

// Service pour les produits
export const produitService = {
  async getAll(): Promise<Produit[]> {
    const { data, error } = await supabase
      .from('produits')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Produit | null> {
    const { data, error } = await supabase
      .from('produits')
      .select('*')
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(produit: Omit<Produit, 'id' | 'created_at' | 'updated_at'>): Promise<Produit> {
    const { data, error } = await supabase
      .from('produits')
      .insert([produit])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Produit>): Promise<Produit> {
    const { data, error } = await supabase
      .from('produits')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('produits')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  },

  async updateStock(id: string, newStock: number): Promise<Produit> {
    return this.update(id, { stock: newStock })
  }
}

// Service pour les services
export const serviceService = {
  async getAll(): Promise<Service[]> {
    const { data, error } = await supabase
      .from('services')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Service | null> {
    const { data, error } = await supabase
      .from('services')
      .select('*')
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(service: Omit<Service, 'id' | 'created_at' | 'updated_at'>): Promise<Service> {
    const { data, error } = await supabase
      .from('services')
      .insert([service])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Service>): Promise<Service> {
    const { data, error } = await supabase
      .from('services')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('services')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  }
}

// Service pour les réparations
export const reparationService = {
  async getAll(): Promise<Reparation[]> {
    const { data, error } = await supabase
      .from('reparations')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Reparation | null> {
    const { data, error } = await supabase
      .from('reparations')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(reparation: Omit<Reparation, 'id' | 'created_at' | 'updated_at'>): Promise<Reparation> {
    const { data, error } = await supabase
      .from('reparations')
      .insert([reparation])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Reparation>): Promise<Reparation> {
    const { data, error } = await supabase
      .from('reparations')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('reparations')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  },

  async getByStatus(status: Reparation['statut']): Promise<Reparation[]> {
    const { data, error } = await supabase
      .from('reparations')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .eq('statut', status)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  }
}

// Service pour les pièces
export const pieceService = {
  async getAll(): Promise<Piece[]> {
    const { data, error } = await supabase
      .from('pieces')
      .select('*')
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Piece | null> {
    const { data, error } = await supabase
      .from('pieces')
      .select('*')
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(piece: Omit<Piece, 'id' | 'created_at' | 'updated_at'>): Promise<Piece> {
    const { data, error } = await supabase
      .from('pieces')
      .insert([piece])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Piece>): Promise<Piece> {
    const { data, error } = await supabase
      .from('pieces')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('pieces')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  },

  async updateStock(id: string, newStock: number): Promise<Piece> {
    return this.update(id, { stock: newStock })
  }
}

// Service pour les commandes
export const commandeService = {
  async getAll(): Promise<Commande[]> {
    const { data, error } = await supabase
      .from('commandes')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  },

  async getById(id: string): Promise<Commande | null> {
    const { data, error } = await supabase
      .from('commandes')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .eq('id', id)
      .single()
    
    if (error) throw error
    return data
  },

  async create(commande: Omit<Commande, 'id' | 'created_at' | 'updated_at'>): Promise<Commande> {
    const { data, error } = await supabase
      .from('commandes')
      .insert([commande])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async update(id: string, updates: Partial<Commande>): Promise<Commande> {
    const { data, error } = await supabase
      .from('commandes')
      .update(updates)
      .eq('id', id)
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async delete(id: string): Promise<void> {
    const { error } = await supabase
      .from('commandes')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  },

  async getByStatus(status: Commande['statut']): Promise<Commande[]> {
    const { data, error } = await supabase
      .from('commandes')
      .select(`
        *,
        clients (
          id,
          nom,
          email,
          telephone
        )
      `)
      .eq('statut', status)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    return data || []
  }
}

// Service pour les produits de commande
export const commandeProduitService = {
  async getByCommandeId(commandeId: string): Promise<CommandeProduit[]> {
    const { data, error } = await supabase
      .from('commande_produits')
      .select(`
        *,
        produits (
          id,
          nom,
          description,
          prix
        )
      `)
      .eq('commande_id', commandeId)
    
    if (error) throw error
    return data || []
  },

  async addProduit(commandeProduit: Omit<CommandeProduit, 'id' | 'created_at'>): Promise<CommandeProduit> {
    const { data, error } = await supabase
      .from('commande_produits')
      .insert([commandeProduit])
      .select()
      .single()
    
    if (error) throw error
    return data
  },

  async removeProduit(id: string): Promise<void> {
    const { error } = await supabase
      .from('commande_produits')
      .delete()
      .eq('id', id)
    
    if (error) throw error
  }
}
