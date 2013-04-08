/* :indentSize=2:tabSize=2:noTabs=true: */

var domino = require('domino'),
  expect = require('chai').expect,
  coffeescript = require("coffee-script"),
  jqueryFactory = require('jquery');
  glyphtreeFactory = require(__dirname+"/../src/glyphtree.coffee");


describe('.glyphtree', function() {

  describe('#options', function() {

    it('should allow global options to be set', function () {
      var window = domino.createWindow('<body><div id="test"></div></body>'),
        document = window.document,
        $ = jqueryFactory.create(window),
        glyphtree = glyphtreeFactory.create(window);
      expect(glyphtree($('#test')).options.classPrefix).to.equal('glyphtree-');
      glyphtree.options.classPrefix = 'foobar-';
      expect(glyphtree($('#test')).options.classPrefix).to.equal('foobar-');
    });

  });

});

describe('GlyphTree', function() {

  describe('#options', function () {

    it('should allow options to be changed', function() {
      var window = domino.createWindow('<body><div id="test"></div></body>'),
        document = window.document,
        $ = jqueryFactory.create(window),
        glyphtree = glyphtreeFactory.create(window);
      var tree = glyphtree($('#test'));
      tree.options.classPrefix = 'foobar-';
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
      // Prefix should change
      expect($('.foobar-node').length).to.be.above(0);
      expect($('.glyphtree-node').length).to.equal(0);
    });

  });

  describe("#load()", function() {

    function createTestTree() {
      var window = domino.createWindow('<body><div id="test"></div></body>'),
        document = window.document,
        $ = jqueryFactory.create(window),
        glyphtree = glyphtreeFactory.create(window);
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
      return $;
    };

    it("should load and render a tree", function() {
      var $ = createTestTree();
      // Four nodes (root, subfolder, README, file.txt)
      expect($('.glyphtree-node').length).to.equal(4);
      // Three trees
      expect($('.glyphtree-tree').length).to.equal(3);
      // Two leaf nodes
      expect($('.glyphtree-leaf').length).to.equal(2);
    });

    it ("should bind click events", function() {
      var $ = createTestTree();
      // Tree starts unexpanded
      expect($('.glyphtree-expanded').length).to.equal(0);
      // Click a node
      $('#test > .glyphtree-tree > .glyphtree-node').click();
      // The hierarchy should expand one level
      expect($('.glyphtree-expanded').length).to.equal(1);
    });

  });

});
