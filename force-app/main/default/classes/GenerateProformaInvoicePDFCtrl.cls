public class GenerateProformaInvoicePDFCtrl {
 public String objectName { get; set; } // To check if the objectName is Quote/Order
    public Id id; // Id of the record
    public Boolean showDiscountColumn { get; set; }
    public Boolean hideDiscountColumn { get; set; }
    public Boolean showInidanAddress { get; set; }
	public Boolean USAPadding { get; set; }
	public Boolean isINR { get; set; }
	public Boolean isUSD { get; set; }
    public Boolean isCAD { get; set; }
    public Boolean showState { get; set; }
	public String remittanceHtml { get; set; }
    // Quote details
    public QuoteWrapper quote { get; set; }
    public Integer itemIndex { get; set; }
    // Wrapper class to hold quote details

    public Decimal PaidAmount { get;  set; }
    public Decimal NowPaying { get;  set; }
    public Decimal RemainingAmount { get;  set; }
    public Decimal taxAmount{get; set;}
    public Decimal totalGrandAmount{get; set;}
    public String selectedTaxType{get;set;}
    public Date dueDate{get;set;}
    public Date tDate{get;set;}
    public String shipVia{get;set;}
    public String index{get;set;}
    public String indexString{get;set;}
    public Decimal installment{get;set;}
    public String balanceString{get;set;}
    public String totalPaidPercentage{get;set;}
    public String totalUnpaidPercentage{get;set;}
    public Integer totalBalance{get;set;}
    public Boolean hasPaidAmount{get;set;}
    public Boolean hasNowPaying{get;set;}
    public Boolean hasBalance{get;set;}
    public Boolean hasTax{get;set;}
    public Boolean hasCGST{get;set;}
    public String CGST{get;set;}
    public Decimal AmountCGST{get;set;}
    public String paymentTerm{get;set;}
    
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
        public String TotalPrice { get; set; }
        public String CurrencyIsoCode { get; set; }
        public String AdditionalComments { get; set; }
        public List<QuoteLineItemWrapper> QuoteLineItems { get; set; }
        public String Status { get; set; }
        public Boolean ShowButton { get; set; }
        public String BillToName { get; set; }
        public String ShipToName { get; set; }
        public String CustomerNumber { get; set; }
        public Decimal PaidAmount { get; private set; }
        public Decimal NowPaying { get; private set; }
        public Decimal RemainingAmount { get; private set; }
        public String quoteCurrency {get;set;}
		public String quoteNumber {get;set;}
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
        public String SalesPrice { get; set;}
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
    public GenerateProformaInvoicePDFCtrl() {
        id = ApexPages.currentPage().getParameters().get('Id'); // Get Id from Aura component
        if (String.isNotBlank(id)) {
            objectName = ApexPages.currentPage().getParameters().get('ObjectName');
            if (objectName == 'isQuote') {
                quote = getQuoteDetails(id);
            }
        }
        showDiscountColumn = hasDiscount(quote.QuoteLineItems);
        // Get the parameters from the URL
        String paid = ApexPages.currentPage().getParameters().get('paid');
        String paying = ApexPages.currentPage().getParameters().get('paying');
        String remaining = ApexPages.currentPage().getParameters().get('remaining');
        String taxAmount = ApexPages.currentPage().getParameters().get('taxAmount');
        String totalGrandAmount = ApexPages.currentPage().getParameters().get('totalGrandAmount');
        String paymentTerm = ApexPages.currentPage().getParameters().get('paymentTerm');
        this.paymentTerm = paymentTerm;
        this.totalGrandAmount = totalGrandAmount != null ? Decimal.valueOf(totalGrandAmount) : 0.00;
        if(this.PaidAmount == this.totalGrandAmount){
            this.PaidAmount = 0.00;
        }
		this.selectedTaxType = ApexPages.currentPage().getParameters().get('selectedTaxType');
        String dueDate = ApexPages.currentPage().getParameters().get('dueDate'); // String parameter
        this.dueDate = Date.valueOf(dueDate); // Correct conversion
        String tDate = ApexPages.currentPage().getParameters().get('tDate'); // String parameter
        
        this.taxAmount = taxAmount != null ? Decimal.valueOf(taxAmount) : 0.00;
        this.tDate = Date.valueOf(tDate); // Correct conversion
        
		
        if(this.selectedTaxType == 'IGST'){
            this.selectedTaxType = this.selectedTaxType + '(18%)';
            
        }else if(this.selectedTaxType == 'SGST/CGST'){
            this.selectedTaxType = 'SGST(9%)';
            this.CGST = 'CGST(9%)';
            this.hasCGST = true;
            this.taxAmount = this.totalGrandAmount * 0.09 ;
            this.amountCGST = this.totalGrandAmount * 0.09 ;
            
        }else{
            this.selectedTaxType = this.selectedTaxType + '(13%)';
        }
        
        String shipVia = ApexPages.currentPage().getParameters().get('shipVia');
        String index = ApexPages.currentPage().getParameters().get('index');
        this.totalUnpaidPercentage = ApexPages.currentPage().getParameters().get('totalUnpaidPercentage');
        this.totalpaidPercentage = ApexPages.currentPage().getParameters().get('totalpaidPercentage');
        // Convert to Decimal
        this.PaidAmount = paid != null ? Decimal.valueOf(paid) : 0.00;
        this.NowPaying = paying != null ? Decimal.valueOf(paying) : 0.00;
        
        this.RemainingAmount = remaining != null ? Decimal.valueOf(remaining) : 0.00;
        
        
       // this.selectedTaxType = selectedTaxType;
        this.shipVia = shipVia;
        //convert to interger
        
        if(this.totalUnpaidPercentage == '100'){
            	this.PaidAmount = 0.00;
                this.NowPaying = 0.00;
                this.RemainingAmount = 0.00;
            
        }else{
            Integer totalPaidUnpaid = Integer.valueOf(this.totalUnpaidPercentage) + Integer.valueOf(this.totalpaidPercentage);
            if(totalPaidUnpaid > 0){
                 totalBalance = 100 - totalPaidUnpaid;
            }
            
            if(this.PaidAmount != 0.00 && this.NowPaying !=0.00){
                    String suffix = '';
                    Integer num = Integer.valueOf(index);
                    if(num == 2){
                        suffix = 'nd';
                    }else if(num == 3){
                        suffix = 'rd';
                    }else{
                        suffix = 'th';
                    }
                    this.indexString = index + suffix + ' installment';
                }else{
                    this.indexString = 'Advance Payable';
            }
            
            if(this.PaidAmount != 0.00 && this.NowPaying == 0.00){
                this.balanceString = 'Balance Payable';
            }else{
                this.balanceString = 'Balance';
            }
        }
        
           // Set the flag for Visualforce rendering
		this.hasPaidAmount = (this.PaidAmount != 0.00); 
        this.hasNowPaying = (this.NowPaying != 0.00);
        this.hasBalance = (this.RemainingAmount != 0.00);
        this.hasTax = (this.taxAmount != 0.00);
        
    }
    
    // Method to retrieve quote details with related information
    @TestVisible
    private QuoteWrapper getQuoteDetails(Id quoteId) {
        QuoteWrapper quoteDetails = new QuoteWrapper();
        
        // Query to retrieve required fields from Quote object along with related Account and Contact fields
        Quote queriedQuote = [SELECT Id, Name, CreatedDate, Contact.Email, Contact.Name, Contact.Phone, ExpirationDate, Quote_PDF_Version__c,BillingName,ShippingName,
                                    Account.Customer_Number__c, QuoteAccount.Customer_Number__c, Payment_Terms__c, IncoTerms__c, Account.Id, QuoteAccount.Id,
                                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Account.Tax_ID_Number__c, QuoteAccount.Tax_ID_Number__c,QuoteNumber,CurrencyIsoCode,
                                    ShippingCity, ShippingCountry, ShippingState, ShippingStreet, ShippingPostalCode, TotalPrice, Opportunity.CurrencyIsoCode, Additional__c, Show_Button__c, Status 
                             FROM Quote
                             WHERE Id = :quoteId WITH SECURITY_ENFORCED];
        
        // Populate QuoteWrapper object with quote details
        quoteDetails.Id = queriedQuote.Id;
        quoteDetails.Name = queriedQuote.Name;
        quoteDetails.CustomerNumber = queriedQuote.QuoteAccount.Customer_Number__c;
        quoteDetails.quoteNumber = queriedQuote.QuoteNumber;
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
        quoteDetails.CurrencyIsoCode = queriedQuote.Opportunity.CurrencyIsoCode;
        if(quoteDetails.CurrencyIsoCode == 'INR'){
            quoteDetails.quoteCurrency = '₹';
        }else{
            quoteDetails.quoteCurrency = '$';
        }
            
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
       
        if(queriedQuote.Opportunity.CurrencyIsoCode == 'INR'){
            quoteDetails.TotalPrice = '₹'+formatDecimal(queriedQuote.TotalPrice);
            System.debug('quoteDetails.TotalPrice '+quoteDetails.TotalPrice );
        }
        else {
            quoteDetails.TotalPrice = '$'+formatDecimal(queriedQuote.TotalPrice);   
            System.debug('quoteDetails.TotalPrice '+quoteDetails.TotalPrice ); 
        }
        if(quoteDetails.BillingState == '' || quoteDetails.ShippingState == '' || quoteDetails.BillingState == null || quoteDetails.ShippingState == null){
            showState = false;
        }
        else{
            showState = true;
        }
        if(queriedQuote.CurrencyIsoCode == 'INR'){
            showInidanAddress = true;
        }
        else{
            showInidanAddress = false;
        }

        // Retrieve and populate Quote Line Items
        quoteDetails.QuoteLineItems = getQuoteLineItems(quoteId);
        if(queriedQuote.CurrencyIsoCode == 'INR'||queriedQuote.CurrencyIsoCode == 'CAD'){
			USAPadding = false;
        }
        else{
            USAPadding = true;
        }
        //System.debug('1'+quoteDetails);
        // Boolean showButton =  getShowButton(quoteDetails);
        remittanceHtml = generateRemittanceHtml(queriedQuote.CurrencyIsoCode);
        return quoteDetails;
    }
    
    // Method to retrieve and populate Quote Line Items
    @TestVisible
    private List<QuoteLineItemWrapper> getQuoteLineItems(Id quoteId) {
        List<QuoteLineItemWrapper> quoteLineItemWrappers = new List<QuoteLineItemWrapper>();
        Quote quote = [SELECT AccountId,Opportunity.CurrencyIsoCode,CurrencyIsoCode FROM Quote WHERE Id = :quoteId];
        
        // Query to retrieve Quote Line Items related to the quote
        List<QuoteLineItem> quoteLineItems = [SELECT Id, Product_Name__c, Product_Description__c, Quantity, UnitPrice,Unit_Price__c, TotalPrice, ListPrice, Discount 
                                              FROM QuoteLineItem
                                              WHERE QuoteId = :quoteId WITH SECURITY_ENFORCED ORDER BY SortOrder];
        String currencyISOCode = quote.Opportunity.CurrencyIsoCode;
        String currencyCodeQuote = quote.CurrencyIsoCode;
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
            Decimal unitPrice = lineItem.UnitPrice;
            Decimal discount = (lineItem.Discount != null) ? lineItem.Discount : 0;
            Decimal discountedPrice = unitPrice;
            
            if (discount > 0) {
                discountedPrice = unitPrice - (unitPrice * (discount / 100));
            }
            
            // Determine currency symbol
            String currencySymbol = (currencyCodeQuote == 'INR') ? '₹' : '$';
            
            // Format and assign
            lineItemWrapper.SalesPrice = currencySymbol + formatDecimal(discountedPrice);
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
    @TestVisible
	private String generateRemittanceHtml(String code) {
    if (code == 'INR') {
        return '<div style="border:1px solid #000; padding:5px;page-break-before: always;">' +
                '<table style="width:100%; font-family:Arial, sans-serif; font-size:10pt;">' +
                '<tr><td style="color:#a09999;">' +
                '<span class="remittance-header" style="text-decoration: underline;"><b>REMITTANCE INFORMATION</b></span><br/><br/>' +
                '<span class="remittance-header">Bank Draft Payment</span><br/>' +
                'Please make Bank Drafts payable to “Invixium Access Pvt. Ltd.” and mail to “203-204 Elanza Vertex, Sindhu Bhavan Road, Bodakdev, Ahmedabad 380059 Gujarat.”<br/><br/>' +
                '<span class="remittance-header">NEFT Transfer</span><br/>' +
                '(All bank charges are to be borne by the remitter)<br/><br/>' +
                '<span class="remittance-info-title">Beneficiary Name:</span> Invixium Access Pvt Ltd.<br/>' +
                '<span class="remittance-info-title">Beneficiary Address:</span> “203-204 Elanza Vertex, Sindhu Bhavan Road, Bodakdev, Ahmedabad 380059 Gujarat”<br/><br/>' +
                '<span class="remittance-info-title">Account Number:</span> 07832020001544<br/>' +
                '<span class="remittance-info-title">Currency:</span> Indian Rupee (INR)<br/>' +
                '<span class="remittance-info-title">IFSC Code:</span> HDFC0000783<br/>' +
                '<span class="remittance-info-title">MICR Code:</span> 380240014<br/>' +
                '<span class="remittance-info-title">Bank:</span> HDFC Bank Showroom<br/>' +
                '<span style="display:inline-block; padding-left:40px;">No. 001, Platinum Plaza, Part 4,<br/>Bodakdev, Ahmedabad, Gujarat 380054</span><br/><br/>' +
                '<span class="remittance-header"><b>Please reference the invoice number when making payment.</b></span>' +
                '</td></tr></table></div>';

    } 
    else if (code == 'USD') {
        return '<div style="border:1px solid #000; padding:5px;page-break-before: always;">' +
            '<table style="width:100%; font-family:Arial, sans-serif; font-size:10pt;">' +
            '<tr><td style="color:#a09999;">' +
            '<span class="remittance-header" style="text-decoration: underline;"><b>REMITTANCE INFORMATION</b></span><br/><br/>' +
            '<span class="remittance-info-title">Cheque Payment within Canada</span><br/>' +
            'Please make cheques payable to “Invixium Access Inc.” and mail to ' +
            '“111 Gordon Baker Road, Suite 300 Toronto, ON M2H 3R1 CANADA.”<br/><br/>' +
            '<span class="remittance-header">EFT Wire Transfer</span><br/>' +
            '(All bank charges are to be borne by the remitter)<br/><br/>' +
            '<span class="remittance-info-title">Beneficiary Name:</span> Invixium Access Inc.<br/>' +
            '<span class="remittance-info-title">Beneficiary Address:</span> 111 Gordon Baker Road, Suite 300 Toronto, ON M2H 3R1 CANADA<br/><br/>' +
            '<span class="remittance-info-title">Beneficiary Bank:</span> Canadian Imperial Bank of Commerce<br/>' +
            '<span class="remittance-info-title">Bank address:</span> 199 Bay Street, Toronto, ON M5L 1G9, Canada<br/>' +
            '<span class="remittance-info-title">Bank Swift Code:</span> CIBCCATT<br/>' +
            '<span class="remittance-info-title">Bank/Financial Institution Number:</span> 0010<br/>' +
            '<span class="remittance-info-title">Bank Transit Number:</span> 00002<br/>' +
            '<span class="remittance-info-title">Format Code:</span> 001000002<br/>' +
            '<span class="remittance-info-title">Beneficiary Transit/Account Number:</span> 000020232017<br/>' +
            '<span class="remittance-info-title">Currency:</span> US Dollar (USD)<br/><br/>' +
            '<span class="remittance-header"><b>Please reference the invoice number when making payment.</b></span>' +
            '</td></tr></table></div>';
    } 
    else if (code == 'CAD') {
        return '<div style="border:1px solid #000; padding:5px;page-break-before: always;">' +
            '<table style="width:100%; font-family:Arial, sans-serif; font-size:10pt;">' +
            '<tr><td style="color:#a09999;">' +
            '<span class="remittance-header" style="text-decoration: underline;"><b>REMITTANCE INFORMATION</b></span><br/><br/>' +
            '<span class="remittance-header">EFT / Wire Transfer</span><br/>' +
            '(All bank charges are to be borne by the remitter)<br/><br/>' +
            '<span class="remittance-info-title">Beneficiary Name:</span> Invixium Access Inc.<br/>' +
            '<span class="remittance-info-title">Beneficiary Address:</span> 111 Gordon Baker Road, Suite 300 Toronto, ON M2H 3R1 CANADA<br/><br/>' +
            '<span class="remittance-info-title">Beneficiary Bank:</span> Canadian Imperial Bank of Commerce<br/>' +
            '<span class="remittance-info-title">Bank address:</span> 199 Bay Street, Toronto, ON M5L 1G9, Canada<br/>' +
            '<span class="remittance-info-title">Bank Swift Code:</span> CIBCCATT<br/>' +
            '<span class="remittance-info-title">Bank/Financial Institution Number:</span> 0010<br/>' +
            '<span class="remittance-info-title">Bank Transit Number:</span> 00002<br/>' +
            '<span class="remittance-info-title">Format Code:</span> 001000002<br/>' +
            '<span class="remittance-info-title">Beneficiary Transit/Account Number:</span> 000028931011<br/>' +
            '<span class="remittance-info-title">Currency:</span> Canadian Dollar (CAD)<br/><br/>' +
            '<span class="remittance-header"><b>Please reference the invoice number when making payment.</b></span>' +
            '</td></tr></table></div>';
    }
    return '';
}

}