/* :indentSize=2:tabSize=2:noTabs=true: */

var domino = require('domino'),
  coffeescript = require("coffee-script");

// Use Chai for assertions
require('chai').should();

describe('GlyphTree', function() {

  describe("#load()", function() {

    it("should load and render a tree", function() {
      var window = domino.createWindow('<body><div id="test"></div></body>'),
        document = window.document,
        $ = loadJQuery(window),
        glyphtree = loadGlyphTree(window);
      var tree = glyphtree($('#test'));
      tree.load([
        {
          name: "root",
          attributes: {
            foo: "bar"
          },
          children: [
            {
              name: "subfolder",
              children: [
                {
                  name: "README"
                },
                {
                  name: "file.txt"
                }
              ]
            }
          ]
        }
      ]);
      // Three nodes (root, subfolder, README, file.txt)
      $('.glyphtree-node').should.have.lengthOf(4);
      // Three trees
      $('.glyphtree-tree').should.have.lengthOf(3);
      // Two leaf nodes
      $('.glyphtree-leaf').should.have.lengthOf(2);

      // Tree starts unexpanded
      $('.glyphtree-expanded').should.have.lengthOf(0);
      // Click a node
      $('#test > .glyphtree-tree > .glyphtree-node').click();
      $('.glyphtree-expanded').should.have.lengthOf(1);
    });

  });

});

// ## Utility functions

// Load jQuery in mock DOM window
function loadJQuery(window) {
  var jquery = require('jquery');
  jquery.create(window);
  return window.jQuery;
}

// Load GlyphTree in mock DOM window
function loadGlyphTree(window) {
  var glyphtree = require(__dirname+"/../src/glyphtree.coffee");
  glyphtree.create(window);
  return window.glyphtree;
}
