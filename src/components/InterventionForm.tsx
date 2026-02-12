import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Checkbox,
  Grid,
  Typography,
  Box,
  Divider,
  Chip,
  Alert,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Close as CloseIcon,
  Print as PrintIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Repair, Client, Device } from '../types';
import { useAppStore } from '../store';
import { interventionService } from '../services/interventionService';
import jsPDF from 'jspdf';

interface InterventionFormProps {
  repair: Repair;
  open: boolean;
  onClose: () => void;
}

interface InterventionData {
  // Informations générales
  interventionDate: string;
  technicianName: string;
  clientName: string;
  clientPhone: string;
  clientEmail: string;
  
  // Informations appareil
  deviceBrand: string;
  deviceModel: string;
  deviceSerialNumber: string;
  deviceType: string;
  
  // État initial de l'appareil
  deviceCondition: string;
  visibleDamages: string;
  missingParts: string;
  passwordProvided: boolean;
  dataBackup: boolean;
  
  // Diagnostic et réparation
  reportedIssue: string;
  initialDiagnosis: string;
  proposedSolution: string;
  estimatedCost: number;
  estimatedDuration: string;
  
  // Conditions et responsabilités
  dataLossRisk: boolean;
  dataLossRiskDetails: string;
  cosmeticChanges: boolean;
  cosmeticChangesDetails: string;
  warrantyVoid: boolean;
  warrantyVoidDetails: string;
  
  // Autorisations
  clientAuthorizesRepair: boolean;
  clientAuthorizesDataAccess: boolean;
  clientAuthorizesReplacement: boolean;
  
  // Notes et observations
  additionalNotes: string;
  specialInstructions: string;
  
  // Informations légales
  termsAccepted: boolean;
  liabilityAccepted: boolean;
  
  // Nouveaux champs pour le système de schéma et mots de passe
  authType?: string;
  accessCode?: string;
  patternPoints?: number[];
  patternDescription?: string;
  securityInfo?: string;
  accessConfirmed?: boolean;
  backupBeforeAccess?: boolean;
}

