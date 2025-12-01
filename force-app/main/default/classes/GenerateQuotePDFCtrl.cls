public with sharing class GenerateQuotePDFCtrl {
    public String objectName { get; set; } // To check if the objectName is Quote/Order
    public Id id; // Id of the record
    public Boolean showDiscountColumn { get; set; }
    public Boolean hideDiscountColumn { get; set; }
    public Boolean showInidanAddress { get; set; }
    public Boolean showState { get; set; }
    // Quote details
    public QuoteWrapper quote { get; set; }
    public Integer itemIndex { get; set; }
    
    // Getter for lumpsum discount visibility
    public Boolean getHasLumpsumDiscount() {
        return quote != null && quote.hasLumpsumDiscount != null && quote.hasLumpsumDiscount;
    }
    // Wrapper class to hold quote details
    
    public class QuoteWrapper {
        public Id Id { get; set; }
        public String Name { get; set; }
        public DateTime CreatedDate { get; set; }
        public Date ExpirationDate { get; set; }
        public String QuoteNumberConstant { get; set; }
        public String PaymentTerms { get; set; }
        public String Incoterms { get; set; }
        public Id AccountId { get; set; }
        public String BillingCountry { get; set;}
        public String BillingState { get; set;}
        public String BillingCity { get; set;}
        public String BillingStreet { get; set;}
        public String BillingPostalCode { get; set;}
        public String ShippingCountry { get; set;}
        public String ShippingState { get; set;}
        public String ShippingCity { get; set;}
        public String ShippingStreet { get; set;}
        public String ShippingPostalCode { get; set;}
        public String TaxIdNumber { get; set; }
        public String ContactEmail { get; set; }
        public String ContactPhone { get; set; }
        public String ContactName { get; set; }
        public String SubTotal { get; set; }
        public String LumpsumDiscount { get; set; }
        public String FinalGrandTotal { get; set; }
        public Boolean hasLumpsumDiscount { get; set; }
        public String CurrencyIsoCode { get; set; }
        public String AdditionalComments { get; set; }
        public List<QuoteLineItemWrapper> QuoteLineItems { get; set; }
        public String Status { get; set; }
        public Boolean ShowButton { get; set; }
        public String BillToName { get; set; }
        public String ShipToName { get; set; }
        public String CustomerNumber { get; set; }
    }
    
    // Wrapper class to hold quote line item details
    public class QuoteLineItemWrapper {
        public Id Id { get; set; }
        public String ProductName { get; set; }
        public Integer Quantity { get; set; }
        public String UnitPrice { get; set; }
        public String TotalPrice { get; set; }
        public String ListPrice {get; set;}
        public String Discount { get; set;}
        public String Description { get; set;}
    }
    public static String formatDecimal(Decimal amount) {
        String amountString = String.valueOf(amount);
        // Split the string into integer and decimal parts
        List<String> parts = amountString.split('\\.');
        // Format the integer part with commas
        Decimal newValue = Decimal.valueOf((String)parts[0]);
        String formattedIntegerPart = newValue.format();
        
        // Check if a decimal part exists
        if (parts.size() == 1) {
            // If no decimal part, append ".00"
            return formattedIntegerPart + '.00';
        } else {
            // Get decimal part and ensure it's exactly 2 digits
            String decimalPart = parts[1];
            if (decimalPart.length() > 2) {
                // If more than 2 digits, round and truncate
                Integer roundedValue = Integer.valueOf(decimalPart.substring(0, 3));
                if (roundedValue >= 995) {
                    // Handle edge case where rounding up affects the integer part
                    newValue = Decimal.valueOf(amountString).setScale(2, RoundingMode.HALF_UP);
                    return newValue.format();
                }
                decimalPart = String.valueOf(Math.round(Decimal.valueOf(decimalPart) / Math.pow(10, decimalPart.length() - 2))).leftPad(2, '0');
            } else if (decimalPart.length() < 2) {
                // If less than 2 digits, pad with zeros
                decimalPart = decimalPart.rightPad(2, '0');
            }
            return formattedIntegerPart + '.' + decimalPart;
        }
    }
    
    // Constructor
    public GenerateQuotePDFCtrl() {
        //System.debug('id');
        id = ApexPages.currentPage().getParameters().get('Id'); // Get Id from Aura component
        //System.debug('id'+id);
        if (String.isNotBlank(id)) {
            objectName = ApexPages.currentPage().getParameters().get('ObjectName');
            //System.debug('id'+id);
            if (objectName == 'isQuote') {
                quote = getQuoteDetails(id);
            }
        }

        showDiscountColumn = hasDiscount(quote.QuoteLineItems);
    }
    
    // Method to retrieve quote details with related information
    @TestVisible
    private QuoteWrapper getQuoteDetails(Id quoteId) {
        QuoteWrapper quoteDetails = new QuoteWrapper();
        
        // Query to retrieve required fields from Quote object along with related Account and Contact fields
        Quote queriedQuote = [SELECT Id, Name, CreatedDate, Contact.Email, Contact.Name, Contact.Phone, ExpirationDate, Quote_PDF_Version__c,BillingName,ShippingName,
                                    Account.Customer_Number__c, QuoteAccount.Customer_Number__c, Payment_Terms__c, IncoTerms__c, Account.Id, QuoteAccount.Id,
                                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Account.Tax_ID_Number__c, QuoteAccount.Tax_ID_Number__c,
                                    ShippingCity, ShippingCountry, ShippingState, ShippingStreet, ShippingPostalCode, SubTotal__c, LumpsumDiscount__c, Final_Grand_Total__c, CurrencyIsoCode, Additional__c, Show_Button__c, Status 
                             FROM Quote
                             WHERE Id = :quoteId WITH SECURITY_ENFORCED];
        
        // Populate QuoteWrapper object with quote details
        quoteDetails.Id = queriedQuote.Id;
        quoteDetails.Name = queriedQuote.Name;
        quoteDetails.CustomerNumber = queriedQuote.QuoteAccount.Customer_Number__c;
        quoteDetails.CreatedDate = queriedQuote.CreatedDate;
        quoteDetails.ExpirationDate = queriedQuote.ExpirationDate;
        quoteDetails.QuoteNumberConstant = queriedQuote.Quote_PDF_Version__c;
        quoteDetails.PaymentTerms = queriedQuote.Payment_Terms__c;
        quoteDetails.Incoterms = queriedQuote.IncoTerms__c;
        quoteDetails.AccountId = queriedQuote.QuoteAccount.Id;
        quoteDetails.BillingCountry = queriedQuote.BillingCountry;
        quoteDetails.BillingState = queriedQuote.BillingState;
        quoteDetails.BillingCity = queriedQuote.BillingCity;
        quoteDetails.BillingStreet = queriedQuote.BillingStreet;
        quoteDetails.BillingPostalCode = queriedQuote.BillingPostalCode;
        quoteDetails.ShippingCountry = queriedQuote.ShippingCountry;
        quoteDetails.ShippingState = queriedQuote.ShippingState;
        quoteDetails.ShippingCity = queriedQuote.ShippingCity;
        quoteDetails.ShippingStreet = queriedQuote.ShippingStreet;
        quoteDetails.ShippingPostalCode = queriedQuote.ShippingPostalCode;
        quoteDetails.TaxIdNumber = queriedQuote.QuoteAccount.Tax_ID_Number__c;
        quoteDetails.CurrencyIsoCode = queriedQuote.CurrencyIsoCode;
        if(queriedQuote.Additional__c != null)
        {
            String comments = queriedQuote.Additional__c;
            String trimComments = comments.trim();
            if(trimComments.length() > 0){
            
                quoteDetails.AdditionalComments = '- '+trimComments;
            }
            else{

                quoteDetails.AdditionalComments = queriedQuote.Additional__c;

            }
        }
        else{
            quoteDetails.AdditionalComments = queriedQuote.Additional__c;
        }

        quoteDetails.ShowButton = queriedQuote.Show_Button__c;
        quoteDetails.Status = queriedQuote.Status;
        quoteDetails.BillToName = queriedQuote.BillingName;
        quoteDetails.ShipToName = queriedQuote.ShippingName ;
        quoteDetails.ContactEmail = queriedQuote.Contact.Email;
        quoteDetails.ContactPhone = queriedQuote.Contact.Phone;
        quoteDetails.ContactName = queriedQuote.Contact.Name;
       
        if(queriedQuote.CurrencyIsoCode == 'INR'){
            quoteDetails.SubTotal = '₹'+formatDecimal(queriedQuote.SubTotal__c != null ? queriedQuote.SubTotal__c : 0);
            quoteDetails.LumpsumDiscount = '₹'+formatDecimal(queriedQuote.LumpsumDiscount__c != null ? queriedQuote.LumpsumDiscount__c : 0);
            quoteDetails.FinalGrandTotal = '₹'+formatDecimal(queriedQuote.Final_Grand_Total__c != null ? queriedQuote.Final_Grand_Total__c : 0);
            // System.debug('quoteDetails.SubTotal '+quoteDetails.SubTotal );
            // System.debug('quoteDetails.LumpsumDiscount '+quoteDetails.LumpsumDiscount );
            // System.debug('quoteDetails.FinalGrandTotal '+quoteDetails.FinalGrandTotal );
        }
        else{
            quoteDetails.SubTotal = '$'+formatDecimal(queriedQuote.SubTotal__c != null ? queriedQuote.SubTotal__c : 0);
            quoteDetails.LumpsumDiscount = '$'+formatDecimal(queriedQuote.LumpsumDiscount__c != null ? queriedQuote.LumpsumDiscount__c : 0);
            quoteDetails.FinalGrandTotal = '$'+formatDecimal(queriedQuote.Final_Grand_Total__c != null ? queriedQuote.Final_Grand_Total__c : 0);   
            // System.debug('quoteDetails.SubTotal '+quoteDetails.SubTotal );
            // System.debug('quoteDetails.LumpsumDiscount '+quoteDetails.LumpsumDiscount );
            // System.debug('quoteDetails.FinalGrandTotal '+quoteDetails.FinalGrandTotal ); 
        }
        
        // Set the flag for whether lumpsum discount exists
        System.debug('queriedQuote.LumpsumDiscount__c value: ' + queriedQuote.LumpsumDiscount__c);
        if(queriedQuote.LumpsumDiscount__c != null && queriedQuote.LumpsumDiscount__c > 0){
            quoteDetails.hasLumpsumDiscount = true;
        }
        else{
            quoteDetails.hasLumpsumDiscount = false;
        }
        System.debug('quoteDetails.hasLumpsumDiscount '+quoteDetails.hasLumpsumDiscount );
        if(quoteDetails.BillingState == '' || quoteDetails.ShippingState == '' || quoteDetails.BillingState == null || quoteDetails.ShippingState == null){
            showState = false;
        }
        else{
            showState = true;
        }
        if(quoteDetails.BillingCountry == 'India'){
            showInidanAddress = true;
        }
        else{
            showInidanAddress = false;
        }

        // Retrieve and populate Quote Line Items
        quoteDetails.QuoteLineItems = getQuoteLineItems(quoteId);
        //System.debug('1'+quoteDetails);
        // Boolean showButton =  getShowButton(quoteDetails);
        return quoteDetails;
    }
    
    // Method to retrieve and populate Quote Line Items
    @TestVisible
    private List<QuoteLineItemWrapper> getQuoteLineItems(Id quoteId) {
        List<QuoteLineItemWrapper> quoteLineItemWrappers = new List<QuoteLineItemWrapper>();
        Quote quote = [SELECT AccountId,CurrencyIsoCode FROM Quote WHERE Id = :quoteId];
        
        // Query to retrieve Quote Line Items related to the quote
        List<QuoteLineItem> quoteLineItems = [SELECT Id, Product_Name__c, Product_Description__c, Quantity, UnitPrice,Unit_Price__c, TotalPrice, ListPrice, Discount 
                                              FROM QuoteLineItem
                                              WHERE QuoteId = :quoteId WITH SECURITY_ENFORCED ORDER BY SortOrder];
        String currencyISOCode = quote.CurrencyIsoCode;
        // Populate Quote Line Items for the quote
        for (QuoteLineItem lineItem : quoteLineItems) {
            QuoteLineItemWrapper lineItemWrapper = new QuoteLineItemWrapper();
            lineItemWrapper.Id = lineItem.Id;
            lineItemWrapper.ProductName = lineItem.Product_Name__c;
            lineItemWrapper.Quantity = Integer.valueOf(lineItem.Quantity);
            if(currencyISOCode == 'INR'){
                lineItemWrapper.UnitPrice = '₹'+formatDecimal(lineItem.UnitPrice); 
            }
            else {
                
                lineItemWrapper.UnitPrice = '$'+formatDecimal(lineItem.UnitPrice);    
                
            }
            lineItemWrapper.Description = lineItem.Product_Description__c;
            if(currencyISOCode == 'INR'){
                lineItemWrapper.TotalPrice = '₹'+formatDecimal(lineItem.TotalPrice); 
            }
            else {
                lineItemWrapper.TotalPrice = '$'+formatDecimal(lineItem.TotalPrice);     
            }
            if(currencyISOCode == 'INR'){
                lineItemWrapper.ListPrice = '₹'+formatDecimal(lineItem.Unit_Price__c);
            }
            else {
                lineItemWrapper.ListPrice = '$'+formatDecimal(lineItem.Unit_Price__c);     
            }
            if(lineItem.Discount!=null && lineItem.Discount!=0){
                lineItemWrapper.Discount = String.valueOf(lineItem.Discount) + '%';
            }
            else {
                lineItemWrapper.Discount = '-';
            }
            
            quoteLineItemWrappers.add(lineItemWrapper);
        }
        //System.debug('2'+quoteLineItemWrappers);
        return quoteLineItemWrappers;
    }
    public Boolean hasDiscount(List<QuoteLineItemWrapper> quoteLineItems) {
        showDiscountColumn = false;
        hideDiscountColumn = false;
        
        for (QuoteLineItemWrapper item : quoteLineItems) {
            if (item.Discount != null && item.Discount != '' && item.Discount !='-' && item.Discount != '0.00%') {
                showDiscountColumn = true;
                return true; // Return true if discount exists
            }
        }
        
        hideDiscountColumn = true;
        return false; 
    }
   
}