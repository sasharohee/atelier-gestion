import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { quoteRequestServiceReal } from '../../services/quoteRequestServiceReal';
import { toast } from 'react-hot-toast';

declare global {
  interface Window {
    __REACT_DEVTOOLS_GLOBAL_HOOK__?: any;
    __REDUX_DEVTOOLS_EXTENSION__?: any;
    __VUE_DEVTOOLS_GLOBAL_HOOK__?: any;
  }
}

// ── Styles ────────────────────────────────────────────────────────────────────

const colors = {
  primary: '#2563eb',
  primaryDark: '#1d4ed8',
  primaryLight: '#dbeafe',
  accent: '#0ea5e9',
  success: '#10b981',
  successLight: '#d1fae5',
  warning: '#f59e0b',
  warningLight: '#fef3c7',
  danger: '#ef4444',
  dangerLight: '#fee2e2',
  critical: '#dc2626',
  bg: '#f8fafc',
  card: '#ffffff',
  border: '#e2e8f0',
  borderFocus: '#2563eb',
  text: '#1e293b',
  textSecondary: '#64748b',
  textMuted: '#94a3b8',
};

const fieldStyle: React.CSSProperties = {
  width: '100%',
  padding: '12px 16px',
  border: `1.5px solid ${colors.border}`,
  borderRadius: '10px',
  fontSize: '15px',
  color: colors.text,
  boxSizing: 'border-box',
  outline: 'none',
  transition: 'border-color 0.2s, box-shadow 0.2s',
  background: colors.card,
  fontFamily: 'inherit',
};

const labelStyle: React.CSSProperties = {
  display: 'block',
  marginBottom: '6px',
  fontWeight: 600,
  color: colors.text,
  fontSize: '14px',
  letterSpacing: '0.01em',
};

const fieldFocus = (e: React.FocusEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
  e.target.style.borderColor = colors.borderFocus;
  e.target.style.boxShadow = `0 0 0 3px ${colors.primaryLight}`;
};

const fieldBlur = (e: React.FocusEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
  e.target.style.borderColor = colors.border;
  e.target.style.boxShadow = 'none';
};

// ── Steps config ──────────────────────────────────────────────────────────────

const steps = [
  { num: 1, label: 'Client', icon: '👤' },
  { num: 2, label: 'Adresse', icon: '📍' },
  { num: 3, label: 'Appareil', icon: '📱' },
];

// ── Component ─────────────────────────────────────────────────────────────────

