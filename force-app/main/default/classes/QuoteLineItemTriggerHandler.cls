/*public class QuoteLineItemTriggerHandler {
    public static void setSubscriptionTerm(List<QuoteLineItem> newItems) {
        System.debug('=== ENTERING setSubscriptionTerm ===');
		set<Id> productId = new set<Id>();
        set<Id> quoteId = new set<Id>();
		List<ProductSellingModel> sellingModels = [SELECT Id FROM ProductSellingModel WHERE Name = 'Monthly Fee' LIMIT 1];
		List<ProductSellingModel> AnnualFee = [SELECT Id FROM ProductSellingModel WHERE Name = 'Annual Fee' LIMIT 1];
            Id sellingModelId;
            if (!sellingModels.isEmpty()) {
                sellingModelId = sellingModels[0].Id;
            } else {
                System.debug('No ProductSellingModel found for Monthly Fee — skipping subscription logic');
                return; // or handle fallback logic
            }
        List<Pricebook2> honeywellBooks = [
            SELECT Id FROM Pricebook2 WHERE Name = 'HONEYWELL Pricebook' LIMIT 1
        ];
        if (honeywellBooks.isEmpty()) {
            System.debug('No Honeywell pricebook found — skipping logic');
            return;
        }
        Id honeyWellPricebookId = honeywellBooks[0].Id;
		List<Pricebook2> lenel2YearWarrantyPricebook = [
            SELECT Id FROM Pricebook2 WHERE Name = 'Lenel 2 Year Warranty Pricebook' LIMIT 1
        ];
        if (lenel2YearWarrantyPricebook.isEmpty()) {
            System.debug('No lenel2YearWarrantyPricebook  found — skipping logic');
            return;
        }
        Id lenel2YearWarrantyPricebookId = lenel2YearWarrantyPricebook[0].Id;

		List<QuoteLineItem> items = new List<QuoteLineItem>();
        for(QuoteLineItem qli: newItems){
			System.debug('QLI Product2: ' + qli.Product2Id + ' | Quote: ' + qli.QuoteId );
			
			productId.add(qli.Product2Id);
           	quoteId.add(qli.QuoteId) ;
            
        }
		Set<Id> pbIds = new Set<Id>{
            lenel2YearWarrantyPricebookId,
            honeyWellPricebookId
        };

        List<Quote> quote = [
            SELECT Id
            FROM Quote
            WHERE Id IN :quoteId
            AND Pricebook2Id IN :pbIds
        ];
        List<Product2> pro = [Select Id from Product2 where Id IN:productId AND Family IN ('Enterprise','Industrial')];
        if(quote.isEmpty() || pro.isEmpty()){
            System.debug('No matching quotes or products found — exiting.');
            return;

        }
		Set<Id> validQuoteIds = new Set<Id>();
        Set<Id> validProductIds = new Set<Id>();

        for (Quote q : quote){
			validQuoteIds.add(q.Id);
        } 
        for (Product2 p : pro){
            validProductIds.add(p.Id);
        }
        // Step 1: Collect Quote Ids
        List<Id> quoteIds = new List<Id>();
        for (QuoteLineItem qli : newItems) {
            if (qli.QuoteId != null && validProductIds.contains(qli.Product2Id) && validQuoteIds.contains(qli.QuoteId)&& qli.ProductSellingModelId == sellingModelId && qli.Quote.Pricebook2Id == honeyWellPricebookId) {
				qli.SubscriptionTerm = 30;
                qli.EndDate = null;
                quoteIds.add(qli.QuoteId);
                System.debug('Collected Quote Id: ' + qli.QuoteId);
            }
            else if(qli.QuoteId != null && validProductIds.contains(qli.Product2Id) && validQuoteIds.contains(qli.QuoteId) &&qli.ProductSellingModelId == AnnualFee[0].Id && qli.Quote.Pricebook2Id == lenel2YearWarrantyPricebookId){
				qli.SubscriptionTerm = 2;
                qli.EndDate = null;
                quoteIds.add(qli.QuoteId);
            }
            else {
                System.debug('Skipped QuoteLineItem without QuoteId: ' + qli);
            }
        }
        System.debug('Total Quote Ids collected: ' + quoteIds);


        // Step 5: Enqueue CalloutPricingProcedure
        if (!quoteIds.isEmpty()) {
            System.debug('Enqueuing CalloutPricingProcedure with QuoteId: ' + quoteIds[0]);
            System.enqueueJob(new CalloutPricingProcedure(quoteIds[0]));
        } else {
            System.debug('No QuoteIds found. Skipping CalloutPricingProcedure enqueue.');
        }

        System.debug('=== EXITING setSubscriptionTerm ===');
    }
}*/
public class QuoteLineItemTriggerHandler {

    public static void setSubscriptionTerm(List<QuoteLineItem> newItems) {

        System.debug('=== ENTERING setSubscriptionTerm ===');

        // ---------------------------------------------------------------
        // Collect productIds and quoteIds
        // ---------------------------------------------------------------
        Set<Id> productIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem qli : newItems) {
            if (qli.Product2Id != null) productIds.add(qli.Product2Id);
            if (qli.QuoteId != null) quoteIds.add(qli.QuoteId);
        }

        // ---------------------------------------------------------------
        // Fetch Selling Models
        // ---------------------------------------------------------------
        Id monthlyFeeModelId;
        Id annualFeeModelId;

