###!
#     Copyright (c) 2013 The University of Queensland
#     MIT Licence - see COPYING for details.
###

defaults = () ->
  classPrefix: "glyphtree-"
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
      # Creat options instance by cloning global settings
      @options = $.extend({}, defaults)
      randomId = Math.floor(Math.random()*Math.pow(2,32)).toString(16)
      @idClass = @options.classPrefix+'id'+randomId
      $(@element).addClass(@idClass)

      this.setupStyle()

    setupStyle: () ->
      $style = $('<style/>')
      $style.attr('type', 'text/css')
      $style.text(this.getStyle())
      $('body').append($style)

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
      @rootNodes = new NodeContainer(new Node(root, cr) for root in structure, cr)
      @render()
      this

    # Render the container
    render: () ->
      $(@element).empty()
      $(@element).append(@rootNodes.element())
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

      element: () ->
        @_element ||= @_buildElement()

      _buildElement: () ->
        $li = $("<li/>")
        $li.text(@name)
        $li.addClass(@cr.node())
        $li.addClass(@cr.type(@type ? 'default'))
        if @children.empty()
          $li.addClass(@cr.state('leaf'))
        else
          expandedClass = @cr.state('expanded')
          $li.click (e) ->
            if this == e.target
              $(this).toggleClass(expandedClass)
          $li.append(@children.element())
        $li

    class NodeContainer

      constructor: (@nodes, @cr) ->

      empty: () -> @nodes.length == 0

      element: () ->
        @_element ||= @_buildElement()

      _buildElement: () ->
        $list = $("<ul/>")
        $list.addClass(@cr.tree())
        $list.append(node.element() for node in @nodes)
        $list

    # Handles resolution of DOM classes
    class ClassResolver
      constructor: (@prefix) ->

      node: () -> @prefix + "node"
      tree: () -> @prefix + "tree"
      type: (type) -> @prefix + 'type-' + type
      state: (state) -> @prefix + state

  # Return new GlyphTree
  new GlyphTree(element, options)
