fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
mime = require 'mime'
mkdirp = require 'mkdirp'
glob = require 'glob'
_ = require 'underscore'
Store = require './store/Store'

# Regex for detecting & adjusting URLs of fingerprinted/compressed assets referred in .css files
# From https://github.com/icflorescu/aspa/blob/master/lib/aspa.iced#L28
stylesheetAssetUrlPattern = ///
  url\(             # url(
  [\'\"]?           # optional ' or "
  ([^\?\#\'\"\)]+)  # file                                       -> file
  ([^\'\"\)]*)      # optional suffix, i.e. #iefix in font URLs  -> suffix
  [\'\"]?           # optional ' or "
  \)                # )
///gi

class Assets
  ###*
   * @param options.assetsDir
   * @param options.rootURI
   * @param options.logger
   * @param options.store
  ###
  constructor: (options={})->
    @store = options.store || new Store()
    @assetsDir = options.assetsDir || path.join(process.cwd(), 'assets')
    @rootURI = options.rootURI || '/'
    @logger = options.logger
    unless @logger?
      @logger = console
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
      @logger.error("File '#{filename}' not exists") if @logger
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
    asset =
      filename: filename
      path: dest
      mimetype: mimetype
      url: url
      timestamp: new Date().toString()
    @store.set key, asset
    @logger.info("Created asset '#{dest}' for key '#{key}'") if @logger
    return asset

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
    globOptions = {}
    globOptions['cwd'] = options.baseDir if options.baseDir?
    files = glob.sync pattern, globOptions
    prefix = if options.prefix? then options.prefix else ''
    for file in files
      filename = if options.baseDir? then  path.join(options.baseDir, file) else file
      @make("#{prefix}#{file}", filename, options)

  _fixCssUrl: (filenameCSS, content)->
    content = content.toString()
    content = content.replace stylesheetAssetUrlPattern, (src, file, suffix) =>
      #filePath = path.resolve sourceFolder, file
      filePath = path.join(path.dirname(filenameCSS), file)
      url = @url(filePath)
      if url != ''
        "url(\"#{url}#{suffix}\")"
      else
        src
    content

  _get: (key)->
    unless @store.get(key)
      @logger.info("trying to create on-demand asset '#{key}'") if @logeer
      @make(key)
    asset = @store.get(key)
    return asset if asset?
    @logger.error("Asset not found, key: '#{key}'") if @loggger
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

module.exports.Store = Store
module.exports.RedisStore = require './store/RedisStore'