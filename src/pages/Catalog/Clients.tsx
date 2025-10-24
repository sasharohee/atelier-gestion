import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Avatar,
  Alert,
  CircularProgress,
  Checkbox,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Chip,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Refresh as RefreshIcon,
  Upload as UploadIcon,
  Download as DownloadIcon,
  Person as PersonIcon,
  Business as BusinessIcon,
  SelectAll as SelectAllIcon,
  DeleteSweep as DeleteSweepIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import ClientForm from '../../components/ClientForm';
import CSVImport from '../../components/CSVImport';
import { clientService } from '../../services/supabaseService';

const Clients: React.FC = () => {
  const { clients, loadClients, addClient, updateClient, deleteClient } = useAppStore();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [clientFormOpen, setClientFormOpen] = useState(false);
  const [editClientFormOpen, setEditClientFormOpen] = useState(false);
  const [editingClient, setEditingClient] = useState<any>(null);
  const [csvImportOpen, setCsvImportOpen] = useState(false);
  
  // États pour la sélection multiple
  const [selectedClients, setSelectedClients] = useState<string[]>([]);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    const loadClientsData = async () => {
      setIsLoading(true);
      setError(null);
      try {
        await loadClients();
      } catch (err) {
        setError('Erreur lors du chargement des clients');
        console.error('Erreur lors du chargement des clients:', err);
      } finally {
        setIsLoading(false);
      }
    };

    // Charger seulement au montage du composant
    loadClientsData();
  }, []); // Dépendances vides pour éviter les boucles

  const handleOpenDialog = () => {
    setClientFormOpen(true);
    setError(null);
  };

  const handleCloseDialog = () => {
    setClientFormOpen(false);
    setError(null);
  };

  const handleOpenCsvImport = () => {
    setCsvImportOpen(true);
    setError(null);
  };

  const handleCloseCsvImport = () => {
    setCsvImportOpen(false);
    setError(null);
  };



  const handleEditClient = async (client: any) => {
    console.log('🔍 CLIENTS PAGE - Données du client reçues:', client);
    console.log('🔍 CLIENTS PAGE - Détails des champs:');
    console.log('  - companyName:', client.companyName);
    console.log('  - vatNumber:', client.vatNumber);
    console.log('  - sirenNumber:', client.sirenNumber);
    console.log('  - addressComplement:', client.addressComplement);
    console.log('  - region:', client.region);
    console.log('  - postalCode:', client.postalCode);
    console.log('  - city:', client.city);
    console.log('  - accountingCode:', client.accountingCode);
    console.log('  - cniIdentifier:', client.cniIdentifier);
    console.log('  - internalNote:', client.internalNote);
    
    try {
      // Récupérer le client complet depuis la base de données
      const result = await clientService.getById(client.id);
      
      if (result.success && 'data' in result && result.data) {
        console.log('🔍 CLIENTS PAGE - Client complet depuis la DB:', result.data);
        
        // Préparer les données du client pour le formulaire d'édition
        const clientFormData = {
          category: result.data.category || 'particulier',
          title: result.data.title || 'mr',
          firstName: result.data.firstName,
          lastName: result.data.lastName,
          companyName: result.data.companyName || '',
          vatNumber: result.data.vatNumber || '',
          sirenNumber: result.data.sirenNumber || '',
          email: result.data.email,
          countryCode: result.data.countryCode || '33',
          mobile: result.data.phone ? result.data.phone.replace(result.data.countryCode || '33', '') : '',
          address: result.data.address || '',
          addressComplement: result.data.addressComplement || '',
          region: result.data.region || '',
          postalCode: result.data.postalCode || '',
          city: result.data.city || '',
          billingAddressSame: result.data.billingAddressSame !== false,
          billingAddress: result.data.billingAddress || '',
          billingAddressComplement: result.data.billingAddressComplement || '',
          billingRegion: result.data.billingRegion || '',
          billingPostalCode: result.data.billingPostalCode || '',
          billingCity: result.data.billingCity || '',
          accountingCode: result.data.accountingCode || '',
          cniIdentifier: result.data.cniIdentifier || '',
          attachedFile: null,
          internalNote: result.data.internalNote || result.data.notes || '',
          status: result.data.status || 'displayed',
          smsNotification: result.data.smsNotification !== false,
          emailNotification: result.data.emailNotification !== false,
          smsMarketing: result.data.smsMarketing !== false,
          emailMarketing: result.data.emailMarketing !== false,
        };

        console.log('📋 CLIENTS PAGE - Données préparées pour le formulaire:', clientFormData);
        
        setEditingClient(result.data);
        setEditClientFormOpen(true);
      } else {
        console.error('❌ CLIENTS PAGE - Erreur lors de la récupération du client:', result);
        alert('Erreur lors de la récupération des données du client');
      }
    } catch (error) {
      console.error('💥 CLIENTS PAGE - Erreur lors de la récupération du client:', error);
      alert('Erreur lors de la récupération des données du client');
    }
  };

  const handleDeleteClient = async (clientId: string) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer ce client ?')) {
      try {
        await deleteClient(clientId);
      } catch (error) {
        console.error('Erreur lors de la suppression du client:', error);
        alert('Erreur lors de la suppression du client');
      }
    }
  };

  const handleCreateNewClient = async (clientFormData: any, skipDuplicateCheck = true) => {
    setIsSubmitting(true);
    setError(null);

    try {
      console.log('🚀 CLIENTS PAGE - Début de la création:', clientFormData);
      
      // Ne plus vérifier les doublons - permettre la création même avec des emails existants
      console.log('📝 CLIENTS PAGE - Création autorisée même avec email existant');
      
      // Si pas d'email, on peut créer sans problème
      if (!clientFormData.email || !clientFormData.email.trim()) {
        console.log('📝 CLIENTS PAGE - Aucun email fourni, génération d\'un email unique automatique');
      }

      // Générer un nom par défaut si ni prénom ni nom ne sont fournis
      const firstName = clientFormData.firstName || '';
      const lastName = clientFormData.lastName || '';
      const displayName = firstName && lastName 
        ? `${firstName} ${lastName}` 
        : firstName || lastName || 'Client sans nom';
      
      const clientData = {
        firstName: firstName || 'Client',
        lastName: lastName || 'Sans nom',
        email: clientFormData.email || '',
        phone: (clientFormData.countryCode || '33') + (clientFormData.mobile || ''),
        address: clientFormData.address || '',
        notes: clientFormData.internalNote || '',
        
        // Nouveaux champs pour les informations personnelles et entreprise
        category: clientFormData.category || 'particulier',
        title: clientFormData.title || 'mr',
        companyName: clientFormData.companyName || '',
        vatNumber: clientFormData.vatNumber || '',
        sirenNumber: clientFormData.sirenNumber || '',
        countryCode: clientFormData.countryCode || '33',
        
        // Nouveaux champs pour l'adresse détaillée
        addressComplement: clientFormData.addressComplement || '',
        region: clientFormData.region || '',
        postalCode: clientFormData.postalCode || '',
        city: clientFormData.city || '',
        
        // Nouveaux champs pour l'adresse de facturation
        billingAddressSame: clientFormData.billingAddressSame !== undefined ? clientFormData.billingAddressSame : true,
        billingAddress: clientFormData.billingAddress || '',
        billingAddressComplement: clientFormData.billingAddressComplement || '',
        billingRegion: clientFormData.billingRegion || '',
        billingPostalCode: clientFormData.billingPostalCode || '',
        billingCity: clientFormData.billingCity || '',
        
        // Nouveaux champs pour les informations complémentaires
        accountingCode: clientFormData.accountingCode || '',
        cniIdentifier: clientFormData.cniIdentifier || '',
        attachedFilePath: clientFormData.attachedFile ? clientFormData.attachedFile.name : '',
        internalNote: clientFormData.internalNote || '',
        
        // Nouveaux champs pour les préférences
        status: clientFormData.status || 'displayed',
        smsNotification: clientFormData.smsNotification !== undefined ? clientFormData.smsNotification : true,
        emailNotification: clientFormData.emailNotification !== undefined ? clientFormData.emailNotification : true,
        smsMarketing: clientFormData.smsMarketing !== undefined ? clientFormData.smsMarketing : true,
        emailMarketing: clientFormData.emailMarketing !== undefined ? clientFormData.emailMarketing : true,
      };

      console.log('📋 CLIENTS PAGE - Données préparées:', clientData);

      await addClient(clientData, true); // skipDuplicateCheck = true pour la création manuelle

      setClientFormOpen(false);
      
      console.log('✅ CLIENTS PAGE - Client créé avec succès!');
      alert('✅ Client créé avec succès !');
      
    } catch (err: any) {
      console.error('💥 CLIENTS PAGE - Erreur lors de la création du client:', err);
      // Afficher le message d'erreur spécifique
      const errorMessage = err?.message || 'Erreur lors de la création du client. Veuillez réessayer.';
      setError(errorMessage);
      alert(`❌ ${errorMessage}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Fonctions pour la sélection multiple
  const handleSelectAll = () => {
    if (selectedClients.length === clients.length) {
      setSelectedClients([]);
    } else {
      setSelectedClients(clients.map(client => client.id));
    }
  };

  const handleSelectClient = (clientId: string) => {
    setSelectedClients(prev => 
      prev.includes(clientId) 
        ? prev.filter(id => id !== clientId)
        : [...prev, clientId]
    );
  };

  const handleBulkDelete = () => {
    setDeleteDialogOpen(true);
  };

  const confirmBulkDelete = async () => {
    if (selectedClients.length === 0) return;

    setIsDeleting(true);
    setError(null);

    try {
      console.log('🗑️ CLIENTS PAGE - Suppression en masse de', selectedClients.length, 'clients');
      
      // Supprimer chaque client sélectionné
      for (const clientId of selectedClients) {
        await deleteClient(clientId);
      }

      // Recharger la liste des clients
      await loadClients();
      
      // Réinitialiser la sélection
      setSelectedClients([]);
      setDeleteDialogOpen(false);
      
      console.log('✅ CLIENTS PAGE - Suppression en masse terminée!');
      alert(`✅ ${selectedClients.length} client(s) supprimé(s) avec succès !`);
      
    } catch (err: any) {
      console.error('💥 CLIENTS PAGE - Erreur lors de la suppression en masse:', err);
      const errorMessage = err?.message || 'Erreur lors de la suppression. Veuillez réessayer.';
      setError(errorMessage);
      alert(`❌ ${errorMessage}`);
    } finally {
      setIsDeleting(false);
    }
  };

  const handleCloseDeleteDialog = () => {
    setDeleteDialogOpen(false);
  };

  const handleUpdateClient = async (clientFormData: any) => {
    setIsSubmitting(true);
    setError(null);

    try {
      // Vérifier si l'email existe déjà (sauf pour le client en cours d'édition)
      const existingClient = clients.find(c => 
        c.email.toLowerCase() === clientFormData.email.toLowerCase() && 
        c.id !== editingClient.id
      );
      if (existingClient) {
        setError(`Un client avec l'email "${clientFormData.email}" existe déjà.`);
        return;
      }

      const clientData = {
        firstName: clientFormData.firstName,
        lastName: clientFormData.lastName,
        email: clientFormData.email,
        phone: clientFormData.countryCode + clientFormData.mobile,
        address: clientFormData.address,
        notes: clientFormData.internalNote || '',
        
        // Nouveaux champs pour les informations personnelles et entreprise
        category: clientFormData.category,
        title: clientFormData.title,
        companyName: clientFormData.companyName,
        vatNumber: clientFormData.vatNumber,
        sirenNumber: clientFormData.sirenNumber,
        countryCode: clientFormData.countryCode,
        
        // Nouveaux champs pour l'adresse détaillée
        addressComplement: clientFormData.addressComplement,
        region: clientFormData.region,
        postalCode: clientFormData.postalCode,
        city: clientFormData.city,
        
        // Nouveaux champs pour l'adresse de facturation
        billingAddressSame: clientFormData.billingAddressSame,
        billingAddress: clientFormData.billingAddress,
        billingAddressComplement: clientFormData.billingAddressComplement,
        billingRegion: clientFormData.billingRegion,
        billingPostalCode: clientFormData.billingPostalCode,
        billingCity: clientFormData.billingCity,
        
        // Nouveaux champs pour les informations complémentaires
        accountingCode: clientFormData.accountingCode,
        cniIdentifier: clientFormData.cniIdentifier,
        attachedFilePath: clientFormData.attachedFile ? clientFormData.attachedFile.name : null,
        internalNote: clientFormData.internalNote,
        
        // Nouveaux champs pour les préférences
        status: clientFormData.status,
        smsNotification: clientFormData.smsNotification,
        emailNotification: clientFormData.emailNotification,
        smsMarketing: clientFormData.smsMarketing,
        emailMarketing: clientFormData.emailMarketing,
      };

      // Utiliser la fonction updateClient du store
      await updateClient(editingClient.id, clientData);

      setEditClientFormOpen(false);
      setEditingClient(null);
      
      // Recharger les clients pour afficher les modifications
      await loadClients();
      
      alert('✅ Client modifié avec succès !');
      
    } catch (err) {
      console.error('Erreur lors de la modification du client:', err);
      setError('Erreur lors de la modification du client. Veuillez réessayer.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleCsvImport = async (clientsToImport: any[]) => {
    setIsSubmitting(true);
    setError(null);

    try {
      console.log('🚀 CLIENTS PAGE - Début de l\'import CSV:', clientsToImport.length, 'clients');
      
      let importedCount = 0;
      let skippedCount = 0;
      
      // Importer chaque client
      for (const clientData of clientsToImport) {
        // Vérifier si l'email existe déjà (seulement si un email est fourni)
        if (clientData.email && clientData.email.trim()) {
          const existingClient = clients.find(c => c.email && c.email.toLowerCase() === clientData.email.toLowerCase());
          if (existingClient) {
            console.warn(`⚠️ Client avec l'email "${clientData.email}" existe déjà, ignoré`);
            skippedCount++;
            continue;
          }
        }

        console.log('📋 CLIENTS PAGE - Import du client:', clientData.email || clientData.firstName + ' ' + clientData.lastName);
        try {
          const result = await addClient(clientData, true); // skipDuplicateCheck = true
          console.log('📋 CLIENTS PAGE - Résultat addClient:', result);
          if (result && result.success) {
            importedCount++;
          }
        } catch (error) {
          console.error('❌ CLIENTS PAGE - Erreur lors de l\'ajout du client:', error);
          // Si c'est une erreur de doublon, l'ignorer
          if (error.message && error.message.includes('existe déjà')) {
            console.warn('⚠️ CLIENTS PAGE - Client ignoré (déjà présent):', clientData.email);
            skippedCount++;
          } else {
            // Pour les autres erreurs, les propager
            throw error;
          }
        }
      }

      // Recharger la liste des clients
      await loadClients();
      
      console.log('✅ CLIENTS PAGE - Import CSV terminé avec succès!');
      
      // Afficher un résumé détaillé
      if (importedCount > 0 || skippedCount > 0) {
        const message = `Import terminé : ${importedCount} client(s) importé(s)`;
        if (skippedCount > 0) {
          alert(`${message}, ${skippedCount} client(s) ignoré(s) (déjà présents)`);
        } else {
          alert(message);
        }
      }
      
    } catch (err: any) {
      console.error('💥 CLIENTS PAGE - Erreur lors de l\'import CSV:', err);
      const errorMessage = err?.message || 'Erreur lors de l\'import CSV. Veuillez réessayer.';
      setError(errorMessage);
      alert(`❌ ${errorMessage}`);
    } finally {
      setIsSubmitting(false);
      setCsvImportOpen(false);
    }
  };

  const handleExportClients = () => {
    if (clients.length === 0) {
      alert('Aucun client à exporter.');
      return;
    }

    // En-têtes du CSV
    const headers = [
      'Prénom',
      'Nom', 
      'Email',
      'Indicatif',
      'Téléphone mobile',
      'Adresse',
      'Complément adresse',
      'Code postal',
      'Ville',
      'Etat',
      'Pays',
      'Société',
      'N° TVA',
      'N° SIREN',
      'Code Comptable',
      'Titre (M. / Mme)',
      'Identifiant CNI'
    ];

    // Convertir les clients en format CSV
    const csvData = clients.map(client => {
      // Extraire le numéro de téléphone sans l'indicatif
      const phoneWithoutCode = client.phone ? client.phone.replace(client.countryCode || '33', '') : '';
      
      return [
        client.firstName || '',
        client.lastName || '',
        client.email || '',
        client.countryCode || '33',
        phoneWithoutCode,
        client.address || '',
        client.addressComplement || '',
        client.postalCode || '',
        client.city || '',
        client.region || '',
        'France', // Pays par défaut
        client.companyName || '',
        client.vatNumber || '',
        client.sirenNumber || '',
        client.accountingCode || '',
        client.title === 'mrs' ? 'Mme' : 'M.',
        client.cniIdentifier || ''
      ];
    });

    // Créer le contenu CSV
    const csvContent = [
      headers.join(','),
      ...csvData.map(row => row.map(field => `"${field}"`).join(','))
    ].join('\n');

    // Créer et télécharger le fichier
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `clients_export_${new Date().toISOString().split('T')[0]}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    console.log('✅ Export CSV terminé:', clients.length, 'clients exportés');
    alert(`✅ ${clients.length} clients exportés avec succès !`);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
          <Box>
            <Typography variant="h4" gutterBottom sx={{ fontWeight: 600 }}>
              Clients
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Base de données clients
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
            <Box sx={{ 
              background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)',
              color: 'white',
              px: 3,
              py: 1.5,
              borderRadius: 2,
              display: 'flex',
              alignItems: 'center',
              gap: 1,
              boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
            }}>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                {clients.length}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.9 }}>
                {clients.length === 1 ? 'client' : 'clients'}
              </Typography>
            </Box>
          </Box>
        </Box>
      </Box>

      <Box sx={{ mb: 3, display: 'flex', gap: 2, alignItems: 'center' }}>
                <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleOpenDialog}
          sx={{
            background: 'linear-gradient(135deg, #6b7280 0%, #4b5563 100%)',
            '&:hover': {
              background: 'linear-gradient(135deg, #4b5563 0%, #374151 100%)',
            }
          }}
        >
          Nouveau client
        </Button>

        <Button
          variant="outlined"
          startIcon={<UploadIcon />}
          onClick={handleOpenCsvImport}
          sx={{
            borderColor: '#6b7280',
            color: '#6b7280',
            '&:hover': {
              borderColor: '#4b5563',
              backgroundColor: '#f9fafb',
            }
          }}
        >
          Importer CSV
        </Button>

        <Button
          variant="outlined"
          startIcon={<DownloadIcon />}
          onClick={handleExportClients}
          disabled={clients.length === 0}
          sx={{
            borderColor: '#10b981',
            color: '#10b981',
            '&:hover': {
              borderColor: '#059669',
              backgroundColor: '#f0fdf4',
            },
            '&:disabled': {
              borderColor: '#d1d5db',
              color: '#9ca3af',
            }
          }}
        >
          Exporter CSV
        </Button>

        {/* Boutons de sélection multiple */}
        {selectedClients.length > 0 && (
          <>
            <Chip
              label={`${selectedClients.length} sélectionné(s)`}
              color="primary"
              variant="outlined"
              sx={{ ml: 2 }}
            />
            <Button
              variant="contained"
              color="error"
              startIcon={<DeleteSweepIcon />}
              onClick={handleBulkDelete}
              disabled={isDeleting}
              sx={{
                background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                '&:hover': {
                  background: 'linear-gradient(135deg, #dc2626 0%, #b91c1c 100%)',
                }
              }}
            >
              Supprimer sélection
            </Button>
          </>
        )}

        <Button 
          variant="outlined" 
          startIcon={<RefreshIcon />}
          onClick={async () => {
            setIsLoading(true);
            setError(null);
            try {
              await loadClients();
            } catch (err) {
              setError('Erreur lors du rechargement des clients');
            } finally {
              setIsLoading(false);
            }
          }}
          disabled={isLoading}
        >
          Actualiser
        </Button>

        
        {isLoading && <CircularProgress size={20} />}
      </Box>

      {/* Statistiques des clients */}
      <Box sx={{ mb: 3, display: 'flex', gap: 2, flexWrap: 'wrap' }}>
        <Card sx={{ 
          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
          color: 'white',
          minWidth: 200
        }}>
          <CardContent sx={{ p: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
                  {clients.length}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Total clients
                </Typography>
              </Box>
              <Box sx={{ 
                background: 'rgba(255,255,255,0.2)',
                borderRadius: '50%',
                p: 1.5,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <PersonIcon sx={{ fontSize: 24 }} />
              </Box>
            </Box>
          </CardContent>
        </Card>

        <Card sx={{ 
          background: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
          color: 'white',
          minWidth: 200
        }}>
          <CardContent sx={{ p: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
                  {clients.filter(c => c.companyName && c.companyName.trim() !== '').length}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Entreprises
                </Typography>
              </Box>
              <Box sx={{ 
                background: 'rgba(255,255,255,0.2)',
                borderRadius: '50%',
                p: 1.5,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <BusinessIcon sx={{ fontSize: 24 }} />
              </Box>
            </Box>
          </CardContent>
        </Card>

        <Card sx={{ 
          background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
          color: 'white',
          minWidth: 200
        }}>
          <CardContent sx={{ p: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <Box>
                <Typography variant="h4" sx={{ fontWeight: 700, mb: 0.5 }}>
                  {clients.filter(c => c.email && c.email.trim() !== '').length}
                </Typography>
                <Typography variant="body2" sx={{ opacity: 0.9 }}>
                  Avec email
                </Typography>
              </Box>
              <Box sx={{ 
                background: 'rgba(255,255,255,0.2)',
                borderRadius: '50%',
                p: 1.5,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <EmailIcon sx={{ fontSize: 24 }} />
              </Box>
            </Box>
          </CardContent>
        </Card>
      </Box>

      {/* Affichage des erreurs */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}


      <Card>
        <CardContent>
          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell padding="checkbox">
                      <Checkbox
                        indeterminate={selectedClients.length > 0 && selectedClients.length < clients.length}
                        checked={clients.length > 0 && selectedClients.length === clients.length}
                        onChange={handleSelectAll}
                        color="primary"
                      />
                    </TableCell>
                    <TableCell>Client</TableCell>
                    <TableCell>Contact</TableCell>
                    <TableCell>Entreprise</TableCell>
                    <TableCell>Adresse</TableCell>
                    <TableCell>Informations</TableCell>
                    <TableCell>Date d'inscription</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {clients.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={8} sx={{ textAlign: 'center', py: 4 }}>
                        <Typography variant="body2" color="text.secondary">
                          Aucun client trouvé
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : (
                    clients.map((client) => (
                      <TableRow key={client.id}>
                        <TableCell padding="checkbox">
                          <Checkbox
                            checked={selectedClients.includes(client.id)}
                            onChange={() => handleSelectClient(client.id)}
                            color="primary"
                          />
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center' }}>
                            <Avatar sx={{ mr: 2 }}>
                              {client.firstName ? client.firstName.charAt(0) : '?'}
                            </Avatar>
                            <Box>
                              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                                {client.firstName && client.lastName 
                                  ? `${client.firstName} ${client.lastName}`
                                  : client.firstName || client.lastName || 'Client sans nom'
                                }
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box>
                            <Box sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                              <EmailIcon fontSize="small" sx={{ mr: 1, color: 'text.secondary' }} />
                              <Typography variant="body2">
                                {client.email && !client.email.includes('@atelier.local') ? client.email : 'Aucun email'}
                              </Typography>
                            </Box>
                            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                              <PhoneIcon fontSize="small" sx={{ mr: 1, color: 'text.secondary' }} />
                              <Typography variant="body2">
                                {client.phone}
                              </Typography>
                            </Box>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box>
                            <Typography variant="body2" color="text.secondary" sx={{ fontWeight: 500 }}>
                              {client.companyName || '-'}
                            </Typography>
                            {client.vatNumber && (
                              <Typography variant="caption" color="text.secondary">
                                TVA: {client.vatNumber}
                              </Typography>
                            )}
                            {client.sirenNumber && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                SIREN: {client.sirenNumber}
                              </Typography>
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box>
                            <Typography variant="body2" color="text.secondary">
                              {client.address || '-'}
                            </Typography>
                            {client.postalCode && client.city && (
                              <Typography variant="caption" color="text.secondary">
                                {client.postalCode} {client.city}
                              </Typography>
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Box>
                            {client.accountingCode && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Code: {client.accountingCode}
                              </Typography>
                            )}
                            {client.cniIdentifier && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                CNI: {client.cniIdentifier}
                              </Typography>
                            )}
                            {client.notes && (
                              <Typography variant="caption" color="text.secondary" sx={{ display: 'block' }}>
                                Note: {client.notes}
                              </Typography>
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          {new Date(client.createdAt).toLocaleDateString('fr-FR')}
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', gap: 1 }}>
                            <IconButton 
                              size="small" 
                              title="Modifier"
                              onClick={() => handleEditClient(client)}
                            >
                              <EditIcon fontSize="small" />
                            </IconButton>
                            <IconButton 
                              size="small" 
                              title="Supprimer" 
                              color="error"
                              onClick={() => handleDeleteClient(client.id)}
                            >
                              <DeleteIcon fontSize="small" />
                            </IconButton>
                          </Box>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* Formulaire de création de client */}
      <ClientForm
        open={clientFormOpen}
        onClose={handleCloseDialog}
        onSubmit={handleCreateNewClient}
        existingEmails={clients.map(c => c.email).filter(Boolean)}
      />

      {/* Formulaire d'édition de client */}
      <ClientForm
        open={editClientFormOpen}
        onClose={() => {
          setEditClientFormOpen(false);
          setEditingClient(null);
        }}
        onSubmit={handleUpdateClient}
        existingEmails={clients
          .filter(c => c.id !== editingClient?.id) // Exclure le client en cours de modification
          .map(c => c.email)
          .filter(Boolean)}
        initialData={editingClient ? {
          category: editingClient.category || 'particulier',
          title: editingClient.title || 'mr',
          firstName: editingClient.firstName,
          lastName: editingClient.lastName,
          companyName: editingClient.companyName || '',
          vatNumber: editingClient.vatNumber || '',
          sirenNumber: editingClient.sirenNumber || '',
          email: editingClient.email,
          countryCode: editingClient.countryCode || '33',
          mobile: editingClient.phone ? editingClient.phone.replace(editingClient.countryCode || '33', '') : '',
          address: editingClient.address || '',
          addressComplement: editingClient.addressComplement || '',
          region: editingClient.region || '',
          postalCode: editingClient.postalCode || '',
          city: editingClient.city || '',
          billingAddressSame: editingClient.billingAddressSame !== false,
          billingAddress: editingClient.billingAddress || '',
          billingAddressComplement: editingClient.billingAddressComplement || '',
          billingRegion: editingClient.billingRegion || '',
          billingPostalCode: editingClient.billingPostalCode || '',
          billingCity: editingClient.billingCity || '',
          accountingCode: editingClient.accountingCode || '',
          cniIdentifier: editingClient.cniIdentifier || '',
          internalNote: editingClient.internalNote || editingClient.notes || '',
          status: editingClient.status || 'displayed',
          smsNotification: editingClient.smsNotification !== false,
          emailNotification: editingClient.emailNotification !== false,
          smsMarketing: editingClient.smsMarketing !== false,
          emailMarketing: editingClient.emailMarketing !== false,
        } : undefined}
        isEditing={true}
      />

      {/* Dialog d'import CSV */}
      <CSVImport
        open={csvImportOpen}
        onClose={handleCloseCsvImport}
        onImport={handleCsvImport}
      />

      {/* Dialog de confirmation de suppression en masse */}
      <Dialog
        open={deleteDialogOpen}
        onClose={handleCloseDeleteDialog}
        aria-labelledby="delete-dialog-title"
        aria-describedby="delete-dialog-description"
      >
        <DialogTitle id="delete-dialog-title">
          Confirmer la suppression
        </DialogTitle>
        <DialogContent>
          <DialogContentText id="delete-dialog-description">
            Êtes-vous sûr de vouloir supprimer {selectedClients.length} client(s) sélectionné(s) ?
            Cette action est irréversible.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDeleteDialog} color="primary">
            Annuler
          </Button>
          <Button 
            onClick={confirmBulkDelete} 
            color="error" 
            variant="contained"
            disabled={isDeleting}
            startIcon={isDeleting ? <CircularProgress size={20} /> : <DeleteSweepIcon />}
          >
            {isDeleting ? 'Suppression...' : 'Supprimer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Clients;
