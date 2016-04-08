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
    if variables.length
      console.log "-> #{name}", chalk.grey "with " + util.inspect(variables).replace /\n/g, ' '
    else
      console.log "-> #{name}"
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
        variables: variables
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
  else
    debug chalk.grey "#{meta.job}: composing"
    for name, setup of meta.conf.compose
      list[name] = object.extend {}, setup,
        data: []
      switch
        when setup.append
          setup.append = Object.keys meta.conf.query if typeof setup.append is 'boolean'
          for alias in setup.append
            list[name].data = list[name].data.concat results[alias]
        else
          return cb new Error "No supported combine method defined for entry #{name}
          of #{meta.job}."
  # optimize lists
  for name, file of list
    # sort lists
    if file.sort
      debug chalk.grey "#{meta.job}.#{name}: sort by #{file.sort}"
      sorter = [file.data].concat file.sort
      file.data = array.sortBy.apply this, sorter
    if file.reverse
      debug chalk.grey "#{meta.job}.#{name}: reverse"
      file.data.reverse()
    # filter fields
    if file.fields
      debug chalk.grey "#{meta.job}.#{name}: filter fields"
      for row in file.data
        for col in Object.keys row
          delete row[col] unless col in file.fields
    # unique lists
    if file.unique
      debug chalk.grey "#{meta.job}.#{name}: unique records"
      file.data = array.unique file.data
    # flip x/y axes
    if file.flip and file.data.length
      debug chalk.grey "#{meta.job}.#{name}: flip x/y axes"
      # convert to array table
      tab = []
      header = Object.keys file.data[0]
      for row, rnum in file.data
        tab[rnum] = []
        for col, cnum in header
          tab[rnum][cnum] = file.data[rnum][col]
      tab.unshift header
      # flip
      flipped = []
      for row, x in tab
        for col, y in row
          flipped[y] ?= []
          flipped[y][x] = col
      # convert to objects
      file.data = []
      for row, x in flipped[1..]
        for col, y in row
          file.data[x] ?= {}
          file.data[x][flipped[0][y]] = col
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
    if meta.conf.csv
      setup.attachments = []
      names = if typeof meta.conf.csv is 'string' then meta.conf.csv else Object.keys list
      for name in names
        data = list[name]
        continue unless data.csv
        setup.attachments.push
          filename: data.file
          content: data.csv
    # generate context sensitive part
    context =
      name: meta.job
      conf: meta.conf
      variables: object.filter meta.variables, (_, key) -> key[0] isnt '_'
      date: new Date()
      result: list
      attachments: setup.attachments
    addPdf meta.job, meta.conf.pdf, context, setup, (err) ->
      return cb err if err
      # test mode
      setup = mail.resolve setup
      if mode.mail
        setup.to = mode.mail.split /,\s+/
        setup.cc = []
        setup.bcc = []
      if mmeta = mode.variables?._mail?.header
        setup.cc = mmeta.cc
        setup.bcc = mmeta.bcc
        setup.subject = "Re: #{mmeta.subject}" if mmeta.subject
        if mmeta.messageId
          setup.inReplyTo = mmeta.messageId
          setup.references = [mmeta.messageId]
      mail.send setup, context, (err) ->
        console.log chalk.grey "Email was send." unless err
        cb err

addPdf = (job, conf, context, email, cb) ->
  return cb() unless conf
  debug chalk.grey "#{job}: attache pdfs"
  async.forEachOf conf, (pdf, name, cb) ->
    if pdf.locale # change locale
      oldLocale = moment.locale()
      moment.locale pdf.locale
    report = new Report
      source: pdf.content context
    if pdf.locale # change locale back
      moment.locale oldLocale
    report.toPdf
      format: job.format
      orientation: job.orientation
    , (err, data) ->
      return cb err if err
      email.attachments ?= []
      email.attachments.push
        filename: "#{pdf.title ? name}.pdf"
        content: data
      cb()
  , (err) ->
    cb err
