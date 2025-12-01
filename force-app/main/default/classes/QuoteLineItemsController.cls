public class QuoteLineItemsController {
    public Id internalQuoteId {
        get { return internalQuoteId; }
        set {
            internalQuoteId = value;
            loadSortedLineItems();
        }
    }
    public Quote quoteRecord { get; set; }
    public List<QuoteLineItem> sortedLineItems { get; set; }
    public QuoteLineItemsController() {
        sortedLineItems = new List<QuoteLineItem>();
        // Do not load items here since quoteId isn't set yet
    }
    private void loadSortedLineItems() {
        if (internalQuoteId == null) {
            System.debug('Quote ID is null in loadSortedLineItems');
            return;
        }
        sortedLineItems = [
            SELECT Id, Product_Name__c, ListPrice, UnitPrice, Quantity, Discount,
                   Discount__c, Unit_Price__c, TotalPrice, SortOrder
            FROM QuoteLineItem
            WHERE QuoteId = :internalQuoteId
            ORDER BY SortOrder ASC
        ];
        
    }
}