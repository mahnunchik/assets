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
      a = Assets()
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/test-454d740c0200f454a7e81b3cb06c945f.js'
    it 'single asset with options', ()->
      a = Assets
        assetsDir: 'public'
        rootURI: '/abc/'
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/abc/test-454d740c0200f454a7e81b3cb06c945f.js'
    it 'multiple assets', ()->
      a = Assets
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

