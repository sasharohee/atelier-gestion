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
    termsAccepted: false,
    liabilityAccepted: false,
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
    return (
      formData.technicianName &&
      formData.clientName &&
      formData.deviceBrand &&
      formData.deviceModel &&
      formData.reportedIssue &&
      formData.termsAccepted &&
      formData.liabilityAccepted
    );
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
const generateInterventionPDF = (data: InterventionData, repair: Repair) => {
  try {
    // Créer un nouveau document PDF
    const doc = new jsPDF();
    
    // Configuration de la page
    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();
    const margin = 15;
    const lineHeight = 5;
    let yPosition = margin;

    // Fonction pour ajouter du texte avec gestion de la pagination
    const addText = (text: string, x: number, y: number, options?: any) => {
      if (y > pageHeight - margin) {
        doc.addPage();
        yPosition = margin;
      }
      doc.text(text, x, y, options);
      return y + lineHeight;
    };

    // Fonction pour ajouter une section avec espacement amélioré
    const addSpacedSection = (title: string, content: string[], startY: number, color: number[] = [52, 152, 219]) => {
      let y = startY;
      
      // Titre de section avec accent coloré
      doc.setFontSize(12);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(color[0], color[1], color[2]);
      y = addText(title, margin, y);
      
      // Ligne de séparation colorée
      doc.setDrawColor(color[0], color[1], color[2]);
      doc.line(margin, y - 2, pageWidth - margin, y - 2);
      
      // Contenu en colonnes avec espacement
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(51, 51, 51);
      
      const itemsPerRow = 2;
      let maxY = y + 4;
      
      for (let i = 0; i < content.length; i += itemsPerRow) {
        const row = content.slice(i, i + itemsPerRow);
        
        row.forEach((item, index) => {
          const itemWidth = (pageWidth - 2 * margin - 20) / itemsPerRow;
          const x = margin + (index * (itemWidth + 20));
          const itemY = addText(item, x, maxY);
          maxY = Math.max(maxY, itemY);
        });
        
        if (i + itemsPerRow < content.length) {
          maxY += 4; // Espacement entre les lignes
        }
      }
      
      return maxY + 8;
    };

    // En-tête moderne avec couleur (compact)
    const headerHeight = 25;
    
    // Fond coloré pour l'en-tête
    doc.setFillColor(52, 152, 219);
    doc.rect(0, 0, pageWidth, headerHeight, 'F');
    
    // Accent coloré en bas
    doc.setFillColor(41, 128, 185);
    doc.rect(0, headerHeight - 2, pageWidth, 2, 'F');
    
    // Titre principal avec signature obligatoire
    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(255, 255, 255);
    yPosition = addText('BON D\'INTERVENTION - Signature obligatoire', pageWidth / 2, 12, { align: 'center' });
    
    // Informations secondaires
    doc.setFontSize(9);
    doc.setTextColor(240, 240, 240);
    yPosition = addText(`Réparation #${repair.id.slice(0, 8)} | ${format(new Date(data.interventionDate), 'dd/MM/yyyy')}`, pageWidth / 2, 20, { align: 'center' });
    
    // Message contractuel sous le titre
    yPosition += 6;
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(240, 240, 240);
    doc.text('Document contractuel - Signature obligatoire pour validation', pageWidth / 2, yPosition, { align: 'center' });
    
    // Reset colors
    doc.setTextColor(51, 51, 51);
    yPosition = headerHeight + 15;

    // Informations générales et appareil combinées
    const generalInfo = [
      `Technicien: ${data.technicianName}`,
      `Client: ${data.clientName}`,
      `Téléphone: ${data.clientPhone || 'Non renseigné'}`,
      `Email: ${data.clientEmail || 'Non renseigné'}`,
      `Marque: ${data.deviceBrand}`,
      `Modèle: ${data.deviceModel}`,
      `Numéro de série: ${data.deviceSerialNumber || 'Non renseigné'}`,
      `Type: ${data.deviceType || 'Non renseigné'}`
    ];
    yPosition = addSpacedSection('INFORMATIONS GÉNÉRALES & APPAREIL', generalInfo, yPosition, [52, 152, 219]);

    // État initial et diagnostic combinés
    const technicalInfo = [
      `État général: ${data.deviceCondition || 'Non renseigné'}`,
      `Dommages visibles: ${data.visibleDamages || 'Aucun'}`,
      `Pièces manquantes: ${data.missingParts || 'Aucune'}`,
      `Mot de passe fourni: ${data.passwordProvided ? 'Oui' : 'Non'}`,
      `Sauvegarde effectuée: ${data.dataBackup ? 'Oui' : 'Non'}`,
      `Problème signalé: ${data.reportedIssue}`,
      `Diagnostic initial: ${data.initialDiagnosis || 'Non renseigné'}`,
      `Solution proposée: ${data.proposedSolution || 'Non renseigné'}`,
      `Coût estimé: ${data.estimatedCost} €`,
      `Durée estimée: ${data.estimatedDuration || 'Non renseigné'}`
    ];
    yPosition = addSpacedSection('TECHNIQUE & DIAGNOSTIC', technicalInfo, yPosition, [46, 204, 113]);

    // Risques et autorisations combinés
    const risksAndAuth = [];
    if (data.dataLossRisk) {
      risksAndAuth.push(`Risque perte données: ${data.dataLossRiskDetails || 'Oui'}`);
    }
    if (data.cosmeticChanges) {
      risksAndAuth.push(`Modifications esthétiques: ${data.cosmeticChangesDetails || 'Oui'}`);
    }
    if (data.warrantyVoid) {
      risksAndAuth.push(`Garantie annulée: ${data.warrantyVoidDetails || 'Oui'}`);
    }
    if (risksAndAuth.length === 0) {
      risksAndAuth.push('Aucun risque particulier identifié');
    }
    risksAndAuth.push(`Autorise réparation: ${data.clientAuthorizesRepair ? 'Oui' : 'Non'}`);
    risksAndAuth.push(`Autorise accès données: ${data.clientAuthorizesDataAccess ? 'Oui' : 'Non'}`);
    risksAndAuth.push(`Autorise remplacement: ${data.clientAuthorizesReplacement ? 'Oui' : 'Non'}`);
    
    yPosition = addSpacedSection('RISQUES & AUTORISATIONS', risksAndAuth, yPosition, [230, 126, 34]);

    // Notes et conditions légales
    const notesAndLegal = [];
    if (data.additionalNotes) {
      notesAndLegal.push(`Notes: ${data.additionalNotes}`);
    }
    if (data.specialInstructions) {
      notesAndLegal.push(`Instructions: ${data.specialInstructions}`);
    }
    if (notesAndLegal.length === 0) {
      notesAndLegal.push('Aucune note additionnelle');
    }
    notesAndLegal.push(`Conditions acceptées: ${data.termsAccepted ? 'Oui' : 'Non'}`);
    notesAndLegal.push(`Responsabilité acceptée: ${data.liabilityAccepted ? 'Oui' : 'Non'}`);
    
    yPosition = addSpacedSection('NOTES & CONDITIONS', notesAndLegal, yPosition, [155, 89, 182]);

    // Section signatures avec espacement et alignement améliorés
    yPosition += 12;
    
    // Titre de section signatures avec couleur
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(52, 73, 94);
    yPosition = addText('SIGNATURES', pageWidth / 2, yPosition, { align: 'center' });
    
    yPosition += 8;
    
    // Ligne de séparation colorée
    doc.setDrawColor(52, 73, 94);
    doc.line(margin, yPosition, pageWidth - margin, yPosition);
    
    yPosition += 10;
    
    // Signatures côte à côte avec cases alignées
    const signatureWidth = (pageWidth - 2 * margin - 20) / 2;
    const signatureStartY = yPosition;
    const caseHeight = 25;
    const caseWidth = signatureWidth - 10;
    
    // Case signature technicien (gauche)
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(52, 152, 219);
    doc.text('👨‍🔧 TECHNICIEN', margin, signatureStartY);
    
    yPosition += 8;
    
    // Case pour la signature du technicien
    doc.setDrawColor(52, 152, 219);
    doc.setLineWidth(1.5);
    doc.rect(margin, yPosition, caseWidth, caseHeight, 'S');
    
    // Texte à l'intérieur de la case
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(128, 128, 128);
    doc.text('Signature du technicien', margin + 5, yPosition + 8);
    
    // Nom et date du technicien
    yPosition += caseHeight + 5;
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(51, 51, 51);
    doc.text('Nom:', margin, yPosition);
    doc.setDrawColor(180, 180, 180);
    doc.setLineWidth(0.5);
    doc.line(margin, yPosition + 2, margin + caseWidth - 5, yPosition + 2);
    
    yPosition += 8;
    doc.text('Date:', margin, yPosition);
    doc.line(margin, yPosition + 2, margin + caseWidth - 5, yPosition + 2);
    
    // Case signature client (droite) - alignée avec la gauche
    const clientStartY = signatureStartY;
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(46, 204, 113);
    doc.text('👤 CLIENT', margin + signatureWidth + 10, clientStartY);
    
    const clientY = clientStartY + 8;
    
    // Case pour la signature du client - alignée avec la gauche
    doc.setDrawColor(46, 204, 113);
    doc.setLineWidth(1.5);
    doc.rect(margin + signatureWidth + 10, clientY, caseWidth, caseHeight, 'S');
    
    // Texte à l'intérieur de la case
    doc.setFontSize(8);
    doc.setFont('helvetica', 'italic');
    doc.setTextColor(128, 128, 128);
    doc.text('Signature du client', margin + signatureWidth + 15, clientY + 8);
    
    // Nom et date du client - alignés avec la gauche
    const clientBottomY = clientY + caseHeight + 5;
    doc.setFontSize(9);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(51, 51, 51);
    doc.text('Nom:', margin + signatureWidth + 10, clientBottomY);
    doc.setDrawColor(180, 180, 180);
    doc.setLineWidth(0.5);
    doc.line(margin + signatureWidth + 10, clientBottomY + 2, pageWidth - margin - 5, clientBottomY + 2);
    
    const clientDateY = clientBottomY + 8;
    doc.text('Date:', margin + signatureWidth + 10, clientDateY);
    doc.line(margin + signatureWidth + 10, clientDateY + 2, pageWidth - margin - 5, clientDateY + 2);
    
    // Ajuster la position finale
    yPosition = Math.max(yPosition, clientDateY + 8);

    // Pied de page sobre
    const footerY = pageHeight - 15;
    doc.setDrawColor(220, 220, 220);
    doc.line(0, footerY, pageWidth, footerY);

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

export default InterventionForm;
