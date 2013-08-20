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
  m0  = o0 = null

  currentRotation = config.globeDefaultRotation     # Store the current rotation of the globe
  currentLevel    = 1                               # Store the current level (1 or 2)
  manualRotationActivated = false                   # If true, mouse move calculation with me activated for manual rotate

  groupPathsSelection = {}          # Store the groupPath selection of element to avoid reselecting DOM

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
            .on("mousedown", mouseDown)
            .on("mousemove", mouseMove)
            .on("mouseup", mouseUp)

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


  ############
  # ROTATION #
  ############

  #
  # Store coodinates of the mouse when user click
  #
  mouseDown = () ->
    # remember where the mouse was pressed, in canvas coords
    m0 = [d3.event.pageX, d3.event.pageY]
    o0 = projection.rotate()

    # Performance : request a rotation using requestAnimationFrame
    manualRotationActivated = true
    animationRequest = requestAnimationFrame rotate

    d3.event.preventDefault()

  #
  # Release last mouse coordinate on mouse move
  #
  mouseUp = ->
    manualRotationActivated = false    # Stop rotation animation

    m0 = null if m0

  #
  # Calculate the new rotation coordinates depending mouse movement
  # Performance : the rotation is not anymore handled by mousemove
  # but using requestAnimationFrame in mouseDown
  #
  mouseMove = ->
    # Move only at level 1
    if m0 && currentLevel == 1

      m1 = [d3.event.pageX, d3.event.pageY]

      o1 = [o0[0] + (m1[0] - m0[0]) / 6, o0[1] + (m0[1] - m1[1]) / 6]
      o1[1] = (if o1[1] > 30 then 30 else (if o1[1] < -30 then -30 else o1[1]))

      # Only override first y axis value, we keep the same x axis value
      currentRotation[0] = o1[0]

  #
  # If the manual rotation is activate, it will rotate the globe using requestAnimationFrame
  #
  rotate = () ->
    # The new projection is calculated using the new rotation
    # Path are then redrawed
    if manualRotationActivated
      projection.rotate currentRotation

      redrawPathsOnRotationOrScale(currentRotation, projection.scale())
      animationRequest = requestAnimationFrame rotate

    # If the manualRotationActivated is false, requestAnimationFrame won't be called
    # and animation stop

  #
  # Redraw every path after sphere rotation
  #
  redrawPathsOnRotationOrScale = (rotation, scale) ->
    currentRotation = rotation

    projection
      .rotate(currentRotation)
      .scale(scale)

    # Performance : cache the selection
    groupPathsSelection["path"] = groupPaths.selectAll("path") unless groupPathsSelection["path"]

    groupPathsSelection["path"]
      .attr("d", path)



window.Globe = Globe