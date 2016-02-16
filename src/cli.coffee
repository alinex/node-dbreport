# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport')
yargs = require 'yargs'
chalk = require 'chalk'
fspath = require 'path'
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
# include classes and helpers
logo = require('./logo') 'Database Reports'
schema = require './configSchema'

process.title = 'DbReport'

# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage("""
  #{logo}
  Usage: $0 [-vCclt] <job...>
  """)
# examples
.example('$0 stats', 'to simply run the stats job')
.example('$0 stats -m info@alinex.de', 'run the job but send to given address')
# general options
.alias('C', 'nocolors')
.describe('C', 'turn of color output')
.boolean('C')
.alias('v', 'verbose')
.describe('v', 'run in verbose mode (multiple makes more verbose)')
.count('verbose')
# change mail address
.alias('m', 'mail')
.describe('m', 'alternative email address to send to')
# general help
.help('h')
.alias('h', 'help')
.epilogue("For more information, look into the man page.")
.showHelpOnFail(false, "Specify --help for available options")
.demand(1)
#.strict()
.fail (err) ->
  console.error """
    #{logo}
    #{chalk.red.bold 'CLI Parameter Failure:'} #{chalk.red err}

    """
  process.exit 1
.argv
# implement some global switches
chalk.enabled = false if argv.nocolors


# Error management
# -------------------------------------------------
exit = (code = 0, err) ->
  # exit without error
  process.exit code unless err
  # exit with error
  console.error chalk.red.bold "FAILED: #{err.message}"
  console.error err.description if err.description
  process.exit code

process.on 'SIGINT', -> exit 130, new Error "Got SIGINT signal"
process.on 'SIGTERM', -> exit 143, new Error "Got SIGTERM signal"
process.on 'SIGHUP', -> exit 129, new Error "Got SIGHUP signal"
process.on 'SIGQUIT', -> exit 131, new Error "Got SIGQUIT signal"
process.on 'SIGABRT', -> exit 134, new Error "Got SIGABRT signal"
process.on 'exit', ->
  console.log "Goodbye\n"
  database.close()


# Run a job
# -------------------------------------------------
run = (name, cb) ->
  conf = config.get "/dbreport/job/#{name}"
  return cb new Error "Job #{name} is not configured" unless conf
  # run the queries
  console.log "-> #{name}"
  debug "start #{name} job"
  async.mapOf conf.query, (query, n, cb) ->
    debug "run query #{n}: #{chalk.grey query.command.replace /\s+/g, ' '}"
    database.list query.database, query.command, (err, data) ->
      return cb err if err
      json2csv
        data: data
        del: ';'
      , cb
  , (err, results) ->
    return cb err if err
    email name, results, cb

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

# Send email
# -------------------------------------------------
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
  setup.subject = setup.subject context if typeof setup.subject is 'function'
  addBody setup, context, ->
    if setup.locale # change locale back
      moment.locale oldLocale
    # add attachements
    setup.attachments = []
    for name, csv of data
      setup.attachments.push
        filename: "#{name}.csv"
        content: csv
    # test mode
    if argv.mail
      setup.to = argv.mail
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


# Main routine
# -------------------------------------------------
console.log logo
console.log "Initializing..."
# init
# add schema for module's configuration
config.setSchema '/dbreport', schema
# set module search path
config.register 'dbreport', fspath.dirname __dirname
# initialize config
database.setup (err) ->
  exit 1, err if err
  config.init (err) ->
    exit 1, err if err
    # start job
    exit 1, new Error "No job given to process" unless argv._.length
    console.log "Run the jobs..."
    async.each argv._, run, (err) ->
      exit 1, err if err
      exit()
