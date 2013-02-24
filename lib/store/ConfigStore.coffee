config = require 'config'
_ = require 'underscore'
###*
 * Config store
 * https://github.com/lorenwest/node-config
###
class ConfigStore
  ###*
   * @param options.key - basic config key to store assets
  ###
  constructor: (options={})->
    @assetsKey = options.key || 'assets'
    config.setModuleDefaults(@assetsKey, {})

  ###*
   * Dirty hack...
  ###
  set: (key, asset)->
    tmp = _.clone(config[@assetsKey])
    tmp[key] = asset
    config[@assetsKey] = tmp

  get: (key)->
    return config[@assetsKey][key]

module.exports = ConfigStore