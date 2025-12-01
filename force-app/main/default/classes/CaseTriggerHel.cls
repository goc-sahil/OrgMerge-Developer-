public class CaseTriggerHel {
    
    private static boolean run = true;
    
    public static boolean runOnce(){
    
        System.debug('@@@@ run:: ' + run);
    
    if(run){
     run=false;
     return true;
    }else{
        return run;
    }
    }

    @InvocableMethod
    public static void updateTotalCaseOpenAge(List<case> inp){
        
        System.debug('@@@@ ' + inp);
        
        /*
        Case caseRecord;
        if(inp != null && inp.size() > 0){
            caseRecord = inp.get(0);
        }
        
        System.debug('@@@@ caseRecord' + caseRecord);
        
        //case objCase =  [select id,Case_Current_Open_Age__c,Case_Open_Age_Total__c from case where id =: caseRecord.id  limit 1];
        Case objCase = caseRecord;
        String currentAge = objCase.Case_Current_Open_Age__c + '';
                        
                        String oldTotalOpenAge = objCase.Case_Open_Age_Total__c;
                        
                        System.debug(' 111111 currentAge: ' + currentAge + ', oldTotalOpenAge : ' + oldTotalOpenAge);
                        
                            
                            if(oldTotalOpenAge != null && oldTotalOpenAge.length() > 0){
                                
                                Double currentHours,currentMinutes;
                                Double oldTotalHours,oldTotalMinutes;
                                
                                // Extract Current Hours and Minutes...
                                if(currentAge != null && currentAge.length() > 0){
                                    List<String> listcurrentHHMM= currentAge.split('Hours');
                                    if(listcurrentHHMM != null && listcurrentHHMM.size() > 0){
                                        if(listcurrentHHMM.get(0) != null){
                                            currentHours = Math.ceil(Decimal.valueOf(listcurrentHHMM.get(0).trim()));
                                            System.debug(' 11111 currentHours ' + currentHours);
                                        }
                                        
                                        if(listcurrentHHMM.get(1) != null){
                                            System.debug(listcurrentHHMM.get(1).split('minutes'));
                                            List<String> listCurrentMin = listcurrentHHMM.get(1).split('minutes');
                                            if(listCurrentMin != null && listCurrentMin.size() > 0){
                                                currentMinutes = Decimal.valueOf(listCurrentMin.get(0).trim());
                                                System.debug(' 11111 currentMinutes ' + currentMinutes);
                                            }
                                        }
                                    }
                                }
                                
                                // Extract old Hours and Minutes...
                                List<String> listOldHHMM= oldTotalOpenAge.split('Hours');
                                if(listOldHHMM != null && listOldHHMM.size() > 0){
                                    if(listOldHHMM.get(0) != null){
                                        oldTotalHours = Math.ceil(Decimal.valueOf(listOldHHMM.get(0).trim()));
                                        System.debug(' 11111 oldTotalHours ' + oldTotalHours);
                                    }
                                    
                                    if(listOldHHMM.get(1) != null){
                                        System.debug(listOldHHMM.get(1).split('minutes'));
                                        List<String> listCurrentMin = listOldHHMM.get(1).split('minutes');
                                        if(listCurrentMin != null && listCurrentMin.size() > 0){
                                            oldTotalMinutes = Decimal.valueOf(listCurrentMin.get(0).trim());
                                            System.debug(' 11111 oldTotalMinutes ' + oldTotalMinutes);
                                        }
                                    }
                                }
                                
                                String finalTotalHours = (oldTotalHours + currentHours) + ' Hours ' + (oldTotalMinutes + currentMinutes) +  ' minutes';
                                System.debug(' 111111 finalTotalHours: ' + finalTotalHours);
                                objCase.Case_Open_Age_Total__c = finalTotalHours;
                            }else{
                                objCase.Case_Open_Age_Total__c = currentAge;
                            }
    */
    }
}