Object.extend(Event, {
  _domReady : function() {
    if (arguments.callee.done) return;
    arguments.callee.done = true;

    if (Event._timer)  clearInterval(Event._timer);
    
    Event._readyCallbacks.each(function(f) { f() });
    Event._readyCallbacks = null;
    
  },
  onReady : function(f) {
    if (!this._readyCallbacks) {
      var domReady = this._domReady;
      
      if (domReady.done) return f();
      
      if (document.addEventListener)
        document.addEventListener("DOMContentLoaded", domReady, false);
        
        /*@cc_on @*/
        /*@if (@_win32)
            document.write("<script id=__ie_onload defer src=javascript:void(0)><\/script>");
            document.getElementById("__ie_onload").onreadystatechange = function() {
                if (this.readyState == "complete") { domReady(); }
            };
        /*@end @*/
        
        if (/WebKit/i.test(navigator.userAgent)) { 
          this._timer = setInterval(function() {
            if (/loaded|complete/.test(document.readyState)) domReady(); 
          }, 10);
        }
        
        Event.observe(window, 'load', domReady);
        Event._readyCallbacks =  [];
    }
    Event._readyCallbacks.push(f);
  }
});

Event.onReady(function() {

  $$('#header a').each(function(currentLink) {
    $(currentLink).observe('click', function() {
      currentLink.up('ul').select('li').each(function(link) {
        link.removeClassName('selected');
      });
      currentLink.up('li').addClassName('selected');
      
      $$('.tab').each(function(tab) {
        tab.addClassName('hidden');
      });
      
      var tabId = 'tab-' + currentLink.id.replace('link-', '');
      $(tabId).removeClassName('hidden');
      $(tabId).down('form').focusFirstElement();
    });
  });
  
  $('tab-ping').down('form').focusFirstElement();

});

LookingGlass = {
  
  formHandler: function(form) {
    $(form).down('div.output-wrapper').update('');
    
    var contentElement = $(form).down('div.output-wrapper');
    contentElement.update('');
    var submitButton = $(form).down('input[type="submit"]');
    submitButton.disable();
    submitButton.addClassName("loading");
    submitButton.value = 'Please, wait...';
    
    $(form).select('input').each(function(field) {
      field.removeClassName('error');
      field.title = '';
    });
    
    new Ajax.Request(form.action, {
      method: 'post',
      parameters: Form.serialize(form),
      onSuccess: function(transport) {
        var response = transport.responseText.evalJSON();
        
        if ('undefined' != typeof response.errors) {
          var errors = response.errors;
          errors.each(function(error) {
            var field = $(form).down('input[name="' + error.field + '"]');
            field.addClassName('error');
            field.title = error.text;
          });
        } else {
          if (!response.status) {
            response.output = '<div class="error">Error</div>' + response.output;
          }
          
          contentElement.update('<pre class="output" style="display: none">' + response.output + '</pre>');
          new Effect.Appear(contentElement.down('pre'));
        }
        
        submitButton.enable();
        submitButton.removeClassName("loading");
        submitButton.value = 'Execute';
      }
    });
  }
  
}
