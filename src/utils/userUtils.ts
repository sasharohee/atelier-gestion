import { User } from '../types';

/**
 * Filtre les utilisateurs qui peuvent être assignés à des réparations
 * Inclut les techniciens, administrateurs et managers
 */
export const getRepairEligibleUsers = (users: User[]): User[] => {
  return users.filter(user => 
    user.role === 'technician' || 
    user.role === 'admin' || 
    user.role === 'manager'
  );
};

/**
 * Vérifie si un utilisateur peut être assigné à des réparations
 */
export const isRepairEligible = (user: User): boolean => {
  return user.role === 'technician' || 
         user.role === 'admin' || 
         user.role === 'manager';
};

/**
 * Obtient le nom d'affichage d'un utilisateur pour les réparations
 * Inclut le rôle pour les administrateurs et managers
 */
export const getRepairUserDisplayName = (user: User): string => {
  const baseName = `${user.firstName} ${user.lastName}`;
  
  // Pour les techniciens, afficher seulement le nom
  if (user.role === 'technician') {
    return baseName;
  }
  
  // Pour les administrateurs et managers, inclure le rôle
  return `${baseName} (${user.role})`;
};

/**
 * Filtre les utilisateurs qui ont accès à l'administration
 * Inclut les administrateurs et techniciens
 */
export const getAdminEligibleUsers = (users: User[]): User[] => {
  return users.filter(user => 
    user.role === 'admin' || 
    user.role === 'technician'
  );
};

/**
 * Vérifie si un utilisateur a accès à l'administration
 */
export const isAdminEligible = (user: User): boolean => {
  return user.role === 'admin' || user.role === 'technician';
};
