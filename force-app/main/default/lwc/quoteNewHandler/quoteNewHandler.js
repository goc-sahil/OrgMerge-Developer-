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
             
                 
             
                 handleSectionToggle(event) {
                     this.activeSections = event.detail.openSections;
                    //  console.log('Active sections:', this.activeSections);
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

                

                // Open review modal if any condition is met
                if (hasDiscountedItems || isNotProfitable) {
                    this.isReviewModalOpen = true;
                    this.isLoading = false;
                    return;
                }
                 
                 }
             
                 
                 // New method to handle review comment submission
                 
             
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
             
             
                
             
                 handleSearchChange(event) {
                     this.searchKey = event.target.value.toLowerCase();
                     this.filterProducts();
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