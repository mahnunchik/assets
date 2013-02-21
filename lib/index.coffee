config = require 'config'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
mime = require 'mime'
mkdirp = require 'mkdirp'

class Assets
  constructor: (@options={})->
    @assetsDir = @options.assetsDir || path.join(process.cwd(), 'assets')
    @rootURI = @options.rootURI || '/'
    config.assets = {} unless config.assets?
    unless fs.existsSync(@assetsDir)
      mkdirp.sync(@assetsDir)

  _make: (key, filename, options)->
    ext  = path.extname(filename)
    base = path.basename(filename, ext)
    mimetype = options.mimetype || mime.lookup(ext)
    unless fs.existsSync(filename)
      return
    content = fs.readFileSync(filename)
    name = base
    if options.hash != false
      md5 = crypto.createHash('md5').update(content).digest('hex')
      name = "#{name}-#{md5}"
    name = "#{name}#{ext}"  
    dest = path.join @assetsDir, name
    fs.writeFileSync(dest, fs.readFileSync(filename))
    #TODO
    #if options.cdn
    url = path.join options.rootURI, name
    config.assets[key] = 
      path: dest
      mimetype: mimetype
      url: url
      timestamp: Date.now()

  make: (key, filename, options)->
    unless filename?
      filename = key
    options = options || {}
    options.assetsDir ?= @assetsDir
    options.rootURI ?= @rootURI
    @_make(key, filename, options)

  _get: (key)->
    unless config.assets[key]
      @make(key)
    return config.assets[key] || {}
  url: (key)->
    return @_get(key).url || ''

  tag: (key)->
    asset = @_get(key)
    switch asset.mimetype
      when 'text/javascript', 'application/javascript'
        return "\n<script type=\"#{asset.mimetype}\" src=\"#{asset.url}\"></script>"
      when 'text/css'
         return "\n<link rel=\"stylesheet\" href=\"#{asset.url}\">"
      else
        return asset.url || ''

module.exports = (options)->
  return new Assets(options)