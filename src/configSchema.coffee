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
    query:
      title: "Query List"
      description: "the queries to run to retrieve the measurement result"
      type: 'object'
      entries: [
        title: "Query"
        description: "the query to run to retrieve the measurement result"
        type: 'object'
        mandatoryKeys: true
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
            type: 'string'
            trim: true
            replace: [/\s+/, ' ']
          sort:
            title: "Sort Order"
            description: "the sort order for the results (if needed)"
            type: 'array'
            toArray: true
            entries:
              type: 'string'
            optional: true
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
          sort:
            title: "Sort Order"
            description: "the sort order for the results (if needed)"
            type: 'array'
            toArray: true
            entries:
              type: 'string'
            optional: true
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
