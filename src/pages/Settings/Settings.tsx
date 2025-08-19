import React, { useState, useEffect } from 'react';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';

interface SettingsData {
  profile: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
  };
  preferences: {
    notificationsEmail: boolean;
    notificationsPush: boolean;
    notificationsSms: boolean;
    themeDarkMode: boolean;
    language: string;
    twoFactorAuth: boolean;
  };
  workshop: {
    name: string;
    address: string;
    phone: string;
    email: string;
    vatRate: string;
    currency: string;
  };
}

const Settings: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' | 'info' } | null>(null);
  
  const [settings, setSettings] = useState<SettingsData>({
    profile: {
      firstName: 'Utilisateur',
      lastName: 'Test',
      email: 'user@example.com',
      phone: '01 23 45 67 89'
    },
    preferences: {
      notificationsEmail: true,
      notificationsPush: true,
      notificationsSms: false,
      themeDarkMode: false,
    language: 'fr',
      twoFactorAuth: false
    },
    workshop: {
      name: 'Atelier de réparation',
      address: '123 Rue de la Paix, 75001 Paris',
      phone: '01 23 45 67 89',
      email: 'contact@atelier.fr',
      vatRate: '20',
      currency: 'EUR'
    }
  });

  const { saveSettings } = useWorkshopSettings();

  // Charger les paramètres depuis localStorage
  useEffect(() => {
    const savedSettings = localStorage.getItem('atelier-settings');
    if (savedSettings) {
      try {
        const parsed = JSON.parse(savedSettings);
        setSettings(parsed);
      } catch (error) {
        console.log('Erreur lors du chargement des paramètres');
      }
    }
  }, []);

  const showMessage = (text: string, type: 'success' | 'error' | 'info') => {
    setMessage({ text, type });
    setTimeout(() => setMessage(null), 3000);
  };

  const saveSettingsData = async () => {
    setLoading(true);
    try {
      // Sauvegarder dans localStorage
      localStorage.setItem('atelier-settings', JSON.stringify(settings));
      
      // Mettre à jour les paramètres de l'atelier via le hook
      if (settings.workshop) {
        saveSettings(settings.workshop);
      }
      
      showMessage('Paramètres sauvegardés avec succès !', 'success');
    } catch (error) {
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

    if (password !== confirmPassword) {
      showMessage('Les mots de passe ne correspondent pas', 'error');
      return;
    }
    
    if (password.length < 6) {
      showMessage('Le mot de passe doit contenir au moins 6 caractères', 'error');
      return;
    }
    
    setLoading(true);
    try {
      // Simuler une sauvegarde asynchrone
      await new Promise(resolve => setTimeout(resolve, 1000));
      showMessage('Mot de passe modifié avec succès !', 'success');
      
      // Vider les champs
      (document.getElementById('newPassword') as HTMLInputElement).value = '';
      (document.getElementById('confirmPassword') as HTMLInputElement).value = '';
    } catch (error) {
      showMessage('Erreur lors de la modification du mot de passe', 'error');
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

  const tabs = [
    { label: 'Profil', content: 'profile' },
    { label: 'Notifications', content: 'notifications' },
    { label: 'Sécurité', content: 'security' },
    { label: 'Atelier', content: 'atelier' }
  ];

  return (
    <div style={{
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      maxWidth: '800px',
      margin: '0 auto',
      padding: '20px',
      backgroundColor: '#f8f9fa',
      minHeight: '100vh'
    }}>
      <div style={{
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
      {/* En-tête */}
        <div style={{
          padding: '24px',
          borderBottom: '1px solid #e9ecef',
          backgroundColor: '#f8f9fa'
        }}>
          <h1 style={{
            margin: '0 0 8px 0',
            fontSize: '24px',
            fontWeight: '600',
            color: '#333'
          }}>
            Paramètres
          </h1>
          <p style={{
            margin: '0',
            color: '#666',
            fontSize: '14px'
          }}>
            Gérez vos préférences et les informations de votre atelier
          </p>
        </div>

        {/* Onglets */}
        <div style={{
          display: 'flex',
          borderBottom: '1px solid #e9ecef',
          backgroundColor: 'white'
        }}>
          {tabs.map((tab, index) => (
            <button
              key={tab.content}
              onClick={() => setActiveTab(index)}
              style={{
                flex: '1',
                padding: '16px',
                border: 'none',
                backgroundColor: activeTab === index ? '#007bff' : 'transparent',
                color: activeTab === index ? 'white' : '#666',
                cursor: 'pointer',
                fontSize: '14px',
                fontWeight: activeTab === index ? '600' : '400',
                transition: 'all 0.2s ease'
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Message de notification */}
        {message && (
          <div style={{
            padding: '12px 24px',
            backgroundColor: message.type === 'success' ? '#d4edda' : 
                           message.type === 'error' ? '#f8d7da' : '#d1ecf1',
            color: message.type === 'success' ? '#155724' : 
                   message.type === 'error' ? '#721c24' : '#0c5460',
            border: `1px solid ${message.type === 'success' ? '#c3e6cb' : 
                                message.type === 'error' ? '#f5c6cb' : '#bee5eb'}`,
            borderRadius: '4px',
            margin: '16px 24px',
            fontSize: '14px'
          }}>
            {message.text}
          </div>
        )}

        {/* Contenu des onglets */}
        <div style={{ padding: '24px' }}>
          {activeTab === 0 && (
            <div>
              <h2 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '600', color: '#333' }}>
                Informations personnelles
              </h2>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Prénom
                  </label>
                  <input
                    type="text"
                    value={settings.profile.firstName}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      profile: { ...prev.profile, firstName: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Nom
                  </label>
                  <input
                    type="text"
                    value={settings.profile.lastName}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      profile: { ...prev.profile, lastName: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '6px', 
                  fontWeight: '500',
                  color: '#333',
                  fontSize: '14px'
                }}>
                  Email
                </label>
                <input
                  type="email"
                  value={settings.profile.email}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    profile: { ...prev.profile, email: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '6px', 
                  fontWeight: '500',
                  color: '#333',
                  fontSize: '14px'
                }}>
                  Téléphone
                </label>
                <input
                  type="tel"
                  value={settings.profile.phone}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    profile: { ...prev.profile, phone: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
            </div>
          )}

          {activeTab === 1 && (
            <div>
              <h2 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '600', color: '#333' }}>
                Préférences de notifications
              </h2>
              
              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  cursor: 'pointer',
                  fontSize: '14px',
                  color: '#333'
                }}>
                  <input
                    type="checkbox"
                    checked={settings.preferences.notificationsEmail}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      preferences: { ...prev.preferences, notificationsEmail: e.target.checked }
                    }))}
                    style={{ marginRight: '8px' }}
                  />
                  Notifications par email
                </label>
              </div>
              
              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  cursor: 'pointer',
                  fontSize: '14px',
                  color: '#333'
                }}>
                  <input
                    type="checkbox"
                    checked={settings.preferences.notificationsPush}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      preferences: { ...prev.preferences, notificationsPush: e.target.checked }
                    }))}
                    style={{ marginRight: '8px' }}
                  />
                  Notifications push
                </label>
              </div>
              
              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  cursor: 'pointer',
                  fontSize: '14px',
                  color: '#333'
                }}>
                  <input
                    type="checkbox"
                    checked={settings.preferences.notificationsSms}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      preferences: { ...prev.preferences, notificationsSms: e.target.checked }
                    }))}
                    style={{ marginRight: '8px' }}
                  />
                  Notifications par SMS
                </label>
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '6px', 
                  fontWeight: '500',
                  color: '#333',
                  fontSize: '14px'
                }}>
                  Langue
                </label>
                <select
                  value={settings.preferences.language}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    preferences: { ...prev.preferences, language: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px',
                    boxSizing: 'border-box'
                  }}
                >
                  <option value="fr">Français</option>
                  <option value="en">English</option>
                  <option value="es">Español</option>
                </select>
              </div>
            </div>
          )}

          {activeTab === 2 && (
            <div>
              <h2 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '600', color: '#333' }}>
                Sécurité
              </h2>
              
              <div style={{ marginBottom: '16px' }}>
                <label style={{ 
                  display: 'flex', 
                  alignItems: 'center', 
                  cursor: 'pointer',
                  fontSize: '14px',
                  color: '#333'
                }}>
                  <input
                    type="checkbox"
                    checked={settings.preferences.twoFactorAuth}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      preferences: { ...prev.preferences, twoFactorAuth: e.target.checked }
                    }))}
                    style={{ marginRight: '8px' }}
                  />
                  Authentification à deux facteurs
                </label>
              </div>
              
              <div style={{ 
                padding: '16px', 
                backgroundColor: '#f8f9fa', 
                borderRadius: '4px',
                marginBottom: '20px'
              }}>
                <h3 style={{ margin: '0 0 12px 0', fontSize: '16px', fontWeight: '600', color: '#333' }}>
                  Changer le mot de passe
                </h3>
                
                <div style={{ marginBottom: '12px' }}>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Nouveau mot de passe
                  </label>
                  <input
                    id="newPassword"
                    type="password"
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
                
                <div style={{ marginBottom: '12px' }}>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Confirmer le mot de passe
                  </label>
                  <input
                    id="confirmPassword"
                    type="password"
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
                
                <button
                  onClick={changePassword}
                  disabled={loading}
                  style={{
                    backgroundColor: '#007bff',
                    color: 'white',
                    border: 'none',
                    padding: '10px 20px',
                    borderRadius: '4px',
                    cursor: loading ? 'not-allowed' : 'pointer',
                    fontSize: '14px',
                    opacity: loading ? 0.6 : 1
                  }}
                >
                  {loading ? 'Modification...' : 'Modifier le mot de passe'}
                </button>
              </div>
            </div>
          )}

          {activeTab === 3 && (
            <div>
              <h2 style={{ margin: '0 0 20px 0', fontSize: '18px', fontWeight: '600', color: '#333' }}>
                Informations de l'atelier
              </h2>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '6px', 
                  fontWeight: '500',
                  color: '#333',
                  fontSize: '14px'
                }}>
                  Nom de l'atelier
                </label>
                <input
                  type="text"
                  value={settings.workshop.name}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    workshop: { ...prev.workshop, name: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{ marginBottom: '20px' }}>
                <label style={{ 
                  display: 'block', 
                  marginBottom: '6px', 
                  fontWeight: '500',
                  color: '#333',
                  fontSize: '14px'
                }}>
                  Adresse
                </label>
                <input
                  type="text"
                  value={settings.workshop.address}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    workshop: { ...prev.workshop, address: e.target.value }
                  }))}
                  style={{
                    width: '100%',
                    padding: '10px',
                    border: '1px solid #ddd',
                    borderRadius: '4px',
                    fontSize: '14px',
                    boxSizing: 'border-box'
                  }}
                />
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Téléphone
                  </label>
                  <input
                    type="tel"
                    value={settings.workshop.phone}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, phone: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
                  }}>
                    Email
                  </label>
                  <input
                    type="email"
                    value={settings.workshop.email}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      workshop: { ...prev.workshop, email: e.target.value }
                    }))}
                    style={{
                      width: '100%',
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
              </div>
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
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
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
                    }}
                  />
                </div>
                
                <div>
                  <label style={{ 
                    display: 'block', 
                    marginBottom: '6px', 
                    fontWeight: '500',
                    color: '#333',
                    fontSize: '14px'
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
                      padding: '10px',
                      border: '1px solid #ddd',
                      borderRadius: '4px',
                      fontSize: '14px',
                      boxSizing: 'border-box'
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
            marginTop: '32px',
            paddingTop: '20px',
            borderTop: '1px solid #e9ecef',
            textAlign: 'right'
          }}>
            <button
              onClick={saveSettingsData}
              disabled={loading}
              style={{
                backgroundColor: '#28a745',
                color: 'white',
                border: 'none',
                padding: '12px 24px',
                borderRadius: '4px',
                cursor: loading ? 'not-allowed' : 'pointer',
                fontSize: '14px',
                fontWeight: '600',
                opacity: loading ? 0.6 : 1
              }}
            >
              {loading ? 'Sauvegarde...' : 'Sauvegarder les paramètres'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
