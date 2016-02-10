# Configuration Schema
# =================================================


# Email Action
# -------------------------------------------------
email =
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
    to:
      title: "To"
      description: "the address emails are send to"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    cc:
      title: "Cc"
      description: "the carbon copy addresses"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    bcc:
      title: "Bcc"
      description: "the blind carbon copy addresses"
      type: 'array'
      toArray: true
      entries:
        type: 'string'
    locale:
      title: "Locale Setting"
      description: "the locale setting for subject and body dates"
      type: 'string'
      minLength: 2
      maxLength: 2
      lowerCase: true
      match: /^[a-z]{2}$/
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
  keys:
    title:
      title: "Title"
      description: "the short title of the job to be used in display"
      type: 'string'
    description:
      title: "Description"
      description: "a short abstract of what this job will check"
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
      ]
#    combine: <func>
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
