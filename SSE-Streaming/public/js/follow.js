window.onload = function() {
  
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
 
}