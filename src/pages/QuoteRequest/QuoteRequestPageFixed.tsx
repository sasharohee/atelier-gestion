import React, { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { quoteRequestServiceReal } from '../../services/quoteRequestServiceReal';
import { toast } from 'react-hot-toast';

// Déclarations TypeScript pour les extensions
declare global {
  interface Window {
    __REACT_DEVTOOLS_GLOBAL_HOOK__?: any;
    __REDUX_DEVTOOLS_EXTENSION__?: any;
    __VUE_DEVTOOLS_GLOBAL_HOOK__?: any;
  }
}

const QuoteRequestPageFixed: React.FC = () => {
  const { customUrl } = useParams<{ customUrl: string }>();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [technicianId, setTechnicianId] = useState<string>('');
  const [formData, setFormData] = useState({
    // Informations personnelles
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    vatNumber: '',
    sirenNumber: '',
    
    // Adresse
    address: '',
    addressComplement: '',
    region: '',
    postalCode: '',
    city: '',
    
    // Appareil
    deviceType: '',
    brand: '',
    model: '',
    deviceId: '',
    color: '',
    accessories: '',
    defects: '',
    deviceRemarks: '',
    
    // Urgence
    urgency: 'medium'
  });

  // Désactiver les extensions problématiques au chargement
  useEffect(() => {
    // Désactiver React DevTools
    if (window.__REACT_DEVTOOLS_GLOBAL_HOOK__) {
      window.__REACT_DEVTOOLS_GLOBAL_HOOK__.isDisabled = true;
    }

    // Désactiver Redux DevTools
    if (window.__REDUX_DEVTOOLS_EXTENSION__) {
      window.__REDUX_DEVTOOLS_EXTENSION__ = undefined;
    }

    // Désactiver Vue DevTools
    if (window.__VUE_DEVTOOLS_GLOBAL_HOOK__) {
      window.__VUE_DEVTOOLS_GLOBAL_HOOK__.enabled = false;
    }

    // Supprimer les erreurs d'extension de la console
    const originalError = console.error;
    console.error = (...args) => {
      const message = args[0];
      if (typeof message === 'string' && message.includes('runtime.lastError')) {
        return; // Ignorer les erreurs d'extension
      }
      originalError.apply(console, args);
    };

    console.log('✅ Extensions désactivées - Erreurs d\'extension supprimées');
  }, []);

  // Récupérer l'ID du technicien basé sur l'URL personnalisée
  useEffect(() => {
    const fetchTechnicianId = async () => {
      if (!customUrl) return;
      
      try {
        // Récupérer l'ID du technicien depuis l'URL personnalisée
        const { data: customUrlData, error } = await quoteRequestServiceReal.getCustomUrlByUrl(customUrl);
        
        if (error) {
          console.error('Erreur lors de la récupération de l\'URL personnalisée:', error);
          toast.error('URL personnalisée introuvable');
          return;
        }
        
        if (customUrlData && customUrlData.technician_id) {
          setTechnicianId(customUrlData.technician_id);
          console.log('✅ ID technicien récupéré:', customUrlData.technician_id);
        } else {
          console.error('Aucun technicien trouvé pour cette URL');
          toast.error('URL personnalisée introuvable');
        }
      } catch (error) {
        console.error('Erreur lors de la récupération du technicien:', error);
        toast.error('Erreur lors de la récupération des informations');
      }
    };

    fetchTechnicianId();
  }, [customUrl]);

  const handleInputChange = (field: string, value: string | boolean) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleNext = async () => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    } else {
      // Soumettre le formulaire avec le vrai service
      await handleSubmit();
    }
  };

  const handleSubmit = async () => {
    if (!technicianId || !customUrl) {
      toast.error('Informations manquantes pour soumettre la demande');
      return;
    }

    setIsSubmitting(true);

    try {
      // Créer la demande avec le vrai service
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
        ipAddress: null, // À récupérer côté serveur
        userAgent: navigator.userAgent,
        // Nouveaux champs client
        company: formData.company,
        vatNumber: formData.vatNumber,
        sirenNumber: formData.sirenNumber,
        // Nouveaux champs adresse
        address: formData.address,
        addressComplement: formData.addressComplement,
        city: formData.city,
        postalCode: formData.postalCode,
        region: formData.region,
        // Nouveaux champs appareil
        deviceId: formData.deviceId,
        color: formData.color,
        accessories: formData.accessories,
        deviceRemarks: formData.deviceRemarks,
      };

      const newRequest = await quoteRequestServiceReal.createQuoteRequest(requestData);

      if (!newRequest) {
        throw new Error('Erreur lors de la création de la demande');
      }

      // Afficher le message de succès
      alert('✅ Demande envoyée avec succès !\n\nVotre demande de devis a été transmise au technicien.\nVous recevrez une réponse dans les plus brefs délais.');
      
      // Réinitialiser le formulaire
      setFormData({
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
        urgency: 'medium'
      });
      
      setCurrentStep(1);

    } catch (error) {
      console.error('Erreur lors de l\'envoi:', error);
      toast.error('Une erreur est survenue lors de l\'envoi de votre demande');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePrevious = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };

  const renderStep1 = () => (
    <>
      {/* Informations Personnelles */}
      <div style={{ marginBottom: '30px' }}>
        <h3 style={{
          color: '#1976d2',
          fontSize: '18px',
          marginBottom: '20px',
          fontWeight: '600',
          borderBottom: '2px solid #e0e0e0',
          paddingBottom: '10px'
        }}>
          Détails Client
        </h3>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Prénom *
            </label>
            <input
              type="text"
              required
              value={formData.firstName}
              onChange={(e) => handleInputChange('firstName', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir Prénom"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Nom *
            </label>
            <input
              type="text"
              required
              value={formData.lastName}
              onChange={(e) => handleInputChange('lastName', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir Nom"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Nom Société
            </label>
            <input
              type="text"
              value={formData.company}
              onChange={(e) => handleInputChange('company', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir nom société"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              N° TVA
            </label>
            <input
              type="text"
              value={formData.vatNumber}
              onChange={(e) => handleInputChange('vatNumber', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Veuillez Saisir N° TVA"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              N° SIREN
            </label>
            <input
              type="text"
              value={formData.sirenNumber}
              onChange={(e) => handleInputChange('sirenNumber', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Veuillez Saisir N° SIREN"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Email *
            </label>
            <input
              type="email"
              required
              value={formData.email}
              onChange={(e) => handleInputChange('email', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #d32f2f',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#d32f2f'}
              placeholder="Saisir Email"
            />
          </div>
        </div>
        
        {/* Téléphone */}
        <div style={{ marginTop: '20px' }}>
          <label style={{
            display: 'block',
            marginBottom: '8px',
            fontWeight: '600',
            color: '#333',
            fontSize: '14px'
          }}>
            Mobile (sans le 0) *
          </label>
          <div style={{ display: 'flex', gap: '10px' }}>
            <input
              type="text"
              value="33"
              readOnly
              style={{
                width: '60px',
                padding: '12px',
                border: '1px solid #d32f2f',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                background: '#f5f5f5'
              }}
            />
            <input
              type="tel"
              required
              value={formData.phone}
              onChange={(e) => handleInputChange('phone', e.target.value)}
              style={{
                flex: 1,
                padding: '12px',
                border: '1px solid #d32f2f',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#d32f2f'}
              placeholder="Saisir N° (sans indicatif et sans le 0)"
            />
          </div>
        </div>
        
        {/* Niveau d'urgence */}
        <div style={{ marginTop: '20px' }}>
          <label style={{
            display: 'block',
            marginBottom: '10px',
            fontWeight: '600',
            color: '#333',
            fontSize: '14px'
          }}>
            Niveau d'urgence *
          </label>
          <select
            required
            value={formData.urgency}
            onChange={(e) => handleInputChange('urgency', e.target.value)}
            style={{
              width: '100%',
              padding: '12px',
              border: '1px solid #ddd',
              borderRadius: '6px',
              fontSize: '14px',
              boxSizing: 'border-box',
              outline: 'none',
              transition: 'border-color 0.2s',
              background: 'white'
            }}
            onFocus={(e) => e.target.style.borderColor = '#1976d2'}
            onBlur={(e) => e.target.style.borderColor = '#ddd'}
          >
            <option value="low">🟢 Faible - Réparation non urgente</option>
            <option value="medium">🟡 Moyenne - Réparation dans les 2-3 jours</option>
            <option value="high">🟠 Élevée - Réparation urgente (24h)</option>
            <option value="critical">🔴 Critique - Réparation immédiate</option>
          </select>
        </div>
      </div>
    </>
  );

  const renderStep2 = () => (
    <>
      {/* Détails Adresse */}
      <div style={{ marginBottom: '30px' }}>
        <h3 style={{
          color: '#1976d2',
          fontSize: '18px',
          marginBottom: '20px',
          fontWeight: '600',
          borderBottom: '2px solid #e0e0e0',
          paddingBottom: '10px'
        }}>
          Détails Adresse
        </h3>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          <div style={{ gridColumn: '1 / -1' }}>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Adresse *
            </label>
            <input
              type="text"
              required
              value={formData.address}
              onChange={(e) => handleInputChange('address', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir Adresse"
            />
          </div>
          
          <div style={{ gridColumn: '1 / -1' }}>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Complément Adresse
            </label>
            <input
              type="text"
              value={formData.addressComplement}
              onChange={(e) => handleInputChange('addressComplement', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Complément Adresse"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Région
            </label>
            <input
              type="text"
              value={formData.region}
              onChange={(e) => handleInputChange('region', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir Région"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Code Postal *
            </label>
            <input
              type="text"
              required
              value={formData.postalCode}
              onChange={(e) => handleInputChange('postalCode', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir Code Postal"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Ville *
            </label>
            <input
              type="text"
              required
              value={formData.city}
              onChange={(e) => handleInputChange('city', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir une ville"
            />
          </div>
        </div>
      </div>
    </>
  );

  const renderStep3 = () => (
    <>
      {/* Détails Appareil */}
      <div style={{ marginBottom: '30px' }}>
        <h3 style={{
          color: '#1976d2',
          fontSize: '18px',
          marginBottom: '20px',
          fontWeight: '600',
          borderBottom: '2px solid #e0e0e0',
          paddingBottom: '10px'
        }}>
          Détails Appareil
        </h3>
        
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Type Appareil *
            </label>
            <select
              required
              value={formData.deviceType}
              onChange={(e) => handleInputChange('deviceType', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s',
                background: 'white'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
            >
              <option value="">- Choisir Type -</option>
              <option value="smartphone">📱 Smartphone</option>
              <option value="tablet">📱 Tablette</option>
              <option value="laptop">💻 Ordinateur portable</option>
              <option value="desktop">🖥️ Ordinateur de bureau</option>
              <option value="console">🎮 Console de jeu</option>
              <option value="other">🔧 Autre</option>
            </select>
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Marque *
            </label>
            <input
              type="text"
              required
              value={formData.brand}
              onChange={(e) => handleInputChange('brand', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #d32f2f',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#d32f2f'}
              placeholder="Ex: Apple, Samsung, Sony, HP, Dell..."
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Modèle *
            </label>
            <input
              type="text"
              required
              value={formData.model}
              onChange={(e) => handleInputChange('model', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #d32f2f',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#d32f2f'}
              placeholder="Ex: iPhone 14, Galaxy S23, MacBook Pro, ThinkPad..."
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              ID Appareil
            </label>
            <input
              type="text"
              value={formData.deviceId}
              onChange={(e) => handleInputChange('deviceId', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Saisir IMEI / MAC / N° Série ..."
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Couleur
            </label>
            <input
              type="text"
              value={formData.color}
              onChange={(e) => handleInputChange('color', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="blanc"
            />
          </div>
          
          <div>
            <label style={{
              display: 'block',
              marginBottom: '8px',
              fontWeight: '600',
              color: '#333',
              fontSize: '14px'
            }}>
              Accessoires
            </label>
            <input
              type="text"
              value={formData.accessories}
              onChange={(e) => handleInputChange('accessories', e.target.value)}
              style={{
                width: '100%',
                padding: '12px',
                border: '1px solid #ddd',
                borderRadius: '6px',
                fontSize: '14px',
                boxSizing: 'border-box',
                outline: 'none',
                transition: 'border-color 0.2s'
              }}
              onFocus={(e) => e.target.style.borderColor = '#1976d2'}
              onBlur={(e) => e.target.style.borderColor = '#ddd'}
              placeholder="Chargeur, coque, etc."
            />
          </div>
        </div>
        
        <div style={{ marginTop: '20px' }}>
          <label style={{
            display: 'block',
            marginBottom: '8px',
            fontWeight: '600',
            color: '#333',
            fontSize: '14px'
          }}>
            Défauts *
          </label>
          <textarea
            required
            rows={4}
            value={formData.defects}
            onChange={(e) => handleInputChange('defects', e.target.value)}
            style={{
              width: '100%',
              padding: '12px',
              border: '1px solid #ddd',
              borderRadius: '6px',
              fontSize: '14px',
              boxSizing: 'border-box',
              outline: 'none',
              transition: 'border-color 0.2s',
              resize: 'vertical',
              fontFamily: 'inherit'
            }}
            onFocus={(e) => e.target.style.borderColor = '#1976d2'}
            onBlur={(e) => e.target.style.borderColor = '#ddd'}
            placeholder="Décrivez en détail les défauts de votre appareil..."
          />
        </div>
        
        <div style={{ marginTop: '20px' }}>
          <label style={{
            display: 'block',
            marginBottom: '8px',
            fontWeight: '600',
            color: '#333',
            fontSize: '14px'
          }}>
            Remarques Appareil
          </label>
          <textarea
            rows={3}
            value={formData.deviceRemarks}
            onChange={(e) => handleInputChange('deviceRemarks', e.target.value)}
            style={{
              width: '100%',
              padding: '12px',
              border: '1px solid #ddd',
              borderRadius: '6px',
              fontSize: '14px',
              boxSizing: 'border-box',
              outline: 'none',
              transition: 'border-color 0.2s',
              resize: 'vertical',
              fontFamily: 'inherit'
            }}
            onFocus={(e) => e.target.style.borderColor = '#1976d2'}
            onBlur={(e) => e.target.style.borderColor = '#ddd'}
            placeholder="Saisir constats"
          />
        </div>
      </div>
    </>
  );

  return (
    <div style={{
      minHeight: '100vh',
      background: '#f5f5f5',
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      padding: '20px'
    }}>
      <div style={{
        maxWidth: '800px',
        margin: '0 auto',
        background: 'white',
        borderRadius: '12px',
        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.1)',
        overflow: 'hidden'
      }}>
        {/* Header */}
        <div style={{
          background: 'white',
          padding: '30px 40px 20px 40px',
          textAlign: 'center',
          borderBottom: '1px solid #e0e0e0'
        }}>
          {/* Logo */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '15px',
            marginBottom: '20px'
          }}>
            <div style={{
              width: '50px',
              height: '50px',
              borderRadius: '50%',
              background: '#1976d2',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '20px'
            }}>
              🔧
            </div>
            <div>
              <h1 style={{
                color: '#333',
                fontSize: '24px',
                margin: '0',
                fontWeight: '700'
              }}>
                ATELIER GESTION
              </h1>
              <p style={{
                color: '#666',
                margin: '0',
                fontSize: '14px'
              }}>
                RÉPARATION MULTI MÉDIA
              </p>
            </div>
          </div>
          
          {/* Progress Bar */}
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '20px',
            marginBottom: '20px'
          }}>
            <div style={{
              width: '30px',
              height: '30px',
              borderRadius: '50%',
              background: currentStep >= 1 ? '#1976d2' : '#e0e0e0',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '14px',
              fontWeight: '600'
            }}>
              {currentStep > 1 ? '✓' : '1'}
            </div>
            <div style={{
              width: '60px',
              height: '2px',
              background: currentStep >= 2 ? '#1976d2' : '#e0e0e0'
            }}></div>
            <div style={{
              width: '30px',
              height: '30px',
              borderRadius: '50%',
              background: currentStep >= 2 ? '#1976d2' : '#e0e0e0',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '14px',
              fontWeight: '600'
            }}>
              {currentStep > 2 ? '✓' : '2'}
            </div>
            <div style={{
              width: '60px',
              height: '2px',
              background: currentStep >= 3 ? '#1976d2' : '#e0e0e0'
            }}></div>
            <div style={{
              width: '30px',
              height: '30px',
              borderRadius: '50%',
              background: currentStep >= 3 ? '#1976d2' : '#e0e0e0',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: '14px',
              fontWeight: '600'
            }}>
              {currentStep > 3 ? '✓' : '3'}
            </div>
          </div>
          
          {/* Title */}
          <h2 style={{
            color: '#1976d2',
            fontSize: '24px',
            margin: '0',
            fontWeight: '600'
          }}>
            Demande de devis
          </h2>
        </div>
        
        {/* Form Content */}
        <div style={{
          padding: '40px'
        }}>
          {currentStep === 1 && renderStep1()}
          {currentStep === 2 && renderStep2()}
          {currentStep === 3 && renderStep3()}
        </div>
        
        {/* Navigation Buttons */}
        <div style={{
          padding: '20px 40px 40px 40px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <button
            onClick={handlePrevious}
            disabled={currentStep === 1}
            style={{
              padding: '12px 24px',
              border: '1px solid #ddd',
              borderRadius: '6px',
              background: 'white',
              color: '#666',
              fontSize: '14px',
              fontWeight: '600',
              cursor: currentStep === 1 ? 'not-allowed' : 'pointer',
              opacity: currentStep === 1 ? 0.5 : 1,
              transition: 'all 0.2s'
            }}
            onMouseOver={(e) => {
              if (currentStep > 1) {
                e.currentTarget.style.borderColor = '#1976d2';
                e.currentTarget.style.color = '#1976d2';
              }
            }}
            onMouseOut={(e) => {
              if (currentStep > 1) {
                e.currentTarget.style.borderColor = '#ddd';
                e.currentTarget.style.color = '#666';
              }
            }}
          >
            ◄ Précédent
          </button>
          
          <div style={{
            fontSize: '12px',
            color: '#999',
            textAlign: 'center'
          }}>
            Étape {currentStep} sur 3
          </div>
          
          <button
            onClick={handleNext}
            disabled={isSubmitting}
            style={{
              padding: '12px 24px',
              border: 'none',
              borderRadius: '6px',
              background: isSubmitting ? '#ccc' : '#1976d2',
              color: 'white',
              fontSize: '14px',
              fontWeight: '600',
              cursor: isSubmitting ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
              opacity: isSubmitting ? 0.7 : 1
            }}
            onMouseOver={(e) => {
              if (!isSubmitting) {
                e.currentTarget.style.background = '#1565c0';
              }
            }}
            onMouseOut={(e) => {
              if (!isSubmitting) {
                e.currentTarget.style.background = '#1976d2';
              }
            }}
          >
            {isSubmitting ? 'Envoi en cours...' : (currentStep === 3 ? 'Envoyer ▸' : 'Suivant ▸')}
          </button>
        </div>
      </div>
    </div>
  );
};

export default QuoteRequestPageFixed;