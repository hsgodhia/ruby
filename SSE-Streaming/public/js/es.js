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
	newElement.innerHTML = e.data;
	eventList.appendChild(newElement);

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
		eventList.appendChild(newElement);
    });
    window.bol = false;
};

}


