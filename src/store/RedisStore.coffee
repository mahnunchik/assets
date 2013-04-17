redis = require "redis"
EventEmitter = require('events').EventEmitter

###*
 * Redis store
 * https://github.com/mranney/node_redis
###
class RedisStore extends EventEmitter
  ###*
   * @param options.key - basic key to store assets
  ###
  constructor: (port, host, options={})->
    @assetsKey = options.key || 'redis_assets'
    @logger = options.logger
    unless @logger?
      @logger = console
    @assets = {}
    @redis = redis.createClient(port, host, options)
    @notify = redis.createClient(port, host, options)
    @notify.subscribe(options.redis_assets_channel || 'redis_assets_channel')
    @notify.on "message", (channel, key)=>
      if key == "all"
        @_update()
      else
        @redis.hget @assetsKey, key, (err, asset)=>
          return @logger.error("Error hget", err) if err? and @logger?
          @_parse(key, asset)
    @_update()

  _update: ()->
    @redis.hgetall @assetsKey, (err, assets)=>
      if err?
        @logger.error("Error hgetall", err) if err? and @logger?
        @emit 'error', err
        return
      for key, asset of assets
        @_parse(key, asset)
      @emit 'ready'

  _parse: (key, asset)->
    try
      @assets[key] = JSON.parse(asset)
    catch err
      @logger.error("Error JSON.parse", err) if @logger?

  set: (key, asset)->
    @assets[key] = asset
    @redis.hset @assetsKey, key, JSON.stringify(asset), (err)=>
      return @logger.error("Error JSON.hset", err) if err? and @logger?

  get: (key)->
    return @assets[key]

  destroy: (key)->
    @redis.hdel @assetsKey, key, (err)=>
      return @logger.error("Error JSON.hdel", err) if err? and @logger?
      delete @assets[key]

module.exports = RedisStore