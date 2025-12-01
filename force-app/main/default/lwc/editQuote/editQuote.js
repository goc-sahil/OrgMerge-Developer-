import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getQuoteById from '@salesforce/apex/QuoteController.getEditQuoteById';
import updateQuote from '@salesforce/apex/QuoteController.updateQuote';
import syncQuoteLineItems from '@salesforce/apex/QuoteController.syncQuoteLineItems';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemController.getQuoteLineItems';
import getProductsFromPricebook from '@salesforce/apex/ProductSelectionController.getProductsFromPricebook';
import getAllOpportunityLineItems from '@salesforce/apex/ProductSelectionController.getAllOpportunityLineItems';
import replaceAllQuoteLineItems from '@salesforce/apex/QuoteController.replaceAllQuoteLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import LUMPSUM_DISCOUNT_PRODUCT from '@salesforce/label/c.Lumpsum_Discount_Product';

const QUOTE_LINE_ITEM_COLUMNS = [
    { label: 'Product Name', fieldName: 'ProductName', type: 'text' },
    { label: 'Product Code', fieldName: 'ProductCode', type: 'text' },
    { 
        label: 'List Price', 
        fieldName: 'FormattedListPrice', 
        type: 'text',
        cellAttributes: { alignment: 'left' }
    },
    // { 
    //     label: 'Sales Price', 
    //     fieldName: 'FormattedSalesPrice', 
    //     type: 'text',
    //     cellAttributes: { alignment: 'left' }
    // },
    { label: 'Product Description', fieldName: 'ProductDescription', type: 'text' },
    { label: 'Product Family', fieldName: 'ProductFamily', type: 'text' }
];

const PRODUCT_COLUMNS = [
    { label: 'Product Name', fieldName: 'ProductName', type: 'text' },
    { label: 'Product Code', fieldName: 'ProductCode', type: 'text' },
    { 
        label: 'List Price', 
        fieldName: 'ListPrice', 
        type: 'currency',
        typeAttributes: {
            currencyCode: { fieldName: 'CurrencyIsoCode' },
            currencyDisplayAs: 'code',
            value: { fieldName: 'ListPrice' }
        },
        cellAttributes: {
            alignment: 'left'
        }
    },
    { label: 'Product Description', fieldName: 'ProductDescription', type: 'text' },
    { label: 'Product Family', fieldName: 'ProductFamily', type: 'text' }
];

export default class QuoteEditQuickAction extends NavigationMixin(LightningElement) {
    isLoaded = false;
        @track modalTitle = 'Edit Quote';
        @track totalPrice = 0;
        @track isStep1 = true;
        @track isStep2 = false;
        @track isStep3 = false;
        @track quoteData = {};
        @track currentStep = '1';
        @track quoteId = null;
        @track pricebookName = null;
        @track Pricebook2Id = null;
        @track savedStep3State = null;
        @track stateOptions = [
            { label: '--None--', value: '' },
            { label: 'Alabama', value: 'Alabama' },
            { label: 'Alaska', value: 'Alaska' },
            { label: 'American Samoa', value: 'American Samoa' },
            { label: 'Arizona', value: 'Arizona' },
            { label: 'Arkansas', value: 'Arkansas' },
            { label: 'California', value: 'California' },
            { label: 'Colorado', value: 'Colorado' },
            { label: 'Connecticut', value: 'Connecticut' },
            { label: 'Delaware', value: 'Delaware' },
            { label: 'District of Columbia', value: 'District of Columbia' },
            { label: 'Florida', value: 'Florida' },
            { label: 'Georgia', value: 'Georgia' },
            { label: 'Guam', value: 'Guam' },
            { label: 'Hawaii', value: 'Hawaii' },
            { label: 'Idaho', value: 'Idaho' },
            { label: 'Illinois', value: 'Illinois' },
            { label: 'Indiana', value: 'Indiana' },
            { label: 'Iowa', value: 'Iowa' },
            { label: 'Kansas', value: 'Kansas' },
            { label: 'Kentucky', value: 'Kentucky' },
            { label: 'Louisiana', value: 'Louisiana' },
            { label: 'Maine', value: 'Maine' },
            { label: 'Maryland', value: 'Maryland' },
            { label: 'Massachusetts', value: 'Massachusetts' },
            { label: 'Michigan', value: 'Michigan' },
            { label: 'Minnesota', value: 'Minnesota' },
            { label: 'Mississippi', value: 'Mississippi' },
            { label: 'Missouri', value: 'Missouri' },
            { label: 'Montana', value: 'Montana' },
            { label: 'Nebraska', value: 'Nebraska' },
            { label: 'Nevada', value: 'Nevada' },
            { label: 'New Hampshire', value: 'New Hampshire' },
            { label: 'New Jersey', value: 'New Jersey' },
            { label: 'New Mexico', value: 'New Mexico' },
            { label: 'New York', value: 'New York' },
            { label: 'North Carolina', value: 'North Carolina' },
            { label: 'North Dakota', value: 'North Dakota' },
            { label: 'Ohio', value: 'Ohio' },
            { label: 'Oklahoma', value: 'Oklahoma' },
            { label: 'Oregon', value: 'Oregon' },
            { label: 'Pennsylvania', value: 'Pennsylvania' },
            { label: 'Puerto Rico', value: 'Puerto Rico' },
            { label: 'Rhode Island', value: 'Rhode Island' },
            { label: 'South Carolina', value: 'South Carolina' },
            { label: 'South Dakota', value: 'South Dakota' },
            { label: 'Tennessee', value: 'Tennessee' },
            { label: 'Texas', value: 'Texas' },
            { label: 'US Virgin Islands', value: 'US Virgin Islands' },
            { label: 'Utah', value: 'Utah' },
            { label: 'Vermont', value: 'Vermont' },
            { label: 'Virginia', value: 'Virginia' },
            { label: 'Washington', value: 'Washington' },
            { label: 'West Virginia', value: 'West Virginia' },
            { label: 'Wisconsin', value: 'Wisconsin' },
            { label: 'Wyoming', value: 'Wyoming' }
        ];
    
        @track selectedQuoteLineItems = [];
        @track selectedAvailableProducts = [];
        @track quoteItems = [];
        @track error;
        @track modifiedItems = [];
        @track isLoading = false;
        @track noData = false;
        @track searchKey = '';
        @track quoteLineItems = [];
        @track allQuoteLineItems = [];
        @track filteredQuoteLineItems = [];
        @track availableProducts = [];
        @track allAvailableProducts = [];
        @track filteredProducts = [];
        @track quoteLineItemIds = new Set();
        quoteLineItemColumns = QUOTE_LINE_ITEM_COLUMNS;
        productColumns = PRODUCT_COLUMNS;
        @track isSearching = false;
        @track hasLoadedAllQuoteLineItems = false;
        newProductRowLimit = 500;
        newProductRowOffSet = 0;
        quoteLineItemRowLimit = 500;
        quoteLineItemRowOffSet = 0;
        enableQuoteLineItemLoadMore = true;
        @track deselectedQuoteLineItemsSet = new Set();
        @track selectedQuoteLineItemsSet = new Set();
        @track selectedAvailableProductsSet = new Set();
        @track editedQuoteItems = [];
        @track isQuoteLineItemCreated = false;
        @track activeSections = ['quoteLineItems', 'newProducts'];
        @track isReviewModalOpen = false;
        @track reviewComment = '';
        wireRecordId;
        currectRecordId;
        
    
        @wire(CurrentPageReference)
        getStateParameters(currentPageReference) {
            if (currentPageReference) {
                this.wireRecordId = currentPageReference.state.recordId;
            }
        }
    
        @api set recordId(value) {
            this.currectRecordId = value;
        }
    
        get recordId() {
            return this.currectRecordId;
        }
    
        get isStep1() {
            return this.currentStep === '1';
        }
        get isStep2() {
            return this.currentStep === '2';
        }
        get isStep3() {
            return this.currentStep === '3';
        }
    
        async connectedCallback() {
            // console.log('currectRecordId ', this.currectRecordId);
            // console.log('wireRecordId ', this.wireRecordId);
            this.updateHostDataAttribute();
            document.addEventListener('click', this.closeDropdowns.bind(this));
            await this.initializeDefaultValues();
            await this.loadInitialQuoteLineItems();
            await this.loadInitialAvailableProducts();
        }
    
        disconnectedCallback() {
            document.removeEventListener('click', this.closeDropdowns.bind(this));
        }
    
        calculateTotalQuotePrice() {
            this.totalPrice = this.quoteItems.reduce((sum, item) => {
                return sum + (parseFloat(item.totalPrice) || 0);
            }, 0).toFixed(2);
        }
    // validateDescriptions() {
    //     let isValid = true;
    //     const inputs = this.template.querySelectorAll('.description-column lightning-textarea');
    
    //     inputs.forEach(input => {
    //         if (!input.value || input.value.trim() === '') {
    //             input.setCustomValidity('Description is required.');
    //             input.reportValidity();
    //             isValid = false;
    //         } else {
    //             input.setCustomValidity('');
    //             input.reportValidity();
    //         }
    //     });
    
    //     return isValid;
    // }
    
