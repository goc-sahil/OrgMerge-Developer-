import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunityDetails from '@salesforce/apex/QuoteController.getOpportunityDetails';
import createQuote from '@salesforce/apex/QuoteController.createQuote';
import updateQuote from '@salesforce/apex/QuoteController.updateQuote';
import getQuoteById from '@salesforce/apex/QuoteController.getQuoteById';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemController.getQuoteLineItems';
import updateQuoteLineItems from '@salesforce/apex/QuoteLineItemController.updateQuoteLineItems';
import createQuoteLineItems from '@salesforce/apex/ProductSelectionController.createQuoteLineItems';
import getOpportunityLineItems from '@salesforce/apex/ProductSelectionController.getOpportunityLineItems';
import getProductsFromPricebook from '@salesforce/apex/ProductSelectionController.getProductsFromPricebook';
import getAllOpportunityLineItems from '@salesforce/apex/ProductSelectionController.getAllOpportunityLineItems';
import LUMPSUM_DISCOUNT_PRODUCT from '@salesforce/label/c.Lumpsum_Discount_Product';
import Lumpsum_Discount_Product_INR from '@salesforce/label/c.Lumpsum_Discount_Product_INR';

const OPPORTUNITY_COLUMNS = [
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

export default class QuoteModalAdvanced extends NavigationMixin(LightningElement) {
      @track totalPrice = 0;
                 @track isStep1 = true;
                 @track isStep2 = false;
                 @track isStep3 = false;
                 @track quoteData = {};
                 @track currentStep = '1';
                 @track createdQuoteId = null;
                 @track pricebookName = null;
                 @track newQuoteName = null;
                 @track Pricebook2Id = null;
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
             
                 _isOpen = false;
                 _recordId;
                 @track selectedOpportunityProducts = [];
                 @track selectedAvailableProducts = [];
                 @track quoteItems = [];
                 @track error;
                 @track modifiedItems = [];
                 @track isLoading = false;
                 @track noData = false;
                 @track searchKey = '';
                 @track opportunityProducts = [];
                 @track allOpportunityProducts = [];
                 @track filteredOpportunityProducts = [];
                 @track availableProducts = [];
                 @track allAvailableProducts = [];
                 @track filteredProducts = [];
                 @track opportunityProductIds = new Set();
                 opportunityColumns = OPPORTUNITY_COLUMNS;
                 productColumns = PRODUCT_COLUMNS;
                 @track isSearching = false;
                 @track hasLoadedAllOppProducts = false;
                 newProductRowLimit = 500;
                 newProductRowOffSet = 0;
                 oppProductRowLimit = 500;
                 oppProductRowOffSet = 0;
                 enableOpportunityLoadMore = true;
                 @track deselectedOpportunityProductsSet = new Set();
                 @track selectedOpportunityProductsSet = new Set();
                 @track selectedAvailableProductsSet = new Set();
                 @track editedQuoteItems = [];
                 @track isQuoteLineItemCreated = false;
                 @track activeSections = ['opportunityProducts', 'newProducts'];
                 @track isReviewModalOpen = false;
                 @track reviewComment = '';
                 @api refreshKey; 
                 get isStep1() {
                     return this.currentStep === '1';
                 }
                 get isStep2() {
                     return this.currentStep === '2';
                 }
                 get isStep3() {
                     return this.currentStep === '3';
                 }
             
                 @api
                 set isOpen(value) {
                     const wasClosed = !this._isOpen && value;
                     this._isOpen = value;
             
                     if (wasClosed && this._recordId) {
                         this.resetModal();
                     }
                 }
             
                 get isOpen() {
                     return this._isOpen;
                 }
             
                 @api
                 set recordId(value) {
                     const isNewId = value !== this._recordId;
                     this._recordId = value;
             
                     if (this._isOpen && isNewId && value) {
                         this.resetModal();
                     }
                 }
             
                 get recordId() {
                     return this._recordId;
                 }
             
                 async connectedCallback() {
                     this.updateHostDataAttribute();
                     document.addEventListener('click', this.closeDropdowns.bind(this));
                     await this.initializeDefaultValues();
                     await this.loadInitialOpportunityProducts();
                     console.log('allOpportunityProducts==>'+this.allOpportunityProducts);
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
                 resetModal() {
                     this.currentStep = '1';
                     this.modalTitle = 'New Quote';
                     this.createdQuoteId = null;
                     this.quoteData = {};
                     this.quoteItems = [];
                     this.modifiedItems = [];
                     this.editedQuoteItems = [];
                     this.noData = false;
                     this.error = undefined;
                     this.isReviewModalOpen = false;
                     this.reviewComment = '';
                     this.initializeDefaultValues();
                 }
             
                 async initializeDefaultValues() {
                     try {
                         this.isLoading = true;
                         const opp = await getOpportunityDetails({ opportunityId: this._recordId });
                         if (!opp || !opp.Id) {
                             this.showToast('Error', 'Opportunity not found.', 'error');
                             return;
                         }
             
                         this.quoteData = {
                             opportunityName: opp.Name,
                             accountName: opp.Account?.Name,
                             OpportunityId: opp.Id,
                             AccountId: opp.AccountId,
                             CurrencyIsoCode: opp.CurrencyIsoCode,
                             Name: opp.Name,
                             ExpirationDate: this.getExpirationDate(),
                             BillingName: opp.Account?.Name,
                             ShippingName: opp.Account?.Name,
                             BillingCountry: opp.Account?.ShippingCountry,
                             ShippingCountry: opp.Account?.ShippingCountry,
                             BillingStreet : opp.Account?.ShippingStreet,
                             BillingCity : opp.Account?.ShippingCity,
                             BillingPostalCode: opp.Account?.ShippingPostalCode,
                             BillingState: opp.Account?.ShippingState,
                             ShippingState: opp.Account?.ShippingState,
                             ShippingStreet: opp.Account?.ShippingStreet,
                             ShippingCity: opp.Account?.ShippingCity,
                             ShippingPostalCode: opp.Account?.ShippingPostalCode,
                             ShippingState: opp.Account?.ShippingState,
                             ShippingPostalCode: opp.Account?.ShippingPostalCode,
                             Pricebook2Id: opp.Pricebook2?.Id,
                             pricebookName: opp.Pricebook2?.Name,
                             CurrencyIsoCode: opp.CurrencyIsoCode,
                             Review_Requested_for__c: ''
                         };
                         this.pricebookName = opp.Pricebook2?.Name || null;
                         this.prepopulateFormFields();
                     } catch (error) {
                         this.showToast('Error', 'Failed to load Opportunity details: ' + this.reduceErrors(error), 'error');
                     } finally {
                         this.isLoading = false;
                     }
                 }
             
                 async fetchQuoteData(quoteId) {
                     try {
                         const quote = await getQuoteById({ quoteId });
                         this.quoteData = {
                             ...this.quoteData,
                             OpportunityId: quote.OpportunityId,
                             AccountId: quote.AccountId,
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
                             CurrencyIsoCode: quote.CurrencyIsoCode || this.quoteData.CurrencyIsoCode
                         };
                         this.Pricebook2Id = quote.Pricebook2?.Id || this.Pricebook2Id;
                         this.pricebookName = quote.Pricebook2?.Name || this.pricebookName;
                         await new Promise(resolve => requestAnimationFrame(resolve));
                         this.prepopulateFormFields();
                     } catch (error) {
                         console.error('Error fetching Quote details:', error);
                         this.showErrorToast(error);
                     }
                 }
             
                 getExpirationDate() {
                     const today = new Date();
                     today.setDate(today.getDate() + 30);
                     return today.toISOString().split('T')[0];
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
                     this._isOpen = false;
                     this.dispatchEvent(new RefreshEvent());
                     if (!this.isQuoteLineItemCreated) {
                         window.location.reload();
                     }
                     this.dispatchEvent(new CustomEvent('close'));
                 }
             
                 submitForm() {
                     const form = this.template.querySelector('lightning-record-edit-form');
                     if (form) {
                         const fields = form.querySelectorAll('lightning-input-field');
                         fields.forEach(field => {
                             if (this.quoteData[field.fieldName]) {
                                 field.value = this.quoteData[field.fieldName];
                             }
                         });
                         form.submit();
                     }
                 }
             
                 handleSuccess(event) {
                     this.createdQuoteId = event.detail.id;
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Success',
                             message: 'Quote created successfully!',
                             variant: 'success'
                         })
                     );
                     this.dispatchEvent(new CustomEvent('success', { detail: this.createdQuoteId }));
                     this.closeModal();
                 }
             
                 goToStep1() {
                     this.isStep1 = true;
                     this.isStep2 = false;
                     this.isStep3 = false;
                     this.updateHostDataAttribute();
                     this.currentStep = '1';
                     this.modalTitle = 'New Quote';
                     if (this.createdQuoteId) {
                         this.fetchQuoteData(this.createdQuoteId);
                     } else {
                         this.initializeDefaultValues();
                     }
                 }
             
                 goToStep2() {
                     this.saveFormValuesToQuoteData(); // Update this.quoteData from form first
                 
                     if (!this.quoteData.Name || this.quoteData.Name.trim() === '') {
                         this.showErrorToast({ body: { message: 'Quote Name is required' } });
                         return;
                     }
                 
                     this.isStep1 = false;
                     this.isStep2 = true;
                     this.isStep3 = false;
                     this.updateHostDataAttribute();
                    this.saveQuoteAndContinue();
                     this.currentStep = '2';
                     this.modalTitle = 'Add Product';
                     // Refresh opportunity products
                    //await this.loadInitialOpportunityProducts();
                     
                     this.opportunityProducts = [...this.allOpportunityProducts];
                     this.availableProducts = [...this.allAvailableProducts];
                     this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
                     this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
                     this.activeSections = ['opportunityProducts', 'newProducts'];
                 }
             
                 handleSectionToggle(event) {
                     this.activeSections = event.detail.openSections;
                    //  console.log('Active sections:', this.activeSections);
                 }
             
                 async saveQuoteAndContinue() {
                     try {
                         if (!this.quoteData.Pricebook2Id) {
                             this.showErrorToast({ body: { message: 'Pricebook is not set for the Opportunity.' } });
                             return;
                         }
                         else{
                             if (!this.quoteData.Name) {
                                 this.showErrorToast({ body: { message: 'Quote Name is required' } });
                                 return;
                             }
                             let quoteId;
                             if (this.createdQuoteId) {
                                 quoteId = await updateQuote({
                                     quoteData: this.quoteData,
                                     quoteId: this.createdQuoteId
                                 });
                                 await this.fetchQuoteData(quoteId);
                             } else {
                                //  console.log('quoteData==>', JSON.stringify(this.quoteData));
                                 quoteId = await createQuote({ quoteData: this.quoteData });
                                 this.createdQuoteId = quoteId;
                             }
                            //  console.log('createdQuoteId==>', this.createdQuoteId);
                             this.newQuoteName = this.quoteData.Name;
                             this.currentStep = '2';
                             this.modalTitle = 'Add Product';
                             this.showSuccessToast();
                         }
                         
                     } catch (error) {
                         console.error('Error during save and continue:', error);
                         this.showErrorToast(error);
                     }
                 }
             
                 async createNewQuote() {
                     try {
                         this.saveFormValuesToQuoteData(); // Update this.quoteData from form first
                 
                         if (!this.quoteData.Name || this.quoteData.Name.trim() === '') {
                             this.showErrorToast({ body: { message: 'Quote Name is required' } });
                             return;
                         }
                         if (!this.quoteData.Pricebook2Id) {
                             this.showErrorToast({ body: { message: 'Pricebook is not set for the Opportunity.' } });
                             return;
                         }
                         let quoteId;
                         if (this.createdQuoteId) {
                             quoteId = await updateQuote({
                                 quoteData: this.quoteData,
                                 quoteId: this.createdQuoteId
                             });
                         } else {
                             quoteId = await createQuote({ quoteData: this.quoteData });
                             this.createdQuoteId = quoteId;
                         }
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
                             message: 'Quote saved successfully!',
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
                     this.searchKey='';
                     this.filterProducts();
                     this.isStep1 = false;
                     this.isStep2 = false;
                     this.isStep3 = true;
                     this.updateHostDataAttribute();
                     this.currentStep = '3';
                     this.modalTitle = 'Edit Quote Line Items';
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
                     if (!this.createdQuoteId) {
                         this.isLoading = false;
                         this.showNotification('Error', 'No quote created. Please save the quote first.', 'error');
                         return;
                     }
                     if (!this.quoteData.Pricebook2Id) {
                         this.isLoading = false;
                         this.showNotification('Error', 'Pricebook is not set for the Opportunity.', 'error');
                         return;
                     }
                     if (this.quoteItems.length === 0) {
                         this.isLoading = false;
                         this.showNotification('Error', 'No quote line items to submit.', 'error');
                         return;
                     }
             
                    // Check for discounted line items
                 const hasDiscountedItems = this.quoteItems.some(item => {
                    const listPrice = parseFloat(item.listPrice);
                    const proposedPrice = parseFloat(item.salesPrice);
                    const discount = item.discount === '-' ? 0 : parseFloat(item.discount);
                    
                    // Calculate price after discount as a percentage of proposed price
                    const priceAfterDiscount = discount ? proposedPrice - (proposedPrice * (discount / 100)) : proposedPrice;
                    
                    return (
                        !isNaN(listPrice) &&
                        !isNaN(proposedPrice) &&
                        !isNaN(discount) &&
                        discount > 0 &&
                        priceAfterDiscount < listPrice
                    );
                });
                            
             
             
                     // Check for lump sum discount
                //  const hasLumpSumDiscount = this.quoteData.Lump_Sum_Discount__c && parseFloat(this.quoteData.Lump_Sum_Discount__c) > 0;
             
                //  // Check for specific product using custom label
                //  const hasTargetProduct = this.quoteItems.some(item => item.Product2Id === LUMPSUM_DISCOUNT_PRODUCT);
                //  const hasTargetProductINR = this.quoteItems.some(item => item.Product2Id === Lumpsum_Discount_Product_INR);
                //  console.log('quoteData==>'+JSON.stringify(this.quoteData));
                //  console.log('this.quoteItems==>'+JSON.stringify(this.quoteItems));
                // console.log('hasTargetProduct==>'+hasTargetProduct);
                // console.log('hasLumpSumDiscount==>'+hasLumpSumDiscount);
                //  // Open review modal if any condition is met
                //  if (hasDiscountedItems || hasLumpSumDiscount || hasTargetProduct || hasTargetProductINR) {
                //      this.isReviewModalOpen = true;
                //      this.isLoading = false;
                //      return;
                //  }

                // Check for lump sum discount
                const hasLumpSumDiscount = this.quoteData.Lump_Sum_Discount__c && parseFloat(this.quoteData.Lump_Sum_Discount__c) > 0;

                // Check for specific product using custom label
                const hasTargetProduct = this.quoteItems.some(item => item.Product2Id === LUMPSUM_DISCOUNT_PRODUCT);
                const hasTargetProductINR = this.quoteItems.some(item => item.Product2Id === Lumpsum_Discount_Product_INR);

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

                // console.log('quoteData==>' + JSON.stringify(this.quoteData));
                // console.log('this.quoteItems==>' + JSON.stringify(this.quoteItems));
                // console.log('hasTargetProduct==>' + hasTargetProduct);
                // console.log('hasLumpSumDiscount==>' + hasLumpSumDiscount);
                // console.log('totalListPrice==>' + totalListPrice);
                // console.log('totalSalesPrice==>' + totalSalesPrice);
                // console.log('isNotProfitable==>' + isNotProfitable);

                // Open review modal if any condition is met
                if (hasDiscountedItems || isNotProfitable) {
                    this.isReviewModalOpen = true;
                    this.isLoading = false;
                    return;
                }
                 // Proceed with original submit logic if no conditions are met
                 this.processQuoteSubmission();
                 }
             
                 async processQuoteSubmission() {
                     const quoteLineItems = this.quoteItems.map((item, index) => {
                         return {
                             QuoteId: this.createdQuoteId,
                             Product2Id: item.Product2Id,
                             PricebookEntryId: item.PricebookEntryId,
                             Product_Name__c: item.productName,
                             UnitPrice: parseFloat(item.salesPrice) || 0,
                             Quantity: parseInt(item.quantity, 10) || 1,
                             Discount: item.discount === '-' ? null : parseFloat(item.discount),
                             Product_Description__c: item.productDescription || '',
                             CurrencyIsoCode: this.quoteData.CurrencyIsoCode,
                             Order__c: item.order,
                             Is_Cloned__c: item.isCloned || false // Include isCloned flag
                         };
                     });
             
                     try {
                         await createQuoteLineItems({ quoteLineItems, pricebook2Id: this.quoteData.Pricebook2Id });
                         this.showNotification('Success', 'Quote line items created successfully.', 'success');
                         this[NavigationMixin.Navigate]({
                             type: 'standard__recordPage',
                             attributes: {
                                 recordId: this.createdQuoteId,
                                 objectApiName: 'Quote',
                                 actionName: 'view'
                             }
                         });
                         this.isQuoteLineItemCreated = true;
                         this.closeModal();
                     } catch (error) {
                         this.isLoading = false;
                         const errorMessage = this.reduceErrors(error);
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
                             this.showNotification('Error', 'Failed to create quote line items: ' + errorMessage, 'error');
                         }
                     }
                 }
                 // New method to handle review comment submission
                 async handleReviewCommentSubmit() {
                     if (!this.reviewComment.trim()) {
                         this.showNotification('Error', 'Please enter a review comment.', 'error');
                         return;
                     }
                     this.isLoading = true;
                     try {
                         // Update quoteData with the review comment
                         this.quoteData.Review_Requested_for__c = this.reviewComment;
             
                         // Update the Quote record with the comment
                         await updateQuote({
                             quoteData: {
                                 ...this.quoteData,
                                 Review_Requested_for__c: this.reviewComment
                             },
                             quoteId: this.createdQuoteId
                         });
             
                         this.isReviewModalOpen = false;
                         this.reviewComment = ''; // Reset comment
                         await this.processQuoteSubmission(); // Proceed with quote submission
                     } catch (error) {
                         this.isLoading = false;
                         this.showNotification('Error', 'Failed to save review comment: ' + this.reduceErrors(error), 'error');
                     }
                 }
             
                 // New method to handle review modal cancel
                 handleReviewModalCancel() {
                     this.isReviewModalOpen = false;
                     this.reviewComment = '';
                     this.isLoading = false;
                 }
             
                 // New method to handle comment input change
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
                    //  console.log('quoteData before save:', JSON.stringify(this.quoteData));
                 }
             
                 loadQuoteLineItems() {
                    this.isLoading = true;
                    // console.log('Loading Quote Line Items...');
            
                    if (this.createdQuoteId) {
                        getQuoteLineItems({ quoteId: this.createdQuoteId })
                            .then(result => {
                                const serverItems = result.map((item, index) => ({
                                    id: item.Id,
                                    productName: item.Product_Name__c || item.Product2?.Name,
                                    productDescription: item.Product_Description__c || '',
                                    listPrice: item.ListPrice || 0,
                                    salesPrice: item.UnitPrice || 0,
                                    quantity: item.Quantity || 1,
                                    currency: item.CurrencyIsoCode || this.quoteData.CurrencyIsoCode,
                                    discount: item.Discount != null ? item.Discount : '-',
                                    actualprice: this.calculateActualPrice(item.UnitPrice, item.Discount),
                                    totalPrice: this.calculateTotalPrice(item.UnitPrice, item.Discount, item.Quantity),
                                    isEditingProductName: false,
                                    isEditingProductDescription: false,
                                    isEditingSalesPrice: false,
                                    isEditingQuantity: false,
                                    isEditingDiscount: false,
                                    isDropdownOpen: false,
                                    PricebookEntryId: item.PricebookEntryId,
                                    Product2Id: item.Product2Id,
                                    order: item.Order__c || (index + 1),
                                    isCloned: item.Is_Cloned__c || false, // Reflect server-side Is_Cloned__c
                                    initialValues: {
                                        productName: item.Product_Name__c || item.Product2?.Name,
                                        productDescription: item.Product_Description__c || '',
                                        salesPrice: item.UnitPrice || 0,
                                        quantity: item.Quantity || 1,
                                        discount: item.Discount != null ? item.Discount : null,
                                        order: item.Order__c || (index + 1)
                                    }
                                }));
            
                                const selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet)
                                    .map(id => this.allOpportunityProducts.find(product => product.Id === id))
                                    .filter(product => product);
                                const selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet)
                                    .map(id => this.allAvailableProducts.find(product => product.Id === id))
                                    .filter(product => product);
            
                                const editedItemsMap = new Map(this.editedQuoteItems.map(item => [item.id, item]));
            
                                const combinedProducts = [
                                    ...selectedOpportunityProducts.map((item, index) => {
                                        const existingItem = editedItemsMap.get(item.Id) || serverItems.find(s => s.Product2Id === item.Product2Id && !s.isCloned);
                                        return {
                                            id: item.Id,
                                            productName: existingItem ? existingItem.productName : item.ProductName,
                                            productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                            listPrice: item.ListPrice || 0,
                                            salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                            quantity: existingItem ? existingItem.quantity : (item.Quantity || 1),
                                            currency: this.quoteData.CurrencyIsoCode,
                                            discount: existingItem ? existingItem.discount : '-',
                                            actualprice: this.calculateActualPrice(
                                                existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                existingItem ? existingItem.discount : null
                                            ),
                                            totalPrice: this.calculateTotalPrice(
                                                existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                existingItem ? existingItem.discount : null,
                                                existingItem ? existingItem.quantity : (item.Quantity || 1)
                                            ),
                                            isEditingProductName: false,
                                            isEditingProductDescription: false,
                                            isEditingSalesPrice: false,
                                            isEditingQuantity: false,
                                            isEditingDiscount: false,
                                            isDropdownOpen: false,
                                            PricebookEntryId: item.PricebookEntryId,
                                            Product2Id: item.Product2Id,
                                            order: existingItem ? existingItem.order : (serverItems.length + index + 1),
                                            isCloned: false, // Opportunity Products are not cloned
                                            initialValues: {
                                                productName: existingItem ? existingItem.productName : item.ProductName,
                                                productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                                salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                quantity: existingItem ? existingItem.quantity : (item.Quantity || 1),
                                                discount: existingItem ? existingItem.discount : null,
                                                order: existingItem ? existingItem.order : (serverItems.length + index + 1)
                                            }
                                        };
                                    }),
                                    ...selectedAvailableProducts.map((item, index) => {
                                        const existingItem = editedItemsMap.get(item.Id) || serverItems.find(s => s.Product2Id === item.Product2Id && !s.isCloned);
                                        return {
                                            id: item.Id,
                                            productName: existingItem ? existingItem.productName : item.ProductName,
                                            productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                            listPrice: item.ListPrice || 0,
                                            salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                            quantity: existingItem ? existingItem.quantity : 1,
                                            currency: this.quoteData.CurrencyIsoCode,
                                            discount: existingItem ? existingItem.discount : '-',
                                            actualprice: this.calculateActualPrice(
                                                existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                existingItem ? existingItem.discount : null
                                            ),
                                            totalPrice: this.calculateTotalPrice(
                                                existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                existingItem ? existingItem.discount : null,
                                                existingItem ? existingItem.quantity : 1
                                            ),
                                            isEditingProductName: false,
                                            isEditingProductDescription: false,
                                            isEditingSalesPrice: false,
                                            isEditingQuantity: false,
                                            isEditingDiscount: false,
                                            isDropdownOpen: false,
                                            PricebookEntryId: item.Id,
                                            Product2Id: item.Product2Id,
                                            order: existingItem ? existingItem.order : (serverItems.length + selectedOpportunityProducts.length + index + 1),
                                            isCloned: false, // Available Products are not cloned
                                            initialValues: {
                                                productName: existingItem ? existingItem.productName : item.ProductName,
                                                productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                                salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                                quantity: existingItem ? existingItem.quantity : 1,
                                                discount: existingItem ? existingItem.discount : null,
                                                order: existingItem ? existingItem.order : (serverItems.length + selectedOpportunityProducts.length + index + 1)
                                            }
                                        };
                                    })
                                ];
            
                                const clonedItems = this.editedQuoteItems
                                    .filter(item => item.id.startsWith('CLONE_'))
                                    .map((item, index) => {
                                        const originalItemId = item.id.replace(/^CLONE_/, '');
                                        const originalOppProduct = this.allOpportunityProducts.find(product => product.Id === originalItemId);
                                        const originalAvailProduct = this.allAvailableProducts.find(product => product.Id === originalItemId);
                                        return {
                                            id: item.id,
                                            productName: item.productName,
                                            productDescription: item.productDescription,
                                            listPrice: item.salesPrice || 0,
                                            salesPrice: item.salesPrice,
                                            quantity: item.quantity,
                                            currency: this.quoteData.CurrencyIsoCode,
                                            discount: item.discount || '-',
                                            actualprice: this.calculateActualPrice(item.salesPrice, item.discount),
                                            totalPrice: this.calculateTotalPrice(item.salesPrice, item.discount, item.quantity),
                                            isEditingProductName: false,
                                            isEditingProductDescription: false,
                                            isEditingSalesPrice: false,
                                            isEditingQuantity: false,
                                            isEditingDiscount: false,
                                            isDropdownOpen: false,
                                            PricebookEntryId: item.PricebookEntryId || originalOppProduct?.PricebookEntryId || originalAvailProduct?.Id || null,
                                            Product2Id: item.Product2Id || originalOppProduct?.Product2Id || originalAvailProduct?.Product2Id || null,
                                            order: item.order || (combinedProducts.length + index + 1),
                                            isCloned: true, // Cloned items
                                            initialValues: {
                                                productName: item.productName,
                                                productDescription: item.productDescription,
                                                salesPrice: item.salesPrice,
                                                quantity: item.quantity,
                                                discount: item.discount,
                                                order: item.order || (combinedProducts.length + index + 1)
                                            }
                                        };
                                    });
            
                                let allItems = [...serverItems, ...combinedProducts, ...clonedItems];
            
                                // Modified deduplication logic to preserve cloned items
                                const uniqueItems = [];
                                const seenProduct2Ids = new Set();
                                allItems.forEach(item => {
                                    if (item.isCloned || !seenProduct2Ids.has(item.Product2Id)) {
                                        uniqueItems.push(item);
                                        if (!item.isCloned) {
                                            seenProduct2Ids.add(item.Product2Id);
                                        }
                                    }
                                });
            
                                // Sort and reassign order
                                uniqueItems.sort((a, b) => (a.order || Infinity) - (b.order || Infinity));
            
                                const finalItems = uniqueItems.map((item, index) => ({
                                    ...item,
                                    order: index + 1,
                                    initialValues: {
                                        ...item.initialValues,
                                        order: index + 1
                                    }
                                }));
            
                                if (finalItems.length > 0) {
                                    this.noData = false;
                                    this.quoteItems = finalItems;
                                    this.editedQuoteItems = finalItems.map(item => ({
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
                                    this.calculateTotalQuotePrice();
                                    // console.log('Quote Items Set:', JSON.stringify(this.quoteItems));
                                    // console.log('Edited Quote Items Updated:', JSON.stringify(this.editedQuoteItems));
                                } else {
                                    this.noData = true;
                                    this.quoteItems = [];
                                    this.editedQuoteItems = [];
                                    this.totalPrice = 0;
                                    // console.log('No Quote Items Found');
                                }
            
                                this.error = undefined;
                                this.isLoading = false;
                            })
                            .catch(error => {
                                // console.error('Error loading quote line items:', error);
                                this.showNotification('Error', 'Failed to load quote line items: ' + this.reduceErrors(error), 'error');
                                this.isLoading = false;
                            });
                    } else {
                        const selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet)
                            .map(id => this.allOpportunityProducts.find(product => product.Id === id))
                            .filter(product => product);
                        const selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet)
                            .map(id => this.allAvailableProducts.find(product => product.Id === id))
                            .filter(product => product);
            
                        const editedItemsMap = new Map(this.editedQuoteItems.map(item => [item.id, item]));
            
                        const combinedProducts = [
                            ...selectedOpportunityProducts.map((item, index) => {
                                const existingItem = editedItemsMap.get(item.Id);
                                return {
                                    id: item.Id,
                                    productName: existingItem ? existingItem.productName : item.ProductName,
                                    productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                    listPrice: item.ListPrice || 0,
                                    salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                    quantity: existingItem ? existingItem.quantity : (item.Quantity || 1),
                                    currency: this.quoteData.CurrencyIsoCode,
                                    discount: existingItem ? existingItem.discount : '-',
                                    actualprice: this.calculateActualPrice(
                                        existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        existingItem ? existingItem.discount : null
                                    ),
                                    totalPrice: this.calculateTotalPrice(
                                        existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        existingItem ? existingItem.discount : null,
                                        existingItem ? existingItem.quantity : (item.Quantity || 1)
                                    ),
                                    isEditingProductName: false,
                                    isEditingProductDescription: false,
                                    isEditingSalesPrice: false,
                                    isEditingQuantity: false,
                                    isEditingDiscount: false,
                                    isDropdownOpen: false,
                                    PricebookEntryId: item.PricebookEntryId,
                                    Product2Id: item.Product2Id,
                                    order: existingItem ? existingItem.order : (index + 1),
                                    isCloned: false, // Opportunity Products are not cloned
                                    initialValues: {
                                        productName: existingItem ? existingItem.productName : item.ProductName,
                                        productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                        salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        quantity: existingItem ? existingItem.quantity : (item.Quantity || 1),
                                        discount: existingItem ? existingItem.discount : null,
                                        order: existingItem ? existingItem.order : (index + 1)
                                    }
                                };
                            }),
                            ...selectedAvailableProducts.map((item, index) => {
                                const existingItem = editedItemsMap.get(item.Id);
                                return {
                                    id: item.Id,
                                    productName: existingItem ? existingItem.productName : item.ProductName,
                                    productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                    listPrice: item.ListPrice || 0,
                                    salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                    quantity: existingItem ? existingItem.quantity : 1,
                                    currency: this.quoteData.CurrencyIsoCode,
                                    discount: existingItem ? existingItem.discount : '-',
                                    actualprice: this.calculateActualPrice(
                                        existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        existingItem ? existingItem.discount : null
                                    ),
                                    totalPrice: this.calculateTotalPrice(
                                        existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        existingItem ? existingItem.discount : null,
                                        existingItem ? existingItem.quantity : 1
                                    ),
                                    isEditingProductName: false,
                                    isEditingProductDescription: false,
                                    isEditingSalesPrice: false,
                                    isEditingQuantity: false,
                                    isEditingDiscount: false,
                                    isDropdownOpen: false,
                                    PricebookEntryId: item.Id,
                                    Product2Id: item.Product2Id,
                                    order: existingItem ? existingItem.order : (selectedOpportunityProducts.length + index + 1),
                                    isCloned: false, // Available Products are not cloned
                                    initialValues: {
                                        productName: existingItem ? existingItem.productName : item.ProductName,
                                        productDescription: existingItem ? existingItem.productDescription : (item.ProductDescription || ''),
                                        salesPrice: existingItem ? existingItem.salesPrice : (item.UnitPrice || item.ListPrice || 0),
                                        quantity: existingItem ? existingItem.quantity : 1,
                                        discount: existingItem ? existingItem.discount : null,
                                        order: existingItem ? existingItem.order : (selectedOpportunityProducts.length + index + 1)
                                    }
                                };
                            })
                        ];
            
                        const clonedItems = this.editedQuoteItems
                            .filter(item => item.id.startsWith('CLONE_'))
                            .map((item, index) => {
                                const originalItemId = item.id.replace(/^CLONE_/, '');
                                const originalOppProduct = this.allOpportunityProducts.find(product => product.Id === originalItemId);
                                const originalAvailProduct = this.allAvailableProducts.find(product => product.Id === originalItemId);
                                return {
                                    id: item.id,
                                    productName: item.productName,
                                    productDescription: item.productDescription,
                                    listPrice: item.salesPrice || 0,
                                    salesPrice: item.salesPrice,
                                    quantity: item.quantity,
                                    currency: this.quoteData.CurrencyIsoCode,
                                    discount: item.discount || '-',
                                    actualprice: this.calculateActualPrice(item.salesPrice, item.discount),
                                    totalPrice: this.calculateTotalPrice(item.salesPrice, item.discount, item.quantity),
                                    isEditingProductName: false,
                                    isEditingProductDescription: false,
                                    isEditingSalesPrice: false,
                                    isEditingQuantity: false,
                                    isEditingDiscount: false,
                                    isDropdownOpen: false,
                                    PricebookEntryId: item.PricebookEntryId || originalOppProduct?.PricebookEntryId || originalAvailProduct?.Id || null,
                                    Product2Id: item.Product2Id || originalOppProduct?.Product2Id || originalAvailProduct?.Product2Id || null,
                                    order: item.order || (combinedProducts.length + index + 1),
                                    isCloned: true, // Cloned items
                                    initialValues: {
                                        productName: item.productName,
                                        productDescription: item.productDescription,
                                        salesPrice: item.salesPrice,
                                        quantity: item.quantity,
                                        discount: item.discount,
                                        order: item.order || (combinedProducts.length + index + 1)
                                    }
                                };
                            });
            
                        let allItems = [...combinedProducts, ...clonedItems];
            
                        // Modified deduplication logic to preserve cloned items
                        const uniqueItems = [];
                        const seenProduct2Ids = new Set();
                        allItems.forEach(item => {
                            if (item.isCloned || !seenProduct2Ids.has(item.Product2Id)) {
                                uniqueItems.push(item);
                                if (!item.isCloned) {
                                    seenProduct2Ids.add(item.Product2Id);
                                }
                            }
                        });
            
                        // Sort and reassign order
                        uniqueItems.sort((a, b) => (a.order || Infinity) - (b.order || Infinity));
            
                        const finalItems = uniqueItems.map((item, index) => ({
                            ...item,
                            order: index + 1,
                            initialValues: {
                                ...item.initialValues,
                                order: index + 1
                            }
                        }));
            
                        if (finalItems.length > 0) {
                            this.noData = false;
                            this.quoteItems = finalItems;
                            this.editedQuoteItems = finalItems.map(item => ({
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
                            this.calculateTotalQuotePrice();
                            // console.log('Quote Items Set:', JSON.stringify(this.quoteItems));
                            // console.log('Edited Quote Items Updated:', JSON.stringify(this.editedQuoteItems));
                        } else {
                            this.noData = true;
                            this.quoteItems = [];
                            this.editedQuoteItems = [];
                            this.totalPrice = 0;
                            // console.log('No Quote Items Found');
                        }
            
                        this.error = undefined;
                        this.isLoading = false;
                    }
                }
             
                 moveUp(event) {
                     const itemId = event.target.dataset.id;
                     const index = this.quoteItems.findIndex(item => item.id === itemId);
                     if (index <= 0) return;
             
                     this.isLoading = true;
             
                     const updatedItems = [...this.quoteItems];
                     const temp = updatedItems[index];
                     updatedItems[index] = updatedItems[index - 1];
                     updatedItems[index - 1] = temp;
             
                     updatedItems[index].order = index + 1;
                     updatedItems[index - 1].order = index;
             
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
                         PricebookEntryId: item.PricebookEntryId
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
                         PricebookEntryId: item.PricebookEntryId
                     }));
             
                     this.isLoading = false;
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
             
                 validation(event) {
                     const field = event.target.dataset.field;
                     const id = event.target.dataset.id;
                     const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
                     if (quoteItemIndex !== -1) {
                         if (field == 'discount' && this.quoteItems[quoteItemIndex].discount > 100) {
                             this.showNotification('Failed to update quote line items', 'Discount (Percentage) must be between 0 and 100', 'error');
                         }
                     }
                 }
             
                 handleSave() {
                     if (this.modifiedItems.length > 0) {
                         const itemsToUpdate = [];
                         const itemsToCreate = [];
             
                         this.modifiedItems.forEach(item => {
                             const fullItem = this.quoteItems.find(qi => qi.id === item.id);
                             const fields = {
                                 Product_Name__c: fullItem.productName,
                                 UnitPrice: parseFloat(fullItem.salesPrice),
                                 Quantity: parseInt(fullItem.quantity, 10),
                                 Discount: fullItem.discount === '-' ? null : parseFloat(fullItem.discount),
                                 Product_Description__c: fullItem.productDescription,
                                 Order__c: fullItem.order
                             };
             
                             if (item.id.startsWith('CLONE_')) {
                                 itemsToCreate.push({
                                     ...fields,
                                     QuoteId: this.createdQuoteId,
                                     Product2Id: this.getProduct2IdForItem(item.id, fullItem),
                                     PricebookEntryId: this.getPricebookEntryIdForClonedItem(item.id, fullItem),
                                     CurrencyIsoCode: this.quoteData.CurrencyIsoCode
                                 });
                             } else {
                                 itemsToUpdate.push({
                                     Id: item.id,
                                     ...fields
                                 });
                             }
                         });
             
                         if (itemsToUpdate.length > 0) {
                             updateQuoteLineItems({ quoteLineItems: itemsToUpdate })
                                 .then(() => {
                                     this.showNotification('Success', 'Quote line items updated successfully', 'success');
                                     this.modifiedItems = this.modifiedItems.filter(item => !itemsToUpdate.some(updated => updated.Id === item.id));
                                 })
                                 .catch(error => {
                                     let errorMessage = error.body?.message?.split(':')[2] || error.body?.message || 'Unknown error';
                                     this.showNotification('Failed to update quote line items', errorMessage, 'error');
                                 });
                         }
             
                         if (itemsToCreate.length > 0) {
                             createQuoteLineItems({ quoteLineItems: itemsToCreate, pricebook2Id: this.quoteData.Pricebook2Id })
                                 .then(() => {
                                     this.showNotification('Success', 'Cloned quote line items created successfully', 'success');
                                     this.modifiedItems = this.modifiedItems.filter(item => !itemsToCreate.some(created => created.Id === item.id));
                                 })
                                 .catch(error => {
                                     this.showNotification('Error', 'Failed to create cloned quote line items: ' + this.reduceErrors(error), 'error');
                                 });
                         }
             
                         if (itemsToUpdate.length === 0 && itemsToCreate.length === 0) {
                             this.showNotification('Info', 'No changes to save', 'info');
                         }
                     } else {
                         this.showNotification('Info', 'No changes to save', 'info');
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
                
                 // Update handleDelete to recalculate total price
                 handleDelete(event) {
                     this.isLoading = true;
                     const itemId = event.target.dataset.id;
             
                     const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
                     if (itemIndex === -1) {
                         this.isLoading = false;
                         this.showNotification('Error', 'Quote line item not found.', 'error');
                         return;
                     }
             
                     const isOpportunityProduct = this.allOpportunityProducts.some(product => product.Id === itemId);
                     const isAvailableProduct = this.allAvailableProducts.some(product => product.Id === itemId);
             
                     this.quoteItems.splice(itemIndex, 1);
             
                     this.quoteItems = this.quoteItems.map((item, idx) => ({
                         ...item,
                         order: idx + 1,
                         initialValues: {
                             ...item.initialValues,
                             order: idx + 1
                         }
                     }));
             
                     if (isOpportunityProduct) {
                         this.selectedOpportunityProductsSet.delete(itemId);
                         this.deselectedOpportunityProductsSet.add(itemId);
                         this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
                     } else if (isAvailableProduct) {
                         this.selectedAvailableProductsSet.delete(itemId);
                         this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
                     }
             
                     this.editedQuoteItems = this.quoteItems.map(item => ({
                         id: item.id,
                         productName: item.productName,
                         productDescription: item.productDescription,
                         salesPrice: item.salesPrice,
                         quantity: item.quantity,
                         discount: item.discount,
                         order: item.order,
                         Product2Id: item.Product2Id,
                         PricebookEntryId: item.PricebookEntryId
                     }));
             
                     if (this.quoteItems.length === 0) {
                         this.noData = true;
                     }
             
                     this.closeAllDropdowns();
                     this.calculateTotalQuotePrice(); // Recalculate total price
                     this.isLoading = false;
                     this.showNotification('Success', 'Quote line item deleted successfully.', 'success');
                 }
             
                 generateUniqueId() {
                     return 'CLONE_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                 }
             
                 getProduct2IdForItem(clonedItemId, fullItem) {
                     const originalItemId = clonedItemId.replace(/^CLONE_/, '');
                     const isOpportunityProduct = this.allOpportunityProducts.find(product => product.Id === originalItemId);
                     const isAvailableProduct = this.allAvailableProducts.find(product => product.Id === originalItemId);
                     return (isOpportunityProduct || isAvailableProduct)?.Product2Id || null;
                 }
             
                 getPricebookEntryIdForClonedItem(clonedItemId, fullItem) {
                     const originalItemId = clonedItemId.replace(/^CLONE_/, '');
                     const isOpportunityProduct = this.allOpportunityProducts.find(product => product.Id === originalItemId);
                     const isAvailableProduct = this.allAvailableProducts.find(product => product.Id === originalItemId);
                     return isOpportunityProduct?.PricebookEntryId || isAvailableProduct?.Id || null;
                 }
             
                 calculateActualPrice(salesPrice, discount) {
                     let convDiscount = discount === '-' ? undefined : discount;
                     if (!salesPrice && !convDiscount) return 0.00;
                     if (salesPrice && !convDiscount) return parseFloat(salesPrice).toFixed(2);
                     if (!salesPrice && convDiscount) return 0.00;
                     return (salesPrice - (salesPrice * (convDiscount / 100))).toFixed(2);
                 }
             
                 calculateTotalPrice(salesPrice, discount, quantity) {
                     let convDiscount = discount === '-' ? undefined : discount;
                     let convQuantity = quantity ? parseFloat(quantity) : 0;
                     if (!salesPrice || salesPrice == 0 || !convQuantity) return 0.00;
                     if (convDiscount) {
                         return ((salesPrice - (salesPrice * (convDiscount / 100))) * convQuantity).toFixed(2);
                     }
                     return (parseFloat(salesPrice) * convQuantity).toFixed(2);
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
             
                 async loadInitialOpportunityProducts() {
                     if (this._recordId) {
                         this.isLoading = true;
                         try {
                             const result = await getAllOpportunityLineItems({ opportunityId: this._recordId });
                             console.log('apec call result==>'+JSON.stringify(result));
                             const transformedData = this.transformData(result);
                             this.allOpportunityProducts = transformedData;
                             this.opportunityProducts = transformedData;
                             this.filteredOpportunityProducts = transformedData;
             
                             this.opportunityProductIds = new Set(
                                 transformedData.map(item => item.Product2Id)
                             );
             
                             this.selectedOpportunityProductsSet = new Set(
                                 transformedData.map(item => item.Id)
                             );
                             this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
             
                             this.deselectedOpportunityProductsSet = new Set();
                             this.hasLoadedAllOppProducts = true;
                             this.enableOpportunityLoadMore = false;
                         } catch (error) {
                             this.showToast('Error', 'Error loading opportunity products: ' + this.reduceErrors(error), 'error');
                         } finally {
                             this.isLoading = false;
                         }
                     }
                 }
             
                 loadMoreOpportunityProductData(event) {
                     if (this.isSearching) return;
             
                     const target = event.target;
                     target.isLoading = true;
             
                     this.oppProductRowOffSet += this.oppProductRowLimit;
             
                     getOpportunityLineItems({
                         opportunityId: this._recordId,
                         limitSize: this.oppProductRowLimit,
                         offset: this.oppProductRowOffSet
                     })
                         .then(result => {
                             const newRecords = this.transformData(result);
                             const moreDataAvailable = result.length === this.oppProductRowLimit;
             
                             if (newRecords.length > 0) {
                                 const uniqueProductsMap = new Map();
             
                                 this.allOpportunityProducts.forEach(product => {
                                     uniqueProductsMap.set(product.Id, product);
                                 });
             
                                 newRecords.forEach(product => {
                                     uniqueProductsMap.set(product.Id, product);
                                     this.selectedOpportunityProductsSet.add(product.Id);
                                 });
             
                                 this.allOpportunityProducts = Array.from(uniqueProductsMap.values());
             
                                 this.opportunityProductIds = new Set(
                                     this.allOpportunityProducts.map(item => item.Product2Id)
                                 );
             
                                 if (this.searchKey) {
                                     this.filterProducts();
                                 } else {
                                     this.opportunityProducts = [...this.allOpportunityProducts];
                                     this.filteredOpportunityProducts = [...this.allOpportunityProducts];
                                 }
             
                                 this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
                             }
             
                             target.enableInfiniteLoading = moreDataAvailable;
                             this.enableOpportunityLoadMore = moreDataAvailable;
                             target.isLoading = false;
                         })
                         .catch(error => {
                             this.showToast('Error', 'Error loading more opportunity products: ' + this.reduceErrors(error), 'error');
                             target.isLoading = false;
                         });
                 }
             
                 async loadInitialAvailableProducts() {
                     this.isLoading = true;
                     try {
                         const result = await getProductsFromPricebook({
                             pricebookId: this.quoteData.Pricebook2Id,
                             limitSize: this.newProductRowLimit,
                             offset: 0,
                             CurrencyIsoCode: this.quoteData.CurrencyIsoCode
                         });
                         const newRecords = this.transformData(result);
             
                         this.availableProducts = newRecords.filter(product =>
                             !this.opportunityProductIds.has(product.Product2Id)
                         );
             
                         this.allAvailableProducts = [...this.availableProducts];
                         this.filteredProducts = [...this.availableProducts];
                     } catch (error) {
                         this.showToast('Error', 'Error loading available products: ' + this.reduceErrors(error), 'error');
                     } finally {
                         this.isLoading = false;
                     }
                 }
             
                 async loadMoreNewProductData(event) {
                     const target = event.target;
                     target.isLoading = true;
             
                     this.newProductRowOffSet += this.newProductRowLimit;
                     try {
                         const result = await getProductsFromPricebook({
                             pricebookId: this.quoteData.Pricebook2Id,
                             limitSize: this.newProductRowLimit,
                             offset: this.newProductRowOffSet,
                             CurrencyIsoCode: this.quoteData.CurrencyIsoCode
                         });
                         const newRecords = this.transformData(result);
             
                         const newFilteredRecords = newRecords.filter(product =>
                             !this.opportunityProductIds.has(product.Product2Id)
                         );
             
                         const moreDataAvailable = result.length === this.newProductRowLimit;
             
                         if (newFilteredRecords.length > 0) {
                             this.availableProducts = [...this.availableProducts, ...newFilteredRecords];
                             this.allAvailableProducts = [...this.allAvailableProducts, ...newFilteredRecords];
             
                             if (this.searchKey) {
                                 this.filterProducts();
                             } else {
                                 this.filteredProducts = [...this.availableProducts];
                             }
                         }
             
                         target.enableInfiniteLoading = moreDataAvailable;
                     } catch (error) {
                         this.showToast('Error', 'Error loading more products: ' + this.reduceErrors(error), 'error');
                     } finally {
                         target.isLoading = false;
                     }
                 }
             
                 transformData(data) {
                    //  console.log('Raw data from Apex:', JSON.stringify(data));
                     const transformed = data.map(item => {
                         return {
                             Id: item.Id,
                             Product2Id: item.Product2Id,
                             ProductName: item.Product2 ? item.Product2.Name : '',
                             ProductCode: item.Product2 ? item.Product2.ProductCode : '',
                             ListPrice: item.ListPrice || item.UnitPrice || 0,
                             UnitPrice: item.UnitPrice || item.ListPrice || 0,
                             Quantity: item.Quantity || 1,
                             ProductDescription: item.Product2 ? item.Product2.Description : '',
                             ProductFamily: item.Product2 ? item.Product2.Family : '',
                             PricebookEntryId: item.PricebookEntryId,
                             CurrencyIsoCode: item.CurrencyIsoCode 
                         };
                     });
                    //  console.log('Transformed data:', JSON.stringify(transformed));
                     return transformed;
                 }
             
                 handleSearchChange(event) {
                     this.searchKey = event.target.value.toLowerCase();
                     this.filterProducts();
                 }
             
                 loadAllOpportunityProductsForSearch() {
                     this.isSearching = true;
                     this.isLoading = true;
             
                     getAllOpportunityLineItems({ opportunityId: this._recordId })
                         .then(result => {
                             const allProducts = this.transformData(result);
             
                             const uniqueProductsMap = new Map();
             
                             this.allOpportunityProducts.forEach(product => {
                                 uniqueProductsMap.set(product.Id, product);
                             });
             
                             allProducts.forEach(product => {
                                 uniqueProductsMap.set(product.Id, product);
                                 if (!this.selectedOpportunityProductsSet.has(product.Id)) {
                                     this.selectedOpportunityProductsSet.add(product.Id);
                                 }
                             });
             
                             this.allOpportunityProducts = Array.from(uniqueProductsMap.values());
             
                             this.opportunityProductIds = new Set(
                                 this.allOpportunityProducts.map(item => item.Product2Id)
                             );
             
                             this.hasLoadedAllOppProducts = true;
             
                             this.filterProducts();
                             this.isLoading = false;
                             this.isSearching = false;
                         })
                         .catch(error => {
                             this.showToast('Error', 'Error loading all opportunity products: ' + this.reduceErrors(error), 'error');
                             this.isLoading = false;
                             this.isSearching = false;
                         });
                 }
             
                 filterProducts() {
                     if (this.searchKey) {
                         this.filteredOpportunityProducts = this.allOpportunityProducts.filter(product =>
                             product.ProductName.toLowerCase().includes(this.searchKey) ||
                             (product.ProductCode && product.ProductCode.toLowerCase().includes(this.searchKey))
                         );
             
                         this.opportunityProducts = this.filteredOpportunityProducts;
             
                         this.filteredProducts = this.allAvailableProducts.filter(product =>
                             product.ProductName.toLowerCase().includes(this.searchKey) ||
                             (product.ProductCode && product.ProductCode.toLowerCase().includes(this.searchKey))
                         );
             
                         this.availableProducts = this.filteredProducts;
                     } else {
                         this.opportunityProducts = [...this.allOpportunityProducts];
                         this.filteredOpportunityProducts = [...this.allOpportunityProducts];
                         this.filteredProducts = [...this.allAvailableProducts];
                         this.availableProducts = [...this.allAvailableProducts];
                     }
             
                     this.selectedOpportunityProductsSet = new Set(
                         this.opportunityProducts
                             .filter(product => !this.deselectedOpportunityProductsSet.has(product.Id))
                             .map(product => product.Id)
                     );
             
                     this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
                     this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
                 }
             
                 get filteredProducts() {
                     let products = this.searchKey
                         ? this.allAvailableProducts.filter(product =>
                             product.ProductName.toLowerCase().includes(this.searchKey) ||
                             (product.ProductCode && product.ProductCode.toLowerCase().includes(this.searchKey))
                         )
                         : [...this.allAvailableProducts];
             
                     return products.filter(product => !this.opportunityProductIds.has(product.Product2Id));
                 }
             
                 handleOpportunityProductsSelection(event) {
                     const selectedRows = new Set(event.detail.selectedRows.map(row => row.Id));
             
                     const currentlyDisplayedIds = new Set(this.opportunityProducts.map(prod => prod.Id));
             
                     this.opportunityProducts.forEach(product => {
                         const productId = product.Id;
             
                         if (currentlyDisplayedIds.has(productId) && !selectedRows.has(productId)) {
                             this.deselectedOpportunityProductsSet.add(productId);
                         }
             
                         if (currentlyDisplayedIds.has(productId) && selectedRows.has(productId)) {
                             this.deselectedOpportunityProductsSet.delete(productId);
                         }
                     });
             
                     this.selectedOpportunityProductsSet = selectedRows;
                     this.selectedOpportunityProducts = Array.from(this.selectedOpportunityProductsSet);
                 }
             
                 handleAvailableProductsSelection(event) {
                     const selectedRows = event.detail.selectedRows;
             
                     const currentlyDisplayedIds = new Set(this.availableProducts.map(prod => prod.Id));
             
                     const selectedRowIds = new Set(selectedRows.map(row => row.Id));
             
                     this.availableProducts.forEach(product => {
                         const productId = product.Id;
             
                         if (selectedRowIds.has(productId)) {
                             this.selectedAvailableProductsSet.add(productId);
                         } else if (currentlyDisplayedIds.has(productId)) {
                             this.selectedAvailableProductsSet.delete(productId);
                         }
                     });
             
                     this.selectedAvailableProducts = Array.from(this.selectedAvailableProductsSet);
                 }
             
                 get selectedOpportunityProducts() {
                     return Array.from(this.selectedOpportunityProductsSet);
                 }
             
                 set selectedOpportunityProducts(value) {
                     this._selectedOpportunityProducts = value;
                 }
             
                 get selectedAvailableProducts() {
                     return Array.from(this.selectedAvailableProductsSet);
                 }
             
                 set selectedAvailableProducts(value) {
                     this._selectedAvailableProducts = value;
                 }
             
                 showToast(title, message, variant) {
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: title,
                             message: message,
                             variant: variant
                         })
                     );
                 }
             
                 reduceErrors(errors) {
                     if (!Array.isArray(errors)) {
                         errors = [errors];
                     }
             
                     return errors.map(error => {
                         if (typeof error === 'string') {
                             return error;
                         }
                         if (error.message) {
                             return error.message;
                         }
                         if (error.body && error.body.message) {
                             return error.body.message;
                         }
                         return JSON.stringify(error);
                     }).join(', ');
                 }
                 renderedCallback() {
                    if (this.refreshKey !== this.lastRefreshKey) {
                        this.lastRefreshKey = this.refreshKey;
                        this.refreshData();
                    }
                }

                async refreshData() {
                    console.log('Refreshing data...');
                    await this.initializeDefaultValues();
                    await this.loadInitialOpportunityProducts();
                    await this.loadInitialAvailableProducts();
                }
                handleFieldChange(event){
                    
                }

             }