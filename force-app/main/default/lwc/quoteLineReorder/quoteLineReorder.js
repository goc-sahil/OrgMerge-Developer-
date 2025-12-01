import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getQuoteLineItemsForQuote from '@salesforce/apex/QuoteLineOrderService.getQuoteLineItemsForQuote';
import saveQuoteLineItemSortOrders from '@salesforce/apex/QuoteLineOrderService.saveQuoteLineItemSortOrders';

export default class QuoteLineReorder extends LightningElement {
    @api quoteId;
    @track isModalOpen = true;
    @track blocks = []; // Array of parent blocks with children
    @track isLoading = false;
    @track hasChanges = false;
    
    wiredQuoteLineItemsResult;
    originalData = [];

    /**
     * Wire adapter to fetch quote line items
     */
    @wire(getQuoteLineItemsForQuote, { quoteId: '0Q0bZ000001QOPVSA4' })
    wiredQuoteLineItems(result) {
        this.wiredQuoteLineItemsResult = result;
        if (result.data) {
            this.originalData = JSON.parse(JSON.stringify(result.data));
            this.buildBlocks(result.data);
            this.hasChanges = false;
        } else if (result.error) {
            this.showToast('Error', 'Error loading quote line items: ' + this.getErrorMessage(result.error), 'error');
        }
    }

    /**
     * Opens the modal
     */
    @api
    openModal() {
        this.isModalOpen = true;
    }

    /**
     * Closes the modal
     */
    closeModal() {
        if (this.hasChanges) {
            if (confirm('You have unsaved changes. Are you sure you want to close?')) {
                this.isModalOpen = false;
                this.hasChanges = false;
                // Reset to original data
                this.buildBlocks(this.originalData);
            }
        } else {
            this.isModalOpen = false;
        }
    }

    /**
     * Builds hierarchical block structure from flat list
     * Each block contains a parent and its children
     */
    buildBlocks(items) {
        if (!items || items.length === 0) {
            this.blocks = [];
            return;
        }

        // Separate parents and children
        const parents = [];
        const childrenMap = new Map();

        items.forEach(item => {
            if (!item.parentQuoteLineItemId) {
                // This is a parent
                parents.push(item);
            } else {
                // This is a child
                if (!childrenMap.has(item.parentQuoteLineItemId)) {
                    childrenMap.set(item.parentQuoteLineItemId, []);
                }
                childrenMap.get(item.parentQuoteLineItemId).push(item);
            }
        });

        // Sort parents by sortOrder
        parents.sort((a, b) => a.sortOrder - b.sortOrder);

        // Build blocks
        this.blocks = parents.map((parent, index) => {
            const children = childrenMap.get(parent.id) || [];
            // Sort children by sortOrder
            children.sort((a, b) => a.sortOrder - b.sortOrder);

            return {
                id: parent.id,
                parent: parent,
                children: children,
                isFirst: index === 0,
                isLast: index === parents.length - 1,
                displayName: parent.productName || parent.name || 'Unnamed Product',
                hasChildren: children.length > 0
            };
        });
    }

    /**
     * Moves a parent block up
     */
    handleMoveUp(event) {
        const blockId = event.currentTarget.dataset.blockId;
        const blockIndex = this.blocks.findIndex(b => b.id === blockId);

        if (blockIndex > 0) {
            // Swap with previous block
            const temp = this.blocks[blockIndex];
            this.blocks[blockIndex] = this.blocks[blockIndex - 1];
            this.blocks[blockIndex - 1] = temp;

            // Update isFirst/isLast flags
            this.updateBlockFlags();
            this.hasChanges = true;
        }
    }

    /**
     * Moves a parent block down
     */
    handleMoveDown(event) {
        const blockId = event.currentTarget.dataset.blockId;
        const blockIndex = this.blocks.findIndex(b => b.id === blockId);

        if (blockIndex < this.blocks.length - 1) {
            // Swap with next block
            const temp = this.blocks[blockIndex];
            this.blocks[blockIndex] = this.blocks[blockIndex + 1];
            this.blocks[blockIndex + 1] = temp;

            // Update isFirst/isLast flags
            this.updateBlockFlags();
            this.hasChanges = true;
        }
    }

