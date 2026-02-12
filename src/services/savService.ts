import { v4 as uuidv4 } from 'uuid';
import { WorkTimer, RepairLog, SAVStats, Repair, RepairStatus } from '../types';

class SAVService {
  // Timers actifs en mémoire
  private activeTimers: Map<string, WorkTimer> = new Map();
  private timerIntervals: Map<string, NodeJS.Timeout> = new Map();

  // ================== Gestion des Timers ==================

  /**
   * Démarre un timer pour une réparation
   */
  startTimer(repairId: string): WorkTimer {
    // Vérifier si un timer existe déjà
    let timer = this.activeTimers.get(repairId);

    if (timer) {
      // Si le timer existe et est en pause, on le reprend
      if (timer.isPaused) {
        timer.isPaused = false;
        timer.updatedAt = new Date();
        this.activeTimers.set(repairId, timer);
        return timer;
      }
      // Si le timer est déjà actif, on le retourne
      return timer;
    }

    // Créer un nouveau timer
    timer = {
      id: uuidv4(),
      repairId,
      startTime: new Date(),
      pausedTime: 0,
      totalDuration: 0,
      isPaused: false,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.activeTimers.set(repairId, timer);

    // Démarrer l'intervalle de mise à jour
    const interval = setInterval(() => {
      const currentTimer = this.activeTimers.get(repairId);
      if (currentTimer && !currentTimer.isPaused) {
        const now = new Date();
        const elapsed = now.getTime() - currentTimer.startTime.getTime() - (currentTimer.pausedTime || 0);
        currentTimer.totalDuration = elapsed;
        currentTimer.updatedAt = now;
        this.activeTimers.set(repairId, currentTimer);
      }
    }, 1000);

    this.timerIntervals.set(repairId, interval);

    return timer;
  }

  /**
   * Met en pause un timer
   */
  pauseTimer(repairId: string): WorkTimer | null {
    const timer = this.activeTimers.get(repairId);
    if (!timer || timer.isPaused) {
      return timer || null;
    }

    timer.isPaused = true;
    timer.updatedAt = new Date();
    this.activeTimers.set(repairId, timer);

    return timer;
  }

  /**
   * Reprend un timer en pause
   */
  resumeTimer(repairId: string): WorkTimer | null {
    const timer = this.activeTimers.get(repairId);
    if (!timer || !timer.isPaused) {
      return timer || null;
    }

    timer.isPaused = false;
    timer.updatedAt = new Date();
    this.activeTimers.set(repairId, timer);

    return timer;
  }

  /**
   * Arrête un timer
   */
  stopTimer(repairId: string): WorkTimer | null {
    const timer = this.activeTimers.get(repairId);
    if (!timer) {
      return null;
    }

    // Calculer la durée totale finale
    if (!timer.isPaused) {
      const now = new Date();
      const elapsed = now.getTime() - timer.startTime.getTime() - (timer.pausedTime || 0);
      timer.totalDuration = elapsed;
    }

    timer.isActive = false;
    timer.endTime = new Date();
    timer.updatedAt = new Date();

    // Nettoyer l'intervalle
    const interval = this.timerIntervals.get(repairId);
    if (interval) {
      clearInterval(interval);
      this.timerIntervals.delete(repairId);
    }

    // Garder le timer en mémoire pour consultation mais le marquer comme inactif
    this.activeTimers.set(repairId, timer);

    return timer;
  }

  /**
   * Récupère un timer actif
   */
  getTimer(repairId: string): WorkTimer | null {
    return this.activeTimers.get(repairId) || null;
  }

  /**
   * Récupère tous les timers actifs
   */
  getAllActiveTimers(): WorkTimer[] {
    return Array.from(this.activeTimers.values()).filter(timer => timer.isActive);
  }

  /**
   * Formate une durée en millisecondes en format HH:MM:SS
   */
  formatDuration(milliseconds: number): string {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  // ================== Gestion des Logs ==================

  /**
   * Crée un log d'action pour une réparation
   */
  createLog(
    repairId: string,
    action: string,
    userId: string,
    userName: string,
    description?: string,
    metadata?: Record<string, any>
  ): RepairLog {
    const log: RepairLog = {
      id: uuidv4(),
      repairId,
      action,
      description,
      userId,
      userName,
      timestamp: new Date(),
      metadata,
    };

    // Dans une vraie app, on sauvegarderait en base de données
    // Pour l'instant, on le retourne simplement
    return log;
  }

  // ================== Calcul des Statistiques ==================

  /**
   * Calcule les statistiques SAV en temps réel
   */
  calculateStats(repairs: Repair[], repairStatuses: RepairStatus[]): SAVStats {
    const now = new Date();

    // Créer un map des statuts pour accès rapide
    const statusMap = new Map(repairStatuses.map(s => [s.id, s.name.toLowerCase()]));

    // Initialiser les compteurs
    let totalRepairs = repairs.length;
    let newRepairs = 0;
    let inProgressRepairs = 0;
    let waitingPartsRepairs = 0;
    let completedRepairs = 0;
    let urgentRepairs = 0;
    let overdueRepairs = 0;
    let totalDuration = 0;
    let repairsWithDuration = 0;

    repairs.forEach(repair => {
      const statusName = statusMap.get(repair.status)?.toLowerCase() || '';

      // Compter par statut
      if (statusName.includes('new') || statusName.includes('nouvelle')) {
        newRepairs++;
      } else if (statusName.includes('progress') || statusName.includes('cours')) {
        inProgressRepairs++;
      } else if (statusName.includes('waiting') || statusName.includes('attente')) {
        waitingPartsRepairs++;
      } else if (statusName.includes('completed') || statusName.includes('terminée') || statusName.includes('delivered')) {
        completedRepairs++;
      }

      // Compter les urgents
      if (repair.isUrgent) {
        urgentRepairs++;
      }

      // Compter les retards
      if (new Date(repair.dueDate) < now && !statusName.includes('completed') && !statusName.includes('delivered')) {
        overdueRepairs++;
      }

      // Calculer la durée moyenne
      if (repair.actualDuration) {
        totalDuration += repair.actualDuration;
        repairsWithDuration++;
      }
    });

    const averageDuration = repairsWithDuration > 0 ? totalDuration / repairsWithDuration : 0;
    const completionRate = totalRepairs > 0 ? (completedRepairs / totalRepairs) * 100 : 0;

    return {
      totalRepairs,
      newRepairs,
      inProgressRepairs,
      waitingPartsRepairs,
      completedRepairs,
      urgentRepairs,
      overdueRepairs,
      averageDuration,
      completionRate,
    };
  }

  /**
   * Génère un numéro de réparation unique
   */
  generateRepairNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const random = Math.floor(Math.random() * 9999).toString().padStart(4, '0');

    return `REP-${year}${month}${day}-${random}`;
  }

  /**
   * Vérifie si une réparation est en retard
   */
  isOverdue(repair: Repair, repairStatuses: RepairStatus[]): boolean {
    const now = new Date();
    const statusName = repairStatuses.find(s => s.id === repair.status)?.name.toLowerCase() || '';
    const isCompleted = statusName.includes('completed') || statusName.includes('terminée') || statusName.includes('delivered');

    return new Date(repair.dueDate) < now && !isCompleted;
  }

  /**
   * Calcule le temps restant avant la date limite
   */
  getTimeRemaining(dueDate: Date): { days: number; hours: number; minutes: number; isOverdue: boolean } {
    const now = new Date();
    const due = new Date(dueDate);
    const diff = due.getTime() - now.getTime();
    const isOverdue = diff < 0;
    const absDiff = Math.abs(diff);

    const days = Math.floor(absDiff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((absDiff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((absDiff % (1000 * 60 * 60)) / (1000 * 60));

    return { days, hours, minutes, isOverdue };
  }

  /**
   * Nettoie tous les timers (utile lors du démontage)
   */
  cleanup(): void {
    this.timerIntervals.forEach(interval => clearInterval(interval));
    this.timerIntervals.clear();
    this.activeTimers.clear();
  }
}

// Export d'une instance unique (singleton)
export const savService = new SAVService();










