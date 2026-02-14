import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  TextField,
  Button,
  Tabs,
  Tab,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Switch,
  FormControlLabel,
  Snackbar,
  Alert,
  InputAdornment,
  LinearProgress,
  IconButton,
  alpha,
  Divider,
} from '@mui/material';
import {
  Person as PersonIcon,
  Lock as LockIcon,
  Business as BusinessIcon,
  Description as InvoiceIcon,
  Save as SaveIcon,
  Email as EmailIcon,
  Phone as PhoneIcon,
  Badge as BadgeIcon,
  Visibility as VisIcon,
  VisibilityOff as VisOffIcon,
  Store as StoreIcon,
  LocationOn as LocationIcon,
  Numbers as SiretIcon,
  Percent as PercentIcon,
  Euro as EuroIcon,
  Article as ArticleIcon,
  Gavel as GavelIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { supabase } from '../../lib/supabase';

/* ─── design tokens ─── */
const CARD_STATIC = {
  borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
} as const;
const BTN_DARK = {
  borderRadius: '10px', textTransform: 'none', fontWeight: 600,
  bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
  boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
} as const;
const INPUT_SX = { '& .MuiOutlinedInput-root': { borderRadius: '10px' } } as const;

/* ─── section label ─── */
function SectionLabel({ icon, color, label, sub }: { icon: React.ReactNode; color: string; label: string; sub?: string }) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
      <Box sx={{ width: 40, height: 40, borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: `linear-gradient(135deg, ${color}, ${alpha(color, 0.7)})`, color: '#fff',
        boxShadow: `0 4px 14px ${alpha(color, 0.3)}`, flexShrink: 0 }}>
        {icon}
      </Box>
      <Box>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, lineHeight: 1.3 }}>{label}</Typography>
        {sub && <Typography variant="caption" sx={{ color: 'text.secondary' }}>{sub}</Typography>}
      </Box>
    </Box>
  );
}

/* ─── types ─── */
interface SettingsData {
  profile: { firstName: string; lastName: string; email: string; phone: string };
  preferences: { themeDarkMode: boolean; language: string };
  workshop: { name: string; address: string; phone: string; email: string; siret: string; vatNumber: string; vatRate: string; currency: string };
  invoiceQuote: { conditions: string; vatExempt: boolean; vatNotApplicableArticle293B: boolean };
}

