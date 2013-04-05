###!
#     Copyright (c) 2013 The University of Queensland
#     MIT Licence - see COPYING for details.
###

# Export methods for node.js testing or browser window
root = exports ? this

defaults =
  classPrefix: "filetree-"
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

root.glyphtree = (e) ->
  # Writing a cross-browser widget with DOM manipulation is hard, so
  # GlyphTree needs jQuery (or something like it)
  if (typeof($) == 'undefined')
    throw new Exception 'GlyphTree requires jQuery (or a compatible clone).'
  new GlyphTree(e)

root.glyphtree.options = defaults  

class GlyphTree
  
  constructor: (@element) ->
    @options = root.glyphtree.options
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
    style = (typeName, type) =>
      # Make the default state being the absence of a state class
      stateSelector = (state) =>
        if state == 'default' then '' else '.'+@_stateClass(state)
      typeSelector = (t) =>
        if t == 'default' then '' else '.'+@_typeClass(t)
      # Setup icons for each of the states. 
      # Any missing will have the default state icon.
      ("""
      .#{@idClass} ul li.#{@_nodeClass()}#{stateSelector(state)}#{typeSelector(typeName)}:before {
        font-family: #{type.icon[state].font};
        content: '#{type.icon[state].content}';
      }
      """ for state in ['default', 'leaf', 'expanded'] when type.icon[state]).join("\n")+
      # Hide children except when expanded
      """
      .#{@idClass} ul li.#{@_nodeClass()}#{stateSelector('default')}#{typeSelector(typeName)} > ul.#{@_treeClass()} {
        display: none;
      }
      .#{@idClass} ul li.#{@_nodeClass()}#{stateSelector('expanded')}#{typeSelector(typeName)} > ul.#{@_treeClass()} {
        display: block;
      }
      """
    boilerplate = """
    .#{@idClass} ul {
      list-style-type: none;
    }
    .#{@idClass} ul li.#{@_nodeClass()} {
      cursor: pointer;
    }
    .#{@idClass} ul li.#{@_nodeClass()}:before {
      width: 1em;
      text-align: center;
      display: inline-block;
      padding-right: 1ex;
      speak: none;
    }
    """
    boilerplate + "\n"+ (style(k,v) for k,v of @options.types).join("\n")
      
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
    makeElement = (node) =>
      $li = $("<li/>")
      $li.text(node.name)
      $li.addClass(@_nodeClass())
      $li.addClass(@_typeClass(node.type ? 'default'))
      $li.attr("data-#{k}", v) for k, v of node.attributes
      if (node.children ? []).length == 0
        $li.addClass(@_stateClass('leaf'))
      else
        expandedClass = @_stateClass('expanded')
        $li.click (e) ->
          if this == e.target
            $(this).toggleClass(expandedClass)
      if node.children
        $li.append(makeElements(node.children))
      $li
    
    makeElements = (nodes) =>
      $list = $("<ul/>")
      $list.addClass(@_treeClass())
      $list.append(makeElement(node)) for node in nodes
      $list
    
    $(@element).empty()
    $(@element).append(makeElements(structure))
    this
    
  _nodeClass: () -> @options.classPrefix+"node"
  _treeClass: () -> @options.classPrefix+"tree"
  
  _typeClass: (typeName) ->
    @options.classPrefix+'type-'+typeName
    
  _stateClass: (state) ->
    @options.classPrefix+state
