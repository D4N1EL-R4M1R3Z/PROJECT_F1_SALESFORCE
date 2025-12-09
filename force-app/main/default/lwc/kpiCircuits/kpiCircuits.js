import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import countCircuits from '@salesforce/apex/CircuitKpiService.countCircuits';

export default class KpiCircuits extends NavigationMixin(LightningElement) {
    @api backgroundColor = '#1b66e4';
    @api textColor = '#ffffff';
    @api targetTabValue = 'Circuits'; // Developer Name del tab

    total = 0;
    isLoading = true;
    error;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.isLoading = true;
        this.error = undefined;
        try {
            this.total = await countCircuits();
        } catch (e) {
            this.error = e?.body?.message || e?.message || 'Error';
            this.total = 0;
        } finally {
            this.isLoading = false;
        }
    }

    get computedStyle() {
        return `background:${this.backgroundColor}; color:${this.textColor};`;
    }


notifyClick() {
    thisNavigationMixin.Navigate;
}

}