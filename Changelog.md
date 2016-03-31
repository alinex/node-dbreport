Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 1.4.4 (2016-03-31)
-------------------------------------------------
- Upgraded config package.

Version 1.4.3 (2016-03-31)
-------------------------------------------------
- Remove strict yargs parsing.

Version 1.4.2 (2016-03-30)
-------------------------------------------------
- Add variables to handlebars context.
- Fix quiet switch to be used.

Version 1.4.1 (2016-03-30)
-------------------------------------------------
- Upgraded report and chalk packages.
- Add code completion for bash.
- Add list of attachments to context parameters.
- Fixed sending of empty attached csv files.

Version 1.4.0 (2016-03-23)
-------------------------------------------------
- Add pdf report attachements by configuration.
- Add configuration for pdf.
- Allow to select fields to filter.
- Allow xy axes flip in composing table data.
- Add unique option to compose.
- Support reverse sorting of data lists.
- Add possible future configuration options as example comments.
- Add environment settings in help output.
- Upgrade yargs syntax to more specific parsing and help page.

Version 1.3.3 (2016-03-21)
-------------------------------------------------
- Upgrade validator, config, util, yaml and builder.
- Removed debug output.
- Fixed attachement check.

Version 1.3.2 (2016-03-17)
-------------------------------------------------
- Upgraded mail package.
- Not add attachements if not allowed in email config.
- No attachements if set to false.
- Fixed validation if no _mail present.

Version 1.3.1 (2016-03-17)
-------------------------------------------------
- Added checking for _mail variable.

Version 1.3.0 (2016-03-17)
-------------------------------------------------
- Allow variables to be used in query.

Version 1.2.0 (2016-03-16)
-------------------------------------------------
- Moved email template config to upper level.
- Use external mail package for email sending.
- Fix encoding of csv to windows1252 to work better in excel.
- Fixed general link in README.
- Added schema test.
- Change Usage info.

Version 1.1.3 (2016-02-29)
-------------------------------------------------
- Move alinex to alinex-core module because of npm problems.
- Include logo from alinex.

Version 1.1.2 (2016-02-26)
-------------------------------------------------
- Fixed sorting and added example.
- Add sort option for reports.
- Remove debug output.

Version 1.1.1 (2016-02-25)
-------------------------------------------------
- Enhance documentation for configuration options.

Version 1.1.0 (2016-02-24)
-------------------------------------------------
- Updated documentation.
- Working append mechanism.
- Updated examples.
- Use queries as fallback if no compose
- Updated config to allow compose settings.

Version 1.0.3 (2016-02-22)
-------------------------------------------------
- Display 0 rows as so instead NaN.

Version 1.0.2 (2016-02-22)
-------------------------------------------------
- Fixed row counting in csv.
- Updated documentation.

Version 1.0.1 (2016-02-17)
-------------------------------------------------
- Remove some debugging output.
- Add replyTo header in configuration.

Version 1.0.0 (2016-02-17)
-------------------------------------------------
- Added support for table of contents and remove empty attachements.
- Fix bug in using alternative email per command.
- Added list option support.
- Modularize into api module.

Version 0.1.0 (2016-02-16)
-------------------------------------------------
- Removed test output.

Version 0.0.3 (2016-02-16)
-------------------------------------------------
- Support dates.
- Added missing json2csv package.

Version 0.0.2 (2016-02-16)
-------------------------------------------------
- Added mocha test.
- Updated yargs parsing.
- Rename executable for installation to dbreport.
- Upgraded packages report and yargs.
- Add --mail option for try mode.
- Add missing packages.
- Allow country locales.

Version 0.0.1 (2016-02-10)
-------------------------------------------------
- Allow setting local form email contents.
- Configure coveralls and travis.
- Updated documentation.
- Finished tool but missing test and doc.
- Add default email config.
- Setup framework for new application.
- Initial commit

