trigger CaseTriggerHelper on Case (before insert, after insert, before update, after update) {
    
    DeskComMigrationSetting__c defaultCustomSetting = DeskComMigrationSetting__c.getOrgDefaults();
    System.debug('@@ defaultCustomSetting.isMigrationEnable__c : ' + defaultCustomSetting.isMigrationEnable__c);
    
    if(Trigger.isAfter){
        System.debug('5555555 Inside after');
    }
    
    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            
            Integer lastDeskID = 0;
            AggregateResult DeskIDObj = [SELECT MAX(Desk_Id__c) DeskID FROM case];
            lastDeskID = Integer.ValueOf(DeskIDObj.get('DeskID'));
            if(lastDeskID == null){
                lastDeskID = 0;
            }
            System.debug('lastDeskID :: ' + lastDeskID);
            for(Case objCase :Trigger.new){
                if(defaultCustomSetting.isMigrationEnable__c){
                    if (!String.isBlank(objCase.labels__c)){
                        objCase.labels__c = objCase.labels__c.replace(', ', ',');
                        objCase.labels__c = objCase.labels__c.replace(' ,', ',');
                    }
                }else{
                    
                    lastDeskID++;
                    //system.debug('objCase.subject: ' + objCase.subject);
                    
                    if(!String.isBlank(objCase.subject) && !objCase.subject.contains('Case ID #')){
                        objCase.Desk_Id__c = lastDeskID ;
                        //objCase.subject = objCase.subject+' Case ID #'+lastDeskID ;
                    }
                    
                    if (String.isBlank(objCase.labels__c))     
                        objCase.labels__c = objCase.Labels_Pickval__c;
                    
                    
                }
            }
        }
    }
    
    if(!defaultCustomSetting.isMigrationEnable__c){
        if (Trigger.isUpdate && Trigger.isBefore) {
            //if (Trigger.isBefore) {
                 for(Case objCase :Trigger.new){
                     
                     String newPickListValue = objCase.Labels_Pickval__c;
                     
                     String newStatus = objCase.status;
                     
                     Case oldCase = Trigger.oldMap.get(objCase.Id);
                     
                     String oldPickListValue = oldCase.Labels_Pickval__c;
                     
                     String oldStatus = oldCase.status;
                     
                     system.debug('@@@@ newStatus:' + newStatus + ', oldStatus : ' + oldStatus);
                     if(oldStatus.equalsIgnoreCase('open') && !oldStatus.equalsIgnoreCase(newStatus)){
                        system.debug('@@@@ Case_Current_Open_Age__c:' + objCase.Case_Current_Open_Age__c);
                        system.debug('@@@@ oldCase Case_Current_Open_Age__c:' + oldCase.Case_Current_Open_Age__c);
                        objCase.Open_Age_LastValue__c = oldCase.Case_Current_Open_Age__c;
                        
                        
                        String currentAge = '';
                        if(objCase.country_assignment__c.equalsIgnoreCase('India')){
                            System.debug('Inside India...');
                            currentAge = oldCase.Idle_Case_Age_India__c + '';
                        }else if(objCase.country_assignment__c.equalsIgnoreCase('Canada')){
                            System.debug('Inside Canada...');
                            currentAge = oldCase.Idle_Case_Age_Canada__c + '';
                        }
                        
                        String oldTotalOpenAge = objCase.Case_Open_Age_Total__c;
                        
                        System.debug(' 111111 currentAge: ' + currentAge + ', oldTotalOpenAge : ' + oldTotalOpenAge);
                        
                        if(CaseTriggerHel.runOnce()){
                            if(oldTotalOpenAge != null && oldTotalOpenAge.length() > 0 && oldTotalOpenAge.containsIgnoreCase('Hours') && oldTotalOpenAge.containsIgnoreCase('minutes')){
                                
                                Double currentHours=0,currentMinutes=0;
                                Double oldTotalHours=0,oldTotalMinutes=0;
                                
                                // Extract Current Hours and Minutes...
                                if(currentAge != null && currentAge.length() > 0){
                                    List<String> listcurrentHHMM= currentAge.split('Hours');
                                    if(listcurrentHHMM != null && listcurrentHHMM.size() > 0){
                                        if(listcurrentHHMM.get(0) != null && listcurrentHHMM.get(0).length() > 0){
                                            String trimmedHours = listcurrentHHMM.get(0).trim();
                                            System.debug('@@@ trimmedHours : ' +trimmedHours);
                                            if(trimmedHours != null && trimmedHours != ''  && trimmedHours.length() > 0){
                                                System.debug(' 11111 before currentHours ' + currentHours);
                                                currentHours = Math.ceil(Decimal.valueOf(listcurrentHHMM.get(0).trim()));
                                                System.debug(' 11111 after currentHours ' + currentHours);
                                            }
                                        }
                                        
                                        if(listcurrentHHMM.get(1) != null){
                                            System.debug(listcurrentHHMM.get(1).split('minutes'));
                                            List<String> listCurrentMin = listcurrentHHMM.get(1).split('minutes');
                                            if(listCurrentMin != null && listCurrentMin.size() > 0){
                                                if(listCurrentMin.get(0).trim() != null && listCurrentMin.get(0).trim() != '' && listCurrentMin.get(0).trim().length() > 0){
                                                    currentMinutes = Decimal.valueOf(listCurrentMin.get(0).trim());
                                                    System.debug(' 11111 currentMinutes ' + currentMinutes);
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Extract old Hours and Minutes...
                                List<String> listOldHHMM= oldTotalOpenAge.split('Hours');
                                if(listOldHHMM != null && listOldHHMM.size() > 0){
                                    if(listOldHHMM.get(0) != null && listOldHHMM.get(0).trim() != '' && listOldHHMM.get(0).trim().length() > 0){
                                        oldTotalHours = Math.ceil(Decimal.valueOf(listOldHHMM.get(0).trim()));
                                        System.debug(' 11111 oldTotalHours ' + oldTotalHours);
                                    }
                                    
                                    if(listOldHHMM.get(1) != null){
                                        System.debug(listOldHHMM.get(1).split('minutes'));
                                        List<String> listCurrentMin = listOldHHMM.get(1).split('minutes');
                                        if(listCurrentMin != null && listCurrentMin.size() > 0 && listCurrentMin.get(0).trim() != '' && listCurrentMin.get(0).trim().length() > 0){
                                            oldTotalMinutes = Decimal.valueOf(listCurrentMin.get(0).trim());
                                            System.debug(' 11111 oldTotalMinutes ' + oldTotalMinutes);
                                        }
                                    }
                                }
                                
                                Decimal totalMinutes = Math.Mod(Integer.valueOf(oldTotalMinutes + currentMinutes),60);
                                
                                Decimal additionalHours = Math.Floor((oldTotalMinutes + currentMinutes)/60);
                                
                                System.debug(' 111111 totalMinutes: ' + totalMinutes + ' ,additionalHours : ' + additionalHours);
                                
                                String finalTotalHours = Integer.valueOf(oldTotalHours + currentHours + additionalHours) + ' Hours ' + totalMinutes +  ' minutes';
                                System.debug(' 111111 finalTotalHours: ' + finalTotalHours);
                                objCase.Case_Open_Age_Total__c = finalTotalHours;
                            }else{
                                objCase.Case_Open_Age_Total__c = currentAge;
                            }
                        }
                        
                     }
                     
                     system.debug('@@@@ New Value:' + newPickListValue + ', Old Value : ' + oldPickListValue);
                     
                     if(newPickListValue != null && !newPickListValue.equals(oldPickListValue)){
                         System.debug('@@@ Now Update the label.....');
                         if (String.isnotBlank(objCase.labels__c)) {
                    
                            objCase.labels__c = objCase.labels__c.replace(', ', ',');
                            objCase.labels__c = objCase.labels__c.replace(' ,', ',');
                            
                            
                            if( objCase.Labels_Pickval__c == 'Other Department Dependency Completed' ){
                                String otherdepLabelval = ',Other Department Dependency';
                                String otherdepLabelval1 = 'Other Department Dependency,';
                                String otherdepLabelval2 = 'Other Department Dependency';
                                if( (objCase.labels__c).contains(otherdepLabelval) ){
                                    objCase.labels__c= objCase.labels__c.replace(otherdepLabelval,'')+','+ objCase.Labels_Pickval__c; 
                                    
                                }else if( (objCase.labels__c).contains(otherdepLabelval1) ){
                                    objCase.labels__c= objCase.labels__c.replace(otherdepLabelval1,'')+','+ objCase.Labels_Pickval__c;
                                    
                                        }else IF( (objCase.labels__c).contains(otherdepLabelval2) ){
                                    objCase.labels__c= objCase.labels__c.replace(otherdepLabelval1,'')+ objCase.Labels_Pickval__c;
                                        }
                            } else if( objCase.Labels_Pickval__c == 'Engineering Completed'){
                                String EnggLabelval = ',Engineering Pending';
                                String EnggLabelval1 = 'Engineering Pending,';
                                String EnggLabelval2 = 'Engineering Pending';
                                if( (objCase.labels__c).contains(EnggLabelval) ){
                                    objCase.labels__c= objCase.labels__c.replace(EnggLabelval,'')+','+ objCase.Labels_Pickval__c; 
                                    
                                }else if( (objCase.labels__c).contains(EnggLabelval1) ){
                                    objCase.labels__c= objCase.labels__c.replace(EnggLabelval1,'')+','+ objCase.Labels_Pickval__c;
                                    
                                        }else IF( (objCase.labels__c).contains(EnggLabelval2) ){
                                    objCase.labels__c= objCase.labels__c.replace(EnggLabelval2,'')+ objCase.Labels_Pickval__c;
                                        }
                                
                            } else {
                                objCase.labels__c = objCase.labels__c+','+ objCase.Labels_Pickval__c;
                            
                            }
                            
                        }
                        if (String.isBlank(objCase.labels__c))     
                            objCase.labels__c = objCase.Labels_Pickval__c;
                     }
                    
                    
                 }
                
            //}
        }
    }
}