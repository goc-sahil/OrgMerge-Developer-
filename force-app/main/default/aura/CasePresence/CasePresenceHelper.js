({
  connectCometd : function(component) {
    var helper = this;

    // Configure CometD
    var cometdUrl = window.location.protocol+'//'+window.location.hostname+'/cometd/40.0/';
    var cometd = component.get('v.cometd');
    cometd.configure({
      url: cometdUrl,
      requestHeaders: { Authorization: 'OAuth '+ component.get('v.sessionId')},
      appendMessageTypeToURL : false
    });
    cometd.websocketEnabled = false;

    // Establish CometD connection
    //console.log('Connecting to CometD: '+ cometdUrl);
    cometd.handshake(function(handshakeReply) {
      if (handshakeReply.successful) {
        //console.log('Connected to CometD.');
        var customEvent = component.getEvent("cometDLoadedEvent");
        customEvent.fire();
        var newSubscription = cometd.subscribe('/event/Case_Notification__e',
          function(platformEvent) {
            //console.log('Platform event received: '+ JSON.stringify(platformEvent));
            helper.onReceiveNotification(component, platformEvent);
          }
        );
        // Save subscription for later
        var subscriptions = component.get('v.cometdSubscriptions');
        subscriptions.push(newSubscription);
        component.set('v.cometdSubscriptions', subscriptions);
      }
      else
        console.error('Failed to connected to CometD.');
    });
      },

  disconnectCometd : function(component) {
    var cometd = component.get('v.cometd');

    // Unsuscribe all CometD subscriptions
    cometd.batch(function() {
      var subscriptions = component.get('v.cometdSubscriptions');
      subscriptions.forEach(function (subscription) {
        cometd.unsubscribe(subscription);
      });
    });
    component.set('v.cometdSubscriptions', []);

    // Disconnect CometD
    cometd.disconnect();
    //console.log('CometD disconnected.');
  },

  onReceiveNotification : function(component, platformEvent) {
    var helper = this;
    var exists = false;
    var abbr;
    //console.log("inside receiveNotification.");
    
    //create username abbreviation
    var str = platformEvent.data.payload.User_Name__c;  
    var patt = new RegExp("(.)[^\\s.]*\\s(.).*");
    if(patt.test(str)){
        //patt = /(.)[^\s.]*\s(.).*/g;
        patt = new RegExp("(.)[^\\s.]*\\s(.).*");
        var res = patt.exec(str);
         abbr = res[1]+res[2];
     }else{
         //patt = /(..).*/g;
         patt = new RegExp("(..).*");
         var res = patt.exec(str);
         abbr = res[1];
     }  
      
    // Extract notification from platform event
    var newUserAccessing = {
      time : $A.localizationService.formatDateTime(
        platformEvent.data.payload.CreatedDate, 'HH:mm'),
      caseId : platformEvent.data.payload.CaseId__c,
      userId : platformEvent.data.payload.UserId__c,
      userName : platformEvent.data.payload.User_Name__c,
      userNameAbbr : abbr, 
      isOpen : platformEvent.data.payload.IsOpen__c,
      isFirst : platformEvent.data.payload.IsFirst__c,
      smallPhotoURL : platformEvent.data.payload.PhotoURL__c
        
    };
     
    // Save notification in history
     if(component.get('v.userId') != null && (newUserAccessing.userId != component.get('v.userId')) && ( newUserAccessing.caseId == component.get('v.recordId'))) {
         //console.log('newUserId: '+newUserAccessing.userId+', thisuserId: '+component.get('v.userId'));
        if(newUserAccessing.isFirst)
              helper.sendNotificationHelper(component,false,true);
        var usersAccessing = component.get('v.usersAccessing');
        if(!newUserAccessing.isOpen){
            for (var i = 0; i < usersAccessing.length; i++) {
                if (usersAccessing[i].userId === newUserAccessing.userId) {
                    console.log('before splice: '+usersAccessing.length);
                    
                    usersAccessing.splice(i,1);
                    console.log('after splice: '+usersAccessing.length);                   
                }
            }
        } else {
            for (var i = 0; i < usersAccessing.length; i++) {
                if (usersAccessing[i].userId == newUserAccessing.userId) {
                    exists = true;
                }
            } 
            if (!exists)  
                usersAccessing.push(newUserAccessing); 
        }
       
        component.set('v.usersAccessing', usersAccessing);      
        //console.log('UserAccessing: '+usersAccessing);
          
    } else if(component.get('v.userId') != null 
              && newUserAccessing.userId == component.get('v.userId') 
              && !newUserAccessing.isOpen
              && newUserAccessing.caseId == component.get('v.recordId')) {
        //console.log('inside multiple brower tab scenario.');
        helper.sendNotificationHelper(component,false,true);
    }
  	},
    
    displayUsers : function (component){
        
    },
    
    sendNotificationHelper : function(component,isFirst,isOpen) {
        var action = component.get('c.publishNotification');
        //console.log("trying to publish");
        action.setParams({
            "caseId": component.get("v.recordId"),
            "userId" : component.get("v.userId"),
            "username" : component.get("v.username"),
            "isFirst" : isFirst,
            "isOpen" : isOpen,
            "smallPhotoURL" : component.get("v.smallPhotoURL")
        });
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() === 'SUCCESS') {
                //console.log('publish notification response: ' + response.getReturnValue());
            }
            else
                console.error(response);
        });
        $A.enqueueAction(action);
    },
    
    
   toggleHelper : function(component,event) {
    
    
     $A.util.toggleClass(event.currentTarget.nextElementSibling, "toggle");
   }
   

})