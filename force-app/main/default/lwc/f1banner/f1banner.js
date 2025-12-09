import { LightningElement } from 'lwc';
import myResource from '@salesforce/resourceUrl/F1_Banner2';

export default class f1banner extends LightningElement {
    // Si el recurso es una imagen única (PNG/JPG/SVG), con esto basta:
    imageUrl = myResource;

    // Si tu static resource fuera un ZIP con "img/f1.jpg",
    // usarías:
    // imageUrl = `${myResource}/img/f1.jpg`;
}