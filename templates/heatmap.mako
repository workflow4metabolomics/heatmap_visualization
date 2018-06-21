<%
    root = h.url_for( "/" )
    app_root = root + "plugins/visualizations/heatmap/static/"
%>

<html>
  <meta charset="utf-8">

  <style>
    .axis path,
    .axis line {
      fill: none;
      stroke: black;
      shape-rendering: crispEdges;
    }

    .axis text {
        font-family: sans-serif;
        font-size: 11px;
    }
        .heatmap{
          top:10px;
          position: relative;
      }
  </style>

  <head>
    <title>Heatmap Visualizer</title>

    <!-- Jquery -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>

    <!-- D3 -->
    <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.6/d3.min.js"></script> -->
    <script src="//d3js.org/d3.v4.min.js"></script>

    <!-- Visualizations -->
    <!-- ${h.javascript_link( app_root + 'unipept-visualizations.es5.js' )} -->

    <!-- Stylesheet -->
    <!-- ${h.stylesheet_link( app_root + 'style.css' )} -->

    <script>
    function RMS(arr){
        return Math.pow(arr.reduce(function(acc,pres){
            return acc+ Math.pow(pres,2);
        })/arr.length,.5)
    }
    
    // mean
    function mean(arr){
        return arr.reduce(function(acc,prev){
            return acc+prev;
        })/arr.length;
    }
    
    var lPatchWidth=200;
    var itemSize = 20,
      cellSize = itemSize - 3,
      margin = {top: 50, right: 100, bottom: 100, left: 100};
  
    var data;
    
    var width = 1000,
        height = 600;
    var colorScale;
    
    colorHold=["#800000","#ff0000","#ff6600","#ffcc00","#ffff99","#99ff66","#66ff33","#33cc33","#009933","#006600"]
    colorLText=["< -80%","-80% to -60%","-60% to -40%","-40% to -20%","-20% to 0%","0% to 20%","20% to 40%","40% to 60%","60% to 80%", "> 80%"]
  
    function bandClassifier(val,multiplier)
    {
        if(val>=0)
        { 
            return (Math.floor((val*multiplier)/(.20*multiplier))+1)>5?5:Math.floor((val*multiplier)/(.20*multiplier))+1
        }
        else{
            return (Math.floor((val*multiplier)/(.20*multiplier)))<-5?-5:Math.floor((val*multiplier)/(.20*multiplier))
        }
    }
  
    //TODO : Fonction pour creer des intervalles de 20 pourcents selon les valeurs val=d.perchange
    function range_of_values(values){
        return ([Math.max(values)])
    }

    window.onload=function(){
      d3.csv("${h.url_for( controller='/datasets', action='index')}/${trans.security.encode_id( hda.id )}/display", function ( response ) {

        data = response.map(function( item ) {
          var newItem = {};
          newItem.MT = item.x;
          newItem.sample = item.y;
          newItem.value = +item.value;

          return newItem;
        })    
    
        invertcolors=0;
        // Inverting color scale
        if(invertcolors){
          colorHold.reverse();  
        }

        var x_elements = d3.set(data.map(function( item ) { return item.sample; } )).values(),
            y_elements = d3.set(data.map(function( item ) { return item.MT; } )).values(),
            values = d3.set(data.map(function( item ) { return item.value; } )).values();

        colorLabelText = values
	//range_of_values(values)
        //["< -80%","-80% to -60%","-60% to -40%","-40% to -20%","-20% to 0%","0% to 20%","20% to 40%","40% to 60%","60% to 80%", "> 80%"]

        var xScale = d3.scaleBand()
          .domain(x_elements)
          .range([0, x_elements.length * itemSize/2])
          .paddingInner(20).paddingOuter(cellSize/2)

        var xAxis = d3.axisBottom()
          .scale(xScale)
          .tickFormat(function (d) {
            return d;
          });

        var yScale = d3.scaleBand()
          .domain(y_elements)
          .range([0, y_elements.length * itemSize])
          .paddingInner(.2).paddingOuter(.2);

        var yAxis = d3.axisLeft()
          .scale(yScale)
          .tickFormat(function (d) {
            return d;
          });
    
        // Finding the mean of the data
        var mean=window.mean(data.map(function(d){return +d.value}));
    
        //setting percentage change for value w.r.t average
        data.forEach(function(d){
          d.perChange=(d.value-mean)/mean
        })

        colorScale = d3.scaleOrdinal()
          .domain([-5,-4,-3,-2,-1,1,2,3,4,5])
          .range(colorHold);

        var rootsvg = d3.select('.heatmap')
          .append("svg")
          .attr("width", x_elements.length*itemSize/2+150)
          .attr("height", "100%")
        var svg=rootsvg.append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    
        // tooltip
        tooltip=d3.select("body").append("div").style("width","100px").style("height","40px").style("background","#C3B3E5")
        .style("opacity","1").style("position","absolute").style("visibility","hidden").style("box-shadow","0px 0px 6px #7861A5").style("padding","10px");
        toolval=tooltip.append("div");
          
    
        var cells = svg.selectAll('rect')
          .data(data)
          .enter().append('g').append('rect')
          .attr('class', 'cell')
          .attr('width', cellSize/2)
          .attr('height', cellSize)
          .attr('y', function(d) { return yScale(d.MT); })
          .attr('x', function(d) { return xScale(d.sample)-cellSize/2; })
          .attr('fill', function(d) { return colorScale(window.bandClassifier(d.perChange,100));})
          .attr("rx",3)
          .attr("ry",3)
          .on("mouseover",function(d){
            console.log(d);
            //d3.select(this).attr("fill","#655091");
            d3.select(this).style("stroke","orange").style("stroke-width","3px")
            d3.select(".trianglepointer").transition().delay(100).attr("transform","translate("+(-((lPatchWidth/colorScale.range().length)/2+(colorScale.domain().indexOf(bandClassifier(d.perChange,100))*(lPatchWidth/colorScale.range().length) )))+",0)");
            d3.select(".LegText").select("text").text(colorLText[colorScale.domain().indexOf(bandClassifier(d.perChange,100))])
          })
          .on("mouseout",function(){
            //d3.select(this).attr('fill', function(d) { return colorScale(window.bandClassifier(d.perChange,100));});
            d3.select(this).style("stroke","none");
            tooltip.style("visibility","hidden");
          })
          .on("mousemove",function(d){
            tooltip.style("visibility","visible")
            .style("top",(d3.event.pageY-30)+"px").style("left",(d3.event.pageX+20)+"px");
            
            console.log(d3.mouse(this)[0])
            tooltip.select("div").html("<strong>"+d.sample+"</strong><br/> "+(+d.value).toFixed(2))
          })


        svg.append("g")
          .attr("class", "y axis")
          .call(yAxis)
          .selectAll('text')
          .attr('font-weight', 'normal');

        svg.append("g")
          .attr("class", "x axis")
          .attr("transform","translate(0,"+(y_elements.length * itemSize +cellSize/2)+")")
          .call(xAxis)
          .selectAll('text')
          .attr('font-weight', 'normal')
          .style("text-anchor", "end")
          .attr("dx", "-.8em")
          .attr("dy", "-.5em")
          .attr("transform", function (d) {
            return "rotate(-65)";
          });
          
        // Legends section
        legends=svg.append("g").attr("class","legends")
          .attr("transform","translate("+((width+margin.right)/2-lPatchWidth/2 -margin.left/2)+","+(height+margin.bottom)+")");
    
        // Legend traingle pointer generator
        var symbolGenerator = d3.symbol()
          .type(d3.symbolTriangle)
          .size(64);    
        legends.append("g").attr("transform","rotate(180)").append("g").attr("class","trianglepointer")
          .attr("transform","translate("+(-lPatchWidth/colorScale.range().length)/2+")")
          .append("path").attr("d",symbolGenerator());

        //Legend Rectangels
        legends.append("g").attr("class","LegRect")
          .attr("transform","translate(0,"+15+")")
          .selectAll("rect").data(colorScale.range()).enter()
          .append("rect").attr("width",lPatchWidth/colorScale.range().length+"px").attr("height","10px").attr("fill",function(d){ return d})
          .attr("x",function(d,i){ return i*(lPatchWidth/colorScale.range().length) })
    
        // legend text
        legends.append("g").attr("class","LegText")
          .attr("transform","translate(0,45)")
          .append("text")
          .attr("x",lPatchWidth/2)
          .attr('font-weight', 'normal')
          .style("text-anchor", "middle")
          .text(colorLText[0])
     
        // Heading 
        rootsvg.append("g")
          .attr("transform","translate(0,30)")
          .append("text")
          .attr("x",(width+margin.right+margin.left)/2)
          .attr('font-weight', 'bold')
          .attr('font-size', '22px')
          .attr('font-family', 'Segoe UI bold')
          .style("text-anchor", "middle")
          .text("Heatmap")
      });
    }

    </script>
  </head>

  <body>
    <div class="heatmap" id="heatmap" style="height:100%; width:100%; overflow-x:scroll;"></div>
  </body>
</html>
