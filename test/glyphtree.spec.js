/* :indentSize=2:tabSize=2:noTabs=true: */

var jsdom = require("jsdom"),
  expect = require('chai').expect,
  coffeescript = require("coffee-script"),
  jqueryFactory = require('jquery');
  glyphtreeFactory = require(__dirname+"/../src/glyphtree.coffee");


describe('.glyphtree', function() {

  describe('#options', function() {

    it('should allow global options to be set', function (done) {
      jsdom.env(
        '<body><div id="test"></div></body>',
        function(errors, window) {
          var document = window.document,
            $ = jqueryFactory.create(window),
            glyphtree = glyphtreeFactory.create(window);
          expect(glyphtree($('#test')).options.classPrefix)
            .to.equal('glyphtree-');
          glyphtree.options.classPrefix = 'foobar-';
          expect(glyphtree($('#test')).options.classPrefix)
            .to.equal('foobar-');
          done();
        }
      );
    });

  });

});

describe('GlyphTree', function() {

  describe('#options', function () {

    it('should allow options to be changed', function(done) {
      jsdom.env(
        '<body><div id="test"></div></body>',
        function(errors, window) {
          var document = window.document,
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
          done();
        }
      );
    });

  });

  describe("#load()", function() {

    it("should load and render a tree", function(done) {
      withTestTree(function(tree, $) {
        // Four nodes (root, subfolder, README, file.txt)
        expect($('.glyphtree-node').length).to.equal(4);
        // Four nodes name spans (root, subfolder, README, file.txt)
        expect($('span.glyphtree-node-label').length).to.equal(4);
        // Three trees
        expect($('.glyphtree-tree').length).to.equal(3);
        // Two leaf nodes
        expect($('.glyphtree-leaf').length).to.equal(2);
      }, done);
    });

  });

  describe("user events", function() {
    function doExpansionTest(toggleAction, callback) {
      withTestTree(function (tree, $) {
        var $e =
          $([ '#test', '.glyphtree-tree',
              '.glyphtree-node:not(.glyphtree-leaf)',
              '.glyphtree-node-label'
            ].join(' > ')).first()
        // Tree starts unexpanded
        expect($('.glyphtree-expanded').length).to.equal(0);
        // Expand
        toggleAction($e, $);
        // The hierarchy should expand one level
        expect($('.glyphtree-expanded').length).to.equal(1);
        // Collapse
        toggleAction($e, $);
        // The hierarchy should collapse one level
        expect($('.glyphtree-expanded').length).to.equal(0);
      }, callback);
    }

    it ("should toggle expansion on click", function(done) {
      doExpansionTest(function($e) { $e.click() }, done);
    });

    it ("should toggle expansion on enter keydown", function(done) {
      // Press enter
      doExpansionTest(function($e, $) {
        $e.trigger($.Event("keydown", { keyCode: 0x0d }));
      }, done);
    });

    it ("should toggle expansion on space keydown", function(done) {
      // Press space
      doExpansionTest(function($e, $) {
        $e.trigger($.Event("keydown", { keyCode: 0x20 }));
      }, done);
    });

  });

  describe("#expandAll()", function() {

    it ("should expand all trees", function(done) {
      withTestTree(function (tree, $) {
        // Tree starts unexpanded
        expect($('.glyphtree-expanded').length).to.equal(0);
        // Click a node
        tree.expandAll();
        // The hierarchy should expand all nodes
        expect($('.glyphtree-expanded').length).to.equal(4);
      }, done);
    });

  });

  describe("#collapseAll()", function() {

    it ("should collapse all trees", function(done) {
      withTestTree(function (tree, $) {
        tree.options.startExpanded = true
        tree.render()
        // Tree starts expanded
        expect($('.glyphtree-expanded').length).to.equal(4);
        // Click a node
        tree.collapseAll();
        // The hierarchy should expand all nodes
        expect($('.glyphtree-expanded').length).to.equal(0);
      }, done);
    });

  });

  describe("#walk()", function() {

    it ("should perform a function for all nodes in the tree", function(done){
      withTestTree(function (tree, $) {
        var nodeCount = 0, leafCount = 0;
        tree.walk(function(node) { nodeCount++ });
        tree.walk(function(node) { if (node.isLeaf()) leafCount++ });
        expect(nodeCount).to.equal(4);
        expect(leafCount).to.equal(2);
      }, done);
    });

  });

  function withTestTree(jqueryTestFunc, callback) {
    jsdom.env(
      '<body><div id="test"></div></body>',
      function(errors, window) {
        var document = window.document,
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
        jqueryTestFunc(tree, $);
        callback();
      }
    );
  };

});
