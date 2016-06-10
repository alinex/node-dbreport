# Main class
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
yargs = require 'yargs'
chalk = require 'chalk'
async = require 'async'
fspath = require 'path'
# include alinex modules
config = require 'alinex-config'
database = require 'alinex-database'
Report = require 'alinex-report'
mail = require 'alinex-mail'
alinex = require 'alinex-core'
# include classes and helpers
dbreport = require './index'

process.title = 'DbReport'
logo = alinex.logo 'Database Reports'


# Support quiet mode through switch
# -------------------------------------------------
quiet = false
for a in ['--get-yargs-completions', 'bashrc', '-q', '--quiet']
  quiet = true if a in process.argv


# Error management
# -------------------------------------------------
alinex.initExit()
process.on 'exit', ->
  console.log "Goodbye\n"
  database.close()


# Command Setup
# -------------------------------------------------
command = (name, conf) ->
  # return builder and handler
  builder: (yargs) ->
    yargs
    .usage "\nUsage: $0 #{name} [options]\n\n#{conf.description ? ''}"
#    # add options
#    if lib.options
#      yargs.option key, def for key, def of lib.options
#      yargs.group Object.keys(lib.options), "#{util.string.ucFirst name} Command Options:"
    # help
    yargs.strict()
    .help 'h'
    .alias 'h', 'help'
    .epilogue """
      This is the description of the '#{name}' job. You may also look into the
      general help or the man page.
      """
  handler: (argv) ->
    if argv.json
      try
        variables = JSON.parse argv.json
      catch error
        alinex.exit 2, error
    dbreport.init
      mail: argv.mail
      variables: variables ? {}
    # run the command
    dbreport.run name, (err) ->
      alinex.exit err if err
    return true


# Main routine
# -------------------------------------------------
unless quiet
  console.log logo
  console.log "Initializing..."

dbreport.setup (err) ->
  alinex.exit 16, err if err
  config.init (err) ->
    alinex.exit err if err
    yargs
    .usage "\nUsage: $0 <job...> [options]"
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
    # add Commands
    for job in dbreport.list()
      conf = dbreport.get job
      yargs.command job, conf.title, command job, conf
    # general help
    yargs.help 'help'
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
      alinex.exit 2, err
    # now parse the arguments
    argv = yargs.argv
    # list possible jobs
    if argv.list
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
    # check for corrct call
    else unless argv._.length
      alinex.exit 2, new Error "Nothing to do specify --help for available options"
