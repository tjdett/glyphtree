###!
#     Copyright (c) 2013 The University of Queensland
#     MIT Licence - see COPYING for details.
###

# # GlyphTree.js
#
# GlyphTree provides a light-weight visual tree for managing hierarchical
# data without requiring the traditional boat-load of image & CSS resources.
#
# It does this by:
#
#  * only using font glyphs (single character strings + fonts) for icons
#  * injecting its own generated stylesheets into the document
#
# It is built with Twitter Bootstrap in mind, but should work with almost any
# sensible stylesheet.

toggleExpansionHandler = (event, node) ->
  if !node.isLeaf()
    if node.isExpanded()
      node.collapse()
    else
      node.expand()

# ## Defaults
#
# GlyphTree allows you to be fairly flexibile about CSS it generates, and how
# it shows content in the DOM.
#
# You can:
defaults = () ->
  # * define the prefix used for all classes;
  classPrefix: "glyphtree-"
  # * create the tree already expanded;
  startExpanded: false
  # * specify event handlers for node interactions;
  events:
    icon:
      click: [ toggleExpansionHandler ]
    label:
      click: [ toggleExpansionHandler ]
  # * specify custom types for nodes, and their styling;
  types:
    default:
      icon:
        default:
          content: "\u25b6" # Right triangle
        leaf:
          content: "\u2022" # Bullet
        expanded:
          content: "\u25bc" # Down triangle
  # * specify your own function to determine what type a node is, allowing you
  #   to determine types client-side.
  typeResolver: (struct) ->
    struct.type
  # * specify your own function to determine the natural order of nodes, so
  #   you can sort based on your own criteria. (default: sort by name)
  nodeComparator: (nodeA, nodeB) ->
    switch
      when nodeA.name < nodeB.name then -1
      when nodeA.name > nodeB.name then 1
      else 0

