import React from 'react';
import { Typography, Box, Chip } from '@mui/material';

interface SpecificationsDisplayProps {
  specifications: any;
  maxDisplay?: number;
}

const SpecificationsDisplay: React.FC<SpecificationsDisplayProps> = ({ 
  specifications, 
  maxDisplay = 3 
}) => {
  if (!specifications) {
    return <Typography variant="body2" color="text.secondary">-</Typography>;
  }

  try {
    // Si c'est une chaîne JSON, la parser
    let specs = specifications;
    if (typeof specifications === 'string') {
      specs = JSON.parse(specifications);
    }

    // Si ce n'est pas un objet, afficher comme texte simple
    if (typeof specs !== 'object' || specs === null) {
      return <Typography variant="body2" color="text.secondary">{String(specs)}</Typography>;
    }

    // Convertir en tableau de paires clé-valeur
    const entries = Object.entries(specs);
    
    if (entries.length === 0) {
      return <Typography variant="body2" color="text.secondary">-</Typography>;
    }

    // Afficher les premières spécifications comme chips
    const displayEntries = entries.slice(0, maxDisplay);
    const remainingCount = entries.length - maxDisplay;

    return (
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
        {displayEntries.map(([key, value]) => (
          <Chip
            key={key}
            label={`${key}: ${value}`}
            size="small"
            variant="outlined"
            sx={{ fontSize: '0.75rem', height: '20px' }}
          />
        ))}
        {remainingCount > 0 && (
          <Chip
            label={`+${remainingCount} autres`}
            size="small"
            variant="outlined"
            sx={{ fontSize: '0.75rem', height: '20px' }}
          />
        )}
      </Box>
    );
  } catch (error) {
    console.error('Erreur affichage specifications:', error);
    return <Typography variant="body2" color="text.secondary">Erreur d'affichage</Typography>;
  }
};

export default SpecificationsDisplay;