        List<ProductSellingModel> sellingModels = [
            SELECT Id, Name
            FROM ProductSellingModel
            WHERE Name IN ('Monthly Fee', 'Annual Fee')
            LIMIT 2
        ];

        for (ProductSellingModel sm : sellingModels) {
            if (sm.Name == 'Monthly Fee') monthlyFeeModelId = sm.Id;
            if (sm.Name == 'Annual Fee') annualFeeModelId = sm.Id;
        }

        if (monthlyFeeModelId == null || annualFeeModelId == null) {
            System.debug('Required SellingModels missing — exiting');
            return;
        }

        // ---------------------------------------------------------------
        // Fetch Pricebooks (Honeywell + Lenel)
        // ---------------------------------------------------------------
        Id honeywellPBId;
        Id lenelPBId;

        List<Pricebook2> pricebooks = [
            SELECT Id, Name
            FROM Pricebook2
            WHERE Name IN (
                'HONEYWELL Pricebook',
                'Lenel 2 Year Warranty Pricebook'
            )
        ];

        for (Pricebook2 pb : pricebooks) {
            if (pb.Name == 'HONEYWELL Pricebook') honeywellPBId = pb.Id;
            if (pb.Name == 'Lenel 2 Year Warranty Pricebook') lenelPBId = pb.Id;
        }

        if (honeywellPBId == null || lenelPBId == null) {
            System.debug('Required Pricebooks missing — exiting');
            return;
        }
		// Fetch Device Annual product
        Id deviceAnnualProductId;
        
        List<Product2> deviceAnnualProd = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Device  Annual'
            LIMIT 1
        ];
        
        if (!deviceAnnualProd.isEmpty()) {
            deviceAnnualProductId = deviceAnnualProd[0].Id;
        }


        // Create set for filtering in SOQL
        Set<Id> validPBIds = new Set<Id>{ honeywellPBId, lenelPBId };

        // ---------------------------------------------------------------
        // Fetch Quotes (Pricebook2Id included)
        // ---------------------------------------------------------------
        Map<Id, Id> quoteToPB = new Map<Id, Id>();

        for (Quote q : [
            SELECT Id, Pricebook2Id
            FROM Quote
            WHERE Id IN :quoteIds
            AND Pricebook2Id IN :validPBIds
        ]) {
            quoteToPB.put(q.Id, q.Pricebook2Id);
        }

        if (quoteToPB.isEmpty()) {
            System.debug('No matching quotes found — exiting');
            return;
        }

        // ---------------------------------------------------------------
        // Fetch Products (Enterprise + Industrial only)
        // ---------------------------------------------------------------
        Set<Id> validProductIds = new Set<Id>();
		Set<Id> validProductIds2 = new Set<Id>();
        for (Product2 p : [
            SELECT Id,Family
            FROM Product2
            WHERE Id IN :productIds
            AND Family IN ('Enterprise', 'Industrial','Software') 
        ]) {
            if(p.Family!='Software'){
				validProductIds.add(p.Id);
            }
            else if(p.Family=='Software'&&p.Id == deviceAnnualProductId){
				validProductIds2.add(p.Id);
            }
        }

        if (validProductIds.isEmpty() && validProductIds2.isEmpty()) {
            System.debug('No matching products found — exiting');
            return;
        }

        // ---------------------------------------------------------------
        // Main Logic — Assign SubscriptionTerms
        // ---------------------------------------------------------------
        List<Id> finalQuoteIds = new List<Id>();

        for (QuoteLineItem qli : newItems) {

            // skip if Quote/Prod not valid
            if (qli.QuoteId == null ||
                (!validProductIds.contains(qli.Product2Id)&& !validProductIds2.contains(qli.Product2Id)) ||
                !quoteToPB.containsKey(qli.QuoteId)) {

                System.debug('Skipping QLI: ' + qli.Id);
                continue;
            }

            Id pbId = quoteToPB.get(qli.QuoteId);

            // Monthly Fee — Honeywell
            if (qli.ProductSellingModelId == monthlyFeeModelId &&
                pbId == honeywellPBId) {

                qli.SubscriptionTerm = 30;
                qli.EndDate = null;
                finalQuoteIds.add(qli.QuoteId);
            }

            // Annual Fee — Lenel
            else if (qli.ProductSellingModelId == annualFeeModelId &&
                     pbId == lenelPBId) {

                qli.SubscriptionTerm = 2;
                qli.EndDate = null;
                finalQuoteIds.add(qli.QuoteId);
            }
			// New requirement: If product = Device Annual AND pricebook = Lenel PB
            else if (
                qli.Product2Id == deviceAnnualProductId &&
                pbId == lenelPBId
            ) {
				system.debug('in the else');
                qli.SubscriptionTerm = 2;
                qli.EndDate = null;
                finalQuoteIds.add(qli.QuoteId);
            }

        }

        System.debug('Final QuoteIds: ' + finalQuoteIds);

        // ---------------------------------------------------------------
        // Enqueue repricing job
        // ---------------------------------------------------------------
        if (!finalQuoteIds.isEmpty()) {
            System.enqueueJob(new CalloutPricingProcedure(finalQuoteIds[0]));
        }

        System.debug('=== EXITING setSubscriptionTerm ===');
    }

}