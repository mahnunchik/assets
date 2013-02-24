###*
 * Just a memory store
###
class Store
  constructor: ()->
    @assets = {}

  set: (key, asset)->
    @assets[key] = asset

  get: (key)->
    return @assets[key]

module.exports = Store