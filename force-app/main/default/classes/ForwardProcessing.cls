public class ForwardProcessing {
    @InvocableMethod(label='Forward Processing' description='Set the contact based on the original email address')
    public static void forwarProcessing(List<Id> caseIds){
        
        Set<String> emails = new set<String>();
        Map<Id,String> caseEmails = new Map<id, String>();
        Map<Id,String> caseNames = new Map<Id, String>();
        Map<String,String> contactEmails = new Map<String,String>();
        Map<String, Id> newContactsMap = new Map<String, Id>();
        Set<String> createdContactEmails = new Set<String>();
        List<Contact> newContacts = new List<Contact>();
        Set<String> userEmails = new Set<String>();
        Account HoldingAccount;
        String name;
        Boolean updateFlag = false;
        System.Debug('Inside Forward Processing');
        
        
        
        List<Case> cases = [select Id, subject, description, contactId, accountId, sourceid, SuppliedEmail from case where id in :caseIds];
       
        //Email Message record not available! Not sure why.
        //List<EmailMessage> emailmessages = [select id, parentid from emailmessage where parentid in :caseIds];
        //System.debug('Email Messages: '+emailmessages);
        
        if(cases.size() > 0){            
            List<User> users = [select id, email from user where isactive = true];
            if (users.size()>0)
                for(User u:users)
                    userEmails.add(u.email);
            
            //regex for looking at the from address within the description (email body)
            Pattern  p =  Pattern.compile('(?i)from: *([a-z ,]*)[\" <](\\b[A-Z0-9._%+-]+@[A-Z0-9.-]+.[A-Z]{2,}\\b)');
            //regex for checking if there is a comma in the name
            Pattern  p2 = Pattern.compile('([a-zA-Z]+) *, *([a-zA-Z]+)');
            Matcher pm;
            Matcher pm2;
            
            //loop to set supplied email and supplied name if case subject contains Fwd: or Fw
            //if so, the loop also sets contactid to null
            for (Case c:cases) {
                System.Debug('CaseId-description: '+c.Id+'-'+c.description);
                if(userEmails.contains(c.SuppliedEmail) && c.subject != null
                   && (c.subject.toLowerCase().contains('fw:') || c.subject.toLowerCase().contains('fwd'))){                       
                         pm = p.matcher( c.description );
                         if( pm.find() ){ 
                             System.Debug('Matches- Name: '+pm.group(1)+', email: '+pm.group(2));
                              
                             caseEmails.put(c.Id,pm.group(2));
                             emails.add(pm.group(2));   
                             c.SuppliedEmail = pm.group(2);
                             System.Debug('Point 1');
                             
                             if(pm.group(1).contains(',')){
                                 pm2 = p2.matcher(pm.group(1));
                                 if(pm2.find()) { 
                                     c.SuppliedName = pm2.group(2)+' '+pm2.group(1); 
                                     System.Debug('pm2 matches: '+pm2.group(2)+' '+pm2.group(1));
                                 }
                                 
                             }
                             
                             else if(!pm.group(1).contains(',')){
                                 c.SuppliedName = pm.group(1);
                             }
                             caseNames.put(c.Id, c.SuppliedName);
                             System.Debug('Point 2');
                             c.contactId = null;
                         }
                }
            }
           	System.Debug('Emails: '+caseEmails);
            System.Debug('Names: '+caseNames);
            
            
            //Rest of the method runs only there was Fwd email found
            if(caseEmails.size()>0){
                
                List<Contact> ctList = [select id, email from contact where email in :emails];
                System.Debug('Contact Size: '+ctList.size());
                if(ctList.size() > 0){
    
                    for(Contact ct:ctList){
                        if(contactEmails.get(ct.email) == null){
                            contactEmails.put(ct.email, ct.id);
                        }
                        else if (contactEmails.get(ct.email) != null){
                            contactEmails.put(ct.email,contactEmails.get(ct.email)+','+ct.Id);
                        }
                    }
                }                
                System.Debug('Contact Emails: '+contactEmails);
                
                //Loop for creating contacts if contact does not exist                
                for(Case c:Cases){   
                    if (caseEmails.get(c.Id) != null 
                        && contactEmails.get(caseEmails.get(c.Id)) == null 
                        && caseNames.get(c.Id) != null 
                        && caseNames.get(c.Id).trim().length() > 0
                        && !createdContactEmails.contains(caseEmails.get(c.Id))){
                            System.Debug('Creating Contact');
                            
                            //Checking for existing account with name 'Holding Account'. If it does not exist, create.
                            List<Account> AccList = [select id from Account where Name = 'Holding Account' limit 1];
                            if (AccList.size()>0) HoldingAccount = AccList[0];   
                            else {
                                HoldingAccount = new Account(Name='Holding Account'); 
                                try{  
                                    insert HoldingAccount;
                                }catch(Exception e){
                                    HoldingAccount = null;
                                }
                            }                            
                            String[] nameParts = caseNames.get(c.Id).trim().split(' ',2);
                            Id AccountId = HoldingAccount==null?null:HoldingAccount.Id;
                            Contact ct;
                            System.Debug('Name Parts: '+nameParts);
                            if (nameParts.size() == 2){
                                 ct = new Contact(FirstName=nameParts[0],
                                                            LastName=nameParts[1],
                                                            Email=caseEmails.get(c.Id),
                                                  			AccountId=AccountId
                                                           );
                            }
                            else if (nameParts.size() == 1) {
                                 ct = new Contact(LastName=nameParts[0],                                                            
                                                     Email=caseEmails.get(c.Id),
                                                     AccountId=AccountId
                                                           );
                            }                        
                            newContacts.add(ct);
                            createdContactEmails.add(caseEmails.get(c.Id));
                        }
                }
                if(newContacts.size() > 0){
                    insert newContacts;
                    for (Contact ct:newContacts){
                        newContactsMap.put(ct.email,ct.id);
                    }
                }
                
                //Loop for setting contactid on Case
                for(Case c:Cases){
                    if(caseEmails.get(c.Id) != null){
                        if(contactEmails.get(caseEmails.get(c.Id)) != null){                            
                            if(contactEmails.get(caseEmails.get(c.Id)).contains(',')){
                                c.ContactId = null;
                            }
                            else if(!contactEmails.get(caseEmails.get(c.Id)).contains(',')){
                                c.ContactId = (Id)contactEmails.get(caseEmails.get(c.Id));
                            }
                        } 
                        else if(contactEmails.get(caseEmails.get(c.Id)) == null){
                            if (newContactsMap.get(caseEmails.get(c.Id)) != null)
                                c.ContactId = newContactsMap.get(caseEmails.get(c.Id));
                        }
                        
                    }  
                }              
                update cases; 
            }
            
            
        }
            
            
        	
    }

}