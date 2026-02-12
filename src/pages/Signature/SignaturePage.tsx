import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Alert,
  CircularProgress,
  Fade,
  FormControlLabel,
  Checkbox,
  Divider,
  Chip,
} from '@mui/material';
import {
  CheckCircle as CheckCircleIcon,
  Draw as DrawIcon,
  Warning as WarningIcon,
  ErrorOutline as ErrorIcon,
  Smartphone as SmartphoneIcon,
  MedicalServices as DiagnosticIcon,
  Security as SecurityIcon,
} from '@mui/icons-material';
import { useParams } from 'react-router-dom';
import SignatureCanvas, { SignatureCanvasRef } from '../../components/SignatureCanvas';
import { signatureService, InterventionSummary } from '../../services/signatureService';

type PageState = 'loading' | 'form' | 'submitting' | 'confirmed' | 'error';

const SignaturePage: React.FC = () => {
  const { token } = useParams<{ token: string }>();
  const signatureRef = useRef<SignatureCanvasRef>(null);

  const [pageState, setPageState] = useState<PageState>('loading');
  const [intervention, setIntervention] = useState<InterventionSummary | null>(null);
  const [errorMessage, setErrorMessage] = useState('');
  const [conditionsAccepted, setConditionsAccepted] = useState(false);
  const [signatureError, setSignatureError] = useState('');

  // Load intervention data
  useEffect(() => {
    if (!token) {
      setErrorMessage('Lien de signature invalide.');
      setPageState('error');
      return;
    }

    const loadIntervention = async () => {
      const result = await signatureService.getInterventionByToken(token);
      if (result.success && result.data) {
        if (result.data.signature_status === 'signed') {
          setPageState('confirmed');
          return;
        }
        setIntervention(result.data);
        setPageState('form');
      } else {
        setErrorMessage(result.error || 'Impossible de charger l\'intervention.');
        setPageState('error');
      }
    };

    loadIntervention();
  }, [token]);

  const handleSubmit = async () => {
    if (!signatureRef.current || signatureRef.current.isEmpty()) {
      setSignatureError('Veuillez signer avant de valider.');
      return;
    }
    if (!conditionsAccepted) {
      setSignatureError('Veuillez accepter les conditions.');
      return;
    }
    if (!token) return;

    setSignatureError('');
    setPageState('submitting');

    const signatureImage = signatureRef.current.toDataURL();
    const result = await signatureService.submitSignature(token, signatureImage);

    if (result.success) {
      setPageState('confirmed');
    } else {
      setSignatureError(result.error || 'Erreur lors de la soumission.');
      setPageState('form');
    }
  };

  // Loading state
  if (pageState === 'loading') {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#f8fafc',
        }}
      >
        <Box sx={{ textAlign: 'center' }}>
          <CircularProgress size={40} sx={{ mb: 2 }} />
          <Typography variant="body1" color="text.secondary">
            Chargement...
          </Typography>
        </Box>
      </Box>
    );
  }

  // Error state
  if (pageState === 'error') {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#f8fafc',
          p: 2,
        }}
      >
        <Card sx={{ maxWidth: 400, width: '100%' }}>
          <CardContent sx={{ textAlign: 'center', py: 4 }}>
            <ErrorIcon sx={{ fontSize: 56, color: '#ef4444', mb: 2 }} />
            <Typography variant="h6" sx={{ mb: 1 }}>
              Lien invalide ou expiré
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {errorMessage}
            </Typography>
          </CardContent>
        </Card>
      </Box>
    );
  }

  // Confirmed state
  if (pageState === 'confirmed') {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#f8fafc',
          p: 2,
        }}
      >
        <Fade in timeout={500}>
          <Card sx={{ maxWidth: 400, width: '100%' }}>
            <CardContent sx={{ textAlign: 'center', py: 4 }}>
              <CheckCircleIcon sx={{ fontSize: 64, color: '#16a34a', mb: 2 }} />
              <Typography variant="h5" sx={{ fontWeight: 600, mb: 1 }}>
                Signature enregistrée
              </Typography>
              <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
                Merci ! Votre signature a bien été prise en compte.
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Vous pouvez fermer cette page.
              </Typography>
            </CardContent>
          </Card>
        </Fade>
      </Box>
    );
  }

  // Form state (including submitting)
  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: '#f8fafc',
        p: 2,
        pb: 4,
      }}
    >
      <Box sx={{ maxWidth: 500, mx: 'auto' }}>
        {/* Header */}
        <Box sx={{ textAlign: 'center', mb: 3, pt: 2 }}>
          <SmartphoneIcon sx={{ fontSize: 36, color: '#3b82f6', mb: 1 }} />
          <Typography variant="h5" sx={{ fontWeight: 600, mb: 0.5 }}>
            Bon d'intervention
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Vérifiez les informations et signez ci-dessous
          </Typography>
        </Box>

        {/* Intervention summary */}
        {intervention && (
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="subtitle2" sx={{ mb: 2, color: '#3b82f6' }}>
                Résumé de l'intervention
              </Typography>

              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                <Box>
                  <Typography variant="caption" color="text.secondary">Client</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {intervention.client_name}
                  </Typography>
                </Box>

                <Box>
                  <Typography variant="caption" color="text.secondary">Appareil</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 500 }}>
                    {intervention.device_brand} {intervention.device_model}
                    {intervention.device_type && ` (${intervention.device_type})`}
                  </Typography>
                </Box>

                <Box>
                  <Typography variant="caption" color="text.secondary">Problème signalé</Typography>
                  <Typography variant="body2">
                    {intervention.reported_issue}
                  </Typography>
                </Box>

                {intervention.estimated_cost > 0 && (
                  <Box>
                    <Typography variant="caption" color="text.secondary">Coût estimé</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {intervention.estimated_cost.toFixed(2)} €
                    </Typography>
                  </Box>
                )}

                {intervention.estimated_duration && (
                  <Box>
                    <Typography variant="caption" color="text.secondary">Durée estimée</Typography>
                    <Typography variant="body2">{intervention.estimated_duration}</Typography>
                  </Box>
                )}
              </Box>

              {/* Diagnostic & Solution */}
              {(intervention.initial_diagnosis || intervention.proposed_solution) && (
                <>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="subtitle2" sx={{ mb: 1.5, color: '#3b82f6', display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <DiagnosticIcon fontSize="small" /> Diagnostic & Solution
                  </Typography>
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                    {intervention.initial_diagnosis && (
                      <Box>
                        <Typography variant="caption" color="text.secondary">Diagnostic initial</Typography>
                        <Typography variant="body2">{intervention.initial_diagnosis}</Typography>
                      </Box>
                    )}
                    {intervention.proposed_solution && (
                      <Box>
                        <Typography variant="caption" color="text.secondary">Solution proposée</Typography>
                        <Typography variant="body2">{intervention.proposed_solution}</Typography>
                      </Box>
                    )}
                    {intervention.device_condition && (
                      <Box>
                        <Typography variant="caption" color="text.secondary">État de l'appareil</Typography>
                        <Typography variant="body2">{intervention.device_condition}</Typography>
                      </Box>
                    )}
                  </Box>
                </>
              )}

              {/* Risks */}
              {(intervention.data_loss_risk || intervention.cosmetic_changes || intervention.warranty_void) && (
                <>
                  <Divider sx={{ my: 2 }} />
                  <Typography variant="subtitle2" sx={{ mb: 1, color: '#ef4444', display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    <WarningIcon fontSize="small" /> Risques identifiés
                  </Typography>
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                    {intervention.data_loss_risk && (
                      <Box>
                        <Chip label="Perte de données" size="small" color="error" variant="outlined" />
                        {intervention.data_loss_risk_details && (
                          <Typography variant="caption" sx={{ display: 'block', mt: 0.5, pl: 1 }}>
                            {intervention.data_loss_risk_details}
                          </Typography>
                        )}
                      </Box>
                    )}
                    {intervention.cosmetic_changes && (
                      <Box>
                        <Chip label="Modifications esthétiques" size="small" color="warning" variant="outlined" />
                        {intervention.cosmetic_changes_details && (
                          <Typography variant="caption" sx={{ display: 'block', mt: 0.5, pl: 1 }}>
                            {intervention.cosmetic_changes_details}
                          </Typography>
                        )}
                      </Box>
                    )}
                    {intervention.warranty_void && (
                      <Box>
                        <Chip label="Annulation garantie" size="small" color="error" variant="outlined" />
                        {intervention.warranty_void_details && (
                          <Typography variant="caption" sx={{ display: 'block', mt: 0.5, pl: 1 }}>
                            {intervention.warranty_void_details}
                          </Typography>
                        )}
                      </Box>
                    )}
                  </Box>
                </>
              )}

              {/* Autorisations */}
              <Divider sx={{ my: 2 }} />
              <Typography variant="subtitle2" sx={{ mb: 1.5, color: '#7c3aed', display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <SecurityIcon fontSize="small" /> Autorisations demandées
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 0.5 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip
                    label={intervention.client_authorizes_repair ? 'Oui' : 'Non'}
                    size="small"
                    color={intervention.client_authorizes_repair ? 'success' : 'default'}
                    variant="outlined"
                    sx={{ minWidth: 48 }}
                  />
                  <Typography variant="body2">Autorisation de réparation</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip
                    label={intervention.client_authorizes_data_access ? 'Oui' : 'Non'}
                    size="small"
                    color={intervention.client_authorizes_data_access ? 'success' : 'default'}
                    variant="outlined"
                    sx={{ minWidth: 48 }}
                  />
                  <Typography variant="body2">Accès aux données</Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Chip
                    label={intervention.client_authorizes_replacement ? 'Oui' : 'Non'}
                    size="small"
                    color={intervention.client_authorizes_replacement ? 'success' : 'default'}
                    variant="outlined"
                    sx={{ minWidth: 48 }}
                  />
                  <Typography variant="body2">Remplacement de pièces</Typography>
                </Box>
              </Box>

              {/* Notes */}
              {intervention.additional_notes && (
                <>
                  <Divider sx={{ my: 2 }} />
                  <Box>
                    <Typography variant="caption" color="text.secondary">Notes supplémentaires</Typography>
                    <Typography variant="body2">{intervention.additional_notes}</Typography>
                  </Box>
                </>
              )}
            </CardContent>
          </Card>
        )}

        {/* Conditions */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              En signant ce bon d'intervention, vous confirmez avoir été informé(e) des risques
              potentiels et acceptez les conditions de réparation. Vous reconnaissez l'état initial
              de l'appareil tel que décrit ci-dessus.
            </Typography>
            <FormControlLabel
              control={
                <Checkbox
                  checked={conditionsAccepted}
                  onChange={(e) => setConditionsAccepted(e.target.checked)}
                />
              }
              label={
                <Typography variant="body2" sx={{ fontWeight: 500 }}>
                  J'ai lu et compris les conditions
                </Typography>
              }
            />
          </CardContent>
        </Card>

        {/* Signature */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Typography variant="subtitle2" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <DrawIcon fontSize="small" color="primary" />
              Votre signature
            </Typography>
            <SignatureCanvas ref={signatureRef} height={180} />
          </CardContent>
        </Card>

        {/* Error */}
        {signatureError && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {signatureError}
          </Alert>
        )}

        {/* Submit */}
        <Button
          fullWidth
          variant="contained"
          size="large"
          onClick={handleSubmit}
          disabled={pageState === 'submitting' || !conditionsAccepted}
          startIcon={pageState === 'submitting' ? <CircularProgress size={20} /> : <DrawIcon />}
          sx={{
            backgroundColor: '#16a34a',
            '&:hover': { backgroundColor: '#15803d' },
            py: 1.5,
            fontSize: '1rem',
          }}
        >
          {pageState === 'submitting' ? 'Envoi en cours...' : 'Signer et valider'}
        </Button>
      </Box>
    </Box>
  );
};

export default SignaturePage;
