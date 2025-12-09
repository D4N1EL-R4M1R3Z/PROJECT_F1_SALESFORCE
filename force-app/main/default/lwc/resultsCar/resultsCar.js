// force-app/main/default/lwc/raceResults/raceResults.js
import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRecentResults from '@salesforce/apex/RaceResultsController.getRecentResults';

export default class RaceResults extends NavigationMixin(LightningElement) {
    data;
    error;
    loaded = false;

    @wire(getRecentResults, { limitSize: 3 }) // ajusta el límite
    wiredResults({ data, error }) {
        if (data) {
            this.data = data;
            this.loaded = true;
        } else if (error) {
            this.error = error;
            this.loaded = true;
            // Puedes mapear el error para mostrar un mensaje más amigable
        }
    }

    get errorMessage() {
        // Muestra un mensaje simple si hay error
        return this.error ? 'No fue posible cargar los resultados.' : '';
    }

    handleNavigate(event) {
        const recordId = event.currentTarget.dataset.id;
        if (!recordId) return;

     

    }
}