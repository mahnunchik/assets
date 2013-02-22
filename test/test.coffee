Assets = null
assert = require 'assert'
fs = require 'fs'

describe 'Assets', ()->

  before (done)->
    configDir = process.cwd() + '/config'
    unless fs.existsSync(configDir)
      fs.mkdirSync(configDir)
    Assets = require('../')
    done()

  describe '#make()', ()->

    it 'single asset without options', ()->
      a = Assets({log: false})
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/test-454d740c0200f454a7e81b3cb06c945f.js'

    it 'single asset with options', ()->
      a = Assets
        log: false
        assetsDir: 'public'
        rootURI: '/abc/'
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/abc/test-454d740c0200f454a7e81b3cb06c945f.js'

    it 'multiple assets', ()->
      a = Assets
        log: false
        assetsDir: 'public'
        rootURI: '/abc/'
      js = 'test/fixtures/test.js'
      css= 'test/fixtures/test.css'
      a.make
        js:
          file: js
        css:
          file: css
          hash: false
      assert.notEqual a.tag('js'), null
      assert.notEqual a.tag('css'), null
      assert.equal a.url('js'), '/abc/test-454d740c0200f454a7e81b3cb06c945f.js'
      assert.equal a.url('css'), '/abc/test.css'

    it 'wrong key', ()->
      a = Assets({log: false})
      assert.equal a.tag('asdfgh'), ''
      assert.equal a.url('qwertyu'), ''

    it 'shoul asset images and replase url', ()->
      a = Assets({log: false})
      file = 'test/fixtures/bootstrap/css/bootstrap.css'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/bootstrap-18d58e803c7a54dc6427c82a6be780c5.css'
      assert.equal a.url('test/fixtures/bootstrap/img/glyphicons-halflings.png'), '/glyphicons-halflings-2516339970d710819585f90773aebe0a.png'
      assert.equal a.url('test/fixtures/bootstrap/img/glyphicons-halflings-white.png'), '/glyphicons-halflings-white-9bbc6e9602998a385c2ea13df56470fd.png'

    it 'shoul asset images and replase url (min css)', ()->
      a = Assets({log: false})
      file = 'test/fixtures/bootstrap/css/bootstrap.min.css'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/bootstrap.min-bc0b45d7d2a6c858b157b8c1f0e0c66e.css'
      assert.equal a.url('test/fixtures/bootstrap/img/glyphicons-halflings.png'), '/glyphicons-halflings-2516339970d710819585f90773aebe0a.png'
      assert.equal a.url('test/fixtures/bootstrap/img/glyphicons-halflings-white.png'), '/glyphicons-halflings-white-9bbc6e9602998a385c2ea13df56470fd.png'

  describe '#dir()', ()->
    it 'should asset directory', ()->
      a = Assets({log: false})
      a.dir("test/fixtures/**/*.png")
      assert.notEqual a.url 'test/fixtures/bootstrap/img/glyphicons-halflings-white.png', null
      assert.notEqual a.url 'test/fixtures/bootstrap/img/glyphicons-halflings.png', null
      assert.notEqual a.url 'test/fixtures/glyphicons-halflings-white.png', null

    it 'key should be without baseDir', ()->
      a = Assets({log: false})
      a.dir("fixtures/**/*.png", {baseDir: 'test', prefix: '/'})
      assert.notEqual a.url '/fixtures/bootstrap/img/glyphicons-halflings-white.png', null
      assert.notEqual a.url '/fixtures/bootstrap/img/glyphicons-halflings.png', null
      assert.notEqual a.url '/fixtures/glyphicons-halflings-white.png', null


