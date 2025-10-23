import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Typography,
  Switch,
  FormControlLabel,
  IconButton,
  Tooltip,
  Alert,
} from '@mui/material';
import {
  Close as CloseIcon,
  Print as PrintIcon,
  Preview as PreviewIcon,
} from '@mui/icons-material';
import { Repair, Client, Device, User, Sale } from '../types';
import { thermalPrintService, ThermalReceiptData, ThermalReceiptFormat, ThermalReceiptOptions } from '../services/thermalPrintService';

interface ThermalReceiptDialogProps {
  open: boolean;
  onClose: () => void;
  repair?: Repair;
  sale?: Sale;
  client?: Client;
  device?: Device;
  technician?: User;
  workshopInfo: {
    name: string;
    address?: string;
    phone?: string;
    email?: string;
    siret?: string;
    vatNumber?: string;
  };
}

const ThermalReceiptDialog: React.FC<ThermalReceiptDialogProps> = ({
  open,
  onClose,
  repair,
  sale,
  client,
  device,
  technician,
  workshopInfo,
}) => {
  const [format, setFormat] = useState<ThermalReceiptFormat>('80mm');
  const [showConditions, setShowConditions] = useState(true);
  const [showServices, setShowServices] = useState(true);
  const [showParts, setShowParts] = useState(true);
  const [previewMode, setPreviewMode] = useState(false);

  const handlePrint = () => {
    if (repair) {
      // Impression pour réparation
      const data: ThermalReceiptData = {
        repair,
        client: client,
        device,
        technician,
        workshopInfo,
      };

      const options: ThermalReceiptOptions = {
        format,
        showConditions,
        showServices,
        showParts,
      };

      thermalPrintService.printReceipt(data, options);
    } else if (sale) {
      // Impression pour vente - convertir Sale en Repair pour le service
      const repairData: Repair = {
        id: sale.id,
        repairNumber: sale.id.slice(0, 8),
        clientId: sale.clientId || '',
        deviceId: null,
        status: sale.status,
        assignedTechnicianId: undefined,
        description: `Vente - ${Array.isArray(sale.items) ? sale.items.map(item => item.name).join(', ') : 'Articles'}`,
        issue: '',
        estimatedDuration: 0,
        actualDuration: undefined,
        estimatedStartDate: undefined,
        estimatedEndDate: undefined,
        startDate: undefined,
        endDate: undefined,
        dueDate: new Date(sale.createdAt),
        isUrgent: false,
        notes: '',
        services: Array.isArray(sale.items) ? sale.items.filter(item => item.type === 'service').map(item => ({
          id: item.id,
          serviceId: item.id,
          quantity: item.quantity,
          price: item.unitPrice,
        })) : [],
        parts: Array.isArray(sale.items) ? sale.items.filter(item => item.type === 'part').map(item => ({
          id: item.id,
          partId: item.id,
          quantity: item.quantity,
          price: item.unitPrice,
          isUsed: true,
        })) : [],
        totalPrice: sale.total,
        discountPercentage: 0,
        discountAmount: 0,
        originalPrice: sale.total,
        isPaid: sale.status === 'completed',
        source: 'sale' as const,
        createdAt: new Date(sale.createdAt),
        updatedAt: new Date(sale.updatedAt),
      };

      const data: ThermalReceiptData = {
        repair: repairData,
        client: client,
        device,
        technician,
        workshopInfo,
      };

      const options: ThermalReceiptOptions = {
        format,
        showConditions,
        showServices,
        showParts,
      };

      thermalPrintService.printReceipt(data, options);
    }
  };

  const handlePreview = () => {
    setPreviewMode(!previewMode);
  };

  const generatePreviewHTML = () => {
    if (repair) {
      const data: ThermalReceiptData = {
        repair,
        client: client,
        device,
        technician,
        workshopInfo,
      };

      const options: ThermalReceiptOptions = {
        format,
        showConditions,
        showServices,
        showParts,
      };

      return thermalPrintService.generateReceiptHTML(data, options);
    } else if (sale) {
      // Convertir Sale en Repair pour l'aperçu
      const repairData: Repair = {
        id: sale.id,
        repairNumber: sale.id.slice(0, 8),
        clientId: sale.clientId || '',
        deviceId: null,
        status: sale.status,
        assignedTechnicianId: undefined,
        description: `Vente - ${Array.isArray(sale.items) ? sale.items.map(item => item.name).join(', ') : 'Articles'}`,
        issue: '',
        estimatedDuration: 0,
        actualDuration: undefined,
        estimatedStartDate: undefined,
        estimatedEndDate: undefined,
        startDate: undefined,
        endDate: undefined,
        dueDate: new Date(sale.createdAt),
        isUrgent: false,
        notes: '',
        services: Array.isArray(sale.items) ? sale.items.filter(item => item.type === 'service').map(item => ({
          id: item.id,
          serviceId: item.id,
          quantity: item.quantity,
          price: item.unitPrice,
        })) : [],
        parts: Array.isArray(sale.items) ? sale.items.filter(item => item.type === 'part').map(item => ({
          id: item.id,
          partId: item.id,
          quantity: item.quantity,
          price: item.unitPrice,
          isUsed: true,
        })) : [],
        totalPrice: sale.total,
        discountPercentage: 0,
        discountAmount: 0,
        originalPrice: sale.total,
        isPaid: sale.status === 'completed',
        source: 'sale' as const,
        createdAt: new Date(sale.createdAt),
        updatedAt: new Date(sale.updatedAt),
      };

      const data: ThermalReceiptData = {
        repair: repairData,
        client: client,
        device,
        technician,
        workshopInfo,
      };

      const options: ThermalReceiptOptions = {
        format,
        showConditions,
        showServices,
        showParts,
      };

      return thermalPrintService.generateReceiptHTML(data, options);
    }
    return '';
  };

  const getTitle = () => {
    if (repair) {
      return `Reçu Thermique - ${repair.repairNumber || `REP-${repair.id.slice(0, 8)}`}`;
    } else if (sale) {
      return `Reçu Thermique - Vente ${sale.id.slice(0, 8)}`;
    }
    return 'Reçu Thermique';
  };

  return (
    <Dialog 
      open={open} 
      onClose={onClose} 
      maxWidth="md" 
      fullWidth
      PaperProps={{
        sx: { minHeight: '600px' }
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6">
            {getTitle()}
          </Typography>
          <IconButton onClick={onClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent>
        <Box sx={{ display: 'flex', gap: 3, height: '100%' }}>
          {/* Configuration */}
          <Box sx={{ flex: 1, minWidth: '300px' }}>
            <Typography variant="h6" gutterBottom>
              Configuration
            </Typography>

            <FormControl fullWidth sx={{ mb: 3 }}>
              <InputLabel>Format d'impression</InputLabel>
              <Select
                value={format}
                onChange={(e) => setFormat(e.target.value as ThermalReceiptFormat)}
                label="Format d'impression"
              >
                <MenuItem value="58mm">58mm (Format étroit)</MenuItem>
                <MenuItem value="80mm">80mm (Format standard)</MenuItem>
              </Select>
            </FormControl>

            <Box sx={{ mb: 3 }}>
              <Typography variant="subtitle2" gutterBottom>
                Contenu à inclure
              </Typography>
              
              <FormControlLabel
                control={
                  <Switch
                    checked={showServices}
                    onChange={(e) => setShowServices(e.target.checked)}
                  />
                }
                label="Services"
              />
              
              <FormControlLabel
                control={
                  <Switch
                    checked={showParts}
                    onChange={(e) => setShowParts(e.target.checked)}
                  />
                }
                label="Pièces détachées"
              />
              
              <FormControlLabel
                control={
                  <Switch
                    checked={showConditions}
                    onChange={(e) => setShowConditions(e.target.checked)}
                  />
                }
                label="Conditions générales"
              />
            </Box>

            <Alert severity="info" sx={{ mb: 2 }}>
              <Typography variant="body2">
                <strong>Format 58mm:</strong> Idéal pour les imprimantes thermiques portables
                <br />
                <strong>Format 80mm:</strong> Standard pour les imprimantes de caisse
              </Typography>
            </Alert>

            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                Assurez-vous que votre imprimante thermique est configurée et connectée avant d'imprimer.
              </Typography>
            </Alert>
          </Box>

          {/* Aperçu */}
          <Box sx={{ flex: 1, minWidth: '300px' }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="h6">
                Aperçu
              </Typography>
              <Tooltip title={previewMode ? "Masquer l'aperçu" : "Afficher l'aperçu"}>
                <IconButton onClick={handlePreview} size="small">
                  <PreviewIcon />
                </IconButton>
              </Tooltip>
            </Box>

            {previewMode && (
              <Box
                sx={{
                  border: '1px solid #ccc',
                  borderRadius: 1,
                  p: 1,
                  backgroundColor: '#f9f9f9',
                  maxHeight: '400px',
                  overflow: 'auto',
                }}
              >
                <Box
                  dangerouslySetInnerHTML={{ __html: generatePreviewHTML() }}
                  sx={{
                    transform: 'scale(0.8)',
                    transformOrigin: 'top left',
                    width: '125%',
                  }}
                />
              </Box>
            )}

            {!previewMode && (
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  height: '200px',
                  border: '2px dashed #ccc',
                  borderRadius: 1,
                  backgroundColor: '#f9f9f9',
                }}
              >
                <Typography variant="body2" color="text.secondary">
                  Cliquez sur l'icône d'aperçu pour voir le reçu
                </Typography>
              </Box>
            )}
          </Box>
        </Box>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>
          Annuler
        </Button>
        <Button
          onClick={handlePrint}
          variant="contained"
          startIcon={<PrintIcon />}
          color="primary"
        >
          Imprimer
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ThermalReceiptDialog;