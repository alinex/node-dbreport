# Compose data
# =================================================

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('dbreport:compose')
chalk = require 'chalk'
async = require 'async'
json2csv = require 'json2csv'
moment = require 'moment'
iconv = require 'iconv-lite'
# include alinex modules
format = require 'alinex-format'
table = require 'alinex-table'
util = require 'alinex-util'
validator = require 'alinex-validator'
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
        data: results[name]
        title: setup.title
        description: setup.description
  else
    debug chalk.grey "#{meta.job}: composing"
    for name, setup of meta.conf.compose
      list[name] = util.extend util.clone(setup),
        data: []
      switch
        when setup.append
          setup.append = Object.keys meta.conf.query if typeof setup.append is 'boolean'
          debug chalk.grey "#{meta.job}.#{name}: append"
          for alias in setup.append
#            console.log results[alias]
            #raw = object.clone results[alias]
            raw = []
            for e in results[alias]
              n = {}
              n[k] = v for k, v of e
              raw.push n
#            console.log raw
#            console.log raw is results[alias]
#            console.log raw[0] is results[alias][0]
#            cl = object.clone results[alias]
            cl = []
            for e in results[alias]
              cl.push util.clone e
#            console.log cl
#            console.log cl is results[alias]
#            console.log cl[0] is results[alias][0]
#            process.exit 1
            list[name].data = list[name].data.concat cl
        when setup.join
          debug chalk.grey "#{meta.job}.#{name}: join"
          doJoin results, list[name]
        when results[name]?
          list[name].data = results[name]
        else
          return cb new Error "No supported compose method (append/join) defined for entry #{name}
          of #{meta.job}."
#  list.table.data[0].anzahl = 999999
  # work on each file
  async.each Object.keys(list), (name, cb) ->
    file = list[name]
    unless file.data.length
      file.rows = 0
      return cb()
    # optimize data
    async.eachSeries [
      sort
      reverse
      fields
      fieldformat
      unique
      flip
    ], (method, cb) ->
      method.call this, meta, name, file, cb
    , (err) ->
      # update file info
      file.rows = file.data.length ? 0
      cb err
  , (err) ->
    return cb err if err
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


# Join helpers
# -------------------------------------------------

doJoin = (results, list) ->
  # get join conditions
  join = {}
  if typeof list.join is 'boolean'
    for entry in Object.keys results
      join[entry] = 'inner'
    list.join = join
  else if Array.isArray list.join
    for entry in list.join
      join[entry] = 'inner'
    list.join = join
  # start joining
  for alias, join of list.join
    # go on if empty
    continue unless results[alias].length
    # add if first record set
    unless list.data?.length
      list.data = results[alias]
      continue
    # append
    if join is 'append'
      list.data = list.data.concat results[alias]
      continue
    # find equal field names
    cols = Object.keys list.data[0]
    .filter (e) -> results[alias][0][e]
    # switch for right join
    if join is 'right'
      r = list.data
      l = results[alias]
    else
      l = list.data
      r = results[alias]
    # join
    all = []
    for lr in l
      found = false
      for rr in r
        continue unless matchCols cols, lr, rr
        all.push addCols lr, rr unless join is 'outer'
        found = true
      unless found or join is 'inner'
        e = {}
        e[n] = null for n of r[0]
        all.push addCols lr, e
    if join is 'outer'
      for rr in r
        found = false
        for lr in l
          continue unless matchCols cols, rr, lr
          found = true
        unless found or join is 'inner'
          e = {}
          e[n] = null for n of l[0]
          all.push addCols rr, e
    list.data = all

matchCols = (cols, l, r) ->
  for c in cols
    return false unless l[c] is r[c]
  return true
addCols = (l, r) ->
  l[n] = v ? l[n] ? null for n, v of r
  l


# Composing Methods
# -------------------------------------------------

# sort lists
sort = (meta, name, file, cb) ->
  return cb() unless file.sort
  debug chalk.grey "#{meta.job}.#{name}: sort by #{file.sort}"
  sorter = [file.data].concat file.sort
  file.data = util.array.sortBy.apply this, sorter
  cb()

reverse = (meta, name, file, cb) ->
  return cb() unless file.reverse
  debug chalk.grey "#{meta.job}.#{name}: reverse"
  file.data.reverse()
  cb()

# filter fields
fields = (meta, name, file, cb) ->
  return cb() unless file.fields
  debug chalk.grey "#{meta.job}.#{name}: filter fields"
  for row in file.data
    for col in Object.keys row
      delete row[col] unless col in file.fields
  # reorder first record columns
  head = {}
  head[col] = file.data[0][col] for col in file.fields
  file.data[0] = head
  cb()

# format
fieldformat = (meta, name, file, cb) ->
  return cb() unless file.format
  debug chalk.grey "#{meta.job}.#{name}: format columns"
  async.each file.data, (row, cb) ->
    async.each Object.keys(row), (col, cb) ->
      return cb() unless file.format[col]
      validator.check
        name: "format-cell"
        value: row[col]
        schema: file.format[col]
      , (err, result) ->
        row[col] = result
        cb()
    , cb
  , (err) ->
    return cb err if err
    cb()

# unique lists
unique = (meta, name, file, cb) ->
  return cb() unless file.unique
  debug chalk.grey "#{meta.job}.#{name}: unique records"
  file.data = util.array.unique file.data
  cb()

# flip x/y axes
flip = (meta, name, file, cb) ->
  return cb() unless file.flip
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


# Data Transformation to Files
# -------------------------------------------------

data2csv = (meta, out, list, cb) ->
  # return if set to false
  return cb() if meta.conf.csv? and not meta.conf.csv
  csvlist = if meta.conf.csv and typeof meta.conf.csv isnt 'boolean' then meta.conf.csv
  else Object.keys list
  async.each csvlist, (name, cb) ->
    return cb() if Array.isArray meta.conf.csv and name not in meta.conf.csv
    debug chalk.grey "#{meta.job}.#{name}: convert to csv"
    file = list[name]
    return cb() unless file.data.length
    # optimize structure
    first = file.data[0]
    for row in file.data
      for field of row
        # add missing fields
        first[field] ?= null
    json2csv
      data: file.data
      del: ';'
    , (err, string) ->
      return cb err if err
      out.push
        type: 'csv'
        filename: "#{file.title ? name}.csv"
        description: file.description
        content: iconv.encode string, 'windows1252'
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
