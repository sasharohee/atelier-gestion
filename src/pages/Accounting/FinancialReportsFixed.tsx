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
  Paper,
  Chip,
  IconButton,
  LinearProgress,
} from '@mui/material';
import {
  Assessment,
  Download,
  TrendingUp,
  TrendingDown,
  AttachMoney,
  Delete,
} from '@mui/icons-material';
import { useAppStore } from '../../store';
import { useWorkshopSettings } from '../../contexts/WorkshopSettingsContext';
import { formatFromEUR } from '../../utils/currencyUtils';

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

const FinancialReportsFixed: React.FC = () => {
  const [reports, setReports] = useState<Report[]>([]);
  const [financialData, setFinancialData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  const { sales, repairs, expenses, clients, systemSettings, loadSales, loadRepairs, loadExpenses, loadClients, loadSystemSettings } = useAppStore();
  const { workshopSettings } = useWorkshopSettings();

  useEffect(() => {
    loadRealData();
    // Charger les rapports sauvegardés
    loadSavedReports();
  }, []);

  // Charger les rapports sauvegardés depuis localStorage
  const loadSavedReports = () => {
    try {
      const savedReports = localStorage.getItem('atelier-financial-reports');
      if (savedReports) {
        const parsedReports = JSON.parse(savedReports);
        setReports(parsedReports);
      }
    } catch (error) {
      console.error('Erreur lors du chargement des rapports sauvegardés:', error);
    }
  };

  // Sauvegarder les rapports dans localStorage
  const saveReports = (newReports: Report[]) => {
    try {
      // Limiter à 50 rapports maximum pour éviter l'accumulation
      const limitedReports = newReports.slice(0, 50);
      localStorage.setItem('atelier-financial-reports', JSON.stringify(limitedReports));
    } catch (error) {
      console.error('Erreur lors de la sauvegarde des rapports:', error);
    }
  };

  // Supprimer un rapport
  const handleDeleteReport = (reportId: string) => {
    const updatedReports = reports.filter(r => r.id !== reportId);
    setReports(updatedReports);
    saveReports(updatedReports);
  };

  const loadRealData = async () => {
    try {
      setIsLoading(true);
      
      // Charger toutes les données nécessaires
      console.log('Chargement des données...', { 
        sales: sales.length, 
        repairs: repairs.length, 
        expenses: expenses.length,
        systemSettings: systemSettings.length 
      });

      // Charger les paramètres système si nécessaire
      if (systemSettings.length === 0) {
        await loadSystemSettings();
      }

      // Charger les données si elles ne sont pas disponibles
      if (sales.length === 0) {
        await loadSales();
      }
      if (repairs.length === 0) {
        await loadRepairs();
      }
      if (expenses.length === 0) {
        await loadExpenses();
      }
      if (clients.length === 0) {
        await loadClients();
      }

      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 100));

      // Récupérer les données mises à jour
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();
      
      console.log('Données après chargement:', { 
        sales: updatedSales.length, 
        repairs: updatedRepairs.length, 
        expenses: updatedExpenses.length,
        clients: updatedClients.length 
      });

      // Calculer les données financières réelles avec les données mises à jour
      const calculatedData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(calculatedData);

      // Générer des rapports basés sur les vraies données seulement si aucun rapport n'existe
      const savedReports = localStorage.getItem('atelier-financial-reports');
      if (!savedReports || JSON.parse(savedReports).length === 0) {
        const realReports = generateReportsFromData(calculatedData);
        setReports(realReports);
        saveReports(realReports);
      }

    } catch (error) {
      console.error('Erreur lors du chargement des données financières:', error);
    } finally {
      setIsLoading(false);
    }
  };

  // Récupérer le taux de TVA depuis les paramètres système
  const getVatRate = () => {
    const vatSetting = systemSettings.find(s => s.key === 'vat_rate');
    return vatSetting ? parseFloat(vatSetting.value) : 20; // Valeur par défaut 20%
  };

  // Calculer les données financières réelles avec les données passées en paramètre
  // Utilise EXACTEMENT la même logique que la page comptabilité
  const calculateFinancialDataWithData = (salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const vatRate = getVatRate();
    
    console.log('Calcul avec données:', { 
      sales: salesData.length, 
      repairs: repairsData.length, 
      expenses: expensesData.length,
      clients: clientsData.length 
    });

    // Logs détaillés pour vérifier la cohérence avec la page comptabilité
    console.log('Détail des ventes:', salesData.map(s => ({ 
      id: s.id, 
      status: s.status, 
      total: s.total, 
      createdAt: s.createdAt 
    })));
    console.log('Détail des réparations:', repairsData.map(r => ({ 
      id: r.id, 
      isPaid: r.isPaid, 
      status: r.status, 
      totalPrice: r.totalPrice, 
      createdAt: r.createdAt 
    })));
    console.log('Détail des dépenses:', expensesData.map(e => ({ 
      id: e.id, 
      status: e.status, 
      amount: e.amount, 
      expenseDate: e.expenseDate,
      tags: e.tags 
    })));
    
    // Calculer les revenus totaux (ventes + réparations payées) - EXACTEMENT comme la page comptabilité
    const totalSales = salesData
      .filter(sale => sale.status === 'completed')
      .reduce((sum, sale) => sum + (sale.total || 0), 0);

    const totalRepairs = repairsData
      .filter(repair => repair.isPaid && repair.status === 'completed')
      .reduce((sum, repair) => sum + (repair.totalPrice || 0), 0);

    const totalRevenue = totalSales + totalRepairs;

    // Calculer les dépenses totales - EXACTEMENT comme la page comptabilité
    const totalExpenses = expensesData
      .filter(expense => expense.status === 'paid')
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    // Calculer le profit net
    const netProfit = totalRevenue - totalExpenses;

    // Calculer les données par mois
    const currentDate = new Date();
    const last12Months = [];
    
    for (let i = 11; i >= 0; i--) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const monthName = date.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      
      const monthSales = salesData
        .filter(sale => {
          const saleDate = new Date(sale.createdAt);
          return saleDate.getMonth() === date.getMonth() && 
                 saleDate.getFullYear() === date.getFullYear() &&
                 sale.status === 'completed';
        })
        .reduce((sum, sale) => sum + (sale.total || 0), 0);

      const monthRepairs = repairsData
        .filter(repair => {
          const repairDate = new Date(repair.createdAt);
          return repairDate.getMonth() === date.getMonth() && 
                 repairDate.getFullYear() === date.getFullYear() &&
                 repair.isPaid && repair.status === 'completed';
        })
        .reduce((sum, repair) => sum + (repair.totalPrice || 0), 0);

      const monthExpenses = expensesData
        .filter(expense => {
          const expenseDate = new Date(expense.expenseDate);
          return expenseDate.getMonth() === date.getMonth() && 
                 expenseDate.getFullYear() === date.getFullYear() &&
                 expense.status === 'paid';
        })
        .reduce((sum, expense) => sum + (expense.amount || 0), 0);

      last12Months.push({
        month: monthName,
        revenue: monthSales + monthRepairs,
        expenses: monthExpenses,
        profit: (monthSales + monthRepairs) - monthExpenses
      });
    }

    // Calculer les 30 derniers jours - EXACTEMENT comme la page comptabilité
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const revenueLast30Days = [
      ...salesData.filter(sale => 
        sale.status === 'completed' && 
        new Date(sale.createdAt) >= thirtyDaysAgo
      ),
      ...repairsData.filter(repair => 
        repair.isPaid && 
        repair.status === 'completed' && 
        new Date(repair.createdAt) >= thirtyDaysAgo
      )
    ].reduce((sum, item) => sum + (item.total || item.totalPrice || 0), 0);

    const expensesLast30Days = expensesData
      .filter(expense => 
        expense.status === 'paid' && 
        new Date(expense.expenseDate) >= thirtyDaysAgo
      )
      .reduce((sum, expense) => sum + (expense.amount || 0), 0);

    const profitLast30Days = revenueLast30Days - expensesLast30Days;

    // Agrégation par mois - EXACTEMENT comme la page comptabilité
    const revenueByMonthMap = new Map<string, number>();
    const expensesByMonthMap = new Map<string, number>();

    // Revenus par mois - EXACTEMENT comme la page comptabilité
    // Utiliser les mêmes filtres que totalSales et totalRepairs
    salesData.forEach(sale => {
      if (sale.status === 'completed') {
        const date = new Date(sale.createdAt);
        const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        const amount = sale.total || 0;
        revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + amount);
      }
    });
    
    repairsData.forEach(repair => {
      if (repair.isPaid && repair.status === 'completed') {
        const date = new Date(repair.createdAt);
        const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        const amount = repair.totalPrice || 0;
        revenueByMonthMap.set(month, (revenueByMonthMap.get(month) || 0) + amount);
      }
    });

    // Dépenses par mois - EXACTEMENT comme la page comptabilité
    // Utiliser le même filtre que totalExpenses (status === 'paid')
    expensesData.forEach(expense => {
      if (expense.status === 'paid') {
        const date = new Date(expense.expenseDate);
        const month = date.toLocaleString('fr-FR', { month: 'short', year: 'numeric' });
        expensesByMonthMap.set(month, (expensesByMonthMap.get(month) || 0) + (expense.amount || 0));
      }
    });

    const revenueByMonth = Array.from(revenueByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());

    const expensesByMonth = Array.from(expensesByMonthMap.entries())
      .map(([month, amount]) => ({ month, amount }))
      .sort((a, b) => new Date(a.month).getTime() - new Date(b.month).getTime());

    // Top catégories de dépenses - EXACTEMENT comme la page comptabilité
    // Utiliser le même filtre que totalExpenses (status === 'paid')
    const expensesCategoriesMap = new Map<string, number>();
    expensesData.forEach(expense => {
      if (expense.status === 'paid') {
        const category = expense.tags?.[0] || 'Général';
        expensesCategoriesMap.set(category, (expensesCategoriesMap.get(category) || 0) + (expense.amount || 0));
      }
    });

    const topExpensesCategories = Array.from(expensesCategoriesMap.entries())
      .map(([category, amount]) => ({ category, amount }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5);

    // Vérification de cohérence des revenus et dépenses
    console.log('=== VÉRIFICATION DE COHÉRENCE ===');
    
    // Vérification des revenus
    const totalRevenueByMonth = revenueByMonth.reduce((sum, item) => sum + item.amount, 0);
    const totalRevenueLast12Months = last12Months.reduce((sum, item) => sum + item.revenue, 0);
    
    console.log('Revenus totaux (totalRevenue):', totalRevenue, '€');
    console.log('Total revenus (revenueByMonth):', totalRevenueByMonth, '€');
    console.log('Total revenus (last12Months):', totalRevenueLast12Months, '€');
    console.log('Cohérence revenus:', Math.abs(totalRevenue - totalRevenueByMonth) < 0.01 ? '✅ COHÉRENT' : '❌ INCOHÉRENT');
    
    // Vérification des dépenses
    console.log('Dépenses totales (totalExpenses):', totalExpenses, '€');
    console.log('Dépenses par mois (expensesByMonth):', expensesByMonth);
    console.log('Dépenses 12 mois (last12Months):', last12Months.map(m => ({ month: m.month, expenses: m.expenses })));
    
    const totalExpensesByMonth = expensesByMonth.reduce((sum, item) => sum + item.amount, 0);
    const totalExpensesLast12Months = last12Months.reduce((sum, item) => sum + item.expenses, 0);
    
    console.log('Total dépenses (expensesByMonth):', totalExpensesByMonth, '€');
    console.log('Total dépenses (last12Months):', totalExpensesLast12Months, '€');
    console.log('Cohérence dépenses:', Math.abs(totalExpenses - totalExpensesByMonth) < 0.01 ? '✅ COHÉRENT' : '❌ INCOHÉRENT');

    // Logs finaux pour vérifier la cohérence
    console.log('Résultats finaux:', {
      totalRevenue,
      totalExpenses,
      netProfit,
      totalSales: salesData.length,
      totalRepairs: repairsData.length,
      totalExpensesCount: expensesData.length,
      revenueLast30Days,
      expensesLast30Days,
      profitLast30Days,
      paidRepairs: repairsData.filter(r => r.isPaid).length,
      completedSales: salesData.filter(s => s.status === 'completed').length,
    });

    return {
      totalRevenue,
      totalExpenses,
      netProfit,
      totalSales: salesData.length,
      totalRepairs: repairsData.length,
      totalExpensesCount: expensesData.length,
      last12Months,
      vatRate,
      // Nouvelles métriques de la page comptabilité
      revenueLast30Days,
      expensesLast30Days,
      profitLast30Days,
      revenueByMonth,
      expensesByMonth,
      topExpensesCategories,
      paidRepairs: repairsData.filter(r => r.isPaid).length,
      completedSales: salesData.filter(s => s.status === 'completed').length,
    };
  };

  // Générer des rapports basés sur les vraies données
  const generateReportsFromData = (data: any) => {
    const currentDate = new Date();
    const currentMonth = currentDate.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
    
    return [
      {
        id: 'profit_loss_current',
        name: `Rapport de Profit et Perte - ${currentMonth}`,
        type: 'profit_loss' as const,
        period: currentMonth,
        generatedAt: new Date().toISOString(),
        status: 'ready' as const,
        size: '1.2 MB',
        downloadCount: 0
      },
      {
        id: 'cash_flow_current',
        name: `Flux de Trésorerie - ${currentMonth}`,
        type: 'cash_flow' as const,
        period: currentMonth,
        generatedAt: new Date().toISOString(),
        status: 'ready' as const,
        size: '0.8 MB',
        downloadCount: 0
      },
      {
        id: 'monthly_current',
        name: `Rapport Mensuel - ${currentMonth}`,
        type: 'monthly' as const,
        period: currentMonth,
        generatedAt: new Date().toISOString(),
        status: 'ready' as const,
        size: '1.5 MB',
        downloadCount: 0
      }
    ];
  };

  const getReportTypeLabel = (type: string) => {
    switch (type) {
      case 'profit_loss': return 'Profit & Perte';
      case 'cash_flow': return 'Flux de Trésorerie';
      case 'balance_sheet': return 'Bilan Comptable';
      case 'monthly': return 'Rapport Mensuel';
      default: return type;
    };
  };

  const getReportTypeColor = (type: string) => {
    switch (type) {
      case 'profit_loss': return 'primary';
      case 'cash_flow': return 'success';
      case 'balance_sheet': return 'info';
      case 'monthly': return 'warning';
      default: return 'default';
    };
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ready': return 'success';
      case 'generating': return 'warning';
      case 'error': return 'error';
      default: return 'default';
    };
  };

  const handleGenerateReport = async (type: string) => {
    if (!financialData) return;

    try {
      console.log('=== GÉNÉRATION DE RAPPORT ===');
      console.log('Données avant rechargement:', { 
        sales: sales.length, 
        repairs: repairs.length, 
        expenses: expenses.length 
      });

      // Recharger les données pour s'assurer qu'elles sont à jour
      await loadSales();
      await loadRepairs();
      await loadExpenses();
      await loadClients();

      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 200));

      // Récupérer les données mises à jour
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();

      console.log('Données après rechargement:', { 
        sales: updatedSales.length, 
        repairs: updatedRepairs.length, 
        expenses: updatedExpenses.length 
      });

      // Recalculer les données financières avec les données mises à jour
      const updatedFinancialData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(updatedFinancialData);

      const currentDate = new Date();
      const currentMonth = currentDate.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' });
      
      const newReport: Report = {
        id: Date.now().toString(),
        name: `Rapport ${getReportTypeLabel(type)} - ${currentMonth}`,
        type: type as any,
        period: currentMonth,
        generatedAt: new Date().toISOString(),
        status: 'generating',
        size: '0 MB',
        downloadCount: 0
      };

      const updatedReports = [newReport, ...reports];
      setReports(updatedReports);
      saveReports(updatedReports);

      // Simulation de la fin de génération avec les vraies données
      setTimeout(() => {
        const finalReports = updatedReports.map(report => 
          report.id === newReport.id 
            ? { ...report, status: 'ready', size: '1.2 MB' }
            : report
        );
        setReports(finalReports);
        saveReports(finalReports);
      }, 2000);
    } catch (error) {
      console.error('Erreur lors de la génération du rapport:', error);
    }
  };

  const handleDownloadReport = async (report: Report) => {
    try {
      console.log('=== TÉLÉCHARGEMENT DE RAPPORT ===');
      console.log('Données avant rechargement:', { 
        sales: sales.length, 
        repairs: repairs.length, 
        expenses: expenses.length 
      });

      // Recharger les données pour s'assurer qu'elles sont à jour
      await loadSales();
      await loadRepairs();
      await loadExpenses();
      await loadClients();

      // Attendre un peu pour que les données soient mises à jour
      await new Promise(resolve => setTimeout(resolve, 200));

      // Récupérer les données mises à jour
      const { sales: updatedSales, repairs: updatedRepairs, expenses: updatedExpenses, clients: updatedClients } = useAppStore.getState();

      console.log('Données après rechargement:', { 
        sales: updatedSales.length, 
        repairs: updatedRepairs.length, 
        expenses: updatedExpenses.length 
      });

      // Recalculer les données financières avec les données mises à jour
      const updatedFinancialData = calculateFinancialDataWithData(updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      setFinancialData(updatedFinancialData);

      if (!updatedFinancialData) {
        alert('Données financières non disponibles');
        return;
      }

      // Générer un rapport PDF complet et professionnel avec les données mises à jour
      generateCompletePDFReportWithData(report, updatedFinancialData, updatedSales, updatedRepairs, updatedExpenses, updatedClients);
      
    } catch (error) {
      console.error('Erreur lors du téléchargement:', error);
      alert('Erreur lors du téléchargement du rapport');
    }
  };

  const generateCompletePDFReportWithData = (report: Report, financialData: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    // Créer le contenu HTML complet pour le PDF avec les données mises à jour
    const htmlContent = generateCompleteHTMLReportWithData(report, financialData, salesData, repairsData, expensesData, clientsData);
    
    // Créer et télécharger le PDF
    const blob = new Blob([htmlContent], { type: 'text/html;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `Rapport_${report.type}_${report.period.replace(/\s+/g, '_')}.html`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    
    // Mettre à jour le compteur de téléchargements
    const updatedReports = reports.map(r => 
      r.id === report.id 
        ? { ...r, downloadCount: r.downloadCount + 1 }
        : r
    );
    setReports(updatedReports);
    saveReports(updatedReports);
  };

  const generateCompleteHTMLReportWithData = (report: Report, financialData: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    const currentDate = new Date();
    const reportDate = new Date(report.generatedAt);
    const vatRate = getVatRate();
    
    return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport ${getReportTypeLabel(report.type)} - ${report.period}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
            margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
        }
        .report-container { max-width: 800px; margin: 0 auto; background: white; }
        .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 2px solid #1976d2; }
        .header h1 { font-size: 28px; font-weight: 600; margin: 0 0 8px 0; color: #1976d2; }
        .header .subtitle { font-size: 16px; color: #666; margin-bottom: 16px; }
        .header .date { font-size: 14px; color: #888; }
        .section { margin-bottom: 30px; }
        .section-title { font-size: 20px; font-weight: 600; margin-bottom: 15px; color: #1976d2; border-bottom: 1px solid #e0e0e0; padding-bottom: 5px; }
        .data-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        .data-card { background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #1976d2; }
        .data-card h3 { font-size: 14px; color: #666; margin-bottom: 5px; }
        .data-card .value { font-size: 24px; font-weight: 600; color: #1976d2; }
        .data-card .subtitle { font-size: 12px; color: #888; }
        .table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        .table th { background: #f5f5f5; padding: 12px; text-align: left; font-weight: 600; color: #333; border-bottom: 2px solid #e0e0e0; }
        .table td { padding: 12px; border-bottom: 1px solid #f1f1f1; }
        .table .number { text-align: right; font-weight: 600; }
        .table .total-row { background: #f8f9fa; font-weight: 600; }
        .chart-placeholder { background: #f8f9fa; padding: 40px; text-align: center; border-radius: 8px; margin: 20px 0; }
        .summary { background: #e8f5e8; padding: 20px; border-radius: 8px; border-left: 4px solid #4caf50; }
        .summary h3 { color: #2e7d32; margin-bottom: 10px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e0e0e0; color: #666; font-size: 12px; }
        @media print { body { background: white; } .report-container { box-shadow: none; } }
    </style>
</head>
<body>
    <div class="report-container">
        <!-- En-tête -->
        <div class="header">
            <h1>RAPPORT ${getReportTypeLabel(report.type).toUpperCase()}</h1>
            <div class="subtitle">${report.period}</div>
            <div class="date">Généré le ${reportDate.toLocaleDateString('fr-FR')} à ${reportDate.toLocaleTimeString('fr-FR')}</div>
        </div>

        <!-- Résumé exécutif -->
        <div class="section">
            <h2 class="section-title">RÉSUMÉ EXÉCUTIF</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Chiffre d'Affaires Total</h3>
                    <div class="value">${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</div>
                    <div class="subtitle">Toutes activités confondues</div>
                </div>
                <div class="data-card">
                    <h3>Dépenses Total</h3>
                    <div class="value">${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</div>
                    <div class="subtitle">${financialData.totalExpensesCount} dépenses enregistrées</div>
                </div>
                <div class="data-card">
                    <h3>Bénéfice Net</h3>
                    <div class="value" style="color: ${financialData.netProfit >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(financialData.netProfit, workshopSettings.currency)}</div>
                    <div class="subtitle">Résultat d'exploitation</div>
                </div>
                <div class="data-card">
                    <h3>Marge de Profit</h3>
                    <div class="value">${financialData.totalRevenue > 0 ? ((financialData.netProfit / financialData.totalRevenue) * 100).toFixed(1) : 0}%</div>
                    <div class="subtitle">Rentabilité</div>
                </div>
            </div>
        </div>

        ${generateDetailedContentWithData(report, financialData, salesData, repairsData, expensesData, clientsData)}

        <!-- Analyse des tendances -->
        <div class="section">
            <h2 class="section-title">ANALYSE DES TENDANCES</h2>
            <div class="chart-placeholder">
                <h3>Évolution sur 12 mois</h3>
                <p>Graphique d'évolution des revenus et dépenses par mois</p>
                <div style="margin-top: 20px;">
                    ${financialData.last12Months.slice(-6).map(month => `
                        <div style="display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee;">
                            <span>${month.month}</span>
                            <span>Revenus: ${formatFromEUR(month.revenue, workshopSettings.currency)} | Dépenses: ${formatFromEUR(month.expenses, workshopSettings.currency)}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
        </div>

        <!-- Recommandations -->
        <div class="section">
            <h2 class="section-title">RECOMMANDATIONS</h2>
            <div class="summary">
                <h3>Points d'attention</h3>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    ${generateRecommendationsWithData(financialData)}
                </ul>
            </div>
        </div>

        <!-- Évolution mensuelle détaillée -->
        <div class="section">
            <h2 class="section-title">ÉVOLUTION MENSUELLE DÉTAILLÉE</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Mois</th>
                        <th>Revenus</th>
                        <th>Dépenses</th>
                        <th>Profit</th>
                        <th>Marge</th>
                    </tr>
                </thead>
                <tbody>
                    ${financialData.revenueByMonth?.map((item: any, index: number) => {
                      const expenseItem = financialData.expensesByMonth?.find(e => e.month === item.month);
                      const revenue = item.amount;
                      const expenses = expenseItem?.amount || 0;
                      const profit = revenue - expenses;
                      const margin = revenue > 0 ? ((profit / revenue) * 100).toFixed(1) : 0;
                      return `
                      <tr>
                          <td>${item.month}</td>
                          <td class="number" style="color: #4caf50;">${formatFromEUR(revenue, workshopSettings.currency)}</td>
                          <td class="number" style="color: #f44336;">${formatFromEUR(expenses, workshopSettings.currency)}</td>
                          <td class="number" style="color: ${profit >= 0 ? '#4caf50' : '#f44336'};">${formatFromEUR(profit, workshopSettings.currency)}</td>
                          <td class="number">${margin}%</td>
                      </tr>
                      `;
                    }).join('') || '<tr><td colspan="5">Aucune donnée disponible</td></tr>'}
                </tbody>
            </table>
        </div>

        <!-- Statistiques détaillées de l'atelier -->
        <div class="section">
            <h2 class="section-title">STATISTIQUES DÉTAILLÉES DE L'ATELIER</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Activité Totale</h3>
                    <div class="value">${(financialData.totalSales + financialData.totalRepairs)}</div>
                    <div class="subtitle">Transactions totales</div>
                </div>
                <div class="data-card">
                    <h3>Ventes Réalisées</h3>
                    <div class="value">${financialData.completedSales}</div>
                    <div class="subtitle">Ventes terminées</div>
                </div>
                <div class="data-card">
                    <h3>Réparations Payées</h3>
                    <div class="value">${financialData.paidRepairs}</div>
                    <div class="subtitle">Réparations réglées</div>
                </div>
                <div class="data-card">
                    <h3>Clients Actifs</h3>
                    <div class="value">${clientsData.length}</div>
                    <div class="subtitle">Clients enregistrés</div>
                </div>
            </div>
        </div>

        <!-- Pied de page -->
        <div class="footer">
            <p>Rapport généré automatiquement par le système de gestion d'atelier</p>
            <p>Données extraites le ${currentDate.toLocaleDateString('fr-FR')} à ${currentDate.toLocaleTimeString('fr-FR')}</p>
        </div>
    </div>
</body>
</html>`;
  };

  const generateCompleteHTMLReport = (report: Report) => {
    const currentDate = new Date();
    const reportDate = new Date(report.generatedAt);
    const vatRate = getVatRate();
    
    return `
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport ${getReportTypeLabel(report.type)} - ${report.period}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; 
            margin: 0; padding: 24px; background: white; color: #333; line-height: 1.6;
        }
        .report-container { max-width: 800px; margin: 0 auto; background: white; }
        .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 2px solid #1976d2; }
        .header h1 { font-size: 28px; font-weight: 600; margin: 0 0 8px 0; color: #1976d2; }
        .header .subtitle { font-size: 16px; color: #666; margin-bottom: 16px; }
        .header .date { font-size: 14px; color: #888; }
        .section { margin-bottom: 30px; }
        .section-title { font-size: 20px; font-weight: 600; margin-bottom: 15px; color: #1976d2; border-bottom: 1px solid #e0e0e0; padding-bottom: 5px; }
        .data-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        .data-card { background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 4px solid #1976d2; }
        .data-card h3 { font-size: 14px; color: #666; margin-bottom: 5px; }
        .data-card .value { font-size: 24px; font-weight: 600; color: #1976d2; }
        .data-card .subtitle { font-size: 12px; color: #888; }
        .table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        .table th { background: #f5f5f5; padding: 12px; text-align: left; font-weight: 600; color: #333; border-bottom: 2px solid #e0e0e0; }
        .table td { padding: 12px; border-bottom: 1px solid #f1f1f1; }
        .table .number { text-align: right; font-weight: 600; }
        .table .total-row { background: #f8f9fa; font-weight: 600; }
        .chart-placeholder { background: #f8f9fa; padding: 40px; text-align: center; border-radius: 8px; margin: 20px 0; }
        .summary { background: #e8f5e8; padding: 20px; border-radius: 8px; border-left: 4px solid #4caf50; }
        .summary h3 { color: #2e7d32; margin-bottom: 10px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e0e0e0; color: #666; font-size: 12px; }
        @media print { body { background: white; } .report-container { box-shadow: none; } }
    </style>
</head>
<body>
    <div class="report-container">
        <!-- En-tête -->
        <div class="header">
            <h1>RAPPORT ${getReportTypeLabel(report.type).toUpperCase()}</h1>
            <div class="subtitle">${report.period}</div>
            <div class="date">Généré le ${reportDate.toLocaleDateString('fr-FR')} à ${reportDate.toLocaleTimeString('fr-FR')}</div>
        </div>

        <!-- Résumé exécutif -->
        <div class="section">
            <h2 class="section-title">RÉSUMÉ EXÉCUTIF</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Chiffre d'Affaires Total</h3>
                    <div class="value">${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</div>
                    <div class="subtitle">Toutes activités confondues</div>
                </div>
                <div class="data-card">
                    <h3>Dépenses Total</h3>
                    <div class="value">${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</div>
                    <div class="subtitle">${financialData.totalExpensesCount} dépenses enregistrées</div>
                </div>
                <div class="data-card">
                    <h3>Bénéfice Net</h3>
                    <div class="value" style="color: ${financialData.netProfit >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(financialData.netProfit, workshopSettings.currency)}</div>
                    <div class="subtitle">Résultat d'exploitation</div>
                </div>
                <div class="data-card">
                    <h3>Marge de Profit</h3>
                    <div class="value">${financialData.totalRevenue > 0 ? ((financialData.netProfit / financialData.totalRevenue) * 100).toFixed(1) : 0}%</div>
                    <div class="subtitle">Rentabilité</div>
                </div>
            </div>
        </div>

        ${generateDetailedContent(report)}

        <!-- Analyse des tendances -->
        <div class="section">
            <h2 class="section-title">ANALYSE DES TENDANCES</h2>
            <div class="chart-placeholder">
                <h3>Évolution sur 12 mois</h3>
                <p>Graphique d'évolution des revenus et dépenses par mois</p>
                <div style="margin-top: 20px;">
                    ${financialData.last12Months.slice(-6).map(month => `
                        <div style="display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #eee;">
                            <span>${month.month}</span>
                            <span>Revenus: ${formatFromEUR(month.revenue, workshopSettings.currency)} | Dépenses: ${formatFromEUR(month.expenses, workshopSettings.currency)}</span>
                        </div>
                    `).join('')}
                </div>
            </div>
        </div>

        <!-- Recommandations -->
        <div class="section">
            <h2 class="section-title">RECOMMANDATIONS</h2>
            <div class="summary">
                <h3>Points d'attention</h3>
                <ul style="margin: 10px 0; padding-left: 20px;">
                    ${generateRecommendations()}
                </ul>
            </div>
        </div>

        <!-- Pied de page -->
        <div class="footer">
            <p>Rapport généré automatiquement par le système de gestion d'atelier</p>
            <p>Données extraites le ${currentDate.toLocaleDateString('fr-FR')} à ${currentDate.toLocaleTimeString('fr-FR')}</p>
        </div>
    </div>
</body>
</html>`;
  };

  const generateDetailedContentWithData = (report: Report, financialData: any, salesData: any[], repairsData: any[], expensesData: any[], clientsData: any[]) => {
    switch (report.type) {
      case 'profit_loss':
        return `
        <!-- Détail des revenus -->
        <div class="section">
            <h2 class="section-title">DÉTAIL DES REVENUS</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Type d'activité</th>
                        <th>Nombre</th>
                        <th>Montant HT</th>
                        <th>TVA (${getVatRate()}%)</th>
                        <th>Montant TTC</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Ventes</td>
                        <td>${salesData.filter(s => s.status === 'completed').length}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales / (1 + getVatRate() / 100), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales - (financialData.totalSales / (1 + getVatRate() / 100)), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales, workshopSettings.currency)}</td>
                    </tr>
                    <tr>
                        <td>Réparations</td>
                        <td>${repairsData.filter(r => r.isPaid && r.status === 'completed').length}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs / (1 + getVatRate() / 100), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs - (financialData.totalRepairs / (1 + getVatRate() / 100)), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs, workshopSettings.currency)}</td>
                    </tr>
                    <tr class="total-row">
                        <td><strong>TOTAL</strong></td>
                        <td><strong>${salesData.filter(s => s.status === 'completed').length + repairsData.filter(r => r.isPaid && r.status === 'completed').length}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue / (1 + getVatRate() / 100), workshopSettings.currency)}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue - (financialData.totalRevenue / (1 + getVatRate() / 100)), workshopSettings.currency)}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Détail des dépenses -->
        <div class="section">
            <h2 class="section-title">DÉTAIL DES DÉPENSES</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Catégorie</th>
                        <th>Nombre</th>
                        <th>Montant Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${expensesData.filter(e => e.status === 'paid').reduce((acc, expense) => {
                      const category = expense.tags?.[0] || 'Général';
                      const existing = acc.find(item => item.category === category);
                      if (existing) {
                        existing.count++;
                        existing.amount += expense.amount || 0;
                      } else {
                        acc.push({ category, count: 1, amount: expense.amount || 0 });
                      }
                      return acc;
                    }, []).map(item => `
                    <tr>
                        <td>${item.category}</td>
                        <td>${item.count}</td>
                        <td class="number">${formatFromEUR(item.amount, workshopSettings.currency)}</td>
                    </tr>
                    `).join('')}
                    <tr class="total-row">
                        <td><strong>TOTAL DÉPENSES</strong></td>
                        <td><strong>${financialData.totalExpensesCount}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Analyse des 30 derniers jours -->
        <div class="section">
            <h2 class="section-title">ANALYSE DES 30 DERNIERS JOURS</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Revenus (30j)</h3>
                    <div class="value">${formatFromEUR(financialData.revenueLast30Days || 0, workshopSettings.currency)}</div>
                    <div class="subtitle">Derniers 30 jours</div>
                </div>
                <div class="data-card">
                    <h3>Dépenses (30j)</h3>
                    <div class="value">${formatFromEUR(financialData.expensesLast30Days || 0, workshopSettings.currency)}</div>
                    <div class="subtitle">Derniers 30 jours</div>
                </div>
                <div class="data-card">
                    <h3>Profit (30j)</h3>
                    <div class="value" style="color: ${(financialData.profitLast30Days || 0) >= 0 ? '#4caf50' : '#f44336'}">${formatFromEUR(financialData.profitLast30Days || 0, workshopSettings.currency)}</div>
                    <div class="subtitle">Derniers 30 jours</div>
                </div>
                <div class="data-card">
                    <h3>Marge (30j)</h3>
                    <div class="value">${financialData.revenueLast30Days > 0 ? (((financialData.profitLast30Days || 0) / financialData.revenueLast30Days) * 100).toFixed(1) : 0}%</div>
                    <div class="subtitle">Derniers 30 jours</div>
                </div>
            </div>
        </div>

        <!-- Top catégories de dépenses -->
        <div class="section">
            <h2 class="section-title">TOP CATÉGORIES DE DÉPENSES</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Catégorie</th>
                        <th>Montant</th>
                        <th>Pourcentage</th>
                    </tr>
                </thead>
                <tbody>
                    ${financialData.topExpensesCategories?.map((item: any, index: number) => `
                    <tr>
                        <td>${item.category}</td>
                        <td class="number">${formatFromEUR(item.amount, workshopSettings.currency)}</td>
                        <td class="number">${financialData.totalExpenses > 0 ? ((item.amount / financialData.totalExpenses) * 100).toFixed(1) : 0}%</td>
                    </tr>
                    `).join('') || '<tr><td colspan="3">Aucune dépense enregistrée</td></tr>'}
                </tbody>
            </table>
        </div>`;
        
      case 'cash_flow':
        return `
        <!-- Flux de trésorerie -->
        <div class="section">
            <h2 class="section-title">FLUX DE TRÉSORERIE</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Type de flux</th>
                        <th>Description</th>
                        <th>Montant</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Encaissements</strong></td>
                        <td>Ventes et réparations payées</td>
                        <td class="number" style="color: #4caf50;">+${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</td>
                    </tr>
                    <tr>
                        <td><strong>Décaissements</strong></td>
                        <td>Dépenses et charges</td>
                        <td class="number" style="color: #f44336;">-${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</td>
                    </tr>
                    <tr class="total-row">
                        <td><strong>VARIATION NETTE</strong></td>
                        <td><strong>Trésorerie disponible</strong></td>
                        <td class="number" style="color: ${financialData.netProfit >= 0 ? '#4caf50' : '#f44336'};"><strong>${formatFromEUR(financialData.netProfit, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>`;
        
      case 'monthly':
        return `
        <!-- Activité mensuelle -->
        <div class="section">
            <h2 class="section-title">ACTIVITÉ MENSUELLE</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Réparations</h3>
                    <div class="value">${financialData.totalRepairs}</div>
                    <div class="subtitle">Réparations effectuées</div>
                </div>
                <div class="data-card">
                    <h3>Ventes</h3>
                    <div class="value">${financialData.totalSales}</div>
                    <div class="subtitle">Ventes réalisées</div>
                </div>
                <div class="data-card">
                    <h3>Clients</h3>
                    <div class="value">${clientsData.length}</div>
                    <div class="subtitle">Clients enregistrés</div>
                </div>
                <div class="data-card">
                    <h3>Dépenses</h3>
                    <div class="value">${financialData.totalExpensesCount}</div>
                    <div class="subtitle">Dépenses enregistrées</div>
                </div>
            </div>
        </div>`;
        
      default:
        return '<div class="section"><h2 class="section-title">CONTENU DU RAPPORT</h2><p>Rapport en cours de développement...</p></div>';
    }
  };

  const generateRecommendationsWithData = (financialData: any) => {
    const recommendations = [];
    
    if (financialData.netProfit < 0) {
      recommendations.push('Attention: Bénéfice négatif détecté. Analyser les coûts et optimiser les revenus.');
    }
    
    if (financialData.totalExpenses > financialData.totalRevenue * 0.8) {
      recommendations.push('Les dépenses représentent plus de 80% du chiffre d\'affaires. Optimiser la gestion des coûts.');
    }
    
    if (financialData.totalRevenue > 0 && (financialData.netProfit / financialData.totalRevenue) < 0.1) {
      recommendations.push('Marge de profit faible. Considérer une augmentation des prix ou une réduction des coûts.');
    }
    
    if (financialData.totalSales === 0 && financialData.totalRepairs === 0) {
      recommendations.push('Aucune activité enregistrée. Développer la clientèle et les services.');
    }
    
    if (financialData.totalRevenue > 0 && financialData.netProfit > 0) {
      recommendations.push('Performance positive. Continuer sur cette lancée et optimiser les processus.');
    }
    
    return recommendations.map(rec => `<li>${rec}</li>`).join('');
  };

  const generateDetailedContent = (report: Report) => {
    switch (report.type) {
      case 'profit_loss':
        return `
        <!-- Détail des revenus -->
        <div class="section">
            <h2 class="section-title">DÉTAIL DES REVENUS</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Type d'activité</th>
                        <th>Nombre</th>
                        <th>Montant HT</th>
                        <th>TVA (${getVatRate()}%)</th>
                        <th>Montant TTC</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Ventes</td>
                        <td>${sales.filter(s => s.status === 'completed').length}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales / (1 + getVatRate() / 100), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales - (financialData.totalSales / (1 + getVatRate() / 100)), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalSales, workshopSettings.currency)}</td>
                    </tr>
                    <tr>
                        <td>Réparations</td>
                        <td>${repairs.filter(r => r.isPaid && r.status === 'completed').length}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs / (1 + getVatRate() / 100), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs - (financialData.totalRepairs / (1 + getVatRate() / 100)), workshopSettings.currency)}</td>
                        <td class="number">${formatFromEUR(financialData.totalRepairs, workshopSettings.currency)}</td>
                    </tr>
                    <tr class="total-row">
                        <td><strong>TOTAL</strong></td>
                        <td><strong>${sales.filter(s => s.status === 'completed').length + repairs.filter(r => r.isPaid && r.status === 'completed').length}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue / (1 + getVatRate() / 100), workshopSettings.currency)}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue - (financialData.totalRevenue / (1 + getVatRate() / 100)), workshopSettings.currency)}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>

        <!-- Détail des dépenses -->
        <div class="section">
            <h2 class="section-title">DÉTAIL DES DÉPENSES</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Catégorie</th>
                        <th>Nombre</th>
                        <th>Montant Total</th>
                    </tr>
                </thead>
                <tbody>
                    ${expenses.filter(e => e.status === 'paid').reduce((acc, expense) => {
                      const category = expense.tags?.[0] || 'Général';
                      const existing = acc.find(item => item.category === category);
                      if (existing) {
                        existing.count++;
                        existing.amount += expense.amount || 0;
                      } else {
                        acc.push({ category, count: 1, amount: expense.amount || 0 });
                      }
                      return acc;
                    }, []).map(item => `
                    <tr>
                        <td>${item.category}</td>
                        <td>${item.count}</td>
                        <td class="number">${formatFromEUR(item.amount, workshopSettings.currency)}</td>
                    </tr>
                    `).join('')}
                    <tr class="total-row">
                        <td><strong>TOTAL DÉPENSES</strong></td>
                        <td><strong>${financialData.totalExpensesCount}</strong></td>
                        <td class="number"><strong>${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>`;
        
      case 'cash_flow':
        return `
        <!-- Flux de trésorerie -->
        <div class="section">
            <h2 class="section-title">FLUX DE TRÉSORERIE</h2>
            <table class="table">
                <thead>
                    <tr>
                        <th>Type de flux</th>
                        <th>Description</th>
                        <th>Montant</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Encaissements</strong></td>
                        <td>Ventes et réparations payées</td>
                        <td class="number" style="color: #4caf50;">+${formatFromEUR(financialData.totalRevenue, workshopSettings.currency)}</td>
                    </tr>
                    <tr>
                        <td><strong>Décaissements</strong></td>
                        <td>Dépenses et charges</td>
                        <td class="number" style="color: #f44336;">-${formatFromEUR(financialData.totalExpenses, workshopSettings.currency)}</td>
                    </tr>
                    <tr class="total-row">
                        <td><strong>VARIATION NETTE</strong></td>
                        <td><strong>Trésorerie disponible</strong></td>
                        <td class="number" style="color: ${financialData.netProfit >= 0 ? '#4caf50' : '#f44336'};"><strong>${formatFromEUR(financialData.netProfit, workshopSettings.currency)}</strong></td>
                    </tr>
                </tbody>
            </table>
        </div>`;
        
      case 'monthly':
        return `
        <!-- Activité mensuelle -->
        <div class="section">
            <h2 class="section-title">ACTIVITÉ MENSUELLE</h2>
            <div class="data-grid">
                <div class="data-card">
                    <h3>Réparations</h3>
                    <div class="value">${financialData.totalRepairs}</div>
                    <div class="subtitle">Réparations effectuées</div>
                </div>
                <div class="data-card">
                    <h3>Ventes</h3>
                    <div class="value">${financialData.totalSales}</div>
                    <div class="subtitle">Ventes réalisées</div>
                </div>
                <div class="data-card">
                    <h3>Clients</h3>
                    <div class="value">${clients.length}</div>
                    <div class="subtitle">Clients enregistrés</div>
                </div>
                <div class="data-card">
                    <h3>Dépenses</h3>
                    <div class="value">${financialData.totalExpensesCount}</div>
                    <div class="subtitle">Dépenses enregistrées</div>
                </div>
            </div>
        </div>`;
        
      default:
        return '<div class="section"><h2 class="section-title">CONTENU DU RAPPORT</h2><p>Rapport en cours de développement...</p></div>';
    }
  };

  const generateRecommendations = () => {
    const recommendations = [];
    
    if (financialData.netProfit < 0) {
      recommendations.push('Attention: Bénéfice négatif détecté. Analyser les coûts et optimiser les revenus.');
    }
    
    if (financialData.totalExpenses > financialData.totalRevenue * 0.8) {
      recommendations.push('Les dépenses représentent plus de 80% du chiffre d\'affaires. Optimiser la gestion des coûts.');
    }
    
    if (financialData.totalRevenue > 0 && (financialData.netProfit / financialData.totalRevenue) < 0.1) {
      recommendations.push('Marge de profit faible. Considérer une augmentation des prix ou une réduction des coûts.');
    }
    
    if (financialData.totalSales === 0 && financialData.totalRepairs === 0) {
      recommendations.push('Aucune activité enregistrée. Développer la clientèle et les services.');
    }
    
    if (recommendations.length === 0) {
      recommendations.push('Situation financière stable. Continuer la stratégie actuelle.');
    }
    
    return recommendations.map(rec => `<li>${rec}</li>`).join('');
  };

  if (isLoading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <Box sx={{ textAlign: 'center' }}>
          <LinearProgress sx={{ mb: 2, width: '200px' }} />
          <Typography variant="body1" color="text.secondary">
            Chargement des données financières...
          </Typography>
        </Box>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 'medium' }}>
          Rapports Financiers
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button variant="outlined" onClick={() => handleGenerateReport('profit_loss')}>
            Nouveau P&P
          </Button>
          <Button variant="outlined" onClick={() => handleGenerateReport('cash_flow')}>
            Nouveau Flux
          </Button>
          <Button variant="contained" onClick={() => handleGenerateReport('monthly')}>
            Rapport Mensuel
          </Button>
        </Box>
      </Box>

      {/* Statistiques rapides */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Assessment sx={{ fontSize: 32, mr: 2, color: 'primary.main' }} />
                <Box>
                  <Typography variant="h6">
                    {reports.length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Rapports générés
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Download sx={{ fontSize: 32, mr: 2, color: 'success.main' }} />
                <Box>
                  <Typography variant="h6">
                    {reports.reduce((sum, report) => sum + report.downloadCount, 0)}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Téléchargements
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <TrendingUp sx={{ fontSize: 32, mr: 2, color: 'info.main' }} />
                <Box>
                  <Typography variant="h6">
                    {reports.filter(r => r.status === 'ready').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Prêts
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <AttachMoney sx={{ fontSize: 32, mr: 2, color: 'warning.main' }} />
                <Box>
                  <Typography variant="h6">
                    {reports.filter(r => r.status === 'generating').length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    En cours
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Liste des rapports */}
      <Typography variant="h6" gutterBottom>
        Rapports Disponibles
      </Typography>

      <TableContainer component={Paper} elevation={1}>
        <Table sx={{ minWidth: 650 }} aria-label="reports table">
          <TableHead>
            <TableRow>
              <TableCell>Nom du Rapport</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Période</TableCell>
              <TableCell>Généré le</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Taille</TableCell>
              <TableCell>Téléchargements</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {reports.map((report) => (
              <TableRow key={report.id}>
                <TableCell component="th" scope="row">
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {report.name}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getReportTypeLabel(report.type)} 
                    color={getReportTypeColor(report.type) as any}
                    size="small"
                  />
                </TableCell>
                <TableCell>{report.period}</TableCell>
                <TableCell>
                  {new Date(report.generatedAt).toLocaleDateString('fr-FR')} à{' '}
                  {new Date(report.generatedAt).toLocaleTimeString('fr-FR', { 
                    hour: '2-digit', 
                    minute: '2-digit' 
                  })}
                </TableCell>
                <TableCell>
                  <Chip 
                    label={report.status} 
                    color={getStatusColor(report.status) as any}
                    size="small"
                  />
                  {report.status === 'generating' && (
                    <LinearProgress sx={{ mt: 1 }} />
                  )}
                </TableCell>
                <TableCell>{report.size}</TableCell>
                <TableCell>{report.downloadCount}</TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <IconButton 
                      size="small" 
                      title="Télécharger"
                      disabled={report.status !== 'ready'}
                      onClick={() => handleDownloadReport(report)}
                    >
                      <Download />
                    </IconButton>
                    <IconButton 
                      size="small" 
                      title="Supprimer"
                      onClick={() => handleDeleteReport(report.id)}
                      sx={{ color: 'error.main' }}
                    >
                      <Delete />
                    </IconButton>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default FinancialReportsFixed;
