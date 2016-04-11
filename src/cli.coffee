# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
yargs = require 'yargs'
chalk = require 'chalk'
fspath = require 'path'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
async = require 'alinex-async'
Report = require 'alinex-report'
mail = require 'alinex-mail'
# include classes and helpers
dbreport = require './index'
logo = require('alinex-core').logo 'Database Reports'
schema = require './configSchema'

process.title = 'DbReport'


# Support quiet mode through switch
# -------------------------------------------------
quiet = false
for a in ['--get-yargs-completions', 'bashrc', '-q', '--quiet']
  quiet = true if a in process.argv


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
  console.log "Goodbye\n" unless quiet
  database.close()


# Main routine
# -------------------------------------------------
unless quiet
  console.log logo
  console.log "Initializing..."


# Start argument parsing
# -------------------------------------------------
yargs
.usage "\nUsage: $0 [-Chml] <job...>"
.env 'DBREPORT' # use environment arguments prefixed with DBREPORT_
# examples
.example '$0 stats', 'to simply run the stats job'
.example '$0 stats -m info@alinex.de', 'run the job but send to given address'
# general options
.options
  help:
    alias: 'h',
    description: 'display help message'
  nocolors:
    alias: 'C'
    description: 'turn of color output'
    type: 'boolean'
  quiet:
    alias: 'q'
    describe: "don't output header and footer"
    type: 'boolean'
  list:
    alias: 'l'
    description: 'only list the possible jobs'
    type: 'boolean'
  mail:
    alias: 'm'
    description: 'alternative email address to send to'
    type: 'string'
  json:
    alias: 'j'
    description: 'json formatted data object'
    type: 'string'
.group ['m', 'j'], 'Report Options:'
# general help
.help 'help'
.updateStrings
  'Options:': 'General Options:'
.epilogue """
  You may use environment variables prefixed with 'DBREPORT_' to set any of
  the options like 'DBREPORT_MAIL' to set the email address.

  For more information, look into the man page.
  """
.completion 'bashrc-script', false
# validation
#.strict()
.fail (err) ->
  err = new Error "CLI #{err}"
  err.description = 'Specify --help for available options'
  exit 1, err
# now parse the arguments
args = yargs.argv
# refine yargs and rerun if option needs command
unless args.list
  yargs.demand 1, "Needs a report name to run."
  args = yargs.argv

# implement some global switches
chalk.enabled = false if args.nocolors



# Main routine
# -------------------------------------------------
# init
if args.json
  try
    variables = JSON.parse args.json
  catch error
    exit 255, error
dbreport.init
  mail: args.mail
  variables: variables ? {}
# add schema for module's configuration
config.setSchema '/dbreport', schema
# set module search path
config.register 'dbreport', fspath.dirname __dirname
# initialize config
mail.setup (err) ->
  exit 1, err if err
  database.setup (err) ->
    exit 1, err if err
    config.init (err) ->
      exit 1, err if err
      # show List
      if args.list
        data = []
        for job in dbreport.list()
          conf = dbreport.get job
          data.push
            job: job
            title: conf.title
            to: conf.email.to?.map (e) -> e.replace /[ .@].*/, ''
            .join ', '
        report = new Report()
        report.h1 "List of possible jobs:"
        report.table data, ['JOB', 'TITLE', 'TO']
        report.p 'Run them using their job name.'
        console.log()
        console.log report.toConsole()
        console.log()
        exit()
      # start job
      exit 1, new Error "No job given to process" unless args._.length
      console.log "Run the jobs..."
      async.each args._, dbreport.run, (err) ->
        exit 1, err if err
        exit()
