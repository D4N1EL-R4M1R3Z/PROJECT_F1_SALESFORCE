import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import getCircuits from '@salesforce/apex/HomeF1Controller.getCircuits';
import getConstructors from '@salesforce/apex/HomeF1Controller.getConstructors';

export default class HomeF1 extends LightningElement {
  // Datos
  circuits;
  constructors;

   circuitColumns = [
    //{ label: '2', fieldName: 'Name', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Circuit', fieldName: 'Name', type: 'text' }
  ];

  // Errores
  errorCircuits;
  errorConstructors;

  // Referencias de wire (necesarias para refreshApex)
  wiredCircuitsResult;
  wiredConstructorsResult;

  // Columnas de la tabla (solo lectura)
  constructorColumns = [
    //{ label: '2', fieldName: 'Name', type: 'number', cellAttributes: { alignment: 'left' } },
    { label: 'Constructor', fieldName: 'Name', type: 'text' }
  ];

  // Wire a Apex (cacheable)
  @wire(getCircuits)
  circuitsWire(result) {
    this.wiredCircuitsResult = result;
    const { data, error } = result;
    if (data) {
      this.circuits = data;
      this.errorCircuits = undefined;
    } else if (error) {
      this.errorCircuits = error;
      this.circuits = undefined;
      // opcional: console.error(JSON.stringify(error));
    }
  }

  @wire(getConstructors)
  constructorsWire(result) {
    this.wiredConstructorsResult = result;
    const { data, error } = result;
    if (data) {
      this.constructors = data;
      this.errorConstructors = undefined;
    } else if (error) {
      this.errorConstructors = error;
      this.constructors = undefined;
      // opcional: console.error(JSON.stringify(error));
    }
  }

  // --- Auto-refresh al regresar al Home y cada cierto intervalo ---
  intervalId;

  connectedCallback() {
    // Refresca al volver al tab/ventana
    this.handleVisibilityChange = this.handleVisibilityChange.bind(this);
    window.addEventListener('visibilitychange', this.handleVisibilityChange);

    // Polling suave cada 30s (ajusta si quieres)
    this.intervalId = window.setInterval(() => this.doRefresh(), 30000);
  }

  disconnectedCallback() {
    window.removeEventListener('visibilitychange', this.handleVisibilityChange);
    if (this.intervalId) {
      window.clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  handleVisibilityChange() {
    if (!document.hidden) {
      this.doRefresh();
    }
  }

  handleRefreshClick() {
    this.doRefresh();
  }

  doRefresh() {
    const ops = [];
    if (this.wiredCircuitsResult) ops.push(refreshApex(this.wiredCircuitsResult));
    if (this.wiredConstructorsResult) ops.push(refreshApex(this.wiredConstructorsResult));
    if (ops.length) Promise.all(ops);
  }
}