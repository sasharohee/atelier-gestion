import React, { useState, useEffect } from 'react';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { supabase } from '../../lib/supabase';
import { theme } from '../../theme';

interface SettingsData {
  profile: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
  };
  preferences: {
    themeDarkMode: boolean;
    language: string;
  };
  workshop: {
    name: string;
    address: string;
    phone: string;
    email: string;
    siret: string;
    vatNumber: string;
    vatRate: string;
    currency: string;
  };
}

const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' | 'info' } | null>(null);
  
  const { 
    systemSettings, 
    loadSystemSettings, 
    updateMultipleSystemSettings,
    currentUser 
  } = useAppStore();
  
  const [settings, setSettings] = useState<SettingsData>({
    profile: {
      firstName: '',
      lastName: '',
      email: '',
      phone: ''
    },
    preferences: {
      themeDarkMode: false,
      language: 'fr'
    },
    workshop: {
      name: '',
      address: '',
      phone: '',
      email: '',
      siret: '',
      vatNumber: '',
      vatRate: '20',
      currency: 'EUR'
    }
  });

  const [passwordStrength, setPasswordStrength] = useState<{
    score: number;
    feedback: string;
    color: string;
  }>({ score: 0, feedback: '', color: '#666' });
  
  const [passwordMatch, setPasswordMatch] = useState<{
    match: boolean;
    message: string;
    color: string;
  }>({ match: false, message: '', color: '#666' });

  const { saveSettings } = useWorkshopSettings();

  // Charger les paramètres depuis la base de données
  useEffect(() => {
    const loadSettings = async () => {
      try {
        await loadSystemSettings();
      } catch (error) {
        console.error('Erreur lors du chargement des paramètres:', error);
      }
    };
    
    loadSettings();
  }, [loadSystemSettings]);

  // Mettre à jour les paramètres quand systemSettings change
  useEffect(() => {
    if (systemSettings.length > 0) {
      const newSettings = { ...settings };
      
      // Mettre à jour les paramètres de l'atelier depuis la base de données
      systemSettings.forEach(setting => {
        switch (setting.key) {
          case 'workshop_name':
            newSettings.workshop.name = setting.value;
            break;
          case 'workshop_address':
            newSettings.workshop.address = setting.value;
            break;
          case 'workshop_phone':
            newSettings.workshop.phone = setting.value;
            break;
          case 'workshop_email':
            newSettings.workshop.email = setting.value;
            break;
          case 'workshop_siret':
            newSettings.workshop.siret = setting.value;
            break;
          case 'workshop_vat_number':
            newSettings.workshop.vatNumber = setting.value;
            break;
          case 'vat_rate':
            newSettings.workshop.vatRate = setting.value;
            break;
          case 'currency':
            newSettings.workshop.currency = setting.value;
            break;

          case 'language':
            newSettings.preferences.language = setting.value;
            break;
          case 'user_first_name':
            newSettings.profile.firstName = setting.value;
            break;
          case 'user_last_name':
            newSettings.profile.lastName = setting.value;
            break;
          case 'user_email':
            newSettings.profile.email = setting.value;
            break;
          case 'user_phone':
            newSettings.profile.phone = setting.value;
            break;
        }
      });
      
      // Mettre à jour le profil avec les données de l'utilisateur connecté si pas encore défini
      if (currentUser) {
        if (!newSettings.profile.firstName || newSettings.profile.firstName === 'Utilisateur') {
          newSettings.profile.firstName = currentUser.firstName;
        }
        if (!newSettings.profile.lastName || newSettings.profile.lastName === 'Test') {
          newSettings.profile.lastName = currentUser.lastName;
        }
        if (!newSettings.profile.email || newSettings.profile.email === 'user@example.com') {
          newSettings.profile.email = currentUser.email;
        }
      }
      
      setSettings(newSettings);
    }
  }, [systemSettings, currentUser]);

  const showMessage = (text: string, type: 'success' | 'error' | 'info') => {
    setMessage({ text, type });
    setTimeout(() => setMessage(null), 3000);
  };

  const saveSettingsData = async () => {
    setLoading(true);
    try {
      // Préparer les paramètres à sauvegarder
      const settingsToUpdate = [
        // Paramètres de l'atelier
        { key: 'workshop_name', value: settings.workshop.name },
        { key: 'workshop_address', value: settings.workshop.address },
        { key: 'workshop_phone', value: settings.workshop.phone },
        { key: 'workshop_email', value: settings.workshop.email },
        { key: 'workshop_siret', value: settings.workshop.siret },
        { key: 'workshop_vat_number', value: settings.workshop.vatNumber },
        { key: 'vat_rate', value: settings.workshop.vatRate },
        { key: 'currency', value: settings.workshop.currency },
        
        // Paramètres des préférences
        { key: 'language', value: settings.preferences.language },
        
        // Paramètres du profil utilisateur
        { key: 'user_first_name', value: settings.profile.firstName },
        { key: 'user_last_name', value: settings.profile.lastName },
        { key: 'user_email', value: settings.profile.email },
        { key: 'user_phone', value: settings.profile.phone }
      ];

      // Sauvegarder dans la base de données
      await updateMultipleSystemSettings(settingsToUpdate);
      
      // Mettre à jour les paramètres de l'atelier via le hook (maintenant avec isolation)
      if (settings.workshop) {
        await saveSettings(settings.workshop);
      }
      
      showMessage('Paramètres sauvegardés avec succès !', 'success');
    } catch (error) {
      console.error('Erreur lors de la sauvegarde:', error);
      showMessage('Erreur lors de la sauvegarde', 'error');
    } finally {
      setLoading(false);
    }
  };

  const changePassword = async () => {
    const password = (document.getElementById('newPassword') as HTMLInputElement)?.value;
    const confirmPassword = (document.getElementById('confirmPassword') as HTMLInputElement)?.value;
    
    if (!password || !confirmPassword) {
      showMessage('Veuillez remplir tous les champs', 'error');
      return;
    }

    if (!passwordMatch.match) {
      showMessage('Les mots de passe ne correspondent pas', 'error');
      return;
    }
    
    if (passwordStrength.score < 3) {
      showMessage('Le mot de passe est trop faible. Veuillez choisir un mot de passe plus sécurisé.', 'error');
      return;
    }
    
    setLoading(true);
    try {
      // Utiliser l'API Supabase pour changer le mot de passe
      const { error } = await supabase.auth.updateUser({
        password: password
      });
      
      if (error) {
        throw error;
      }
      
      showMessage('Mot de passe modifié avec succès !', 'success');
      
      // Vider les champs et réinitialiser les états
      (document.getElementById('newPassword') as HTMLInputElement).value = '';
      (document.getElementById('confirmPassword') as HTMLInputElement).value = '';
      setPasswordStrength({ score: 0, feedback: '', color: '#666' });
      setPasswordMatch({ match: false, message: '', color: '#666' });
    } catch (error: any) {
      console.error('Erreur lors de la modification du mot de passe:', error);
      showMessage(error?.message || 'Erreur lors de la modification du mot de passe', 'error');
    } finally {
      setLoading(false);
    }
  };

  const togglePasswordVisibility = (fieldId: string) => {
    const field = document.getElementById(fieldId) as HTMLInputElement;
    if (field) {
      field.type = field.type === 'password' ? 'text' : 'password';
    }
  };

  const evaluatePasswordStrength = (password: string) => {
    let score = 0;
    let feedback = '';
    
    if (password.length >= 6) score += 1;
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (/[a-z]/.test(password)) score += 1;
    if (/[A-Z]/.test(password)) score += 1;
    if (/[0-9]/.test(password)) score += 1;
    if (/[^A-Za-z0-9]/.test(password)) score += 1;
    
    let color = '#666';
    if (score <= 2) {
      feedback = 'Très faible';
      color = '#dc3545';
    } else if (score <= 4) {
      feedback = 'Faible';
      color = '#fd7e14';
    } else if (score <= 6) {
      feedback = 'Moyen';
      color = '#ffc107';
    } else {
      feedback = 'Fort';
      color = '#28a745';
    }
    
    return { score, feedback, color };
  };

  const handlePasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const password = event.target.value;
    const strength = evaluatePasswordStrength(password);
    setPasswordStrength(strength);
    
    // Vérifier si les mots de passe correspondent
    const confirmPassword = (document.getElementById('confirmPassword') as HTMLInputElement)?.value;
    if (confirmPassword) {
      checkPasswordMatch(password, confirmPassword);
    }
  };

  const handleConfirmPasswordChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const confirmPassword = event.target.value;
    const password = (document.getElementById('newPassword') as HTMLInputElement)?.value;
    if (password) {
      checkPasswordMatch(password, confirmPassword);
    }
  };

  const checkPasswordMatch = (password: string, confirmPassword: string) => {
    if (!password || !confirmPassword) {
      setPasswordMatch({ match: false, message: '', color: '#666' });
      return;
    }
    
    if (password === confirmPassword) {
      setPasswordMatch({ 
        match: true, 
        message: '✅ Les mots de passe correspondent', 
        color: '#28a745' 
      });
    } else {
      setPasswordMatch({ 
        match: false, 
        message: '❌ Les mots de passe ne correspondent pas', 
        color: '#dc3545' 
      });
    }
  };

  const tabs = [
    { label: 'Profil', content: 'profile' },

    { label: 'Sécurité', content: 'security' },
    { label: 'Atelier', content: 'atelier' }
  ];

  return (
    <div style={{
      fontFamily: theme.typography.fontFamily,
      maxWidth: '1000px',
      margin: '0 auto',
      padding: '24px',
      backgroundColor: theme.palette.background.default,
      minHeight: '100vh'
    }}>
      <div style={{
        backgroundColor: theme.palette.background.paper,
        borderRadius: theme.shape.borderRadius,
        boxShadow: theme.shadows[3],
        overflow: 'hidden',
        border: `1px solid ${theme.palette.divider}`
      }}>
      {/* En-tête */}
        <div style={{
          padding: '32px',
          borderBottom: `1px solid ${theme.palette.divider}`,
          background: `linear-gradient(135deg, ${theme.palette.primary.main} 0%, ${theme.palette.primary.dark} 100%)`,
          color: theme.palette.primary.contrastText
        }}>
          <h1 style={{
            margin: '0 0 12px 0',
            fontSize: theme.typography.h3.fontSize,
            fontWeight: theme.typography.h3.fontWeight,
            color: theme.palette.primary.contrastText,
            letterSpacing: theme.typography.h3.letterSpacing
          }}>
            ⚙️ Paramètres
          </h1>
          <p style={{
            margin: '0',
            color: 'rgba(255, 255, 255, 0.8)',
            fontSize: theme.typography.body1.fontSize,
            lineHeight: theme.typography.body1.lineHeight
          }}>
            Gérez vos préférences et les informations de votre atelier
          </p>
        </div>

        {/* Onglets */}
        <div style={{
          display: 'flex',
          borderBottom: `1px solid ${theme.palette.divider}`,
          backgroundColor: theme.palette.background.paper,
          padding: '0 8px'
        }}>
          {tabs.map((tab, index) => (
            <button
              key={tab.content}
              onClick={() => setActiveTab(index)}
              style={{
                flex: '1',
                padding: '20px 16px',
                border: 'none',
                backgroundColor: activeTab === index ? theme.palette.primary.main : 'transparent',
                color: activeTab === index ? theme.palette.primary.contrastText : theme.palette.text.secondary,
                cursor: 'pointer',
                fontSize: theme.typography.body2.fontSize,
                fontWeight: activeTab === index ? theme.typography.button.fontWeight : '400',
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                borderRadius: `${theme.shape.borderRadius}px ${theme.shape.borderRadius}px 0 0`,
                margin: '8px 4px 0 4px',
                position: 'relative',
              }}
              onMouseEnter={(e) => {
                if (activeTab !== index) {
                  e.currentTarget.style.backgroundColor = 'rgba(55, 65, 81, 0.08)';
                  e.currentTarget.style.transform = 'translateY(-2px)';
                }
              }}
              onMouseLeave={(e) => {
                if (activeTab !== index) {
                  e.currentTarget.style.backgroundColor = 'transparent';
                  e.currentTarget.style.transform = 'translateY(0)';
                }
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Message de notification */}
        {message && (
          <div style={{
            padding: '16px 24px',
            backgroundColor: message.type === 'success' ? theme.palette.success.light + '20' : 
                           message.type === 'error' ? theme.palette.error.light + '20' : theme.palette.info.light + '20',
            color: message.type === 'success' ? theme.palette.success.dark : 
                   message.type === 'error' ? theme.palette.error.dark : theme.palette.info.dark,
            border: `1px solid ${message.type === 'success' ? theme.palette.success.main : 
                                message.type === 'error' ? theme.palette.error.main : theme.palette.info.main}`,
            borderRadius: theme.shape.borderRadius,
            margin: '20px 24px',
            fontSize: theme.typography.body2.fontSize,
            fontWeight: theme.typography.body2.fontWeight,
            boxShadow: theme.shadows[1],
            display: 'flex',
            alignItems: 'center',
            gap: '12px'
          }}>
            <span style={{ fontSize: '18px' }}>
              {message.type === 'success' ? '✅' : message.type === 'error' ? '❌' : 'ℹ️'}
            </span>
            {message.text}
          </div>
        )}

        {/* Contenu des onglets */}
        <div style={{ padding: '32px' }}>
          {activeTab === 0 && (
            <div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                marginBottom: '28px',
                padding: '20px',
                backgroundColor: 'rgba(55, 65, 81, 0.05)',
                borderRadius: theme.shape.borderRadius,
                border: `1px solid ${theme.palette.divider}`
              }}>
                <div style={{
                  width: '48px',
                  height: '48px',
                  borderRadius: '50%',
                  backgroundColor: theme.palette.primary.main,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginRight: '16px',
                  fontSize: '20px'
                }}>
                  👤
                </div>
                <div>
                  <h2 style={{ 
                    margin: '0 0 4px 0', 
                    fontSize: theme.typography.h5.fontSize, 
                    fontWeight: theme.typography.h5.fontWeight, 
                    color: theme.palette.text.primary 
                  }}>
                    Informations personnelles
                  </h2>
                  <p style={{
                    margin: '0',
                    color: theme.palette.text.secondary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Gérez vos informations de profil et vos coordonnées
                  </p>
                </div>
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '24px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Prénom
                  </label>
                  <input
                    type="text"
                    value={settings.profile.firstName}
                    placeholder="Ex: Jean"
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      profile: { ...prev.profile, firstName: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out',
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Nom
                  </label>
                  <input
                    type="text"
                    value={settings.profile.lastName}
                    placeholder="Ex: Dupont"
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      profile: { ...prev.profile, lastName: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
              </div>
              
              <div style={{ marginBottom: '24px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '8px', 
                  fontWeight: theme.typography.button.fontWeight,
                  color: theme.palette.text.primary,
                  fontSize: theme.typography.body2.fontSize
                }}>
                  Email
                </label>
                <input
                  type="email"
                  value={settings.profile.email}
                  placeholder="Ex: jean.dupont@email.com"
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    profile: { ...prev.profile, email: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: `2px solid ${theme.palette.divider}`,
                    borderRadius: theme.shape.borderRadius,
                    fontSize: theme.typography.body1.fontSize,
                    boxSizing: 'border-box',
                    backgroundColor: theme.palette.background.paper,
                    color: theme.palette.text.primary,
                    transition: 'all 0.2s ease-in-out'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = theme.palette.primary.main;
                    e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = theme.palette.divider;
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '24px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '8px', 
                  fontWeight: theme.typography.button.fontWeight,
                  color: theme.palette.text.primary,
                  fontSize: theme.typography.body2.fontSize
                }}>
                  Téléphone
                </label>
                <input
                  type="tel"
                  value={settings.profile.phone}
                  placeholder="Ex: 06 12 34 56 78"
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    profile: { ...prev.profile, phone: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: `2px solid ${theme.palette.divider}`,
                    borderRadius: theme.shape.borderRadius,
                    fontSize: theme.typography.body1.fontSize,
                    boxSizing: 'border-box',
                    backgroundColor: theme.palette.background.paper,
                    color: theme.palette.text.primary,
                    transition: 'all 0.2s ease-in-out'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = theme.palette.primary.main;
                    e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = theme.palette.divider;
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>
            </div>
          )}



          {activeTab === 1 && (
            <div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                marginBottom: '28px',
                padding: '20px',
                backgroundColor: 'rgba(239, 68, 68, 0.05)',
                borderRadius: theme.shape.borderRadius,
                border: `1px solid ${theme.palette.divider}`
              }}>
                <div style={{
                  width: '48px',
                  height: '48px',
                  borderRadius: '50%',
                  backgroundColor: theme.palette.error.main,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginRight: '16px',
                  fontSize: '20px'
                }}>
                  🔒
                </div>
                <div>
                  <h2 style={{ 
                    margin: '0 0 4px 0', 
                    fontSize: theme.typography.h5.fontSize, 
                    fontWeight: theme.typography.h5.fontWeight, 
                    color: theme.palette.text.primary 
                  }}>
                    Sécurité du compte
                  </h2>
                  <p style={{
                    margin: '0',
                    color: theme.palette.text.secondary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Gérez votre mot de passe et les paramètres de sécurité
                  </p>
                </div>
              </div>
              
              
              <div style={{ 
                padding: '24px', 
                backgroundColor: theme.palette.background.default, 
                borderRadius: theme.shape.borderRadius,
                marginBottom: '24px',
                border: `1px solid ${theme.palette.divider}`,
                boxShadow: theme.shadows[1]
              }}>
                <h3 style={{ 
                  margin: '0 0 20px 0', 
                  fontSize: theme.typography.h6.fontSize, 
                  fontWeight: theme.typography.h6.fontWeight, 
                  color: theme.palette.text.primary,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px'
                }}>
                  🔐 Changer le mot de passe
                </h3>
                
                <div style={{ marginBottom: '16px' }}>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Nouveau mot de passe
                  </label>
                  <div style={{ position: 'relative' }}>
                    <input
                      id="newPassword"
                      type="password"
                      placeholder="Entrez votre nouveau mot de passe"
                      onChange={handlePasswordChange}
                      style={{
                        width: '100%',
                        padding: '12px 40px 12px 12px',
                        border: '1px solid #ddd',
                        borderRadius: '6px',
                        fontSize: '14px',
                        boxSizing: 'border-box'
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => togglePasswordVisibility('newPassword')}
                      style={{
                        position: 'absolute',
                        right: '8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        fontSize: '16px',
                        color: '#666'
                      }}
                    >
                      👁️
                    </button>
                  </div>
                  
                  {/* Indicateur de force du mot de passe */}
                  {(document.getElementById('newPassword') as HTMLInputElement)?.value && (
                    <div style={{ marginTop: '8px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', marginBottom: '4px' }}>
                        <span style={{ 
                          fontSize: '12px', 
                          color: '#666', 
                          marginRight: '8px' 
                        }}>
                          Force du mot de passe:
                        </span>
                        <span style={{ 
                          fontSize: '12px', 
                          fontWeight: '600',
                          color: passwordStrength.color 
                        }}>
                          {passwordStrength.feedback}
                        </span>
                      </div>
                      <div style={{ 
                        width: '100%', 
                        height: '4px', 
                        backgroundColor: '#e9ecef', 
                        borderRadius: '2px',
                        overflow: 'hidden'
                      }}>
                        <div style={{ 
                          width: `${(passwordStrength.score / 7) * 100}%`, 
                          height: '100%', 
                          backgroundColor: passwordStrength.color, 
                          borderRadius: '2px',
                          transition: 'all 0.3s ease'
                        }}></div>
                      </div>
                    </div>
                  )}
                </div>
                
                <div style={{ marginBottom: '16px' }}>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Confirmer le mot de passe
                  </label>
                  <div style={{ position: 'relative' }}>
                    <input
                      id="confirmPassword"
                      type="password"
                      placeholder="Confirmez votre nouveau mot de passe"
                      onChange={handleConfirmPasswordChange}
                      style={{
                        width: '100%',
                        padding: '12px 40px 12px 12px',
                        border: '1px solid #ddd',
                        borderRadius: '6px',
                        fontSize: '14px',
                        boxSizing: 'border-box'
                      }}
                    />
                    <button
                      type="button"
                      onClick={() => togglePasswordVisibility('confirmPassword')}
                      style={{
                        position: 'absolute',
                        right: '8px',
                        top: '50%',
                        transform: 'translateY(-50%)',
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        fontSize: '16px',
                        color: '#666'
                      }}
                    >
                      👁️
                    </button>
                  </div>
                  
                  {/* Indicateur de correspondance des mots de passe */}
                  {passwordMatch.message && (
                    <div style={{ marginTop: '8px' }}>
                      <span style={{ 
                        fontSize: '12px', 
                        fontWeight: '500',
                        color: passwordMatch.color 
                      }}>
                        {passwordMatch.message}
                      </span>
                    </div>
                  )}
                </div>
                
                <div style={{ 
                  backgroundColor: '#e3f2fd', 
                  border: '1px solid #bbdefb', 
                  borderRadius: '6px', 
                  padding: '12px', 
                  marginBottom: '16px' 
                }}>
                  <h4 style={{ 
                    margin: '0 0 8px 0', 
                    fontSize: '14px', 
                    fontWeight: '600', 
                    color: '#1976d2',
                    display: 'flex',
                    alignItems: 'center'
                  }}>
                    🔒 Exigences de sécurité
                  </h4>
                  <ul style={{ 
                    margin: '0', 
                    paddingLeft: '20px', 
                    fontSize: '13px', 
                    color: '#1976d2',
                    lineHeight: '1.4'
                  }}>
                    <li>Au moins 6 caractères</li>
                    <li>Utilisez des lettres, chiffres et symboles</li>
                    <li>Évitez les mots de passe courants</li>
                  </ul>
                </div>
                
                <button
                  onClick={changePassword}
                  disabled={loading || !passwordMatch.match || passwordStrength.score < 3}
                  style={{
                    backgroundColor: passwordMatch.match && passwordStrength.score >= 3 ? '#007bff' : '#6c757d',
                    color: 'white',
                    border: 'none',
                    padding: '12px 24px',
                    borderRadius: '6px',
                    cursor: (loading || !passwordMatch.match || passwordStrength.score < 3) ? 'not-allowed' : 'pointer',
                    fontSize: '14px',
                    fontWeight: '600',
                    opacity: (loading || !passwordMatch.match || passwordStrength.score < 3) ? 0.6 : 1,
                    transition: 'all 0.2s ease',
                    width: '100%'
                  }}
                >
                  {loading ? '🔄 Modification en cours...' : '🔐 Modifier le mot de passe'}
                </button>
              </div>
            </div>
          )}

          {activeTab === 2 && (
            <div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                marginBottom: '28px',
                padding: '20px',
                backgroundColor: 'rgba(16, 185, 129, 0.05)',
                borderRadius: theme.shape.borderRadius,
                border: `1px solid ${theme.palette.divider}`
              }}>
                <div style={{
                  width: '48px',
                  height: '48px',
                  borderRadius: '50%',
                  backgroundColor: theme.palette.success.main,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginRight: '16px',
                  fontSize: '20px'
                }}>
                  🏢
                </div>
                <div>
                  <h2 style={{ 
                    margin: '0 0 4px 0', 
                    fontSize: theme.typography.h5.fontSize, 
                    fontWeight: theme.typography.h5.fontWeight, 
                    color: theme.palette.text.primary 
                  }}>
                    Informations de l'atelier
                  </h2>
                  <p style={{
                    margin: '0',
                    color: theme.palette.text.secondary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Configurez les informations de votre atelier et vos paramètres commerciaux
                  </p>
                </div>
              </div>
              
              <div style={{ marginBottom: '24px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '8px', 
                  fontWeight: theme.typography.button.fontWeight,
                  color: theme.palette.text.primary,
                  fontSize: theme.typography.body2.fontSize
                }}>
                  Nom de l'atelier
                </label>
                <input
                  type="text"
                  value={settings.workshop.name}
                  placeholder="Ex: Atelier de réparation automobile"
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    workshop: { ...prev.workshop, name: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: `2px solid ${theme.palette.divider}`,
                    borderRadius: theme.shape.borderRadius,
                    fontSize: theme.typography.body1.fontSize,
                    boxSizing: 'border-box',
                    backgroundColor: theme.palette.background.paper,
                    color: theme.palette.text.primary,
                    transition: 'all 0.2s ease-in-out'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = theme.palette.primary.main;
                    e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = theme.palette.divider;
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '24px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '8px', 
                  fontWeight: theme.typography.button.fontWeight,
                  color: theme.palette.text.primary,
                  fontSize: theme.typography.body2.fontSize
                }}>
                  Adresse
                </label>
                <input
                  type="text"
                  value={settings.workshop.address}
                  placeholder="Ex: 123 Rue de la Paix, 75001 Paris"
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    workshop: { ...prev.workshop, address: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '12px 16px',
                    border: `2px solid ${theme.palette.divider}`,
                    borderRadius: theme.shape.borderRadius,
                    fontSize: theme.typography.body1.fontSize,
                    boxSizing: 'border-box',
                    backgroundColor: theme.palette.background.paper,
                    color: theme.palette.text.primary,
                    transition: 'all 0.2s ease-in-out'
                  }}
                  onFocus={(e) => {
                    e.target.style.borderColor = theme.palette.primary.main;
                    e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                  }}
                  onBlur={(e) => {
                    e.target.style.borderColor = theme.palette.divider;
                    e.target.style.boxShadow = 'none';
                  }}
                />
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '24px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Téléphone
                  </label>
                  <input
                    type="tel"
                    value={settings.workshop.phone}
                    placeholder="Ex: 01 23 45 67 89"
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, phone: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Email
                  </label>
                  <input
                    type="email"
                    value={settings.workshop.email}
                    placeholder="Ex: contact@atelier.fr"
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, email: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '24px', marginBottom: '24px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    SIRET
                  </label>
                  <input
                    type="text"
                    value={settings.workshop.siret}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, siret: e.target.value }
                    }))}
                    placeholder="123 456 789 00012"
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Numéro de TVA
                  </label>
                  <input
                    type="text"
                    value={settings.workshop.vatNumber}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, vatNumber: e.target.value }
                    }))}
                    placeholder="FR12345678901"
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Taux de TVA (%)
                  </label>
                  <input
                    type="number"
                    value={settings.workshop.vatRate}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, vatRate: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  />
                </div>
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '24px', marginBottom: '24px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '8px', 
                    fontWeight: theme.typography.button.fontWeight,
                    color: theme.palette.text.primary,
                    fontSize: theme.typography.body2.fontSize
                  }}>
                    Devise
                  </label>
                  <select
                    value={settings.workshop.currency}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, currency: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '12px 16px',
                      border: `2px solid ${theme.palette.divider}`,
                      borderRadius: theme.shape.borderRadius,
                      fontSize: theme.typography.body1.fontSize,
                      boxSizing: 'border-box',
                      backgroundColor: theme.palette.background.paper,
                      color: theme.palette.text.primary,
                      transition: 'all 0.2s ease-in-out',
                      cursor: 'pointer'
                    }}
                    onFocus={(e) => {
                      e.target.style.borderColor = theme.palette.primary.main;
                      e.target.style.boxShadow = `0 0 0 3px ${theme.palette.primary.main}20`;
                    }}
                    onBlur={(e) => {
                      e.target.style.borderColor = theme.palette.divider;
                      e.target.style.boxShadow = 'none';
                    }}
                  >
                    <option value="EUR">EUR (€)</option>
                    <option value="USD">USD ($)</option>
                    <option value="GBP">GBP (£)</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          {/* Bouton de sauvegarde */}
          <div style={{
            marginTop: '40px',
            paddingTop: '24px',
            borderTop: `1px solid ${theme.palette.divider}`,
            textAlign: 'right'
          }}>
            <button
              onClick={saveSettingsData}
              disabled={loading}
              style={{
                backgroundColor: loading ? theme.palette.secondary.main : theme.palette.success.main,
                color: theme.palette.success.contrastText || 'white',
                border: 'none',
                padding: '14px 32px',
                borderRadius: theme.shape.borderRadius,
                cursor: loading ? 'not-allowed' : 'pointer',
                fontSize: theme.typography.button.fontSize,
                fontWeight: theme.typography.button.fontWeight,
                opacity: loading ? 0.7 : 1,
                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                boxShadow: theme.shadows[2],
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                marginLeft: 'auto',
                minWidth: '200px',
                justifyContent: 'center'
              }}
              onMouseEnter={(e) => {
                if (!loading) {
                  e.currentTarget.style.transform = 'translateY(-2px)';
                  e.currentTarget.style.boxShadow = theme.shadows[4];
                }
              }}
              onMouseLeave={(e) => {
                if (!loading) {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = theme.shadows[2];
                }
              }}
            >
              <span style={{ fontSize: '16px' }}>
                {loading ? '🔄' : '💾'}
              </span>
              {loading ? 'Sauvegarde...' : 'Sauvegarder les paramètres'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
