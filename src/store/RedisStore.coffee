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
    @assetsChannel = options.redis_assets_channel || 'redis_assets_channel'
    @logger = options.logger
    unless @logger?
      @logger = console
    @assets = {}
    @redis = redis.createClient(port, host, options)
    @notify = redis.createClient(port, host, options)
    @notify.subscribe(@assetsChannel)
    @notify.on "message", (channel, key)=>
      @_update()
    @_update()

  _update: ()->
    @redis.hgetall @assetsKey, (err, assets)=>
      if err?
        @logger.error("Error hgetall", err) if err? and @logger?
        @emit 'error', err
        return
      for key, asset of assets
        try
          @assets[key] = JSON.parse(asset)
        catch err
          @logger.error("Error JSON.parse", err) if @logger?
      @emit 'ready'
    
  set: (key, asset)->
    @assets[key] = asset
    @redis.hset @assetsKey, key, JSON.stringify(asset), (err)=>
      return @logger.error("Error JSON.hset", err) if err? and @logger?
      @redis.publish(@assetsChannel, process.pid)

  get: (key)->
    return @assets[key]

  destroy: (key, cb)->
    @redis.hdel @assetsKey, key, (err)=>
      if err? and @logger?
        @logger.error("Error JSON.hdel", err) 
      else
        delete @assets[key]
      cb(err) if cb?


module.exports = RedisStore