# ## Producing a new GlyphTree
#
# To create a new GlyphTree, you can do something like this:
#
#     var element = document.getElementById('test'),
#         options = { classPrefix: 'myownglyphtreeprefix-' };
#     glyphtree(element, options);
#
glyphtree = (element, options) ->
  # ## Environment
  #
  # Writing a cross-browser widget with DOM manipulation is hard, so
  # GlyphTree needs jQuery (or something like it).
  $ = this.jQuery ? this.$
  if (typeof($) == 'undefined')
    throw new Error 'GlyphTree requires jQuery (or a compatible clone).'

  # ## Classes
  #
  # We define our classes in this context so they get access to `$`.

  # ### GlyphTree
  #
  # The main class for tree interactions. It interprets the provided options,
  # maintains the tree style, and provides access to tree nodes.
  class GlyphTree

    # The contructor sets up the tree and prepares the DOM to accept new
    # nodes. It:
    constructor: (@element, @_options) ->
      # * creates a random ID 32-bit number to identify this tree
      randomId = Math.floor(Math.random()*Math.pow(2,32)).toString(16)
      # * adds an ID class so styles can address this tree only
      @idClass = @_options.classPrefix+'id'+randomId
      $(@element).addClass(@idClass)
      # * creates helper functions for `Node` & `NodeContainer`
      @classResolver = new ClassResolver(@_options.classPrefix)
      @compareNodes = @_options.nodeComparator
      @resolveType = @_options.typeResolver
      # * adds the generated stylesheet to the DOM
      @_styleElement = this.setupStyle()
      # * populates event handlers
      @events = @_options.events
      # * sets the default expansion state
      @startExpanded = @_options.startExpanded
      # * creates an empty root container
      @_setRootContainer(new NodeContainer([], this, null))

    setupStyle: () ->
      # Using "$style.text()" doesn't work for IE8, so...
      $style = $('<style type="text/css">'+this.getStyle()+'</style>')
      $('body').append($style)
      $style

    getStyle: () ->
      cr = @classResolver
      styleExpr = (property, value) ->
        if value.match(/^(#|rgb|\d)/)
          "#{property}: #{value};"
        else
          "#{property}: \"#{value}\";"
      # Produce style rules for each type
      typeStyle = (name, config) =>
        # Make the default state being the absence of a state class.
        sSel = (state) =>
          if state == 'default' then '' else '.'+cr.state(state)
        # Ensure fallback to default styling for unknown types.
        tSel = (type) =>
          if type == 'default' then '' else '.'+cr.type(type)
        # Combine for convenience.
        sel = (state, type) -> sSel(state)+tSel(type)
        # Setup icons for each of the states.
        # Any missing will have the default state icon.
        (for state in ['default', 'leaf', 'expanded'] when config.icon[state]
          ".#{@idClass} ul li.#{cr.node()}#{sel(state, name)} > span.#{cr.node('icon')}:after {" +
          (styleExpr(k, v) for k, v of config.icon[state]).join(" ") +
          "}").join("\n")+"\n" +
        # Hide children except when expanded
        """
        .#{@idClass} ul li.#{cr.node()}#{sel('default',name)} > ul.#{cr.tree()} {
          display: none;
        }
        .#{@idClass} ul li.#{cr.node()}#{sel('expanded',name)} > ul.#{cr.tree()} {
          display: block;
        }
        """
      # Basic style settings which apply to all nodes
      boilerplate = """
      .#{@idClass} ul {
        list-style-type: none;
      }
      .#{@idClass} ul li.#{cr.node()} {
        cursor: pointer;
      }
      .#{@idClass} ul li.#{cr.node()} > span.#{cr.node('icon')}:after {
        width: 1em;
        text-align: center;
        display: inline-block;
        padding-right: 1ex;
        speak: none;
      }
      """
      boilerplate + "\n"+ (typeStyle(k,v) for k,v of @_options.types).join("\n")

    # Takes a structure something like:
    #
    #     [
    #       {
    #         id: '25018945-704e-40d6-98c1-a30729277663',
    #         name: "root",
    #         type: "folder",
    #         attributes: {
    #           foo: "bar"
    #         },
    #         children: [
    #           {
    #             name: "file.txt",
    #             type: "file"
    #           }
    #         ]
    #       }
    #     ]
    #
    #  IDs, attributes and type are optional.
    load: (structure) ->
      @_setRootContainer(
        new NodeContainer(
          new Node(root, this) for root in structure, 
          this, 
          null))
      this

    # Takes a plain object structure for a node, like:
    #
    #     {
    #       id: '25018945-704e-40d6-98c1-a30729277663',
    #       name: 'root',
    #       attributes: {
    #         foo: 'bar'
    #       }
    #     }
    #
    add: (structure, parentId) ->
      if parentId?
        parent = @find(parentId)
        if not parent?
          throw new Error('Cannot add node - unknown parent node ID')
        parent.addChild(new Node(structure, this))
      else
        @rootNodes.add(new Node(structure, this))
      this

    update: (structure) ->
      nodeId = structure.id
      if !nodeId?
        throw new Error('Cannot update without provided ID')
      node = @find(nodeId)
      if node
        node.update(structure)
      this

    remove: (nodeId) ->
      node = @find(nodeId)
      if node?
        node.remove()
      this

    expandAll: () ->
      @walk (node) ->
        node.expand()

    collapseAll: () ->
      @walk (node) ->
        node.collapse()

    # Find node by ID
    find: (id) ->
      for n in @nodes()
        if n.id == id
          return n
      null

    # Get array of nodes in depth-first order.
    nodes: () ->
      nodes = []
      @walk (n) ->
        nodes.push(n)
      nodes

    # Walk all nodes in the tree.
    walk: (f) ->
      if !@rootNodes.empty()
        @rootNodes.walkNodes f
      this

    _setRootContainer: (container) ->
      @rootNodes = container
      $(@element).html(container.element())
      this

    class Node

      constructor: (struct, @tree) ->
        @_cr = @tree.classResolver
        @id = struct.id
        @name = struct.name
        @type = @tree.resolveType(struct)
        @attributes = struct.attributes
        children = if struct.children
          (new Node(child, @tree) for child in struct.children)
        else
          []
        @children = new NodeContainer(children, @tree, this)
        # Decorate with show/hide node expansion methods.
        expandedClass = @_cr.state('expanded')
        @isExpanded = () -> @element().hasClass(expandedClass)
        @expand     = () -> @element().addClass(expandedClass)
        @collapse   = () -> @element().removeClass(expandedClass)

      parent: () ->
        @container.parentNode
        
      addChild: (node) ->
        wasLeaf = @isLeaf()
        @children.add(node)
        if wasLeaf
          @element().append(@children.element())

      update: (struct) ->
        @id = struct.id
        @name = struct.name
        formerType = @type
        @type = @tree.resolveType(struct)
        @attributes = struct.attributes
        @container.refresh()
        @_rebuildElement(formerType)
        this

      remove: () ->
        @container.remove(this)

      element: () ->
        @_element ||= @_buildElement()

      isLeaf: () ->
        @children.empty()

      _buildElement: () ->
        $li = $('<li/>')
          .addClass(@_cr.node())
          .addClass(@_cr.type(@type))
        $icon = $('<span/>')
          .addClass(@_cr.node('icon'))
        $label = $('<span/>')
          .addClass(@_cr.node('label'))
          .attr('tabindex', -1) # Allow focusing on label
          .text(@name)
        $li.append($icon)
        $li.append($label)
        if @isLeaf()
          $li.addClass(@_cr.state('leaf'))
        else
          $li.append(@children.element())
        if @tree.startExpanded
          $li.addClass(@_cr.state('expanded'))
        @_attachEvents($icon, 'icon')
        @_attachEvents($label, 'label')
        $li

      _rebuildElement: (formerType) ->
        if @_element?
          if (formerType != @type)
            @_element.removeClass(@_cr.type(formerType))
            @_element.addClass(@_cr.type(@type))
          $label = @_element.children('.'+@_cr.node('label'))
          $label.text(@name)
        else
          @element()

      _attachEvents: ($element,  eventMapKey) ->
        watchedEvents = [
          'click',
          'keydown',
          'keypress',
          'keyup',
          'mouseenter',
          'mouseleave'
        ].join(' ');
        # Register a generic event handler pointing back to the events map
        $element.on watchedEvents, (e) =>
          if @tree.events[eventMapKey][e.type]?
            for handler in @tree.events[eventMapKey][e.type]
              # Call handler with (original event, node)
              handler(e, this)

    class NodeContainer

      constructor: (@nodes, tree, @parentNode) ->
        @_cr = tree.classResolver
        @_compareNodes = (a, b) ->
          tree.compareNodes(a, b)
        for node in @nodes
          node.container = this
        @_sort()

      empty: () -> @nodes.length == 0

      add: (node) ->
        @nodes.push(node)
        node.container = this
        @refresh()

      remove: (node) ->
        if node in @nodes
          node.element().remove()
          @nodes = (n for n in @nodes when n isnt node)
        else
          throw new Error('Node not in this container')

      refresh: () ->
        @_sort()
        @_rebuildElement()
          
      element: () ->
        @_element ||= @_buildElement()

      _buildElement: () ->
        $list = $("<ul/>")
        $list.addClass(@_cr.tree())
        $list.append(node.element() for node in @nodes)
        $list

      _rebuildElement: () ->
        if @_element?
          for node in @nodes
            node.element().detach()
          @_element.append(node.element() for node in @nodes)
        else
          @element()

      # Sort nodes using comparator
      _sort: () ->
        @nodes.sort(@_compareNodes)

      # Walk all nodes in the tree.
      #
      # Callback should return false to halt early.
      walkNodes: (f) ->
        for node in @nodes
          result = f(node)
          if !node.children.empty()
            node.children.walkNodes(f)
        undefined

    # Handles resolution of DOM classes
    class ClassResolver
      constructor: (@prefix) ->

      node: (attr) ->
        if attr
          @node() + "-" + attr
        else
          @prefix + "node"

      tree: () -> @prefix + "tree"
      type: (type) -> @prefix + 'type-' + (type ? 'default')
      state: (state) -> @prefix + state

  # Return new GlyphTree
  new GlyphTree(element, options)

# ## Window binding
#
# GlyphTree is designed to be tested by Node.js, so it handles injection of
# a window into its environment.
bindToWindow = (window) ->
  options = defaults()
  # Options are deep-merged together
  deepMerge = (obj, defaults) ->
    h = {}
    for k, v of defaults
      h[k] = v
    for k, v of obj
      if typeof(h[k]) == 'object'
        h[k] = deepMerge(v, h[k])
      else
        h[k] = v
    h
  # Bind function to the window context
  window.glyphtree = (element, opts) ->
    glyphtree.call(window, element, deepMerge(opts ? {}, options))
  # Expose options so they can be changed
  window.glyphtree.options = options
  # Return bound function
  window.glyphtree

if exports?
  # Node.js-only method for binding
  exports.create = (windowToInit) ->
    bindToWindow(windowToInit)
else
  # Bind to the window in the browser environment
  bindToWindow(this)


