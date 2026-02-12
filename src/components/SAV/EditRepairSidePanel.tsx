import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Drawer,
  Box,
  Typography,
  IconButton,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Autocomplete,
  FormControlLabel,
  Checkbox,
  Switch,
  Grid,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Alert,
  Chip,
  CircularProgress,
  Divider,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import {
  Close as CloseIcon,
  ExpandMore as ExpandMoreIcon,
  Person as PersonIcon,
  DeviceHub as DeviceIcon,
  Description as DescriptionIcon,
  Schedule as ScheduleIcon,
  Build as BuildIcon,
  Warning as WarningIcon,
  CheckCircle as CheckCircleIcon,
  Draw as DrawIcon,
  Add as AddIcon,
  Print as PrintIcon,
  QrCode2 as QrCodeIcon,
  Edit as EditIcon,
  Payment as PaymentIcon,
} from '@mui/icons-material';
import { QRCodeSVG } from 'qrcode.react';
import { Client, Device, User, RepairStatus, Repair, DeviceType } from '../../types';
import { DeviceModel } from '../../types/deviceManagement';
import { BrandWithCategories } from '../../services/brandService';
import { DeviceCategory } from '../../types/deviceManagement';
import { interventionService } from '../../services/interventionService';
import { getRepairEligibleUsers, getRepairUserDisplayName } from '../../utils/userUtils';
import { formatFromEUR, getCurrencySymbol } from '../../utils/currencyUtils';

interface EditRepairSidePanelProps {
  open: boolean;
  onClose: () => void;
  // Data from store
  clients: Client[];
  users: User[];
  repairStatuses: RepairStatus[];
  deviceModels: DeviceModel[];
  dbCategories: DeviceCategory[];
  dbBrands: BrandWithCategories[];
  // Edit repair state (managed by parent)
  editRepair: {
    clientId: string;
    deviceId: string;
    description: string;
    issue: string;
    status: string;
    isUrgent: boolean;
    totalPrice: number;
    discountPercentage: number;
    deposit: number;
    depositPaymentMethod: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
    finalPaymentMethod: '' | 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
    paymentMethod: 'cash' | 'card' | 'transfer' | 'check' | 'payment_link';
    isPaid: boolean;
    dueDate: string;
    assignedTechnicianId: string;
    selectedServices: string[];
  };
  onEditRepairChange: (field: string, value: any) => void;
  // Intervention data (managed by parent)
  interventionData: {
    technicianName: string;
    deviceCondition: string;
    visibleDamages: string;
    missingParts: string;
    passwordProvided: boolean;
    dataBackup: boolean;
    initialDiagnosis: string;
    proposedSolution: string;
    estimatedDuration: string;
    dataLossRisk: boolean;
    dataLossRiskDetails: string;
    cosmeticChanges: boolean;
    cosmeticChangesDetails: string;
    warrantyVoid: boolean;
    warrantyVoidDetails: string;
    clientAuthorizesRepair: boolean;
    clientAuthorizesDataAccess: boolean;
    clientAuthorizesReplacement: boolean;
    additionalNotes: string;
    specialInstructions: string;
    termsAccepted: boolean;
    liabilityAccepted: boolean;
    authType: string;
    accessCode: string;
    patternPoints: number[];
    patternDescription: string;
    securityInfo: string;
    accessConfirmed: boolean;
    backupBeforeAccess: boolean;
  };
  onInterventionDataChange: (data: any) => void;
  // Selected repair being edited
  selectedRepair: Repair | null;
  // Brand/Category selection (managed by parent)
  selectedBrand: string;
  selectedCategory: string;
  onSelectedBrandChange: (brand: string) => void;
  onSelectedCategoryChange: (category: string) => void;
  // Filtered models and services
  getFilteredModels: () => DeviceModel[];
  getServicesForEditModel: () => any[];
  getUniqueBrands: () => string[];
  getUniqueCategories: () => string[];
  // Actions
  onSaveRepair: () => void;
  onGenerateIntervention: () => void;
  onOpenClientForm: () => void;
  onOpenBrandDialog: () => void;
  onOpenCategoryDialog: () => void;
  onOpenModelDialog: () => void;
  // Settings
  currency: string;
  getClientById: (id: string) => Client | undefined;
  // Existing intervention data (signature, etc.)
  existingIntervention?: {
    id: string;
    signatureToken: string | null;
    signatureStatus: string;
    signatureImage: string | null;
  } | null;
}

