# Configuration Schema
# =================================================


# Email Action
# -------------------------------------------------

exports.email = email =
  title: "Email Action"
  description: "the setup for an individual email action"
  type: 'object'
  allowedKeys: true
  keys:
    base:
      title: "Base Template"
      type: 'string'
      description: "the template used as base for this"
      list: '<<<context:///email>>>'
    transport:
      title: "Service Connection"
      description: "the service connection to send mails through"
      type: 'or'
      or: [
        type: 'string'
      ,
        type: 'object'
      ]
    from:
      title: "From"
      description: "the address emails are send from"
      type: 'string'
      default: 'monitor'
    to:
      title: "To"
      description: "the address emails are send to"
      type: 'string'
    cc:
      title: "Cc"
      description: "the carbon copy addresses"
      type: 'string'
    bcc:
      title: "Bcc"
      description: "the blind carbon copy addresses"
      type: 'string'
    subject:
      title: "Subject"
      description: "the subject line of the generated email"
      type: 'handlebars'
    body:
      title: "Content"
      description: "the body content of the generated email"
      type: 'handlebars'

# Complete Schema Definition
# -------------------------------------------------
job =
  title: "Report Job"
  description: "the definition of a single report job"
  type: 'object'
  allowedKeys: true
  mandatoryKeys: ['database']
  keys:
    database:
      title: "Database"
      description: "the alias name of the database to store to"
      type: 'string'
      list: '<<<context:///database>>>'
      optional: true
    query:
      title: "Query List"
      description: "the queries to run to retrieve the measurement result"
      type: 'object'
      entries: [
        title: "Query"
        description: "the query to run to retrieve the measurement result"
        type: 'string'
      ]
#    combine: <func>
    email: email


# Complete Schema Definition
# -------------------------------------------------

exports.dbreport =
  title: "Report Setup"
  description: "the configuration for the database report system"
  type: 'object'
  allowedKeys: true
  entries: [job]
