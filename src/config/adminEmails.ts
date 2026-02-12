export const ADMIN_EMAILS = ['srohee32@gmail.com', 'repphonereparation@gmail.com'];

export const isAdminEmail = (email: string | null | undefined): boolean => {
  if (!email) return false;
  return ADMIN_EMAILS.includes(email.toLowerCase());
};
