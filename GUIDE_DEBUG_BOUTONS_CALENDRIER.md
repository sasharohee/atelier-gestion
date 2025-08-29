# Guide Debug - Boutons de Vue Calendrier

## 🚨 Problème Actuel

Les boutons de vue (Mois, Semaine, Jour, Liste) ne fonctionnent toujours pas malgré les corrections.

## 🔍 Diagnostic

### 1. **Vérification des Logs**
Ouvrir la console du navigateur et vérifier :
- ✅ `🔄 Changement de vue demandé: [vue]`
- ✅ `✅ État view mis à jour vers: [vue]`

### 2. **Vérification de l'État**
Dans React DevTools, vérifier que l'état `view` change bien.

### 3. **Vérification du Composant**
Le composant FullCalendar devrait se re-rendre avec la nouvelle `key={view}`.

## 🔧 Solutions Testées

### Solution 1 : Propriété `view`
```typescript
<FullCalendar view={view} />
```
❌ **Ne fonctionne pas** - FullCalendar ne réagit pas aux changements

### Solution 2 : Clé de Re-rendu
```typescript
<FullCalendar key={view} initialView={view} />
```
✅ **Devrait fonctionner** - Force le re-rendu complet

## 🧪 Tests à Effectuer

### Test 1 : Console Logs
1. Ouvrir la console du navigateur
2. Cliquer sur "Semaine"
3. Vérifier les logs :
   ```
   🔄 Changement de vue demandé: timeGridWeek
   ✅ État view mis à jour vers: timeGridWeek
   ```

### Test 2 : React DevTools
1. Ouvrir React DevTools
2. Sélectionner le composant Calendar
3. Vérifier l'état `view`
4. Cliquer sur un bouton
5. Vérifier que l'état change

### Test 3 : Re-rendu du Composant
1. Vérifier que FullCalendar se re-rend
2. Vérifier que la vue change visuellement

## 🔄 Prochaines Étapes

Si la solution actuelle ne fonctionne pas :

### Option A : API FullCalendar Directe
```typescript
const calendarRef = useRef(null);

const handleViewChange = (newView) => {
  if (calendarRef.current) {
    const api = calendarRef.current.getApi();
    api.changeView(newView);
  }
};
```

### Option B : État Local + Key
```typescript
const [viewKey, setViewKey] = useState(0);

const handleViewChange = (newView) => {
  setView(newView);
  setViewKey(prev => prev + 1);
};
```

### Option C : Composant Conditionnel
```typescript
{view === 'dayGridMonth' && <FullCalendar initialView="dayGridMonth" />}
{view === 'timeGridWeek' && <FullCalendar initialView="timeGridWeek" />}
// etc.
```

## 📋 Checklist de Debug

- [ ] Console logs s'affichent
- [ ] État React change
- [ ] Composant se re-rend
- [ ] Vue FullCalendar change
- [ ] Interface utilisateur met à jour les boutons

## 🎯 Résultat Attendu

Après correction :
- ✅ Clic sur "Mois" → Vue mensuelle
- ✅ Clic sur "Semaine" → Vue hebdomadaire
- ✅ Clic sur "Jour" → Vue journalière
- ✅ Clic sur "Liste" → Vue liste
- ✅ Bouton actif en surbrillance
