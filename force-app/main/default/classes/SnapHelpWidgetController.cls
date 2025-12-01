public class SnapHelpWidgetController {
    @AuraEnabled
    public static Integer getRemainingDays() {
        Object dt = [Select trialexpirationdate from organization][0].get('trialexpirationdate');  
            if (Test.isRunningTest()) {
                dt = (DateTime) (System.now().date() + 1);
            }
        Date now = System.now().date();
        if (dt != null) {
          Date da = ((DateTime) dt).date();
          return now.daysBetween(da);    
        } 
        return null;
    }
}