import { LightningElement, api } from 'lwc';
import countConstructor from '@salesforce/apex/ConstructorKpiService.countConstructor';

export default class KpiDrivers extends LightningElement {
  @api backgroundColor = '#1b66e4';
  @api textColor = '#ffffff';
  @api targetTabValue = 'Constructor'; // para que el contenedor cambie al tab "Circuitos"

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
      this.total = await countConstructor(); // 👈 consulta SOLO en Apex
    } catch (e) {
      this.error = e?.body?.message || e?.message || 'Error';
      this.total = 0;
    } finally {
      this.isLoading = false;
    }
  }

  @api async refresh() {
    await this.load();
  }

  get computedStyle() {
    return `background:${this.backgroundColor}; color:${this.textColor};`;
  }

  notifyClick() {
    this.dispatchEvent(new CustomEvent('kpiselect', { detail: { tab: this.targetTabValue }}));
  }



}