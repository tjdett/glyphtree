###!
#     Copyright (c) 2013 The University of Queensland
#     MIT Licence - see COPYING for details.
###

defaults = () ->
  classPrefix: "glyphtree-"
  startExpanded: false
  types:
    default:
      icon:
        default:
          content: "\u25b6"
          font: "inherit"
        leaf:
          content: "\u2022"
          font: "inherit"
        expanded:
          content: "\u25bc"
          font: "inherit"
    folder:
      icon:
        default:
          content: "\uf07b"
          font: "FontAwesome"
        expanded:
          content: "\uf07c"
          font: "FontAwesome"
    file:
      icon:
        leaf:
          content: "\uf016"
          font: "FontAwesome"

# Create new GlyphTree function bound to a particular window
bindToWindow = (window) ->
  options = defaults()
  # Bind function to the window context
  window.glyphtree = (element) ->
    glyphtree.call(window, element, options)
  # Expose options so they can be changed
  window.glyphtree.options = options
  # Return bound function
  window.glyphtree

# Node.js-only method for binding
if exports?
  exports.create = (windowToInit) ->
    bindToWindow(windowToInit)
else
  # Bind to the window in the browser environment
  bindToWindow(this)

glyphtree = (element, options) ->
  # Set up the Environment
  # ----------------------
  #
  # Writing a cross-browser widget with DOM manipulation is hard, so
  # GlyphTree needs jQuery (or something like it)
  $ = this.jQuery ? this.$
  if (typeof($) == 'undefined')
    throw new Error 'GlyphTree requires jQuery (or a compatible clone).'

  # Define Classes
  # --------------
  #
  # We define our classes in this context so they get access to `$`.
  class GlyphTree

    constructor: (@element, defaults) ->
      # Create options instance by cloning global settings
      @options = $.extend({}, defaults)
      # Use random ID 32-bit number to identify this tree
      randomId = Math.floor(Math.random()*Math.pow(2,32)).toString(16)
      # Add ID class so styles can address this tree only
      @idClass = @options.classPrefix+'id'+randomId
      $(@element).addClass(@idClass)
      # Add the stylesheet to the dom
      @_styleElement = this.setupStyle()

    setupStyle: () ->
      $style = $('<style/>')
      $style.attr('type', 'text/css')
      $style.text(this.getStyle())
      $('body').append($style)
      $style

    getStyle: () ->
      cr = new ClassResolver(@options.classPrefix)
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
          """
          .#{@idClass} ul li.#{cr.node()}#{sel(state, name)}:before {
            font-family: #{config.icon[state].font};
            content: '#{config.icon[state].content}';
          }
          """).join("\n") +
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
      .#{@idClass} ul li.#{cr.node()}:before {
        width: 1em;
        text-align: center;
        display: inline-block;
        padding-right: 1ex;
        speak: none;
      }
      """
      boilerplate + "\n"+ (typeStyle(k,v) for k,v of @options.types).join("\n")

    # Takes a structure something like:
    #
    #     [
    #       {
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
    load: (structure) ->
      cr = new ClassResolver(@options.classPrefix)
      @_setRootContainer(
        new NodeContainer(new Node(root, cr) for root in structure, cr)
      )
      if @options.startExpanded
        @expandAll()
      this

    add: (structure, parentId) ->
      cr = new ClassResolver(@options.classPrefix)
      if parentId?
        @find(parentId).addChild(new Node(structure, cr))
      else
        if !(@rootNodes?)
          @_setRootContainer(new NodeContainer())
        @rootNodes.add(new Node(structure, cr))
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
      $(@element).empty()
      $(@element).append(container.element())
      this

    class Node

      constructor: (struct, classResolver) ->
        @cr = classResolver
        @id = struct.id
        @name = struct.name
        @type = struct.type
        @attributes = struct.attributes
        children = if struct.children
          (new Node(child, classResolver) for child in struct.children)
        else
          []
        @children = new NodeContainer(children, classResolver)
        # Decorate with show/hide node expansion methods.
        expandedClass = @cr.state('expanded')
        @isExpanded = () -> @element().hasClass(expandedClass)
        @expand     = () -> @element().addClass(expandedClass)
        @collapse   = () -> @element().removeClass(expandedClass)

      addChild: (node) ->
        wasLeaf = @isLeaf()
        @children.add(node)
        if wasLeaf
          @element().append(@children.element())

      remove: () ->
        @container.remove(this)

      element: () ->
        @_element ||= @_buildElement()

      isLeaf: () ->
        @children.empty()

      _buildElement: () ->
        $li = $('<li/>')
          .addClass(@cr.node())
          .addClass(@cr.type(@type ? 'default'))
        $label = $('<span/>')
          .addClass(@cr.node('label'))
          .text(@name)
        $li.append($label)
        if @isLeaf()
          $li.addClass(@cr.state('leaf'))
        else
          $li.append(@children.element())
        @_attachEvents($li, 'icon')
        @_attachEvents($label, 'label')
        $li

      toggleExpansion = (event, node) ->
        if node.isExpanded()
          node.collapse()
        else
          node.expand()

      events:
        icon:
          click: [ toggleExpansion ]
        label:
          click: [ toggleExpansion ]

      _attachEvents: ($element,  eventMapKey) ->
        watchedEvents = """
          click
          keydown
          keypress
          keyup
          mouseover
          mouseout
        """.replace(/\s+/gm, ' ').trim()
        # Register a generic event handler pointing back to the events map
        $element.on watchedEvents, (e) =>
          if @events[eventMapKey][e.type]?
            # Prevent bubbling
            if e.currentTarget == e.target
              for handler in @events[eventMapKey][e.type]
                # Call handler with (original event, node)
                handler(e, this)

    class NodeContainer

      constructor: (@nodes, @cr) ->
        for node in @nodes
          node.container = this

      empty: () -> @nodes.length == 0

      add: (node) ->
        @nodes.push(node)
        @_rebuildElement()

      remove: (node) ->
        if node in @nodes
          node.element().remove()
          @nodes = @nodes.filter (n) -> n isnt node
        else
          throw new Error('Node not in this container')

      element: () ->
        @_element ||= @_buildElement()

      _buildElement: () ->
        $list = $("<ul/>")
        $list.addClass(@cr.tree())
        $list.append(node.element() for node in @nodes)
        $list

      _rebuildElement: () ->
        if @_element?
          for node in @nodes
            node.element().detach()
          @_element.append(node.element() for node in @nodes)
        else
          @element()

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
      type: (type) -> @prefix + 'type-' + type
      state: (state) -> @prefix + state

  # Return new GlyphTree
  new GlyphTree(element, options)
