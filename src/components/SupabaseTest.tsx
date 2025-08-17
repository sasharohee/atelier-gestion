import React, { useState, useEffect } from 'react'
import { supabase } from '../lib/supabase'
import { useClients, useProduits, useServices } from '../hooks/useSupabase'
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  Grid,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  Divider
} from '@mui/material'

const SupabaseTest: React.FC = () => {
  const [connectionStatus, setConnectionStatus] = useState<'checking' | 'connected' | 'error'>('checking')
  const [testMessage, setTestMessage] = useState('')

  // Hooks pour les données
  const { clients, loading: clientsLoading, error: clientsError, addClient } = useClients()
  const { produits, loading: produitsLoading, error: produitsError, addProduit } = useProduits()
  const { services, loading: servicesLoading, error: servicesError, addService } = useServices()

  // État pour les formulaires
  const [newClient, setNewClient] = useState({ nom: '', email: '', telephone: '', adresse: '' })
  const [newProduit, setNewProduit] = useState({ nom: '', description: '', prix: '', stock: '', categorie: '' })
  const [newService, setNewService] = useState({ nom: '', description: '', prix: '', duree_estimee: '' })

  // Vérifier la connexion Supabase
  useEffect(() => {
    const checkConnection = async () => {
      try {
        const { data, error } = await supabase.from('clients').select('count').limit(1)
        if (error) {
          console.log('Erreur de connexion:', error)
          setConnectionStatus('error')
          setTestMessage('Erreur de connexion à Supabase. Vérifiez que les tables sont créées.')
        } else {
          setConnectionStatus('connected')
          setTestMessage('Connexion à Supabase réussie!')
        }
      } catch (err) {
        setConnectionStatus('error')
        setTestMessage('Erreur lors de la vérification de la connexion')
      }
    }

    checkConnection()
  }, [])

  // Fonctions pour ajouter des données
  const handleAddClient = async () => {
    try {
      await addClient({
        nom: newClient.nom,
        email: newClient.email,
        telephone: newClient.telephone,
        adresse: newClient.adresse
      })
      setNewClient({ nom: '', email: '', telephone: '', adresse: '' })
    } catch (error) {
      console.error('Erreur lors de l\'ajout du client:', error)
    }
  }

  const handleAddProduit = async () => {
    try {
      await addProduit({
        nom: newProduit.nom,
        description: newProduit.description,
        prix: parseFloat(newProduit.prix),
        stock: parseInt(newProduit.stock),
        categorie: newProduit.categorie
      })
      setNewProduit({ nom: '', description: '', prix: '', stock: '', categorie: '' })
    } catch (error) {
      console.error('Erreur lors de l\'ajout du produit:', error)
    }
  }

  const handleAddService = async () => {
    try {
      await addService({
        nom: newService.nom,
        description: newService.description,
        prix: parseFloat(newService.prix),
        duree_estimee: parseInt(newService.duree_estimee)
      })
      setNewService({ nom: '', description: '', prix: '', duree_estimee: '' })
    } catch (error) {
      console.error('Erreur lors de l\'ajout du service:', error)
    }
  }

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Test de Connexion Supabase
      </Typography>

      {/* Statut de connexion */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Statut de la Connexion
          </Typography>
          {connectionStatus === 'checking' && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <CircularProgress size={20} />
              <Typography>Vérification de la connexion...</Typography>
            </Box>
          )}
          {connectionStatus === 'connected' && (
            <Alert severity="success">
              ✅ {testMessage}
            </Alert>
          )}
          {connectionStatus === 'error' && (
            <Alert severity="error">
              ❌ {testMessage}
            </Alert>
          )}
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* Section Clients */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Clients ({clients.length})
              </Typography>
              
              {clientsLoading ? (
                <CircularProgress size={20} />
              ) : clientsError ? (
                <Alert severity="error">{clientsError}</Alert>
              ) : (
                <>
                  <List dense>
                    {clients.slice(0, 5).map((client) => (
                      <ListItem key={client.id}>
                        <ListItemText
                          primary={client.nom}
                          secondary={`${client.email} - ${client.telephone}`}
                        />
                      </ListItem>
                    ))}
                  </List>
                  
                  <Divider sx={{ my: 2 }} />
                  
                  <Typography variant="subtitle2" gutterBottom>
                    Ajouter un client
                  </Typography>
                  <TextField
                    fullWidth
                    size="small"
                    label="Nom"
                    value={newClient.nom}
                    onChange={(e) => setNewClient(prev => ({ ...prev, nom: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Email"
                    value={newClient.email}
                    onChange={(e) => setNewClient(prev => ({ ...prev, email: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Téléphone"
                    value={newClient.telephone}
                    onChange={(e) => setNewClient(prev => ({ ...prev, telephone: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Adresse"
                    value={newClient.adresse}
                    onChange={(e) => setNewClient(prev => ({ ...prev, adresse: e.target.value }))}
                    sx={{ mb: 2 }}
                  />
                  <Button
                    variant="contained"
                    onClick={handleAddClient}
                    disabled={!newClient.nom || !newClient.email}
                    fullWidth
                  >
                    Ajouter Client
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Section Produits */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Produits ({produits.length})
              </Typography>
              
              {produitsLoading ? (
                <CircularProgress size={20} />
              ) : produitsError ? (
                <Alert severity="error">{produitsError}</Alert>
              ) : (
                <>
                  <List dense>
                    {produits.slice(0, 5).map((produit) => (
                      <ListItem key={produit.id}>
                        <ListItemText
                          primary={produit.nom}
                          secondary={`${produit.prix}€ - Stock: ${produit.stock}`}
                        />
                      </ListItem>
                    ))}
                  </List>
                  
                  <Divider sx={{ my: 2 }} />
                  
                  <Typography variant="subtitle2" gutterBottom>
                    Ajouter un produit
                  </Typography>
                  <TextField
                    fullWidth
                    size="small"
                    label="Nom"
                    value={newProduit.nom}
                    onChange={(e) => setNewProduit(prev => ({ ...prev, nom: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Description"
                    value={newProduit.description}
                    onChange={(e) => setNewProduit(prev => ({ ...prev, description: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Prix"
                    type="number"
                    value={newProduit.prix}
                    onChange={(e) => setNewProduit(prev => ({ ...prev, prix: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Stock"
                    type="number"
                    value={newProduit.stock}
                    onChange={(e) => setNewProduit(prev => ({ ...prev, stock: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Catégorie"
                    value={newProduit.categorie}
                    onChange={(e) => setNewProduit(prev => ({ ...prev, categorie: e.target.value }))}
                    sx={{ mb: 2 }}
                  />
                  <Button
                    variant="contained"
                    onClick={handleAddProduit}
                    disabled={!newProduit.nom || !newProduit.prix}
                    fullWidth
                  >
                    Ajouter Produit
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Section Services */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Services ({services.length})
              </Typography>
              
              {servicesLoading ? (
                <CircularProgress size={20} />
              ) : servicesError ? (
                <Alert severity="error">{servicesError}</Alert>
              ) : (
                <>
                  <List dense>
                    {services.slice(0, 5).map((service) => (
                      <ListItem key={service.id}>
                        <ListItemText
                          primary={service.nom}
                          secondary={`${service.prix}€ - ${service.duree_estimee}min`}
                        />
                      </ListItem>
                    ))}
                  </List>
                  
                  <Divider sx={{ my: 2 }} />
                  
                  <Typography variant="subtitle2" gutterBottom>
                    Ajouter un service
                  </Typography>
                  <TextField
                    fullWidth
                    size="small"
                    label="Nom"
                    value={newService.nom}
                    onChange={(e) => setNewService(prev => ({ ...prev, nom: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Description"
                    value={newService.description}
                    onChange={(e) => setNewService(prev => ({ ...prev, description: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Prix"
                    type="number"
                    value={newService.prix}
                    onChange={(e) => setNewService(prev => ({ ...prev, prix: e.target.value }))}
                    sx={{ mb: 1 }}
                  />
                  <TextField
                    fullWidth
                    size="small"
                    label="Durée (minutes)"
                    type="number"
                    value={newService.duree_estimee}
                    onChange={(e) => setNewService(prev => ({ ...prev, duree_estimee: e.target.value }))}
                    sx={{ mb: 2 }}
                  />
                  <Button
                    variant="contained"
                    onClick={handleAddService}
                    disabled={!newService.nom || !newService.prix}
                    fullWidth
                  >
                    Ajouter Service
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Instructions */}
      <Card sx={{ mt: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Instructions pour créer les tables
          </Typography>
          <Typography variant="body2" paragraph>
            1. Allez sur le dashboard Supabase: 
            <a href="https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv/editor" target="_blank" rel="noopener noreferrer">
              https://supabase.com/dashboard/project/wlqyrmntfxwdvkzzsujv/editor
            </a>
          </Typography>
          <Typography variant="body2" paragraph>
            2. Dans l'éditeur SQL, copiez et exécutez le contenu du fichier <code>database/schema.sql</code>
          </Typography>
          <Typography variant="body2" paragraph>
            3. Une fois les tables créées, rechargez cette page pour tester la connexion
          </Typography>
        </CardContent>
      </Card>
    </Box>
  )
}

export default SupabaseTest
