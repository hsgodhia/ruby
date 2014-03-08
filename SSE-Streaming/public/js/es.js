window.onload = function() {

//adding content from follow.js because both together are not able to work
 $("#follow").click(function(event)
 {
    var posting = $.post('/follow', { "user_name" : $("b#user_name").text() } );
    posting.done(function(data) { 
	$("#result").html(data); 
    });
 });
 
 $("#back").click(function(event)
 {
    window.location.href = '/home';
 });
 
var id = $("#user_id").text();
var es = new EventSource('/updates/' + id);
window.bol = false;
window.date = ""

es.onmessage = function(e) {
	var newElement = document.createElement("li");
	// sample message {"mssg":"hey man","time":"03:06:55","user":"burberry"}
	var message = e.data;
	var arr = message.split(",")
	var text = arr[0].slice(9, -1);
	var user = arr[2].slice(8, -2);
	newElement.innerHTML = text + ", @"+user;
	$("#eventList").prepend(newElement).slideDown();
	//eventList.appendChild(newElement);

	var t = e.data.indexOf("time");
	window.date = e.data.slice(t+7, t+15);
	window.bol = true;
};

es.onerror = function(e) {
	
	if ( window.bol == false ) return;
	//get data from server in the past (stop - start) seconds
	var posting = $.post('/missed_data', { "last_success" : window.date , "id" : id } );
	posting.done(function(data) { 

		var newElement = document.createElement("li");
		newElement.innerHTML = data;
		if (data != "" )
			$("#eventList").prepend(newElement).slideDown();
    });
    window.bol = false;
};

}


