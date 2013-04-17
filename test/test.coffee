Assets = null
assert = require 'assert'
fs = require 'fs'

logger = false

describe 'Assets', ()->

  before (done)->
    configDir = process.cwd() + '/config'
    unless fs.existsSync(configDir)
      fs.mkdirSync(configDir)
    Assets = require('../')
    done()

  describe '#make()', ()->

    it 'single asset without options', ()->
      a = Assets({logger: logger})
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/test-454d740c0200f454a7e81b3cb06c945f.js'

    it 'single asset with options', ()->
      a = Assets
        logger: logger
        assetsDir: 'public'
        rootURI: '/abc/'
      file = 'test/fixtures/test.js'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/abc/test-454d740c0200f454a7e81b3cb06c945f.js'

    it 'multiple assets', ()->
      a = Assets
        logger: logger
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
      a = Assets({logger: logger})
      assert.equal a.tag('asdfgh'), ''
      assert.equal a.url('qwertyu'), ''

    it 'shoul asset images and replase url', ()->
      a = Assets({logger: logger})
      file = 'test/fixtures/bootstrap/css/bootstrap.css'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/bootstrap-a99472f4c79ed11daa3340210c9c206b.css'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.svg'), '/glyphiconshalflings-regular-d482b7e5283a44780b9c47f3276314e9.svg'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.ttf'), '/glyphiconshalflings-regular-fc7ebef874e3a3786aa60d9bc4a75519.ttf'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.woff'), '/glyphiconshalflings-regular-b177def5c9d78ab14562ca652b7bed48.woff'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.eot'), '/glyphiconshalflings-regular-5ed8ce6d7757638311ffdaa820021aae.eot'

    it 'shoul asset images and replase url (min css)', ()->
      a = Assets({logger: logger})
      file = 'test/fixtures/bootstrap/css/bootstrap.min.css'
      a.make(file)
      assert.notEqual a.tag(file), null
      assert.equal a.url(file), '/bootstrap.min-52a6003f439d25a1e5612c92166e94f9.css'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.svg'), '/glyphiconshalflings-regular-d482b7e5283a44780b9c47f3276314e9.svg'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.ttf'), '/glyphiconshalflings-regular-fc7ebef874e3a3786aa60d9bc4a75519.ttf'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.woff'), '/glyphiconshalflings-regular-b177def5c9d78ab14562ca652b7bed48.woff'
      assert.equal a.url('test/fixtures/bootstrap/fonts/glyphiconshalflings-regular.eot'), '/glyphiconshalflings-regular-5ed8ce6d7757638311ffdaa820021aae.eot'

  describe '#dir()', ()->
    it 'should asset directory', ()->
      a = Assets({logger: logger})
      a.dir("test/fixtures/**/*.png")
      assert.notEqual a.url 'test/fixtures/bootstrap/img_old/glyphicons-halflings-white.png', null
      assert.notEqual a.url 'test/fixtures/bootstrap/img_old/glyphicons-halflings.png', null
      assert.notEqual a.url 'test/fixtures/glyphicons-halflings-white.png', null

    it 'key should be without baseDir', ()->
      a = Assets({logger: logger})
      a.dir("fixtures/**/*.png", {baseDir: 'test', prefix: '/'})
      assert.notEqual a.url '/fixtures/bootstrap/img_old/glyphicons-halflings-white.png', null
      assert.notEqual a.url '/fixtures/bootstrap/img_old/glyphicons-halflings.png', null
      assert.notEqual a.url '/fixtures/glyphicons-halflings-white.png', null

  describe 'RedisStore', ()->
    asset = null
    
    it 'single asset', (done)->
      store = new Assets.RedisStore()
      a = Assets
        logger: logger
        store: store
      store.on 'ready', ()->
        file = 'test/fixtures/test.js'
        asset = a.make(file)
        assert.notEqual a.tag(file), null
        assert.equal a.url(file), '/test-454d740c0200f454a7e81b3cb06c945f.js'
        done()

    it 'load single asset', (done)->
      store = new Assets.RedisStore()
      a = Assets
        logger: logger
        store: store
      store.on 'ready', ()->
        file = 'test/fixtures/test.js'
        rasset = a._get(file)
        assert.notEqual rasset, null
        assert.equal rasset.filename, asset.filename
        assert.equal rasset.timestamp, asset.timestamp
        assert.equal rasset.mimetype, asset.mimetype
        assert.equal rasset.url, asset.url
        done()

    it 'single asset with options', (done)->
      store = new Assets.RedisStore()
      a = Assets
        logger: logger
        assetsDir: 'public'
        rootURI: '/abc/'
        store: store
      store.on 'ready', ()->
        file = 'test/fixtures/test.js'
        a.make(file)
        assert.notEqual a.tag(file), null
        assert.equal a.url(file), '/abc/test-454d740c0200f454a7e81b3cb06c945f.js'
        done()

    it 'multiple assets', (done)->
      store = new Assets.RedisStore(null, null, {key: 'other_key'})
      a = Assets
        logger: logger
        assetsDir: 'public'
        rootURI: '/abc/'
        store: store
      store.on 'ready', ()->
        js = 'test/fixtures/test.js'
        css = 'test/fixtures/test.css'
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
        done()

    it 'wrong key', (done)->
      store = new Assets.RedisStore(null, null, {key: 'other_key'})
      a = Assets
        logger: logger
        store: store
      store.on 'ready', ()->
        assert.equal a.tag('asdfgh'), ''
        assert.equal a.url('qwertyu'), ''
        done()


