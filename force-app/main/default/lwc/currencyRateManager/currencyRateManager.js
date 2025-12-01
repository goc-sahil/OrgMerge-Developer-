import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrencyRate from '@salesforce/apex/CurrencyRateManagerController.getCurrencyRate';
import updateCurrencyRate from '@salesforce/apex/CurrencyRateUpdater.updateCurrencyRate';
import syncAllPricebooksWithCAD from '@salesforce/apex/PricebookCurrencySync.syncAllPricebooksWithCAD';
import syncUSDtoCADStatic from '@salesforce/apex/PricebookCurrencySync.syncUSDtoCADStatic';
import getPricebooksWithCADInfo from '@salesforce/apex/PricebookCurrencySync.getPricebooksWithCADInfo';

export default class CadCurrencyRateManager extends LightningElement {
    @track currentRate;
    @track newRate = '';
    @track isLoading = false;
    @track showConfirmDialog = false;
    @track showPricebookModal = false;
    @track error;
    @track pricebookList = [];
    @track syncMode = 'all'; // 'all' or 'static'
    @track staticPricebookId = '01sbZ000000u301QAA';

    // Wire to fetch current CAD rate on component load
    @wire(getCurrencyRate, { isoCode: 'CAD' })
    wiredCurrencyRate({ error, data }) {
        if (data) {
            this.currentRate = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.currentRate = undefined;
            this.showToast('Error', 'Failed to fetch current CAD rate', 'error');
        }
    }

    // Wire to fetch pricebook information
    @wire(getPricebooksWithCADInfo)
    wiredPricebooks({ error, data }) {
        if (data) {
            this.pricebookList = data;
        } else if (error) {
            console.error('Error fetching pricebooks:', error);
        }
    }

    // Handle input change for new rate
    handleNewRateChange(event) {
        this.newRate = event.target.value;
    }

    // Handle sync mode change (radio button)
    handleSyncModeChange(event) {
        this.syncMode = event.target.value;
    }

    // Handle static pricebook ID change
    handleStaticPricebookChange(event) {
        this.staticPricebookId = event.target.value;
    }

    // Show pricebook info modal
    handleViewPricebooks() {
        this.showPricebookModal = true;
    }

    // Close pricebook modal
    handleClosePricebookModal() {
        this.showPricebookModal = false;
    }

    // Handle Update & Recalculate button click
    handleUpdateClick() {
        // Validate input
        if (!this.newRate || isNaN(this.newRate) || parseFloat(this.newRate) <= 0) {
            this.showToast('Invalid Input', 'Please enter a valid positive number for the exchange rate', 'warning');
            return;
        }

        // Validate static pricebook ID if in static mode
        if (this.syncMode === 'static' && (!this.staticPricebookId || this.staticPricebookId.length !== 18)) {
            this.showToast('Invalid Input', 'Please enter a valid 18-character Pricebook ID', 'warning');
            return;
        }

        // Show confirmation dialog
        this.showConfirmDialog = true;
    }

    // Handle Reset button click
    handleReset() {
        this.newRate = '';
        const inputField = this.template.querySelector('lightning-input[data-id="newRate"]');
        if (inputField) {
            inputField.value = '';
        }
    }

    // Handle confirmation dialog - Yes
    handleConfirmYes() {
        this.showConfirmDialog = false;
        this.updateRateAndRecalculate();
    }

    // Handle confirmation dialog - No
    handleConfirmNo() {
        this.showConfirmDialog = false;
    }

    // Main method to update rate and recalculate prices
    async updateRateAndRecalculate() {
        this.isLoading = true;

        try {
            // Step 1: Update Currency Rate
            const updateResult = await updateCurrencyRate({ 
                isoCode: 'CAD', 
                newRate: parseFloat(this.newRate) 
            });

            if (updateResult.includes('successfully')) {
                this.showToast('Success', 'Currency rate updated successfully', 'success');

                // Step 2: Sync Pricebooks based on selected mode
                try {
                    let syncResult;
                    
                    if (this.syncMode === 'all') {
                        // Sync all pricebooks with CAD entries
                        syncResult = await syncAllPricebooksWithCAD();
                    } else {
                        // Sync specific pricebook
                        syncResult = await syncUSDtoCADStatic({ 
                            staticPricebookId: this.staticPricebookId 
                        });
                    }
                    
                    this.showToast('Success', syncResult, 'success');
                    
                    // Refresh current rate display
                    this.refreshCurrentRate();
                    
                    // Clear input field
                    this.newRate = '';
                    
                    // Refresh pricebook list
                    this.refreshPricebookList();
                    
                } catch (syncError) {
                    this.showToast('Warning', 
                        'Rate updated but pricebook sync failed: ' + 
                        (syncError.body?.message || syncError.message), 
                        'warning');
                }
            } else {
                this.showToast('Error', updateResult, 'error');
            }

        } catch (error) {
            this.showToast('Error', 
                'Failed to update currency rate: ' + 
                (error.body?.message || error.message), 
                'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Refresh current rate after update
    async refreshCurrentRate() {
        try {
            const rate = await getCurrencyRate({ isoCode: 'CAD' });
            this.currentRate = rate;
        } catch (error) {
            console.error('Error refreshing rate:', error);
        }
    }

    // Refresh pricebook list
    async refreshPricebookList() {
        try {
            const pricebooks = await getPricebooksWithCADInfo();
            this.pricebookList = pricebooks;
        } catch (error) {
            console.error('Error refreshing pricebook list:', error);
        }
    }

    // Utility method to show toast messages
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: variant === 'error' ? 'sticky' : 'dismissable'
        });
        this.dispatchEvent(event);
    }

    // Computed property for displaying current rate
    get formattedCurrentRate() {
        return this.currentRate ? this.currentRate.toFixed(4) : 'Loading...';
    }

    // Computed property to disable update button
    get isUpdateDisabled() {
        return this.isLoading || !this.newRate;
    }

    // Computed property for sync mode label
    get syncModeLabel() {
        return this.syncMode === 'all' 
            ? 'All Pricebooks with CAD Entries' 
            : 'Static Pricebook (ID: ' + this.staticPricebookId + ')';
    }

    // Computed property to show static pricebook input
    get showStaticPricebookInput() {
        return this.syncMode === 'static';
    }

    // Computed property for confirmation message
    get confirmationMessage() {
        if (this.syncMode === 'all') {
            return 'This will update ALL pricebooks containing CAD entries. ';
        }
        return 'This will update the specified pricebook (' + this.staticPricebookId + '). ';
    }

    // Computed property for pricebook count
    get pricebookCount() {
        return this.pricebookList ? this.pricebookList.length : 0;
    }

    // Options for sync mode radio group
    get syncModeOptions() {
        return [
            { label: 'All Pricebooks with CAD', value: 'all' },
            { label: 'Static Pricebook', value: 'static' }
        ];
    }
}