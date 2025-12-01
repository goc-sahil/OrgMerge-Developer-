({
    doInit: function(component, event, helper) {
		helper.doInitHelper(component, event, helper);
        
    },

    saveInvoice: function(component, event, helper) {
        helper.saveInvoiceHelper(component, event, helper);
    },
    

    addInstallment : function(component) {
        try {
            let installments = component.get("v.installments");
            installments.push({ amount: 0, paid: false });
            component.set("v.installments", installments);
           // component.handleCalculatePaid();
        } catch(e) {
            console.error('Error in addInstallment', e);
        }
    },

   updateInstallmentAmountWrapper : function(component, event) {
        try {
            let source = event.getSource();
            let indexString = source ? source.get("v.name") : null;
            let index = (indexString !== null && indexString !== undefined) ? parseInt(indexString, 10) : -1;
            let value = event.getParam("value"); 
    
            if (index >= 0) {
                let installments = component.get("v.installments");
                installments[index].amount = value ? Number(value) : 0; 
                component.set("v.installments", installments);
                } else {
                console.error('CRITICAL: Index retrieval failed for Amount. Raw index:', indexString);
            }
        } catch(e) {
            console.error('Exception in updateInstallmentAmountWrapper', e);
        }
	},
    
    updateInstallmentPaidWrapper: function(component, event) {
        try {
            let source = event.getSource();
            let indexString = source ? source.get("v.name") : null;
            let index = (indexString !== null && indexString !== undefined) ? parseInt(indexString, 10) : -1;
            let checked = event.getParam("checked"); 
            if (index >= 0) {
                let installments = component.get("v.installments");
                installments[index].paid = checked;
                component.set("v.installments", installments); 
               } else {
                console.error('CRITICAL: Index retrieval failed for Paid. Raw index:', indexString);
            }
        } catch(e) {
            console.error('Exception in updateInstallmentPaidWrapper', e);
        }
    },


    handleCalculatePaid : function(component) {
        try {
            let installments = component.get("v.installments");
            let totalAmount = Number(component.get("v.totalAmount") || 0); 
            let totalPaid = 0;
			if(totalAmount <= 0) {
                component.set("v.paidPercentage", 0);
                component.set("v.remainingAmount", 0);
                return;
            }
            totalPaid = installments.reduce((sum, inst) => {
                if (inst.paid) {
                    return sum + Number(inst.amount || 0);
                }
                return sum;
            }, 0);
            
            let percent = (totalPaid / totalAmount) * 100;
            let remainingAmount = totalAmount - totalPaid;
            component.set("v.paidPercentage", percent.toFixed(2));
            component.set("v.remainingAmount", remainingAmount.toFixed(2));
        } catch(e) {
            console.error('Error in handleCalculatePaid', e);
        }
    },

	handleTaxTypeChange: function (cmp, event) {
       var selectedOptionValue = event.getParam("value");
        cmp.set("v.selectedTaxType", selectedOptionValue);
        var taxRate = 0;
        if(selectedOptionValue == 'IGST') {
            taxRate = 0.18; 
        } else if(selectedOptionValue == 'SGST/CGST'){
             taxRate = 0.18;
        }else if(selectedOptionValue == 'ONHST'){
             taxRate = 0.13;
        }
        cmp.set("v.taxRate", taxRate);
    },

    handleNext: function(component, event, helper) {
        helper.helperNextMethod(component, event, helper);
    },

    getSimplifiedInstallmentData: function(component) {
        let installments = component.get("v.installments");   
        let simpleData = installments.map((inst, index) => {
            return {
                installment: index + 1,
                amount: Number(inst.amount) || 0, 
                isPaid: inst.paid 
            };
        });
        
        return simpleData;
    },
    handleClose: function (component) {
        $A.get("e.force:closeQuickAction").fire();
    }
})