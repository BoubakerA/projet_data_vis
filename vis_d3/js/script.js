const ctx = {
    MAP_PATH:"../data/countries.geojson",
    
    africanCountryCodes : [
      "DZA","AGO","BEN","BWA","BFA","BDI","CMR","CPV","CAF","TCD",
      "COM","COD","COG","DJI","EGY","GNQ","ERI","SWZ","ETH","GAB",
      "GMB","GHA","GIN","GNB","KEN","LSO","LBR","LBY","MDG","MWI",
      "MLI","MRT","MUS","MAR","MOZ","NAM","NER","NGA","RWA","STP",
      "SEN","SLE","SOM","ZAF","SSD","SDN","TZA","TGO","TUN","UGA",
      "ZMB","ZWE","CIV"],
    
    mapWidth: 700,
    mapHeight: 600,

    chartWidth: 600,
    chartHeight:300,

    distWidth: 600,
    distHeight:100,
  
    margin: { top: 80, right: 80, bottom: 20, left: 80 }

    };


function isDisputed(d) {
  return d.properties["ISO3166-1-Alpha-3"] === "-99";
}


async function loadData(mapSvg, chartSvg, MetaDataSvg) {
  const popData = await d3.csv("../data/population.csv", row => {

  return {
    country: row["Country Name"],
    iso3:    row["Country Code"],
    pop2024: row["2024"]
   };
  });

  
  const populationArray = popData.filter(
    d => ctx.africanCountryCodes.includes(d.iso3) && !isNaN(d.pop2024)
  );  
  const geoData = await d3.json(ctx.MAP_PATH);

  const africa = geoData.features.filter(
    d => ctx.africanCountryCodes.includes(d.properties["ISO3166-1-Alpha-3"])
  );

  const population = {};
  populationArray.forEach(entry => {
    const code = entry.iso3;  
    population[code] = entry.pop2024 || 0; 
  });
  

  const indicators = await d3.csv("../data/indicators_dataset.csv", row => {
    return {
      iso3: row["countryIsoCode"],
      country: row["country"],
      year: +row["year"],
      gnipc: parseFloat(row["gnipc"]),
      mys: parseFloat(row["mys"]),
      hdi: parseFloat(row["hdi"])
    };
  });

  populateSVGcanvas(africa, population, indicators, mapSvg, chartSvg, MetaDataSvg);
  
}

function DisplayMap() {

  const mapSvg = d3.select("#map")
  .attr("width", ctx.mapWidth)
  .attr("height", ctx.mapHeight);

  const chartSvg = d3.select("#chart")
  .attr("width", ctx.chartWidth)
  .attr("height", ctx.chartHeight);

  const MetaDataSvg = d3.select("#metadata")
  .attr("width", ctx.distWidth)
  .attr("height", ctx.distHeight);
  
  loadData(mapSvg, chartSvg, MetaDataSvg);}


function populateSVGcanvas(mapData, population, indicatorsData, mapSvg, chartSvg, MetaDataSvg) {

  const projection = d3.geoMercator()
    .scale(400)
    .center([25, 0])          
    .translate([ctx.mapWidth / 2, ctx.mapHeight / 2]);
  const format = d3.format(".2s");  
  const pathGenerator = d3.geoPath().projection(projection);
  const tooltip = d3.select("#tooltip");
  
  
  mapSvg.selectAll("path")
    .data(mapData)
    .enter()
    .append("path")
      .attr("d", pathGenerator)
      .attr("fill", "#cf4d15")
      .attr("stroke", "#fff")
      .attr("stroke-width", 0.8)
      .on("click", (event, d) => {
      const iso3 = d.properties["ISO3166-1-Alpha-3"];

      // Update figures for clicked country
      updateChart(iso3, indicatorsData, chartSvg);
      updateMetaData(iso3, indicatorsData, MetaDataSvg);
      drawHDIDistribution(iso3, indicatorsData, MetaDataSvg);

      // Highlight selected country on map
      mapSvg.selectAll("path").attr("fill", "#cf4d15");           
      d3.select(event.currentTarget).attr("fill", "#e8a020");})

      .on("mouseover", (event, d) => {
        const code = d.properties["ISO3166-1-Alpha-3"];
        const pop = population[code];
        tooltip
          .style("display", "block")
          .text(d.properties["name"] + ": " + (format(pop) ? format(pop) : "N/A") + " inhabitants");
      })
      .on("mousemove", (event) => {
        tooltip
          .style("left", (event.pageX + 12) + "px")  
          .style("top",  (event.pageY - 28) + "px"); 
      })
      .on("mouseout", () => {
        tooltip.style("display", "none"); 
      });

    randomIso3 = ctx.africanCountryCodes[Math.floor(Math.random() * ctx.africanCountryCodes.length)];
    mapSvg.selectAll("path")
    .attr("fill", d => 
      d.properties["ISO3166-1-Alpha-3"] === randomIso3 ? "#e8a020" : "#cf4d15"
  );
    updateChart(randomIso3, indicatorsData, chartSvg);
    updateMetaData(randomIso3, indicatorsData, MetaDataSvg);
    drawHDIDistribution(randomIso3, indicatorsData, MetaDataSvg);
};