        async initializeDefaultValues() {
            try {
                this.isLoading = true;
                const quote = await getQuoteById({ quoteId: this.wireRecordId });
                if (!quote || !quote.Id) {
                    this.showToast('Error', 'Quote not found.', 'error');
                    return;
                }
    
                this.quoteData = {
                    Id: quote.Id,
                    opportunityName: quote.Opportunity?.Name,
                    accountName: quote.QuoteAccount?.Name,
                    endCustomerId:quote.End_Customer__c,
                    endCustomer:quote.End_Customer__r.Name,
                    OpportunityId: quote.OpportunityId,
                    AccountId: quote.QuoteAccountId,
                    Name: quote.Name,
                    ExpirationDate: quote.ExpirationDate ? new Date(quote.ExpirationDate).toISOString().split('T')[0] : null,
                    Status: quote.Status,
                    Review_Requested_for__c: quote.Review_Requested_for__c || '',
                    Additional__c: quote.Additional__c,
                    Lump_Sum_Discount__c: quote.Lump_Sum_Discount__c,
                    ContactId: quote.ContactId,
                    BillingName: quote.BillingName,
                    BillingCountry: quote.BillingCountry,
                    BillingStreet: quote.BillingStreet,
                    BillingCity: quote.BillingCity,
                    BillingState: quote.BillingState || '',
                    BillingPostalCode: quote.BillingPostalCode,
                    ShippingName: quote.ShippingName,
                    ShippingCountry: quote.ShippingCountry,
                    ShippingStreet: quote.ShippingStreet,
                    ShippingCity: quote.ShippingCity,
                    ShippingState: quote.ShippingState || '',
                    ShippingPostalCode: quote.ShippingPostalCode,
                    Pricebook2Id: quote.Pricebook2Id,
                    pricebookName: quote.Pricebook2?.Name,
                    CurrencyIsoCode: quote.CurrencyIsoCode || 'USD'
                };
                this.quoteId = quote.Id;
                this.pricebookName = quote.Pricebook2?.Name || null;
                this.Pricebook2Id = quote.Pricebook2Id;
                if (!this.isReviewModalOpen) { // Only set if the modal isn’t open
            this.reviewComment = this.quoteData.Review_Requested_for__c;
        }
                // console.log('pre-pop val', this.reviewComment);
                await new Promise(resolve => requestAnimationFrame(resolve));
                this.prepopulateFormFields();
            } catch (error) {
                this.showToast('Error', 'Failed to load Quote details: ' + this.reduceErrors(error), 'error');
            } finally {
                this.isLoading = false;
            }
        }
    
        prepopulateFormFields() {
            const form = this.template.querySelector('lightning-record-edit-form');
            if (form) {
                const fields = form.querySelectorAll('lightning-input-field');
                fields.forEach(field => {
                    const fieldName = field.fieldName;
                    if (this.quoteData[fieldName] !== undefined) {
                        field.value = this.quoteData[fieldName];
                    }
                });
            }
        }
    
