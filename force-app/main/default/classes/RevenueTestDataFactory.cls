@isTest
public class RevenueTestDataFactory {

    // RETURN TYPE IF NEEDED BY TEST CLASS
    public class QuoteResults {
        public Id honeyQuoteId;
        public Id lenelQuoteId;
    }

    @isTest
    public static QuoteResults setupRevenueTestData() {

        QuoteResults qr = new QuoteResults();

        // ---------------------------------------------
        // PRICEBOOKS
        // ---------------------------------------------
        Id stdPB = Test.getStandardPricebookId();
        Pricebook2 honeyPB = createPricebook('Honeywell Pricebook');
        Pricebook2 lenelPB = createPricebook('Lenel 2 Year Warranty Pricebook');

        // ---------------------------------------------
        // ACCOUNTS & CONTACTS
        // ---------------------------------------------
        Account accHoney = createAccount('Honeywell Customer', 'CUST001', 'TAX123', 'India', honeyPB.Id);
        Account accLenel = createAccount('Lenel Customer', 'CUST002', 'TAX999', 'India', lenelPB.Id);

        Contact cHoney = createContact(accHoney.Id, 'Doe', 'test@example.com', '9999999999');
        Contact cLenel = createContact(accLenel.Id, 'Doe', 'lenel@example.com', '8888888888');

        // ---------------------------------------------
        // CURRENT QUOTE NUMBER
        // ---------------------------------------------
        createCurrentQuoteNumber(3570, 1095);

        // ---------------------------------------------
        // OPPORTUNITIES
        // ---------------------------------------------
        Opportunity oppHoney = createOpportunity(
            'Honey Opp', accHoney.Id, honeyPB.Id, 'USD'
        );

        Opportunity oppLenel = createOpportunity(
            'Lenel Opp', accLenel.Id, lenelPB.Id, 'USD'
        );

        // ---------------------------------------------
        // QUOTES
        // ---------------------------------------------
        Quote qtHoney = createQuote(
            'Honey Quote', oppHoney.Id, cHoney.Id, accHoney.Id, 'India', honeyPB.Id, 'Q-001'
        );
        System.debug('qtHoney' + qtHoney);

        Quote qtLenel = createQuote(
            'Lenel Quote', oppLenel.Id, cLenel.Id, accLenel.Id, 'India', lenelPB.Id, 'Q-002'
        );

        qr.honeyQuoteId = qtHoney.Id;
        qr.lenelQuoteId = qtLenel.Id;

        // ---------------------------------------------
        // PRODUCTS + SELLING MODELS
        // ---------------------------------------------
        Product2 honeyProduct = createProduct('Test Product', 'Enterprise', 'TP001');
        Product2 lenelProduct  = createProduct('Lenel Annual Product', 'Enterprise', 'LP001');
        Product2 deviceAnnualProduct  = createProduct('Device  Annual', 'Software', 'DA001');
        
        ProductSellingModel monthly = createSellingModel('Monthly Fee', 'Evergreen', 1, 'Months');
        ProductSellingModel oneYear = createSellingModel('Annual Fee', 'Evergreen', 1, 'Annual');

        createProductSellingModelOption(honeyProduct.Id, monthly.Id);
        createProductSellingModelOption(lenelProduct.Id, oneYear.Id);
        createProductSellingModelOption(deviceAnnualProduct.Id, oneYear.Id);

        // ---------------------------------------------
        // PBEs
        // ---------------------------------------------
        PricebookEntry pbeHoney = createPricebookEntry(honeyProduct.Id, honeyPB.Id, monthly.Id, 1000);
        PricebookEntry pbeLenel = createPricebookEntry(lenelProduct.Id,  lenelPB.Id,  oneYear.Id, 2000);
        PricebookEntry pbeDeviceAnnual = createPricebookEntry(deviceAnnualProduct.Id,  lenelPB.Id,  oneYear.Id, 200);
        System.debug('pbeHoney' + pbeHoney);
        System.debug('pbeDeviceAnnual' + pbeDeviceAnnual);

        // ---------------------------------------------
        // QUOTE LINE ITEMS
        // ---------------------------------------------
        createQuoteLineItem(qtHoney.Id, honeyProduct.Id, pbeHoney.Id, 2, 5000, 10);
        createQuoteLineItem(qtLenel.Id, lenelProduct.Id, pbeLenel.Id, 1, 2000, 0);
        createQuoteLineItem(qtLenel.Id, pbeDeviceAnnual.Id, pbeDeviceAnnual.Id, 1, 200, 0);

        return qr;
    }

