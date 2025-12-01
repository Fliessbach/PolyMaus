# polymaus.praat
# Version 1.0
# Author: Jan Fliessbach
# Date: 01/12/2025
# A script for manual annotation or automatic data extraction from MAUS and polytonia output to csv/txt.
# INSTRUCTIONS
#	The script expects 
#		a)	.wav files
#		b)	.textgrid files with the same names as the wav files, from the MAUS Pipeline 'ASR > G2P > CHUNKER > MAUS > PRO2SYL > SD'
#		c)	A pipeline output where phonological word tier (KAN-MAU) and orthographic word tier (ORT-MAU) are completely aligned (standard MAUS output, no manual changes to intervals)
#		d)	Installed phoetic fonts : https://praat-users.yahoogroups.co.narkive.com/0SrQ2as0/phonetic-font-not-available-shut-down, https://praat.org/download_win.html
#		e)	Facultative : a polytonia file
# Written in Praat 6.4.33
###############FORM########################


# Select base folders and relevant tier indices
form Select directories (with slash at the end, Windows: backslash, OSX: forward slash)
	comment Where are the WAV files kept?
	sentence wav_dir C:\Users\janfl\Desktop\Interviews\polytonia_test4\
	comment Where are the TextGrid files kept?
	sentence txt_dir C:\Users\janfl\Desktop\Interviews\polytonia_test4\
	comment Where should the results file be kept?
	sentence directory C:\Users\janfl\Desktop\Interviews\polytonia_test4\
	comment Which is the tier with the orthographic words (ORT-MAU)?
	integer wordtier 1
	comment Which is the tier with phonological words (KAN-MAU)?
	integer phontier 2
	comment Which is the tier with syllables (MAS)?
	integer syltier 14
	comment Which is the tier with the speaker labels (SPK-MAU)?
	integer speakertier 13
	comment Which is the tier with the chunks/turns (TRN)?
	integer chunktier 15
endform

#  phoneme vs grapheme search 

beginPause: "Search Tier"
	comment: "Select the tier to search for the target:"
	optionMenu: "searchTier", 2
	option: "Phoneme tier"
	option: "Grapheme tier (Orthographic)"
clicked = endPause ("Continue", 1)


#  target and filter toggle 
beginPause: "Target Input"
	if searchTier = 1
		comment: "Specify the target phoneme."
	else
		comment: "Specify the target grapheme (character)."
	endif
	sentence ("target", "d")

	comment: "Do you want to restrict matches based on the surrounding context?"
	optionMenu: "filterContext", 1
	option: "Yes"
	option: "No"
clicked = endPause ("Continue", 1)

#  only shown if context filtering is active 
if filterContext = 1
	beginPause: "Context Filter Settings"
		comment: "Which characters or phonemes may occur before the target?"
		sentence  ("precedingTargetSet", "aeiou")
		comment: "Which characters or phonemes may occur after the target?"
		sentence  ("followingTargetSet", "haeiou")
	clicked = endPause ("Continue", 1)
endif

#  polytonia merge? 
beginPause: "Polytonia merge"
	comment: "Do you want to merge a polytonia file (with suffix _polytonia.textgrid) with your textgrid during the analysis?"
	optionMenu: "polytoniaBool", 1
	option: "Yes, merge."
	option: "No."
clicked = endPause ("Continue", 1)

#  manual annotations? 
beginPause: "Annotations"
	comment: "Do you want to stop at each match to add manual annotations, or continue automatically?"
	optionMenu: "annotationBool", 1
	option: "Annotate manually at each match."
	option: "Run automatically without annotations."
	comment ("Note: If a word contains the target multiple times, the same word will be repeated for each match.")
clicked = endPause ("Continue", 1)

if annotationBool = 0
	startAtMatchIndex = 1
endif

if annotationBool = 1
	beginPause: "Custom Annotation Fields"
		comment ("How many custom annotation fields do you want to define (max. 10)?")
		comment ("You will enter a name and value for each of them.")
		integer ("nAnnotations", 2)
		comment ("Resume from a specific match (index)? (CAUTION: Will apply to all files!)")
		integer ("startAtMatchIndex", 1)
	clicked = endPause ("Continue", 1)
