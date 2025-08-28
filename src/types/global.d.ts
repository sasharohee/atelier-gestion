// Déclarations globales pour le débogage
declare global {
  interface Window {
    useAppStore: any;
    repairService: any;
    testMiseAJourReparations: () => void;
    testServiceDirect: () => void;
  }
}

export {};
