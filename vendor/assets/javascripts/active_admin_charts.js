function draw_pie_chart($el, data) {
  var ctx = $el.get(0).getContext("2d");
  var options = {
    legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<segments.length; i++){%><li><span style=\"background-color:<%=segments[i].fillColor%>\"><%if(segments[i].label){%><%=segments[i].label%> (<%=segments[i].value%>)</span><%}%></li><%}%></ul>"
  
  }
  var piechart = new Chart(ctx).Pie(data,options);
  $el.after(piechart.generateLegend());
}

  
jQuery(function($) {

  draw_pie_chart( $(".js-col-sum-type-graph"), [
    { value: parseInt($('.js-col-sum-type-1').html()) , color:"#F7464A", highlight: "#FF5A5E", label: "Tarjetas de crédito/débito" },
    { value: parseInt($('.js-col-sum-type-2').html()), color: "#46BFBD", highlight: "#5AD3D1", label: "Banco nacional" },
    { value: parseInt($('.js-col-sum-type-3').html()), color: "#FDB45C", highlight: "#FFC870", label: "Banco internacional" }
  ]);

  draw_pie_chart( $(".js-col-sum-freq-graph"), [
    { value: parseInt($('.js-col-sum-freq-1').html()) , color:"#F7464A", highlight: "#FF5A5E", label: "Mensual" },
    { value: parseInt($('.js-col-sum-freq-2').html()), color: "#46BFBD", highlight: "#5AD3D1", label: "Trimestral" },
    { value: parseInt($('.js-col-sum-freq-3').html()), color: "#FDB45C", highlight: "#FFC870", label: "Anual" }
  ]);

  draw_pie_chart( $(".js-col-sum-amount-graph"), [
    { value: parseInt($('.js-col-sum-amount-1').html()) , color:"#F7464A", highlight: "#FF5A5E", label: "Menos de 10 €" },
    { value: parseInt($('.js-col-sum-amount-2').html()), color: "#46BFBD", highlight: "#5AD3D1", label: "Entre 10 y 20 €" },
    { value: parseInt($('.js-col-sum-amount-3').html()), color: "#FDB45C", highlight: "#FFC870", label: "Mayor a 20 €" }
  ]);


  var evolution_labels = []
  var evolution_orders = []
  var evolution_amount = []
  $('table.js-col-sum-evolution tbody tr').each( function(){
    evolution_labels.push( $(this).find('td:nth-child(1)').text().trim() );
    evolution_orders.push( parseInt($(this).find('td:nth-child(2)').text().trim()) );
    evolution_amount.push( parseFloat($(this).find('td:nth-child(3)').text().trim().replace('€','').replace(',','.')) );
  });
  var data = {
    labels: evolution_labels,
    datasets: [
      {
        label: "Por cantidad de ordenes",
        fillColor: "rgba(220,220,220,0.2)",
        strokeColor: "rgba(220,220,220,1)",
        pointColor: "rgba(220,220,220,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(220,220,220,1)",
        data: evolution_orders
      },
      {
        label: "Por cantidad total",
        fillColor: "rgba(151,187,205,0.2)",
        strokeColor: "rgba(151,187,205,1)",
        pointColor: "rgba(151,187,205,1)",
        pointStrokeColor: "#fff",
        pointHighlightFill: "#fff",
        pointHighlightStroke: "rgba(151,187,205,1)",
        data: evolution_amount
      }
    ]
  };

console.log(evolution_labels);
console.log(evolution_orders);
console.log(evolution_amount);

  var options = {
    legendTemplate : "<ul class=\"<%=name.toLowerCase()%>-legend\"><% for (var i=0; i<datasets.length; i++){%><li><span style=\"background-color:<%=datasets[i].strokeColor%>\"><%if(datasets[i].label){%><%=datasets[i].label%></span><%}%></li><%}%></ul>"
  }

  var $el = $('.js-col-sum-evolution-graph');
  var ctx = $el.get(0).getContext("2d");
  var linechart = new Chart(ctx).Line(data, options);
  $el.after(linechart.generateLegend());

});
