$('#short_them').click(function(event){
    event.preventDefault();
    $.ajax({
        url: '/',
        type: 'post',
        dataType: 'json',
        success: function (data) {
            console.log(data);
            $('.result').html("<a class='short_link'>https://ql.lc/"+ data.short_code + "</a>");
        },

        data: {url: $('#big_url').val() }
    });
});
