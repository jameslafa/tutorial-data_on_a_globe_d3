class Globe
  # Define default config
  config =
    # SVG
    svgBlockSelector: ".globe-container"
    svgHeight: 600
    svgWidth: 600

    # GLOBE
    globeDefaultRotation: [0, -10, 0]      # basic rotation used on first display

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



window.Globe = Globe