class Globe
  # Define default config
  config =
    # SVG
    svgBlockSelector: ".globe-container"
    svgHeight: 600
    svgWidth: 600

    # GLOBE
    globeDefaultRotation: [0, -10, 0]      # basic rotation used on first display

    # DATA RESSOURCES URL
    urlWorldTopojson: "data/world_110m_admin_countries-capitals_simplified.json"
    urlCountryToRegion : "data/country_to_region.json"

  # Declare variables
  svg = projection = path = groupPaths = null


  #
  # Contruct class instance
  #
  constructor: (overridingConfig = {}) ->
    # Override config with new parameters
    config = _.defaults(overridingConfig, config)

    # Define initialScale
    config.initialScale = config.svgHeight * 0.5


  #
  # Initialize SVG context + sphere
  #
  initSVG: () ->

    # Create svg tag
    svg = d3.select(config.svgBlockSelector)
            .append("svg")
            .attr("width", config.svgWidth)
            .attr("height", config.svgHeight)

    # Create projection
    projection = d3.geo.orthographic()
                    .scale(config.initialScale)
                    .translate([config.svgWidth / 2, config.svgHeight / 2])
                    .rotate(config.globeDefaultRotation)
                    .clipAngle(90)

    # Create the globe path
    path = d3.geo.path()
             .projection(projection)

    # Create an empty circle (globe
    svg.append("path")
        .datum({type: "Sphere"})
        .attr("class", "sphere")
        .attr("d", path)

    # Create the group of path and add graticule
    groupPaths = svg.append("g")
                    .attr("class", "all-path")

    graticule = d3.geo.graticule()

    groupPaths.append("path")
                .datum(graticule)
                .attr("class", "graticule")
                .attr("d", path)


  #
  # Load and display data
  #
  start: () ->
    queue()
      .defer(d3.json, config.urlWorldTopojson)
      .defer(d3.json, config.urlCountryToRegion)
      .await(loadedDataCallback)


  #
  # Compute data after loading :
  #  - Build country paths
  #
  loadedDataCallback = (error, worldTopo, countryToRegion) ->

    # Add countries to globe
    countries = topojson.feature(worldTopo, worldTopo.objects.countries).features
    capitals = topojson.feature(worldTopo, worldTopo.objects.capitals).features

    groupPaths.selectAll(".country")
                .data(countries)
                .enter()
                  .append("path")
                  .attr("d", path)
                  .attr("class", "country")



window.Globe = Globe