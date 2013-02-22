config = require 'config'
fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
mime = require 'mime'
mkdirp = require 'mkdirp'
glob = require 'glob'
_ = require 'underscore'

class Assets
  ###*
   * @param options.assetsDir
   * @param options.rootURI
   * @param options.log
  ###
  constructor: (options={})->
    @assetsDir = options.assetsDir || path.join(process.cwd(), 'assets')
    @rootURI = options.rootURI || '/'
    @log = options.log != false
    config.setModuleDefaults('assets', {})
    unless fs.existsSync(@assetsDir)
      mkdirp.sync(@assetsDir)

  handle: (req, res, next) ->
    res.locals
      assets: @
    next()

  _make: (key, filename, options)->
    ext  = path.extname(filename)
    base = path.basename(filename, ext)
    mimetype = options.mimetype || mime.lookup(ext)
    unless fs.existsSync(filename)
      console.error("File '#{filename}' not exists") if @log
      return
    content = fs.readFileSync(filename)
    if mimetype == 'text/css'
      content = @_fixCssUrl(filename, content)
    name = base
    if options.hash != false
      md5 = crypto.createHash('md5').update(content).digest('hex')
      name = "#{name}-#{md5}"
    name = "#{name}#{ext}"  
    dest = path.join @assetsDir, name
    fs.writeFileSync(dest, content)
    #TODO
    #if options.cdn
    url = path.join options.rootURI, name
    config.assets[key] = 
      filename: filename
      path: dest
      mimetype: mimetype
      url: url
      timestamp: Date.now()
    console.info("created asset '#{dest}' for key '#{key}'") if @log

  make: (key, filename, options)->
    if _.isObject(key)
      for _key, opts of key
        @make(_key, opts.file, opts)
      return
    unless filename?
      filename = key
    options = options || {}
    options.assetsDir ?= @assetsDir
    options.rootURI ?= @rootURI
    @_make(key, filename, options)

  dir: (pattern, options={})->
    files = glob.sync pattern,
      cwd: options.baseDir
    for file in files
      @make(file, path.join(options.baseDir, file), options)


  _resolveUrl: (filename, url)->
    url = url.replace(/url\(|'|"|\)/g, '')
    url = path.join(path.dirname(filename), url)
    return @url(url)


  _fixCssUrl: (filename, content)->
    content = content.toString()
    results = content.match /url\([^\)]+\)/g
    if results
      for result in results
        url = @_resolveUrl(filename, result)
        if url != ''
          content = content.replace result, "url('#{url}')"
    return content

  _get: (key)->
    unless config.assets[key]
      console.info("trying to create on-demand asset '#{key}'") if @log
      @make(key)
    asset = config.assets[key]
    return asset if asset?
    console.error("Asset not found, key: '#{key}'") if @log
    return {}

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