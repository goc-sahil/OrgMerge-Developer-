public class TrialOnboardingController {
    
    
    public class ReturnData{
        @auraenabled
        public String orgId;
        @auraenabled
        public Long days;
        @auraenabled
        public datetime createdDate;
        @auraenabled
        public String mydomain;
    }
    
    @auraenabled
    public static ReturnData getTrialDaysLeft(){
        ReturnData returnValue = new ReturnData();
        Organization org = [select Id, TrialExpirationDate, CreatedDate from Organization][0];
        //DateTime trialExpirationDate = [select TrialExpirationDate, CreatedDate from Organization][0].TrialExpirationDate;
        if(org.TrialExpirationDate != null){
         	returnValue.days = (org.TrialExpirationDate.getTime() - System.now().getTime())/1000/60/60/24;
        }
        //DateTime createdDate = org.CreatedDate;
        returnValue.createdDate = org.CreatedDate;
        returnValue.orgId = org.Id;
        String url = System.Url.getSalesforceBaseUrl().toExternalForm();
		String mydomain = url.left(url.indexOf('.')).replace('https://','');
        returnValue.mydomain = mydomain;
        return returnValue;
    }

}