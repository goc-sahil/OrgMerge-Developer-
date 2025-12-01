public class CasePresenceController {
    
    @AuraEnabled
    public static List<String> getSessionId() {
      List<String> retValues = new List<String>();
        retValues.add(UserInfo.getSessionId());
        retValues.add(UserInfo.getUserId());
        retValues.add(UserInfo.getName());
        String smallPhotoURL = [SELECT SmallPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()][0].SmallPhotoURL;
        retValues.add(smallPhotoURL.contains('/005/')?'':smallPhotoURL);
      System.Debug('Inside GetSessionId');
        return retValues;
       
    }
    
    @AuraEnabled
    public static Boolean publishNotification(String caseId, String userId, String username, Boolean isFirst, Boolean isOpen, String smallPhotoURL) {       
      Database.SaveResult result = EventBus.publish(
          new Case_Notification__e(CaseId__c = caseId, UserId__c = userId, User_Name__c = username, IsFirst__c = isFirst, IsOpen__c = isOpen, PhotoURL__c = smallPhotoURL));
    
        // Inspect publishing results
        if (!result.isSuccess()) {
            for (Database.Error error : result.getErrors()) {
                System.debug('Error returned: ' +
                             error.getStatusCode() +' - '+
                             error.getMessage());
            }
            return false;
        } else {
            System.debug('Event Id: ' +result.getId());
            return true;
        }
    }



}