/* ═══════════════════════ main component ═══════════════════════ */
const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [snack, setSnack] = useState<{ open: boolean; msg: string; sev: 'success' | 'error' | 'info' }>({ open: false, msg: '', sev: 'info' });

  const { systemSettings, loadSystemSettings, updateMultipleSystemSettings, currentUser } = useAppStore();
  const { saveSettings } = useWorkshopSettings();

  const [settings, setSettings] = useState<SettingsData>({
    profile: { firstName: '', lastName: '', email: '', phone: '' },
    preferences: { themeDarkMode: false, language: 'fr' },
    workshop: { name: '', address: '', phone: '', email: '', siret: '', vatNumber: '', vatRate: '20', currency: 'EUR' },
    invoiceQuote: { conditions: '', vatExempt: false, vatNotApplicableArticle293B: false },
  });

  /* ── password state ── */
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPw, setShowNewPw] = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);

  /* ── load settings ── */
  useEffect(() => { loadSystemSettings().catch(() => {}); }, [loadSystemSettings]);

  useEffect(() => {
    if (systemSettings.length === 0) return;
    const n = { ...settings };
    const map: Record<string, (v: string) => void> = {
      workshop_name: v => n.workshop.name = v,
      workshop_address: v => n.workshop.address = v,
      workshop_phone: v => n.workshop.phone = v,
      workshop_email: v => n.workshop.email = v,
      workshop_siret: v => n.workshop.siret = v,
      workshop_vat_number: v => n.workshop.vatNumber = v,
      vat_rate: v => n.workshop.vatRate = v,
      currency: v => n.workshop.currency = v,
      language: v => n.preferences.language = v,
      user_first_name: v => n.profile.firstName = v,
      user_last_name: v => n.profile.lastName = v,
      user_email: v => n.profile.email = v,
      user_phone: v => n.profile.phone = v,
      invoice_quote_conditions: v => n.invoiceQuote.conditions = v,
      vat_exempt: v => n.invoiceQuote.vatExempt = v === 'true',
      vat_not_applicable_article_293b: v => n.invoiceQuote.vatNotApplicableArticle293B = v === 'true',
    };
    systemSettings.forEach(s => map[s.key]?.(s.value));
    if (currentUser) {
      if (!n.profile.firstName || n.profile.firstName === 'Utilisateur') n.profile.firstName = currentUser.firstName;
      if (!n.profile.lastName || n.profile.lastName === 'Test') n.profile.lastName = currentUser.lastName;
      if (!n.profile.email || n.profile.email === 'user@example.com') n.profile.email = currentUser.email;
    }
    setSettings(n);
  }, [systemSettings, currentUser]);

  /* ── save ── */
  const handleSave = async () => {
    setLoading(true);
    try {
      await updateMultipleSystemSettings([
        { key: 'workshop_name', value: settings.workshop.name },
        { key: 'workshop_address', value: settings.workshop.address },
        { key: 'workshop_phone', value: settings.workshop.phone },
        { key: 'workshop_email', value: settings.workshop.email },
        { key: 'workshop_siret', value: settings.workshop.siret },
        { key: 'workshop_vat_number', value: settings.workshop.vatNumber },
        { key: 'vat_rate', value: settings.workshop.vatRate },
        { key: 'currency', value: settings.workshop.currency },
        { key: 'language', value: settings.preferences.language },
        { key: 'user_first_name', value: settings.profile.firstName },
        { key: 'user_last_name', value: settings.profile.lastName },
        { key: 'user_email', value: settings.profile.email },
        { key: 'user_phone', value: settings.profile.phone },
        { key: 'invoice_quote_conditions', value: settings.invoiceQuote.conditions },
        { key: 'vat_exempt', value: settings.invoiceQuote.vatExempt ? 'true' : 'false' },
        { key: 'vat_not_applicable_article_293b', value: settings.invoiceQuote.vatNotApplicableArticle293B ? 'true' : 'false' },
      ]);
      if (settings.workshop) await saveSettings(settings.workshop);
      setSnack({ open: true, msg: 'Paramètres sauvegardés avec succès', sev: 'success' });
    } catch {
      setSnack({ open: true, msg: 'Erreur lors de la sauvegarde', sev: 'error' });
    } finally {
      setLoading(false);
    }
  };

  /* ── password ── */
  const pwStrength = (() => {
    let s = 0;
    if (newPassword.length >= 6) s++;
    if (newPassword.length >= 8) s++;
    if (newPassword.length >= 12) s++;
    if (/[a-z]/.test(newPassword)) s++;
    if (/[A-Z]/.test(newPassword)) s++;
    if (/[0-9]/.test(newPassword)) s++;
    if (/[^A-Za-z0-9]/.test(newPassword)) s++;
    if (s <= 2) return { score: s, label: 'Très faible', color: '#ef4444' };
    if (s <= 4) return { label: 'Faible', score: s, color: '#f59e0b' };
    if (s <= 6) return { label: 'Moyen', score: s, color: '#f59e0b' };
    return { label: 'Fort', score: s, color: '#22c55e' };
  })();

  const pwMatch = newPassword && confirmPassword ? newPassword === confirmPassword : null;
  const canChangePassword = pwMatch === true && pwStrength.score >= 3;

  const handleChangePassword = async () => {
    if (!canChangePassword) return;
    setLoading(true);
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword });
      if (error) throw error;
      setSnack({ open: true, msg: 'Mot de passe modifié avec succès', sev: 'success' });
      setNewPassword('');
      setConfirmPassword('');
    } catch (err: any) {
      setSnack({ open: true, msg: err?.message || 'Erreur lors de la modification', sev: 'error' });
    } finally {
      setLoading(false);
    }
  };

  /* ── helpers ── */
  const setProfile = (k: keyof SettingsData['profile'], v: string) =>
    setSettings(p => ({ ...p, profile: { ...p.profile, [k]: v } }));
  const setWorkshop = (k: keyof SettingsData['workshop'], v: string) =>
    setSettings(p => ({ ...p, workshop: { ...p.workshop, [k]: v } }));
  const setInvoice = (k: keyof SettingsData['invoiceQuote'], v: any) =>
    setSettings(p => ({ ...p, invoiceQuote: { ...p.invoiceQuote, [k]: v } }));

  /* ════════════════════════ render ════════════════════════ */
  return (
    <Box sx={{ pb: 4, maxWidth: 900, mx: 'auto' }}>
      {/* ── header ── */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h5" sx={{ fontWeight: 800, letterSpacing: '-0.01em' }}>
          Paramètres
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Gérez vos préférences et les informations de votre atelier
        </Typography>
      </Box>

      {/* ── tabs ── */}
      <Card sx={{ ...CARD_STATIC, mb: 3 }}>
        <Tabs value={activeTab} onChange={(_, v) => setActiveTab(v)} variant="fullWidth"
          sx={{
            '& .MuiTab-root': { textTransform: 'none', fontWeight: 600, fontSize: '0.85rem', py: 2 },
            '& .Mui-selected': { color: '#6366f1 !important' },
            '& .MuiTabs-indicator': { bgcolor: '#6366f1', height: 3, borderRadius: '3px 3px 0 0' },
          }}>
          <Tab icon={<PersonIcon sx={{ fontSize: 20 }} />} iconPosition="start" label="Profil" />
          <Tab icon={<LockIcon sx={{ fontSize: 20 }} />} iconPosition="start" label="Sécurité" />
          <Tab icon={<BusinessIcon sx={{ fontSize: 20 }} />} iconPosition="start" label="Atelier" />
          <Tab icon={<InvoiceIcon sx={{ fontSize: 20 }} />} iconPosition="start" label="Facture & Devis" />
        </Tabs>
      </Card>

      {/* ═══ Tab 0 : Profil ═══ */}
      {activeTab === 0 && (
        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: 3 }}>
            <SectionLabel icon={<PersonIcon sx={{ fontSize: 20 }} />} color="#6366f1"
              label="Informations personnelles" sub="Gérez vos informations de profil et vos coordonnées" />

            <Grid container spacing={2.5}>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Prénom" placeholder="Ex : Jean"
                  value={settings.profile.firstName} onChange={e => setProfile('firstName', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><BadgeIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Nom" placeholder="Ex : Dupont"
                  value={settings.profile.lastName} onChange={e => setProfile('lastName', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><BadgeIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Email" placeholder="Ex : jean.dupont@email.com" type="email"
                  value={settings.profile.email} onChange={e => setProfile('email', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><EmailIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Téléphone" placeholder="Ex : 06 12 34 56 78" type="tel"
                  value={settings.profile.phone} onChange={e => setProfile('phone', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><PhoneIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {/* ═══ Tab 1 : Sécurité ═══ */}
      {activeTab === 1 && (
        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: 3 }}>
            <SectionLabel icon={<LockIcon sx={{ fontSize: 20 }} />} color="#ef4444"
              label="Sécurité du compte" sub="Gérez votre mot de passe" />

            <Card sx={{ ...CARD_STATIC, bgcolor: 'rgba(0,0,0,0.01)', p: 0 }}>
              <CardContent sx={{ p: 3 }}>
                <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 2.5 }}>Changer le mot de passe</Typography>

                <Grid container spacing={2.5}>
                  <Grid item xs={12}>
                    <TextField fullWidth size="small" label="Nouveau mot de passe"
                      type={showNewPw ? 'text' : 'password'}
                      value={newPassword} onChange={e => setNewPassword(e.target.value)} sx={INPUT_SX}
                      placeholder="Entrez votre nouveau mot de passe"
                      InputProps={{
                        startAdornment: <InputAdornment position="start"><LockIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment>,
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton size="small" onClick={() => setShowNewPw(!showNewPw)}>
                              {showNewPw ? <VisOffIcon sx={{ fontSize: 18 }} /> : <VisIcon sx={{ fontSize: 18 }} />}
                            </IconButton>
                          </InputAdornment>
                        ),
                      }} />
                    {newPassword && (
                      <Box sx={{ mt: 1 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 0.5 }}>
                          <Typography variant="caption" sx={{ color: 'text.secondary' }}>Force du mot de passe</Typography>
                          <Typography variant="caption" sx={{ fontWeight: 600, color: pwStrength.color }}>{pwStrength.label}</Typography>
                        </Box>
                        <LinearProgress variant="determinate" value={(pwStrength.score / 7) * 100}
                          sx={{ height: 4, borderRadius: 2, bgcolor: 'rgba(0,0,0,0.06)',
                            '& .MuiLinearProgress-bar': { bgcolor: pwStrength.color, borderRadius: 2 } }} />
                      </Box>
                    )}
                  </Grid>
                  <Grid item xs={12}>
                    <TextField fullWidth size="small" label="Confirmer le mot de passe"
                      type={showConfirmPw ? 'text' : 'password'}
                      value={confirmPassword} onChange={e => setConfirmPassword(e.target.value)} sx={INPUT_SX}
                      placeholder="Confirmez votre nouveau mot de passe"
                      InputProps={{
                        startAdornment: <InputAdornment position="start"><LockIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment>,
                        endAdornment: (
                          <InputAdornment position="end">
                            <IconButton size="small" onClick={() => setShowConfirmPw(!showConfirmPw)}>
                              {showConfirmPw ? <VisOffIcon sx={{ fontSize: 18 }} /> : <VisIcon sx={{ fontSize: 18 }} />}
                            </IconButton>
                          </InputAdornment>
                        ),
                      }} />
                    {pwMatch !== null && (
                      <Typography variant="caption" sx={{ mt: 0.5, display: 'block', fontWeight: 600,
                        color: pwMatch ? '#22c55e' : '#ef4444' }}>
                        {pwMatch ? 'Les mots de passe correspondent' : 'Les mots de passe ne correspondent pas'}
                      </Typography>
                    )}
                  </Grid>
                </Grid>

                {/* requirements */}
                <Box sx={{ mt: 2, p: 2, borderRadius: '10px', bgcolor: alpha('#3b82f6', 0.06), border: `1px solid ${alpha('#3b82f6', 0.15)}` }}>
                  <Typography variant="caption" sx={{ fontWeight: 700, color: '#3b82f6', display: 'block', mb: 0.5 }}>
                    Exigences de sécurité
                  </Typography>
                  <Typography variant="caption" sx={{ color: '#3b82f6', lineHeight: 1.8 }}>
                    - Au moins 6 caractères<br />
                    - Lettres, chiffres et symboles recommandés<br />
                    - Évitez les mots de passe courants
                  </Typography>
                </Box>

                <Button fullWidth variant="contained" onClick={handleChangePassword}
                  disabled={loading || !canChangePassword}
                  sx={{ mt: 3, borderRadius: '10px', textTransform: 'none', fontWeight: 600, py: 1.3,
                    bgcolor: canChangePassword ? '#6366f1' : undefined,
                    '&:hover': { bgcolor: canChangePassword ? '#4f46e5' : undefined },
                    boxShadow: canChangePassword ? `0 4px 14px ${alpha('#6366f1', 0.4)}` : 'none',
                  }}>
                  {loading ? 'Modification en cours...' : 'Modifier le mot de passe'}
                </Button>
              </CardContent>
            </Card>
          </CardContent>
        </Card>
      )}

      {/* ═══ Tab 2 : Atelier ═══ */}
      {activeTab === 2 && (
        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: 3 }}>
            <SectionLabel icon={<BusinessIcon sx={{ fontSize: 20 }} />} color="#22c55e"
              label="Informations de l'atelier" sub="Configurez les informations de votre atelier et vos paramètres commerciaux" />

            <Grid container spacing={2.5}>
              <Grid item xs={12}>
                <TextField fullWidth size="small" label="Nom de l'atelier" placeholder="Ex : Atelier de réparation"
                  value={settings.workshop.name} onChange={e => setWorkshop('name', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><StoreIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12}>
                <TextField fullWidth size="small" label="Adresse" placeholder="Ex : 123 Rue de la Paix, 75001 Paris"
                  value={settings.workshop.address} onChange={e => setWorkshop('address', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><LocationIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Téléphone" placeholder="Ex : 01 23 45 67 89" type="tel"
                  value={settings.workshop.phone} onChange={e => setWorkshop('phone', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><PhoneIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={6}>
                <TextField fullWidth size="small" label="Email" placeholder="Ex : contact@atelier.fr" type="email"
                  value={settings.workshop.email} onChange={e => setWorkshop('email', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><EmailIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>

              <Grid item xs={12}><Divider sx={{ my: 0.5 }} /></Grid>

              <Grid item xs={12} md={4}>
                <TextField fullWidth size="small" label="SIRET" placeholder="123 456 789 00012"
                  value={settings.workshop.siret} onChange={e => setWorkshop('siret', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><SiretIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField fullWidth size="small" label="Numéro de TVA" placeholder="FR12345678901"
                  value={settings.workshop.vatNumber} onChange={e => setWorkshop('vatNumber', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><ArticleIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>
              <Grid item xs={12} md={4}>
                <TextField fullWidth size="small" label="Taux de TVA (%)" type="number"
                  value={settings.workshop.vatRate} onChange={e => setWorkshop('vatRate', e.target.value)} sx={INPUT_SX}
                  InputProps={{ startAdornment: <InputAdornment position="start"><PercentIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment> }} />
              </Grid>

              <Grid item xs={12} md={4}>
                <FormControl fullWidth size="small" sx={INPUT_SX}>
                  <InputLabel>Devise</InputLabel>
                  <Select value={settings.workshop.currency} label="Devise"
                    onChange={e => setWorkshop('currency', e.target.value as string)}
                    startAdornment={<InputAdornment position="start"><EuroIcon sx={{ fontSize: 18, color: 'text.disabled' }} /></InputAdornment>}>
                    <MenuItem value="EUR">EUR</MenuItem>
                    <MenuItem value="USD">USD ($)</MenuItem>
                    <MenuItem value="CHF">CHF</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      )}

      {/* ═══ Tab 3 : Facture & Devis ═══ */}
      {activeTab === 3 && (
        <Card sx={CARD_STATIC}>
          <CardContent sx={{ p: 3 }}>
            <SectionLabel icon={<InvoiceIcon sx={{ fontSize: 20 }} />} color="#8b5cf6"
              label="Facture & Devis" sub="Configurez les conditions et politiques de vos documents" />

            <TextField fullWidth size="small" label="Conditions / Politiques" multiline rows={6}
              placeholder="Ex : Facture valable 30 jours. Aucun escompte en cas de paiement anticipé."
              value={settings.invoiceQuote.conditions} onChange={e => setInvoice('conditions', e.target.value)} sx={{ ...INPUT_SX, mb: 1 }} />
            <Typography variant="caption" sx={{ color: 'text.disabled', fontStyle: 'italic', display: 'block', mb: 3 }}>
              Ces conditions seront affichées sur toutes vos factures et devis.
            </Typography>

            {/* VAT switches */}
            <Card sx={{ ...CARD_STATIC, bgcolor: 'rgba(0,0,0,0.01)', mb: 2 }}>
              <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                  <Box sx={{ width: 36, height: 36, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    bgcolor: alpha('#f59e0b', 0.10), color: '#f59e0b', flexShrink: 0, mt: 0.5 }}>
                    <PercentIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Box sx={{ flex: 1 }}>
                    <FormControlLabel
                      control={<Switch checked={settings.invoiceQuote.vatExempt}
                        onChange={e => setInvoice('vatExempt', e.target.checked)}
                        sx={{ '& .Mui-checked': { color: '#f59e0b' }, '& .Mui-checked+.MuiSwitch-track': { bgcolor: '#f59e0b' } }} />}
                      label={<Typography variant="subtitle2" sx={{ fontWeight: 700 }}>Exonéré de TVA</Typography>}
                      sx={{ m: 0 }} />
                    <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 0.5 }}>
                      "Exonéré de TVA" sera affiché sur vos documents. Le total TTC sera égal au total HT.
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>

            <Card sx={{ ...CARD_STATIC, bgcolor: 'rgba(0,0,0,0.01)' }}>
              <CardContent sx={{ p: 2.5, '&:last-child': { pb: 2.5 } }}>
                <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
                  <Box sx={{ width: 36, height: 36, borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    bgcolor: alpha('#8b5cf6', 0.10), color: '#8b5cf6', flexShrink: 0, mt: 0.5 }}>
                    <GavelIcon sx={{ fontSize: 18 }} />
                  </Box>
                  <Box sx={{ flex: 1 }}>
                    <FormControlLabel
                      control={<Switch checked={settings.invoiceQuote.vatNotApplicableArticle293B}
                        onChange={e => setInvoice('vatNotApplicableArticle293B', e.target.checked)}
                        sx={{ '& .Mui-checked': { color: '#8b5cf6' }, '& .Mui-checked+.MuiSwitch-track': { bgcolor: '#8b5cf6' } }} />}
                      label={<Typography variant="subtitle2" sx={{ fontWeight: 700 }}>TVA non applicable, art. 293 B du CGI</Typography>}
                      sx={{ m: 0 }} />
                    <Typography variant="caption" sx={{ color: 'text.secondary', display: 'block', mt: 0.5 }}>
                      Cette mention légale sera affichée sur vos factures et devis.
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </CardContent>
        </Card>
      )}

      {/* ── save button ── */}
      {activeTab !== 1 && (
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', mt: 3 }}>
          <Button variant="contained" startIcon={<SaveIcon />} onClick={handleSave} disabled={loading}
            sx={{ ...BTN_DARK, px: 4, py: 1.3,
              bgcolor: '#22c55e', '&:hover': { bgcolor: '#16a34a' },
              boxShadow: `0 4px 14px ${alpha('#22c55e', 0.4)}`,
              '&.Mui-disabled': { bgcolor: alpha('#22c55e', 0.5), color: '#fff' },
            }}>
            {loading ? 'Sauvegarde...' : 'Sauvegarder les paramètres'}
          </Button>
        </Box>
      )}

      {/* ── snackbar ── */}
      <Snackbar open={snack.open} autoHideDuration={3000} onClose={() => setSnack(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity={snack.sev} variant="filled" sx={{ borderRadius: '10px', fontWeight: 600 }}
          onClose={() => setSnack(s => ({ ...s, open: false }))}>
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Settings;