    // ============================================================
    // HELPERS (Reusable for Any Test)
    // ============================================================

    // PRICEBOOK
    public static Pricebook2 createPricebook(String name) {
        Pricebook2 pb = new Pricebook2(Name = name, IsActive = true);
        insert pb;
        return pb;
    }

    // ACCOUNT
    public static Account createAccount(String name, String custNo, String taxId, String country, Id pricebookId) {
        Account acc = new Account(
            Name = name,
            Customer_Number__c = custNo,
            Tax_ID_Number__c = taxId,
            BillingCountry = country,
            Price_Book__c = pricebookId
        );
        insert acc;

        // ensure PB field is set
        acc.Price_Book__c = pricebookId;
        update acc;

        return acc;
    }

    // CONTACT
    public static Contact createContact(Id accountId, String lastName, String email, String phone) {
        Contact c = new Contact(
            LastName = lastName,
            Email = email,
            Phone = phone,
            AccountId = accountId
        );
        insert c;
        return c;
    }

    // CURRENT QUOTE NUMBER
    public static void createCurrentQuoteNumber(Integer globalNo, Integer indiaNo) {
        currentQuoteNumber__c cs = new currentQuoteNumber__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            currentQuoteNumber__c = globalNo,
            currentQuoteNumberIndia__c = indiaNo
        );
        insert cs;
    }

    // OPPORTUNITY
    public static Opportunity createOpportunity(String name, Id accountId, Id pbId, String currencyIso) {
        Opportunity opp = new Opportunity(
            Name = name,
            StageName = 'Prospect',
            CloseDate = System.today().addDays(10),
            CurrencyIsoCode = currencyIso,
            AccountId = accountId,
            Engagement_Model__c = 'Direct',
            Opportunity_tagging__c = 'Enterprise',
            End_Customer__c = accountId,
            Pricebook2Id = pbId
        );
        insert opp;
        return opp;
    }

    // QUOTE
    public static Quote createQuote(String name, Id oppId, Id contactId, Id accId, String country, Id pbId, String pdfVersion) {
        Quote q = new Quote(
            Name = name,
            OpportunityId = oppId,
            ContactId = contactId,
            QuoteAccountId = accId,
            BillingName = name + ' Billing',
            ShippingName = name + ' Shipping',
            BillingCountry = country,
            ShippingCountry = country,
            Payment_Terms__c = 'Net 30',
            IncoTerms__c = 'FOB',
            Quote_PDF_Version__c = pdfVersion,
            CurrencyIsoCode = 'USD',
            Status = 'Draft',
            Pricebook2Id = pbId
        );
        insert q;
        return q;
    }

    // PRODUCT
    public static Product2 createProduct(String name, String family, String code) {
        Product2 p = new Product2(
            Name = name,
            Family = family,
            ProductCode = code,
            IsActive = true
        );
        insert p;
        return p;
    }

    // SELLING MODEL
    public static ProductSellingModel createSellingModel(String name, String type, Integer term, String unit) {
        ProductSellingModel sm = new ProductSellingModel(
            Name = name,
            SellingModelType = type,
            PricingTerm = term,
            PricingTermUnit = unit,
            Status = 'Active'
        );
        insert sm;
        return sm;
    }

    // PRODUCT SELLING MODEL OPTION
    public static ProductSellingModelOption createProductSellingModelOption(Id productId, Id modelId) {
        ProductSellingModelOption op = new ProductSellingModelOption(
            Product2Id = productId,
            ProductSellingModelId = modelId
        );
        insert op;
        return op;
    }

    // PRICEBOOK ENTRY
    public static PricebookEntry createPricebookEntry(Id productId, Id pbId, Id modelId, Decimal price) {

        // Standard PB entry
        PricebookEntry stdPbe = new PricebookEntry(
            Product2Id = productId,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = price,
            IsActive = true,
            ProductSellingModelId = modelId,
            CurrencyIsoCode = 'USD'
        );
        insert stdPbe;

        // Actual PB entry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = productId,
            Pricebook2Id = pbId,
            UnitPrice = price,
            IsActive = true,
            ProductSellingModelId = modelId,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;

        return pbe;
    }

    // QUOTE LINE ITEM
    public static QuoteLineItem createQuoteLineItem(Id quoteId, Id productId, Id pbeId, Decimal qty, Decimal unitPrice, Decimal discount) {
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quoteId,
            Product2Id = productId,
            PricebookEntryId = pbeId,
            Quantity = qty,
            UnitPrice = unitPrice,
            Discount = discount
        );
        insert qli;
        return qli;
    }
}