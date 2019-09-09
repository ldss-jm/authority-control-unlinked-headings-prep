# authority-control-utilities

* convert unlinked headings report into output suitable for importing into OpenRefine for LC/VIAF lookup
* find headings on an unlinked headings report with zero $a's or multiple $a's.
* from a report of changed fields, extract changes that include 880 and separate
by script (e.g. arabic, cjk, cyrillic, other)
* transform MarcEdit's MarcValidator report into a tab-delimited table

## Unlinked headings processing
Headings are normalized and only data from certain subfields is extracted. An indication of the bib's Sierra current status (unsuppressed / suppressed / deleted) is also output.

For example:

Input:

```text
.b14181587
+100 1  $6880-01$aZilʹbersdorf, E. A.$q(Evgeniĭ)$etranslator
```

Output:

```text
b1418158a   unsuppressed   Zilbersdorf, E. A. (Evgenii)
```

## Setup / Installation

Requirements:

- ruby (see [here](https://www.ruby-lang.org) for download/instructions)
- [git bash](https://gitforwindows.org/) (if using windows)

In a terminal (e.g. powershell, terminal, git bash):

```bash
# clone this repo
git clone https://github.com/ldss-jm/authority-control-utilities

# install bundler
gem install bundle

# install some other dependencies
cd authority-control-utilities
bundle install
```

Sierra credentials (and permissions) are needed if using tasks that connect to Sierra. In the `authority-control-utilities` folder you created during the above, create a `sierra_prod.secret` yaml file with Sierra DB credentials as described [here](https://github.com/UNC-Libraries/sierra-postgres-utilities).

## Usage

NOTE: If using powershell, you may need to switch to code page 65001 after starting the powershell session. To do this, enter `chcp 65001`. To switch back, you can just close the powershell window; or enter `chcp 437`. You'll switch to 65001 each new powershell
session.

After setup, in the `authority-control-utilities` folder, you can:
```bash
# view help text
bundle exec ruby exe/acu help

# Read a marcive ULH report (NCHIPERS.txt) and write data
# suitable for openrefine (openrefine_personal.txt)
bundle exec ruby exe/acu ulh_process NCHIPERS.txt openrefine_personal.txt

# Read a marcive ULH report (NCHIPERS.txt) and write a report
# of fields with zero $a's or multiple $a's
bundle exec ruby exe/acu subfield_a NCHIPERS.txt subfield_a_problems.txt

# From a marcive report of changed authorized fields, extract changes that
# include 880s, and write those changes to files by script/language
bundle exec ruby exe/acu extract_880s NCHIOBSO26.TXT
#   ...or process multiple reports:
bundle exec ruby exe/acu extract_880s NCHIOBSO*.TXT

# Transform MarcEdit's MarcValidator report into a tab-delimited table
#
# NOTE: this task cannot be done in powershell or "Command prompt" It needs to be done in something like git bash, terminal on a mac, etc.
bin/marcvalidator_to_table.sh marcvalidator_errors.txt > table.tsv

```

## Updating

If you need to update your installation, in the `authority-control-utilities` folder:

```bash
# update local files from github
git checkout master
git pull

# install the updated files
bundle install
```
