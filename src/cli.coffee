# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('cli')
yargs = require 'yargs'
chalk = require 'chalk'
fspath = require 'path'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
async = require 'alinex-async'
# include classes and helpers
dbreport = require './index'
logo = require('./logo') 'Database Reports'
schema = require './configSchema'

process.title = 'DbReport'

# Start argument parsing
# -------------------------------------------------
argv = yargs
.usage """
  #{logo}
  Usage: $0 [-Cmdh] <job...>
  """
# examples
.example '$0 stats', 'to simply run the stats job'
.example '$0 stats -m info@alinex.de', 'run the job but send to given address'
# general options
.alias 'C', 'nocolors'
.describe 'C', 'turn of color output'
.boolean 'C'
# change mail address
.alias 'm', 'mail'
.describe 'm', 'alternative email address to send to'
# change mail address
.alias 'd', 'daemon'
.boolean 'd'
.describe 'd', 'run in daemon mode (waiting for commands)'
# general help
.help 'h'
.alias 'h', 'help'
.epilogue "For more information, look into the man page."
.showHelpOnFail false, "Specify --help for available options"
.demand 1
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


# Main routine
# -------------------------------------------------
console.log logo
console.log "Initializing..."
# init
dbreport.init
  mail: argv.mail
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
    async.each argv._, dbreport.run, (err) ->
      exit 1, err if err
      exit()
