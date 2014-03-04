window.onload = function() {
  
 $("#follow").click(function(event)
 {
    var username = $("b#user_name").text(); 
    var data = { "user_name" : username };
    $.post('/follow', data, function(data, status, xhr) { 
				alert(data);
				alert(status);
				console.log(data); 
				$("#result").html(data); 
			      } , 'text/html');
 });
}