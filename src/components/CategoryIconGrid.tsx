import React from 'react';
import { Box, Button, Typography } from '@mui/material';
import CategoryIconDisplay from './CategoryIconDisplay';

interface CategoryIconGridProps {
  selectedIcon: string;
  onIconSelect: (iconType: string) => void;
}

const CategoryIconGrid: React.FC<CategoryIconGridProps> = ({ 
  selectedIcon, 
  onIconSelect 
}) => {
  const iconCategories = [
    {
      title: "Téléphonie et Communication",
      icons: [
        { type: 'smartphone', label: 'Smartphone', color: '#2196F3' },
        { type: 'phone', label: 'Téléphone', color: '#4CAF50' },
        { type: 'tablet', label: 'Tablette', color: '#9C27B0' },
        { type: 'laptop', label: 'Laptop', color: '#FF9800' },
        { type: 'computer', label: 'Ordinateur', color: '#4CAF50' },
        { type: 'watch', label: 'Montre connectée', color: '#E91E63' },
        { type: 'router', label: 'Routeur', color: '#00BCD4' },
        { type: 'bluetooth', label: 'Bluetooth', color: '#3F51B5' },
        { type: 'wifi', label: 'WiFi', color: '#607D8B' }
      ]
    },
    {
      title: "Audio et Vidéo",
      icons: [
        { type: 'headphones', label: 'Casque', color: '#795548' },
        { type: 'speaker', label: 'Haut-parleur', color: '#4CAF50' },
        { type: 'volume', label: 'Volume', color: '#FF5722' },
        { type: 'mic', label: 'Micro', color: '#9E9E9E' },
        { type: 'camera', label: 'Appareil photo', color: '#FFC107' },
        { type: 'videocam', label: 'Caméra vidéo', color: '#FF5722' },
        { type: 'tv', label: 'Télévision', color: '#2196F3' },
        { type: 'screen', label: 'Écran', color: '#607D8B' }
      ]
    },
    {
      title: "Périphériques",
      icons: [
        { type: 'keyboard', label: 'Clavier', color: '#F44336' },
        { type: 'mouse', label: 'Souris', color: '#9E9E9E' },
        { type: 'usb', label: 'USB', color: '#FF9800' },
        { type: 'cable', label: 'Câble', color: '#795548' },
        { type: 'power', label: 'Alimentation', color: '#FF5722' },
        { type: 'battery', label: 'Batterie', color: '#4CAF50' }
      ]
    },
    {
      title: "Gaming",
      icons: [
        { type: 'gaming', label: 'Console Gaming', color: '#9C27B0' }
      ]
    },
    {
      title: "Mémoire et Stockage",
      icons: [
        { type: 'memory', label: 'Mémoire', color: '#3F51B5' },
        { type: 'storage', label: 'Stockage', color: '#607D8B' }
      ]
    },
    {
      title: "Imprimantes et Scan",
      icons: [
        { type: 'printer', label: 'Imprimante', color: '#9E9E9E' },
        { type: 'scanner', label: 'Scanner', color: '#795548' }
      ]
    },
    {
      title: "Outils et Réparation",
      icons: [
        { type: 'build', label: 'Outils', color: '#795548' },
        { type: 'handyman', label: 'Bricolage', color: '#FF9800' },
        { type: 'engineering', label: 'Ingénierie', color: '#607D8B' },
        { type: 'auto-fix', label: 'Réparation auto', color: '#9E9E9E' },
        { type: 'precision', label: 'Précision', color: '#3F51B5' },
        { type: 'factory', label: 'Industrie', color: '#9E9E9E' }
      ]
    }
  ];

  return (
    <Box>
      {iconCategories.map((category, categoryIndex) => (
        <Box key={categoryIndex} sx={{ mb: 3 }}>
          <Typography 
            variant="subtitle2" 
            sx={{ 
              mb: 1, 
              fontWeight: 'bold', 
              color: 'text.secondary',
              fontSize: '0.875rem'
            }}
          >
            {category.title}
          </Typography>
          <Box 
            sx={{ 
              display: 'grid', 
              gridTemplateColumns: 'repeat(auto-fill, minmax(120px, 1fr))', 
              gap: 1 
            }}
          >
            {category.icons.map((icon) => (
              <Button
                key={icon.type}
                variant={selectedIcon === icon.type ? "contained" : "outlined"}
                onClick={() => onIconSelect(icon.type)}
                sx={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: 0.5,
                  py: 1.5,
                  px: 1,
                  minHeight: 'auto',
                  backgroundColor: selectedIcon === icon.type ? icon.color : 'transparent',
                  borderColor: icon.color,
                  color: selectedIcon === icon.type ? 'white' : icon.color,
                  '&:hover': {
                    backgroundColor: selectedIcon === icon.type ? icon.color : `${icon.color}15`,
                    borderColor: icon.color,
                  },
                  '& .MuiButton-startIcon': {
                    margin: 0,
                  }
                }}
                startIcon={
                  <CategoryIconDisplay 
                    iconType={icon.type} 
                    size={24} 
                    color={selectedIcon === icon.type ? 'white' : icon.color} 
                  />
                }
              >
                <Typography 
                  variant="caption" 
                  sx={{ 
                    fontSize: '0.75rem', 
                    fontWeight: selectedIcon === icon.type ? 'bold' : 'normal',
                    textAlign: 'center',
                    lineHeight: 1.2
                  }}
                >
                  {icon.label}
                </Typography>
              </Button>
            ))}
          </Box>
        </Box>
      ))}
    </Box>
  );
};

export default CategoryIconGrid;
