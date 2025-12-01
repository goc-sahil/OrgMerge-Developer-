({
    init: function(cmp) {
      var action = cmp.get('c.getRemainingDays');
      action.setCallback(this, function(res) {
        var state = res.getState();
        var value = res.getReturnValue();

        if (state === 'SUCCESS' && value != null && value >= 0) {
          cmp.set('v.displayWidget', true);
        } else {
          cmp.set('v.displayWidget', false);
        }
       });
    },
    
	onClick : function(cmp, evt, helper) {
		cmp.set('v.isOpen', !cmp.get('v.isOpen'));
	}
})