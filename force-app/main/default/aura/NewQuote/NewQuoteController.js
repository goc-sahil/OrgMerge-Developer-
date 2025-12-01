({
    openModal: function(component, event, helper) {
        const oppId = component.get("v.recordId");

        // *** CHANGE THIS LINE *** Use the Aura Wrapper instead of the LWC
        $A.createComponent(
            "c:quoteNewHandler", // <--- Changed to the wrapper component name
            {
                recordId: oppId,
                onquotecreated: function(event) {
                    const quoteId = event.getParam("quoteId");

                    // Close modal
                    component.find("overlayLib").notifyClose();

                    // Navigate to Quote
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": quoteId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            },
            function(content, status) {
                if (status === "SUCCESS") {
                    component.find("overlayLib").showCustomModal({
                        header: "New Quote",
                        body: content,
                        showCloseButton: true,
                        cssClass: "quote-modal"
                    });
                } else {
                    console.error("Error creating component:", status);
                }
            }
        );
    }
});