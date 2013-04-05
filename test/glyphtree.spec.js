/* :indentSize=2:tabSize=2:noTabs=true: */

var jquery = require('jquery-latest'),
  jsdom = require('jsdom'),
  coffeescript = require("coffee-script");
  
// Use Chai for assertions
require('chai').should();
  

  
describe('GlyphTree', function() {

  describe("#load()", function() {

    it("should load and render a tree", function(done) {
      jsdom.env({
        html: '<body><div id="test"></div></body>',
        done: function(errors, window) {
          var $ = loadJQuery(window),
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
                      name: "file.txt"
                    }
                  ]
                }
              ]
            }
          ]);
          $('.glyphtree-node').should.have.lengthOf(3);
          done();
        }
      });
    });
    
  });
  
});

// ## Utility functions

// Load jQuery in JSDOM window
function loadJQuery(window) {
  var jquery = require('jquery-latest');
  jquery.create(window);
  return window.jQuery;
}

// Load GlyphTree in JSDOM window
function loadGlyphTree(window) {
  var glyphtree = require(__dirname+"/../src/glyphtree.coffee");
  glyphtree.create(window);
  return window.glyphtree;
}
