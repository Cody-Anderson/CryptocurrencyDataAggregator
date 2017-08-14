$(document).on('turbolinks:load', function() {

    var arr = $('#candles').data('temp');       // Import chart data
    var ex = $('#exchange').data('temp');       // Import exchange
    var p1 = $('#pair1').data('temp');          // Import pair data
    var p2 = $('#pair2').data('temp');
    var all = $('#all').data('temp');           // If true, show all exchange data
    var minV = $('#min').data('temp');          // Minimum vertical axis value
    var maxV = $('#max').data('temp');          // Maximum vertical axis value
    
    var pair = p1 + "/" + p2;           // Form chart title from passed-in
    var exchange = pair + " - " + ex;     // exchange and pair
    var leg = "none";
    
    if( all == true ) {         // Removes the exchange from the title, if all exchanges are wanted
        exchange = pair;        // Also adds a legend if there are multiple series
        leg = "bottom"
    }

    for( var i = 0; i < arr.length; i++ ) {     // Convert each passed-in time string to
        arr[i][0] = new Date(arr[i][0]);        // a date object
    }

    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback(drawChart);

    function drawChart() {
        var data = google.visualization.arrayToDataTable(arr, false);

        var options = {
            title: exchange,
            titleTextStyle: { fontSize: 30 },
            legend: leg,
            chartArea: { width: '85%', height: '86%' },
            
            backgroundColor: { strokeWidth: 0 },
            
            candlestick: {
                fallingColor: { strokeWidth: 0, fill: '#a52714' }, // Falling candles are red
                risingColor: { strokeWidth: 0, fill: '#0f9d58' }   // Rising candles are green
            },
          
            hAxis: {
                gridlines: {
                    count: -1,
                    units: {
                        days: { format: ['MMM dd'] },
                        hours: { format: ['ha'] },
                    }
                },
            
                minorGridlines: {
                    units: {
                        hours: { format: ['hh:mm:ss a', 'ha'] },
                        minutes: { format: ['HH:mm a Z', ':mm'] }
                    }
                }
            },
            
            vAxis: { viewWindow: { min: minV * 0.999, max: maxV * 1.001 } }
        };

        var chart = new google.visualization.CandlestickChart(document.getElementById('chart_div'));

        chart.draw(data, options);
    }
});
