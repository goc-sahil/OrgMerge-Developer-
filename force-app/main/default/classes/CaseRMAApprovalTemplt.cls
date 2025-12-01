public  class CaseRMAApprovalTemplt
{
    public Id caseId {get;set;}
    public String deviceNumbers {set;}
    public String deviceFamily {get;set;}
    public String deviceType {get;set;}
    public String warrentyStatus {get;set;}
    public String hardwareIssue {get;set;}
    private List<RMA_Device_Detail__c> listRMAObj;
    
    
    public List<RMA_Device_Detail__c> getrma()
    {
        
        system.debug('ID :' + caseId);
        
        List<RMA_Device_Detail__c> listRmaDevices = [SELECT Id,Name, Device_Serial_Number__c,Device_Family__c,Device_Type__c,Warranty_Status__c,Hardware_Issue__c FROM RMA_Device_Detail__c WHERE Case__c =: caseId ];
        system.debug(listRmaDevices );
        listRMAObj = listRmaDevices;
    
        
        /*
        if(listRmaDevices != null && listRmaDevices.size() > 0){
            
            for(RMA_Device_Detail__c rmaDevDetail: listRmaDevices){
                rmaDeviceNumbers += (rmaDeviceNumbers.length() > 0 ? ',' : '') + rmaDevDetail.Name;
            }
        }*/
        return listRmaDevices;
    }
    
    public String getDeviceNumbers(){
        String rmaDeviceNumbers = '';
        deviceFamily = '';
        deviceType = '';
        warrentyStatus = '';
        hardwareIssue = '';
        if(listRMAObj != null && listRMAObj.size() > 0){
            for(RMA_Device_Detail__c rmaDevDetail: listRMAObj){
                if(rmaDevDetail.Device_Serial_Number__c != null && rmaDevDetail.Device_Serial_Number__c.length() > 0){
                    rmaDeviceNumbers += (rmaDeviceNumbers != null && rmaDeviceNumbers.length() > 0 ? ',' : '') + rmaDevDetail.Device_Serial_Number__c;
                }
                if(rmaDevDetail.Device_Family__c != null && rmaDevDetail.Device_Family__c.length() > 0){
                    deviceFamily += (deviceFamily != null && deviceFamily.length() > 0 ? ',' : '') + rmaDevDetail.Device_Family__c;
                }
                if(rmaDevDetail.Device_Type__c != null && rmaDevDetail.Device_Type__c.length() > 0){
                    deviceType += (deviceType != null && deviceType.length() > 0 ? ',' : '') + rmaDevDetail.Device_Type__c;
                }
                if(rmaDevDetail.Warranty_Status__c != null && rmaDevDetail.Warranty_Status__c.length() > 0){
                    warrentyStatus += (warrentyStatus != null && warrentyStatus.length() > 0 ? ',' : '') + rmaDevDetail.Warranty_Status__c;
                }
                if(rmaDevDetail.Hardware_Issue__c != null && rmaDevDetail.Hardware_Issue__c.length() > 0){
                    hardwareIssue += (hardwareIssue != null && hardwareIssue.length() > 0 ? ',' : '') + rmaDevDetail.Hardware_Issue__c;
                }
            }
        }
        return rmaDeviceNumbers;
    }
}