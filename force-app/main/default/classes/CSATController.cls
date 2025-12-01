public class CSATController {
    
    //public String caseId {get; set;}
    public Integer agentFeedbackScore {get; set;}
    public Integer productFeedbackScore {get; set;}
    public String feedbackComments {get; set;}
    
    
    public PageReference saveFeedback(){
        
        if ((agentFeedbackScore == 0 || agentFeedbackScore == null) && ApexPages.currentPage().getParameters().get('Score') != null)
            agentFeedbackScore = Integer.ValueOf(ApexPages.currentPage().getParameters().get('Score'));
        String afs;
        String pfs;
        String agentName;
        
        if(agentFeedbackScore != null ) afs =  String.ValueOf(agentFeedbackScore);
        if(productFeedbackScore != null ) pfs =  String.ValueOf(productFeedbackScore);
        if(ApexPages.currentPage().getParameters().get('AgentName') != null) agentName = ApexPages.currentPage().getParameters().get('AgentName');
        
        Case c = new Case(
        	id = ApexPages.currentPage().getParameters().get('caseid'),
            agent_feedback_score__c = afs,
            product_feedback_score__c = null, //replace with pfs for including product feedback score
            feedback_comments__c = feedbackComments ,
            Feedback_for_Agent__c = agentName
        );
        try{
        	update c;
        }catch (Exception e){
        	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
            return null;
        }	
        PageReference pageRef = new PageReference('/apex/CSATThankyou');
        return pageRef;
        //return null;
    }

}