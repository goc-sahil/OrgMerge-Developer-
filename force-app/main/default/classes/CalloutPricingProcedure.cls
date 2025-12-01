public class CalloutPricingProcedure implements Queueable, Database.AllowsCallouts {
    
    public Id quoteId;

    public CalloutPricingProcedure(Id quot) {
        this.quoteId = quot;
        System.debug('=== Constructor Called ===');
        System.debug('Received Quote Id: ' + this.quoteId);
    }

    public void execute(QueueableContext context) {
        System.debug('=== ENTERING execute() ===');
        System.debug('Queueable Context Id: ' + context.getJobId());
        System.debug('Executing CalloutPricingProcedure for Quote Id: ' + quoteId);

        try {
            updateQuotePrices();
        } catch (Exception e) {
            System.debug('❌ Exception in execute(): ' + e.getMessage());
            System.debug('❌ Stack Trace: ' + e.getStackTraceString());
        }

        System.debug('=== EXITING execute() ===');
    }

    public void updateQuotePrices() {
        System.debug('=== ENTERING updateQuotePrices() ===');
        System.debug('Quote Id: ' + quoteId);

        try {
            // Step 1: Define Pricing Settings
            PlaceQuote.PricingPreferenceEnum pricingPreference = PlaceQuote.PricingPreferenceEnum.FORCE;
            System.debug('PricingPreference set to: ' + pricingPreference);

            PlaceQuote.ConfigurationInputEnum configEnum = PlaceQuote.ConfigurationInputEnum.RunAndAllowErrors;
            System.debug('ConfigurationInputEnum set to: ' + configEnum);

            PlaceQuote.ConfigurationOptionsInput config = new PlaceQuote.ConfigurationOptionsInput();
            config.addDefaultConfiguration = true;
            config.executeConfigurationRules = true;
            config.validateAmendRenewCancel = true;
            config.validateProductCatalog = true;

            System.debug('Configuration Options Initialized: ' + JSON.serializePretty(config));

            // Step 2: Create Quote Record Reference
            PlaceQuote.RecordResource quoteRecord = new PlaceQuote.RecordResource(Quote.getSobjectType(), 'PATCH', quoteId);
            System.debug('RecordResource Created for Quote Id: ' + quoteId);

            PlaceQuote.RecordWithReferenceRequest quoteObject =
                new PlaceQuote.RecordWithReferenceRequest('refQuote', quoteRecord);
         

            // Step 3: Prepare Records List
            List<PlaceQuote.RecordWithReferenceRequest> records = new List<PlaceQuote.RecordWithReferenceRequest>();
            records.add(quoteObject);
            System.debug('Records List Prepared. Size: ' + records.size());

            // Step 4: Invoke Place Quote API
            PlaceQuote.GraphRequest graph = new PlaceQuote.GraphRequest('myGraphId', records);
            

            System.debug('=== Invoking PlaceQuoteRLMApexProcessor.execute() ===');
            PlaceQuote.PlaceQuoteResponse resp = 
                PlaceQuote.PlaceQuoteRLMApexProcessor.execute(pricingPreference, graph, configEnum, config);

            // Step 5: Log the Response
            System.debug('✅ Pricing API Response: ' + JSON.serializePretty(resp));

        } catch (Exception ex) {
            System.debug('❌ Exception in updateQuotePrices(): ' + ex.getMessage());
            System.debug('❌ Stack Trace: ' + ex.getStackTraceString());
        }

        System.debug('=== EXITING updateQuotePrices() ===');
    }
}