$(document).ready(function()
{
 $("#send").click(function(event)
 {
    var data = { "login": $("#login").val(), "pwd": $("#pwd").val() };
    $.post( '/user/validate', data, 'json');
 });
});