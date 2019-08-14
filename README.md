# authority-control-unlinked-headings-prep

Converts a unlinked headings reports from marcive into output suitable for importing into OpenRefine for LC/VIAF lookup. Headings are normalized and only data from certain subfields is extracted. An indication of the bib's Sierra current status (unsuppressed/suppressed/deleted) is also output.

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

You can also create a report listing headings with zero $a's or multiple $a's.

## Setup / Installation

Requires ruby (see [here](https://www.ruby-lang.org) for ruby download/instructions)

In a terminal (e.g. powershell, terminal, bash):

```bash
# clone this repo
git clone https://github.com/ldss-jm/authority-control-unlinked-headings-prep

# install bundler
gem install bundle

# install some other dependencies
cd authority-control-unlinked-headings-prep
bundle install
```

Then, in the `authority-control-unlinked-headings-prep` folder you created during the above, create a `sierra_prod.secret` yaml file with Sierra DB credentials as described [here](https://github.com/UNC-Libraries/sierra-postgres-utilities).

## Usage

After setup, in the `authority-control-unlinked-headings-prep` folder, you can:

```bash
# view help text
bundle exec ruby exe/ulh help

# Read a marcive ULH report (NCHIPERS.txt) and write data
# suitable for openrefine (openrefine_personal.txt)
bundle exec ruby exe/ulh process NCHIPERS.txt openrefine_personal.txt

# Read a marcive ULH report (NCHIPERS.txt) and write a report
# of fields with zero $a's or multiple $a's
bundle exec ruby exe/ulh subfield_a NCHIPERS.txt subfield_a_problems.txt
```

## Updating

If you need to update your installation, in the `authority-control-unlinked-headings-prep` folder:

```bash
# update local files from github
git checkout master
git pull

# install the updated files
bundle install
```
