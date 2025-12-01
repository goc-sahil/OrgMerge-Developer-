({
       display : function(component, event, helper) {
           
           helper.toggleHelper(component, event);
       },
        
        displayOut : function(component, event, helper) {
            helper.toggleHelper(component, event);
        }, 
    
       
    onTabClosed : function(component, event, helper) {
        helper.sendNotificationHelper(component,false,false);
    },
    
    
    onCometdLoaded : function(component, event, helper) {
      var cometd = new org.cometd.CometD();
      component.set('v.cometd', cometd);
      if (component.get('v.sessionId') != null)
        helper.connectCometd(component);
    },

    
    onInit : function(component, event, helper) {
       
        //console.log('onInit');
        
        //console.log("Case Id: "+component.get("v.recordId"));
          component.set('v.cometdSubscriptions', []);
        
           // Disconnect CometD when leaving page
            window.addEventListener('beforeunload', function(event) {
            //console.log("Disconnected");
            helper.sendNotificationHelper(component,false,false); 
            helper.disconnectCometd(component);
            }); 
        
         
        
          // Retrieve session id
          var action = component.get('c.getSessionId');
          action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === 'SUCCESS') {
              var retValue = response.getReturnValue();
              component.set('v.sessionId', retValue[0]);
              component.set('v.userId', retValue[1]);
              component.set('v.username', retValue[2]);
              component.set('v.smallPhotoURL', retValue[3]);
                //console.log('Retunrs: '+retValue[0]+", "+retValue[1]+", "+retValue[2]+", "+retValue[3]);
              if (component.get('v.cometd') != null)
               	 helper.connectCometd(component);
            }
            else
              console.error(response);
          });
          $A.enqueueAction(action);
          
    
    },
    
    sendNotification : function(component, event, helper) {
        helper.sendNotificationHelper(component,true,true);
        //console.log('sending notification now');
        
    }   
})