    /**
     * Moves a child line up within its parent
     */
    handleMoveChildUp(event) {
        const blockId = event.currentTarget.dataset.blockId;
        const childId = event.currentTarget.dataset.childId;
        const block = this.blocks.find(b => b.id === blockId);

        if (block) {
            const childIndex = block.children.findIndex(c => c.id === childId);
            if (childIndex > 0) {
                // Swap with previous child
                const temp = block.children[childIndex];
                block.children[childIndex] = block.children[childIndex - 1];
                block.children[childIndex - 1] = temp;
                
                this.hasChanges = true;
                // Force re-render
                this.blocks = [...this.blocks];
            }
        }
    }

    /**
     * Moves a child line down within its parent
     */
    handleMoveChildDown(event) {
        const blockId = event.currentTarget.dataset.blockId;
        const childId = event.currentTarget.dataset.childId;
        const block = this.blocks.find(b => b.id === blockId);

        if (block) {
            const childIndex = block.children.findIndex(c => c.id === childId);
            if (childIndex < block.children.length - 1) {
                // Swap with next child
                const temp = block.children[childIndex];
                block.children[childIndex] = block.children[childIndex + 1];
                block.children[childIndex + 1] = temp;
                
                this.hasChanges = true;
                // Force re-render
                this.blocks = [...this.blocks];
            }
        }
    }

    /**
     * Updates isFirst and isLast flags for all blocks
     */
    updateBlockFlags() {
        this.blocks.forEach((block, index) => {
            block.isFirst = index === 0;
            block.isLast = index === this.blocks.length - 1;
        });
        // Force re-render
        this.blocks = [...this.blocks];
    }

    /**
     * Saves the reordered quote line items
     */
    async handleSave() {
        this.isLoading = true;

        try {
            // Generate new sort orders
            const updates = [];
            let currentSortOrder = 10;
            const sortOrderIncrement = 10;

            this.blocks.forEach(block => {
                // Add parent
                updates.push({
                    id: block.parent.id,
                    newSortOrder: currentSortOrder,
                    parentQuoteLineItemId: null
                });
                currentSortOrder += sortOrderIncrement;

                // Add children
                block.children.forEach(child => {
                    updates.push({
                        id: child.id,
                        newSortOrder: currentSortOrder,
                        parentQuoteLineItemId: child.parentQuoteLineItemId
                    });
                    currentSortOrder += sortOrderIncrement;
                });
            });

            // Call Apex to save
            await saveQuoteLineItemSortOrders({
                quoteId: this.quoteId,
                updates: updates
            });

            this.showToast('Success', 'Quote line items reordered successfully', 'success');
            this.hasChanges = false;
            
            // Refresh the data
            await refreshApex(this.wiredQuoteLineItemsResult);
            
            // Dispatch event to refresh parent page
            this.dispatchEvent(new CustomEvent('quotelinesreordered', {
                detail: { quoteId: this.quoteId }
            }));

            this.closeModal();

        } catch (error) {
            this.showToast('Error', 'Error saving changes: ' + this.getErrorMessage(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Cancels changes and closes modal
     */
    handleCancel() {
        this.closeModal();
    }

    /**
     * Shows a toast message
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    /**
     * Extracts error message from error object
     */
    getErrorMessage(error) {
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        }
        return 'Unknown error';
    }

    /**
     * Formats currency values
     */
    formatCurrency(value) {
        return value != null ? '$' + value.toFixed(2) : '-';
    }

    /**
     * Gets child row class with proper indentation
     */
    getChildRowClass(childIndex, childrenLength) {
        return childIndex < childrenLength - 1 ? 'slds-is-relative' : 'slds-is-relative';
    }
}