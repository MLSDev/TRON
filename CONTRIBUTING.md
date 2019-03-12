# Contributing to TRON

This document contains a set of guidelines to help you during the contribution
process.
Please review it in order to ensure a fast and effective response from the
maintainers and volunteers.

We are happy to welcome all contributions from anyone willing to improve this
project.
Thank you for helping out and remember, no contribution is too small.

## Table Of Contents

- [General questions](#general-questions)
- [Issues and bugs](#issues-and-bugs)
- [Feature requests](#feature-requests)
- [Submitting contributions](#submitting-contributions)
- [Additional notes](#additional-notes)

## General questions

The main function of the issue tracker is to record bug reports and feature
requests.
For general questions you can look at the [documentation], [guides] and [project README](https://github.com/MLSDev/TRON) to learn more about
the project and find some examples.
If you still have questions please consider using [Stack Overflow].

## Issues and bugs

Before creating a new issue please search for similar issues, open or closed,
to see if someone else has already noticed the same problem and possible
solutions.
Do not comment on open issues unless you can provide more information to
resolve it.
Use the subscribe function to keep up-to-date with the report or the voting
system to support it.
When you can't find a previous report open an issue keeping in mind the
following considerations:

- Try to reproduce the bug using the code found on the master branch to ensure
  it hasn't been fixed
- Fill the bug report template with all the information requested
- Provide a failing test case or an example with step by step instructions to
  reproduce the bug
- Copy and paste the full error message, including the backtrace
- Be as detailed as possible and include any additional information relevant to
  the report

## Feature requests

If you want to request or implement a new feature please submit an issue
describing the details and possible use cases.
When the feature can be implemented as a plugin/extension/external package
please do so to maintain the code base as small and simple as possible.
Features that break backwards compatibility must provide good reasons to do it
and a deprecation note when applicable.

## Submitting contributions

We are glad to receive code contributions in the form of patches, improvements
and new features.
Below you will find the process and workflow used to review and merge your
changes.

### Step 0: Find or create an issue

Every change in this project should/must have an associated issue.
If you want to contribute a patch, comment on the bug report to let the
maintainers, volunteers and interested people know you are working on it.
If you want to contribute a new feature or code improvement open a new issue
first to discuss it and be sure the maintainers will want to merge it before
working.

### Step 1: Fork the project

Fork the project and work on your own copy.

### Step 2: Branch

Create a new branch. Use its name to identify the issue your addressing.

### Step 3: Code

- **Follow the code conventions**: Make sure that new code does not produce any warnings
from automatic linter using SwiftLint.

- **Document your changes**: Add or update the relevant entries for your change
  in the documentation to reflect your work and inform the users about it.
  If you don't write documentation, we have to, and this can hold up acceptance
  of your changes

- **Add unit tests**: If you add or modify functionality, it must include unit
  tests.
  If you don't write tests, we have to, and this can hold up acceptance of
  your changes

- **Update the CHANGELOG**: Once you meet all previous requirements, add an
  entry to the *Next* section of the change log.
  Again, if you don't update the CHANGELOG, we have to, and this holds up
  acceptance.

### Step 4: Commit

Try to commit as often as you can, keeping your changes logically grouped
within individual commits.
Generally it's easier to review changes that are split across multiple commits.
A good commit message should describe what changed and why.
Use git interactive rebase if you need to tidy up your commits.

### Step 5: Rebase

Rebase your branch to include the latest work on your branch and resolve
possible merge conflicts.

### Step 6: Test

Bug fixes and features should have tests and avoid breaking tested code.
Run the test suite and make sure all tests pass.
Please do not submit patches that fail either check.

### Step 7: Push

When your work is ready and complies with the project conventions,
upload your changes to your fork.

### Step 8: Pull request

Open a new Pull Request from your working branch to `master`.
Write about the changes and add any relevant information to the reviewer.
Add a reference to the related issue with `Fix: ###` or `Close: ###`,
depending if the pull request fixes a bug or adds a new feature,
at the end of the PR message, where ### is the number of the issue.

## Additional notes

TRON heavily relies on Foundation URL loading system and [Alamofire](https://github.com/Alamofire/Alamofire),
so you may need to dig into documentation of those on specific topic you are encountering issues with or want to improve.

[documentation]: https://mlsdev.github.io/TRON/
[guides]: https://github.com/MLSDev/TRON/tree/master/Docs
[Stack Overflow]: http://stackoverflow.com/