function drawHDIDistribution(iso3, indicatorsData, MetaDataSvg) {
  
  const tooltip = d3.select("#tooltip");
  const xScaleHDI = d3.scaleLinear()
  .domain([0, 1])                                    
  .range([ctx.margin.left, ctx.distWidth - ctx.margin.right]);

  // console.log("Indicators data: ", indicatorsData);
  const latestYear = d3.max(indicatorsData.filter(d => d.iso3 === iso3  && !isNaN(d.hdi)), d => d.year);
  console.log("Latest year for iso3 " + iso3 + ": " + latestYear);
  const hdiLatest = indicatorsData.filter(d => d.year === latestYear && !isNaN(d.hdi));
  // console.log("HDI data for distribution: ", hdiLatest);

  // Draw a baseline
  MetaDataSvg.append("line")
    .attr("x1", ctx.margin.left)
    .attr("x2", ctx.distWidth - ctx.margin.right)
    .attr("y1", ctx.distHeight/2)
    .attr("y2", ctx.distHeight/2)
    .attr("stroke", "#ccc")
    .attr("stroke-width", 1);

  // Draw X axis
  MetaDataSvg.append("g")
    .attr("transform", `translate(0, ${ctx.distHeight/2})`)
    .call(d3.axisBottom(xScaleHDI).ticks(5));

  // Draw one dot per country
  MetaDataSvg.selectAll("circle.hdi-dot")
  .data(hdiLatest)
  .enter()
  .append("circle")
      .attr("class", "hdi-dot")
      .attr("cx", d => xScaleHDI(d.hdi))
      .attr("cy", ctx.distHeight/2)
      .attr("r", 6)
      .attr("fill", "#ed9528")
      .attr("opacity", 0.1)
      .attr("id", d => "dot-" + d.iso3); 
    
    const countryHDI = hdiLatest.find(d => d.iso3 === iso3) || null;
    if (countryHDI && countryHDI.hdi) {
      MetaDataSvg.append("circle")
        .attr("class", "selected-dot")
        .attr("cx", xScaleHDI(countryHDI.hdi))
        .attr("cy", ctx.distHeight/2)
        .attr("r", 8)
        .attr("fill", "#cf4d15")
        .attr("opacity", 1)
        .attr("stroke", "#fff")
        .attr("stroke-width", 2)
        .on("mouseover", (event, d) => {
        tooltip
          .style("display", "block")
          .text("HDI"+ ": " + countryHDI.hdi);
        })
        .on("mousemove", (event) => {
          tooltip
            .style("left", (event.pageX + 12) + "px")  
            .style("top",  (event.pageY - 28) + "px"); 
        })
        .on("mouseout", () => {
          tooltip.style("display", "none"); 
        });
    }
    MetaDataSvg.append("text")
      .attr("x", ctx.distWidth/2)
      .attr("y", ctx.distHeight/2 - 25)
      .attr("text-anchor", "middle")
      .style("font-size", "16px")
      .style("font-weight", "bold")
      .text("Human developpement indicator for the year " + latestYear);
  }

function updateMetaData(iso3, allData, MetaDataSvg) {
  MetaDataSvg.selectAll("*").remove();
  // console.log("Updating metadata for iso3: " + iso3);
}

