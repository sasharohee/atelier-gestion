import React, { useState, useRef } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Alert,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  CloudUpload as UploadIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Close as CloseIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';

interface CSVImportProps {
  open: boolean;
  onClose: () => void;
  onImport: (clients: any[]) => Promise<void>;
}

interface ParsedClient {
  firstName: string;
  lastName: string;
  email: string;
  countryCode: string;
  mobile: string;
  address: string;
  addressComplement: string;
  postalCode: string;
  city: string;
  region: string;
  country: string;
  companyName: string;
  vatNumber: string;
  sirenNumber: string;
  accountingCode: string;
  title: string;
  cniIdentifier: string;
  isValid: boolean;
  errors: string[];
}

const CSVImport: React.FC<CSVImportProps> = ({ open, onClose, onImport }) => {
  const [file, setFile] = useState<File | null>(null);
  const [parsedData, setParsedData] = useState<ParsedClient[]>([]);
  const [isProcessing, setIsProcessing] = useState(false);
  const [importProgress, setImportProgress] = useState(0);
  const [importStatus, setImportStatus] = useState<'idle' | 'parsing' | 'importing' | 'completed' | 'error'>('idle');
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Template CSV attendu
  const expectedHeaders = [
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

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = event.target.files?.[0];
    if (selectedFile && selectedFile.type === 'text/csv') {
      setFile(selectedFile);
      setError(null);
      parseCSV(selectedFile);
    } else {
      setError('Veuillez sélectionner un fichier CSV valide.');
    }
  };

  const parseCSV = async (file: File) => {
    setIsProcessing(true);
    setImportStatus('parsing');
    
    try {
      const text = await file.text();
      const lines = text.split('\n').filter(line => line.trim());
      
      if (lines.length < 2) {
        throw new Error('Le fichier CSV doit contenir au moins un en-tête et une ligne de données.');
      }

      // Vérifier les en-têtes
      const headers = lines[0].split(',').map(h => h.trim().replace(/"/g, ''));
      const missingHeaders = expectedHeaders.filter(expected => 
        !headers.some(header => header.toLowerCase().includes(expected.toLowerCase()))
      );

      if (missingHeaders.length > 0) {
        throw new Error(`En-têtes manquants: ${missingHeaders.join(', ')}`);
      }

      // Parser les données
      const clients: ParsedClient[] = [];
      
      for (let i = 1; i < lines.length; i++) {
        const values = lines[i].split(',').map(v => v.trim().replace(/"/g, ''));
        const errors: string[] = [];
        
        // Validation des champs obligatoires
        if (!values[0] || !values[1] || !values[2]) {
          errors.push('Prénom, Nom et Email sont obligatoires');
        }
        
        if (values[2] && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(values[2])) {
          errors.push('Format email invalide');
        }

        const client: ParsedClient = {
          firstName: values[0] || '',
          lastName: values[1] || '',
          email: values[2] || '',
          countryCode: values[3] || '33',
          mobile: values[4] || '',
          address: values[5] || '',
          addressComplement: values[6] || '',
          postalCode: values[7] || '',
          city: values[8] || '',
          region: values[9] || '',
          country: values[10] || 'France',
          companyName: values[11] || '',
          vatNumber: values[12] || '',
          sirenNumber: values[13] || '',
          accountingCode: values[14] || '',
          title: values[15] === 'Mme' ? 'mrs' : 'mr',
          cniIdentifier: values[16] || '',
          isValid: errors.length === 0,
          errors
        };

        clients.push(client);
      }

      setParsedData(clients);
      setImportStatus('idle');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors du parsing du fichier CSV');
      setImportStatus('error');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleImport = async () => {
    const validClients = parsedData.filter(client => client.isValid);
    
    if (validClients.length === 0) {
      setError('Aucun client valide à importer.');
      return;
    }

    setIsProcessing(true);
    setImportStatus('importing');
    setImportProgress(0);

    try {
      const batchSize = 5;
      const totalBatches = Math.ceil(validClients.length / batchSize);
      
      for (let i = 0; i < totalBatches; i++) {
        const batch = validClients.slice(i * batchSize, (i + 1) * batchSize);
        
        // Préparer les données pour l'import
        const clientsToImport = batch.map(client => ({
          firstName: client.firstName,
          lastName: client.lastName,
          email: client.email,
          phone: client.countryCode + client.mobile,
          address: client.address,
          notes: '',
          category: client.companyName ? 'entreprise' : 'particulier',
          title: client.title,
          companyName: client.companyName,
          vatNumber: client.vatNumber,
          sirenNumber: client.sirenNumber,
          countryCode: client.countryCode,
          addressComplement: client.addressComplement,
          region: client.region,
          postalCode: client.postalCode,
          city: client.city,
          billingAddressSame: true,
          billingAddress: client.address,
          billingAddressComplement: client.addressComplement,
          billingRegion: client.region,
          billingPostalCode: client.postalCode,
          billingCity: client.city,
          accountingCode: client.accountingCode,
          cniIdentifier: client.cniIdentifier,
          attachedFilePath: '',
          internalNote: '',
          status: 'displayed',
          smsNotification: true,
          emailNotification: true,
          smsMarketing: true,
          emailMarketing: true,
        }));

        await onImport(clientsToImport);
        
        setImportProgress(((i + 1) / totalBatches) * 100);
      }

      setImportStatus('completed');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur lors de l\'import');
      setImportStatus('error');
    } finally {
      setIsProcessing(false);
    }
  };

  const handleClose = () => {
    setFile(null);
    setParsedData([]);
    setError(null);
    setImportStatus('idle');
    setImportProgress(0);
    onClose();
  };

  const downloadTemplate = () => {
    const csvContent = expectedHeaders.join(',') + '\n';
    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'template_clients.csv';
    link.click();
    window.URL.revokeObjectURL(url);
  };

  const validClientsCount = parsedData.filter(client => client.isValid).length;
  const invalidClientsCount = parsedData.filter(client => !client.isValid).length;

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="lg" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Typography variant="h6">Import de clients CSV</Typography>
          <Box sx={{ display: 'flex', gap: 1 }}>
            <Button
              variant="outlined"
              startIcon={<DownloadIcon />}
              onClick={downloadTemplate}
              size="small"
            >
              Télécharger le template
            </Button>
            <IconButton onClick={handleClose} size="small">
              <CloseIcon />
            </IconButton>
          </Box>
        </Box>
      </DialogTitle>

      <DialogContent>
        {!file ? (
          <Box sx={{ textAlign: 'center', py: 4 }}>
            <UploadIcon sx={{ fontSize: 64, color: 'text.secondary', mb: 2 }} />
            <Typography variant="h6" gutterBottom>
              Sélectionnez un fichier CSV
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
              Le fichier doit suivre le template fourni avec les colonnes suivantes:
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, justifyContent: 'center', mb: 3 }}>
              {expectedHeaders.map(header => (
                <Chip key={header} label={header} size="small" variant="outlined" />
              ))}
            </Box>
            <Button
              variant="contained"
              component="label"
              startIcon={<UploadIcon />}
              sx={{ mb: 2 }}
            >
              Choisir un fichier CSV
              <input
                ref={fileInputRef}
                type="file"
                accept=".csv"
                hidden
                onChange={handleFileSelect}
              />
            </Button>
          </Box>
        ) : (
          <Box>
            {error && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {error}
              </Alert>
            )}

            {isProcessing && (
              <Box sx={{ mb: 2 }}>
                <Typography variant="body2" sx={{ mb: 1 }}>
                  {importStatus === 'parsing' ? 'Analyse du fichier...' : 'Import en cours...'}
                </Typography>
                <LinearProgress variant="determinate" value={importProgress} />
              </Box>
            )}

            {parsedData.length > 0 && (
              <Box>
                <Box sx={{ display: 'flex', gap: 2, mb: 2, alignItems: 'center' }}>
                  <Typography variant="h6">
                    Aperçu des données ({parsedData.length} clients)
                  </Typography>
                  <Chip 
                    label={`${validClientsCount} valides`} 
                    color="success" 
                    size="small"
                  />
                  {invalidClientsCount > 0 && (
                    <Chip 
                      label={`${invalidClientsCount} invalides`} 
                      color="error" 
                      size="small"
                    />
                  )}
                </Box>

                <TableContainer component={Paper} sx={{ maxHeight: 400 }}>
                  <Table stickyHeader>
                    <TableHead>
                      <TableRow>
                        <TableCell>Nom</TableCell>
                        <TableCell>Email</TableCell>
                        <TableCell>Téléphone</TableCell>
                        <TableCell>Entreprise</TableCell>
                        <TableCell>Statut</TableCell>
                        <TableCell>Erreurs</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {parsedData.slice(0, 10).map((client, index) => (
                        <TableRow key={index}>
                          <TableCell>
                            {client.firstName} {client.lastName}
                          </TableCell>
                          <TableCell>{client.email}</TableCell>
                          <TableCell>{client.countryCode} {client.mobile}</TableCell>
                          <TableCell>{client.companyName || '-'}</TableCell>
                          <TableCell>
                            {client.isValid ? (
                              <Chip icon={<CheckIcon />} label="Valide" color="success" size="small" />
                            ) : (
                              <Chip icon={<ErrorIcon />} label="Invalide" color="error" size="small" />
                            )}
                          </TableCell>
                          <TableCell>
                            {client.errors.length > 0 && (
                              <Tooltip title={client.errors.join(', ')}>
                                <Typography variant="caption" color="error">
                                  {client.errors.length} erreur(s)
                                </Typography>
                              </Tooltip>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>

                {parsedData.length > 10 && (
                  <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                    Affichage des 10 premiers clients sur {parsedData.length}
                  </Typography>
                )}
              </Box>
            )}
          </Box>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={handleClose}>
          Annuler
        </Button>
        {file && parsedData.length > 0 && (
          <Button
            variant="contained"
            onClick={handleImport}
            disabled={isProcessing || validClientsCount === 0}
            startIcon={<UploadIcon />}
          >
            {isProcessing ? 'Import en cours...' : `Importer ${validClientsCount} clients`}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default CSVImport;
