import { LightningElement, api, track } from 'lwc';
import getQuoteLineItems from '@salesforce/apex/QuoteLineItemSorter.getQuoteLineItems';
import updateSortOrders from '@salesforce/apex/QuoteLineItemSorter.updateSortOrders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class QuoteLineItemSorter extends LightningElement {
    recordId;
    @track rawList = [];
    @track hierarchy = [];
    @track loading = false;
    @track error;
    isLoaded = false;
    originalOrderMap = new Map();
    changedItemsSet = new Set();
    saveDisabled = true;
    draggedItemId = null;
    expandedParents = new Set();

    renderedCallback() {
        if (this.isLoaded) return;
        const STYLE = document.createElement('style');
        STYLE.innerText = `.uiModal--medium .modal-container{
            width: 100% !important;
            max-width: 80%;
            min-width: 480px;
            max-height: 100%;
            min-height: 103% !important;
        }`;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }
    connectedCallback() {
        this.recordId = new URL(window.location.href).searchParams.get("recordId");
        this.loadItems();
    }

    async loadItems() {
        this.loading = true;
        this.error = undefined;
        try {
            const result = await getQuoteLineItems({ quoteId: this.recordId });
            this.rawList = result.map(item => {
                return {
                    Id: item.Id,
                    Name: item.Product_Name__c,
                    SalesPrice: this.formatPrice(item.UnitPrice),
                    RawPrice: item.UnitPrice,
                    CurrencyCode: item.CurrencyIsoCode || 'USD',
                    SortOrder: item.SortOrder,
                    ParentQuoteLineItemId: item.ParentQuoteLineItemId
                };
            });
            
            console.log('RESULT::', JSON.stringify(result));
            
            this.originalOrderMap.clear();
            for (const r of this.rawList) {
                this.originalOrderMap.set(r.Id, r.SortOrder);
            }

            this.buildHierarchy();
        } catch (err) {
            this.error = err.body ? err.body.message : err.message;
        } finally {
            this.loading = false;
        }
    }

    formatPrice(price) {
        if (price == null) return '0.00';
        return parseFloat(price).toFixed(2);
    }

    buildHierarchy() {
        const parentMap = new Map();
        this.rawList.sort((a, b) => {
            const sa = a.SortOrder == null ? Number.MAX_SAFE_INTEGER : a.SortOrder;
            const sb = b.SortOrder == null ? Number.MAX_SAFE_INTEGER : b.SortOrder;
            return sa - sb;
        });

        for (const item of this.rawList) {
            if (!item.ParentQuoteLineItemId) {
                parentMap.set(item.Id, { ...item, children: [] });
            }
        }

        for (const item of this.rawList) {
            if (item.ParentQuoteLineItemId) {
                const parent = parentMap.get(item.ParentQuoteLineItemId);
                if (parent) {
                    parent.children.push({ ...item });
                } else {
                    parentMap.set(item.Id, { ...item, children: [] });
                }
            }
        }

        const orderedParents = [];
        for (const r of this.rawList) {
            if (!r.ParentQuoteLineItemId && parentMap.has(r.Id)) {
                orderedParents.push(parentMap.get(r.Id));
                parentMap.delete(r.Id);
            }
        }
        for (const val of parentMap.values()) orderedParents.push(val);

        // Add UI helper properties
        this.hierarchy = orderedParents.map((parent, index) => {
            const hasChildren = parent.children && parent.children.length > 0;
            const isExpanded = this.expandedParents.has(parent.Id);
            
            return {
                ...parent,
                isFirst: index === 0,
                isLast: index === orderedParents.length - 1,
                hasChildren: hasChildren,
                childCount: parent.children ? parent.children.length : 0,
                isExpanded: isExpanded,
                showChildren: hasChildren && isExpanded,
                expandIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                expandTitle: isExpanded ? 'Collapse' : 'Expand',
                cssClass: this.getRowCssClass(parent.Id, true),
                children: parent.children ? parent.children.map(child => ({
                    ...child,
                    cssClass: this.getRowCssClass(child.Id, false)
                })) : []
            };
        });

        this.saveDisabled = true;
    }

    getRowCssClass(itemId, isParent) {
        const baseClass = isParent ? 'parent-row slds-grid slds-align_absolute-center' : 'child-row slds-grid slds-align_absolute-center';
        const changedClass = this.changedItemsSet.has(itemId) ? ' row-changed' : '';
        return baseClass + changedClass;
    }

    handleToggleChildren(event) {
        event.stopPropagation();
        const parentId = event.currentTarget.dataset.id;
        
        if (this.expandedParents.has(parentId)) {
            this.expandedParents.delete(parentId);
        } else {
            this.expandedParents.add(parentId);
        }
        
        // Rebuild hierarchy to update UI
        const currentHierarchy = [...this.hierarchy];
        this.hierarchy = currentHierarchy.map((parent, index) => {
            if (parent.Id === parentId) {
                const isExpanded = this.expandedParents.has(parent.Id);
                return {
                    ...parent,
                    isExpanded: isExpanded,
                    showChildren: parent.hasChildren && isExpanded,
                    expandIcon: isExpanded ? 'utility:chevrondown' : 'utility:chevronright',
                    expandTitle: isExpanded ? 'Collapse' : 'Expand'
                };
            }
            return parent;
        });
    }

    markItemsAsChanged() {
        this.changedItemsSet.clear();
        let currentOrder = 10;
        
        for (const parent of this.hierarchy) {
            if (this.originalOrderMap.get(parent.Id) !== currentOrder) {
                this.changedItemsSet.add(parent.Id);
            }
            currentOrder += 10;

            if (parent.children && parent.children.length > 0) {
                for (const child of parent.children) {
                    if (this.originalOrderMap.get(child.Id) !== currentOrder) {
                        this.changedItemsSet.add(child.Id);
                    }
                    currentOrder += 10;
                }
            }
        }

        // Update CSS classes
        this.hierarchy = this.hierarchy.map((parent, index) => ({
            ...parent,
            isFirst: index === 0,
            isLast: index === this.hierarchy.length - 1,
            cssClass: this.getRowCssClass(parent.Id, true),
            children: parent.children ? parent.children.map(child => ({
                ...child,
                cssClass: this.getRowCssClass(child.Id, false)
            })) : []
        }));
    }

    // Drag and Drop Handlers
    handleDragStart(event) {
        this.draggedItemId = event.currentTarget.dataset.id;
        event.currentTarget.classList.add('dragging');
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.draggedItemId);
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        return false;
    }

    handleDragEnter(event) {
        event.preventDefault();
        const targetId = event.currentTarget.dataset.id;
        if (targetId !== this.draggedItemId) {
            event.currentTarget.classList.add('drag-over');
        }
    }

    handleDragLeave(event) {
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        
        const targetId = event.currentTarget.dataset.id;
        
        // Remove all drag styling
        const allRows = this.template.querySelectorAll('.parent-row');
        allRows.forEach(row => {
            row.classList.remove('drag-over', 'dragging');
        });
        
        if (targetId && this.draggedItemId && targetId !== this.draggedItemId) {
            const draggedIndex = this.findParentIndexById(this.draggedItemId);
            const targetIndex = this.findParentIndexById(targetId);
            
            if (draggedIndex !== -1 && targetIndex !== -1) {
                // Create new array and reorder
                const newHierarchy = [...this.hierarchy];
                const draggedItem = newHierarchy[draggedIndex];
                newHierarchy.splice(draggedIndex, 1);
                newHierarchy.splice(targetIndex, 0, draggedItem);
                
                this.hierarchy = newHierarchy;
                this.saveDisabled = false;
                this.markItemsAsChanged();
            }
        }
        
        this.draggedItemId = null;
        return false;
    }

    findParentIndexById(parentId) {
        return this.hierarchy.findIndex(p => p.Id === parentId);
    }

    handleMoveUpParent(event) {
        event.stopPropagation();
        const parentId = event.currentTarget.dataset.id;
        const idx = this.findParentIndexById(parentId);
        
        if (idx > 0) {
            const newHierarchy = [...this.hierarchy];
            const temp = newHierarchy[idx - 1];
            newHierarchy[idx - 1] = newHierarchy[idx];
            newHierarchy[idx] = temp;
            
            this.hierarchy = newHierarchy;
            this.saveDisabled = false;
            this.markItemsAsChanged();
        }
    }

    handleMoveDownParent(event) {
        event.stopPropagation();
        const parentId = event.currentTarget.dataset.id;
        const idx = this.findParentIndexById(parentId);
        
        if (idx >= 0 && idx < this.hierarchy.length - 1) {
            const newHierarchy = [...this.hierarchy];
            const temp = newHierarchy[idx + 1];
            newHierarchy[idx + 1] = newHierarchy[idx];
            newHierarchy[idx] = temp;
            
            this.hierarchy = newHierarchy;
            this.saveDisabled = false;
            this.markItemsAsChanged();
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSave() {
    this.loading = true;
    this.error = undefined;
    try {
        let nextOrder = 10;
        const updates = [];

        for (const parent of this.hierarchy) {
            updates.push({ 
                id: String(parent.Id), 
                sortOrder: Number(nextOrder)
            });
            nextOrder += 10;

            if (parent.children && parent.children.length > 0) {
                for (const child of parent.children) {
                    updates.push({ 
                        id: String(child.Id), 
                        sortOrder: Number(nextOrder)
                    });
                    nextOrder += 10;
                }
            }
        }

        if (updates.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({ title: 'No changes', message: 'Order unchanged', variant: 'info' })
            );
            this.loading = false;
            return;
        }

        console.log('Updates to send:', JSON.stringify(updates));

        const resIds = await updateSortOrders({ updates });
        
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Success', message: 'Sort order updated', variant: 'success' })
        );

        this.dispatchEvent(new CustomEvent('ordersaved', { detail: { ids: resIds } }));

        // Keep spinner visible for 5 seconds, then close popup and refresh page
        setTimeout(() => {
           
            this.dispatchEvent(new CloseActionScreenEvent());
            // Refresh the page after popup closes
            setTimeout(() => {
                 let origin = location.origin;
                    // console.log('origin'+origin);
                    location.href=`${origin}/lightning/r/Quote/${this.recordId}/view`;
            }, 100); // Small delay to ensure popup closes first
        }, 5000); // 5 second delay

    } catch (err) {
        this.error = err.body ? err.body.message : err.message;
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Error', message: this.error, variant: 'error' })
        );
        this.loading = false;
    }
}
}