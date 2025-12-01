import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// Standard and custom fields
import SUBTOTAL_FIELD from '@salesforce/schema/Quote.SubTotal__c';
import GRANDTOTAL_FIELD from '@salesforce/schema/Quote.GrandTotal';
import LUMPSUMDISCOUNT_FIELD from '@salesforce/schema/Quote.LumpsumDiscount__c';
import FINAL_GRANDTOTAL_FIELD from '@salesforce/schema/Quote.Final_Grand_Total__c'; // formula field created above
import CURRENCYISOCODE_FIELD from '@salesforce/schema/Quote.CurrencyIsoCode';
import ID_FIELD from '@salesforce/schema/Quote.Id';

const FIELDS = [
    SUBTOTAL_FIELD,
    GRANDTOTAL_FIELD,
    LUMPSUMDISCOUNT_FIELD,
    FINAL_GRANDTOTAL_FIELD,
    CURRENCYISOCODE_FIELD
];

export default class LumpsumDiscountEditor extends LightningElement {
    @api recordId;

    // track local state
    @track lumpsumDiscount = 0;
    subtotal = 0;
    standardGrandTotal = 0;
    finalGrandTotalFormula = 0; // from formula field
    currencyIsoCode = '';
    isLoading = false;

    wiredRecordResult;
    originalLumpsum = 0;

    renderedCallback() {
        getRecordNotifyChange([{recordId: this.recordId}]);
    }

    // wire to get record values
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { data, error } = result;

        if (data) {
            // Cast to Number safely
            this.subtotal = Number(data.fields.SubTotal__c.value) || 0;
            this.standardGrandTotal = Number(data.fields.GrandTotal.value) || 0;

            this.lumpsumDiscount = Number(data.fields.LumpsumDiscount__c.value) || 0;
            this.originalLumpsum = this.lumpsumDiscount;

            this.finalGrandTotalFormula = Number(data.fields.Final_Grand_Total__c.value) || (this.standardGrandTotal - this.lumpsumDiscount);

            this.currencyIsoCode = data.fields.CurrencyIsoCode.value || '';
        } else if (error) {
            this.showToast('Error', 'Error loading quote: ' + (error.body?.message || error.message), 'error');
            console.error('Error loading Quote:', error);
        }
    }

    // Show Save button only if user changed the lumpsum
    get showSaveButton() {
        return Number(this.lumpsumDiscount) !== Number(this.originalLumpsum);
    }

    // Display: use formula field value (always accurate) — but show user immediate local update too
    get calculatedFinal() {
        // prefer formula value when available; otherwise calculate from standardGrandTotal - lumpsum
        const base = (this.finalGrandTotalFormula !== 0) ? this.finalGrandTotalFormula : (this.standardGrandTotal - this.lumpsumDiscount);
        // When user edits lumpsum, mirror immediate UI change:
        return (this.standardGrandTotal - this.lumpsumDiscount);
    }

    get formattedSubtotal() {
        return this.formatCurrency(this.subtotal);
    }

    get formattedFinalGrandTotal() {
        // Use calculatedFinal but ensure two decimals
        return this.formatCurrency(Number(this.calculatedFinal));
    }

    formatCurrency(value) {
        const num = Number(value) || 0;
        return new Intl.NumberFormat('en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(num);
    }

    handleDiscountChange(event) {
        const value = parseFloat(event.target.value);
        // guard: non-numeric or negative -> 0
        this.lumpsumDiscount = (!isNaN(value) && value >= 0) ? value : 0;
    }

    handleSave() {
        // Basic guard: do not save if unchanged
        if (!this.showSaveButton) {
            return;
        }

        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LUMPSUMDISCOUNT_FIELD.fieldApiName] = this.lumpsumDiscount;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Lumpsum discount saved', 'success');
                this.originalLumpsum = this.lumpsumDiscount;
                // Refresh the record to get updated formula value from server
                return refreshApex(this.wiredRecordResult);
            })
            .catch(error => {
                const msg = error?.body?.message || error.message || 'Unknown error';
                this.showToast('Error', 'Error saving lumpsum discount: ' + msg, 'error');
                console.error('Update error:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant = 'info') {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
