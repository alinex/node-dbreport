# Api to real function
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport')
chalk = require 'chalk'
async = require 'async'
fspath = require 'path'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
util = require 'alinex-util'
mail = require 'alinex-mail'
validator = require 'alinex-validator'
# internal methods
compose = require './compose'
schema = require './configSchema'


# Initialized Data
# -------------------------------------------------
# This will be set on init

# ### General Mode
# This is a collection of base settings which may alter the runtime of the system
# without changing anything in the general configuration. This values may also
# be changed at any time.
mode =
  mail: null # alternative email to use
  variables: {} # list of additional command variables

exports.setup = (cb) ->
  async.each [mail, database], (mod, cb) ->
    mod.setup cb
  , (err) ->
    return cb err if err
    # add schema for module's configuration
    config.setSchema '/dbreport', schema
    # set module search path
    config.register 'dbreport', fspath.dirname __dirname
    cb()

exports.init = (setup) ->
  mode = setup

# Run a job
# -------------------------------------------------
exports.run = (name, cb) ->
  console.log "Run the #{name} job."
  conf = config.get "/dbreport/job/#{name}"
  return cb new Error "Job #{name} is not configured" unless conf
  # validate variables
  validator.check
    name: 'cli-variables'
    value: mode.variables
    schema:
      type: 'object'
      allowedKeys: true
      mandatoryKeys: true
      keys: util.extend
        _mail:
          type: 'object'
          optional: true
      , conf.variables
  , (err, variables) ->
    return cb err if err
    # run the queries
    if variables.length
      console.log "-> #{name}", chalk.grey "with " + util.inspect(variables).replace /\n/g, ' '
    else
      console.log "-> #{name}"
    debug "start #{name} job"
    keys = Object.keys conf.query
    async.map keys, (n, cb) ->
      query = conf.query[n]
      debug chalk.grey "#{n}: run query #{chalk.grey query.command(variables).replace /\s+/g, ' '}"
      database.list query.database, query.command(variables), (err, data) ->
        debug "#{n}: #{data?.length} rows fetched"
        cb err, data
    , (err, results) ->
      return cb err if err
      # combine the results into an object again
      map = {}
      map[keys[num]] = results[num] for num in [0..keys.length-1]
      results = map
      # check for sending
      isEmpty = true
      for query, data of results
        continue unless data.length
        isEmpty = false
        break
      if isEmpty
        debug "#{name}: no data found"
        return cb() unless conf.sendEmpty
      # build data tables out of results
      compose
        job: name
        conf: conf
        variables: variables
        isEmpty: isEmpty
      , results, (err, list, attachments, context) ->
        return cb err if err
        # create email
        email = mail.resolve util.clone conf.email
        email.attachments = attachments
        if mode.mail
          email.to = mode.mail.split /,\s+/
          email.cc = []
          email.bcc = []
        if mmeta = mode.variables?._mail?.header
          email.cc = mmeta.cc
          email.bcc = mmeta.bcc
          email.subject = "Re: #{mmeta.subject}" if mmeta.subject
          if mmeta.messageId
            email.inReplyTo = mmeta.messageId
            email.references = [mmeta.messageId]
        mail.send email, context, (err) ->
          console.log chalk.grey "Email was send." unless err
          cb err


# List possible jobs
# -------------------------------------------------
exports.list = ->
  Object.keys config.get("/dbreport/job") ? {}


# Get the job configuration
# -------------------------------------------------
exports.get = (name) ->
  config.get "/dbreport/job/#{name}"
