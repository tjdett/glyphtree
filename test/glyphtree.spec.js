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

  var testTreeStructure = [
    {
      id: '25018945-704e-40d6-98c1-a30729277663',
      name: "root",
      attributes: {
        foo: "bar"
      },
      children: [
        {
          id: '05089265-5f13-4fc8-a728-7a987c0c096e',
          name: "subfolder",
          children: [
            {
              id: '888c3513-9ab0-47e8-ab69-5b11effb1f6a',
              name: "README"
            },
            {
              // Intentionally no ID field, which should be fine
              name: "file.txt"
            }
          ]
        }
      ]
    }
  ];

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
          tree.load(testTreeStructure);
          // Prefix should change
          expect($('.foobar-node').length).to.be.above(0);
          expect($('.glyphtree-node').length).to.equal(0);
          done();
        }
      );
    });

  });

  describe('#load()', function() {

    it('should load and render a tree', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
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

  describe('#add()', function() {

    it('should add nodes to the root', function(done) {
      withTestTree({}, function(tree, $) {
        // No nodes initially
        expect($('.glyphtree-node').length).to.equal(0);
        for (var i = 1; i <= 5; i++) {
          var nodeName = "root node "+i;
          // Add a node
          tree.add({
            name: nodeName
          });
          // A single node should exist
          expect($('.glyphtree-node').length).to.equal(i);
          expect($('.glyphtree-node:contains('+nodeName+')').length)
            .to.equal(1);
          expect($('.glyphtree-tree').length).to.equal(1);
        }
      }, done);
    });

    it('should add nodes to a parent designated by ID', function(done) {
      withTestTree({}, function(tree, $) {
        // No nodes initially
        expect($('.glyphtree-node').length).to.equal(0);
        for (var i = 1; i <= 5; i++) {
          var nodeName = "root node "+i;
          // Add a node
          tree.add({
            id: i,
            name: nodeName
          }, i > 1 ? i-1 : null);
          // A single node should exist
          expect($('.glyphtree-node').length).to.equal(i);
          expect($('.glyphtree-node > .glyphtree-node-label:contains('
            +nodeName+')').length).to.equal(1);
          expect($('.glyphtree-tree').length).to.equal(i);
        }
      }, done);
    });

  });

  describe('#remove()', function() {
    it('should remove nodes designated by ID', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var nodeName = 'README'
        expect($('.glyphtree-node > .glyphtree-node-label:contains('
            +nodeName+')').length).to.equal(1);
        tree.remove('888c3513-9ab0-47e8-ab69-5b11effb1f6a');
        expect($('.glyphtree-node > .glyphtree-node-label:contains('
            +nodeName+')').length).to.equal(0);
      }, done);
    });
  });


  describe('#find()', function () {

    it('should return the node with the given ID', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var node;
        node = tree.find('888c3513-9ab0-47e8-ab69-5b11effb1f6a');
        expect(node.name).to.equal('README');
        expect(node.isLeaf()).to.be.true;
        node = tree.find('25018945-704e-40d6-98c1-a30729277663');
        expect(node.name).to.equal('root');
        expect(node.isLeaf()).to.be.false;
      }, done);
    });

    it('should return null if no node found', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var node;
        node = tree.find('foobar');
        expect(node).to.be.null;
        node = tree.find(null);
        expect(node).to.be.null;
      }, done);
    });
  });

  describe('#find()', function () {

    it('should return the node with the given ID', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var node;
        node = tree.find('888c3513-9ab0-47e8-ab69-5b11effb1f6a');
        expect(node.name).to.equal('README');
        expect(node.isLeaf()).to.be.true;
        node = tree.find('25018945-704e-40d6-98c1-a30729277663');
        expect(node.name).to.equal('root');
        expect(node.isLeaf()).to.be.false;
      }, done);
    });

    it('should return null if no node found', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var node;
        node = tree.find('foobar');
        expect(node).to.be.null;
        node = tree.find(null);
        expect(node).to.be.null;
      }, done);
    });
  });

  describe('#nodes()', function () {
    it('should produce array of nodes in depth-first order', function(done) {
      withTestTree(testTreeStructure, function(tree, $) {
        var nodes = tree.nodes();
        expect(nodes[0].name).to.equal('root');
        expect(nodes[1].name).to.equal('subfolder');
        expect(nodes[2].name).to.equal('README');
        expect(nodes[3].name).to.equal('file.txt');
      }, done);
    });
  });

  describe("#expandAll()", function() {

    it ("should expand all trees", function(done) {
      withTestTree(testTreeStructure, function (tree, $) {
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
      withTestTree({}, function (tree, $) {
        tree.options.startExpanded = true
        tree.load(testTreeStructure)
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
      withTestTree(testTreeStructure, function (tree, $) {
        var nodeCount = 0, leafCount = 0;
        tree.walk(function(node) { nodeCount++ });
        tree.walk(function(node) { if (node.isLeaf()) leafCount++ });
        expect(nodeCount).to.equal(4);
        expect(leafCount).to.equal(2);
      }, done);
    });

  });

  describe("default user events", function() {
    function doExpansionTest(toggleAction, callback) {
      withTestTree(testTreeStructure, function (tree, $) {
        var $e =
          $([ '#test', '.glyphtree-tree',
              '.glyphtree-node:not(.glyphtree-leaf)'
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

  });

  function withTestTree(structure, jqueryTestFunc, callback) {
    jsdom.env(
      '<body><div id="test"></div></body>',
      function(errors, window) {
        var document = window.document,
          $ = jqueryFactory.create(window),
          glyphtree = glyphtreeFactory.create(window);
        var tree = glyphtree($('#test'));
        tree.load(structure);
        jqueryTestFunc(tree, $);
        callback();
      }
    );
  };

});
