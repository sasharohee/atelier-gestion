import React from 'react';
import {
  Box,
  Button,
  Typography,
  Paper,
  Grid,
} from '@mui/material';
import {
  Backspace as BackspaceIcon,
  Clear as ClearIcon,
} from '@mui/icons-material';

interface NumericKeypadProps {
  value: string;
  onChange: (value: string) => void;
  onValidate: () => void;
  onCancel: () => void;
  disabled?: boolean;
}

const NumericKeypad: React.FC<NumericKeypadProps> = ({
  value,
  onChange,
  onValidate,
  onCancel,
  disabled = false,
}) => {
  const handleNumberClick = (num: string) => {
    if (disabled) return;
    onChange(value + num);
  };

  const handleClear = () => {
    if (disabled) return;
    onChange('');
  };

  const handleBackspace = () => {
    if (disabled) return;
    onChange(value.slice(0, -1));
  };

  const handleZeroClick = (zeros: string) => {
    if (disabled) return;
    onChange(value + zeros);
  };

  const handleDecimal = () => {
    if (disabled) return;
    if (!value.includes('.')) {
      onChange(value + '.');
    }
  };

  const formatDisplayValue = (val: string) => {
    if (!val) return '0,00';
    const num = parseFloat(val);
    if (isNaN(num)) return '0,00';
    return num.toLocaleString('fr-FR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  };

  const isValidPrice = (val: string) => {
    if (!val) return false;
    const num = parseFloat(val);
    return !isNaN(num) && num > 0;
  };

  return (
    <Paper 
      elevation={3} 
      sx={{ 
        p: 2, 
        bgcolor: '#f5f5f5',
        borderRadius: 2,
        minHeight: 500,
        display: 'flex',
        flexDirection: 'column'
      }}
    >
      {/* Affichage du prix */}
      <Box 
        sx={{ 
          mb: 3, 
          p: 2, 
          bgcolor: 'white', 
          borderRadius: 2, 
          border: '2px solid #e0e0e0',
          textAlign: 'center'
        }}
      >
        <Typography 
          variant="h4" 
          sx={{ 
            fontWeight: 600, 
            color: 'primary.main',
            fontFamily: 'monospace',
            letterSpacing: 1
          }}
        >
          {formatDisplayValue(value)} €
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Prix à saisir
        </Typography>
      </Box>

      {/* Clavier numérique */}
      <Box sx={{ flexGrow: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Ligne 1: 1, 2, 3 */}
        <Grid container spacing={1} sx={{ mb: 1 }}>
          {['1', '2', '3'].map((num) => (
            <Grid item xs={4} key={num}>
              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={() => handleNumberClick(num)}
                disabled={disabled}
                sx={{
                  height: 60,
                  fontSize: '1.5rem',
                  fontWeight: 600,
                  bgcolor: '#4caf50',
                  '&:hover': {
                    bgcolor: '#45a049',
                  },
                  '&:disabled': {
                    bgcolor: '#e0e0e0',
                    color: '#9e9e9e',
                  },
                }}
              >
                {num}
              </Button>
            </Grid>
          ))}
        </Grid>

        {/* Ligne 2: 4, 5, 6 */}
        <Grid container spacing={1} sx={{ mb: 1 }}>
          {['4', '5', '6'].map((num) => (
            <Grid item xs={4} key={num}>
              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={() => handleNumberClick(num)}
                disabled={disabled}
                sx={{
                  height: 60,
                  fontSize: '1.5rem',
                  fontWeight: 600,
                  bgcolor: '#4caf50',
                  '&:hover': {
                    bgcolor: '#45a049',
                  },
                  '&:disabled': {
                    bgcolor: '#e0e0e0',
                    color: '#9e9e9e',
                  },
                }}
              >
                {num}
              </Button>
            </Grid>
          ))}
        </Grid>

        {/* Ligne 3: 7, 8, 9 */}
        <Grid container spacing={1} sx={{ mb: 1 }}>
          {['7', '8', '9'].map((num) => (
            <Grid item xs={4} key={num}>
              <Button
                fullWidth
                variant="contained"
                size="large"
                onClick={() => handleNumberClick(num)}
                disabled={disabled}
                sx={{
                  height: 60,
                  fontSize: '1.5rem',
                  fontWeight: 600,
                  bgcolor: '#4caf50',
                  '&:hover': {
                    bgcolor: '#45a049',
                  },
                  '&:disabled': {
                    bgcolor: '#e0e0e0',
                    color: '#9e9e9e',
                  },
                }}
              >
                {num}
              </Button>
            </Grid>
          ))}
        </Grid>

        {/* Ligne 4: 0, ., C */}
        <Grid container spacing={1} sx={{ mb: 1 }}>
          <Grid item xs={4}>
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={() => handleNumberClick('0')}
              disabled={disabled}
              sx={{
                height: 60,
                fontSize: '1.5rem',
                fontWeight: 600,
                bgcolor: '#4caf50',
                '&:hover': {
                  bgcolor: '#45a049',
                },
                '&:disabled': {
                  bgcolor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              0
            </Button>
          </Grid>
          <Grid item xs={4}>
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={handleDecimal}
              disabled={disabled}
              sx={{
                height: 60,
                fontSize: '1.2rem',
                fontWeight: 600,
                bgcolor: '#ff9800',
                '&:hover': {
                  bgcolor: '#f57c00',
                },
                '&:disabled': {
                  bgcolor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              .
            </Button>
          </Grid>
          <Grid item xs={4}>
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={handleClear}
              disabled={disabled}
              sx={{
                height: 60,
                fontSize: '1.2rem',
                fontWeight: 600,
                bgcolor: '#f44336',
                '&:hover': {
                  bgcolor: '#d32f2f',
                },
                '&:disabled': {
                  bgcolor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              <ClearIcon />
            </Button>
          </Grid>
        </Grid>

        {/* Ligne 5: Boutons spéciaux pour zéros */}
        <Grid container spacing={1} sx={{ mb: 2 }}>
          {['00', '000', '0000'].map((zeros) => (
            <Grid item xs={4} key={zeros}>
              <Button
                fullWidth
                variant="outlined"
                size="large"
                onClick={() => handleZeroClick(zeros)}
                disabled={disabled}
                sx={{
                  height: 50,
                  fontSize: '1rem',
                  fontWeight: 600,
                  borderColor: '#4caf50',
                  color: '#4caf50',
                  '&:hover': {
                    bgcolor: '#e8f5e8',
                    borderColor: '#45a049',
                  },
                  '&:disabled': {
                    borderColor: '#e0e0e0',
                    color: '#9e9e9e',
                  },
                }}
              >
                {zeros}
              </Button>
            </Grid>
          ))}
        </Grid>

        {/* Ligne 6: Backspace */}
        <Grid container spacing={1} sx={{ mb: 2 }}>
          <Grid item xs={12}>
            <Button
              fullWidth
              variant="outlined"
              size="large"
              onClick={handleBackspace}
              disabled={disabled}
              startIcon={<BackspaceIcon />}
              sx={{
                height: 50,
                fontSize: '1rem',
                fontWeight: 600,
                borderColor: '#ff9800',
                color: '#ff9800',
                '&:hover': {
                  bgcolor: '#fff3e0',
                  borderColor: '#f57c00',
                },
                '&:disabled': {
                  borderColor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              Effacer
            </Button>
          </Grid>
        </Grid>

        {/* Boutons d'action */}
        <Grid container spacing={1}>
          <Grid item xs={6}>
            <Button
              fullWidth
              variant="outlined"
              size="large"
              onClick={onCancel}
              disabled={disabled}
              sx={{
                height: 60,
                fontSize: '1.1rem',
                fontWeight: 600,
                borderColor: '#f44336',
                color: '#f44336',
                '&:hover': {
                  bgcolor: '#ffebee',
                  borderColor: '#d32f2f',
                },
                '&:disabled': {
                  borderColor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              Annuler
            </Button>
          </Grid>
          <Grid item xs={6}>
            <Button
              fullWidth
              variant="contained"
              size="large"
              onClick={onValidate}
              disabled={disabled || !isValidPrice(value)}
              sx={{
                height: 60,
                fontSize: '1.1rem',
                fontWeight: 600,
                bgcolor: isValidPrice(value) ? '#4caf50' : '#e0e0e0',
                '&:hover': {
                  bgcolor: isValidPrice(value) ? '#45a049' : '#e0e0e0',
                },
                '&:disabled': {
                  bgcolor: '#e0e0e0',
                  color: '#9e9e9e',
                },
              }}
            >
              Valider
            </Button>
          </Grid>
        </Grid>
      </Box>
    </Paper>
  );
};

export default NumericKeypad;