function updateChart(iso3, allData, chartSvg) {
  
  chartSvg.selectAll("*").remove();;

  const tooltip = d3.select("#tooltip");
  // Filter data for selected country
  const countryData = allData.filter(d => d.iso3 === iso3 && !isNaN(d.mys) && !isNaN(d.gnipc));

  const xScale = d3.scaleLinear()
    .domain([d3.min(countryData, d => d.year), d3.max(countryData, d => d.year)])
    .range([ctx.margin.left, ctx.chartWidth - ctx.margin.right]);

    // Two separate Y scales
  const yScaleGNIPC = d3.scaleLinear()
    .domain([d3.min(allData, d => d.gnipc), d3.max(countryData, d => d.gnipc)])
    .range([ctx.chartHeight - ctx.margin.bottom, ctx.margin.top]);

  const yScaleMYS = d3.scaleLinear()
    .domain([d3.min(allData, d => d.mys), d3.max(allData, d => d.mys)])
    .range([ctx.chartHeight - ctx.margin.bottom, ctx.margin.top]);

  // X axis
  chartSvg.append("g")
    .attr("transform", `translate(0, ${ctx.chartHeight - ctx.margin.bottom})`)
    .call(d3.axisBottom(xScale).tickFormat(d3.format("d")))
    .append("text")
      .attr("x", ctx.chartWidth / 2)
      .attr("y", 40)                       
      .attr("text-anchor", "middle")
      .attr("font-size", "12px")
      .attr("fill", "black")            
      .text("Year"); 

  chartSvg.append("g")
    .attr("transform", `translate(${ctx.margin.left}, 0)`)
    .call(d3.axisLeft(yScaleGNIPC))
    .append("text")
      .attr("transform", "rotate(-90)")   // rotate to read vertically
      .attr("x", -(ctx.chartHeight / 2))  // center vertically (x becomes y after rotation)
      .attr("y", -45)                     // distance to the left of the axis
      .attr("text-anchor", "middle")
      .attr("font-size", "12px")
      .attr("fill", "#f70909")
      .text("GNIPC (USD)");
      

  chartSvg.append("g")
    .attr("transform", `translate(${ctx.chartWidth - ctx.margin.right}, 0)`)
    .call(d3.axisRight(yScaleMYS))
    .append("text")
      .attr("transform", "rotate(-90)")   
      .attr("x", -(ctx.chartHeight / 2))  
      .attr("y", 40)                     
      .attr("text-anchor", "middle")
      .attr("font-size", "12px")
      .attr("fill", "#181ff3")
      .text("Mean Years of Schooling");
      
  // Draw dots
  chartSvg.selectAll("circle.mys")
    .data(countryData)
    .enter()
    .append("circle")
      .attr("cx", d => xScale(d.year))
      .attr("cy", d => yScaleMYS(d.mys))
      .attr("r", 4)
      .attr("fill", "#181ff3")
      .attr("opacity", 0.8)
      
    .on("mouseover", (event, d) => {
      // console.log("country: " + d.country);
      tooltip
        .style("display", "block")
        .html(`
          Year: ${d.year}<br>
          MYS: ${d.mys} years
        `);
    })

    .on("mousemove", (event) => {
      tooltip
        .style("left", (event.pageX + 12) + "px")
        .style("top",  (event.pageY - 28) + "px");
    })

    .on("mouseout", () => {
      tooltip.style("display", "none");
    });

  chartSvg.selectAll("circle.gnipc")
  .data(countryData)
  .enter()
  .append("circle")
    .attr("class", "gnipc")
    .attr("cx", d => xScale(d.year))
    .attr("cy", d => yScaleGNIPC(d.gnipc))
    .attr("r", 4)
    .attr("fill", "#f31818")
    .attr("opacity", 0.8)
    .on("mouseover", (event, d) => {
      // console.log("country: " + d.country);
      tooltip
        .style("display", "block")
        .html(`
          Year: ${d.year}<br>
          GNIPC: ${d.gnipc} USD
        `);
    })

    .on("mousemove", (event) => {
      tooltip
        .style("left", (event.pageX + 12) + "px")
        .style("top",  (event.pageY - 28) + "px");
    })

    .on("mouseout", () => {
      tooltip.style("display", "none");
    });

  chartSvg.append("text")
  .attr("x", ctx.chartWidth / 2)
  .attr("y", ctx.margin.top / 2)
  .attr("text-anchor", "middle")
  .style("font-size", "16px")
  .style("font-weight", "bold")
  .text("Gross National Income per Capita and Mean Years of Schooling");
  
  const countryName = allData.find(d => d.iso3 === iso3)?.country || iso3;
  chartSvg.append("text")
  .attr("x", ctx.chartWidth - ctx.margin.right)
  .attr("y", ctx.margin.top / 6)
  .attr("text-anchor", "end")
  .style("font-size", "16px")
  .style("font-weight", "bold")
  .attr("fill", "#e8a020")
  .text(countryName);

}
DisplayMap();

