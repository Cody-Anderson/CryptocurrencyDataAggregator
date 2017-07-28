$(document).on('turbolinks:load', function() {

    var arr = $('#candles').data('temp');       // Import chart data
    var ex = $('#exchange').data('temp');       // Import exchange
    var p1 = $('#pair1').data('temp');
    var p2 = $('#pair2').data('temp');
    
    var pair = p1 + "/" + p2;           // Form chart title from passed-in
    var exchange = pair + " - " + ex;     // exchange and pair
    
    
    
    for( var i = 0; i < arr.length; i++ ) {     // Convert each passed-in time string to
        arr[i][0] = new Date(arr[i][0]);        // a date object
    }

    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback(drawChart);

    function drawChart() {
        var data = google.visualization.arrayToDataTable(arr, true);

        var options = {
            title: exchange,
            titleTextStyle: { fontSize: 30 },
            legend: 'none',
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
            }
        };

        var chart = new google.visualization.CandlestickChart(document.getElementById('chart_div'));

        chart.draw(data, options);
    }
});
