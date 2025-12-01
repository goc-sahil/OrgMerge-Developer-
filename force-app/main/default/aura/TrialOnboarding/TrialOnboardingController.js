({
	afterRender: function(cmp, event, helper) {
		var action = cmp.get("c.getTrialDaysLeft");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            console.log('response state',state,response.getReturnValue());
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('result',result);
                var days = result.days;
                var createdDate = result.createdDate;
                var orgId = result.orgId;
                var mydomain = result.mydomain;
                var baseUrl = 'https://desktosvc.secure.force.com/trial/trialonboarding';
                if(days){
	                cmp.find("trialonboarding-iframe").getElement().setAttribute("src",baseUrl+"?days="+days+"&createdDate="+createdDate+"&orgId="+orgId+"&mydomain="+mydomain);      
                }else {
					cmp.find("trialonboarding-iframe").getElement().setAttribute("src",baseUrl+"?days="+days+"&createdDate="+createdDate+"&orgId="+orgId+"&mydomain="+mydomain);      
                }
                cmp.set("v.showLoadingSpinner",false);
            }
            else if (state === "INCOMPLETE") {
                cmp.find("trialonboarding-iframe").getElement().setAttribute("src",baseUrl+"?days=-1&createdDate=-1&orgId=-1&mydomain=-1");
                cmp.set("v.showLoadingSpinner",false);
            }
            else if (state === "ERROR") {
                cmp.find("trialonboarding-iframe").getElement().setAttribute("src",baseUrl+"?days=-1&createdDate=-1&orgId=-1&mydomain=-1");
                cmp.set("v.showLoadingSpinner",false);
            }
           
        });
        $A.enqueueAction(action);

	}
})