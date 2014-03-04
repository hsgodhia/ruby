var es = new EventSource('/updates/connect');
//event source accpets the URI of the server which generates data
es.onmessage = function(e) {
	var newElement = document.createElement("li");
	newElement.innerHTML = e.data;
	eventList.appendChild(newElement);
}
