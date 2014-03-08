$(document).ready(function(){

	$("#go_back").click(function(event){
		window.location.href = '/market/showcase';
	});

	$("#update").hide();
	$("#price_box").hide();
	$("#show_edit").click(function(event)
	 {
	    $(this).hide();
		$("#update").show();
		$("#price_box").show();
	 });

	$("#update").click(function(event){

		var str = $("#imagelink").attr("src");
	 	var price = $("#price_box").val();

	 	console.log(str.slice(8));    	
	 	console.log(price);

	 	var posting = $.post('/item/edit', { "new_price":  price , "item_path" : str.slice(8) });
		
		posting.done(function(data) { 
			if (data[0] == "1")
				$("#result_positive").html(data.slice(1)); 
			else
				$("#result_negative").html(data.slice(1)); 
		});
	});
});
