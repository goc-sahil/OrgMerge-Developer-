import { LightningElement, track, api } from 'lwc';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemController.getQuoteLineItems';
import deleteQuoteLineItem from '@salesforce/apex/QuoteLineItemController.deleteQuoteLineItem';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateQuoteLineItems from '@salesforce/apex/QuoteLineItemController.updateQuoteLineItems';

export default class editableQuoteTable extends LightningElement {
    @track quoteItems = [];
    @track error;
    @track modifiedItems = [];
    @track isLoading = false; // Track loading state
    quoteId;
    recordId;
    isLoaded = false;
    noData=false;
    // isDropdownOpen = false;

    renderedCallback() {
        if (this.isLoaded) return;
        const STYLE = document.createElement('style');
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 80% !important;
            max-width: 80%;
            min-width: 480px;
            max-height: 100%;
            min-height: 800px;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }

    connectedCallback() {
        this.recordId = new URL(window.location.href).searchParams.get("recordId");
        this.quoteId = this.recordId;

        if (this.quoteId) {
            this.loadQuoteLineItems();
            document.addEventListener('click', this.closeDropdowns.bind(this));

        } else {
            this.showNotification('Error', 'Quote ID is missing from the URL', 'error');
        }
    }
    disconnectedCallback() {
        document.removeEventListener('click', this.closeDropdowns.bind(this));
    }

    loadQuoteLineItems() {
        this.isLoading = true; // Start spinner
        getQuoteLineItems({ quoteId: this.quoteId })
            .then(data => {
                // console.log(JSON.stringify(data));
                if(data.length > 0 ){
                    this.noData=false;
                    this.quoteItems = data.map(item => ({
                        id: item.Id,
                        productName: item.Product_Name__c,
                        productDescription: item.Product_Description__c,
                        listPrice: item.ListPrice,
                        salesPrice: item.UnitPrice,
                        quantity: item.Quantity,
                        currency: item.CurrencyIsoCode,
                        discount: item?.Discount ? item?.Discount : "-",
                        actualprice: this.calculateActualPrice(item.UnitPrice, item.Discount),
                        totalPrice: this.calculateTotalPrice(item.UnitPrice, item.Discount,item.Quantity),
                        isEditingProductName: false,
                        isEditingProductDescription: false,
                        isEditingSalesPrice: false,
                        isEditingQuantity: false,
                        isEditingDiscount: false,
                        isDropdownOpen: false,
                        initialValues: {
                            productName: item.Product_Name__c,
                            productDescription: item.Product_Description__c,
                            salesPrice: item.UnitPrice,
                            quantity: item.Quantity,
                            discount: item.Discount
                        }
                    }));
                    
                }
                else{
                    this.noData = true;
                }
                this.error = undefined;
            })
            
            .catch(error => {
                this.error = error;
                this.quoteItems = [];
                this.showNotification('Error loading quote line items', 'error', 'error');
            })
            .finally(() => {
                this.isLoading = false; // Stop spinner
            });
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const id = event.target.dataset.id;
        let value = event.target.value;
    
        // Define fields that are numeric and require decimal validation
        const numericFields = ['salesPrice', 'discount', 'quantity'];
        
        // Apply decimal validation only if the field is numeric
        if (numericFields.includes(field)) {
            let validValue = value.match(/^\d+(\.\d{0,2})?$/);
    
            // If invalid, revert the input field or log the issue
            if (!validValue) {
                console.log('Invalid input: ' + value);
                return; // Exit if the input is invalid
            }
            
            value = validValue[0]; // Extract the matched value as a string
            console.log('Valid numeric value:', value);
        }
    
        const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
    
        if (quoteItemIndex !== -1) {
            const updatedItem = { ...this.quoteItems[quoteItemIndex], [field]: value };
    
            if (field === 'salesPrice' || field === 'discount' || field === 'quantity') {
                // Calculate the total and actual price based on sales price, discount, and quantity
                updatedItem.totalPrice = this.calculateTotalPrice(updatedItem.salesPrice, updatedItem.discount, updatedItem.quantity);
                updatedItem.actualprice = this.calculateActualPrice(updatedItem.salesPrice, updatedItem.discount);
            }
    
            // Update the quoteItems array
            this.quoteItems[quoteItemIndex] = updatedItem;
    
            // Check if the value differs from the initial value
            if (value !== this.quoteItems[quoteItemIndex].initialValues[field]) {
                const modifiedItemIndex = this.modifiedItems.findIndex(item => item.id === id);
    
                if (modifiedItemIndex !== -1) {
                    // Update the modifiedItems entry
                    this.modifiedItems[modifiedItemIndex][field] = value;
                } else {
                    // Add a new entry to modifiedItems
                    const newModifiedItem = { id };
                    newModifiedItem[field] = value;
                    this.modifiedItems.push(newModifiedItem);
                }
            } else {
                // If the value matches the initial value, remove it from modifiedItems
                this.modifiedItems = this.modifiedItems.filter(item => !(item.id === id && item[field] === value));
            }
        }
    }
    

