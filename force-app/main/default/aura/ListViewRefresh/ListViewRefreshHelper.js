({
	handler: function (e, component) {
            e = e || window.event;
        
            var pageX = e.pageX;
            var pageY = e.pageY;
        
            // IE 8
            if (pageX === undefined) {
                pageX = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
                pageY = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
            }
        
            component.set("v.posX", pageX);
        	component.set("v.posY", pageY);
        	
        	//document.onmousemove = null;
        	//console.log(pageX, pageY);
    }
})