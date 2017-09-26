Script at github, install to your local drive (not here)
	https://github.com/ldss-jm/authority-control-unlinked-headings-prep/
	postgres_connect - install this too
		https://github.com/ldss-jm/postgres_connect
		needs to live inside a folder called "postgres_connect" in the parent directory of the unlinked headings script
			so, eg.:
			c:/things/ulh_whatever/split_ulh.rb
			c:/things/postgres_connect/connect.rb
		ask for help setting up the auths
	updating script with git bash
		run git bash in the scrip dir; use git pull
Place in working directory any ULH files you want processed
Remove any other .ULH files from working directory
If there are any previous result files you want to keep, move them out of working directory or they will be overwritten.
If you run into encoding errors running any of the ruby scripts, you may have to run them from powershell after changing your code page for the session to 65001 (chcp 65001)
Run split_ulh.rb (on your local drive). It doesn't modify the ULH file(s), but will:
	write, as they are in the ULH file, entries with an index/tag we do care about to files divided by index/tag, so:
		pname.split.ulh
		cname.split.ulh
		psubj.split.ulh
		csubj.split.ulh
		series.split.ulh
	ignore header text, empty lines etc. from the file
	ignore entries with an index or tag we don't care about right now
	This step is cheap and easy, so treat these split files as disposable. You can easily recreate them by running split_ulh.rb again
Delete any *.split.ulh files you don't want to further process. Pare down the *.split.ulh file(s) you do want to process to the desired number of entries or alphabetic subset.
	If you pare down the files, use a text editor which isn't going to interpret the content and/or change the encoding. Text editors like Wordpad, Notepad++, and Geany are fine. I'd guess NoteTab Lite is fine. Notepad is probably fine for small enough files. Word is likely not fine. You want something you can use to delete unwanted lines, but not change anything else.
	The next step queries the Sierra database, which we'd rather not do needlessly. So, don't process all 300k lines of the pname file. Process, more or less, however many lines staff will deal with before this script gets run again. If that guideline results in you processing 20k-80k lines or fewer at a time, a few times a month, you should have no problems. (So please also don't waste your own time by being overly cautious.)
Once the split.ulh files are pared down or removed, run prep_for_openrefine.rb (on your local drive). And then you're done! [until you have SierraDNA permissions, email jamie and he'll run this]
	This checks for matches against the Sierra database. You need SierraDNA permissions to do this part.
	There's no prohibition against processing mixed types of split.ulh files (e.g. pname and csubj) at the same time
	It might take about a minute per 10k-15k entries.
	It will write:
		A txt file ready to be ingested into OpenRefine for the LC/VIAF lookup.
			One txt file for each index/tag type
			Named along the lines of or_pname.txt
		Various files in the debug folder, which are useful for debugging but aren't necessarily indicative of a problem.
			unsure.debug - a list of records the script wasn't confident it was capable of determining whether Sierra has a match. These entries get included in the file for OpenRefine alongside actual matches.
			no_matches.debug - list of records the script determined are not in Sierra. Contains: index_tag, norm_field_content, field_content
			no_matches_orig.debug - the same list as above, but just contains the altered entry from the ULH file.
			fail.debug - a list of record without a conclusive match (so, entries on unsure or no_matches). Contains just the original line from LTI's ULH file, so it can be re-run through prep_for_or.rb if testing improvements or bug fixes.
			[type].debug (e.g. pname.debug) - a list of records written to each or_[type].txt file. Includes both cases where the script found a positive match and cases where the script was not confident it could determine whether Sierra had a match.
				Probably contains: field_code, field_content, index_tag, norm_field_content, status, problem, openrefine, sierra]
			discards.debug - if the split.ulh files contains entries we don't care about (like genre headings) or blank/filler lines, 
