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
{object} = require 'alinex-util'
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
      return cb err if err
      debug "#{n}: #{data.length} rows fetched"
      return cb() unless data.length # no entries
      # convert dates
      for row in data
        for field, value of row
          row[field] = moment(value).format() if value instanceof Date
      json2csv
        data: data
        del: ';'
      , cb
  , (err, results) ->
    return cb err if err
    email name, results, cb


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

# ### Send email
email = (name, data, cb) ->
  conf = config.get "/dbreport/job/#{name}/email"
  # configure email
  setup = object.clone conf
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
    name: name
    conf: config.get "/dbreport/job/#{name}"
    date: new Date()
    result: {}
  for name, conf of context.conf.query
    context.result[name] =
      rows: data[name]?.split(/\n/).length-1 ? 0
      file: "#{conf.title ? name}.csv"
      description: conf.description
  setup.subject = setup.subject context if typeof setup.subject is 'function'
  addBody setup, context, ->
    if setup.locale # change locale back
      moment.locale oldLocale
    # add attachements
    setup.attachments = []
    for name, csv of data
      continue unless csv # skip empty ones
      setup.attachments.push
        filename: context.result[name].file
        content: csv
    # test mode
    if mode.mail
      setup.to = mode.mail.split /,\s+/
      delete setup.cc
      delete setup.bcc
    # send email
    mails = setup.to?.map (e) -> e.replace /".*?" <(.*?)>/g, '$1'
    debug "sending email to #{mails?.join ', '}..."
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