endif

if annotationBool = 1
	# Initialize a list of annotation variable names and default values
	for iAnn from 1 to nAnnotations
		formName$ = "Annotation " + string$(iAnn)
		beginPause: "Define annotation field " + string$(iAnn)
			comment: "Enter a name for annotation field " + string$(iAnn) + ":"
			sentence ("annotationName" + string$(iAnn), "annotation" + string$(iAnn))
		clicked = endPause ("Continue", 1)
	endfor
	# Store original annotation field labels to be reused for pauses
	if nAnnotations > 0
		annotationFieldLabel1$ = annotationName1$
	endif
	if nAnnotations > 1
		annotationFieldLabel2$ = annotationName2$
	endif
	if nAnnotations > 2
		annotationFieldLabel3$ = annotationName3$
	endif
	if nAnnotations > 3
		annotationFieldLabel4$ = annotationName4$
	endif
	if nAnnotations > 4
		annotationFieldLabel5$ = annotationName5$
	endif
	if nAnnotations > 5
		annotationFieldLabel6$ = annotationName6$
	endif
	if nAnnotations > 6
		annotationFieldLabel7$ = annotationName7$
	endif
	if nAnnotations > 7
		annotationFieldLabel8$ = annotationName8$
	endif
	if nAnnotations > 8
		annotationFieldLabel9$ = annotationName9$
	endif
	if nAnnotations > 9
		annotationFieldLabel10$ = annotationName10$
	endif
endif


############FILES, TABLE AND STRING LISTS###################

# Check for and then delete any pre-existing version of the results file
Create Strings as file list... listTxt 'directory$'*.txt
numberOfResultsFilesTxt = Get number of strings
Create Strings as file list... listCsv 'directory$'*.csv
numberOfResultsFilesCsv = Get number of strings
numberOfResultsFiles = numberOfResultsFilesTxt + numberOfResultsFilesCsv
if 'numberOfResultsFiles' > 0
	pauseScript: "Warning: There are already .txt or .csv files in the results folder. Please move or rename them before proceeding to avoid overwriting."
endif


# List all WAV files (they determine the number of loops)
Create Strings as file list... listWav 'wav_dir$'*.wav
numberOfWavFiles = Get number of strings


# Allow for user-defined range of files to analyze
beginPause ("Select file range to analyze")
	comment ("Review the current WAV file list in the Objects window.")
	comment ("Enter the first and last file indices to process:")
	integer ("nfilefirst", 1)
	comment ("Last file index:")
	integer ("numberOfWavFiles", 'numberOfWavFiles')
	comment ("Note: Restarting from the middle of a previously processed file is not supported.")
endPause ("OK", 1)



############FILE LOOP###################
#
# Loop through each WAV file (as selected in subset)
#

for iFile from nfilefirst to numberOfWavFiles
	select Strings listWav
	fileName$ = Get string... 'iFile'
	baseName$ = fileName$ - ".wav"
			
	# Read in the Sound files with that base name
	mywav = Read from file... 'wav_dir$''baseName$'.wav
	mygrid = Read from file... 'txt_dir$''baseName$'.TextGrid
	gridName$ = selected$ ("TextGrid")
	
	# Select the Sound and compute pitch
	select Sound 'baseName$'
	# Filter out high frequencies above 900 Hz to reduce fricative interference
	Filter (stop Hann band): 900, 20000, 100

	# Create the pitch object using autocorrelation with a voicing threshold of 0.6
	select Sound 'baseName$'_band
	To Pitch (raw autocorrelation): 0, 50, 800, 15, "yes", 0.03, 0.6, 0.01, 0.35, 0.14
	select Pitch 'baseName$'_band
	Rename: baseName$

	if polytoniaBool = 1
		mygrid_poly = Read from file... 'txt_dir$''baseName$'_polytonia.TextGrid
		select TextGrid 'gridName$'
		plus TextGrid 'gridName$'_polytonia
		Merge
		select TextGrid 'gridName$'
		Rename... 'gridName$'_old
		select TextGrid merged
		Rename... 'gridName$'
		numberOfTiersMerged = Get number of tiers
		Save as text file... 'txt_dir$''baseName$'_merged.TextGrid
	endif

