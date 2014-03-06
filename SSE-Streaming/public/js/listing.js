$(document).ready(function()
{
	$("#send").hide();
	$("#price_box").hide();

	 $("#show_price_drop").click(function(event)
	 {
	    $(this).hide();
		$("#send").show();
		$("#price_box").show();
	 });
});