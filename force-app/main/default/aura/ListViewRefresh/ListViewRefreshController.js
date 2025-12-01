({
    
    refresh : function(component, event, helper) {
        //clearInterval(component.get('v.intervalId'));
		if(event.getSource().get('v.label') == 'Disable'){
           	clearInterval(component.get('v.intervalId'));
            event.getSource().set("v.disabled","true"); 
            component.find("enableButton").set("v.disabled","false");
        } 
        if(event.getSource().get('v.label') == 'Enable'){
            component.set('v.intervalId', setInterval(component.reloadView,60000));
            event.getSource().set('v.disabled','true');
            component.find("disableButton").set("v.disabled","false");
        } 
	},
    
    onInit : function(component, event, helper) {
    	component.set('v.intervalId', setInterval(component.reloadView,60000));
        document.onmousemove = function(e) { helper.handler(e, component); };
    },
    
    reloadView: function(component, event, helper) {
        if(window.location.href.includes('/Case/list')){
            var x = component.get("v.posX");
            var y = component.get("v.posY");  
            var x2, y2, keyDown=false;
            //console.log('1:',x,y,keyDown);
            document.addEventListener('keydown', function(event) {
                keyDown = true;
            });
            setTimeout(function() { 
            	x2 = component.get("v.posX");
                y2 = component.get("v.posY");
                //console.log('2:',x2,y2,keyDown);
                if (x2 == x && y2 == y && !keyDown)
                     $A.get('e.force:refreshView').fire();
                keyDown = false;
            }, 8000);      
        }
    },
    
    reload: function(cmp, evt, helper) {
        $A.get('e.force:refreshView').fire();
    }   
    
})