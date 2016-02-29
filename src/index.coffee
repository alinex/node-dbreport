# Api to real function
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport')
chalk = require 'chalk'
util = require 'util'
nodemailer = require 'nodemailer'
inlineBase64 = require 'nodemailer-plugin-inline-base64'
json2csv = require 'json2csv'
moment = require 'moment'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
async = require 'alinex-async'
{array, object} = require 'alinex-util'
Report = require 'alinex-report'


# Initialized Data
# -------------------------------------------------
# This will be set on init

# ### General Mode
# This is a collection of base settings which may alter the runtime of the system
# without changing anything in the general configuration. This values may also
# be changed at any time.
mode =
  mail: null # alternative email to use

exports.init = (setup) ->
  mode = setup

# Run a job
# -------------------------------------------------
exports.run = (name, cb) ->
  conf = config.get "/dbreport/job/#{name}"
  return cb new Error "Job #{name} is not configured" unless conf
  # run the queries
  console.log "-> #{name}"
  debug "start #{name} job"
  async.mapOf conf.query, (query, n, cb) ->
    debug chalk.grey "#{n}: run query #{chalk.grey query.command.replace /\s+/g, ' '}"
    database.list query.database, query.command, (err, data) ->
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

# ### Add body to mail setup from report
addBody= (setup, context, cb) ->
  return cb() unless setup.body
  report = new Report
    source: setup.body context
  report.toHtml
    inlineCss: true
    locale: setup.locale
  , (err, html) ->
    setup.text = report.toText()
    setup.html = html
    delete setup.body
    cb err

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
      list[name].csv = string
      cb()
  , (err) ->
    return cb err if err
    # send email
    email meta, list, cb

# ### Send email
email = (meta, list, cb) ->
  # configure email
  setup = object.clone meta.conf.email
  debug chalk.grey "#{meta.job}: building email"
  # use base settings
  while setup.base
    base = config.get "/dbreport/email/#{setup.base}"
    delete setup.base
    setup = object.extend {}, base, setup
  # support handlebars
  if setup.locale # change locale
    oldLocale = moment.locale()
    moment.locale setup.locale
  context =
    name: meta.job
    conf: meta.conf
    date: new Date()
    result: list
  setup.subject = setup.subject context if typeof setup.subject is 'function'
  addBody setup, context, ->
    if setup.locale # change locale back
      moment.locale oldLocale
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
      delete setup.cc
      delete setup.bcc
    # send email
    mails = setup.to?.map (e) -> e.replace /".*?" <(.*?)>/g, '$1'
    debug chalk.grey "#{meta.job}: sending email to #{mails?.join ', '}..."
    # setup transporter
    transporter = nodemailer.createTransport setup.transport ? 'direct:?name=hostname'
    transporter.use 'compile', inlineBase64
    debug chalk.grey "using #{transporter.transporter.name}"
    # try to send email
    transporter.sendMail setup, (err, info) ->
      if err
        if err.errors
          debug chalk.red e.message for e in err.errors
        else
          debug chalk.red err.message
        debug chalk.grey "send through " + util.inspect setup.transport
      if info
        debug "message send: " + chalk.grey util.inspect(info).replace /\s+/, ''
        return cb new Error "Some messages were rejected: #{info.response}" if info.rejected?.length
      cb err?.errors?[0] ? err ? null
