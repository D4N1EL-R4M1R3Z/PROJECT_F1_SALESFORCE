import { LightningElement, api, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { refreshApex } from '@salesforce/apex';

export default class KpiTile extends LightningElement {
  @api title = 'Total de Circuitos';
  @api objectApiName = 'circuit__c';     // <-- tu API Name tal cual nos diste
  @api listViewApiName = 'All';          // 'All' o el Id/API Name de la List View
  @api targetTabValue = 'circuit';       // valor del tab a activar en el contenedor
  @api backgroundColor = '#1b66e4';
  @api textColor = '#ffffff';
  @api iconName = 'utility:track';

  total = 0;
  error;
  isLoading = true;
  _wiredResult;

  @wire(getListUi, { objectApiName: '$objectApiName', listViewApiName: '$listViewApiName' })
  wiredList(result) {
    this._wiredResult = result;
    const { data, error } = result;
    this.isLoading = false;
    if (data) {
      this.total = data?.info?.totalRecords ?? 0;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.total = 0;
    }
  }

  /** Permite refrescar desde el contenedor (ej. al activar el tab) */
  @api async refresh() {
    this.isLoading = true;
    try {
      await refreshApex(this._wiredResult);
    } finally {
      this.isLoading = false;
    }
  }

  get computedStyle() {
    return `background:${this.backgroundColor}; color:${this.textColor};`;
  }

  notifyClick() {
    this.dispatchEvent(new CustomEvent('kpiselect', { detail: { tab: this.targetTabValue }}));
  }
}