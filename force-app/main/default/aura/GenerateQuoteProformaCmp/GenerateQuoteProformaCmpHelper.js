({
	helperNextMethod : function(component, event, helper) {
		 // ========== STEP 1: Get Fields ==========
    let dateInput = component.find("dateInput");
    let dueDateInput = component.find("dueDateInput");
    let installments = component.get("v.installments");

    let isValid = true;

    // ========== STEP 2: Clear previous validation messages ==========
    dateInput.setCustomValidity("");
    dueDateInput.setCustomValidity("");

    // ========== STEP 3: Validate Date Fields ==========
    let dateValue = dateInput.get("v.value");
    let dueDateValue = dueDateInput.get("v.value");

    if (!dateValue) {
        dateInput.setCustomValidity("Please select a date.");
        isValid = false;
    }

    if (!dueDateValue) {
        dueDateInput.setCustomValidity("Please select a due date.");
        isValid = false;
    }


    // Show validation messages
    dateInput.reportValidity();
    dueDateInput.reportValidity();

    // ========== STEP 4: Validate Amount Fields ==========
    let amountInputs = component.find("amountInput");
    let totalPercentage = 0;

    if (Array.isArray(amountInputs)) {

        amountInputs.forEach((input, idx) => {
            let value = Number(input.get("v.value") || 0);

            // Individual field validation
            if (value <= 0) {
               input.setCustomValidity("Please enter a valid amount greater than 0.");
                isValid = false;
            } else {
                input.setCustomValidity("");
            }
            input.reportValidity();

            // Keep running total
            totalPercentage += value;
        });

    } else if (amountInputs) {
        // Single input case
        let value = Number(amountInputs.get("v.value") || 0);

        if (value <= 0) {
             amountInputs.setCustomValidity("Please enter a valid amount greater than 0.");
            isValid = false;
        } else {
            amountInputs.setCustomValidity("");
        }
        amountInputs.reportValidity();

        totalPercentage = value;

    } else {
        console.warn(" No amount inputs found!");
    }

    // NEW TOTAL VALIDATION
    if (totalPercentage > 100) {
       isValid = false;
        // Optionally show a toast message
        let toast = $A.get("e.force:showToast");
        if (toast) {
            toast.setParams({
                title: "Validation Error",
                message: `Total Installment Percentage cannot exceed 100%. Currently: ${totalPercentage}%`,
                type: "error"
            });
            toast.fire();
        }
    }

    // ========== STEP 5: Stop if Validation Fails ==========
    if (!isValid) {
        helper.showToast("Error", "Please correct the highlighted errors before proceeding.", "error");
        return;
    }


    // ========== STEP 6: Calculation ==========
        let totalQuoteAmount = Number(component.get("v.totalAmount") || 0);
        let taxAmount = totalQuoteAmount * component.get("v.taxRate");
        component.set("v.taxAmount", taxAmount.toFixed(2));
        let totalGrandAmount = taxAmount + totalQuoteAmount;
        component.set("v.totalGrandAmount", totalGrandAmount.toFixed(2));
    	let totalPaidAmount = 0;
        let totalUnpaidAmount = 0;
    	installments.forEach((inst, index) => {
            // Ensure the amount is a number (default to 0 if invalid/empty)
            let amount = Number(inst.amount || 0); 
            
            if (inst.paid) {
                totalPaidAmount += amount; // Accumulate paid installment amounts
            } else {
                totalUnpaidAmount += amount; // Accumulate unpaid installment amounts
                component.set("v.index", index+1);
            }
            component.set('v.totalPaidAmount', totalPaidAmount);
            component.set('v.totalUnpaidAmount', totalUnpaidAmount);
        });
	let paidPercentage = (totalPaidAmount * totalGrandAmount) / 100;
    let nowPaying = (totalUnpaidAmount * totalGrandAmount) / 100;
    let quoteAmountRemaining = totalGrandAmount - (paidPercentage + nowPaying);
    component.set("v.paidAmount", paidPercentage.toFixed(2));
    component.set("v.remainingAmount", quoteAmountRemaining.toFixed(2));
    component.set("v.nowPaying", nowPaying.toFixed(2));

    component.set("v.showIframe", true);
	},
    
    saveInvoiceHelper : function(component, event, helper) {
         const action = component.get("c.savePdf");
    
        // Collect all required parameters from component
        const params = {
            recordId: component.get("v.recordId"),
            tDate: component.get("v.tDate"),
            dueDate: component.get("v.dueDate"),
            paid: component.get("v.paidAmount"),
            paying: component.get("v.nowPaying"),
            remaining: component.get("v.remainingAmount"),
            taxAmount: component.get("v.taxAmount"),
            totalGrandAmount: component.get("v.totalGrandAmount"),
            selectedTaxType: component.get("v.selectedTaxType"),
            shipVia: component.get("v.shipVia"),
            index: component.get("v.index"),
            paymentTerm: component.get("v.paymentTerm"),
            totalpaidPercentage: component.get("v.totalPaidAmount"),
            totalUnpaidPercentage: component.get("v.totalUnpaidAmount")
        };
    
        action.setParams(params);
    
        //  Handle callback
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const toastEvent = $A.get("e.force:showToast");
                if (toastEvent) {
                    toastEvent.setParams({
                        title: "Success!",
                        message: "The Proforma Invoice PDF has been successfully saved to the record.",
                        type: "success"
                    });
                    toastEvent.fire();
                } else {
                    alert("Success: PDF saved!");
                }
    
                $A.get("e.force:closeQuickAction").fire();
                $A.get("e.force:refreshView").fire();
            } else {
                // Handle Apex errors cleanly
                const errors = response.getError();
                let errorMessage = "Unknown error occurred.";
                if (errors && errors[0]) {
                    if (errors[0].message) {
                        errorMessage = errors[0].message;
                    } else if (errors[0].pageErrors && errors[0].pageErrors[0].message) {
                        errorMessage = errors[0].pageErrors[0].message;
                    }
                }
    
                const toastEvent = $A.get("e.force:showToast");
                if (toastEvent) {
                    toastEvent.setParams({
                        title: "Error Saving PDF",
                        message: errorMessage,
                        type: "error"
                    });
                    toastEvent.fire();
                } else {
                    alert("Error Saving PDF: " + errorMessage);
                }
    
                console.error("Save PDF Error:", errors);
            }
        });
    
        $A.enqueueAction(action);
        },
        
      doInitHelper : function(component, event, helper) {
        component.set("v.installments", [{'amount':0,'paid':false}]); // Reset installments
        component.set("v.selectedTaxType", "");                         // Reset Tax Type
        component.set("v.paidAmount", 0);                              // Reset paid amount
        component.set("v.nowPaying", 0);                                // Reset now paying
        component.set("v.remainingAmount", 0);                         // Reset remaining amount
        component.set("v.showIframe", false);                          // Hide the iframe view
        // **********************************************
        var recordId = component.get("v.recordId");
        let today = new Date();
        let yyyy = today.getFullYear();
        let mm = String(today.getMonth() + 1).padStart(2, '0');
        let dd = String(today.getDate()).padStart(2, '0');
        let todayStr = `${yyyy}-${mm}-${dd}`;
        component.set("v.tDate", todayStr);
        var getTotalAction = component.get("c.getTotalQuoteAmount"); 
        getTotalAction.setParams({ recordId: recordId });
        getTotalAction.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let totalAmount = response.getReturnValue() || 0;
                component.set("v.totalAmount", totalAmount); 
            } else {
                console.error('Error loading total quote amount', response.getError());
            }
        });
        $A.enqueueAction(getTotalAction);

        if(!component.get("v.installments") || component.get("v.installments").length === 0){
            component.set("v.installments", [{ amount: 0, paid: false }]);
        }
        component.set("v.remainingAmount", 0);
    }
})