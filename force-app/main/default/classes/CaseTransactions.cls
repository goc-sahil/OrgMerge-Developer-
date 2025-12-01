public class CaseTransactions {

    @InvocableMethod(label='Insert Accounts' description='Inse    rts the accounts specified and returns the IDs of the new accounts.')
    public static list<string> checkmultipicklistvalues(list<wrapperX> AB) {
     system.debug('------'+AB);
      ID Caseid;
        for(wrapperX wrap : AB){
            system.debug('------'+wrap.a1);
            system.debug('------'+wrap.a2);
            Caseid=wrap.a2.get(0);
             system.debug('------'+Caseid);
                   }
                   
        List<case> caseidlist = [select id,test_labels_1__c from case where id =: Caseid];    
        system.debug('------'+caseidlist); 
                   
        return null;
    }
    
    
    public class wrapperX
    {
    @invocablevariable
    public List<String> a1;
    @invocablevariable
    public list<ID> a2;
    }

}