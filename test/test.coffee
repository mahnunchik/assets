assets = require('../')()

assets.make('css', 'test/fixtures/test.css', {rootURI: 'abs'})

console.log 'tag:', assets.tag('css')
console.log 'url:', assets.url('css')