# Api to real function
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport')
chalk = require 'chalk'
util = require 'util'
json2csv = require 'json2csv'
moment = require 'moment'
iconv = require 'iconv-lite'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
async = require 'alinex-async'
{array, object} = require 'alinex-util'
mail = require 'alinex-mail'
validator = require 'alinex-validator'


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

exports.init = (setup) ->
  mode = setup

# Run a job
# -------------------------------------------------
exports.run = (name, cb) ->
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
      keys: object.extend
        _mail:
          type: 'object'
          optional: true
      , conf.variables
  , (err, variables) ->
    return cb err if err
    # run the queries
    console.log "-> #{name} with", chalk.grey util.inspect(variables).replace /\n/g, ' '
    debug "start #{name} job"
    async.mapOf conf.query, (query, n, cb) ->
      debug chalk.grey "#{n}: run query #{chalk.grey query.command(variables).replace /\s+/g, ' '}"
      database.list query.database, query.command(variables), (err, data) ->
        debug "#{n}: #{data?.length} rows fetched"
        cb err, data
    , (err, results) ->
      return cb err if err
      # check for sending
      isEmpty = true
      for query, data of results
        continue unless data.length
        isEmpty = false
        break
      if isEmpty
        debug "#{name}: no data found"
        return cb() unless conf.sendEmpty
      # build results
      compose
        job: name
        conf: conf
        isEmpty: isEmpty
      , results, cb


# List possible jobs
# -------------------------------------------------
exports.list = ->
  Object.keys config.get "/dbreport/job"


# Get the job configuration
# -------------------------------------------------
exports.get = (name) ->
  config.get "/dbreport/job/#{name}"


# Helper
# -------------------------------------------------

# ### Make output objects
compose = (meta, results, cb) ->
  # make data files
  list = {}
  unless meta.conf.compose
    for name, setup of meta.conf.query
      list[name] =
        data: results[name]
        title: setup.title
        description: setup.description
        sort: setup.sort
  else
    debug chalk.grey "#{meta.job}: composing"
    for name, setup of meta.conf.compose
      list[name] =
        data: []
        title: setup.title
        description: setup.description
        sort: setup.sort
      switch
        when setup.append
          setup.append = Object.keys meta.conf.query if typeof setup.append is 'boolean'
          for alias in setup.append
            list[name].data = list[name].data.concat results[alias]
        else
          return cb new Error "No supported combine method defined for entry #{name}
          of #{meta.job}."
  # sort lists
  for name, file of list
    continue unless file.sort
    debug chalk.grey "#{meta.job}.#{name}: sort by #{file.sort}"
    sorter = [file.data].concat file.sort
    file.data = array.sortBy.apply this, sorter
  # add some meta information
  debug chalk.grey "#{meta.job}: convert to csv"
  for name, file of list
    file.rows = file.data.length
    file.file = "#{file.title ? name}.csv"
  # generate csv
  async.each Object.keys(list), (name, cb) ->
    return cb() unless list[name].data.length
    # optimize structure
    first = list[name].data[0]
    for row in list[name].data
      for field, value of row
        # add missing fields
        first[field] ?= null
        # convert dates
        row[field] = moment(value).format() if value instanceof Date
    json2csv
      data: list[name].data
      del: ';'
    , (err, string) ->
      return cb err if err
      list[name].csv = iconv.encode string, 'windows1252'
      cb()
  , (err) ->
    return cb err if err
    # send email
    #email meta, list, cb
    setup = object.clone meta.conf.email
    # add attachements
    setup.attachments = []
    for name, data of list
      continue unless data.csv # skip empty ones
      setup.attachments.push
        filename: data.file
        content: data.csv
    # test mode
    if mode.mail
      setup.to = mode.mail.split /,\s+/
      setup.cc = []
      setup.bcc = []
    mail.send setup,
      name: meta.job
      conf: meta.conf
      date: new Date()
      result: list
    , cb