        closeModal() {
            this.dispatchEvent(new RefreshEvent());
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    
        handleSuccess(event) {
            this.quoteId = event.detail.id;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quote updated successfully!',
                    variant: 'success'
                })
            );
            this.dispatchEvent(new CustomEvent('success', { detail: this.quoteId }));
            this.closeModal();
        }
    
        goToStep1() {
            this.modalTitle = 'Edit Quote';
            this.isStep1 = true;
            this.isStep2 = false;
            this.isStep3 = false;
            this.updateHostDataAttribute();
            this.currentStep = '1';
            this.initializeDefaultValues();
        }
    
        async goToStep2() {
    this.modalTitle = 'Quote Line Items';
    if (!this.quoteData.Name || this.quoteData.Name.trim() === '') {
        this.showErrorToast({ body: { message: 'Quote Name is required' } });
        return;
    }
    // Set loading state at the start
    this.isLoading = true;
    try {
        // Preserve current selections if savedStep3State is not available
        const previousSelectedAvailableProductsSet = new Set(this.selectedAvailableProductsSet);
        const previousDeselectedQuoteLineItemsSet = new Set(this.deselectedQuoteLineItemsSet);
        const previousSelectedQuoteLineItemsSet = new Set(this.selectedQuoteLineItemsSet);
        const previousDeletedClonedItems = this.deletedClonedItems ? new Set(this.deletedClonedItems) : new Set();
        
        // Restore Step 2 state from savedStep3State if available
        if (this.savedStep3State) {
            this.selectedAvailableProductsSet = new Set(this.savedStep3State.selectedAvailableProductsSet);
            this.deselectedQuoteLineItemsSet = new Set(this.savedStep3State.deselectedQuoteLineItemsSet);
            this.selectedQuoteLineItemsSet = new Set(this.savedStep3State.selectedQuoteLineItemsSet);
            this.deletedClonedItems = this.savedStep3State.deletedClonedItems ? 
                new Set(this.savedStep3State.deletedClonedItems) : 
                previousDeletedClonedItems;
            
            // console.log('Restored Step 2 state from savedStep3State:', {
            //     selectedAvailableProductsSet: Array.from(this.selectedAvailableProductsSet),
            //     deselectedQuoteLineItemsSet: Array.from(this.deselectedQuoteLineItemsSet),
            //     selectedQuoteLineItemsSet: Array.from(this.selectedQuoteLineItemsSet),
            //     deletedClonedItems: Array.from(this.deletedClonedItems)
            // });
        } else {
            // console.log('No savedStep3State, retaining previous selections:', {
            //     selectedAvailableProductsSet: Array.from(previousSelectedAvailableProductsSet),
            //     deselectedQuoteLineItemsSet: Array.from(previousDeselectedQuoteLineItemsSet),
            //     selectedQuoteLineItemsSet: Array.from(previousSelectedQuoteLineItemsSet),
            //     deletedClonedItems: Array.from(previousDeletedClonedItems)
            // });
        }
        
        // Update step flags
        this.isStep1 = false;
        this.isStep2 = true;
        this.isStep3 = false;
        this.currentStep = '2';
        this.updateHostDataAttribute();
        this.saveFormValuesToQuoteData();
        
        // Perform all asynchronous operations
        await this.saveQuoteAndContinue();
        
        // Load quote line items and available products concurrently
        const loadPromises = [
            this.hasLoadedAllQuoteLineItems ? Promise.resolve() : this.loadInitialQuoteLineItems(),
            this.loadInitialAvailableProducts()
        ];
        await Promise.all(loadPromises);
        
        // Update selections after loading data
        this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet);
        this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
        this.activeSections = ['quoteLineItems', 'newProducts'];
    } catch (error) {
        console.error('Error in goToStep2:', error);
        this.showErrorToast({ body: { message: 'Failed to load Step 2: ' + this.reduceErrors(error) } });
    } finally {
        // Clear loading state only after all operations complete
        this.isLoading = false;
    }
}
    
        async saveQuoteAndContinue() {
            try {
                if (!this.quoteData.Pricebook2Id) {
                    this.showErrorToast({ body: { message: 'Pricebook is not set for the Quote.' } });
                    return;
                }
    
                if (!this.quoteData.Name) {
                    this.showErrorToast({ body: { message: 'Quote Name is required' } });
                    return;
                }
    
                const quoteId = await updateQuote({
                    quoteData: this.quoteData,
                    quoteId: this.quoteId
                });
    
                this.quoteId = quoteId;
                await this.initializeDefaultValues();
                this.currentStep = '2';
                this.showSuccessToast();
    
            } catch (error) {
                console.error('Error during save and continue:', error);
                this.showErrorToast(error);
            }
        }
    
        async updateQuote() {
            try {
                this.saveFormValuesToQuoteData();
    
                if (!this.quoteData.Name || this.quoteData.Name.trim() === '') {
                    this.showErrorToast({ body: { message: 'Quote Name is required' } });
                    return;
                }
                if (!this.quoteData.Pricebook2Id) {
                    this.showErrorToast({ body: { message: 'Pricebook is not set for the Quote.' } });
                    return;
                }
                const quoteId = await updateQuote({
                    quoteData: this.quoteData,
                    quoteId: this.quoteId
                });
                this.quoteId = quoteId;
                this.showSuccessToast();
                this.dispatchEvent(new CustomEvent('success', { detail: quoteId }));
                this.closeModal();
            } catch (error) {
                this.showErrorToast(error);
            }
        }
    
        showSuccessToast() {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Quote updated successfully!',
                    variant: 'success'
                })
            );
        }
    
        showErrorToast(error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : 'An error occurred while saving the quote.',
                    variant: 'error'
                })
            );
        }
    
        goToStep3() {
    // Save Step 2 state in savedStep3State to preserve selections
    this.savedStep3State = {
        quoteItems: JSON.parse(JSON.stringify(this.quoteItems)),
        editedQuoteItems: JSON.parse(JSON.stringify(this.editedQuoteItems)),
        selectedQuoteLineItemsSet: new Set(this.selectedQuoteLineItemsSet),
        selectedAvailableProductsSet: new Set(this.selectedAvailableProductsSet),
        deselectedQuoteLineItemsSet: new Set(this.deselectedQuoteLineItemsSet),
        // Save deleted cloned items state
        deletedClonedItems: this.deletedClonedItems ? new Set(this.deletedClonedItems) : new Set()
    };
    
    // console.log('Saved Step 2 state in savedStep3State:', JSON.stringify(this.savedStep3State, null, 2));
    
    this.modalTitle = 'Edit Quote Line Items';
    this.isStep1 = false;
    this.isStep2 = false;
    this.isStep3 = true;
    this.updateHostDataAttribute();
    this.currentStep = '3';
    
    // console.log('Navigating to Step 3 - Current State:');
    // console.log('quoteItems:', JSON.stringify(this.quoteItems, null, 2));
    // console.log('editedQuoteItems:', JSON.stringify(this.editedQuoteItems, null, 2));
    // console.log('selectedQuoteLineItemsSet:', Array.from(this.selectedQuoteLineItemsSet));
    // console.log('selectedAvailableProductsSet:', Array.from(this.selectedAvailableProductsSet));
    // console.log('deselectedQuoteLineItemsSet:', Array.from(this.deselectedQuoteLineItemsSet));
    // console.log('deletedClonedItems:', this.deletedClonedItems ? Array.from(this.deletedClonedItems) : []);
    // console.log('savedStep3State:', JSON.stringify(this.savedStep3State, null, 2));
    // console.log('allQuoteLineItems at step 3 : ', JSON.stringify(this.allQuoteLineItems, null, 2));
    
    this.loadQuoteLineItems();
}
    
        updateHostDataAttribute() {
            if (this.isStep2) {
                this.template.host.setAttribute('data-step2', '');
            } else {
                this.template.host.removeAttribute('data-step2');
            }
        }
    
       submitQuote() {
        this.isLoading = true;
    
        // Validate description fields
        if (!this.validateDescriptions()) {
            this.isLoading = false;
            this.showNotification('Error', 'Description is required for all quote line items.', 'error');
            return;
        }
    
        if (!this.quoteId) {
            this.isLoading = false;
            this.showNotification('Error', 'No quote found. Please save the quote first.', 'error');
            return;
        }
        if (!this.quoteData.Pricebook2Id) {
            this.isLoading = false;
            this.showNotification('Error', 'Pricebook is not set for the Quote.', 'error');
            return;
        }
        if (this.quoteItems.length === 0) {
            this.isLoading = false;
            this.showNotification('Error', 'No quote line items to submit.', 'error');
            return;
        }
    
        const hasDiscountedItems = this.quoteItems.some(item => {
            const listPrice = parseFloat(item.listPrice);
            const proposedPrice = parseFloat(item.salesPrice);
            const discount = item.discount === '-' ? 0 : parseFloat(item.discount);
            const priceAfterDiscount = discount ? proposedPrice - (proposedPrice * (discount / 100)) : proposedPrice;
            return (
                !isNaN(listPrice) &&
                !isNaN(proposedPrice) &&
                !isNaN(discount) &&
                discount > 0 &&
                priceAfterDiscount < listPrice
            );
        });
    
        // const hasLumpSumDiscount = this.quoteData.Lump_Sum_Discount__c && parseFloat(this.quoteData.Lump_Sum_Discount__c) > 0;
        // const hasTargetProduct = this.quoteItems.some(item => item.Product2Id === LUMPSUM_DISCOUNT_PRODUCT);
    
        // if (hasDiscountedItems || hasLumpSumDiscount || hasTargetProduct) {
        //     this.isReviewModalOpen = true;
        //     this.isLoading = false;
        //     return;
        // }
    
        // Check for lump sum discount
        // const hasLumpSumDiscount = this.quoteData.Lump_Sum_Discount__c && parseFloat(this.quoteData.Lump_Sum_Discount__c) > 0;
    
        // Check for specific product using custom label
        //const hasTargetProduct = this.quoteItems.some(item => item.Product2Id === LUMPSUM_DISCOUNT_PRODUCT);
        //const hasTargetProductINR = this.quoteItems.some(item => item.Product2Id === Lumpsum_Discount_Product_INR);
    
        // Calculate total list price and total sales price
        let totalListPrice = 0;
        let totalSalesPrice = 0;
    
        this.quoteItems.forEach(item => {
            // Assuming these fields exist in your quoteItems
            if (item.listPrice) {
                totalListPrice += parseFloat(item.listPrice);
            }
            if (item.actualprice) {
                totalSalesPrice += parseFloat(item.actualprice);
            }
        });
    
        // Check if total list price is greater than total sales price
        const isNotProfitable = totalListPrice > totalSalesPrice;
        // Open review modal if any condition is met
        if (hasDiscountedItems || isNotProfitable) {
           this.isReviewModalOpen = true;
        //    console.log('pop-up comment', this.reviewComment);
this.isLoading = false;

// setTimeout(() => {
//     const textarea = this.template.querySelector('textarea#comment-textarea');
//     if (textarea) {
//         textarea.value = this.reviewComment;
//         console.log('Programmatically set textarea value:', this.reviewComment);
//     }
// }, 0);

            return;
        }
        this.processQuoteSubmission();
    }
    validateDescriptions() {
        let isValid = true;
    
        // Check quoteItems for empty or missing descriptions
        this.quoteItems.forEach((item, index) => {
            if (!item.productDescription || item.productDescription.trim() === '') {
                isValid = false;
                // Find the corresponding textarea if in edit mode
                const textarea = this.template.querySelector(`lightning-textarea[data-id="${item.id}"][data-field="productDescription"]`);
                if (textarea) {
                    textarea.setCustomValidity('Description is required.');
                    textarea.reportValidity();
                }
            } else {
                // Clear validity for valid fields
                const textarea = this.template.querySelector(`lightning-textarea[data-id="${item.id}"][data-field="productDescription"]`);
                if (textarea) {
                    textarea.setCustomValidity('');
                    textarea.reportValidity();
                }
            }
        });
    
        return isValid;
    }
    async processQuoteSubmission() {
    try {
        const hasChanges = (item) => {
            const initial = item.initialValues || {};
            return (
                parseFloat(item.salesPrice) !== parseFloat(initial.salesPrice) ||
                parseInt(item.quantity, 10) !== parseInt(initial.quantity, 10) ||
                (item.discount === '-' ? null : parseFloat(item.discount)) !== (initial.discount === '-' ? null : parseFloat(initial.discount)) ||
                (item.productDescription || '') !== (initial.productDescription || '') ||
                (item.productName || '') !== (initial.productName || '') ||
                item.order !== initial.order
            );
        };

        const allQuoteLineItemIds = new Set(this.allActualQuoteLineItems.map(item => item.Id));
        
        // Sort quoteItems by order property to ensure correct ordering
        const sortedQuoteItems = [...this.quoteItems].sort((a, b) => {
            return (parseInt(a.order, 10) || 0) - (parseInt(b.order, 10) || 0);
        });
        
        // Update the order numbers to be sequential
        sortedQuoteItems.forEach((item, index) => {
            item.order = index + 1;
        });

        const itemsToInsert = sortedQuoteItems
            .filter(item => 
                !this.deselectedQuoteLineItemsSet.has(item.id) &&
                (item.id.startsWith('CLONE_') || !allQuoteLineItemIds.has(item.id))
            )
            .map((item, index) => {
                const salesPrice = parseFloat(item.salesPrice) || 1;
                if (!item.PricebookEntryId || !item.PricebookEntryId.startsWith('01u')) {
                    throw new Error(`Invalid PricebookEntryId for product: ${item.productName}`);
                }
                const discount = item.discount === '-' ? null : parseFloat(item.discount);
                if (discount !== null && (isNaN(discount) || discount < 0 || discount > 100)) {
                    throw new Error(`Invalid discount for product: ${item.productName}. Discount must be between 0 and 100.`);
                }
                return {
                    QuoteId: this.quoteId,
                    Product2Id: item.Product2Id,
                    PricebookEntryId: item.PricebookEntryId,
                    productName: item.productName,
                    UnitPrice: salesPrice,
                    Quantity: parseInt(item.quantity, 10) || 1,
                    Discount: discount,
                    productDescription: item.productDescription || '',
                    orderNumber: item.order, // Using updated sequential order
                    isCloned: item.isCloned || false
                };
            });
        // console.log('step 3 quoteItems==>'+JSON.stringify(sortedQuoteItems));
        
        const itemsToUpdate = sortedQuoteItems
            .filter(item => 
                !item.id.startsWith('CLONE_') && 
                allQuoteLineItemIds.has(item.id) && 
                !this.deselectedQuoteLineItemsSet.has(item.id) && 
                (hasChanges(item) || true) && // Force update for ordering
                item.id && typeof item.id === 'string' && item.id.length === 18
            )
            .map((item, index) => {
                const salesPrice = parseFloat(item.salesPrice) || 1;
                const discount = item.discount === '-' ? null : parseFloat(item.discount);
                if (discount !== null && (isNaN(discount) || discount < 0 || discount > 100)) {
                    throw new Error(`Invalid discount for product: ${item.productName}. Discount must be between 0 and 100.`);
                }
                return {
                    Id: item.id,
                    QuoteId: this.quoteId,
                    Product2Id: item.Product2Id,
                    PricebookEntryId: item.PricebookEntryId,
                    productName: item.productName,
                    UnitPrice: salesPrice,
                    Quantity: parseInt(item.quantity, 10) || 1,
                    Discount: discount,
                    productDescription: item.productDescription || '',
                    orderNumber: item.order, // Using updated sequential order
                    isCloned: item.isCloned || false
                };
            });

        const quoteItemIds = new Set(sortedQuoteItems.map(item => item.id));
        const itemsToDelete = [
            ...this.allActualQuoteLineItems
                .filter(item => !quoteItemIds.has(item.Id))
                .map(item => item.Id),
            ...Array.from(this.deselectedQuoteLineItemsSet)
                .filter(id => !id.startsWith('CLONE_') && allQuoteLineItemIds.has(id))
        ].filter((id, index, self) => self.indexOf(id) === index);

        // console.log('=== Data Sent to syncQuoteLineItems ===');
        // console.log('itemsToInsert:', JSON.stringify(itemsToInsert, null, 2));
        // console.log('itemsToUpdate:', JSON.stringify(itemsToUpdate, null, 2));
        // console.log('itemsToDelete:', JSON.stringify(itemsToDelete, null, 2));
        // console.log('quoteId:', this.quoteId);

        await syncQuoteLineItems({
            quoteId: this.quoteId,
            itemsToInsert: itemsToInsert,
            itemsToUpdate: itemsToUpdate,
            itemsToDelete: itemsToDelete
        });

        this.showNotification('Success', 'Quote line items updated successfully.', 'success');
        this.isQuoteLineItemCreated = true;
        this.savedStep3State = null;
        this.closeModal();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.quoteId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    } catch (error) {
        this.isLoading = false;
        const errorMessage = this.reduceErrors(error);
        console.error('Error in processQuoteSubmission:', errorMessage, error);
        if (errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') && 
            errorMessage.includes('Proposed Price can not be less than List Price')) {
            let rowIndex = 0;
            const rowMatch = errorMessage.match(/row (\d+)/);
            if (rowMatch && rowMatch[1]) {
                rowIndex = parseInt(rowMatch[1], 10);
            }
            const productName = this.quoteItems[rowIndex]?.productName || 'Unknown Product';
                this.showNotification('Error', 
                    `Proposed Price cannot be less than List Price for product: ${productName}`, 
                    'error');
        } else {
            this.showNotification('Error', 'Failed to update quote line items: ' + errorMessage, 'error');
        }
    }
}
    
        async handleReviewCommentSubmit() {
            if (!this.reviewComment.trim()) {
                this.showNotification('Error', 'Please enter a review comment.', 'error');
                return;
            }
            this.isLoading = true;
            try {
                this.quoteData.Review_Requested_for__c = this.reviewComment;
                await updateQuote({
                    quoteData: {
                        ...this.quoteData,
                        Review_Requested_for__c: this.reviewComment
                    },
                    quoteId: this.quoteId
                });
                this.isReviewModalOpen = false;
                this.reviewComment = this.quoteData.Review_Requested_for__c;
                this.isLoaded = false; // Reset to allow re-rendering of styles
                await this.processQuoteSubmission();
            } catch (error) {
                this.isLoading = false;
                this.showNotification('Error', 'Failed to save root cause: ' + this.reduceErrors(error), 'error');
            }
        }
    
        handleReviewModalCancel() {
    this.isReviewModalOpen = false;
    //this.reviewComment = '';
    this.isLoading = false;
    this.isLoaded = false; // Reset to allow re-rendering of styles
}
    
        handleReviewCommentChange(event) {
            this.reviewComment = event.target.value;
        }
    
        saveFormValuesToQuoteData() {
            const form = this.template.querySelector('lightning-record-edit-form');
            if (form) {
                const inputFields = form.querySelectorAll('lightning-input-field');
                inputFields.forEach(field => {
                    const fieldName = field.fieldName;
                    const value = field.value;
                    if (value !== undefined && fieldName && fieldName !== 'OpportunityId' && fieldName !== 'Pricebook2Id') {
                        this.quoteData[fieldName] = value;
                    }
                });
            }
        }
    
     loadQuoteLineItems() {
    this.isLoading = true;

    // console.log('loadQuoteLineItems - Input State:');
    // console.log('allQuoteLineItems:', JSON.stringify(this.allQuoteLineItems, null, 2));
    // console.log('deselectedQuoteLineItemsSet:', Array.from(this.deselectedQuoteLineItemsSet));
    // console.log('selectedAvailableProductsSet:', Array.from(this.selectedAvailableProductsSet));
    // console.log('editedQuoteItems:', JSON.stringify(this.editedQuoteItems, null, 2));
    // console.log('deletedClonedItems:', this.deletedClonedItems ? Array.from(this.deletedClonedItems) : []);

    // Create a map of user-edited order values to preserve sort order on navigation
    const userEditedOrderMap = new Map();
    this.editedQuoteItems.forEach(item => {
        if (item.order) {
            userEditedOrderMap.set(item.id, item.order);
        }
    });

    const buildQuoteItem = (item, editedItem, index, sourceItem, isOpportunityLineItem = false, isCloned = false) => {
        const isNonOliQuoteLineItem = item.IsNonOliQuoteLineItem || false;
        const pricebookEntryId = item.PricebookEntryId || (sourceItem?.Id && sourceItem.Id.startsWith('01u') ? sourceItem.Id : null);
        const salesPrice = (isNonOliQuoteLineItem || isCloned) && !editedItem
            ? (item.UnitPrice || item.ListPrice || 1)
            : (editedItem ? (parseFloat(editedItem.salesPrice) || item.UnitPrice || item.ListPrice || 1) : (item.UnitPrice || item.ListPrice || 1));
        const quantity = (isNonOliQuoteLineItem || isCloned) && !editedItem
            ? (item.Quantity != null ? item.Quantity : 1)
            : (editedItem ? editedItem.quantity : (item.Quantity != null ? item.Quantity : 1));
        const discount = (isNonOliQuoteLineItem || isCloned) && !editedItem
            ? (item.Discount != null ? item.Discount : null)
            : (editedItem ? editedItem.discount : item.Discount != null ? item.Discount : null);

        // Determine ListPrice for cloned items
        let listPrice;
        if (isCloned && editedItem) {
            const sourceProduct = this.allAvailableProducts.find(p => p.Product2Id === editedItem.Product2Id) ||
                                 this.allQuoteLineItems.find(q => q.Product2Id === editedItem.Product2Id) ||
                                 this.allActualQuoteLineItems.find(q => q.Product2Id === editedItem.Product2Id);
            listPrice = sourceProduct ? (sourceProduct.ListPrice || sourceProduct.UnitPrice || 0) : (item.ListPrice || item.UnitPrice || 0);
        } else {
            listPrice = item.ListPrice || item.UnitPrice || 0;
        }

        if (!pricebookEntryId || !pricebookEntryId.startsWith('01u')) {
            console.warn(`Invalid PricebookEntryId for item ${item.Id || item.id}: ${pricebookEntryId}`);
            this.showNotification('Warning', `Invalid PricebookEntryId for product: ${item.ProductName || 'Unknown'}.`, 'warning');
        }

        const itemId = item.Id || editedItem?.id || item.id;
        const userEditedOrder = userEditedOrderMap.get(itemId);
        const itemOrder = userEditedOrder || 
                         (editedItem ? editedItem.order : (item.SortOrder || index + 1));

        return {
            id: itemId,
            productName: editedItem ? editedItem.productName : item.ProductName || item.Product_Name__c || '',
            productDescription: editedItem ? editedItem.productDescription : item.ProductDescription || item.Product_Description__c || '',
            listPrice: listPrice,
            salesPrice: salesPrice,
            quantity: quantity,
            currency: this.quoteData.CurrencyIsoCode || 'USD',
            discount: discount != null ? discount.toString() : '-',
            actualprice: this.calculateActualPrice(salesPrice, discount),
            totalPrice: this.calculateTotalPrice(salesPrice, discount, quantity),
            isEditingProductName: false,
            isEditingProductDescription: false,
            isEditingSalesPrice: false,
            isEditingQuantity: false,
            isEditingDiscount: false,
            isDropdownOpen: false,
            PricebookEntryId: pricebookEntryId,
            Product2Id: editedItem ? editedItem.Product2Id : item.Product2Id,
            order: itemOrder,
            isCloned: isCloned || (editedItem?.isCloned || false),
            initialValues: {
                productName: editedItem ? editedItem.productName : item.ProductName || item.Product_Name__c || '',
                productDescription: editedItem ? editedItem.productDescription : item.ProductDescription || item.Product_Description__c || '',
                salesPrice: salesPrice,
                quantity: quantity,
                discount: discount != null ? discount.toString() : '-',
                order: itemOrder
            }
        };
    };

    const editedItemsMap = new Map(this.editedQuoteItems.map(item => [item.id, item]));
    let allItems = [];

    // Step 1: Process existing Quote Line Items (saved in database, non-Opportunity Line Items)
    const existingQuoteLineItems = this.allQuoteLineItems
        .filter(item => !item.IsOpportunityLineItem && !this.deselectedQuoteLineItemsSet.has(item.Id) && !(this.deletedClonedItems && this.deletedClonedItems.has(item.Id)))
        .map((item, index) => {
            const editedItem = editedItemsMap.get(item.Id);
            const isCloned = item.Is_Cloned__c || false;
            return buildQuoteItem(item, editedItem, index, item, false, isCloned);
        });

    // console.log('existingQuoteLineItems after binding:', JSON.stringify(existingQuoteLineItems, null, 2));

    // Step 2: Process new Available Products (not yet saved)
    const newAvailableProducts = Array.from(this.selectedAvailableProductsSet)
        .map(id => this.allAvailableProducts.find(product => product.Id === id))
        .filter(product => product && !this.deselectedQuoteLineItemsSet.has(product.Id) && !product.Is_Cloned__c && !(this.deletedClonedItems && this.deletedClonedItems.has(product.Id)))
        .map((product, index) => {
            const editedItem = editedItemsMap.get(product.Id);
            return buildQuoteItem(product, editedItem, existingQuoteLineItems.length + index, product, false, false);
        });

    // console.log('newAvailableProducts after binding:', JSON.stringify(newAvailableProducts, null, 2));

    // Step 3: Process Opportunity Line Items (to be appended at the end)
    const opportunityLineItems = this.allQuoteLineItems
        .filter(item => item.IsOpportunityLineItem && !this.deselectedQuoteLineItemsSet.has(item.Id) && !(this.deletedClonedItems && this.deletedClonedItems.has(item.Id)))
        .map((item, index) => {
            const editedItem = editedItemsMap.get(item.Id);
            return buildQuoteItem(item, editedItem, existingQuoteLineItems.length + newAvailableProducts.length + index, item, true, false);
        });

    // console.log('opportunityLineItems after binding:', JSON.stringify(opportunityLineItems, null, 2));

    // Step 4: Process client-side cloned items (not yet saved)
    const clonedItems = this.editedQuoteItems
        .filter(item => item.id.startsWith('CLONE_') && !this.deselectedQuoteLineItemsSet.has(item.id) && !(this.deletedClonedItems && this.deletedClonedItems.has(item.id)))
        .map((item, index) => {
            const sourceItem = this.allAvailableProducts.find(p => p.Product2Id === item.Product2Id) ||
                              this.allQuoteLineItems.find(q => q.Id === item.id) ||
                              this.allActualQuoteLineItems.find(q => q.Product2Id === item.Product2Id);
            return buildQuoteItem(item, item, existingQuoteLineItems.length + newAvailableProducts.length + opportunityLineItems.length + index, sourceItem, false, true);
        });

    // console.log('clonedItems after binding:', JSON.stringify(clonedItems, null, 2));

    // Step 5: Combine all items in the desired order
    allItems = [
        ...existingQuoteLineItems,   // Existing non-OLI Quote Line Items
        ...newAvailableProducts,     // New products from Pricebook
        ...opportunityLineItems,     // Opportunity Line Items (appended)
        ...clonedItems               // Cloned items
    ];

    // console.log('allItems before deduplication:', JSON.stringify(allItems, null, 2));

    // Step 6: Deduplicate non-cloned items by Product2Id, include all cloned items
    const uniqueItems = [];
    const seenProduct2Ids = new Set();

    // Sort all items by their order property before deduplication
    allItems.sort((a, b) => {
        return a.order - b.order;
    });

    // Add items to uniqueItems, respecting deduplication rules
    allItems.forEach(item => {
        if (item.isCloned) {
            uniqueItems.push(item);
        } else if (!seenProduct2Ids.has(item.Product2Id)) {
            uniqueItems.push(item);
            seenProduct2Ids.add(item.Product2Id);
        }
    });

    // console.log('uniqueItems after deduplication:', JSON.stringify(uniqueItems, null, 2));

    // Step 7: Reassign order property (1-based indexing) to ensure contiguous ordering
    uniqueItems.forEach((item, index) => {
        item.order = index + 1;
        item.initialValues.order = index + 1;
    });

    // Step 8: Update quoteItems and editedQuoteItems
    this.quoteItems = uniqueItems;
    this.editedQuoteItems = uniqueItems.map(item => ({
        id: item.id,
        productName: item.productName,
        productDescription: item.productDescription,
        salesPrice: item.salesPrice,
        quantity: item.quantity,
        discount: item.discount,
        order: item.order,
        Product2Id: item.Product2Id,
        PricebookEntryId: item.PricebookEntryId,
        sortOrder: item.sortOrder,
        isCloned: item.isCloned
    }));

    // console.log('Final quoteItems:', JSON.stringify(this.quoteItems, null, 2));
    // console.log('Final editedQuoteItems:', JSON.stringify(this.editedQuoteItems, null, 2));

    this.noData = uniqueItems.length === 0;
    this.calculateTotalQuotePrice();
    this.isLoading = false;

    this.savedStep3State = null;

    // Refresh actual Quote Line Items in background
    this.loadInitialActualQuoteLineItems();
}

    
        async loadInitialActualQuoteLineItems() {
            try {
                const result = await getQuoteLineItems({ quoteId: this.quoteId });
                this.allActualQuoteLineItems = this.transformQuoteLineItemData(result);
            } catch (error) {
                console.error('Error loading actual Quote Line Items:', error);
            }
        }
    
        moveUp(event) {
            const itemId = event.target.dataset.id;
            const index = this.quoteItems.findIndex(item => item.id === itemId);
            if (index <= 0) return;
    
            this.isLoading = true;

            // console.log('Before Swapping : ' + JSON.stringify(this.quoteItems));
            
    
            const updatedItems = [...this.quoteItems];
            const temp = updatedItems[index];
            updatedItems[index] = updatedItems[index - 1];
            updatedItems[index - 1] = temp;
    
            updatedItems[index].order = index + 1;
            updatedItems[index - 1].order = index;
    
            this.quoteItems = updatedItems;

            // console.log('After Swapping : ' + JSON.stringify(this.quoteItems));
    
            this.editedQuoteItems = this.quoteItems.map(item => ({
                id: item.id,
                productName: item.productName,
                productDescription: item.productDescription,
                salesPrice: item.salesPrice,
                quantity: item.quantity,
                discount: item.discount,
                order: item.order,
                Product2Id: item.Product2Id,
                PricebookEntryId: item.PricebookEntryId,
                isCloned: item.isCloned || false // Include isCloned
            }));

    
            this.isLoading = false;
        }
    
        moveDown(event) {
            const itemId = event.target.dataset.id;
            const index = this.quoteItems.findIndex(item => item.id === itemId);
            if (index >= this.quoteItems.length - 1) return;
    
            this.isLoading = true;
    
            const updatedItems = [...this.quoteItems];
            const temp = updatedItems[index];
            updatedItems[index] = updatedItems[index + 1];
            updatedItems[index + 1] = temp;
    
            updatedItems[index].order = index + 1;
            updatedItems[index + 1].order = index + 2;
    
            this.quoteItems = updatedItems;
    
            this.editedQuoteItems = this.quoteItems.map(item => ({
                id: item.id,
                productName: item.productName,
                productDescription: item.productDescription,
                salesPrice: item.salesPrice,
                quantity: item.quantity,
                discount: item.discount,
                order: item.order,
                Product2Id: item.Product2Id,
                PricebookEntryId: item.PricebookEntryId,
                isCloned: item.isCloned || false // Include isCloned
            }));
    
            this.isLoading = false;
        }
    
       handleInputChange(event) {
    const field = event.target.dataset.field;
    const id = event.target.dataset.id;
    let value = event.target.value;

    if (field === 'quantity') {
        // Allow empty input temporarily to avoid blocking typing
        if (value === '') {
            value = '';
        } else {
            // Parse the input as an integer
            const parsedValue = parseInt(value, 10);
            // Check if the input is a valid positive integer
            if (isNaN(parsedValue) || !/^\d+$/.test(value)) {
                this.showNotification('Error', 'Quantity must be a valid positive integer.', 'error');
                value = this.quoteItems.find(item => item.id === id)?.quantity || '1';
            } else if (parsedValue <= 0) {
                this.showNotification('Warning', 'Quantity must be at least 1.', 'warning');
                value = '1';
            } else {
                value = parsedValue.toString(); // Ensure it's a string for consistency
            }
        }
    } else if (field === 'salesPrice') {
        // Existing salesPrice logic (unchanged)
        if (value === '') {
            value = '';
        } else {
            let validValue = value.match(/^-?\d+(\.\d{0,2})?$/);
            if (!validValue) {
                this.showNotification('Error', 'Invalid sales price. Please enter a valid number.', 'error');
                return;
            }
            value = validValue[0];
        }
    } else if (field === 'discount') {
        // Existing discount logic (unchanged)
        if (value === '' || value === '-') {
            value = '-';
        } else {
            let validValue = value.match(/^-?\d+(\.\d{0,2})?$/);
            if (!validValue) {
                this.showNotification('Error', 'Invalid discount. Please enter a valid number.', 'error');
                return;
            }
            value = validValue[0];
            if (parseFloat(value) < 0 || parseFloat(value) > 100) {
                this.showNotification('Error', 'Discount must be between 0 and 100.', 'error');
                return;
            }
        }
    }

    const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
    if (quoteItemIndex !== -1) {
        const updatedItem = { ...this.quoteItems[quoteItemIndex], [field]: value };

        if (field === 'salesPrice' || field === 'discount' || field === 'quantity') {
            updatedItem.totalPrice = this.calculateTotalPrice(
                updatedItem.salesPrice,
                updatedItem.discount === '-' ? null : updatedItem.discount,
                updatedItem.quantity
            );
            updatedItem.actualprice = this.calculateActualPrice(
                updatedItem.salesPrice,
                updatedItem.discount === '-' ? null : updatedItem.discount
            );
        }

        this.quoteItems = [
            ...this.quoteItems.slice(0, quoteItemIndex),
            updatedItem,
            ...this.quoteItems.slice(quoteItemIndex + 1)
        ];

        const editedItemIndex = this.editedQuoteItems.findIndex(item => item.id === id);
        const updatedEditedItem = {
            id,
            productName: updatedItem.productName,
            productDescription: updatedItem.productDescription,
            salesPrice: updatedItem.salesPrice,
            quantity: updatedItem.quantity,
            discount: updatedItem.discount,
            order: updatedItem.order,
            Product2Id: updatedItem.Product2Id,
            PricebookEntryId: updatedItem.PricebookEntryId,
            isCloned: updatedItem.isCloned || false
        };

        if (editedItemIndex !== -1) {
            this.editedQuoteItems = [
                ...this.editedQuoteItems.slice(0, editedItemIndex),
                updatedEditedItem,
                ...this.editedQuoteItems.slice(editedItemIndex + 1)
            ];
        } else {
            this.editedQuoteItems = [...this.editedQuoteItems, updatedEditedItem];
        }

        this.calculateTotalQuotePrice();

        // Update the input field value in real-time if necessary
        if (field === 'quantity' && value !== event.target.value) {
            setTimeout(() => {
                const inputElement = this.template.querySelector(`lightning-input[data-id="${id}"][data-field="${field}"]`);
                if (inputElement) {
                    inputElement.value = value;
                }
            }, 0);
        }
    }
}
    
        toggleEditMode(event) {
            // console.log('event');
            const field = event.target.dataset.field;
            const id = event.target.dataset.id;
            const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
            
            if (quoteItemIndex !== -1) {
                // Only toggle if we're not already editing this field (prevents toggling off when clicking on input)
                if (!this.quoteItems[quoteItemIndex][`isEditing${field.charAt(0).toUpperCase() + field.slice(1)}`]) {
                    this.quoteItems[quoteItemIndex] = {
                        ...this.quoteItems[quoteItemIndex],
                        discount: this.quoteItems[quoteItemIndex].discount === '' ? '-' : this.quoteItems[quoteItemIndex].discount,
                        quantity: this.quoteItems[quoteItemIndex].quantity === '' ? '0' : this.quoteItems[quoteItemIndex].quantity,
                        salesPrice: this.quoteItems[quoteItemIndex].salesPrice === '' ? '0' : this.quoteItems[quoteItemIndex].salesPrice,
                        [`isEditing${field.charAt(0).toUpperCase() + field.slice(1)}`]: true
                    };
                    this.quoteItems = [...this.quoteItems]; // Trigger reactivity
                    
                    // Schedule focus on the newly created input field
                    setTimeout(() => {
                        const inputElement = this.template.querySelector(`lightning-input[data-id="${id}"][data-field="${field}"], lightning-textarea[data-id="${id}"][data-field="${field}"]`);
                        if (inputElement) {
                            inputElement.focus();
                        }
                    }, 0);
                }
            }
        }
       handleInputBlur(event) {
    const field = event.target.dataset.field;
    const id = event.target.dataset.id;
    const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
    
    if (quoteItemIndex !== -1) {
        let updatedItem = { ...this.quoteItems[quoteItemIndex] };
        
        // Handle quantity field on blur
        if (field === 'quantity') {
            let value = event.target.value.trim();
            // If the field is empty or contains 0, set it to 1
            if (value === '' || parseInt(value, 10) === 0) {
                updatedItem.quantity = '1';
                this.showNotification('Info', 'Quantity set to 1.', 'info');
            }
        }
        // Handle salesPrice field on blur
        else if (field === 'salesPrice') {
            let value = event.target.value.trim();
            // If the field is empty, set it to 0
            if (value === '') {
                updatedItem.salesPrice = '0';
                // this.showNotification('Info', 'Sales price set to 0.', 'info');
            }
        }
        
        // Update editing state
        updatedItem[`isEditing${field.charAt(0).toUpperCase() + field.slice(1)}`] = false;
        
        // Update the quoteItems array
        this.quoteItems[quoteItemIndex] = updatedItem;
        this.quoteItems = [...this.quoteItems]; // Trigger reactivity
    }
}
    
        handleClone(event) {
    this.isLoading = true;
    const itemId = event.target.dataset.id;

    // Check if itemId is valid before trying to find it
    if (!itemId) {
        this.isLoading = false;
        this.showNotification('Error', 'Couldn’t find that item, Please check and try again.', 'error');
        return;
    }

    // Add a small delay to ensure DOM updates have propagated
    setTimeout(() => {
        // Find the item in the array - be more defensive in checking
        const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
        
        if (itemIndex === -1) {
            console.error('Quote line item not found:', itemId);
            console.log('Available items:', JSON.stringify(this.quoteItems.map(item => item.id)));
            this.isLoading = false;
            this.showNotification('Error', 'Quote line item not found.', 'error');
            return;
        }
        
        const originalItem = this.quoteItems[itemIndex];
        const newId = this.generateUniqueId();
        
        const clonedItem = {
            ...originalItem,
            id: newId,
            isEditingProductName: false,
            isEditingProductDescription: false,
            isEditingSalesPrice: false,
            isEditingQuantity: false,
            isEditingDiscount: false,
            isDropdownOpen: false,
            order: itemIndex + 2,
            isCloned: true, // Mark as cloned
            initialValues: {
                productName: originalItem.productName,
                productDescription: originalItem.productDescription,
                salesPrice: originalItem.salesPrice,
                quantity: originalItem.quantity,
                discount: originalItem.discount,
                order: itemIndex + 2
            }
        };
        
        // Create a new copy of the array to avoid mutation issues
        const updatedQuoteItems = [...this.quoteItems];
        
        // Insert the cloned item at the right position
        updatedQuoteItems.splice(itemIndex + 1, 0, clonedItem);
        
        // Update orders for subsequent items
        for (let i = itemIndex + 2; i < updatedQuoteItems.length; i++) {
            updatedQuoteItems[i] = {
                ...updatedQuoteItems[i],
                order: i + 1,
                initialValues: { 
                    ...updatedQuoteItems[i].initialValues, 
                    order: i + 1 
                }
            };
        }
        
        // Update the quote items
        this.quoteItems = updatedQuoteItems;
        
        // Add to editedQuoteItems
        this.editedQuoteItems = [
            ...this.editedQuoteItems,
            {
                id: newId,
                productName: clonedItem.productName,
                productDescription: clonedItem.productDescription,
                salesPrice: clonedItem.salesPrice,
                quantity: clonedItem.quantity,
                discount: clonedItem.discount,
                order: clonedItem.order,
                Product2Id: clonedItem.Product2Id,
                PricebookEntryId: clonedItem.PricebookEntryId,
                isCloned: true // Mark as cloned
            }
        ];
        
        this.noData = false;
        this.closeAllDropdowns();
        this.calculateTotalQuotePrice();
        this.isLoading = false;
        this.showNotification('Success', 'Quote line item cloned successfully.', 'success');
    }, 50); // Small delay to ensure DOM is updated
}
    
    async handleDelete(event) {
        this.isLoading = true;
        const itemId = event.target.dataset.id;
        const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
        if (itemIndex === -1) {
            this.isLoading = false;
            this.showNotification('Error', 'Quote line item not found.', 'error');
            return;
        }
        this.deselectedQuoteLineItemsSet.add(itemId);
        this.selectedQuoteLineItemsSet.delete(itemId);
        this.selectedAvailableProductsSet.delete(itemId);
        // Remove the item
        this.quoteItems.splice(itemIndex, 1);
        // Update order of remaining items without modifying initialValues.order
        this.quoteItems = this.quoteItems.map((item, idx) => ({
            ...item,
            order: idx + 1
        }));
        // Update editedQuoteItems to reflect new order
        this.editedQuoteItems = this.quoteItems.map(item => ({
            id: item.id,
            productName: item.productName,
            productDescription: item.productDescription,
            salesPrice: item.salesPrice,
            quantity: item.quantity,
            discount: item.discount,
            order: item.order,
            Product2Id: item.Product2Id,
            PricebookEntryId: item.PricebookEntryId,
            isCloned: item.isCloned || false
        }));
        if (this.quoteItems.length === 0) {
            this.noData = true;
        }
        this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet);
        this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
        this.closeAllDropdowns();
        this.calculateTotalQuotePrice();
        this.isLoading = false;
        this.showNotification('Success', 'Quote line item deleted successfully.', 'success');
    }
    
        generateUniqueId() {
            return 'CLONE_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        }
    
        calculateActualPrice(salesPrice, discount) {
            const parsedSalesPrice = parseFloat(salesPrice);
            const parsedDiscount = discount === '-' || discount == null ? null : parseFloat(discount);
            if (!parsedSalesPrice || isNaN(parsedSalesPrice)) return 0.00;
            if (!parsedDiscount) return parsedSalesPrice.toFixed(2);
            return (parsedSalesPrice - (parsedSalesPrice * (parsedDiscount / 100))).toFixed(2);
        }
    
        calculateTotalPrice(salesPrice, discount, quantity) {
            const parsedSalesPrice = parseFloat(salesPrice);
            const parsedDiscount = discount === '-' || discount == null ? null : parseFloat(discount);
            const parsedQuantity = parseFloat(quantity) || 0;
            if (!parsedSalesPrice || isNaN(parsedSalesPrice) || !parsedQuantity) return 0.00;
            if (parsedDiscount) {
                return ((parsedSalesPrice - (parsedSalesPrice * (parsedDiscount / 100))) * parsedQuantity).toFixed(2);
            }
            return (parsedSalesPrice * parsedQuantity).toFixed(2);
        }
    
        showNotification(title, message, variant) {
            const evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            });
            this.dispatchEvent(evt);
        }
    
        toggleDropdown(event) {
            event.stopPropagation();
            const itemId = event.target.dataset.id;
            const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
            this.quoteItems.forEach(ele => {
                ele.isDropdownOpen = false;
            });
            if (itemIndex !== -1) {
                this.quoteItems[itemIndex].isDropdownOpen = !this.quoteItems[itemIndex].isDropdownOpen;
            }
        }
    
        closeDropdowns(event) {
            const dropdowns = this.template.querySelectorAll('.slds-dropdown_right');
            dropdowns.forEach(ele => {
                if (!ele.contains(event.target)) {
                    this.closeAllDropdowns();
                }
            });
        }
    
        closeAllDropdowns() {
            this.quoteItems = this.quoteItems.map(qli => {
                return { ...qli, isDropdownOpen: false };
            });
        }
    
 async loadInitialQuoteLineItems() {
    if (!this.quoteId || !this.quoteData.OpportunityId) {
        console.warn('No quoteId or OpportunityId available for fetching line items');
        this.showToast('Warning', 'Quote ID or Opportunity ID is missing. Cannot load line items.', 'warning');
        this.quoteLineItems = [];
        this.allQuoteLineItems = [];
        this.isLoading = false;
        return;
    }
    this.isLoading = true;
    try {
        const [quoteLineItems, oppLineItems] = await Promise.all([
            getQuoteLineItems({ quoteId: this.quoteId }),
            getAllOpportunityLineItems({ opportunityId: this.quoteData.OpportunityId })
        ]);
        // console.log('Quote Line Items Size:', quoteLineItems.length);
        // console.log('Quote Line Items Response:', JSON.stringify(quoteLineItems, null, 2));
        // console.log('Opportunity Line Items Response:', JSON.stringify(oppLineItems, null, 2));

        // Process opportunity line items without applying quote line item changes
        const processedOppLineItems = this.transformLineItemData(oppLineItems, true).map(item => ({
            ...item,
            IsOpportunityLineItem: true
        }));
        
        // Split Quote Line Items into originals and clones
        // Cloned products have no relation with 2nd screen and only appear in 3rd screen
        const originalQuoteLineItems = quoteLineItems.filter(item => !item.Is_Cloned__c);
        const clonedQuoteLineItems = quoteLineItems.filter(item => item.Is_Cloned__c);
        
        // Create a map of Product2Id to original Quote Line Item
        // Explicitly exclude cloned products from this mapping
        const originalQuoteLineItemMap = new Map();
        originalQuoteLineItems.forEach(qli => {
            originalQuoteLineItemMap.set(qli.Product2Id, qli);
        });
        
        // Process original OLIs with quote changes
        const oppLineItemsWithQuoteChanges = oppLineItems.map(oli => {
            const matchingQLI = originalQuoteLineItemMap.get(oli.Product2Id);
            const oliCopy = { ...oli };
            
            if (matchingQLI) {
                // console.log(`Found matching original QLI for product ${oli.Product2Id}`);
                // Copy ALL relevant fields from quote line item to ensure we show quote values
                if (matchingQLI.Quantity != null) oliCopy.Quantity = matchingQLI.Quantity;
                if (matchingQLI.UnitPrice != null) oliCopy.UnitPrice = matchingQLI.UnitPrice;
                if (matchingQLI.Discount != null) oliCopy.Discount = matchingQLI.Discount;
                
                // Ensure product name and description are taken from Quote Line Item
                oliCopy.Product_Name__c = matchingQLI.Product_Name__c || oliCopy.Product_Name__c;
                oliCopy.Product_Description__c = matchingQLI.Product_Description__c || oliCopy.Product_Description__c;
                
                // Add a flag to indicate this has quote line item data
                oliCopy.HasQuoteLineItemData = true;
            }
            
            return oliCopy;
        });
        
        // Transform OLIs with quote changes - this is what will be shown in the 3rd screen
        const transformedOppLineItems = this.transformLineItemData(oppLineItemsWithQuoteChanges, false).map(item => ({
            ...item,
            SortOrder: originalQuoteLineItemMap.get(item.Product2Id)?.SortOrder,
            IsOpportunityLineItem: true,
            // Preserve the flag for UI rendering decisions
            HasQuoteLineItemData: item.HasQuoteLineItemData || false
        }));
        
        // Create a set of existing product IDs from opportunity line items
        const existingProductIds = new Set(oppLineItems.map(item => item.Product2Id));
        
        // Process cloned items independently - completely separate from opportunity line items
        // These only appear in the 3rd screen and have NO relation to the 2nd screen
        const transformedClonedItems = this.transformLineItemData(clonedQuoteLineItems, false).map(item => ({
            ...item,
            IsOpportunityLineItem: false,
            IsNonOliQuoteLineItem: true,
            Is_Cloned__c: true,
            // Cloned items always have quote data since they only exist in quotes
            HasQuoteLineItemData: true
        }));
        
        // Process any additional non-OLI items that aren't clones
        const nonOliNonClonedItems = originalQuoteLineItems.filter(
            item => !processedOppLineItems.some(oli => oli.Product2Id === item.Product2Id)
        );
        
        const transformedNonOliItems = this.transformLineItemData(nonOliNonClonedItems, false).map(item => ({
            ...item,
            IsOpportunityLineItem: false,
            IsNonOliQuoteLineItem: true,
            // These are pure quote line items
            HasQuoteLineItemData: true
        }));
        
        // Identify Quote Product IDs - exclude cloned products as they have no relation to 2nd screen
        const quoteProductIds = new Set(originalQuoteLineItems.map(item => item.Product2Id));
        
        // For the 2nd screen, we want to show opportunity line items ONLY
        // Cloned products should NOT appear in the 2nd screen
        this.quoteLineItems = processedOppLineItems;
        this.filteredQuoteLineItems = processedOppLineItems;
        
        // For the 3rd screen, combine all items with quote line item data prioritized
        // Cloned products are handled completely separately and always appear in the 3rd screen only
        this.allQuoteLineItems = [
            ...transformedOppLineItems,  // Original items with quote changes
            ...transformedClonedItems,   // Cloned items - always in 3rd screen, no relation to 2nd screen
            ...transformedNonOliItems    // Additional non-OLI items
        ];
        
        // console.log('Transformed OLIs:', JSON.stringify(transformedOppLineItems));
        // console.log('Transformed Cloned Items:', JSON.stringify(transformedClonedItems));
        // console.log('Transformed Non-OLI Items:', JSON.stringify(transformedNonOliItems));
        // console.log('All Quote Line Items:', JSON.stringify(this.allQuoteLineItems));
        
        // Set quoteLineItemIds
        this.quoteLineItemIds = new Set(processedOppLineItems.map(item => item.Product2Id));

        // Initialize selection sets
        const previousDeselected = new Set(this.deselectedQuoteLineItemsSet);
        
        // Handle selections for original OLI items
        this.selectedQuoteLineItemsSet = new Set(
            processedOppLineItems
                .filter(item => quoteProductIds.has(item.Product2Id) && !previousDeselected.has(item.Id))
                .map(item => item.Id)
        );
        
        this.deselectedQuoteLineItemsSet = new Set([
            ...previousDeselected,
            ...processedOppLineItems
                .filter(item => !quoteProductIds.has(item.Product2Id))
                .map(item => item.Id)
        ]);

        // Pre-select all non-OLI QLIs and cloned items unless explicitly deselected
        const nonOliAndClonedItems = [...transformedNonOliItems, ...transformedClonedItems];
        this.selectedAvailableProductsSet = new Set([
            ...this.selectedAvailableProductsSet,
            ...nonOliAndClonedItems
                .filter(item => !previousDeselected.has(item.Id))
                .map(item => item.Id)
        ]);

        // Always select cloned items
        transformedClonedItems.forEach(item => {
            this.deselectedQuoteLineItemsSet.delete(item.Id);
            this.selectedAvailableProductsSet.add(item.Id);
        });

        this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet);
        this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);

        this.hasLoadedAllQuoteLineItems = true;
        this.enableQuoteLineItemLoadMore = processedOppLineItems.length >= this.quoteLineItemRowLimit;
        // console.log('Selected Line Items Set after load:', JSON.stringify(Array.from(this.selectedQuoteLineItemsSet)));
        // console.log('Deselected Line Items Set after load:', JSON.stringify(Array.from(this.deselectedQuoteLineItemsSet)));
        // console.log('Selected Available Products Set after load:', JSON.stringify(Array.from(this.selectedAvailableProductsSet)));
    } catch (error) {
        console.error('Error loading line items:', error);
        this.showToast('Error', 'Error loading Quote and Opportunity Line Items: ' + this.reduceErrors(error), 'error');
        this.quoteLineItems = [];
        this.allQuoteLineItems = [];
    } finally {
        this.isLoading = false;
    }
}
    
        loadMoreQuoteLineItemData(event) {
            if (this.isSearching) return;
    
            const target = event.target;
            target.isLoading = true;
    
            this.quoteLineItemRowOffSet += this.quoteLineItemRowLimit;
    
            Promise.all([
                getQuoteLineItems({ quoteId: this.quoteId }),
                getAllOpportunityLineItems({ opportunityId: this.quoteData.OpportunityId })
            ])
                .then(([quoteLineItems, oppLineItems]) => {
                    const quoteProductIds = new Set(quoteLineItems.map(item => item.Product2Id));
    
                    const transformedQuoteLineItems = this.transformLineItemData(quoteLineItems, false)
                        .map(item => ({ ...item, IsOpportunityLineItem: false }))
                        .slice(this.quoteLineItemRowOffSet, this.quoteLineItemRowOffSet + this.quoteLineItemRowLimit);
    
                    const uniqueOppLineItems = oppLineItems.filter(item => !quoteProductIds.has(item.Product2Id));
                    const transformedOppLineItems = this.transformLineItemData(uniqueOppLineItems, true)
                        .map(item => ({ ...item, IsOpportunityLineItem: true }))
                        .slice(this.quoteLineItemRowOffSet, this.quoteLineItemRowOffSet + this.quoteLineItemRowLimit);
    
                    const newRecords = [...transformedQuoteLineItems, ...transformedOppLineItems];
                    const moreDataAvailable = newRecords.length === this.quoteLineItemRowLimit;
    
                    if (newRecords.length > 0) {
                        const uniqueItemsMap = new Map();
    
                        this.allQuoteLineItems.forEach(item => {
                            uniqueItemsMap.set(item.Id, item);
                        });
    
                        newRecords.forEach(item => {
                            uniqueItemsMap.set(item.Id, item);
                            if (!this.deselectedQuoteLineItemsSet.has(item.Id)) {
                                if (!item.IsOpportunityLineItem) {
                                    this.selectedQuoteLineItemsSet.add(item.Id);
                                } else {
                                    this.deselectedQuoteLineItemsSet.add(item.Id);
                                }
                            }
                            // Ensure cloned items are selected
                            if (item.Is_Cloned__c) {
                                this.deselectedQuoteLineItemsSet.delete(item.Id);
                                this.selectedAvailableProductsSet.add(item.Id);
                            }
                        });
    
                        this.allQuoteLineItems = Array.from(uniqueItemsMap.values());
    
                        this.quoteLineItemIds = new Set(
                            this.allQuoteLineItems.map(item => item.Product2Id)
                        );
    
                        if (this.searchKey) {
                            this.filterProducts();
                        } else {
                            this.quoteLineItems = [...this.allQuoteLineItems];
                            this.filteredQuoteLineItems = [...this.allQuoteLineItems];
                        }
    
                        this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet);
                    }
    
                    target.enableInfiniteLoading = moreDataAvailable;
                    this.enableQuoteLineItemLoadMore = moreDataAvailable;
                    target.isLoading = false;
                })
                .catch(error => {
                    this.showToast('Error', 'Error loading more line items: ' + this.reduceErrors(error), 'error');
                    target.isLoading = false;
                });
        }
    
        async loadInitialAvailableProducts() {
            if (!this.quoteData.Pricebook2Id) {
                console.warn('No Pricebook2Id available for fetching products');
                this.showToast('Warning', 'Pricebook ID is missing. Cannot load available products.', 'warning');
                this.availableProducts = [];
                this.isLoading = false;
                return;
            }
            this.isLoading = true;
            try {
                // Fetch Opportunity Line Items to exclude their Product2Ids
                const oppLineItems = await getAllOpportunityLineItems({ opportunityId: this.quoteData.OpportunityId });
                const oppProductIds = new Set(oppLineItems.map(item => item.Product2Id));
        
                // Get non-OLI Quote Line Items (non-cloned) from allQuoteLineItems
                const nonOliQuoteLineItems = this.allQuoteLineItems.filter(
                    item => item.IsNonOliQuoteLineItem && !oppProductIds.has(item.Product2Id) && !item.Is_Cloned__c
                );
        
                // Fetch Pricebook products
                const result = await getProductsFromPricebook({
                    pricebookId: this.quoteData.Pricebook2Id,
                    limitSize: this.newProductRowLimit,
                    offset: 0,
                    CurrencyIsoCode: this.quoteData.CurrencyIsoCode
                });
                // console.log('Available Products Response:', JSON.stringify(result));
        
                // Transform Pricebook products
                const pricebookProducts = this.transformProductData(result);
        
                // Combine non-OLI QLIs and Pricebook products, deduplicating by Product2Id
                const uniqueProductsMap = new Map();
        
                // Add non-OLI Quote Line Items only if not deselected
                nonOliQuoteLineItems.forEach(item => {
                    if (!this.deselectedQuoteLineItemsSet.has(item.Id)) {
                        uniqueProductsMap.set(item.Product2Id, {
                            ...item,
                            Id: item.Id,
                            Quantity: item.Quantity,
                            UnitPrice: item.UnitPrice,
                            Discount: item.Discount
                        });
                    }
                });
        
                // Add Pricebook products, excluding those already in quoteLineItemIds, oppProductIds, or non-OLI QLIs
                pricebookProducts.forEach(product => {
                    if (!uniqueProductsMap.has(product.Product2Id) && !this.quoteLineItemIds.has(product.Product2Id) && !oppProductIds.has(product.Product2Id)) {
                        uniqueProductsMap.set(product.Product2Id, product);
                    }
                });
        
                const combinedProducts = Array.from(uniqueProductsMap.values());
        
                // Update available products lists
                this.availableProducts = combinedProducts;
                this.allAvailableProducts = combinedProducts;
                this.filteredProducts = combinedProducts;
        
                // Preserve existing selections and add non-OLI QLIs only if not deselected
                const previousSelections = new Set(this.selectedAvailableProductsSet);
                this.selectedAvailableProductsSet = new Set([
                    ...previousSelections,
                    ...nonOliQuoteLineItems
                        .filter(item => !this.deselectedQuoteLineItemsSet.has(item.Id) && !previousSelections.has(item.Id))
                        .map(item => item.Id)
                ]);
        
                // Update selectedAvailableProducts to reflect current selections
                this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet)
                    .filter(id => 
                        combinedProducts.some(product => product.Id === id) || 
                        this.allQuoteLineItems.some(qli => qli.Id === id && !qli.Is_Cloned__c)
                    );
        
                // console.log('Selected Available Products Set after load:', Array.from(this.selectedAvailableProductsSet));
            } catch (error) {
                console.error('Error loading available products:', error);
                this.showToast('Error', 'Error loading available products: ' + this.reduceErrors(error), 'error');
                this.availableProducts = [];
            } finally {
                this.isLoading = false;
            }
        }
    
        async loadMoreNewProductData(event) {
            const target = event.target;
            target.isLoading = true;
        
            this.newProductRowOffSet += this.newProductRowLimit;
            try {
                const oppLineItems = await getAllOpportunityLineItems({ opportunityId: this.quoteData.OpportunityId });
                const oppProductIds = new Set(oppLineItems.map(item => item.Product2Id));
        
                const result = await getProductsFromPricebook({
                    pricebookId: this.quoteData.Pricebook2Id,
                    limitSize: this.newProductRowLimit,
                    offset: this.newProductRowOffSet,
                    CurrencyIsoCode: this.quoteData.CurrencyIsoCode
                });
                const newRecords = this.transformProductData(result);
                const moreDataAvailable = result.length === this.newProductRowLimit;
        
                if (newRecords.length > 0) {
                    const uniqueProductsMap = new Map();
                    this.allAvailableProducts.forEach(product => {
                        uniqueProductsMap.set(product.Id, product);
                    });
                    newRecords.forEach(product => {
                        uniqueProductsMap.set(product.Id, product);
                    });
        
                    this.allAvailableProducts = Array.from(uniqueProductsMap.values());
        
                    this.availableProducts = this.allAvailableProducts.filter(product =>
                        !this.quoteLineItemIds.has(product.Product2Id) && 
                        !oppProductIds.has(product.Product2Id) && 
                        !product.Is_Cloned__c // Exclude cloned items
                    );
                    this.filteredProducts = [...this.availableProducts];
                }
        
                target.enableInfiniteLoading = moreDataAvailable;
                target.isLoading = false;
            } catch (error) {
                this.showToast('Error', 'Error loading more products: ' + this.reduceErrors(error), 'error');
                target.isLoading = false;
            }
        }
    
        transformLineItemData(data, isOpportunityLineItem = false) {
            return data.map(item => {
                const discount = item.Discount != null ? item.Discount : null;
                return {
                    Id: item.Id,
                    ProductName: isOpportunityLineItem ? item.Product2?.Name || '' : item.Product_Name__c || item.Product2?.Name || '',
                    ProductCode: item.Product2?.ProductCode || '',
                    ListPrice: item.ListPrice || item.UnitPrice || 0,
                    FormattedListPrice: `${item.CurrencyIsoCode} ${parseFloat(item.ListPrice || item.UnitPrice || 0).toFixed(2)}`,
                    ProductDescription: isOpportunityLineItem ? item.Product2?.Description || '' : item.Product_Description__c || item.Product2?.Description || '',
                    ProductFamily: item.Product2?.Family || '',
                    PricebookEntryId: item.PricebookEntryId,
                    Product2Id: item.Product2Id,
                    CurrencyIsoCode: item.CurrencyIsoCode || this.quoteData.CurrencyIsoCode || 'USD',
                    Quantity: item.Quantity != null ? item.Quantity : 1,
                    UnitPrice: item.UnitPrice || item.ListPrice || 0,
                    Discount: discount,
                    SortOrder: item.SortOrder,
                    Is_Cloned__c: item.Is_Cloned__c || false // Include server-side clone status
                };
            });
        }
    
        transformQuoteLineItemData(data) {
            return this.transformLineItemData(data, false);
        }
    
        transformProductData(data) {
            return data.map(item => ({
                Id: item.Id,
                ProductName: item.Product2?.Name || '',
                ProductCode: item.Product2?.ProductCode || '',
                ListPrice: item.UnitPrice || 0,
                FormattedListPrice: `${item.CurrencyIsoCode} ${parseFloat(item.UnitPrice || 0).toFixed(2)}`,
                ProductDescription: item.Product2?.Description || '',
                ProductFamily: item.Product2?.Family || '',
                Product2Id: item.Product2Id,
                CurrencyIsoCode: item.CurrencyIsoCode || this.quoteData.CurrencyIsoCode || 'USD',
                Quantity: 1,
                Discount: null
            }));
        }
    
        handleSearchChange(event) {
            this.searchKey = event.target.value;
            this.isSearching = !!this.searchKey;
            // console.log('Search Key:', this.searchKey);
            this.filterProducts();
        }
    
        filterProducts() {
            const searchTerm = this.searchKey.toLowerCase();
            if (searchTerm) {
                this.filteredQuoteLineItems = this.allQuoteLineItems.filter(item =>
                    item.ProductName.toLowerCase().includes(searchTerm) ||
                    item.ProductCode.toLowerCase().includes(searchTerm)
                );
                this.filteredProducts = this.allAvailableProducts.filter(product =>
                    !this.quoteLineItemIds.has(product.Product2Id) &&
                    (product.ProductName.toLowerCase().includes(searchTerm) ||
                     product.ProductCode.toLowerCase().includes(searchTerm))
                );
            } else {
                this.filteredQuoteLineItems = [...this.allQuoteLineItems];
                this.filteredProducts = this.allAvailableProducts.filter(product =>
                    !this.quoteLineItemIds.has(product.Product2Id)
                );
            }
            
            this.quoteLineItems = [...this.filteredQuoteLineItems];
            this.availableProducts = [...this.filteredProducts];
            
            this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet)
                .filter(id => this.allQuoteLineItems.some(item => item.Id === id));
            this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet)
                .filter(id => this.allAvailableProducts.some(product => product.Id === id) || this.allQuoteLineItems.some(qli => qli.Id === id));
            
            // console.log('Selected Line Items after filtering:', this.selectedQuoteLineItems);
            // console.log('Selected Available Products after filtering:', this.selectedAvailableProducts);
        }
    
        handleQuoteLineItemsSelection(event) {
            const selectedRows = event.detail.selectedRows;
            const newlySelectedIds = new Set(selectedRows.map(row => row.Id));
            const currentVisibleIds = new Set(this.quoteLineItems.map(item => item.Id));
        
            this.allQuoteLineItems.forEach(item => {
                const id = item.Id;
                if (currentVisibleIds.has(id)) {
                    if (newlySelectedIds.has(id)) {
                        this.selectedQuoteLineItemsSet.add(id);
                        this.deselectedQuoteLineItemsSet.delete(id);
                    } else if (!item.Is_Cloned__c) { // Prevent deselection of cloned items
                        this.selectedQuoteLineItemsSet.delete(id);
                        this.deselectedQuoteLineItemsSet.add(id);
                    }
                }
            });
        
            this.selectedQuoteLineItems = Array.from(this.selectedQuoteLineItemsSet)
                .filter(id => this.allQuoteLineItems.some(item => item.Id === id));
        
            // console.log('After selection - Selected Line Items Set:', Array.from(this.selectedQuoteLineItemsSet));
            // console.log('After selection - Deselected Line Items Set:', Array.from(this.deselectedQuoteLineItemsSet));
        }
        
        handleAvailableProductsSelection(event) {
            const selectedRows = event.detail.selectedRows;
            const newlySelectedIds = new Set(selectedRows.map(row => row.Id));
            const currentVisibleIds = new Set(this.availableProducts.map(item => item.Id));
        
            this.allAvailableProducts.forEach(product => {
                const id = product.Id;
                if (currentVisibleIds.has(id)) {
                    if (newlySelectedIds.has(id)) {
                        this.selectedAvailableProductsSet.add(id);
                        this.deselectedQuoteLineItemsSet.delete(id);
                    } else if (!this.allQuoteLineItems.some(qli => qli.Id === id && qli.Is_Cloned__c)) { // Prevent deselection of cloned items
                        this.selectedAvailableProductsSet.delete(id);
                        this.deselectedQuoteLineItemsSet.add(id);
                    }
                }
            });
        
            this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet)
                .filter(id => 
                    this.allAvailableProducts.some(product => product.Id === id) || 
                    this.allQuoteLineItems.some(qli => qli.Id === id && !qli.Is_Cloned__c)
                );
        
            // console.log('After selection - Selected Available Products Set:', Array.from(this.selectedAvailableProductsSet));
            // console.log('After selection - Deselected Quote Line Items Set:', Array.from(this.deselectedQuoteLineItemsSet));
        }
    
        handleFieldChange(event) {
            const fieldName = event.target.name || event.target.fieldName;
            let value = event.target.value;
    
            if (fieldName === 'BillingState' || fieldName === 'ShippingState') {
                value = value || '';
            }
    
            this.quoteData = { ...this.quoteData, [fieldName]: value };
        }
    
        reduceErrors(error) {
            if (error.body && error.body.message) {
                return error.body.message;
            } else if (error.message) {
                return error.message;
            } else if (typeof error === 'string') {
                return error;
            }
            return 'Unknown error';
        }
    
        showToast(title, message, variant) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title,
                    message,
                    variant
                })
            );
        }
    
       renderedCallback() {
    if (!this.isLoaded) {
        const style = document.createElement('style');
        style.innerText = `.uiModal--medium .modal-container {
            width: 100% !important;
            max-width: 100%;
            min-width: 480px;
        }
        .slds-modal__content {
            padding: 0 !important;
        }
        .slds-modal__container {
            padding: 30px !important;
        }`;
        this.template.querySelector('.sticky-container')?.appendChild(style);
        this.isLoaded = true;
    }
}
    }