    toggleEditMode(event) {
        // console.log('Inside toglle');
        const field = event.target.dataset.field;
        const id = event.target.dataset.id;
        // let elemetnToFocus = this.template.querySelectorAll(`.focus[data-id='${id}']`);
        // console.log("elemetnToFocus : " + elemetnToFocus[4]);
        // elemetnToFocus[4].focus();
        const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
        // console.log('this.quoteItems[quoteItemIndex].discount : ' + this.quoteItems[quoteItemIndex].discount);
        if (quoteItemIndex !== -1) {
            
            this.quoteItems[quoteItemIndex] = {
                ...this.quoteItems[quoteItemIndex],
                discount: this.quoteItems[quoteItemIndex].discount == '' ? '-' : this.quoteItems[quoteItemIndex].discount,
                quantity: this.quoteItems[quoteItemIndex].quantity == '' ? '0' : this.quoteItems[quoteItemIndex].quantity,
                salesPrice: this.quoteItems[quoteItemIndex].salesPrice == '' ? '0' : this.quoteItems[quoteItemIndex].salesPrice,
                [`isEditing${field.charAt(0).toUpperCase() + field.slice(1)}`]: !this.quoteItems[quoteItemIndex][`isEditing${field.charAt(0).toUpperCase() + field.slice(1)}`]
            };
        }
    }
    validation(event){
        const field = event.target.dataset.field;
        const id = event.target.dataset.id;
        const quoteItemIndex = this.quoteItems.findIndex(item => item.id === id);
        if (quoteItemIndex !== -1) {
            if(field == 'discount' && this.quoteItems[quoteItemIndex].discount > 100) {
                this.showNotification('Failed to update quote line items','Discount (Percentage) must be between 0 and 100', 'error');
            }
        }
    }

    handleSave() {
        if (this.modifiedItems.length > 0) {
            const itemsToUpdate = this.modifiedItems.map(item => {
                const fullItem = this.quoteItems.find(qi => qi.id === item.id);
                const fieldsToUpdate = {
                    Id: item.id,
                    Product_Name__c: fullItem.productName, // Include Product2Id if needed
                    UnitPrice: parseFloat(fullItem.salesPrice),
                    Quantity: parseInt(fullItem.quantity, 10),
                    Discount: parseFloat(fullItem.discount),
                    Product_Description__c: fullItem.productDescription
                };
                // console.log('Updating Item:', fieldsToUpdate);
                return fieldsToUpdate;
            });

            updateQuoteLineItems({ quoteLineItems: itemsToUpdate })
                .then(() => {
                    this.showNotification('Success', 'Quote line items updated successfully', 'success');
                    this.modifiedItems = []; // Clear modified items list
                    // this.loadQuoteLineItems(); // Refresh data
                    this.closeAction();
                   c
                })
                .catch(error => {
                    // console.error('Error updating quote line items:', JSON.stringify(error));
                    // console.log(error.body.message);
                    let errorMessage = error.body.message.split(':')[2];
                    // console.log('errormessage:'+errorMessage);
                    let errorMessageSplit = errorMessage.split(',')[1];
                    // console.log('split:'+errorMessageSplit);

                    this.showNotification('Failed to update quote line items ', ` ${errorMessageSplit}`, 'error');
                });
        } else {
            this.showNotification('Info', 'No changes to save', 'info');
        }
    }

