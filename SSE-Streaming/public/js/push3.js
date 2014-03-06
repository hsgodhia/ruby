$(document).ready(function()
{
 $("#send").click(function(event)
 {
    event.preventDefault();   
    var data = { "mssg": $('#message').val()};
    $('#message').val('');
    $.post( '/push', data,'json');
 });
 
 $("#logout").click(function(event)
 {
    window.location.href = '/clear';
 });

 $("#showcase").click(function(event)
 {
    window.location.href = '/market/showcase';
 });

 $("#home").click(function(event)
 {
    window.location.href = '/home';
 });

});