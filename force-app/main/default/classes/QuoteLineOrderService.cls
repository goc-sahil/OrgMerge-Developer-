/**
* @File Name : QuoteLineOrderService.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : November 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 21, 2025 |   | Initial Version
**/

public with sharing class QuoteLineOrderService {
    
    /**
     * @description DTO for transferring QuoteLineItem data to LWC
     */
    public class QuoteLineItemDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public Id parentQuoteLineItemId;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Id product2Id;
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public Decimal totalPrice;
        @AuraEnabled public String productName;
        
        public QuoteLineItemDTO(QuoteLineItem qli) {
            this.id = qli.Id;
            this.parentQuoteLineItemId = qli.ParentQuoteLineItemId;
            this.sortOrder = qli.SortOrder != null ? Integer.valueOf(qli.SortOrder) : 0;
            //this.name = qli.Name;
            this.quantity = qli.Quantity;
            this.product2Id = qli.Product2Id;
            this.unitPrice = qli.UnitPrice;
            this.totalPrice = qli.TotalPrice;
            this.productName = qli.Product2?.Name;
        }
    }
    
    /**
     * @description DTO for sort order updates
     */
    public class SortOrderUpdate {
        @AuraEnabled public Id id;
        @AuraEnabled public Integer newSortOrder;
        @AuraEnabled public Id parentQuoteLineItemId;
    }
    
    /**
     * @description Retrieves all QuoteLineItems for a given Quote
     * @param quoteId The Quote ID
     * @return List of QuoteLineItemDTO objects
     */
    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItemDTO> getQuoteLineItemsForQuote(Id quoteId) {
        try {
            // Validate input
            if (quoteId == null) {
                throw new AuraHandledException('Quote ID is required');
            }
            
            // Check FLS and CRUD permissions
            if (!Schema.sObjectType.QuoteLineItem.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access Quote Line Items');
            }
            
            // Query all QuoteLineItems for the Quote with Product information
            List<QuoteLineItem> quoteLineItems = [
                SELECT Id, ParentQuoteLineItemId, SortOrder, Product2Id, 
                       Quantity, UnitPrice, TotalPrice, Product2.Name
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY SortOrder ASC NULLS LAST, Id
            ];
            
            // Convert to DTOs
            List<QuoteLineItemDTO> dtos = new List<QuoteLineItemDTO>();
            for (QuoteLineItem qli : quoteLineItems) {
                dtos.add(new QuoteLineItemDTO(qli));
            }
            
            return dtos;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Quote Line Items: ' + e.getMessage());
        }
    }
    
    /**
     * @description Saves updated sort orders for QuoteLineItems
     * @param quoteId The Quote ID
     * @param updates List of SortOrderUpdate objects
     */
    @AuraEnabled
    public static void saveQuoteLineItemSortOrders(Id quoteId, List<SortOrderUpdate> updates) {
        try {
            // Validate input
            if (quoteId == null || updates == null || updates.isEmpty()) {
                throw new AuraHandledException('Quote ID and updates are required');
            }
            
            // Check FLS and CRUD permissions
            if (!Schema.sObjectType.QuoteLineItem.isUpdateable() || 
                !Schema.sObjectType.QuoteLineItem.fields.SortOrder.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to updatee Quote Line Items');
            }
            
            // Collect all IDs from updates
            Set<Id> lineItemIds = new Set<Id>();
            for (SortOrderUpdate updatee : updates) {
                if (updatee.id != null) {
                    lineItemIds.add(updatee.id);
                }
            }
            
            // Query existing records to validate they belong to the quote
            Map<Id, QuoteLineItem> existingItems = new Map<Id, QuoteLineItem>([
                SELECT Id, QuoteId, ParentQuoteLineItemId, SortOrder
                FROM QuoteLineItem
                WHERE Id IN :lineItemIds
            ]);
            
            // Validate all records belong to the specified Quote
            for (QuoteLineItem qli : existingItems.values()) {
                if (qli.QuoteId != quoteId) {
                    throw new AuraHandledException('Invalid operation: Line items must belong to the specified Quote');
                }
            }
            
            // Prepare records for updatee
            List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
            for (SortOrderUpdate updatee : updates) {
                if (existingItems.containsKey(updatee.id)) {
                    QuoteLineItem qli = existingItems.get(updatee.id);
                    
                    // Only updatee if sort order has changed
                    if (qli.SortOrder != updatee.newSortOrder) {
                        qli.SortOrder = updatee.newSortOrder;
                        itemsToUpdate.add(qli);
                    }
                }
            }
            
            // Perform bulk updatee
            if (!itemsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(itemsToUpdate, false);
                
                // Collect errors
                List<String> errors = new List<String>();
                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        String errorMsg = 'Record ' + itemsToUpdate[i].Id + ': ';
                        for (Database.Error error : results[i].getErrors()) {
                            errorMsg += error.getMessage() + '; ';
                        }
                        errors.add(errorMsg);
                    }
                }
                
                // Throw exception if there were errors
                if (!errors.isEmpty()) {
                    throw new AuraHandledException('Update failed: ' + String.join(errors, ' | '));
                }
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving sort orders: ' + e.getMessage());
        }
    }
    
    /**
     * @description Reindexes sort orders to ensure contiguous integers
     * This can be called if sort orders become fragmented
     * @param quoteId The Quote ID
     */
    @AuraEnabled
    public static void reindexSortOrders(Id quoteId) {
        try {
            if (quoteId == null) {
                throw new AuraHandledException('Quote ID is required');
            }
            
            // Check permissions
            if (!Schema.sObjectType.QuoteLineItem.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to updatee Quote Line Items');
            }
            
            // Query all items ordered by current sort order
            List<QuoteLineItem> allItems = [
                SELECT Id, ParentQuoteLineItemId, SortOrder
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
                ORDER BY SortOrder ASC NULLS LAST, Id
            ];
            
            // Reassign sort orders as contiguous integers (10, 20, 30, etc.)
            Integer newSortOrder = 10;
            List<QuoteLineItem> itemsToUpdate = new List<QuoteLineItem>();
            
            for (QuoteLineItem qli : allItems) {
                if (qli.SortOrder != newSortOrder) {
                    qli.SortOrder = newSortOrder;
                    itemsToUpdate.add(qli);
                }
                newSortOrder += 10;
            }
            
            if (!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error reindexing sort orders: ' + e.getMessage());
        }
    }
}