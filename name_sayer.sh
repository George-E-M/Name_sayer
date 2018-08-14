#!/bin/bash

#Creates a directory to store files if it doesn't exist
if [ ! -d "AVStorage" ]
then
	mkdir "AVStorage"
fi

#This function is used to display all of the current creations
showCurrentCreations() {
	#Checks if there are any creations
	if [ -z "$(ls -A AVStorage)" ]
	then
		echo "You currently have no creations"
	else
		#Loops through all the files and outputs then neatly
		local files=(AVStorage/*)
		local count=1
		for file in "${files[@]}"
		do
			local editedFile=${file/'_'/' '}
			editedFile=${editedFile/'.mkv'/''}
			editedFile=${editedFile/'AVStorage/'/''}
			echo "$count) $editedFile"
			let count=$count+1
		done
	fi
}

#This function is used to select one of the current creations for delete or play, these creations
#are displayed using showCurrentCreations
selectCurrentCreations() {
	#Calls this to display the creations
	showCurrentCreations
	echo "======================================================"
	while :
	do
		#Gets the files and takes an input to select(to delete or play)
		local files=(AVStorage/*)
		local number
		read -p "Please enter the number of a creation or [q] to quit: " number
		local numberOfFiles=${#files[@]}
		if ( [[ "$number" -ge "1" && "$number" -le "$numberOfFiles" ]] ) 2>/dev/null
		then
			let number=$number-1
			selectedCreation=${files[$number]}
			break
		elif [ "$number" == "q" ]
		then
			selectedCreation="q"
			break
		else
			echo "Please enter a valid input"
		fi
	done
}

#Lists all current creations by calling showCurrentCreations
list() {
	#Shows current creations
	clear
	echo "======================================================"
	echo "Current Creations"
	echo "======================================================"
	showCurrentCreations
	echo "======================================================"
	read -n 1 -s -r -p "Press any key to continue "
}

#Handles the recording part of creation
record() {
	#Checks if the process has been terminated
	local stillRecording=true
	while [ "$stillRecording" = true ]
	do	
		#Takes recording input
		echo ""
		echo "You need to record the audio for this creation"
		local reply
		read -n 1 -s -r -p "Press [q] to quit and any other key to start recording: " reply
		if [ "$reply" == "q" ]
		then
			rm video.mkv
			break
		fi
		#Starts recording
		echo ""
		echo "Recording..."
		ffmpeg -y -f alsa -loglevel quiet -t 5 -i default audio.mp3 < /dev/null
		echo ""
		echo "Done!"
		#Checks if they want to hear the recording
		while :
		do
			local record
			read -p "Do you wish to hear the recording?[y/n] (or [q] to quit): " record
			if [ "$record" == "y" ]
			then
				ffplay -i audio.mp3 -autoexit -loglevel quiet
				break
			elif [ "$record" == "n" ]
			then
				break
			elif [ "$record" == "q" ]
			then
				stillRecording=false
				break
			else
				echo "Please enter a valid input"
			fi
		done
		#Checks if they want to keep the recording
		while [ "$stillRecording" = true ]
		do
			local keep
			read -p "Do you wish to keep or redo the recording?[k/r] (or [q] to quit): " keep
			if [ $keep == "k" ]
			then
				#Combines the files
				ffmpeg -loglevel quiet -i video.mkv -i audio.mp3 -codec copy -shortest AVStorage/$1.mkv
				rm audio.mp3
				rm video.mkv
				read -n 1 -s -r -p "Creation successful, press any key to return to the menu"
				stillRecording=false
				break
			elif [ $keep == "r" ]
			then
				rm audio.mp3
				break;
			elif [ $keep == "q" ]
			then
				rm audio.mp3
				rm video.mkv
				stillRecording=false
				break
			else
				echo "Please enter a valid input"
			fi
		done
	done
}

#Creates a new creation by first creating the text file and then calling record.
create() {
	#Removes files the may be left over if the program was aborted using ctrl-c
	if [ -f "audio.mp3" ]
	then
		rm audio.mp3
	fi
	if [ -f "video.mkv" ]
	then
		rm video.mkv
	fi
	
	#Takes and checks the name input
	clear
	while :
	do
		#Takes the name of the creation
		local name
		read -p "Enter a full name for the new creation or [q] to quit: " name
		#Checks if the user wants to abort
		if [ "$name" == "q" ]
		then
			break
		fi
		#Checks if the input is a name
		local reg='^[a-zA-Z ]+$'
		if [[ $name =~ $reg ]]
		then
	
			name=$name | sed 's/^[ \t]*//;s/[ \t]*$//'
			local nameWithSpace=$name
			name=${name/' '/'_'}
			#Checks the name doesn't already exist
			if ( [[ ! -f AVStorage/$name".mkv" ]] ) 2>/dev/null
			then
				ffmpeg -f lavfi -i color=c=black:s=640x480:d=5 -loglevel quiet -vf drawtext="fontfile=/usr/shar/fonts/truetype/liberation/LiberationSans-Regular.ttf:fontsize=30:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$nameWithSpace'" video.mkv
				record $name
				break
			else
				echo "This name is already taken"
			fi
		else
			echo "Use only characters and spaces (you must include atleast one character)"
		fi
	done
}

#Plays a creation by calling selectCurrentCreations
play() {	
		#Displays the creations to play and gives the option to choose one
		clear
		echo "======================================================"
		echo "Select a creation to play"
		echo "======================================================"
		selectCurrentCreations
		if [ ! $selectedCreation == "q" ]
		then
			ffplay -i $selectedCreation -loglevel quiet -autoexit
		fi
}

#Deletes a creation by playing selectCurrentCreations then asks for confirmation
delete() {
	#Allows the user to delete files
	local deleted=false
	while [ "$deleted" = false ]
	do
		clear
		echo "======================================================"
		echo "Select a creation to delete"
		echo "======================================================"
		selectCurrentCreations
		if [ ! $selectedCreation == "q" ]
		then
			while :
			do	
				#Makes the input user friendly
				local editedCreation
				editedCreation=${selectedCreation/'_'/' '}
				editedCreation=${editedCreation/'.mkv'/''}
				editedCreation=${editedCreation/'AVStorage/'/''}
				local confirm
				#Asks the user to confirm deletion
				read -p "Are you sure you wish to delete $editedCreation [y/n]: " confirm
				if [ "$confirm" == "y" ]
				then
					rm $selectedCreation
					deleted=true
					read -n 1 -s -r -p "Creation successfully deleted, press any key to return to the menu"
					break
				elif [ "$confirm" == "n" ]
				then
					break
				else
						echo "Please enter a valid input"
				fi
			done
		else
			deleted=true
		fi
	done
}

#Main loop (can only be exited with a q input).
__failedInput=false
while :
do
	if [ "$__failedInput" = false ]
	then	
		clear
		echo "======================================================"
		echo "Welcome to NameSayer"
		echo "======================================================"
		echo "Please select from one of the following options:"
		echo "	(l)ist existing creations"
		echo "	(p)lay an existing creation"
		echo "	(d)elete an existing creation"
		echo "	(c)reate a new creation"
		echo "	(q)uit authoring tool"
	fi
	read -p "Enter a selection [l/p/d/c/q]: " CMD
	case $CMD in 
	l)
		__failedInput=false
		list
		;;
	p)
		__failedInput=false
		play
		;;
	d)
		__failedInput=false
		delete
		;;
	c)
		__failedInput=false
		create
		;;
	q)
		clear				
		exit
		;;
	*)
		echo "Please enter a valid input"
		__failedInput=true
		;;
	esac	
done
