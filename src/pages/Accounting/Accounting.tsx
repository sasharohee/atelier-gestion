import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Chip,
  CircularProgress,
  Alert,
  alpha,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Receipt as ReceiptIcon,
  Description as InvoiceIcon,
  AttachMoney as ExpenseIcon,
  FileDownload as ExportIcon,
  Assessment as ReportIcon,
} from '@mui/icons-material';

import AccountingOverview from './AccountingOverviewSimple';
import TransactionsList from './TransactionsListFixed';
import InvoicesManagement from './InvoicesManagementFixed';
import ExpensesView from './ExpensesViewFixed';
import ExportsCenter from './ExportsCenterFixed';
import FinancialReports from './FinancialReportsFixed';

const TAB_OPTIONS = [
  { label: 'Vue d\'ensemble', icon: <DashboardIcon sx={{ fontSize: 18 }} />, component: <AccountingOverview /> },
  { label: 'Transactions', icon: <ReceiptIcon sx={{ fontSize: 18 }} />, component: <TransactionsList /> },
  { label: 'Factures', icon: <InvoiceIcon sx={{ fontSize: 18 }} />, component: <InvoicesManagement /> },
  { label: 'Dépenses', icon: <ExpenseIcon sx={{ fontSize: 18 }} />, component: <ExpensesView /> },
  { label: 'Exports', icon: <ExportIcon sx={{ fontSize: 18 }} />, component: <ExportsCenter /> },
  { label: 'Rapports', icon: <ReportIcon sx={{ fontSize: 18 }} />, component: <FinancialReports /> },
];

const Accounting: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => setIsLoading(false), 800);
    return () => clearTimeout(timer);
  }, []);

  if (isLoading) {
    return (
      <Box sx={{
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        height: '50vh', flexDirection: 'column', gap: 2,
      }}>
        <CircularProgress size={36} sx={{ color: '#6366f1' }} />
        <Typography variant="body2" color="text.secondary">
          Chargement de la comptabilité...
        </Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ maxWidth: 1400, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 700, letterSpacing: '-0.02em' }}>
          Comptabilité
        </Typography>
        <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
          Gestion financière et rapports de votre atelier
        </Typography>
      </Box>

      {/* Beta notice */}
      <Alert
        severity="warning"
        sx={{
          mb: 3, borderRadius: '12px', border: '1px solid',
          borderColor: alpha('#f59e0b', 0.2), bgcolor: alpha('#f59e0b', 0.04),
          '& .MuiAlert-icon': { color: '#f59e0b' },
        }}
      >
        <Typography variant="body2">
          <strong>Version Bêta :</strong> Cette page peut comporter des erreurs de calculs.
          Merci de nous signaler toute incohérence.
        </Typography>
      </Alert>

      {/* Tab navigation */}
      <Box sx={{ display: 'flex', gap: 1, mb: 3, flexWrap: 'wrap' }}>
        {TAB_OPTIONS.map((tab, i) => (
          <Chip
            key={i}
            icon={tab.icon}
            label={tab.label}
            onClick={() => setActiveTab(i)}
            sx={{
              fontWeight: 600, fontSize: '0.8rem', borderRadius: '10px', px: 0.5,
              height: 36,
              '& .MuiChip-icon': { ml: '8px' },
              ...(activeTab === i
                ? {
                    bgcolor: '#111827', color: '#fff',
                    '&:hover': { bgcolor: '#1f2937' },
                    boxShadow: '0 2px 8px rgba(17,24,39,0.18)',
                    '& .MuiChip-icon': { color: '#fff' },
                  }
                : {
                    bgcolor: 'transparent', color: 'text.secondary',
                    border: '1px solid', borderColor: 'divider',
                    '&:hover': { bgcolor: 'grey.50' },
                    '& .MuiChip-icon': { color: 'text.secondary' },
                  }),
            }}
          />
        ))}
      </Box>

      {/* Active tab content */}
      <Box>{TAB_OPTIONS[activeTab].component}</Box>
    </Box>
  );
};

export default Accounting;