#
#
#################WORD LOOP###################
	
	# Load corresponding TextGrid and count intervals in phon tier
	# Select the TextGrid corresponding to our current wav
	select TextGrid 'gridName$'
	
	# Determine the number of intervals in the phon (KAN-MAUS) tier.
	number_of_wordsphon = Get number of intervals... 'phontier'

	# Index initialized
	matchIndex = 0

	# Iterate over intervals (i.e. words) in the phon tier
	for iWord from 1 to number_of_wordsphon
		# Write header and initialize result file on first word only
		# Filename depends on filtering and annotation settings
		if iWord = 1
			name$ = selected$ ("TextGrid")
			file$ = name$ + "_" + target$
			if filterContext = 1
				file$ = file$ + "_ctx"
			endif
			header$ = "matchIndex" + tab$ + "target" + tab$ + "fileName" + tab$ + "word_label" + tab$ + "phon_label" + tab$ + "begin_wordphon" + tab$ + "end_wordphon" + tab$ + "duration_wordphon" + tab$ + "interval_wordphon" + tab$ + "speakerOfWord" + tab$ + "chunkAroundWord" + tab$ + "previousWordOrtho" + tab$ + "previousWordphon" + tab$ + "labelToSearch" + tab$ + "subsequentWordOrtho" + tab$ + "subsequentWordphon" + tab$ + "labelLength" + tab$ + "targetIndexInWord" + tab$ + "positionInWord" + tab$ + "precedingTarget" + tab$ + "followingTarget" + tab$ + "matchAcrossWordBoundary" + tab$ + "f0Min_prev" + tab$ + "f0TimeMin_prev" + tab$ + "f0Max_prev" + tab$ + "f0TimeMax_prev" + tab$ + "f0Mean_prev" + tab$ + "f0Min_current" + tab$ + "f0TimeMin_current" + tab$ + "f0Max_current" + tab$ + "f0TimeMax_current" + tab$ + "f0Mean_current" + tab$ + "f0Min_next" + tab$ + "f0TimeMin_next" + tab$ + "f0Max_next" + tab$ + "f0TimeMax_next" + tab$ + "f0Mean_next" + tab$ + "polytoniaLabel"
			if annotationBool = 1
				fileCSV$ = file$ + "_anno.csv"
				fileTXT$ = file$ + "_anno.txt"
				if nAnnotations > 0
					
					header$ = header$ + tab$ + annotationName1$
					
					if nAnnotations > 1
						header$ = header$ + tab$ + annotationName2$
					endif
					if nAnnotations > 2
						header$ = header$ + tab$ + annotationName3$
					endif
					if nAnnotations > 3
						header$ = header$ + tab$ + annotationName4$
					endif
					if nAnnotations > 4
						header$ = header$ + tab$ + annotationName5$
					endif
					if nAnnotations > 5
						header$ = header$ + tab$ + annotationName6$
					endif
					if nAnnotations > 6
						header$ = header$ + tab$ + annotationName7$
					endif
					if nAnnotations > 7
						header$ = header$ + tab$ + annotationName8$
					endif
					if nAnnotations > 8
						header$ = header$ + tab$ + annotationName9$
					endif
					if nAnnotations > 9
						header$ = header$ + tab$ + annotationName10$
					endif
				endif
			else
				fileCSV$ = file$ + "_noAnno.csv"
				fileTXT$ = file$ + "_noAnno.txt"
			endif
			writeFileLine: fileCSV$, header$
			writeFileLine: fileTXT$, header$
		endif
		#CSV file initialized
		#Now get info
		select TextGrid 'gridName$'
		word_label$ = Get label of interval... 'wordtier' 'iWord'
		phon_label$ = Get label of interval... 'phontier' 'iWord'
		
		if searchTier = 1
			search_label$ = phon_label$
			search_label_nospaces$ = replace$(search_label$, " ", "", 0)
			labelToSearch$ = search_label_nospaces$
		else
			search_label$ = word_label$
			labelToSearch$ = search_label$
		endif
		labelLength = length(labelToSearch$)
		#Check for target
		# If the current word contains the target character, proceed
		if index(labelToSearch$, target$) <> 0
			# Get timing, speaker, context, and chunk information for the interval
			begin_wordphon = Get starting point... 'phontier' 'iWord'
			end_wordphon = Get end point... 'phontier' 'iWord'
			duration_wordphon = (end_wordphon - begin_wordphon) * 1000
			midpoint_wordphon = begin_wordphon + (end_wordphon - begin_wordphon) / 2
			interval_wordphon = Get interval at time... 'phontier' 'midpoint_wordphon'
			speakerAroundWordInterval = Get interval at time... 'speakertier' 'midpoint_wordphon'
			speaker_label$ = Get label of interval... 'speakertier' 'speakerAroundWordInterval'
			chunkAroundWordInterval = Get interval at time... 'chunktier' 'midpoint_wordphon'
			chunkAroundWord$ = Get label of interval... 'chunktier' 'chunkAroundWordInterval'
			if 'iWord'>1
				previousWordOrtho$ = Get label of interval... 'wordtier' 'iWord'-1
				previousWordphon$ = Get label of interval... 'phontier' 'iWord'-1
				previousWordphonNospaces$ = replace$(previousWordphon$, " ", "", 0)
			else
				previousWordOrtho$ = "NA"
				previousWordphon$ = "NA"
				previousWordphonNospaces$ = "NA"
			endif
			
			if 'iWord'< number_of_wordsphon
				subsequentWordOrtho$ = Get label of interval... 'wordtier' 'iWord'+1
				subsequentWordphon$ = Get label of interval... 'phontier' 'iWord'+1
				subsequentWordphonNospaces$ = replace$(subsequentWordphon$, " ", "", 0)
			else
				subsequentWordOrtho$ = "NA"
				subsequentWordphon$ = "NA"
				subsequentWordphonNospaces$ = "NA"
			endif
			
			#  Polytonia extraction 
			
			#  Polytonia label extraction over word span 
			if polytoniaBool = 1
				polytoniaIndexBegin = Get interval at time... 'numberOfTiersMerged' begin_wordphon
				polytoniaIndexEnd = Get interval at time... 'numberOfTiersMerged' end_wordphon
				polytoniaLabel$ = ""
				for i from polytoniaIndexBegin to polytoniaIndexEnd
					thisLabel$ = Get label of interval... 'numberOfTiersMerged' i
					if length(thisLabel$) > 0
						if length(polytoniaLabel$) = 0
							polytoniaLabel$ = thisLabel$
						else
							polytoniaLabel$ = polytoniaLabel$ + "/" + thisLabel$
						endif
					endif
				endfor
				if length(polytoniaLabel$) = 0
					polytoniaLabel$ = "NA"
				endif
			else
				polytoniaLabel$ = "NA"
			endif
			
			#  F0 Extraction 
			# Get time boundaries from the wordtier
			if 'iWord' > 1
				begin_prev = Get starting point... 'wordtier' 'iWord' - 1
				end_prev = Get end point... 'wordtier' 'iWord' - 1
			else
				begin_prev = -1
				end_prev = -1
			endif
			begin_current = begin_wordphon
			end_current = end_wordphon
			if 'iWord' < number_of_wordsphon
				begin_next = Get starting point... 'wordtier' 'iWord' + 1
				end_next = Get end point... 'wordtier' 'iWord' + 1
			else
				begin_next = -1
				end_next = -1
			endif

			# Initialize default values
			f0Min_prev = -1
			f0TimeMin_prev = -1
			f0Max_prev = -1
			f0TimeMax_prev = -1
			f0Mean_prev = -1

			f0Min_current = -1
			f0TimeMin_current = -1
			f0Max_current = -1
			f0TimeMax_current = -1
			f0Mean_current = -1

			f0Min_next = -1
			f0TimeMin_next = -1
			f0Max_next = -1
			f0TimeMax_next = -1
			f0Mean_next = -1


			select Pitch 'baseName$'
			# Extract for previous word
			if begin_prev >= 0 and end_prev > begin_prev
				f0Min_prev = Get minimum... begin_prev end_prev Hertz Parabolic
				f0TimeMin_prev = Get time of minimum... begin_prev end_prev Hertz Parabolic
				f0Max_prev = Get maximum... begin_prev end_prev Hertz Parabolic
				f0TimeMax_prev = Get time of maximum... begin_prev end_prev Hertz Parabolic
				f0Mean_prev = Get mean... begin_prev end_prev Hertz
			endif

			# Extract for current word
			f0Min_current = Get minimum... begin_current end_current Hertz Parabolic
			f0TimeMin_current = Get time of minimum... begin_current end_current Hertz Parabolic
			f0Max_current = Get maximum... begin_current end_current Hertz Parabolic
			f0TimeMax_current = Get time of maximum... begin_current end_current Hertz Parabolic
			f0Mean_current = Get mean... begin_current end_current Hertz

			# Extract for next word
			if begin_next >= 0 and end_next > begin_next
				f0Min_next = Get minimum... begin_next end_next Hertz Parabolic
				f0TimeMin_next = Get time of minimum... begin_next end_next Hertz Parabolic
				f0Max_next = Get maximum... begin_next end_next Hertz Parabolic
				f0TimeMax_next = Get time of maximum... begin_next end_next Hertz Parabolic
				f0Mean_next = Get mean... begin_next end_next Hertz
			endif
			
			#  F0 values for previous word 
			if string$(f0Min_prev) = "--undefined--"
				f0Min_prev_string$ = "NA"
			else
				f0Min_prev_string$ = fixed$(f0Min_prev, 3)
			endif

			if string$(f0TimeMin_prev) = "--undefined--"
				f0TimeMin_prev_string$ = "NA"
			else
				f0TimeMin_prev_string$ = fixed$(f0TimeMin_prev, 3)
			endif

			if string$(f0Max_prev) = "--undefined--"
				f0Max_prev_string$ = "NA"
			else
				f0Max_prev_string$ = fixed$(f0Max_prev, 3)
			endif

			if string$(f0TimeMax_prev) = "--undefined--"
				f0TimeMax_prev_string$ = "NA"
			else
				f0TimeMax_prev_string$ = fixed$(f0TimeMax_prev, 3)
			endif

			if string$(f0Mean_prev) = "--undefined--"
				f0Mean_prev_string$ = "NA"
			else
				f0Mean_prev_string$ = fixed$(f0Mean_prev, 3)
			endif

			#  F0 values for current word 
			if string$(f0Min_current) = "--undefined--"
				f0Min_current_string$ = "NA"
			else
				f0Min_current_string$ = fixed$(f0Min_current, 3)
			endif

			if string$(f0TimeMin_current) = "--undefined--"
				f0TimeMin_current_string$ = "NA"
			else
				f0TimeMin_current_string$ = fixed$(f0TimeMin_current, 3)
			endif

			if string$(f0Max_current) = "--undefined--"
				f0Max_current_string$ = "NA"
			else
				f0Max_current_string$ = fixed$(f0Max_current, 3)
			endif

			if string$(f0TimeMax_current) = "--undefined--"
				f0TimeMax_current_string$ = "NA"
			else
				f0TimeMax_current_string$ = fixed$(f0TimeMax_current, 3)
			endif

			if string$(f0Mean_current) = "--undefined--"
				f0Mean_current_string$ = "NA"
			else
				f0Mean_current_string$ = fixed$(f0Mean_current, 3)
			endif

			#  F0 values for subsequent word 
			if string$(f0Min_next) = "--undefined--"
				f0Min_next_string$ = "NA"
			else
				f0Min_next_string$ = fixed$(f0Min_next, 3)
			endif

			if string$(f0TimeMin_next) = "--undefined--"
				f0TimeMin_next_string$ = "NA"
			else
				f0TimeMin_next_string$ = fixed$(f0TimeMin_next, 3)
			endif

			if string$(f0Max_next) = "--undefined--"
				f0Max_next_string$ = "NA"
			else
				f0Max_next_string$ = fixed$(f0Max_next, 3)
			endif

			if string$(f0TimeMax_next) = "--undefined--"
				f0TimeMax_next_string$ = "NA"
			else
				f0TimeMax_next_string$ = fixed$(f0TimeMax_next, 3)
			endif

			if string$(f0Mean_next) = "--undefined--"
				f0Mean_next_string$ = "NA"
			else
				f0Mean_next_string$ = fixed$(f0Mean_next, 3)
			endif
			
			
			
			
			#Check for >1 matches of target
			# Count all occurrences of the target character in the label
			# Iterate over each position/character in the word to detect matches and extract context
			select TextGrid 'gridName$'
			targetIndexInWord = 0
			for iIndexTarget from 1 to labelLength
				if mid$(labelToSearch$, iIndexTarget, 1) = target$
					targetIndexInWord = targetIndexInWord + 1
					# Default context values
					precedingTarget$ = "NA"
					followingTarget$ = "NA"
					matchAcrossWordBoundary$ = "no"
					if filterContext = 1
						# Determine preceding target
						if iIndexTarget > 1
							precedingTarget$ = mid$(labelToSearch$, iIndexTarget - 1, 1)
						else
							if searchTier = 1
								if previousWordphonNospaces$ <> "NA" and length(previousWordphonNospaces$) > 0
									precedingTarget$ = right$(previousWordphonNospaces$, 1)
									matchAcrossWordBoundary$ = "preceding"
								endif
							else
								if previousWordOrtho$ <> "NA" and length(previousWordOrtho$) > 0
									precedingTarget$ = right$(previousWordOrtho$, 1)
									matchAcrossWordBoundary$ = "preceding"
								endif
							endif
						endif
						# Determine following target
						if iIndexTarget < labelLength
							followingTarget$ = mid$(labelToSearch$, iIndexTarget + 1, 1)
						else
							if searchTier = 1
								if subsequentWordphonNospaces$ <> "NA" and length(subsequentWordphonNospaces$) > 0
									followingTarget$ = left$(subsequentWordphonNospaces$, 1)
									matchAcrossWordBoundary$ = "following"
								endif
							else
								if subsequentWordOrtho$ <> "NA" and length(subsequentWordOrtho$) > 0
									followingTarget$ = left$(subsequentWordOrtho$, 1)
									matchAcrossWordBoundary$ = "following"
								endif
							endif
						endif
						# Filter: skip unless both context Targets match (break loop and go to ready)
						if index(precedingTargetSet$, precedingTarget$) = 0 or index(followingTargetSet$, followingTarget$) = 0
							goto ready
						endif
					endif
					
					# Skip if not from start
					matchIndex = matchIndex + 1
					if matchIndex < startAtMatchIndex
						goto ready
					endif
					
					# Proceed with annotation and output
					#Annotation
					if annotationBool = 1
						select TextGrid 'gridName$'
						plus Sound 'baseName$'
						View & Edit
						editor: "TextGrid " + gridName$
						Select: 'begin_wordphon'-0.1, 'end_wordphon'+0.1
						Zoom to selection
						Zoom out
						beginPause ("Don't click on spectrogram (selection lost), only on title bar; CTRL+N/O to zoom in/out.")
							comment ("Annotate. Position in word: " + string$(iIndexTarget) + "; Nth target in word: " + string$(targetIndexInWord) + "; Nth match in Grid: "  + string$(matchIndex))
							if nAnnotations = 0
								comment ("You specified nAnnotations = 0.")
							endif
							if nAnnotations > 0
								comment ("Field: " + annotationFieldLabel1$)
								sentence ("annotationResponse1", "NA")
							endif
							if nAnnotations > 1
								comment ("Field: " + annotationFieldLabel2$)
								sentence ("annotationResponse2", "NA")
							endif
							if nAnnotations > 2
								comment ("Field: " + annotationFieldLabel3$)
								sentence ("annotationResponse3", "NA")
							endif
							if nAnnotations > 3
								comment ("Field: " + annotationFieldLabel4$)
								sentence ("annotationResponse4", "NA")
							endif
							if nAnnotations > 4
								comment ("Field: " + annotationFieldLabel5$)
								sentence ("annotationResponse5", "NA")
							endif
							if nAnnotations > 5
								comment ("Field: " + annotationFieldLabel6$)
								sentence ("annotationResponse6", "NA")
							endif
							if nAnnotations > 6
								comment ("Field: " + annotationFieldLabel7$)
								sentence ("annotationResponse7", "NA")
							endif
							if nAnnotations > 7
								comment ("Field: " + annotationFieldLabel8$)
								sentence ("annotationResponse8", "NA")
							endif
							if nAnnotations > 8
								comment ("Field: " + annotationFieldLabel9$)
								sentence ("annotationResponse9", "NA")
							endif
							if nAnnotations > 9
								comment ("Field: " + annotationFieldLabel10$)
								sentence ("annotationResponse10", "NA")
							endif
						endPause ("OK", 1)
						Close
					endif
					# Write one output line per match
					# Includes target position, surrounding context, and optional manual annotations
					appendLine$ = string$(matchIndex) + tab$ + target$ + tab$ + baseName$ + tab$ + word_label$ + tab$ + phon_label$ + tab$ + fixed$(begin_wordphon, 3) + tab$ + fixed$(end_wordphon, 3) + tab$ + fixed$(duration_wordphon, 3) + tab$ + string$(interval_wordphon) + tab$ + speaker_label$ + tab$ + chunkAroundWord$ + tab$ + previousWordOrtho$ + tab$ + previousWordphonNospaces$ + tab$ + labelToSearch$ + tab$ + subsequentWordOrtho$ + tab$ + subsequentWordphonNospaces$ + tab$ + string$(labelLength) + tab$ + string$(targetIndexInWord) + tab$ + string$(iIndexTarget) + tab$ + precedingTarget$ + tab$ + followingTarget$ + tab$ + matchAcrossWordBoundary$ + tab$ + f0Min_prev_string$ + tab$ + f0TimeMin_prev_string$ + tab$ + f0Max_prev_string$ + tab$ + f0TimeMax_prev_string$ + tab$ + f0Mean_prev_string$ + tab$ + f0Min_current_string$ + tab$ + f0TimeMin_current_string$ + tab$ + f0Max_current_string$ + tab$ + f0TimeMax_current_string$ + tab$ + f0Mean_current_string$ + tab$ + f0Min_next_string$ + tab$ + f0TimeMin_next_string$ + tab$ + f0Max_next_string$ + tab$ + f0TimeMax_next_string$ + tab$ + f0Mean_next_string$ + tab$ + polytoniaLabel$
					
					if annotationBool = 1
						if nAnnotations > 0
							appendLine$ = appendLine$ + tab$ + annotationResponse1$
						endif
						if nAnnotations > 1
							appendLine$ = appendLine$ + tab$ + annotationResponse2$
						endif
						if nAnnotations > 2
							appendLine$ = appendLine$ + tab$ + annotationResponse3$
						endif
						if nAnnotations > 3
							appendLine$ = appendLine$ + tab$ + annotationResponse4$
						endif
						if nAnnotations > 4
							appendLine$ = appendLine$ + tab$ + annotationResponse5$
						endif
						if nAnnotations > 5
							appendLine$ = appendLine$ + tab$ + annotationResponse6$
						endif
						if nAnnotations > 6
							appendLine$ = appendLine$ + tab$ + annotationResponse7$
						endif
						if nAnnotations > 7
							appendLine$ = appendLine$ + tab$ + annotationResponse8$
						endif
						if nAnnotations > 8
							appendLine$ = appendLine$ + tab$ + annotationResponse9$
						endif
						if nAnnotations > 9
							appendLine$ = appendLine$ + tab$ + annotationResponse10$
						endif
					endif
					appendFileLine: fileCSV$, appendLine$
					appendFileLine: fileTXT$, appendLine$
					# Annotation finished and appended
					# Break point in case of filter (ready)
					label ready
				endif
			endfor
		endif
	endfor
endfor

# Remove all objects from the Praat environment
select all
Remove