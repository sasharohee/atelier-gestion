import React, { useState, useEffect } from 'react';
import {
  Box,
  TextField,
  Typography,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
} from '@mui/material';
import { useWorkshopSettings } from '../contexts/WorkshopSettingsContext';

export interface PriceInputValues {
  price_ht: number;
  price_ttc: number;
  price_is_ttc: boolean;
}

interface PriceInputFieldsProps {
  priceHT: number;
  priceTTC: number;
  priceIsTTC?: boolean;
  currency?: string;
  onChange: (values: PriceInputValues) => void;
  disabled?: boolean;
  error?: string;
}

const PriceInputFields: React.FC<PriceInputFieldsProps> = ({
  priceHT,
  priceTTC,
  priceIsTTC = false,
  currency = 'EUR',
  onChange,
  disabled = false,
  error,
}) => {
  const { workshopSettings } = useWorkshopSettings();
  const [localPriceHT, setLocalPriceHT] = useState(priceHT);
  const [localPriceTTC, setLocalPriceTTC] = useState(priceTTC);
  const [lastEditedField, setLastEditedField] = useState<'ht' | 'ttc'>('ht');

  // Obtenir le taux de TVA configuré
  const getVatRate = () => {
    if (workshopSettings?.vatRate !== undefined && workshopSettings?.vatRate !== null) {
      const parsedRate = parseFloat(workshopSettings.vatRate);
      if (!isNaN(parsedRate)) {
        return parsedRate;
      }
    }
    return 20; // Valeur par défaut 20%
  };

  const vatRate = getVatRate();

  // Synchroniser les valeurs locales avec les props
  useEffect(() => {
    setLocalPriceHT(priceHT);
    setLocalPriceTTC(priceTTC);
  }, [priceHT, priceTTC]);

  // Calculer le prix TTC à partir du prix HT
  const calculateTTCFromHT = (htPrice: number): number => {
    return Math.round(htPrice * (1 + vatRate / 100) * 100) / 100;
  };

  // Calculer le prix HT à partir du prix TTC
  const calculateHTFromTTC = (ttcPrice: number): number => {
    return Math.round(ttcPrice / (1 + vatRate / 100) * 100) / 100;
  };

  // Gérer le changement du prix HT
  const handlePriceHTChange = (value: number) => {
    setLocalPriceHT(value);
    setLastEditedField('ht');
    
    const calculatedTTC = calculateTTCFromHT(value);
    setLocalPriceTTC(calculatedTTC);
    
    onChange({
      price_ht: value,
      price_ttc: calculatedTTC,
      price_is_ttc: false,
    });
  };

  // Gérer le changement du prix TTC
  const handlePriceTTCChange = (value: number) => {
    setLocalPriceTTC(value);
    setLastEditedField('ttc');
    
    const calculatedHT = calculateHTFromTTC(value);
    setLocalPriceHT(calculatedHT);
    
    onChange({
      price_ht: calculatedHT,
      price_ttc: value,
      price_is_ttc: true,
    });
  };

  return (
    <Box>
      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}
      
      <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start' }}>
        <TextField
          fullWidth
          label={`Prix HT (${currency})`}
          type="number"
          value={localPriceHT || ''}
          onChange={(e) => handlePriceHTChange(parseFloat(e.target.value) || 0)}
          inputProps={{ min: 0, step: 0.01 }}
          helperText="Prix hors taxes"
          disabled={disabled}
          error={!!error}
        />
        
        <TextField
          fullWidth
          label={`Prix TTC (${currency})`}
          type="number"
          value={localPriceTTC || ''}
          onChange={(e) => handlePriceTTCChange(parseFloat(e.target.value) || 0)}
          inputProps={{ min: 0, step: 0.01 }}
          helperText="Prix toutes taxes comprises"
          disabled={disabled}
          error={!!error}
        />
      </Box>
      
      <Box sx={{ mt: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="caption" color="text.secondary">
          TVA: {vatRate}%
        </Typography>
        <Typography variant="caption" color="text.secondary">
          {lastEditedField === 'ht' ? 'Calculé depuis HT' : 'Calculé depuis TTC'}
        </Typography>
      </Box>
      
      {/* Affichage de la différence TVA */}
      <Box sx={{ mt: 1 }}>
        <Typography variant="caption" color="text.secondary">
          TVA: {Math.round((localPriceTTC - localPriceHT) * 100) / 100} {currency}
        </Typography>
      </Box>
    </Box>
  );
};

export default PriceInputFields;

