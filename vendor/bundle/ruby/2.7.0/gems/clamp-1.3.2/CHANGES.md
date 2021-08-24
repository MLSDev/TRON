# Changelog

## 1.3.2 (2020-08-20)

* Fix Ruby warnings.

## 1.3.1 (2019-07-11)

* Choose a sensible column width in generated help, based on content.
* Fix issue#99: extraneous parameter names in subcommand help.

## 1.3.0 (2018-06-17)

* Add `.execute` DSL method.
* Append '(required)' to the description of required options.
* Fix issue#75: don't generate `default_XXX` method unless a default is specified.
* Fix issue#90: allow required options to be provided after subcommands.

## 1.2.0 (2018-02-12)

* Add option to `Clamp.allow_options_after_parameters`.

## 1.1.2 (2017-02-12)

* Improve usage help for commands with both parameters and subcommands.

## 1.1.1 (2016-10-19)

* Rename `.declare_attribute` back to `.define_accessors_for`.

## 1.1.0 (2016-10-17)

* Add `#subcommand_missing`.
* Fix issue#66: pass parameter values down to nested subcommands.
* Drop support for Ruby 1.9 and 2.0.

## 1.0.1 (2016-10-01)

* Minor bug-fixes.

## 1.0.0 (2015-06-08)

* Allow options to be `:hidden`.
* I18N support.

## 0.6.5 (2015-05-02)

* Catch signals and exit appropriately.

## 0.6.4 (2015-02-26)

* Ensure computed defaults are only computed once.

## 0.6.3 (2013-11-14)

* Specify (MIT) license.

## 0.6.2 (2013-11-06)

* Refactoring around multi-valued attributes.
* Allow injection of a custom help-builder.

## 0.6.1 (2013-05-07)

* Signal a usage error when an environment_variable fails validation.
* Refactor setting, defaulting and inheritance of attributes.

## 0.6.0 (2013-04-28)

* Introduce "banner" to describe a command (replacing "self.description=").
* Introduce "Clamp do ... end" syntax sugar.
* Allow parameters to be specified before a subcommand.
* Add support for :multivalued options.
* Multi valued options and parameters get an "#append_to_foo_list" method, rather than
  "#foo_list=".
* default_subcommand must be specified before any subcommands.