const InterventionForm: React.FC<InterventionFormProps> = ({ repair, open, onClose }) => {
  const { systemSettings, loadSystemSettings } = useAppStore();
  const [formData, setFormData] = useState<InterventionData>({
    interventionDate: format(new Date(), 'yyyy-MM-dd'),
    technicianName: '',
    clientName: '',
    clientPhone: '',
    clientEmail: '',
    deviceBrand: '',
    deviceModel: '',
    deviceSerialNumber: '',
    deviceType: '',
    deviceCondition: '',
    visibleDamages: '',
    missingParts: '',
    passwordProvided: false,
    dataBackup: false,
    reportedIssue: '',
    initialDiagnosis: '',
    proposedSolution: '',
    estimatedCost: 0,
    estimatedDuration: '',
    dataLossRisk: false,
    dataLossRiskDetails: '',
    cosmeticChanges: false,
    cosmeticChangesDetails: '',
    warrantyVoid: false,
    warrantyVoidDetails: '',
    clientAuthorizesRepair: false,
    clientAuthorizesDataAccess: false,
    clientAuthorizesReplacement: false,
    additionalNotes: '',
    specialInstructions: '',
    termsAccepted: true, // Coché par défaut
    liabilityAccepted: true, // Coché par défaut
  });

  // Charger les paramètres système
  useEffect(() => {
    if (systemSettings.length === 0) {
      loadSystemSettings();
    }
  }, [systemSettings.length, loadSystemSettings]);

  // Charger les données de la réparation
  useEffect(() => {
    if (repair) {
      // Récupérer les informations du client et de l'appareil
      // Ces données devraient être passées en props ou récupérées via un service
      setFormData(prev => ({
        ...prev,
        reportedIssue: repair.issue || '',
        estimatedCost: repair.totalPrice || 0,
        estimatedDuration: repair.estimatedDuration ? `${repair.estimatedDuration} minutes` : '',
      }));
    }
  }, [repair]);

  const handleInputChange = (field: keyof InterventionData, value: any) => {
    console.log('🔄 Changement de champ:', field, 'valeur:', value);
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleGeneratePDF = () => {
    // Générer le PDF avec toutes les informations
    generateInterventionPDF(formData, repair);
  };



  const isFormValid = () => {
    const isValid = (
      formData.technicianName &&
      formData.clientName &&
      formData.deviceBrand &&
      formData.deviceModel &&
      formData.reportedIssue &&
      formData.termsAccepted &&
      formData.liabilityAccepted
    );
    
    console.log('🔍 Validation du formulaire:', {
      technicianName: !!formData.technicianName,
      clientName: !!formData.clientName,
      deviceBrand: !!formData.deviceBrand,
      deviceModel: !!formData.deviceModel,
      reportedIssue: !!formData.reportedIssue,
      termsAccepted: formData.termsAccepted,
      liabilityAccepted: formData.liabilityAccepted,
      isValid
    });
    
    return isValid;
  };

  return (
    <Dialog 
      open={open} 
      onClose={onClose} 
      maxWidth="lg" 
      fullWidth
      PaperProps={{
        sx: { maxHeight: '90vh' }
      }}
    >
      <DialogTitle sx={{ 
        display: 'flex', 
        justifyContent: 'space-between', 
        alignItems: 'center',
        backgroundColor: '#f5f5f5',
        borderBottom: '1px solid #e0e0e0'
      }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            📋 Bon d'Intervention
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Réparation #{repair.id.slice(0, 8)}
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent sx={{ pt: 2 }}>
        <Box sx={{ mb: 3 }}>
          <Alert severity="info" sx={{ mb: 2 }}>
            <Typography variant="body2">
              <strong>Important :</strong> Ce bon d'intervention permet de documenter l'état initial de l'appareil 
              et de dédouaner le réparateur de toute responsabilité en cas de problème non signalé.
            </Typography>
          </Alert>
        </Box>

        <Grid container spacing={3}>
          {/* INFORMATIONS GÉNÉRALES */}
          <Grid item xs={12}>
            <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
              📅 Informations Générales
            </Typography>
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="Date d'intervention"
              type="date"
              value={formData.interventionDate}
              onChange={(e) => handleInputChange('interventionDate', e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="Nom du technicien"
              value={formData.technicianName}
              onChange={(e) => handleInputChange('technicianName', e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <TextField
              fullWidth
              label="Nom du client"
              value={formData.clientName}
              onChange={(e) => handleInputChange('clientName', e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Téléphone du client"
              value={formData.clientPhone}
              onChange={(e) => handleInputChange('clientPhone', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Email du client"
              type="email"
              value={formData.clientEmail}
              onChange={(e) => handleInputChange('clientEmail', e.target.value)}
            />
          </Grid>

          {/* INFORMATIONS APPAREIL */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
              📱 Informations Appareil
            </Typography>
          </Grid>

          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              label="Marque"
              value={formData.deviceBrand}
              onChange={(e) => handleInputChange('deviceBrand', e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              label="Modèle"
              value={formData.deviceModel}
              onChange={(e) => handleInputChange('deviceModel', e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={3}>
            <TextField
              fullWidth
              label="Numéro de série"
              value={formData.deviceSerialNumber}
              onChange={(e) => handleInputChange('deviceSerialNumber', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={3}>
            <FormControl fullWidth>
              <InputLabel>Type d'appareil</InputLabel>
              <Select
                value={formData.deviceType}
                onChange={(e) => handleInputChange('deviceType', e.target.value)}
                label="Type d'appareil"
              >
                <MenuItem value="smartphone">Smartphone</MenuItem>
                <MenuItem value="tablet">Tablette</MenuItem>
                <MenuItem value="laptop">Ordinateur portable</MenuItem>
                <MenuItem value="desktop">Ordinateur fixe</MenuItem>
                <MenuItem value="other">Autre</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          {/* ÉTAT INITIAL */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
              🔍 État Initial de l'Appareil
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="État général de l'appareil"
              value={formData.deviceCondition}
              onChange={(e) => handleInputChange('deviceCondition', e.target.value)}
              placeholder="Décrivez l'état général : rayures, chocs, usure..."
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Dommages visibles"
              value={formData.visibleDamages}
              onChange={(e) => handleInputChange('visibleDamages', e.target.value)}
              placeholder="Écran cassé, coque abîmée, boutons défectueux..."
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={2}
              label="Pièces manquantes"
              value={formData.missingParts}
              onChange={(e) => handleInputChange('missingParts', e.target.value)}
              placeholder="Chargeur, câbles, accessoires..."
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.passwordProvided}
                    onChange={(e) => handleInputChange('passwordProvided', e.target.checked)}
                  />
                }
                label="Mot de passe fourni par le client"
              />
              <FormControlLabel
                control={
                  <Checkbox
                    checked={formData.dataBackup}
                    onChange={(e) => handleInputChange('dataBackup', e.target.checked)}
                  />
                }
                label="Sauvegarde des données effectuée"
              />
            </Box>
          </Grid>

          {/* DIAGNOSTIC ET RÉPARATION */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
              🔧 Diagnostic et Réparation
            </Typography>
          </Grid>

          <Grid item xs={12}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Problème signalé par le client"
              value={formData.reportedIssue}
              onChange={(e) => handleInputChange('reportedIssue', e.target.value)}
              required
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Diagnostic initial"
              value={formData.initialDiagnosis}
              onChange={(e) => handleInputChange('initialDiagnosis', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Solution proposée"
              value={formData.proposedSolution}
              onChange={(e) => handleInputChange('proposedSolution', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Coût estimé (€)"
              type="number"
              value={formData.estimatedCost}
              onChange={(e) => handleInputChange('estimatedCost', parseFloat(e.target.value) || 0)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              label="Durée estimée"
              value={formData.estimatedDuration}
              onChange={(e) => handleInputChange('estimatedDuration', e.target.value)}
              placeholder="ex: 2-3 jours"
            />
          </Grid>

          {/* RISQUES ET RESPONSABILITÉS */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#d32f2f', borderBottom: '2px solid #d32f2f', pb: 1 }}>
              ⚠️ Risques et Responsabilités
            </Typography>
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.dataLossRisk}
                  onChange={(e) => handleInputChange('dataLossRisk', e.target.checked)}
                />
              }
              label="Risque de perte de données"
            />
            {formData.dataLossRisk && (
              <TextField
                fullWidth
                multiline
                rows={2}
                label="Détails du risque"
                value={formData.dataLossRiskDetails}
                onChange={(e) => handleInputChange('dataLossRiskDetails', e.target.value)}
                sx={{ mt: 1 }}
              />
            )}
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.cosmeticChanges}
                  onChange={(e) => handleInputChange('cosmeticChanges', e.target.checked)}
                />
              }
              label="Modifications esthétiques possibles"
            />
            {formData.cosmeticChanges && (
              <TextField
                fullWidth
                multiline
                rows={2}
                label="Détails des modifications"
                value={formData.cosmeticChangesDetails}
                onChange={(e) => handleInputChange('cosmeticChangesDetails', e.target.value)}
                sx={{ mt: 1 }}
              />
            )}
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.warrantyVoid}
                  onChange={(e) => handleInputChange('warrantyVoid', e.target.checked)}
                />
              }
              label="Garantie susceptible d'être annulée"
            />
            {formData.warrantyVoid && (
              <TextField
                fullWidth
                multiline
                rows={2}
                label="Détails de la garantie"
                value={formData.warrantyVoidDetails}
                onChange={(e) => handleInputChange('warrantyVoidDetails', e.target.value)}
                sx={{ mt: 1 }}
              />
            )}
          </Grid>

          {/* AUTORISATIONS */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#2e7d32', borderBottom: '2px solid #2e7d32', pb: 1 }}>
              ✅ Autorisations Client
            </Typography>
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.clientAuthorizesRepair}
                  onChange={(e) => handleInputChange('clientAuthorizesRepair', e.target.checked)}
                />
              }
              label="Autorise la réparation"
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.clientAuthorizesDataAccess}
                  onChange={(e) => handleInputChange('clientAuthorizesDataAccess', e.target.checked)}
                />
              }
              label="Autorise l'accès aux données"
            />
          </Grid>

          <Grid item xs={12} md={4}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.clientAuthorizesReplacement}
                  onChange={(e) => handleInputChange('clientAuthorizesReplacement', e.target.checked)}
                />
              }
              label="Autorise le remplacement de pièces"
            />
          </Grid>

          {/* NOTES ET OBSERVATIONS */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#1976d2', borderBottom: '2px solid #1976d2', pb: 1 }}>
              📝 Notes et Observations
            </Typography>
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Notes additionnelles"
              value={formData.additionalNotes}
              onChange={(e) => handleInputChange('additionalNotes', e.target.value)}
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Instructions spéciales"
              value={formData.specialInstructions}
              onChange={(e) => handleInputChange('specialInstructions', e.target.value)}
            />
          </Grid>

          {/* CONDITIONS LÉGALES */}
          <Grid item xs={12}>
            <Divider sx={{ my: 2 }} />
            <Typography variant="h6" sx={{ mb: 2, color: '#d32f2f', borderBottom: '2px solid #d32f2f', pb: 1 }}>
              ⚖️ Conditions Légales
            </Typography>
          </Grid>

          <Grid item xs={12}>
            <Alert severity="warning" sx={{ mb: 2 }}>
              <Typography variant="body2">
                <strong>Attention :</strong> En signant ce bon d'intervention, le client reconnaît avoir été informé 
                des risques potentiels et accepte les conditions de réparation.
              </Typography>
            </Alert>
          </Grid>

          <Grid item xs={12} md={6}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.termsAccepted}
                  onChange={(e) => handleInputChange('termsAccepted', e.target.checked)}
                  required
                />
              }
              label="J'accepte les conditions générales de réparation"
            />
          </Grid>

          <Grid item xs={12} md={6}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.liabilityAccepted}
                  onChange={(e) => handleInputChange('liabilityAccepted', e.target.checked)}
                  required
                />
              }
              label="Je comprends et accepte les clauses de responsabilité"
            />
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ 
        p: 3, 
        backgroundColor: '#f5f5f5',
        borderTop: '1px solid #e0e0e0'
      }}>
        <Button onClick={onClose} color="inherit">
          Annuler
        </Button>
        <Button
          onClick={handleGeneratePDF}
          variant="contained"
          startIcon={<PrintIcon />}
          disabled={!isFormValid()}
          sx={{ backgroundColor: '#1976d2' }}
        >
          Générer PDF
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// Fonction pour générer le PDF
const generateInterventionPDF = (data: InterventionData, repair: Repair, workshopSettings?: any, signatureImage?: string) => {
  try {
    // Créer un nouveau document PDF
    const doc = new jsPDF();
    
    // Configuration de la page
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const margin = 15;
    let yPosition = margin;

    // Fonction pour ajouter du texte
    const addText = (text: string, x: number, y: number, options?: any) => {
      doc.text(text, x, y, options);
      return y + 5;
    };

    // Fonction pour dessiner une case
    const drawBox = (x: number, y: number, width: number, height: number, label: string) => {
      doc.setDrawColor(0, 0, 0);
      doc.setLineWidth(0.5);
      doc.rect(x, y, width, height, 'S');
      
      // Label au-dessus de la case
      doc.setFontSize(8);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text(label, x, y - 2);
    };

    // ===== EN-TÊTE =====
    // Titre principal
    doc.setFontSize(18);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(0, 0, 0);
    yPosition = addText('BON D\'INTERVENTION', pageWidth / 2, yPosition, { align: 'center' });
    
    // Informations de l'atelier (si disponibles)
    if (workshopSettings) {
      yPosition += 5;
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      yPosition = addText(`${workshopSettings.workshop_name}`, pageWidth / 2, yPosition, { align: 'center' });
      
      doc.setFontSize(9);
      doc.setFont('helvetica', 'normal');
      yPosition = addText(`${workshopSettings.workshop_address}`, pageWidth / 2, yPosition, { align: 'center' });
      yPosition = addText(`Tél: ${workshopSettings.workshop_phone} | Email: ${workshopSettings.workshop_email}`, pageWidth / 2, yPosition, { align: 'center' });
      
      if (workshopSettings.workshop_siret) {
        yPosition = addText(`SIRET: ${workshopSettings.workshop_siret}`, pageWidth / 2, yPosition, { align: 'center' });
      }
      if (workshopSettings.workshop_vat) {
        yPosition = addText(`N° TVA: ${workshopSettings.workshop_vat}`, pageWidth / 2, yPosition, { align: 'center' });
      }
    }
    
    // Ligne de séparation
    yPosition += 5;
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(1);
    doc.line(margin, yPosition, pageWidth - margin, yPosition);
    yPosition += 10;

    // ===== INFORMATIONS CLIENT =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('INFORMATIONS CLIENT', margin, yPosition);
    
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    yPosition = addText(`Nom: ${data.clientName}`, margin, yPosition);
    yPosition = addText(`Téléphone: ${data.clientPhone || 'Non renseigné'}`, margin, yPosition);
    yPosition = addText(`Email: ${data.clientEmail || 'Non renseigné'}`, margin, yPosition);
    yPosition += 5;

    // ===== INFORMATIONS APPAREIL =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('INFORMATIONS APPAREIL', margin, yPosition);
    
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    yPosition = addText(`Marque: ${data.deviceBrand}`, margin, yPosition);
    yPosition = addText(`Modèle: ${data.deviceModel}`, margin, yPosition);
    yPosition = addText(`Type: ${data.deviceType || 'Non renseigné'}`, margin, yPosition);
    yPosition += 5;

    // ===== DIAGNOSTIC =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('DIAGNOSTIC', margin, yPosition);
    
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    yPosition = addText(`Problème signalé: ${data.reportedIssue}`, margin, yPosition);
    if (data.initialDiagnosis) {
      yPosition = addText(`Diagnostic: ${data.initialDiagnosis}`, margin, yPosition);
    }
    if (data.proposedSolution) {
      yPosition = addText(`Solution proposée: ${data.proposedSolution}`, margin, yPosition);
    }
    yPosition = addText(`Coût estimé: ${data.estimatedCost} €`, margin, yPosition);
    yPosition += 5;

    // ===== ÉTAT INITIAL =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('ÉTAT INITIAL DE L\'APPAREIL', margin, yPosition);
    
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    if (data.deviceCondition) {
      yPosition = addText(`État général: ${data.deviceCondition}`, margin, yPosition);
    }
    if (data.visibleDamages) {
      yPosition = addText(`Dommages visibles: ${data.visibleDamages}`, margin, yPosition);
    }
    if (data.missingParts) {
      yPosition = addText(`Pièces manquantes: ${data.missingParts}`, margin, yPosition);
    }
    yPosition = addText(`Sauvegarde effectuée: ${data.dataBackup ? 'Oui' : 'Non'}`, margin, yPosition);
    
    // Informations de sécurité et accès
    if (data.authType || data.accessCode || data.patternDescription) {
      yPosition += 3;
      doc.setFontSize(9);
      doc.setFont('helvetica', 'bold');
      yPosition = addText('Sécurité et accès:', margin, yPosition);
      
      doc.setFontSize(9);
      doc.setFont('helvetica', 'normal');
      if (data.authType) {
        yPosition = addText(`Type d'authentification: ${data.authType}`, margin, yPosition);
      }
      if (data.accessCode) {
        yPosition = addText(`Code d'accès: ${data.accessCode}`, margin, yPosition);
      }
      if (data.patternDescription) {
        yPosition = addText(`Description du schéma: ${data.patternDescription}`, margin, yPosition);
      }
      if (data.securityInfo) {
        yPosition = addText(`Informations de sécurité: ${data.securityInfo}`, margin, yPosition);
      }
      yPosition = addText(`Accès confirmé: ${data.accessConfirmed ? 'Oui' : 'Non'}`, margin, yPosition);
      yPosition = addText(`Sauvegarde avant accès: ${data.backupBeforeAccess ? 'Oui' : 'Non'}`, margin, yPosition);
    }
    yPosition += 5;

    // ===== CONDITIONS LÉGALES =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('CONDITIONS LÉGALES', margin, yPosition);
    
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    yPosition = addText('• Le client confirme avoir été informé des risques de perte de données', margin, yPosition);
    yPosition = addText('• Le client autorise l\'intervention sur son appareil', margin, yPosition);
    yPosition = addText('• Le client accepte les conditions générales de réparation', margin, yPosition);
    yPosition = addText('• Le client confirme avoir effectué une sauvegarde de ses données', margin, yPosition);
    yPosition += 5;

    // ===== SIGNATURES =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('SIGNATURES', pageWidth / 2, yPosition, { align: 'center' });
    yPosition += 8;
    
    // Ligne de séparation
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(0.5);
    doc.line(margin, yPosition, pageWidth - margin, yPosition);
    yPosition += 8;
    
    // Cases de signature côte à côte
    const signatureWidth = (pageWidth - 2 * margin - 20) / 2;
    const caseHeight = 25;
    
    // Case signature technicien (gauche)
    drawBox(margin, yPosition, signatureWidth, caseHeight, 'SIGNATURE TECHNICIEN');
    
    // Case signature client (droite)
    drawBox(margin + signatureWidth + 20, yPosition, signatureWidth, caseHeight, 'SIGNATURE CLIENT');

    // Intégrer la signature numérique si disponible
    if (signatureImage) {
      try {
        const sigX = margin + signatureWidth + 22;
        const sigY = yPosition + 2;
        const sigMaxW = signatureWidth - 4;
        const sigMaxH = caseHeight - 4;
        doc.addImage(signatureImage, 'PNG', sigX, sigY, sigMaxW, sigMaxH);
      } catch (e) {
        console.warn('Impossible d\'intégrer la signature dans le PDF:', e);
      }
    }

    yPosition += caseHeight + 8;
    
    // Informations sous les signatures
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(0, 0, 0);
    
    // Technicien
    doc.text('Nom du technicien:', margin, yPosition);
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(0.3);
    doc.line(margin, yPosition + 2, margin + signatureWidth - 5, yPosition + 2);
    
    doc.text('Date:', margin, yPosition + 8);
    doc.line(margin, yPosition + 10, margin + signatureWidth - 5, yPosition + 10);
    
    // Client
    doc.text('Nom du client:', margin + signatureWidth + 20, yPosition);
    doc.line(margin + signatureWidth + 20, yPosition + 2, pageWidth - margin - 5, yPosition + 2);
    
    doc.text('Date:', margin + signatureWidth + 20, yPosition + 8);
    doc.line(margin + signatureWidth + 20, yPosition + 10, pageWidth - margin - 5, yPosition + 10);

    yPosition += 15;

    // Mention de signature numérique
    if (signatureImage) {
      doc.setFontSize(7);
      doc.setFont('helvetica', 'italic');
      doc.setTextColor(100, 100, 100);
      doc.text(
        `Signé numériquement le ${format(new Date(), 'dd/MM/yyyy à HH:mm', { locale: fr })}`,
        margin + signatureWidth + 20,
        yPosition
      );
      doc.setTextColor(0, 0, 0);
      yPosition += 8;
    }

    // ===== INFORMATIONS COMPLÉMENTAIRES =====
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    yPosition = addText('INFORMATIONS COMPLÉMENTAIRES', margin, yPosition);
    
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    yPosition = addText(`Date d'intervention: ${format(new Date(data.interventionDate), 'dd/MM/yyyy', { locale: fr })}`, margin, yPosition);
    yPosition = addText(`Technicien: ${data.technicianName}`, margin, yPosition);
    yPosition = addText(`Numéro de réparation: ${repair.id.slice(0, 8)}`, margin, yPosition);
    
    if (data.additionalNotes) {
      yPosition = addText(`Notes: ${data.additionalNotes}`, margin, yPosition);
    }
    yPosition += 5;

    // Pied de page professionnel
    const footerY = pageHeight - 12;
    doc.setDrawColor(0, 0, 0);
    doc.setLineWidth(0.5);
    doc.line(margin, footerY, pageWidth - margin, footerY);
    
    // Texte du pied de page
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(0, 0, 0);
    doc.text('Document contractuel - Signature obligatoire pour validation de l\'intervention', pageWidth / 2, footerY + 5, { align: 'center' });
    doc.text(`Généré le ${format(new Date(), 'dd/MM/yyyy à HH:mm')}`, pageWidth / 2, footerY + 10, { align: 'center' });

    // Générer le nom du fichier
    const fileName = `Bon_Intervention_${repair.id.slice(0, 8)}_${format(new Date(), 'ddMMyyyy_HHmm')}.pdf`;
    
    // Télécharger le PDF
    doc.save(fileName);
    
    console.log('✅ PDF généré et téléchargé avec succès:', fileName);
    
  } catch (error) {
    console.error('❌ Erreur lors de la génération du PDF:', error);
    alert('Erreur lors de la génération du PDF. Veuillez réessayer.');
  }
};

export { generateInterventionPDF };
export default InterventionForm;