const QuoteRequestPageFixed: React.FC = () => {
  const { customUrl } = useParams<{ customUrl: string }>();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [technicianId, setTechnicianId] = useState<string>('');
  const [urlNotFound, setUrlNotFound] = useState(false);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    vatNumber: '',
    sirenNumber: '',
    address: '',
    addressComplement: '',
    region: '',
    postalCode: '',
    city: '',
    deviceType: '',
    brand: '',
    model: '',
    deviceId: '',
    color: '',
    accessories: '',
    defects: '',
    deviceRemarks: '',
    urgency: 'medium',
  });

  useEffect(() => {
    if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) window.__REACT_DEVTOOLS_GLOBAL_HOOK__.isDisabled = true;
    if (window.__REDUX_DEVTOOLS_EXTENSION__) window.__REDUX_DEVTOOLS_EXTENSION__ = undefined;
    if (window.__VUE_DEVTOOLS_GLOBAL_HOOK__) window.__VUE_DEVTOOLS_GLOBAL_HOOK__.enabled = false;
    const origError = console.error;
    console.error = (...args) => {
      if (typeof args[0] === 'string' && args[0].includes('runtime.lastError')) return;
      origError.apply(console, args);
    };
  }, []);

  useEffect(() => {
    const fetchTechnicianId = async () => {
      if (!customUrl) return;
      try {
        const { data, error } = await quoteRequestServiceReal.getCustomUrlByUrl(customUrl);
        if (error || !data?.technician_id) {
          setUrlNotFound(true);
          return;
        }
        setTechnicianId(data.technician_id);
      } catch {
        setUrlNotFound(true);
      }
    };
    fetchTechnicianId();
  }, [customUrl]);

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleNext = async () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } else {
      await handleSubmit();
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const handleSubmit = async () => {
    if (!technicianId || !customUrl) {
      toast.error('Informations manquantes pour soumettre la demande');
      return;
    }
    setIsSubmitting(true);
    try {
      const requestData = {
        customUrl,
        technicianId,
        clientFirstName: formData.firstName,
        clientLastName: formData.lastName,
        clientEmail: formData.email,
        clientPhone: formData.phone,
        description: `Demande de devis pour ${formData.deviceType} ${formData.brand} ${formData.model}`,
        deviceType: formData.deviceType,
        deviceBrand: formData.brand,
        deviceModel: formData.model,
        issueDescription: formData.defects,
        urgency: formData.urgency,
        status: 'pending',
        priority: 'medium',
        source: 'website',
        ipAddress: null,
        userAgent: navigator.userAgent,
        company: formData.company,
        vatNumber: formData.vatNumber,
        sirenNumber: formData.sirenNumber,
        address: formData.address,
        addressComplement: formData.addressComplement,
        city: formData.city,
        postalCode: formData.postalCode,
        region: formData.region,
        deviceId: formData.deviceId,
        color: formData.color,
        accessories: formData.accessories,
        deviceRemarks: formData.deviceRemarks,
      };
      const newRequest = await quoteRequestServiceReal.createQuoteRequest(requestData);
      if (!newRequest) throw new Error('Erreur lors de la création');
      setIsSubmitted(true);
    } catch (error) {
      console.error('Erreur lors de l\'envoi:', error);
      toast.error('Une erreur est survenue lors de l\'envoi de votre demande');
    } finally {
      setIsSubmitting(false);
    }
  };

  // ── URL not found ───────────────────────────────────────────────────────────

  if (urlNotFound) {
    return (
      <div style={{ minHeight: '100vh', background: colors.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', padding: '20px' }}>
        <div style={{ textAlign: 'center', maxWidth: 440, background: colors.card, borderRadius: 20, padding: '48px 36px', boxShadow: '0 4px 24px rgba(0,0,0,0.06)' }}>
          <div style={{ fontSize: 56, marginBottom: 16 }}>🔗</div>
          <h2 style={{ color: colors.text, fontSize: 22, margin: '0 0 12px', fontWeight: 700 }}>Lien introuvable</h2>
          <p style={{ color: colors.textSecondary, fontSize: 15, lineHeight: 1.6, margin: 0 }}>
            Ce lien de demande de devis n'existe pas ou a été désactivé. Veuillez vérifier l'URL ou contacter votre réparateur.
          </p>
        </div>
      </div>
    );
  }

  // ── Success screen ──────────────────────────────────────────────────────────

  if (isSubmitted) {
    return (
      <div style={{ minHeight: '100vh', background: colors.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', padding: '20px' }}>
        <div style={{ textAlign: 'center', maxWidth: 480, background: colors.card, borderRadius: 20, padding: '48px 36px', boxShadow: '0 4px 24px rgba(0,0,0,0.06)' }}>
          <div style={{
            width: 80, height: 80, borderRadius: '50%', background: colors.successLight,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 24px', fontSize: 40,
          }}>
            ✓
          </div>
          <h2 style={{ color: colors.text, fontSize: 24, margin: '0 0 12px', fontWeight: 700 }}>
            Demande envoyée !
          </h2>
          <p style={{ color: colors.textSecondary, fontSize: 15, lineHeight: 1.7, margin: '0 0 32px' }}>
            Votre demande de devis a été transmise avec succès.<br />
            Le technicien vous recontactera dans les meilleurs délais.
          </p>
          <button
            onClick={() => {
              setIsSubmitted(false);
              setCurrentStep(1);
              setFormData({
                firstName: '', lastName: '', email: '', phone: '',
                company: '', vatNumber: '', sirenNumber: '',
                address: '', addressComplement: '', region: '', postalCode: '', city: '',
                deviceType: '', brand: '', model: '', deviceId: '',
                color: '', accessories: '', defects: '', deviceRemarks: '',
                urgency: 'medium',
              });
            }}
            style={{
              padding: '14px 32px', border: 'none', borderRadius: 12,
              background: colors.primary, color: '#fff', fontSize: 15,
              fontWeight: 600, cursor: 'pointer', transition: 'background 0.2s',
            }}
            onMouseOver={e => (e.currentTarget.style.background = colors.primaryDark)}
            onMouseOut={e => (e.currentTarget.style.background = colors.primary)}
          >
            Envoyer une autre demande
          </button>
        </div>
      </div>
    );
  }

  // ── Stepper ─────────────────────────────────────────────────────────────────

  const renderStepper = () => (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0, padding: '0 20px' }}>
      {steps.map((step, i) => {
        const isActive = currentStep === step.num;
        const isDone = currentStep > step.num;
        return (
          <React.Fragment key={step.num}>
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, minWidth: 72 }}>
              <div style={{
                width: 44, height: 44, borderRadius: '50%',
                background: isDone ? colors.success : isActive ? colors.primary : '#e2e8f0',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: isDone || isActive ? '#fff' : colors.textMuted,
                fontSize: isDone ? 18 : 15, fontWeight: 700,
                transition: 'all 0.3s ease',
                boxShadow: isActive ? `0 0 0 4px ${colors.primaryLight}` : isDone ? `0 0 0 4px ${colors.successLight}` : 'none',
              }}>
                {isDone ? '✓' : step.icon}
              </div>
              <span style={{
                fontSize: 12, fontWeight: isActive ? 700 : 500,
                color: isActive ? colors.primary : isDone ? colors.success : colors.textMuted,
                transition: 'color 0.3s',
              }}>
                {step.label}
              </span>
            </div>
            {i < steps.length - 1 && (
              <div style={{
                flex: 1, height: 3, borderRadius: 2, margin: '0 8px',
                background: currentStep > step.num ? colors.success : '#e2e8f0',
                transition: 'background 0.3s', marginBottom: 22,
              }} />
            )}
          </React.Fragment>
        );
      })}
    </div>
  );

  // ── Step 1 ── Client ────────────────────────────────────────────────────────

  const renderStep1 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      {/* Identité */}
      <section>
        <SectionHeader icon="👤" title="Identité" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
          <InputField label="Prénom" field="firstName" value={formData.firstName} onChange={handleInputChange} required placeholder="Jean" />
          <InputField label="Nom" field="lastName" value={formData.lastName} onChange={handleInputChange} required placeholder="Dupont" />
        </div>
      </section>

      {/* Contact */}
      <section>
        <SectionHeader icon="📧" title="Contact" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
          <InputField label="Email" field="email" value={formData.email} onChange={handleInputChange} required type="email" placeholder="jean.dupont@email.com" />
          <div>
            <label style={labelStyle}>
              Téléphone <span style={{ color: colors.danger }}>*</span>
            </label>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{
                ...fieldStyle,
                width: 64, textAlign: 'center', background: '#f1f5f9',
                color: colors.textSecondary, fontWeight: 600, flexShrink: 0,
              }}>
                +33
              </div>
              <input
                type="tel"
                required
                value={formData.phone}
                onChange={e => handleInputChange('phone', e.target.value)}
                style={{ ...fieldStyle, flex: 1 }}
                onFocus={fieldFocus}
                onBlur={fieldBlur}
                placeholder="6 12 34 56 78"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Entreprise (optionnel) */}
      <section>
        <SectionHeader icon="🏢" title="Entreprise" subtitle="(optionnel)" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
          <InputField label="Nom de la société" field="company" value={formData.company} onChange={handleInputChange} placeholder="Ma société SARL" />
          <InputField label="N° TVA" field="vatNumber" value={formData.vatNumber} onChange={handleInputChange} placeholder="FR 12 345678901" />
          <InputField label="N° SIREN" field="sirenNumber" value={formData.sirenNumber} onChange={handleInputChange} placeholder="123 456 789" />
        </div>
      </section>

      {/* Urgence */}
      <section>
        <SectionHeader icon="⚡" title="Niveau d'urgence" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 10 }}>
          {([
            { value: 'low', label: 'Faible', desc: 'Pas pressé', color: colors.success, bg: colors.successLight },
            { value: 'medium', label: 'Moyenne', desc: 'Sous 2-3 jours', color: colors.warning, bg: colors.warningLight },
            { value: 'high', label: 'Élevée', desc: 'Urgent (24h)', color: colors.danger, bg: colors.dangerLight },
            { value: 'critical', label: 'Critique', desc: 'Immédiat', color: colors.critical, bg: '#fef2f2' },
          ] as const).map(u => {
            const selected = formData.urgency === u.value;
            return (
              <button
                key={u.value}
                type="button"
                onClick={() => handleInputChange('urgency', u.value)}
                style={{
                  padding: '14px 16px',
                  border: `2px solid ${selected ? u.color : colors.border}`,
                  borderRadius: 12,
                  background: selected ? u.bg : colors.card,
                  cursor: 'pointer',
                  textAlign: 'left',
                  transition: 'all 0.2s',
                  outline: 'none',
                }}
              >
                <div style={{ fontWeight: 700, fontSize: 14, color: selected ? u.color : colors.text, marginBottom: 2 }}>
                  {u.label}
                </div>
                <div style={{ fontSize: 12, color: colors.textSecondary }}>{u.desc}</div>
              </button>
            );
          })}
        </div>
      </section>
    </div>
  );

  // ── Step 2 ── Adresse ───────────────────────────────────────────────────────

  const renderStep2 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      <section>
        <SectionHeader icon="📍" title="Adresse" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
          <InputField label="Adresse" field="address" value={formData.address} onChange={handleInputChange} required placeholder="12 rue de la Paix" span />
          <InputField label="Complément d'adresse" field="addressComplement" value={formData.addressComplement} onChange={handleInputChange} placeholder="Bâtiment A, Apt 3" span />
          <InputField label="Code postal" field="postalCode" value={formData.postalCode} onChange={handleInputChange} required placeholder="75001" />
          <InputField label="Ville" field="city" value={formData.city} onChange={handleInputChange} required placeholder="Paris" />
          <InputField label="Région" field="region" value={formData.region} onChange={handleInputChange} placeholder="Île-de-France" />
        </div>
      </section>
    </div>
  );

  // ── Step 3 ── Appareil ──────────────────────────────────────────────────────

  const renderStep3 = () => (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 28 }}>
      <section>
        <SectionHeader icon="📱" title="Appareil" />
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 18 }}>
          <div>
            <label style={labelStyle}>
              Type d'appareil <span style={{ color: colors.danger }}>*</span>
            </label>
            <select
              required
              value={formData.deviceType}
              onChange={e => handleInputChange('deviceType', e.target.value)}
              style={{ ...fieldStyle, appearance: 'none', backgroundImage: 'url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'12\' height=\'12\' viewBox=\'0 0 12 12\'%3E%3Cpath fill=\'%2364748b\' d=\'M6 8L1 3h10z\'/%3E%3C/svg%3E")', backgroundRepeat: 'no-repeat', backgroundPosition: 'right 14px center' }}
              onFocus={fieldFocus as any}
              onBlur={fieldBlur as any}
            >
              <option value="">Choisir le type</option>
              <option value="smartphone">Smartphone</option>
              <option value="tablet">Tablette</option>
              <option value="laptop">Ordinateur portable</option>
              <option value="desktop">Ordinateur de bureau</option>
              <option value="console">Console de jeu</option>
              <option value="other">Autre</option>
            </select>
          </div>
          <InputField label="Marque" field="brand" value={formData.brand} onChange={handleInputChange} required placeholder="Apple, Samsung, HP..." />
          <InputField label="Modèle" field="model" value={formData.model} onChange={handleInputChange} required placeholder="iPhone 15, Galaxy S24..." />
          <InputField label="Couleur" field="color" value={formData.color} onChange={handleInputChange} placeholder="Noir, Blanc..." />
          <InputField label="IMEI / N° Série" field="deviceId" value={formData.deviceId} onChange={handleInputChange} placeholder="Numéro d'identification" />
          <InputField label="Accessoires fournis" field="accessories" value={formData.accessories} onChange={handleInputChange} placeholder="Chargeur, coque..." />
        </div>
      </section>

      <section>
        <SectionHeader icon="🔍" title="Description du problème" />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 18 }}>
          <TextareaField
            label="Décrivez les défauts"
            field="defects"
            value={formData.defects}
            onChange={handleInputChange}
            required
            placeholder="Décrivez en détail le(s) problème(s) rencontré(s) avec votre appareil..."
            rows={5}
          />
          <TextareaField
            label="Remarques supplémentaires"
            field="deviceRemarks"
            value={formData.deviceRemarks}
            onChange={handleInputChange}
            placeholder="Informations complémentaires, état de l'appareil, historique de réparations..."
            rows={3}
          />
        </div>
      </section>
    </div>
  );

  // ── Render ──────────────────────────────────────────────────────────────────

  return (
    <div style={{
      minHeight: '100vh',
      background: `linear-gradient(135deg, ${colors.bg} 0%, #eef2ff 50%, #f0f9ff 100%)`,
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      padding: '24px 16px',
    }}>
      <div style={{
        maxWidth: 720,
        margin: '0 auto',
      }}>
        {/* ── Header card ──────────────────────────────────────────────── */}
        <div style={{
          background: colors.card,
          borderRadius: 20,
          boxShadow: '0 1px 3px rgba(0,0,0,0.04), 0 6px 24px rgba(0,0,0,0.06)',
          overflow: 'hidden',
          marginBottom: 20,
        }}>
          {/* Brand bar */}
          <div style={{
            background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.accent} 100%)`,
            padding: '28px 32px',
            textAlign: 'center',
          }}>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 14,
            }}>
              <div style={{
                width: 48, height: 48, borderRadius: 14,
                background: 'rgba(255,255,255,0.2)', backdropFilter: 'blur(8px)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 24,
              }}>
                🔧
              </div>
              <div style={{ textAlign: 'left' }}>
                <div style={{ color: '#fff', fontSize: 20, fontWeight: 800, letterSpacing: '-0.02em' }}>
                  Demande de devis
                </div>
                <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 13, fontWeight: 500 }}>
                  Remplissez le formulaire pour recevoir votre devis
                </div>
              </div>
            </div>
          </div>

          {/* Stepper */}
          <div style={{ padding: '20px 16px 16px' }}>
            {renderStepper()}
          </div>
        </div>

        {/* ── Form card ────────────────────────────────────────────────── */}
        <div style={{
          background: colors.card,
          borderRadius: 20,
          boxShadow: '0 1px 3px rgba(0,0,0,0.04), 0 6px 24px rgba(0,0,0,0.06)',
          overflow: 'hidden',
        }}>
          {/* Form body */}
          <div style={{ padding: '32px 28px' }}>
            {currentStep === 1 && renderStep1()}
            {currentStep === 2 && renderStep2()}
            {currentStep === 3 && renderStep3()}
          </div>

          {/* Footer */}
          <div style={{
            padding: '20px 28px',
            borderTop: `1px solid ${colors.border}`,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            background: '#fafbfc',
          }}>
            <button
              onClick={handlePrevious}
              disabled={currentStep === 1}
              style={{
                padding: '12px 24px',
                border: `1.5px solid ${colors.border}`,
                borderRadius: 12,
                background: colors.card,
                color: currentStep === 1 ? colors.textMuted : colors.text,
                fontSize: 14,
                fontWeight: 600,
                cursor: currentStep === 1 ? 'default' : 'pointer',
                opacity: currentStep === 1 ? 0.5 : 1,
                transition: 'all 0.2s',
              }}
              onMouseOver={e => { if (currentStep > 1) { e.currentTarget.style.borderColor = colors.primary; e.currentTarget.style.color = colors.primary; } }}
              onMouseOut={e => { if (currentStep > 1) { e.currentTarget.style.borderColor = colors.border; e.currentTarget.style.color = colors.text; } }}
            >
              ← Précédent
            </button>

            <span style={{ fontSize: 13, color: colors.textMuted, fontWeight: 500 }}>
              Étape {currentStep} sur 3
            </span>

            <button
              onClick={handleNext}
              disabled={isSubmitting}
              style={{
                padding: '12px 28px',
                border: 'none',
                borderRadius: 12,
                background: currentStep === 3
                  ? (isSubmitting ? colors.textMuted : colors.success)
                  : (isSubmitting ? colors.textMuted : colors.primary),
                color: '#fff',
                fontSize: 14,
                fontWeight: 700,
                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                boxShadow: isSubmitting ? 'none' : `0 2px 8px ${currentStep === 3 ? 'rgba(16,185,129,0.3)' : 'rgba(37,99,235,0.3)'}`,
              }}
              onMouseOver={e => { if (!isSubmitting) e.currentTarget.style.transform = 'translateY(-1px)'; }}
              onMouseOut={e => { e.currentTarget.style.transform = 'translateY(0)'; }}
            >
              {isSubmitting ? 'Envoi en cours...' : currentStep === 3 ? 'Envoyer la demande ✓' : 'Suivant →'}
            </button>
          </div>
        </div>

        {/* ── Footnote ─────────────────────────────────────────────────── */}
        <p style={{
          textAlign: 'center', color: colors.textMuted,
          fontSize: 12, marginTop: 20, lineHeight: 1.5,
        }}>
          Vos données sont utilisées uniquement pour traiter votre demande de devis.
        </p>
      </div>
    </div>
  );
};

// ── Sub-components ────────────────────────────────────────────────────────────

const InputField: React.FC<{
  label: string; field: string; value: string;
  onChange: (field: string, value: string) => void;
  required?: boolean; type?: string; placeholder: string; span?: boolean;
}> = ({ label, field, value, onChange, required, type = 'text', placeholder, span }) => (
  <div style={span ? { gridColumn: '1 / -1' } : undefined}>
    <label style={labelStyle}>
      {label} {required && <span style={{ color: colors.danger }}>*</span>}
    </label>
    <input
      type={type}
      required={required}
      value={value}
      onChange={e => onChange(field, e.target.value)}
      style={fieldStyle}
      onFocus={fieldFocus}
      onBlur={fieldBlur}
      placeholder={placeholder}
    />
  </div>
);

const TextareaField: React.FC<{
  label: string; field: string; value: string;
  onChange: (field: string, value: string) => void;
  required?: boolean; placeholder: string; rows?: number;
}> = ({ label, field, value, onChange, required, placeholder, rows = 4 }) => (
  <div style={{ gridColumn: '1 / -1' }}>
    <label style={labelStyle}>
      {label} {required && <span style={{ color: colors.danger }}>*</span>}
    </label>
    <textarea
      required={required}
      rows={rows}
      value={value}
      onChange={e => onChange(field, e.target.value)}
      style={{ ...fieldStyle, resize: 'vertical' as const }}
      onFocus={fieldFocus as any}
      onBlur={fieldBlur as any}
      placeholder={placeholder}
    />
  </div>
);

const SectionHeader: React.FC<{ icon: string; title: string; subtitle?: string }> = ({ icon, title, subtitle }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 10,
    marginBottom: 18, paddingBottom: 10,
    borderBottom: `2px solid ${colors.border}`,
  }}>
    <span style={{ fontSize: 20 }}>{icon}</span>
    <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: colors.text }}>
      {title}
    </h3>
    {subtitle && (
      <span style={{ fontSize: 13, color: colors.textMuted, fontWeight: 400 }}>{subtitle}</span>
    )}
  </div>
);

export default QuoteRequestPageFixed;
