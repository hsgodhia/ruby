$(document).ready(function()
{
 $("#send").click(function(event)
 {
    event.preventDefault();   
    var data = { "mssg": $('#message').val()};
    $('#message').val('');
    $.post( '/push', data,'json');
 });
});