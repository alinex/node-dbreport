# Compose data
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport:compose')
chalk = require 'chalk'
async = require 'async'
moment = require 'moment'
iconv = require 'iconv-lite'
# include alinex modules
Table = require 'alinex-table'
format = require 'alinex-format'
util = require 'alinex-util'
Report = require 'alinex-report'


# Main Method Composing Data
# -------------------------------------------------

module.exports = (meta, results, cb) ->
  # make data files
  debug chalk.grey "#{meta.job}: read setup"
  list = {}
  unless meta.conf.compose
    for name, setup of meta.conf.query
      list[name] =
        table: results[name]
        title: setup.title
        description: setup.description
  else
    debug chalk.grey "#{meta.job}: composing"

    for name, setup of meta.conf.compose
      list[name] = util.extend util.clone(setup),
        table: []
      switch
        when setup.append
          debug chalk.grey "#{meta.job}.#{name}: append"
          # transform to list
          setup.append = Object.keys meta.conf.query if typeof setup.append is 'boolean'
          # append to new list
          list[name].table = table = new Table()
          for alias in setup.append
            table.append results[alias]
        when setup.join
          debug chalk.grey "#{meta.job}.#{name}: join"
          # transform to object
          setup.join = Object.keys meta.conf.query if typeof setup.join is 'boolean'
          if Array.isArray setup.join
            setup.join = {}
            setup.join[k] = 'left' for k in setup.join
          # join to new list
          list[name].table = table = new Table()
          for alias, type of setup.join
            if type is 'append'
              table.append results[alias]
            else
              table.join type, results[alias]
        when results[name]?
          list[name].table = results[name]
        else
          return cb new Error "No supported compose method (append/join) defined for entry #{name}
          of #{meta.job}."
  # work on each file
  for name, file of list
    unless file.table.data.length
      file.rows = 0
      continue
    # optimize table
    if file.sort
      debug chalk.grey "#{meta.job}.#{name}: sort by #{file.sort}"
      file.table.sort file.sort
    if file.reverse
      debug chalk.grey "#{meta.job}.#{name}: reverse"
      file.table.reverse()
    if file.fields
      debug chalk.grey "#{meta.job}.#{name}: filter columns #{file.fields}"
      cols = {}
      cols[k] = k for k in file.fields
      file.table.columns cols
    if file.format
      debug chalk.grey "#{meta.job}.#{name}: format columns"
      file.table.format file.format
    if file.unique
      debug chalk.grey "#{meta.job}.#{name}: unique"
      file.table.unique()
    if file.flip
      debug chalk.grey "#{meta.job}.#{name}: flip"
      file.table.flip()
    # update file info
    file.rows = file.table.data.length ? 0
  # create report context
  context =
    name: meta.job
    conf: meta.conf
    variables: util.object.filter meta.variables, (_, key) -> key[0] isnt '_'
    date: new Date()
    result: list
  # generate output data files
  out = []
  async.parallel [
    (cb) -> data2csv meta, out, list, cb
    (cb) -> data2pdf meta, out, list, context, cb
  ], (err) ->
    return cb err if err
    context.attachments = out
    cb null, list, out, context


# Data Transformation to Files
# -------------------------------------------------

data2csv = (meta, out, list, cb) ->
  # return if set to false
  return cb() if meta.conf.csv? and not meta.conf.csv
  csvlist = if meta.conf.csv and typeof meta.conf.csv isnt 'boolean' then meta.conf.csv
  else Object.keys list
  async.each csvlist, (name, cb) ->
    return cb() if Array.isArray meta.conf.csv and name not in meta.conf.csv
    file = list[name]
    return cb() unless file.table.data.length
    debug chalk.grey "#{meta.job}.#{name}: convert to csv"
    format.stringify file.table, 'csv', (err, csv) ->
      console.log csv
      return cb err if err
      out.push
        type: 'csv'
        filename: "#{file.title ? name}.csv"
        description: file.description
        content: iconv.encode csv, 'windows1252'
        rows: file.rows
      file.file = "#{file.title ? name}.csv"
      cb()
  , cb

data2pdf = (meta, out, list, context, cb) ->
  # return if set to false
  return cb() unless meta.conf.pdf
  async.forEachOf meta.conf.pdf, (pdf, name, cb) ->
    return cb() if Array.isArray meta.conf.pdf and name not in meta.conf.pdf
    debug chalk.grey "#{meta.job}.#{name}: convert to pdf"
    if pdf.locale # change locale
      oldLocale = moment.locale()
      moment.locale pdf.locale
    report = new Report
      source: pdf.content context
    if pdf.locale # change locale back
      moment.locale oldLocale
    report.toPdf
      format: meta.job.format
      orientation: meta.job.orientation
    , (err, data) ->
      return cb err if err
      out.push
        type: 'pdf'
        filename: "#{pdf.title ? name}.pdf"
        description: pdf.description
        content: data
      cb()
  , cb
