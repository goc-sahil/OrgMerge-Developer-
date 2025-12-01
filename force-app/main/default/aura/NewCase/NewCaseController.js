({
    doInit: function(cmp, event, helper) {
        cmp.set("v.isOpen", true);
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            var isCon = 0
            if (response == true)
                isCon = 1;
            cmp.set("v.Isconsole",isCon);
        })
    },
    
    handleLoad: function(cmp, event, helper) {
        cmp.set('v.showSpinner', false);
        cmp.set("v.isOpen", true);
    },
    
    handleSubmit: function(cmp, event, helper) {
        
        cmp.set('v.disabled', true);
        cmp.set('v.showSpinner', true);
        debugger;
        var sSubject = cmp.find("SubjectField")
        var vSubject = sSubject.get("v.value");
        if (vSubject == null || vSubject.trim() == '')
        {
        	var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type" : "error",
                "mode" : "pester",
                "message": "Subject field is empty!!!"
            });
            toastEvent.fire();
        
        }
        else
            cmp.find("newCaseForm").submit();
            
        return;
    },
    
    handleError: function(cmp, event, helper) {
        //debugger;
    },
    
    handleSuccess: function(cmp, event, helper) {
        debugger;
        /*var sSubject = cmp.find("SubjectField")
        var vSubject = sSubject.get("v.value");
        alert(vSubject);
        if (vSubject == null)
        {
            sSubject.set("v.errors", [{message:"Invalue Subject value!!!"}]);
        	return;
        }
        return;*/
        var params = event.getParams();
        cmp.set('v.recordId', params.response.id);
        cmp.set('v.saved', true);
        cmp.set("v.isOpen", false);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId" : cmp.get('v.recordId'),
            "slideDevName": "Detail"
        });
        navEvt.fire();
    },
    
    cancelDialog : function(cmp, helper) {
        var workspaceAPI = cmp.find("workspace");
        //debugger;
        if (cmp.get("v.Isconsole") == 1)
        {
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.closeTab({tabId: focusedTabId});
            })
            .catch(function(error) {
                console.log(error);
            });
        }
        else
        {
            var navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope" : "Case"
            });
            navEvt.fire();
        }
    },
    
    
});