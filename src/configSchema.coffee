# Configuration Schema
# =================================================


email = require('alinex-mail/lib/configSchema.js').email

# Complete Schema Definition
# -------------------------------------------------
job =
  title: "Report Job"
  description: "the definition of a single report job"
  type: 'object'
  allowedKeys: true
  keys:
    title:
      title: "Title"
      description: "the short title of the job to be used in display"
      type: 'string'
    description:
      title: "Description"
      description: "a short abstract of what this job will retrieve"
      type: 'string'
    variables:
      type: 'object'
      entries: [
        type: 'object'
        mandatoryKeys: ['type']
        keys:
          type:
            type: 'string'
      ]
      optional: true
    query:
      title: "Query List"
      description: "the queries to run to retrieve the measurement result"
      type: 'object'
      entries: [
        title: "Query"
        description: "the query to run to retrieve the measurement result"
        type: 'object'
        mandatoryKeys: true
        allowedKeys: true
        keys:
          title:
            title: "Title"
            description: "the short title of the query to be used as file"
            type: 'string'
            optional: true
          description:
            title: "Description"
            description: "a short abstract of what this query will do"
            type: 'string'
            optional: true
          database:
            title: "Database"
            description: "the alias name of the database to store to"
            type: 'string'
            list: '<<<context:///database>>>'
            optional: true
          command:
            title: "Command"
            description: "the concrete sql to run to retrieve the measurement result"
            type: 'handlebars'
      ]
    sendEmpty:
      title: "Send Empty Data"
      description: "a flag indicating to also send an email if no data could be found"
      type: 'boolean'
      default: true
    compose:
      title: "Compose Data"
      description: "the logic to compose results from data"
      type: 'object'
      entries: [
        title: "List"
        description: "the alias name of the list to create"
        type: 'object'
        mandatoryKeys: true
        allowedKeys: true
        keys:
          title:
            title: "Title"
            description: "the short title of the list to be used as file"
            type: 'string'
            optional: true
          description:
            title: "Description"
            description: "a short abstract of what this list will contain"
            type: 'string'
            optional: true
          append:
            title: "Table Data to Append"
            description: "the list of table data (alias names) to append"
            type: 'or'
            or: [
              type: 'array'
              toArray: true
              entries:
                type: 'string'
            ,
              type: "boolean"
            ]
            optional: true
          join:
            title: "Table Data to Join"
            description: "the list of table data (alias names) to join"
            type: 'or'
            or: [
              type: 'object'
              entries: [
                type: 'string'
                list: ['left', 'right', 'inner', 'outer', 'append']
              ]
            ,
              type: 'array'
              toArray: true
              entries:
                type: 'string'
            ,
              type: "boolean"
            ]
            optional: true
          sort:
            title: "Sort Order"
            description: "the sort order for the results (if needed)"
            type: 'array'
            toArray: true
            entries:
              type: 'string'
            optional: true
          reverse:
            title: "Reverse Order"
            description: "the list will be reversed"
            type: 'boolean'
            optional: true
          fields:
            title: "Display Fields"
            description: "the list of fields to include"
            type: 'array'
            delimiter: /\s*,\s*/
            entries:
              type: 'string'
            optional: true
          format:
            title: "Format Values"
            description: "the format for each column"
            type: 'object'
            optional: true
          unique:
            title: "Remove Duplicates"
            description: "the duplicated rows will be removed"
            type: 'boolean'
            optional: true
          flip:
            title: "Flip x/y Axis"
            description: "the x and y axes are changed"
            type: 'boolean'
            optional: true
      ]
    csv:
      title: "Include CSV"
      description: "a flag if or which csv data should be attached"
      type: 'or'
      or: [
        type: 'boolean'
      ,
        type: 'array'
        entries:
          type: 'string'
      ]
      default: true
    html:
      title: "Create HTML"
      description: "the list of HTML Reports to generate"
      type: 'object'
      entries: [
        title: "List"
        description: "the alias name of the list to create"
        type: 'object'
        mandatoryKeys: true
        allowedKeys: true
        keys:
          title:
            title: "Title"
            description: "the short title of the report to be used as file"
            type: 'string'
            optional: true
          locale:
            title: "Locale Setting"
            description: "the locale setting for subject and body dates"
            type: 'string'
            minLength: 2
            maxLength: 5
            lowerCase: true
            match: /^[a-z]{2}(-[a-z]{2})?$/
            optional: true
          content:
            title: "Content"
            description: "the content of the generated pdf report"
            type: 'handlebars'
      ]
    pdf:
      title: "Create PDF"
      description: "the list of PDF Reports to generate"
      type: 'object'
      entries: [
        title: "List"
        description: "the alias name of the list to create"
        type: 'object'
        mandatoryKeys: true
        allowedKeys: true
        keys:
          title:
            title: "Title"
            description: "the short title of the report to be used as file"
            type: 'string'
            optional: true
          format:
            title: "Page Size"
            description: "the size of the pages"
            type: 'string'
            list: ['A3', 'A4', 'A5', 'Legal', 'Letter', 'Tabloid']
            default: 'A4'
          orientation:
            title: "Orientation"
            description: "the orientation of the page"
            type: 'string'
            list: ['portrait', 'landscape']
            default: 'portrait'
          locale:
            title: "Locale Setting"
            description: "the locale setting for subject and body dates"
            type: 'string'
            minLength: 2
            maxLength: 5
            lowerCase: true
            match: /^[a-z]{2}(-[a-z]{2})?$/
            optional: true
          content:
            title: "Content"
            description: "the content of the generated pdf report"
            type: 'handlebars'
      ]
    email: email


# Complete Schema Definition
# -------------------------------------------------

module.exports =
  title: "Report Setup"
  description: "the configuration for the database report system"
  type: 'object'
  allowedKeys: true
  keys:
    job:
      title: "Report Setup"
      description: "the configuration for the database report system"
      type: 'object'
      allowedKeys: true
      entries: [job]
    email:
      title: "Email Templates"
      description: "the possible templates used for sending emails"
      type: 'object'
      entries: [email]
