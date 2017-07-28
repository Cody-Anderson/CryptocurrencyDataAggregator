$(document).on('turbolinks:load', function() {

    var arr = $('#candles').data('temp');       // Import chart data
    
    for( var i = 0; i < arr.length; i++ ) {     // Convert each passed-in time string to
        arr[i][0] = new Date(arr[i][0]);        // a date object
    }

    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback(drawChart);

    function drawChart() {
        var data = google.visualization.arrayToDataTable(arr, true);

        var options = {
            legend:'none'
        };

        var chart = new google.visualization.CandlestickChart(document.getElementById('chart_div'));

        chart.draw(data, options);
    }
});
