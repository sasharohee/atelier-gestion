import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  LinearProgress,
  alpha,
} from '@mui/material';
import {
  Assessment,
  Download,
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Delete,
  Analytics as AnalyticsIcon,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

const CARD_BASE = {
  borderRadius: '16px',
  border: '1px solid rgba(0,0,0,0.04)',
  boxShadow: '0 4px 20px rgba(0,0,0,0.06)',
  transition: 'all 0.3s cubic-bezier(0.4,0,0.2,1)',
  '&:hover': {
    boxShadow: '0 8px 32px rgba(0,0,0,0.10)',
    transform: 'translateY(-2px)',
  },
} as const;

const TABLE_HEAD_SX = {
  '& th': {
    borderBottom: '2px solid', borderColor: 'divider', fontWeight: 600,
    fontSize: '0.75rem', color: 'text.secondary', textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
} as const;

interface Report {
  id: string;
  name: string;
  type: 'profit_loss' | 'cash_flow' | 'balance_sheet' | 'monthly';
  period: string;
  generatedAt: string;
  status: 'ready' | 'generating' | 'error';
  size: string;
  downloadCount: number;
}

function KpiMini({ icon, iconColor, label, value }: {
  icon: React.ReactNode; iconColor: string; label: string; value: string | number;
}) {
  return (
    <Card sx={CARD_BASE}>
      <CardContent sx={{ p: '16px !important' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Box sx={{
            width: 40, height: 40, borderRadius: '12px', display: 'flex',
            alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(135deg, ${iconColor}, ${alpha(iconColor, 0.7)})`,
            color: '#fff', flexShrink: 0,
            boxShadow: `0 4px 14px ${alpha(iconColor, 0.3)}`,
          }}>
            {icon}
          </Box>
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2, fontSize: '1.1rem' }}>
              {value}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 500, fontSize: '0.7rem' }}>
              {label}
            </Typography>
          </Box>
        </Box>
      </CardContent>
    </Card>
  );
}

const FinancialReportsFixed: React.FC = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [financialData, setFinancialData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  const { sales, repairs, expenses, clients, systemSettings, loadSales, loadRepairs, loadExpenses, loadClients, loadSystemSettings } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();
  const currency = workshopSettings?.currency || 'EUR';

  useEffect(() => {
    loadRealData();
    loadSavedReports();
  }, []);

  const loadSavedReports = () => {
    try {
      const savedReports = localStorage.getItem('atelier-financial-reports');
      if (savedReports) setReports(JSON.parse(savedReports));
    } catch { /* ignore */ }
  };

  const saveReports = (newReports: Report[]) => {
    try {
      localStorage.setItem('atelier-financial-reports', JSON.stringify(newReports.slice(0, 50)));
    } catch { /* ignore */ }
  };

  const handleDeleteReport = (reportId: string) => {
    const updatedReports = reports.filter(r => r.id !== reportId);
    setReports(updatedReports);
    saveReports(updatedReports);
  };

  const loadRealData = async () => {
    try {
      setIsLoading(true);
      if (systemSettings.length === 0) await loadSystemSettings();
      if (sales.length === 0) await loadSales();
      if (repairs.length === 0) await loadRepairs();
      if (expenses.length === 0) await loadExpenses();
      if (clients.length === 0) await loadClients();
      await new Promise(resolve => setTimeout(resolve, 100));

      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();
      const calculatedData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(calculatedData);

      const savedReports = localStorage.getItem('atelier-financial-reports');
      if (!savedReports || JSON.parse(savedReports).length === 0) {
        const realReports = generateReportsFromData(calculatedData);
        setReports(realReports);
        saveReports(realReports);
      }
    } catch { /* ignore */ } finally {
      setIsLoading(false);
    }
  };

  const getVatRate = () => {
    const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
    return vatSetting ? parseFloat(vatSetting.value) : 20;
  };

  const calculateFinancialDataWithData = (salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const vatRate = getVatRate();

    const totalSales = salesData
      .filter(sale => sale.status === 'completed')
      .reduce((sum, sale) => sum + (sale.total || 0), 0);
    const totalRepairs = repairsData
      .filter(repair => repair.isPaid && repair.status === 'completed')
      .reduce((sum, repair) => sum + (repair.totalPrice || 0), 0);
    const totalRevenue = totalSales + totalRepairs;
    const totalExpenses = expensesData
      .filter(expense => expense.status === 'paid')
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);
    const netProfit = totalRevenue - totalExpenses;

    const currentDate = new Date();
    const last12Months: { month: string; revenue: number; expenses: number; profit: number }[] = [];
    for (let i = 11; i >= 0; i--) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const monthName = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      const monthSales = salesData
        .filter(sale => { const d = new Date(sale.createdAt); return d.getMonth() === date.getMonth() && d.getFullYear() === date.getFullYear() && sale.status === 'completed'; })
        .reduce((sum, sale) => sum + (sale.total || 0), 0);
      const monthRepairs = repairsData
        .filter(repair => { const d = new Date(repair.createdAt); return d.getMonth() === date.getMonth() && d.getFullYear() === date.getFullYear() && repair.isPaid && repair.status === 'completed'; })
        .reduce((sum, repair) => sum + (repair.totalPrice || 0), 0);
      const monthExpenses = expensesData
        .filter(expense => { const d = new Date(expense.expenseDate); return d.getMonth() === date.getMonth() && d.getFullYear() === date.getFullYear() && expense.status === 'paid'; })
        .reduce((sum, expense) => sum + (expense.amount || 0), 0);
      last12Months.push({ month: monthName, revenue: monthSales + monthRepairs, expenses: monthExpenses, profit: (monthSales + monthRepairs) - monthExpenses });
    }

    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const revenueLast30Days = [
      ...salesData.filter(sale => sale.status === 'completed' && new Date(sale.createdAt) >= thirtyDaysAgo),
      ...repairsData.filter(repair => repair.isPaid && repair.status === 'completed' && new Date(repair.createdAt) >= thirtyDaysAgo),
    ].reduce((sum, item) => sum + (item.total || item.totalPrice || 0), 0);
    const expensesLast30Days = expensesData
      .filter(expense => expense.status === 'paid' && new Date(expense.expenseDate) >= thirtyDaysAgo)
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    const revenueByMonthMap = new Map<string, number>();
    const expensesByMonthMap = new Map<string, number>();
    salesData.forEach(sale => {
      if (sale.status === 'completed') {
        const month = new Date(sale.createdAt).toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + (sale.total || 0));
      }
    });
    repairsData.forEach(repair => {
      if (repair.isPaid && repair.status === 'completed') {
        const month = new Date(repair.createdAt).toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + (repair.totalPrice || 0));
      }
    });
    expensesData.forEach(expense => {
      if (expense.status === 'paid') {
        const month = new Date(expense.expenseDate).toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        expensesByMonthMap.set(month, (expensesByMonthMap.get(month) || 0) + (expense.amount || 0));
      }
    });

    const revenueByMonth = Array.from(revenueByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());
    const expensesByMonth = Array.from(expensesByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());

    const expensesCategoriesMap = new Map<string, number>();
    expensesData.forEach(expense => {
      if (expense.status === 'paid') {
        const category = expense.tags?.[0] || 'Général';
        expensesCategoriesMap.set(category, (expensesCategoriesMap.get(category) || 0) + (expense.amount || 0));
      }
    });
    const topExpensesCategories = Array.from(expensesCategoriesMap.entries())
      .map(([category, amount]) => ({ category, amount }))
      .sort((a, b) => b.amount - a.amount).slice(0, 5);

    return {
      totalRevenue, totalExpenses, netProfit,
      totalSales: salesData.length, totalRepairs: repairsData.length,
      totalExpensesCount: expensesData.length, last12Months, vatRate,
      revenueLast30Days, expensesLast30Days, profitLast30Days: revenueLast30Days - expensesLast30Days,
      revenueByMonth, expensesByMonth, topExpensesCategories,
      paidRepairs: repairsData.filter(r => r.isPaid).length,
      completedSales: salesData.filter(s => s.status === 'completed').length,
    };
  };

  const generateReportsFromData = (_data: any) => {
    const currentMonth = new Date().toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
    return [
      { id: 'profit_loss_current', name: `Rapport de Profit et Perte - ${currentMonth}`, type: 'profit_loss' as const, period: currentMonth, generatedAt: new Date().toISOString(), status: 'ready' as const, size: '1.2 MB', downloadCount: 0 },
      { id: 'cash_flow_current', name: `Flux de Trésorerie - ${currentMonth}`, type: 'cash_flow' as const, period: currentMonth, generatedAt: new Date().toISOString(), status: 'ready' as const, size: '0.8 MB', downloadCount: 0 },
      { id: 'monthly_current', name: `Rapport Mensuel - ${currentMonth}`, type: 'monthly' as const, period: currentMonth, generatedAt: new Date().toISOString(), status: 'ready' as const, size: '1.5 MB', downloadCount: 0 },
    ];
  };

  const getReportTypeLabel = (type: string) => {
    const map: Record<string, string> = { profit_loss: 'Profit & Perte', cash_flow: 'Flux de Trésorerie', balance_sheet: 'Bilan Comptable', monthly: 'Rapport Mensuel' };
    return map[type] || type;
  };

  const getReportTypeChip = (type: string) => {
    const map: Record<string, { label: string; color: string }> = {
      profit_loss: { label: 'P&P', color: '#6366f1' },
      cash_flow: { label: 'Flux', color: '#22c55e' },
      balance_sheet: { label: 'Bilan', color: '#06b6d4' },
      monthly: { label: 'Mensuel', color: '#f59e0b' },
    };
    const c = map[type] || { label: type, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const getStatusChip = (status: string) => {
    const map: Record<string, { label: string; color: string }> = {
      ready: { label: 'Prêt', color: '#22c55e' },
      generating: { label: 'En cours', color: '#f59e0b' },
      error: { label: 'Erreur', color: '#ef4444' },
    };
    const c = map[status] || { label: status, color: '#6b7280' };
    return (
      <Chip label={c.label} size="small" sx={{
        fontWeight: 600, borderRadius: '8px', fontSize: '0.72rem',
        bgcolor: alpha(c.color, 0.1), color: c.color,
      }} />
    );
  };

  const handleGenerateReport = async (type: string) => {
    if (!financialData) return;
    try {
      await loadSales(); await loadRepairs(); await loadExpenses(); await loadClients();
      await new Promise(resolve => setTimeout(resolve, 200));
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();
      const updatedFinancialData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(updatedFinancialData);

      const currentMonth = new Date().toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      const newReport: Report = {
        id: Date.now().toString(),
        name: `Rapport ${getReportTypeLabel(type)} - ${currentMonth}`,
        type: type as any, period: currentMonth,
        generatedAt: new Date().toISOString(), status: 'generating',
        size: '0 MB', downloadCount: 0,
      };
      const updatedReports = [newReport, ...reports];
      setReports(updatedReports);
      saveReports(updatedReports);

      setTimeout(() => {
        const finalReports = updatedReports.map(report =>
          report.id === newReport.id ? { ...report, status: 'ready', size: '1.2 MB' } : report
        );
        setReports(finalReports);
        saveReports(finalReports);
      }, 2000);
    } catch { /* ignore */ }
  };

  const handleDownloadReport = async (report: Report) => {
    try {
      await loadSales(); await loadRepairs(); await loadExpenses(); await loadClients();
      await new Promise(resolve => setTimeout(resolve, 200));
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();
      const updatedFinancialData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(updatedFinancialData);
      if (!updatedFinancialData) { alert('Données financières non disponibles'); return; }
      generateCompletePDFReportWithData(report, updatedFinancialData, updatedSales, updatedRepairs, updatedExpenses, updatedClients);
    } catch {
      alert('Erreur lors du téléchargement du rapport');
    }
  };

  const generateCompletePDFReportWithData = (report: Report, fd: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const htmlContent = generateCompleteHTMLReportWithData(report, fd, salesData, repairsData, expensesData, clientsData);
    const blob = new Blob([htmlContent], { type: 'text/html;charset=utf-8;' });
    const link = document.createElement('a');
    link.setAttribute('href', URL.createObjectURL(blob));
    link.setAttribute('download', `Rapport_${report.type}_${report.period.replace(/\s+/g, '_')}.html`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    const updatedReports = reports.map(r => r.id === report.id ? { ...r, downloadCount: r.downloadCount + 1 } : r);
    setReports(updatedReports);
    saveReports(updatedReports);
  };

  const generateCompleteHTMLReportWithData = (report: Report, fd: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const currentDate = new Date();
    const reportDate = new Date(report.generatedAt);
    return `<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>Rapport ${getReportTypeLabel(report.type)} - ${report.period}</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;margin:0;padding:24px;background:#fff;color:#333;line-height:1.6}.report-container{max-width:800px;margin:0 auto}.header{text-align:center;margin-bottom:40px;padding-bottom:20px;border-bottom:2px solid #1976d2}.header h1{font-size:28px;font-weight:600;margin:0 0 8px;color:#1976d2}.header .subtitle{font-size:16px;color:#666;margin-bottom:16px}.header .date{font-size:14px;color:#888}.section{margin-bottom:30px}.section-title{font-size:20px;font-weight:600;margin-bottom:15px;color:#1976d2;border-bottom:1px solid #e0e0e0;padding-bottom:5px}.data-grid{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px}.data-card{background:#f8f9fa;padding:15px;border-radius:8px;border-left:4px solid #1976d2}.data-card h3{font-size:14px;color:#666;margin-bottom:5px}.data-card .value{font-size:24px;font-weight:600;color:#1976d2}.data-card .subtitle{font-size:12px;color:#888}.table{width:100%;border-collapse:collapse;margin-bottom:20px}.table th{background:#f5f5f5;padding:12px;text-align:left;font-weight:600;color:#333;border-bottom:2px solid #e0e0e0}.table td{padding:12px;border-bottom:1px solid #f1f1f1}.table .number{text-align:right;font-weight:600}.table .total-row{background:#f8f9fa;font-weight:600}.chart-placeholder{background:#f8f9fa;padding:40px;text-align:center;border-radius:8px;margin:20px 0}.summary{background:#e8f5e8;padding:20px;border-radius:8px;border-left:4px solid #4caf50}.summary h3{color:#2e7d32;margin-bottom:10px}.footer{text-align:center;margin-top:40px;padding-top:20px;border-top:1px solid #e0e0e0;color:#666;font-size:12px}@media print{body{background:#fff}.report-container{box-shadow:none}}</style></head><body><div class="report-container"><div class="header"><h1>RAPPORT ${getReportTypeLabel(report.type).toUpperCase()}</h1><div class="subtitle">${report.period}</div><div class="date">Généré le ${reportDate.toLocaleDateString('fr-FR')} à ${reportDate.toLocaleTimeString('fr-FR')}</div></div><div class="section"><h2 class="section-title">RÉSUMÉ EXÉCUTIF</h2><div class="data-grid"><div class="data-card"><h3>Chiffre d'Affaires Total</h3><div class="value">${formatFromEUR(fd.totalRevenue, currency)}</div><div class="subtitle">Toutes activités confondues</div></div><div class="data-card"><h3>Dépenses Total</h3><div class="value">${formatFromEUR(fd.totalExpenses, currency)}</div><div class="subtitle">${fd.totalExpensesCount} dépenses enregistrées</div></div><div class="data-card"><h3>Bénéfice Net</h3><div class="value" style="color:${fd.netProfit >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(fd.netProfit, currency)}</div><div class="subtitle">Résultat d'exploitation</div></div><div class="data-card"><h3>Marge de Profit</h3><div class="value">${fd.totalRevenue > 0 ? ((fd.netProfit / fd.totalRevenue) * 100).toFixed(1) : 0}%</div><div class="subtitle">Rentabilité</div></div></div></div>${generateDetailedContentWithData(report, fd, salesData, repairsData, expensesData, clientsData)}<div class="section"><h2 class="section-title">ANALYSE DES TENDANCES</h2><div class="chart-placeholder"><h3>Évolution sur 12 mois</h3><div style="margin-top:20px">${fd.last12Months.slice(-6).map((month: any) => `<div style="display:flex;justify-content:space-between;padding:5px 0;border-bottom:1px solid #eee"><span>${month.month}</span><span>Revenus: ${formatFromEUR(month.revenue, currency)} | Dépenses: ${formatFromEUR(month.expenses, currency)}</span></div>`).join('')}</div></div></div><div class="section"><h2 class="section-title">RECOMMANDATIONS</h2><div class="summary"><h3>Points d'attention</h3><ul style="margin:10px 0;padding-left:20px">${generateRecommendationsWithData(fd)}</ul></div></div><div class="section"><h2 class="section-title">ÉVOLUTION MENSUELLE DÉTAILLÉE</h2><table class="table"><thead><tr><th>Mois</th><th>Revenus</th><th>Dépenses</th><th>Profit</th><th>Marge</th></tr></thead><tbody>${fd.revenueByMonth?.map((item: any) => { const expenseItem = fd.expensesByMonth?.find((e: any) => e.month === item.month); const revenue = item.amount; const exp = expenseItem?.amount || 0; const profit = revenue - exp; const margin = revenue > 0 ? ((profit / revenue) * 100).toFixed(1) : 0; return `<tr><td>${item.month}</td><td class="number" style="color:#4caf50">${formatFromEUR(revenue, currency)}</td><td class="number" style="color:#f44336">${formatFromEUR(exp, currency)}</td><td class="number" style="color:${profit >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(profit, currency)}</td><td class="number">${margin}%</td></tr>`; }).join('') || '<tr><td colspan="5">Aucune donnée disponible</td></tr>'}</tbody></table></div><div class="section"><h2 class="section-title">STATISTIQUES DÉTAILLÉES</h2><div class="data-grid"><div class="data-card"><h3>Activité Totale</h3><div class="value">${fd.totalSales + fd.totalRepairs}</div><div class="subtitle">Transactions totales</div></div><div class="data-card"><h3>Ventes Réalisées</h3><div class="value">${fd.completedSales}</div><div class="subtitle">Ventes terminées</div></div><div class="data-card"><h3>Réparations Payées</h3><div class="value">${fd.paidRepairs}</div><div class="subtitle">Réparations réglées</div></div><div class="data-card"><h3>Clients Actifs</h3><div class="value">${clientsData.length}</div><div class="subtitle">Clients enregistrés</div></div></div></div><div class="footer"><p>Rapport généré automatiquement par le système de gestion d'atelier</p><p>Données extraites le ${currentDate.toLocaleDateString('fr-FR')} à ${currentDate.toLocaleTimeString('fr-FR')}</p></div></div></body></html>`;
  };

  const generateDetailedContentWithData = (report: Report, fd: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const vatRate = getVatRate();
    switch (report.type) {
      case 'profit_loss':
        return `<div class="section"><h2 class="section-title">DÉTAIL DES REVENUS</h2><table class="table"><thead><tr><th>Type d'activité</th><th>Nombre</th><th>Montant HT</th><th>TVA (${vatRate}%)</th><th>Montant TTC</th></tr></thead><tbody><tr><td>Ventes</td><td>${salesData.filter(s => s.status === 'completed').length}</td><td class="number">${formatFromEUR(fd.totalSales / (1 + vatRate / 100), currency)}</td><td class="number">${formatFromEUR(fd.totalSales - (fd.totalSales / (1 + vatRate / 100)), currency)}</td><td class="number">${formatFromEUR(fd.totalSales, currency)}</td></tr><tr><td>Réparations</td><td>${repairsData.filter(r => r.isPaid && r.status === 'completed').length}</td><td class="number">${formatFromEUR(fd.totalRepairs / (1 + vatRate / 100), currency)}</td><td class="number">${formatFromEUR(fd.totalRepairs - (fd.totalRepairs / (1 + vatRate / 100)), currency)}</td><td class="number">${formatFromEUR(fd.totalRepairs, currency)}</td></tr><tr class="total-row"><td><strong>TOTAL</strong></td><td><strong>${salesData.filter(s => s.status === 'completed').length + repairsData.filter(r => r.isPaid && r.status === 'completed').length}</strong></td><td class="number"><strong>${formatFromEUR(fd.totalRevenue / (1 + vatRate / 100), currency)}</strong></td><td class="number"><strong>${formatFromEUR(fd.totalRevenue - (fd.totalRevenue / (1 + vatRate / 100)), currency)}</strong></td><td class="number"><strong>${formatFromEUR(fd.totalRevenue, currency)}</strong></td></tr></tbody></table></div><div class="section"><h2 class="section-title">DÉTAIL DES DÉPENSES</h2><table class="table"><thead><tr><th>Catégorie</th><th>Nombre</th><th>Montant Total</th></tr></thead><tbody>${expensesData.filter(e => e.status === 'paid').reduce((acc: any[], expense: any) => { const category = expense.tags?.[0] || 'Général'; const existing = acc.find(item => item.category === category); if (existing) { existing.count++; existing.amount += expense.amount || 0; } else { acc.push({ category, count: 1, amount: expense.amount || 0 }); } return acc; }, []).map((item: any) => `<tr><td>${item.category}</td><td>${item.count}</td><td class="number">${formatFromEUR(item.amount, currency)}</td></tr>`).join('')}<tr class="total-row"><td><strong>TOTAL DÉPENSES</strong></td><td><strong>${fd.totalExpensesCount}</strong></td><td class="number"><strong>${formatFromEUR(fd.totalExpenses, currency)}</strong></td></tr></tbody></table></div><div class="section"><h2 class="section-title">ANALYSE DES 30 DERNIERS JOURS</h2><div class="data-grid"><div class="data-card"><h3>Revenus (30j)</h3><div class="value">${formatFromEUR(fd.revenueLast30Days || 0, currency)}</div></div><div class="data-card"><h3>Dépenses (30j)</h3><div class="value">${formatFromEUR(fd.expensesLast30Days || 0, currency)}</div></div><div class="data-card"><h3>Profit (30j)</h3><div class="value" style="color:${(fd.profitLast30Days || 0) >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(fd.profitLast30Days || 0, currency)}</div></div><div class="data-card"><h3>Marge (30j)</h3><div class="value">${fd.revenueLast30Days > 0 ? (((fd.profitLast30Days || 0) / fd.revenueLast30Days) * 100).toFixed(1) : 0}%</div></div></div></div><div class="section"><h2 class="section-title">TOP CATÉGORIES DE DÉPENSES</h2><table class="table"><thead><tr><th>Catégorie</th><th>Montant</th><th>Pourcentage</th></tr></thead><tbody>${fd.topExpensesCategories?.map((item: any) => `<tr><td>${item.category}</td><td class="number">${formatFromEUR(item.amount, currency)}</td><td class="number">${fd.totalExpenses > 0 ? ((item.amount / fd.totalExpenses) * 100).toFixed(1) : 0}%</td></tr>`).join('') || '<tr><td colspan="3">Aucune dépense enregistrée</td></tr>'}</tbody></table></div>`;
      case 'cash_flow':
        return `<div class="section"><h2 class="section-title">FLUX DE TRÉSORERIE</h2><table class="table"><thead><tr><th>Type de flux</th><th>Description</th><th>Montant</th></tr></thead><tbody><tr><td><strong>Encaissements</strong></td><td>Ventes et réparations payées</td><td class="number" style="color:#4caf50">+${formatFromEUR(fd.totalRevenue, currency)}</td></tr><tr><td><strong>Décaissements</strong></td><td>Dépenses et charges</td><td class="number" style="color:#f44336">-${formatFromEUR(fd.totalExpenses, currency)}</td></tr><tr class="total-row"><td><strong>VARIATION NETTE</strong></td><td><strong>Trésorerie disponible</strong></td><td class="number" style="color:${fd.netProfit >= 0 ? '#4caf50' : '#f44336'}"><strong>${formatFromEUR(fd.netProfit, currency)}</strong></td></tr></tbody></table></div>`;
      case 'monthly':
        return `<div class="section"><h2 class="section-title">ACTIVITÉ MENSUELLE</h2><div class="data-grid"><div class="data-card"><h3>Réparations</h3><div class="value">${fd.totalRepairs}</div><div class="subtitle">Réparations effectuées</div></div><div class="data-card"><h3>Ventes</h3><div class="value">${fd.totalSales}</div><div class="subtitle">Ventes réalisées</div></div><div class="data-card"><h3>Clients</h3><div class="value">${clientsData.length}</div><div class="subtitle">Clients enregistrés</div></div><div class="data-card"><h3>Dépenses</h3><div class="value">${fd.totalExpensesCount}</div><div class="subtitle">Dépenses enregistrées</div></div></div></div>`;
      default:
        return '<div class="section"><h2 class="section-title">CONTENU DU RAPPORT</h2><p>Rapport en cours de développement...</p></div>';
    }
  };

  const generateRecommendationsWithData = (fd: any) => {
    const recs: string[] = [];
    if (fd.netProfit < 0) recs.push('Attention: Bénéfice négatif détecté. Analyser les coûts et optimiser les revenus.');
    if (fd.totalExpenses > fd.totalRevenue * 0.8) recs.push('Les dépenses représentent plus de 80% du chiffre d\'affaires. Optimiser la gestion des coûts.');
    if (fd.totalRevenue > 0 && (fd.netProfit / fd.totalRevenue) < 0.1) recs.push('Marge de profit faible. Considérer une augmentation des prix ou une réduction des coûts.');
    if (fd.totalSales === 0 && fd.totalRepairs === 0) recs.push('Aucune activité enregistrée. Développer la clientèle et les services.');
    if (fd.totalRevenue > 0 && fd.netProfit > 0) recs.push('Performance positive. Continuer sur cette lancée et optimiser les processus.');
    return recs.map(r => `<li>${r}</li>`).join('');
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 200 }}>
        <Box sx={{ textAlign: 'center' }}>
          <LinearProgress sx={{ mb: 2, width: 200, borderRadius: 4, '& .MuiLinearProgress-bar': { bgcolor: '#6366f1' } }} />
          <Typography variant="body2" color="text.secondary">Chargement des données financières...</Typography>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h6" sx={{ fontWeight: 600 }}>
          Rapports financiers
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            size="small"
            onClick={() => handleGenerateReport('profit_loss')}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'divider', color: 'text.secondary', '&:hover': { bgcolor: 'grey.50', borderColor: 'grey.400' } }}
          >
            Nouveau P&P
          </Button>
          <Button
            variant="outlined"
            size="small"
            onClick={() => handleGenerateReport('cash_flow')}
            sx={{ borderRadius: '10px', textTransform: 'none', fontWeight: 600, borderColor: 'divider', color: 'text.secondary', '&:hover': { bgcolor: 'grey.50', borderColor: 'grey.400' } }}
          >
            Nouveau Flux
          </Button>
          <Button
            variant="contained"
            size="small"
            onClick={() => handleGenerateReport('monthly')}
            sx={{
              borderRadius: '10px', textTransform: 'none', fontWeight: 600,
              bgcolor: '#111827', '&:hover': { bgcolor: '#1f2937' },
              boxShadow: '0 2px 8px rgba(17,24,39,0.25)',
            }}
          >
            Rapport Mensuel
          </Button>
        </Box>
      </Box>

      {/* KPI cards */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={6} md={3}>
          <KpiMini
            icon={<Assessment sx={{ fontSize: 20 }} />}
            iconColor="#6366f1"
            label="Rapports générés"
            value={reports.length}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini
            icon={<Download sx={{ fontSize: 20 }} />}
            iconColor="#22c55e"
            label="Téléchargements"
            value={reports.reduce((sum, r) => sum + r.downloadCount, 0)}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini
            icon={<TrendingUp sx={{ fontSize: 20 }} />}
            iconColor="#06b6d4"
            label="Prêts"
            value={reports.filter(r => r.status === 'ready').length}
          />
        </Grid>
        <Grid item xs={6} md={3}>
          <KpiMini
            icon={<AttachMoney sx={{ fontSize: 20 }} />}
            iconColor="#f59e0b"
            label="En cours"
            value={reports.filter(r => r.status === 'generating').length}
          />
        </Grid>
      </Grid>

      {/* Reports table */}
      <Card sx={{ borderRadius: '16px', border: '1px solid rgba(0,0,0,0.04)', boxShadow: '0 4px 20px rgba(0,0,0,0.06)' }}>
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow sx={TABLE_HEAD_SX}>
                <TableCell>Rapport</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Période</TableCell>
                <TableCell>Généré le</TableCell>
                <TableCell>Statut</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {reports.map((report) => (
                <TableRow key={report.id} sx={{ '&:last-child td': { borderBottom: 0 }, '& td': { py: 1.5 } }}>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{report.name}</Typography>
                    <Typography variant="caption" color="text.disabled" sx={{ fontSize: '0.68rem' }}>
                      {report.size} • {report.downloadCount} téléchargement{report.downloadCount !== 1 ? 's' : ''}
                    </Typography>
                  </TableCell>
                  <TableCell>{getReportTypeChip(report.type)}</TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">{report.period}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {new Date(report.generatedAt).toLocaleDateString('fr-FR')}
                    </Typography>
                    <Typography variant="caption" color="text.disabled" sx={{ fontSize: '0.68rem' }}>
                      {new Date(report.generatedAt).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {getStatusChip(report.status)}
                    {report.status === 'generating' && (
                      <LinearProgress sx={{ mt: 0.5, borderRadius: 4, '& .MuiLinearProgress-bar': { bgcolor: '#f59e0b' } }} />
                    )}
                  </TableCell>
                  <TableCell align="center">
                    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                      <IconButton
                        size="small"
                        disabled={report.status !== 'ready'}
                        onClick={() => handleDownloadReport(report)}
                        sx={{
                          width: 32, height: 32, borderRadius: '8px',
                          bgcolor: alpha('#22c55e', 0.1), color: '#22c55e',
                          '&:hover': { bgcolor: alpha('#22c55e', 0.2) },
                          '&.Mui-disabled': { bgcolor: 'grey.50', color: 'grey.300' },
                        }}
                      >
                        <Download sx={{ fontSize: 16 }} />
                      </IconButton>
                      <IconButton
                        size="small"
                        onClick={() => handleDeleteReport(report.id)}
                        sx={{
                          width: 32, height: 32, borderRadius: '8px',
                          bgcolor: alpha('#ef4444', 0.1), color: '#ef4444',
                          '&:hover': { bgcolor: alpha('#ef4444', 0.2) },
                        }}
                      >
                        <Delete sx={{ fontSize: 16 }} />
                      </IconButton>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>

        {reports.length === 0 && (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', py: 6 }}>
            <AnalyticsIcon sx={{ fontSize: 40, color: 'grey.300', mb: 1 }} />
            <Typography variant="body2" color="text.disabled">Aucun rapport disponible</Typography>
          </Box>
        )}
      </Card>
    </Box>
  );
};

export default FinancialReportsFixed;