const EditRepairSidePanel: React.FC<EditRepairSidePanelProps> = ({
  open,
  onClose,
  clients,
  users,
  repairStatuses,
  deviceModels,
  dbCategories,
  dbBrands,
  editRepair,
  onEditRepairChange,
  interventionData,
  onInterventionDataChange,
  selectedRepair,
  selectedBrand,
  selectedCategory,
  onSelectedBrandChange,
  onSelectedCategoryChange,
  getFilteredModels,
  getServicesForEditModel,
  getUniqueBrands,
  getUniqueCategories,
  onSaveRepair,
  onGenerateIntervention,
  onOpenClientForm,
  onOpenBrandDialog,
  onOpenCategoryDialog,
  onOpenModelDialog,
  currency,
  getClientById,
  existingIntervention,
}) => {
  const theme = useTheme();
  const isSmall = useMediaQuery(theme.breakpoints.down('sm'));
  const isMedium = useMediaQuery(theme.breakpoints.between('sm', 'lg'));

  const currencySymbol = getCurrencySymbol(currency);

  // Expanded accordion sections
  const [expanded, setExpanded] = useState<string[]>(['client-device', 'description']);

  // Signature state
  const [signatureToken, setSignatureToken] = useState<string | null>(null);
  const [signatureStatus, setSignatureStatus] = useState<string>('pending');
  const [signatureImage, setSignatureImage] = useState<string | null>(null);
  const [interventionId, setInterventionId] = useState<string | null>(null);
  const [generatingQR, setGeneratingQR] = useState(false);
  const pollingRef = useRef<NodeJS.Timeout | null>(null);

  // Drawer width
  const drawerWidth = isSmall ? '100vw' : isMedium ? 440 : 520;

  const handleAccordionChange = (panel: string) => (_: React.SyntheticEvent, isExpanded: boolean) => {
    setExpanded(prev =>
      isExpanded ? [...prev, panel] : prev.filter(p => p !== panel)
    );
  };

  // Poll signature status (resilient to errors)
  const startPolling = useCallback((intId: string) => {
    if (pollingRef.current) clearInterval(pollingRef.current);
    pollingRef.current = setInterval(async () => {
      try {
        const result = await interventionService.getSignatureStatus(intId);
        if (result.success && result.data) {
          setSignatureStatus(result.data.signature_status || 'pending');
          if (result.data.signature_image) {
            setSignatureImage(result.data.signature_image);
          }
          if (result.data.signature_status === 'signed') {
            if (pollingRef.current) clearInterval(pollingRef.current);
          }
        }
      } catch {
        // Ignore polling errors
      }
    }, 5000);
  }, []);

  // Initialize signature state from existing intervention when panel opens
  useEffect(() => {
    if (open && existingIntervention) {
      setInterventionId(existingIntervention.id);
      setSignatureToken(existingIntervention.signatureToken);
      setSignatureStatus(existingIntervention.signatureStatus || 'pending');
      setSignatureImage(existingIntervention.signatureImage);
      // If signature was sent but not yet signed, start polling
      if (existingIntervention.signatureStatus === 'sent' && existingIntervention.id) {
        startPolling(existingIntervention.id);
      }
    } else if (!open) {
      if (pollingRef.current) clearInterval(pollingRef.current);
      setSignatureToken(null);
      setSignatureStatus('pending');
      setSignatureImage(null);
      setInterventionId(null);
    }
  }, [open, existingIntervention, startPolling]);

  // Cleanup polling on unmount
  useEffect(() => {
    return () => {
      if (pollingRef.current) clearInterval(pollingRef.current);
    };
  }, []);

  // Handle creating/updating the intervention and generating QR code
  const handleGenerateQR = async () => {
    if (!editRepair.clientId || !editRepair.deviceId || !editRepair.description) {
      alert('Veuillez d\'abord remplir les informations client, appareil et description.');
      return;
    }

    setGeneratingQR(true);
    try {
      const client = getClientById(editRepair.clientId);
      const selectedModel = deviceModels.find(m => m.id === editRepair.deviceId);

      const interventionPayload = {
        repair_id: selectedRepair?.id || '',
        intervention_date: new Date().toISOString().split('T')[0],
        technician_name: interventionData.technicianName || 'Non assigné',
        client_name: client ? `${client.firstName} ${client.lastName}` : '',
        client_phone: client?.phone || '',
        client_email: client?.email || '',
        device_brand: selectedModel?.brandName || '',
        device_model: selectedModel?.model || selectedModel?.name || '',
        device_serial_number: '',
        device_type: selectedModel?.categoryName || '',
        device_condition: interventionData.deviceCondition || '',
        visible_damages: interventionData.visibleDamages || '',
        missing_parts: interventionData.missingParts || '',
        password_provided: interventionData.passwordProvided,
        data_backup: interventionData.dataBackup,
        reported_issue: editRepair.description,
        initial_diagnosis: interventionData.initialDiagnosis || '',
        proposed_solution: interventionData.proposedSolution || '',
        estimated_cost: editRepair.totalPrice,
        estimated_duration: interventionData.estimatedDuration || '',
        data_loss_risk: interventionData.dataLossRisk,
        data_loss_risk_details: interventionData.dataLossRiskDetails || '',
        cosmetic_changes: interventionData.cosmeticChanges,
        cosmetic_changes_details: interventionData.cosmeticChangesDetails || '',
        warranty_void: interventionData.warrantyVoid,
        warranty_void_details: interventionData.warrantyVoidDetails || '',
        client_authorizes_repair: interventionData.clientAuthorizesRepair,
        client_authorizes_data_access: interventionData.clientAuthorizesDataAccess,
        client_authorizes_replacement: interventionData.clientAuthorizesReplacement,
        additional_notes: interventionData.additionalNotes || '',
        special_instructions: interventionData.specialInstructions || '',
        terms_accepted: interventionData.termsAccepted,
        liability_accepted: interventionData.liabilityAccepted,
      };

      const result = await interventionService.createWithToken(interventionPayload);
      if (!result.success || !result.data) {
        const errMsg = (result.error as any)?.message || 'Erreur lors de la création';
        throw new Error(errMsg);
      }

      const { id: intId, token } = result.data;
      setInterventionId(intId);
      setSignatureToken(token);
      setSignatureStatus('sent');
      startPolling(intId);
    } catch (error: any) {
      console.error('Erreur QR:', error);
      alert('Erreur lors de la génération du QR code: ' + (error.message || 'Erreur inconnue'));
    } finally {
      setGeneratingQR(false);
    }
  };

  const signatureUrl = signatureToken
    ? `${window.location.origin}/sign/${signatureToken}`
    : '';

  // Computed values
  const finalPrice = editRepair.totalPrice * (100 - (editRepair.discountPercentage || 0)) / 100;
  const remainingBalance = Math.max(0, finalPrice - (editRepair.deposit || 0));

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      SlideProps={{ direction: 'left' }}
      transitionDuration={350}
      PaperProps={{
        sx: {
          width: drawerWidth,
          maxWidth: '100vw',
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          px: 3,
          py: 2,
          borderBottom: '1px solid',
          borderColor: 'divider',
          backgroundColor: '#f8fafc',
          position: 'sticky',
          top: 0,
          zIndex: 10,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <EditIcon sx={{ color: '#2563eb' }} />
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Modifier la réparation
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </Box>

      {/* Body - Scrollable */}
      <Box sx={{ flex: 1, overflow: 'auto', pb: 10 }}>

        {/* Section 1: Client & Appareil */}
        <Accordion
          expanded={expanded.includes('client-device')}
          onChange={handleAccordionChange('client-device')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <PersonIcon color="primary" fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Client & Appareil</Typography>
              {editRepair.clientId && editRepair.deviceId && (
                <CheckCircleIcon sx={{ color: '#16a34a', fontSize: 18 }} />
              )}
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              {/* Client */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <Autocomplete
                    fullWidth
                    options={clients}
                    getOptionLabel={(client) =>
                      `${client.firstName} ${client.lastName}${client.email ? ` - ${client.email}` : ''}${client.phone ? ` - ${client.phone}` : ''}`
                    }
                    value={clients.find((c) => c.id === editRepair.clientId) || null}
                    onChange={(_, val) => onEditRepairChange('clientId', val?.id || '')}
                    renderInput={(params) => (
                      <TextField {...params} label="Client *" placeholder="Rechercher..." size="small" />
                    )}
                    renderOption={({ key, ...optionProps }, client) => (
                      <Box component="li" key={key} {...optionProps}>
                        <Box>
                          <Typography variant="body2" sx={{ fontWeight: 500 }}>
                            {client.firstName} {client.lastName}
                          </Typography>
                          {client.phone && (
                            <Typography variant="caption" color="text.secondary">
                              {client.phone}
                            </Typography>
                          )}
                        </Box>
                      </Box>
                    )}
                    filterOptions={(options, { inputValue }) => {
                      const f = inputValue.toLowerCase();
                      return options.filter(
                        (c) =>
                          c.firstName.toLowerCase().includes(f) ||
                          c.lastName.toLowerCase().includes(f) ||
                          (c.email && c.email.toLowerCase().includes(f)) ||
                          (c.phone && c.phone.includes(f))
                      );
                    }}
                    noOptionsText="Aucun client trouvé"
                    size="small"
                  />
                  <IconButton
                    onClick={onOpenClientForm}
                    color="primary"
                    sx={{ border: '1px solid', borderColor: 'primary.main', borderRadius: 1 }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Box>
              </Grid>

              {/* Brand filter */}
              <Grid item xs={6}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>Marque</InputLabel>
                    <Select
                      label="Marque"
                      value={selectedBrand}
                      onChange={(e) => {
                        onSelectedBrandChange(e.target.value);
                        onEditRepairChange('deviceId', '');
                      }}
                    >
                      <MenuItem value="">Toutes</MenuItem>
                      {getUniqueBrands().map((b) => (
                        <MenuItem key={b} value={b}>{b}</MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  <IconButton
                    onClick={onOpenBrandDialog}
                    color="primary"
                    size="small"
                    sx={{ border: '1px solid', borderColor: 'primary.main', borderRadius: 1 }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Box>
              </Grid>

              {/* Category filter */}
              <Grid item xs={6}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>Catégorie</InputLabel>
                    <Select
                      label="Catégorie"
                      value={selectedCategory}
                      onChange={(e) => {
                        onSelectedCategoryChange(e.target.value);
                        onSelectedBrandChange('');
                        onEditRepairChange('deviceId', '');
                      }}
                    >
                      <MenuItem value="">Toutes</MenuItem>
                      {getUniqueCategories().map((c) => (
                        <MenuItem key={c} value={c}>{c}</MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  <IconButton
                    onClick={onOpenCategoryDialog}
                    color="primary"
                    size="small"
                    sx={{ border: '1px solid', borderColor: 'primary.main', borderRadius: 1 }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Box>
              </Grid>

              {/* Model */}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', alignItems: 'flex-end', gap: 1 }}>
                  <FormControl fullWidth size="small">
                    <InputLabel>Modèle *</InputLabel>
                    <Select
                      label="Modèle *"
                      value={editRepair.deviceId || ''}
                      onChange={(e) => {
                        onEditRepairChange('deviceId', e.target.value);
                        onEditRepairChange('selectedServices', []);
                      }}
                      disabled={getFilteredModels().length === 0}
                    >
                      {getFilteredModels().map((model) => (
                        <MenuItem key={model.id} value={model.id}>
                          {model.brandName} {model.name || model.model} ({model.categoryName})
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  <IconButton
                    onClick={onOpenModelDialog}
                    color="primary"
                    size="small"
                    sx={{ border: '1px solid', borderColor: 'primary.main', borderRadius: 1 }}
                  >
                    <AddIcon fontSize="small" />
                  </IconButton>
                </Box>
              </Grid>

              {/* Services */}
              {editRepair.deviceId && getServicesForEditModel().length > 0 && (
                <Grid item xs={12}>
                  <FormControl fullWidth size="small">
                    <InputLabel>Services associés</InputLabel>
                    <Select
                      multiple
                      label="Services associés"
                      value={editRepair.selectedServices}
                      onChange={(e) => onEditRepairChange('selectedServices', e.target.value)}
                      renderValue={(selected) => (
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                          {selected.map((id) => {
                            const svc = getServicesForEditModel().find((s: any) => s.id === id);
                            return (
                              <Chip
                                key={id}
                                label={svc?.service_name || svc?.serviceName || id}
                                size="small"
                              />
                            );
                          })}
                        </Box>
                      )}
                    >
                      {getServicesForEditModel().map((service: any) => (
                        <MenuItem key={service.id} value={service.id}>
                          <Box sx={{ display: 'flex', flexDirection: 'column', width: '100%' }}>
                            <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
                              {service.service_name || service.serviceName || 'Service'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {service.service_description || service.serviceDescription || ''}
                            </Typography>
                            <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 0.5 }}>
                              <Typography variant="caption" color="primary">
                                {formatFromEUR(service.effective_price || service.effectivePrice || 0, currency)}
                              </Typography>
                            </Box>
                          </Box>
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  {editRepair.selectedServices.length > 0 && (
                    <Box sx={{ mt: 1, p: 1, bgcolor: 'grey.50', borderRadius: 1 }}>
                      <Typography variant="caption" color="text.secondary">
                        Services: {editRepair.selectedServices.length}
                      </Typography>
                      <Typography variant="caption" color="primary" sx={{ ml: 1, fontWeight: 'bold' }}>
                        Total: {formatFromEUR(
                          getServicesForEditModel()
                            .filter((s: any) => editRepair.selectedServices.includes(s.id))
                            .reduce((sum: number, s: any) => sum + (s.effective_price || s.effectivePrice || 0), 0),
                          currency
                        )}
                      </Typography>
                    </Box>
                  )}
                </Grid>
              )}
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 2: Description & Problème */}
        <Accordion
          expanded={expanded.includes('description')}
          onChange={handleAccordionChange('description')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <DescriptionIcon color="primary" fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Description & Problème</Typography>
              {editRepair.description && (
                <CheckCircleIcon sx={{ color: '#16a34a', fontSize: 18 }} />
              )}
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  label="Description du problème *"
                  multiline
                  rows={3}
                  value={editRepair.description}
                  onChange={(e) => onEditRepairChange('description', e.target.value)}
                  placeholder="Décrivez le problème rencontré..."
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  label="Diagnostic initial"
                  multiline
                  rows={2}
                  value={editRepair.issue}
                  onChange={(e) => onEditRepairChange('issue', e.target.value)}
                  placeholder="Diagnostic préliminaire (optionnel)..."
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={editRepair.isUrgent}
                      onChange={(e) => onEditRepairChange('isUrgent', e.target.checked)}
                      color="error"
                    />
                  }
                  label="Réparation urgente"
                />
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 3: Planification & Tarif */}
        <Accordion
          expanded={expanded.includes('planning')}
          onChange={handleAccordionChange('planning')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <ScheduleIcon color="primary" fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Planification & Tarif</Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label={`Prix estimé (${currencySymbol})`}
                  type="number"
                  value={editRepair.totalPrice}
                  onChange={(e) => onEditRepairChange('totalPrice', parseFloat(e.target.value) || 0)}
                />
                {editRepair.selectedServices.length > 0 && (
                  <Typography variant="caption" color="primary" sx={{ mt: 0.5, display: 'block' }}>
                    Mis à jour avec les services
                  </Typography>
                )}
              </Grid>
              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label="Réduction (%)"
                  type="number"
                  value={editRepair.discountPercentage}
                  onChange={(e) =>
                    onEditRepairChange('discountPercentage', Math.max(0, Math.min(100, parseFloat(e.target.value) || 0)))
                  }
                  inputProps={{ min: 0, max: 100, step: 0.1 }}
                />
              </Grid>
              {editRepair.discountPercentage > 0 && (
                <Grid item xs={12}>
                  <Typography variant="caption" color="success.main">
                    Prix final: {formatFromEUR(finalPrice, currency)}
                  </Typography>
                </Grid>
              )}

              <Grid item xs={12}>
                <Divider sx={{ my: 0.5 }} />
                <Typography variant="subtitle2" sx={{ color: '#2563eb', mt: 1, mb: 0.5, display: 'flex', alignItems: 'center', gap: 0.5 }}>
                  <PaymentIcon fontSize="small" /> Paiements
                </Typography>
              </Grid>

              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label={`Acompte payé (${currencySymbol})`}
                  type="number"
                  value={editRepair.deposit}
                  onChange={(e) => onEditRepairChange('deposit', parseFloat(e.target.value) || 0)}
                  inputProps={{ min: 0, step: 0.01 }}
                />
              </Grid>
              <Grid item xs={6}>
                <FormControl fullWidth size="small">
                  <InputLabel>Paiement acompte</InputLabel>
                  <Select
                    label="Paiement acompte"
                    value={editRepair.depositPaymentMethod || 'cash'}
                    onChange={(e) => onEditRepairChange('depositPaymentMethod', e.target.value)}
                    disabled={!editRepair.deposit || editRepair.deposit === 0}
                  >
                    <MenuItem value="cash">Espèces</MenuItem>
                    <MenuItem value="card">Carte bancaire</MenuItem>
                    <MenuItem value="check">Chèque</MenuItem>
                    <MenuItem value="transfer">Virement</MenuItem>
                    <MenuItem value="payment_link">Lien de paiement</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label={`Reste à payer (${currencySymbol})`}
                  type="number"
                  value={remainingBalance.toFixed(2)}
                  InputProps={{ readOnly: true }}
                  sx={{
                    '& .MuiInputBase-input': {
                      fontWeight: 'bold',
                      color: remainingBalance > 0 ? '#dc2626' : '#16a34a',
                    }
                  }}
                />
              </Grid>
              <Grid item xs={6}>
                <FormControl fullWidth size="small">
                  <InputLabel>Paiement final</InputLabel>
                  <Select
                    label="Paiement final"
                    value={editRepair.finalPaymentMethod || ''}
                    onChange={(e) => onEditRepairChange('finalPaymentMethod', e.target.value)}
                    disabled={!editRepair.isPaid}
                  >
                    <MenuItem value="">Non payé</MenuItem>
                    <MenuItem value="cash">Espèces</MenuItem>
                    <MenuItem value="card">Carte bancaire</MenuItem>
                    <MenuItem value="check">Chèque</MenuItem>
                    <MenuItem value="transfer">Virement</MenuItem>
                    <MenuItem value="payment_link">Lien de paiement</MenuItem>
                  </Select>
                </FormControl>
              </Grid>

              <Grid item xs={12}>
                <Divider sx={{ my: 0.5 }} />
              </Grid>

              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label="Date d'échéance"
                  type="date"
                  value={editRepair.dueDate}
                  onChange={(e) => onEditRepairChange('dueDate', e.target.value)}
                  InputLabelProps={{ shrink: true }}
                />
              </Grid>
              <Grid item xs={6}>
                <FormControl fullWidth size="small">
                  <InputLabel>Statut</InputLabel>
                  <Select
                    label="Statut"
                    value={editRepair.status || ''}
                    onChange={(e) => onEditRepairChange('status', e.target.value)}
                  >
                    {repairStatuses.map((s) => (
                      <MenuItem key={s.id} value={s.id}>{s.name}</MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12}>
                <FormControl fullWidth size="small">
                  <InputLabel>Technicien assigné</InputLabel>
                  <Select
                    label="Technicien assigné"
                    value={editRepair.assignedTechnicianId || ''}
                    onChange={(e) => onEditRepairChange('assignedTechnicianId', e.target.value)}
                  >
                    <MenuItem value="">Aucun</MenuItem>
                    {getRepairEligibleUsers(users).map((user) => (
                      <MenuItem key={user.id} value={user.id}>
                        {getRepairUserDisplayName(user)}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 4: État de l'appareil */}
        <Accordion
          expanded={expanded.includes('device-state')}
          onChange={handleAccordionChange('device-state')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <DeviceIcon color="primary" fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>État de l'appareil</Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="État général"
                  value={interventionData.deviceCondition}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, deviceCondition: e.target.value }))}
                  placeholder="Rayures, chocs, usure..."
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="Dommages visibles"
                  value={interventionData.visibleDamages}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, visibleDamages: e.target.value }))}
                  placeholder="Écran cassé, coque abîmée..."
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  label="Pièces manquantes"
                  value={interventionData.missingParts}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, missingParts: e.target.value }))}
                  placeholder="Chargeur, câbles..."
                />
              </Grid>
              {/* Security section */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" sx={{ mt: 1, mb: 1, color: '#1976d2' }}>
                  Sécurité & Accès
                </Typography>
              </Grid>
              <Grid item xs={6}>
                <FormControl fullWidth size="small">
                  <InputLabel>Authentification</InputLabel>
                  <Select
                    value={interventionData.authType || ''}
                    onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, authType: e.target.value }))}
                    label="Authentification"
                  >
                    <MenuItem value="password">Mot de passe</MenuItem>
                    <MenuItem value="pattern">Schéma</MenuItem>
                    <MenuItem value="pin">Code PIN</MenuItem>
                    <MenuItem value="fingerprint">Empreinte</MenuItem>
                    <MenuItem value="face">Face ID</MenuItem>
                    <MenuItem value="none">Aucun</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label="Code d'accès"
                  value={interventionData.accessCode || ''}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, accessCode: e.target.value }))}
                  type="password"
                />
              </Grid>
              {/* Pattern diagram */}
              {interventionData.authType === 'pattern' && (
                <Grid item xs={12}>
                  <Box sx={{
                    p: 2,
                    border: '2px dashed #1976d2',
                    borderRadius: 2,
                    backgroundColor: '#f8f9fa',
                    textAlign: 'center'
                  }}>
                    <Typography variant="body2" sx={{ mb: 1, color: '#1976d2', fontWeight: 600 }}>
                      Schéma de déverrouillage
                    </Typography>
                    <Box sx={{
                      width: 120,
                      height: 120,
                      mx: 'auto',
                      border: '2px solid #ccc',
                      borderRadius: 2,
                      backgroundColor: '#fff',
                      mb: 1
                    }}>
                      <Box sx={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(3, 1fr)',
                        gap: 1,
                        p: 1.5,
                        height: '100%'
                      }}>
                        {[1, 2, 3, 4, 5, 6, 7, 8, 9].map((point) => (
                          <Box
                            key={point}
                            sx={{
                              width: 15,
                              height: 15,
                              borderRadius: '50%',
                              backgroundColor: interventionData.patternPoints?.includes(point) ? '#1976d2' : '#e0e0e0',
                              border: '2px solid #ccc',
                              cursor: 'pointer',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '10px',
                              fontWeight: 'bold',
                              color: interventionData.patternPoints?.includes(point) ? 'white' : '#666',
                              '&:hover': {
                                backgroundColor: interventionData.patternPoints?.includes(point) ? '#1565c0' : '#f0f0f0',
                              }
                            }}
                            onClick={() => {
                              const currentPoints = interventionData.patternPoints || [];
                              const newPoints = currentPoints.includes(point)
                                ? currentPoints.filter((p: number) => p !== point)
                                : [...currentPoints, point];
                              onInterventionDataChange((prev: any) => ({
                                ...prev,
                                patternPoints: newPoints,
                                accessCode: `Schéma: ${newPoints.join('-')}`
                              }));
                            }}
                          >
                            {point}
                          </Box>
                        ))}
                      </Box>
                    </Box>
                    <Button
                      variant="outlined"
                      size="small"
                      onClick={() => onInterventionDataChange((prev: any) => ({
                        ...prev,
                        patternPoints: [],
                        accessCode: '',
                        patternDescription: ''
                      }))}
                    >
                      Effacer
                    </Button>
                  </Box>
                </Grid>
              )}
              <Grid item xs={12}>
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                  <FormControlLabel
                    control={
                      <Checkbox
                        size="small"
                        checked={interventionData.passwordProvided}
                        onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, passwordProvided: e.target.checked }))}
                      />
                    }
                    label={<Typography variant="body2">Mot de passe fourni</Typography>}
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        size="small"
                        checked={interventionData.dataBackup}
                        onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, dataBackup: e.target.checked }))}
                      />
                    }
                    label={<Typography variant="body2">Sauvegarde effectuée</Typography>}
                  />
                  <FormControlLabel
                    control={
                      <Checkbox
                        size="small"
                        checked={interventionData.accessConfirmed}
                        onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, accessConfirmed: e.target.checked }))}
                      />
                    }
                    label={<Typography variant="body2">Accès testé et confirmé</Typography>}
                  />
                </Box>
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 5: Diagnostic & Risques */}
        <Accordion
          expanded={expanded.includes('diagnostic')}
          onChange={handleAccordionChange('diagnostic')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <WarningIcon sx={{ color: '#ef4444' }} fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Diagnostic & Risques</Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  label="Nom du technicien"
                  value={interventionData.technicianName}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, technicianName: e.target.value }))}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="Diagnostic initial"
                  value={interventionData.initialDiagnosis}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, initialDiagnosis: e.target.value }))}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="Solution proposée"
                  value={interventionData.proposedSolution}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, proposedSolution: e.target.value }))}
                />
              </Grid>
              <Grid item xs={6}>
                <TextField
                  fullWidth
                  size="small"
                  label="Durée estimée"
                  value={interventionData.estimatedDuration}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, estimatedDuration: e.target.value }))}
                  placeholder="ex: 2-3 jours"
                />
              </Grid>
              <Grid item xs={12}>
                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2" sx={{ color: '#ef4444', mb: 1 }}>
                  Risques
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.dataLossRisk}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, dataLossRisk: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Risque de perte de données</Typography>}
                />
                {interventionData.dataLossRisk && (
                  <TextField
                    fullWidth
                    size="small"
                    multiline
                    rows={2}
                    label="Détails du risque"
                    value={interventionData.dataLossRiskDetails}
                    onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, dataLossRiskDetails: e.target.value }))}
                    sx={{ mt: 1 }}
                  />
                )}
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.cosmeticChanges}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, cosmeticChanges: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Modifications esthétiques possibles</Typography>}
                />
                {interventionData.cosmeticChanges && (
                  <TextField
                    fullWidth
                    size="small"
                    multiline
                    rows={2}
                    label="Détails"
                    value={interventionData.cosmeticChangesDetails}
                    onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, cosmeticChangesDetails: e.target.value }))}
                    sx={{ mt: 1 }}
                  />
                )}
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.warrantyVoid}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, warrantyVoid: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Garantie susceptible d'être annulée</Typography>}
                />
                {interventionData.warrantyVoid && (
                  <TextField
                    fullWidth
                    size="small"
                    multiline
                    rows={2}
                    label="Détails"
                    value={interventionData.warrantyVoidDetails}
                    onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, warrantyVoidDetails: e.target.value }))}
                    sx={{ mt: 1 }}
                  />
                )}
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 6: Autorisations & Conditions */}
        <Accordion
          expanded={expanded.includes('authorizations')}
          onChange={handleAccordionChange('authorizations')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CheckCircleIcon sx={{ color: '#2e7d32' }} fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Autorisations & Conditions</Typography>
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            <Grid container spacing={1}>
              <Grid item xs={12}>
                <Typography variant="subtitle2" sx={{ color: '#2e7d32', mb: 1 }}>
                  Autorisations client
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.clientAuthorizesRepair}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, clientAuthorizesRepair: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Autorise la réparation</Typography>}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.clientAuthorizesDataAccess}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, clientAuthorizesDataAccess: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Autorise l'accès aux données</Typography>}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.clientAuthorizesReplacement}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, clientAuthorizesReplacement: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Autorise le remplacement de pièces</Typography>}
                />
              </Grid>

              <Grid item xs={12}>
                <Divider sx={{ my: 1 }} />
                <Typography variant="subtitle2" sx={{ color: '#d32f2f', mb: 1 }}>
                  Conditions légales
                </Typography>
              </Grid>
              <Grid item xs={12}>
                <Alert severity="warning" sx={{ mb: 1 }}>
                  <Typography variant="caption">
                    Le client reconnaît avoir été informé des risques et accepte les conditions.
                  </Typography>
                </Alert>
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.termsAccepted}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, termsAccepted: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">J'accepte les conditions de réparation</Typography>}
                />
              </Grid>
              <Grid item xs={12}>
                <FormControlLabel
                  control={
                    <Checkbox
                      size="small"
                      checked={interventionData.liabilityAccepted}
                      onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, liabilityAccepted: e.target.checked }))}
                    />
                  }
                  label={<Typography variant="body2">Je comprends les clauses de responsabilité</Typography>}
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="Notes additionnelles"
                  value={interventionData.additionalNotes}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, additionalNotes: e.target.value }))}
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  size="small"
                  multiline
                  rows={2}
                  label="Instructions spéciales"
                  value={interventionData.specialInstructions}
                  onChange={(e) => onInterventionDataChange((prev: any) => ({ ...prev, specialInstructions: e.target.value }))}
                />
              </Grid>

              {/* Generate intervention PDF button */}
              <Grid item xs={12}>
                <Button
                  fullWidth
                  variant="outlined"
                  startIcon={<PrintIcon />}
                  onClick={onGenerateIntervention}
                  disabled={!interventionData.technicianName || !interventionData.termsAccepted || !interventionData.liabilityAccepted}
                  sx={{ mt: 1 }}
                >
                  Générer le Bon d'Intervention (PDF)
                </Button>
              </Grid>
            </Grid>
          </AccordionDetails>
        </Accordion>

        {/* Section 7: Signature Client */}
        <Accordion
          expanded={expanded.includes('signature')}
          onChange={handleAccordionChange('signature')}
          disableGutters
          sx={{ '&:before': { display: 'none' } }}
        >
          <AccordionSummary expandIcon={<ExpandMoreIcon />}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <DrawIcon color="primary" fontSize="small" />
              <Typography sx={{ fontWeight: 600 }}>Signature Client</Typography>
              {signatureStatus === 'signed' && (
                <Chip label="Signé" size="small" color="success" />
              )}
              {signatureStatus === 'sent' && (
                <Chip label="En attente" size="small" color="warning" />
              )}
            </Box>
          </AccordionSummary>
          <AccordionDetails>
            {!signatureToken ? (
              <Box sx={{ textAlign: 'center', py: 2 }}>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Générez un QR code pour que le client puisse signer depuis son téléphone.
                </Typography>
                <Button
                  variant="contained"
                  startIcon={generatingQR ? <CircularProgress size={18} /> : <QrCodeIcon />}
                  onClick={handleGenerateQR}
                  disabled={generatingQR || !editRepair.clientId || !editRepair.deviceId || !editRepair.description}
                >
                  {generatingQR ? 'Génération...' : 'Générer le QR code de signature'}
                </Button>
                {(!editRepair.clientId || !editRepair.deviceId || !editRepair.description) && (
                  <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                    Remplissez d'abord client, appareil et description
                  </Typography>
                )}
              </Box>
            ) : (
              <Box sx={{ textAlign: 'center' }}>
                {signatureStatus !== 'signed' ? (
                  <>
                    <Typography variant="body2" sx={{ mb: 2 }}>
                      Scannez ce QR code avec le téléphone du client :
                    </Typography>
                    <Box
                      sx={{
                        display: 'inline-block',
                        p: 2,
                        border: '2px solid #e5e7eb',
                        borderRadius: 2,
                        backgroundColor: '#fff',
                        mb: 2,
                      }}
                    >
                      <QRCodeSVG value={signatureUrl} size={180} />
                    </Box>
                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
                      {signatureUrl}
                    </Typography>
                    <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1 }}>
                      <CircularProgress size={16} />
                      <Typography variant="body2" color="text.secondary">
                        En attente de la signature du client...
                      </Typography>
                    </Box>
                  </>
                ) : (
                  <>
                    <Alert severity="success" sx={{ mb: 2 }}>
                      Le client a signé le bon d'intervention !
                    </Alert>
                    {signatureImage && (
                      <Box sx={{ mb: 2 }}>
                        <Typography variant="body2" sx={{ mb: 1 }}>Aperçu de la signature :</Typography>
                        <Box
                          sx={{
                            display: 'inline-block',
                            border: '1px solid #e0e0e0',
                            borderRadius: 1,
                            p: 1,
                            backgroundColor: '#fff',
                          }}
                        >
                          <img
                            src={signatureImage}
                            alt="Signature client"
                            style={{ maxWidth: 200, maxHeight: 80 }}
                          />
                        </Box>
                      </Box>
                    )}
                  </>
                )}
              </Box>
            )}
          </AccordionDetails>
        </Accordion>
      </Box>

      {/* Footer */}
      <Box
        sx={{
          position: 'sticky',
          bottom: 0,
          px: 3,
          py: 2,
          borderTop: '1px solid',
          borderColor: 'divider',
          backgroundColor: '#f8fafc',
          display: 'flex',
          gap: 2,
          justifyContent: 'flex-end',
          zIndex: 10,
        }}
      >
        <Button onClick={onClose} variant="outlined" color="inherit">
          Annuler
        </Button>
        <Button
          variant="contained"
          onClick={onSaveRepair}
          disabled={!editRepair.clientId || !editRepair.deviceId || !editRepair.description}
          sx={{
            backgroundColor: '#2563eb',
            '&:hover': { backgroundColor: '#1d4ed8' },
          }}
        >
          Sauvegarder
        </Button>
      </Box>
    </Drawer>
  );
};

export default EditRepairSidePanel;
