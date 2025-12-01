({
    doInit: function(component, event, helper) {
        // Call the Apex method directly from the controller
        var recordId = component.get("v.recordId");
        //console.log(recordId);
        var action = component.get("c.showButton");
        action.setParams({ recordId: recordId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                //console.log('In');
                component.set("v.showButton", result);
            } else {
                //console.log('Out');
                console.error('Unknown error');
            }
        });
        $A.enqueueAction(action);
    },
    saveInvoice: function (component, event, helper) {

        var recordId = component.get("v.recordId");
        var action = component.get("c.savePdf");
        action.setParams({ recordId: recordId });
        action.setCallback(this, function (res) {
            var state = res.getState();
            // console.log(state);
            if (state === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": 'success',
                    "message": "PDF Save"
                });
                toastEvent.fire();
            }
        })
        $A.enqueueAction(action);
    },

    handleClose: function (component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    // getQuoteDetails : function(component) {
    //     var action = component.get("c.getQuoteWrapper");
    //     action.setCallback(this, function(response) {
    //         var state = response.getState();
    //         if (state === "SUCCESS") {
    //             var quote = response.getReturnValue();
    //             component.set("v.quote", quote);
    //             // Check if the button should be visible
    //             this.checkButtonVisibility(component, quote);
    //         }
    //     });
    //     $A.enqueueAction(action);
    // },
    // checkButtonVisibility : function(component, quote) {
    //     if (quote && quote.Id) {
    //         var isApproved = quote.Status === 'Approved';
    //         var isPresented = quote.Status === 'Presented';
    //         var isAccepted = quote.Status === 'Accepted';
    //         var isDenied = quote.Status === 'Denied';
    //         var isShowButton = quote.Show_Button__c;

    //         var isButtonVisible = (isApproved || isPresented || isAccepted || isDenied) && isShowButton;
    //         component.set("v.isButtonVisible", isButtonVisible);
    //     }
    // }
})