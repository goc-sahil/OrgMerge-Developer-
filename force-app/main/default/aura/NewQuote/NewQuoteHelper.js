({
    createBody : function(component, oppId) {
        return new Promise($A.getCallback((resolve) => {

            $A.createComponent(
                "c:quoteNewHandler",
                {
                    recordId: oppId,
                    onquotecreated: function(event) {

                        const quoteId = event.getParam("quoteId");

                        let overlay = component.find("overlayLib");
                        overlay.close();   // close modal

                        // navigate to new Quote
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": quoteId,
                            "slideDevName": "detail"
                        });
                        navEvt.fire();
                    }
                },
                function(newCmp, status) {
                    if (status === "SUCCESS") {
                        resolve(newCmp);
                    }
                }
            );

        }));
    }
});