    handleDelete(event) {
        let hasError = false;
        this.isLoading = true;
        const itemId = event.target.dataset.id;
        const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
        if (itemIndex !== -1) {
            deleteQuoteLineItem({ quoteLineItemId: itemId })
                .then(() => {
                    this.showNotification('Success', 'Quote line item deleted successfully', 'success');
                    this.quoteItems.splice(itemIndex, 1);
                    if(this.quoteItems.length==0){
                        this.noData = true;
                    }
                })
                .catch(error => {
                    hasError = true;
                    // console.error('Error deleting quote line item:', error);
                    this.showNotification('Error', `Failed to delete quote line item: ${error.body.message}`, 'error');
                }).finally(() => {
                    this.isLoading = false;
                    // let origin = location.origin;
                    // console.log('origin'+origin);
                    if(!hasError){
                        location.reload();
                    }
                }
                );
        }
    }
    calculateActualPrice(salesPrice, discount){
        // console.log("calcu"+salesPrice, discount);
        let convDiscount = discount == '-' ? undefined : discount;
        // console.log("calcu"+convDiscount);
        if (salesPrice == undefined && convDiscount== undefined) return 0.00;
        else if (salesPrice != undefined && convDiscount== undefined ){
            if(salesPrice !=0) return parseFloat(salesPrice).toFixed(2);
            else return 0.00;
        }
        else if (salesPrice == undefined && convDiscount != undefined) {
            return 0.00;
        }
        else if (salesPrice != undefined && convDiscount != undefined ) {
            if(salesPrice !=0) return (salesPrice - (salesPrice * (convDiscount / 100))).toFixed(2);
            else return 0.00;
        }
    }

    calculateTotalPrice(salesPrice, discount, quantity) {
        // console.log("calcu"+salesPrice, discount);
        let convDiscount = discount == '-' ? undefined : discount;
        let convQuantity = quantity!=''?parseFloat(quantity): 0;
        // console.log("calcu"+salesPrice, discount, quantity);
        // console.log("calcu"+salesPrice, convDiscount, quantity);
        // console.log("calcuted quanty"+convQuantity);
        // console.log("calcu"+convDiscount);
        // if (salesPrice == undefined && convDiscount== undefined) return 0.00;
        // else if (salesPrice != undefined && convDiscount== undefined ){
        //     if(salesPrice !=0) return parseFloat(salesPrice).toFixed(2)*convQuantity;
        //     else return 0.00;
        // }
        // else if (salesPrice == undefined && convDiscount != undefined) {
        //     return 0.00;
        // }
        // else if (salesPrice != undefined && convDiscount != undefined ) {
        //     if(salesPrice !=0) return (salesPrice - (salesPrice * (convDiscount / 100))).toFixed(2)*convQuantity;
        //     else return 0.00;
        // }
        if(salesPrice == undefined || salesPrice == 0){
            return 0.00;
        }
        else{
            if(convQuantity == undefined || convQuantity == 0){
                return 0.00;
            }
            else
            {
                if(convDiscount != undefined && convDiscount != 0.00){
                    return ((salesPrice - (salesPrice * (convDiscount / 100)))*convQuantity).toFixed(2);
                }
                else{
                    return (parseFloat(salesPrice)*convQuantity).toFixed(2);
                }
            }
        }
    }

    formattedAmount(value){
        if (value >= 1000) {
           return value.toLocaleString();
        }
        else{
            return value;
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    closeAction(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    toggleDropdown(event) {
        event.stopPropagation();
        const itemId = event.target.dataset.id;
        const itemIndex = this.quoteItems.findIndex(item => item.id === itemId);
        this.quoteItems.forEach(ele => {
            ele.isDropdownOpen = false;
        })
        if (itemIndex !== -1) {
            this.quoteItems[itemIndex].isDropdownOpen = !this.quoteItems[itemIndex].isDropdownOpen;
        }
    }
    closeDropdowns(event) {
        // Iterate through quoteItems and close dropdowns if click is outside
        const dropdowns = this.template.querySelectorAll('.slds-dropdown_right');
        dropdowns.forEach(ele => {
            if (!ele.contains(event.target)) {
                this.closeAllDropdowns();
            }
        })
    }
    closeAllDropdowns() {
        this.quoteItems = this.quoteItems.map(qli => {
            return { ...qli, isDropdownOpen: false };
        });
    }


}