import { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import type { Client, Produit, Service, Reparation, Piece, Commande } from '../lib/supabase'
import { 
  clientService, 
  produitService, 
  serviceService, 
  reparationService, 
  pieceService, 
  commandeService 
} from '../services/supabaseService'

// Hook pour les clients
export const useClients = () => {
  const [clients, setClients] = useState<Client[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchClients = async () => {
    try {
      setLoading(true)
      const data = await clientService.getAll()
      setClients(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des clients')
    } finally {
      setLoading(false)
    }
  }

  const addClient = async (client: Omit<Client, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newClient = await clientService.create(client)
      setClients(prev => [newClient, ...prev])
      return newClient
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout du client')
      throw err
    }
  }

  const updateClient = async (id: string, updates: Partial<Client>) => {
    try {
      const updatedClient = await clientService.update(id, updates)
      setClients(prev => prev.map(client => client.id === id ? updatedClient : client))
      return updatedClient
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour du client')
      throw err
    }
  }

  const deleteClient = async (id: string) => {
    try {
      await clientService.delete(id)
      setClients(prev => prev.filter(client => client.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression du client')
      throw err
    }
  }

  useEffect(() => {
    fetchClients()
  }, [])

  return {
    clients,
    loading,
    error,
    fetchClients,
    addClient,
    updateClient,
    deleteClient
  }
}

// Hook pour les produits
export const useProduits = () => {
  const [produits, setProduits] = useState<Produit[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchProduits = async () => {
    try {
      setLoading(true)
      const data = await produitService.getAll()
      setProduits(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des produits')
    } finally {
      setLoading(false)
    }
  }

  const addProduit = async (produit: Omit<Produit, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newProduit = await produitService.create(produit)
      setProduits(prev => [newProduit, ...prev])
      return newProduit
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout du produit')
      throw err
    }
  }

  const updateProduit = async (id: string, updates: Partial<Produit>) => {
    try {
      const updatedProduit = await produitService.update(id, updates)
      setProduits(prev => prev.map(produit => produit.id === id ? updatedProduit : produit))
      return updatedProduit
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour du produit')
      throw err
    }
  }

  const deleteProduit = async (id: string) => {
    try {
      await produitService.delete(id)
      setProduits(prev => prev.filter(produit => produit.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression du produit')
      throw err
    }
  }

  useEffect(() => {
    fetchProduits()
  }, [])

  return {
    produits,
    loading,
    error,
    fetchProduits,
    addProduit,
    updateProduit,
    deleteProduit
  }
}

// Hook pour les services
export const useServices = () => {
  const [services, setServices] = useState<Service[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchServices = async () => {
    try {
      setLoading(true)
      const data = await serviceService.getAll()
      setServices(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des services')
    } finally {
      setLoading(false)
    }
  }

  const addService = async (service: Omit<Service, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newService = await serviceService.create(service)
      setServices(prev => [newService, ...prev])
      return newService
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout du service')
      throw err
    }
  }

  const updateService = async (id: string, updates: Partial<Service>) => {
    try {
      const updatedService = await serviceService.update(id, updates)
      setServices(prev => prev.map(service => service.id === id ? updatedService : service))
      return updatedService
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour du service')
      throw err
    }
  }

  const deleteService = async (id: string) => {
    try {
      await serviceService.delete(id)
      setServices(prev => prev.filter(service => service.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression du service')
      throw err
    }
  }

  useEffect(() => {
    fetchServices()
  }, [])

  return {
    services,
    loading,
    error,
    fetchServices,
    addService,
    updateService,
    deleteService
  }
}

// Hook pour les réparations
export const useReparations = () => {
  const [reparations, setReparations] = useState<Reparation[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchReparations = async () => {
    try {
      setLoading(true)
      const data = await reparationService.getAll()
      setReparations(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des réparations')
    } finally {
      setLoading(false)
    }
  }

  const addReparation = async (reparation: Omit<Reparation, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newReparation = await reparationService.create(reparation)
      setReparations(prev => [newReparation, ...prev])
      return newReparation
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout de la réparation')
      throw err
    }
  }

  const updateReparation = async (id: string, updates: Partial<Reparation>) => {
    try {
      const updatedReparation = await reparationService.update(id, updates)
      setReparations(prev => prev.map(reparation => reparation.id === id ? updatedReparation : reparation))
      return updatedReparation
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour de la réparation')
      throw err
    }
  }

  const deleteReparation = async (id: string) => {
    try {
      await reparationService.delete(id)
      setReparations(prev => prev.filter(reparation => reparation.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression de la réparation')
      throw err
    }
  }

  const getReparationsByStatus = async (status: Reparation['statut']) => {
    try {
      const data = await reparationService.getByStatus(status)
      return data
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du filtrage des réparations')
      throw err
    }
  }

  useEffect(() => {
    fetchReparations()
  }, [])

  return {
    reparations,
    loading,
    error,
    fetchReparations,
    addReparation,
    updateReparation,
    deleteReparation,
    getReparationsByStatus
  }
}

// Hook pour les pièces
export const usePieces = () => {
  const [pieces, setPieces] = useState<Piece[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchPieces = async () => {
    try {
      setLoading(true)
      const data = await pieceService.getAll()
      setPieces(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des pièces')
    } finally {
      setLoading(false)
    }
  }

  const addPiece = async (piece: Omit<Piece, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newPiece = await pieceService.create(piece)
      setPieces(prev => [newPiece, ...prev])
      return newPiece
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout de la pièce')
      throw err
    }
  }

  const updatePiece = async (id: string, updates: Partial<Piece>) => {
    try {
      const updatedPiece = await pieceService.update(id, updates)
      setPieces(prev => prev.map(piece => piece.id === id ? updatedPiece : piece))
      return updatedPiece
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour de la pièce')
      throw err
    }
  }

  const deletePiece = async (id: string) => {
    try {
      await pieceService.delete(id)
      setPieces(prev => prev.filter(piece => piece.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression de la pièce')
      throw err
    }
  }

  useEffect(() => {
    fetchPieces()
  }, [])

  return {
    pieces,
    loading,
    error,
    fetchPieces,
    addPiece,
    updatePiece,
    deletePiece
  }
}

// Hook pour les commandes
export const useCommandes = () => {
  const [commandes, setCommandes] = useState<Commande[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchCommandes = async () => {
    try {
      setLoading(true)
      const data = await commandeService.getAll()
      setCommandes(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du chargement des commandes')
    } finally {
      setLoading(false)
    }
  }

  const addCommande = async (commande: Omit<Commande, 'id' | 'created_at' | 'updated_at'>) => {
    try {
      const newCommande = await commandeService.create(commande)
      setCommandes(prev => [newCommande, ...prev])
      return newCommande
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'ajout de la commande')
      throw err
    }
  }

  const updateCommande = async (id: string, updates: Partial<Commande>) => {
    try {
      const updatedCommande = await commandeService.update(id, updates)
      setCommandes(prev => prev.map(commande => commande.id === id ? updatedCommande : commande))
      return updatedCommande
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la mise à jour de la commande')
      throw err
    }
  }

  const deleteCommande = async (id: string) => {
    try {
      await commandeService.delete(id)
      setCommandes(prev => prev.filter(commande => commande.id !== id))
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de la suppression de la commande')
      throw err
    }
  }

  const getCommandesByStatus = async (status: Commande['statut']) => {
    try {
      const data = await commandeService.getByStatus(status)
      return data
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du filtrage des commandes')
      throw err
    }
  }

  useEffect(() => {
    fetchCommandes()
  }, [])

  return {
    commandes,
    loading,
    error,
    fetchCommandes,
    addCommande,
    updateCommande,
    deleteCommande,
    getCommandesByStatus
  }
}
