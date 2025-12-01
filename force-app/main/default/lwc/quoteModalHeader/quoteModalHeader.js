// In your JavaScript controller file
import { LightningElement, api, track } from 'lwc';

export default class QuoteInformation extends LightningElement {
    @api quoteName;
    @api accountName;
    @api pricebookName;
    @api showTotalPrice = false;
    @api totalPrice;
    
    // Add a space after currency code
    _currencyCode;
    
    @api
    get currency() {
        return this._currencyCode;
    }
    
    set currency(value) {
        // Add a space after the currency code
        this._currencyCode = value ? `${value} ` : '';
    }
}