function Chat(host) {
    var chat = this;
    var myImage = document.getElementById('image');
    var times = 0;
    chat.ws = new WebSocket('ws://' + host);
    chat.ws.onopen = function() {
         console.log("on open");
    };
    chat.imageCache = {};
    chat.ws.onmessage = function(event) {
        var received_msg = event.data;
        times++;
        console.log("on message"+times);
        console.log(received_msg);
        
        
        var reader = new FileReader();
        reader.readAsDataURL(received_msg);
        reader.onloadend = function() {
            base64data = reader.result;
            myImage.src = base64data;
           
        }
        
    }

    
};
