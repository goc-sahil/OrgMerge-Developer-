import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedQuotes from '@salesforce/apex/QuotesRelatedListController.getRelatedQuotes';
import deleteQuote from '@salesforce/apex/QuoteController.deleteQuote';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';
// import URL from '@salesforce/label/c.URL';

export default class QuotesRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isExpanded = true;
    @track isLoading = true;
    @track allQuotes = [];
    @track displayedQuotes = [];
    @track totalRecords = 0;
    @track isModalOpen = false;
    @track isModalOpen2 = false;
    @track isDeleteModalOpen = false;
    @track selectedQuoteId;
    @track refreshKey = 0;
    @track dataRefreshKey = 0;

    connectedCallback() {
        this.loadQuotes();
    }

    loadQuotes() {
        this.isLoading = true;
        getRelatedQuotes({ opportunityId: this.recordId })
            .then(result => {
                this.allQuotes = result.map(quote => ({
                    ...quote,
                    FormattedExpirationDate: this.formatDate(quote.Expiration_Date__c)
                }));
                this.totalRecords = this.allQuotes.length > 5 ? '5+' : this.allQuotes.length;
                this.displayedQuotes = this.allQuotes.slice(0, 5);
                this.isLoading = false;
                 this.dataRefreshKey += 1; // Trigger child refresh
            })
            .catch(error => {
                console.error('Error loading quotes:', error);
                this.isLoading = false;
            });
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toISOString().split('T')[0];
    }

    toggleCollapse() {
        this.isExpanded = !this.isExpanded;
    }

    handleTitleClick() {
        this.navigateToRelatedList();
    }

    handleViewAll() {
        this.navigateToRelatedList();
    }

    navigateToRelatedList() {
        //window.location.href = `https://invixium--quotemgt.sandbox.lightning.force.com/lightning/r/Opportunity/${this.recordId}/related/Quotes/view`;
      this[NavigationMixin.Navigate]({
    type: 'standard__recordRelationshipPage',
    attributes: {
        recordId: this.recordId,
        objectApiName: 'Opportunity',
        relationshipApiName: 'Quotes',
        actionName: 'view'
    }
});

    }

    handleQuoteClick(event) {
        const quoteId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: quoteId,
                objectApiName: 'Quote',
                actionName: 'view'
            }
        });
    }

   handleEditNavigation(event) {
    const quoteId = event.currentTarget.dataset.id;
    const baseUrl = window.location.origin;
    const url = `${baseUrl}/lightning/action/quick/Quote.EditQuote?objectApiName=Quote&context=RECORD_DETAIL&recordId=${quoteId}&backgroundContext=%2Flightning%2Fr%2FQuote%2F${quoteId}%2Fview`;
    window.location.href = url;
}

    openModal() {
        this.isModalOpen = true;

    }

    closeModal() {
        this.isModalOpen = false;
        this.dataRefreshKey += 1; 
    }

    openModal2() {
        this.isModalOpen2 = true;
    }

    closeModal2() {
        this.isModalOpen2 = false;
    }

    openDeleteModal(event) {
        try {
            this.selectedQuoteId = event.currentTarget.dataset.id;
            this.isDeleteModalOpen = true;
        } catch (error) {
            console.error('Error in openDeleteModal:', error);
            this.showToast('Error', 'Failed to open delete modal', 'error');
        }
    }

    closeDeleteModal() {
        this.isDeleteModalOpen = false;
        this.selectedQuoteId = null;
    }

    confirmDelete() {
        this.isLoading = true;
        deleteQuote({ quoteId: this.selectedQuoteId })
            .then(() => {
                this.showToast('Success', 'Quote deleted successfully', 'success');
                this.closeDeleteModal();
                this.isExpanded = true;
                this.allQuotes = [];
                this.displayedQuotes = [];
                this.totalRecords = 0;
                this.selectedQuoteId = null;
                this.refreshKey += 1;
                this.loadQuotes();
                this.dispatchEvent(new RefreshEvent());
            })
            .catch(error => {
                console.error('Error deleting quote:', error);
                this.showToast('Error', 'Failed to delete quote', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleMenuSelect(event) {
        const selectedAction = event.detail.value;
        const quoteId = event.currentTarget.dataset.id;

        if (selectedAction === 'delete') {
            this.openDeleteModalById(quoteId);
        }
    }

    openDeleteModalById(quoteId) {
        this.recordId = quoteId;
        this.isDeleteModalOpen = true;
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
}