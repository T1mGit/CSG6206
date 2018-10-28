#!/bin/bash

############ REFERENCES #############
# Natarajan, R. (2010). The Ultimate Bash Array Tutorial with 15 Examples. The Geek Stuff, 1–23. IT. Retrieved from https://www.thegeekstuff.com/2010/06/bash-array-tutoria
# Chadwick, R. (2018). Arithmetic! It all adds up. Ryan Chadwick. Retrieved from https://ryanstutorials.net/bash-scripting-tutorial/bash-arithmetic.php

#file download is disabled. Not required for assignment.
#url="$2" #http://sipi.usc.edu/database/misc.zip

if [[ $# < 1 ]] ; then
	echo Error. No directory supplied
	exit 1
fi

target="$1" #target folder


ls -d $target
let err=$?
if [[ $err -ne 0 ]] ; then
	echo Directory not found
	exit 2
fi

################# Function Definition #####################

function padstr {
#function padstr <str> <pad> <chr> will add padding to <str> until  width of str+pad = <pad>
#if <pad> is less than <str> no padding is added
str="$1"
pad=$2
chr="$3"
let strlen=${#str}
if [ $strlen -gt $pad ] ; then
	let padlen=0
	let rem=0
else
	#the pad length to add to each side is half the total pad length
	let padlen=($pad-$strlen)
	let rem=($padlen % 2)
	let padlen=($padlen/2)
fi
#to account for odd  padding left & justified we must add padding to both side 1 less than the expected value.
for (( s=1; s < $padlen; s++ )) ; do
	str="$chr$str$chr"
done
# to left justify add the last pad character to the right side only
str="$str$chr"
#if padding and string was even (check remainder) then add pad character to left side aswell
if [ $rem -eq 1 ]; then
	str="$chr$str"
fi
printf "%s" $str
}

#Download is not required for assignment as file is assumed to exist.
function download {
	#download and arbitrary file from the web to target folder
	src=$1
	tgt="$2"
	wget --tries=3 --directory-prefix="$tgt" --show-progress $src
	let err=$?
	if [ $err -gt 0 ] ; then
		printf "wget returned error %d\n" $err
		return  1
	fi
	#for each file in download directory, if it is a zip file unzip it
	for f in "$2"/*.zip ; do
		if [ "$(file $f | cut -d' ' -f2)"="Zip" ] ; then
			unzip $f -d .
			let err=$?
			if [ $err -gt 0 ] ; then
				printf "unzip returned error %d\n" $err
				return 2
			fi
		fi
	done
	return 0
}

#download the file - disabled not required for assignement
#download $url $target
#let err=$?
#if [ $err -gt 0 ] ; then
#	printf "download returned error %d. 1-wget error. 2-unzip error.\n" $err
#	exit
#fi

################# Main  Body ###################################

#declare arrays to store filenames
declare -a colors
declare -a grays

#loop through files in  folder 
for i in $target/*.tiff ; do
	type=$( identify $i | cut -d' ' -f6 ) #cut breaks up  the otput of identify into token and returns  token f#
	name=$( identify $i | cut -d' ' -f1 )
	#sort the file into an array based on the  type
	if [ "$type" = "sRGB" ] ; then
		colors=("${colors[@]}" "$name") #this is string expansion
	elif [ "$type" = "Grayscale" ] ; then
		grays=("${grays[@]}" "$name")
	fi
done
#print the table header using the padstr function ( padstr <str> <pad> <chr> )
padstr Greyscale 41 -
printf "|"
padstr Color 41 -
printf "\n"
padstr _ 41 _
printf "|"
padstr _ 41 _
printf "\n"

#print the filenames in columns
let count=${#grays[*]}
for (( i=0; i < $count; i++ )) ; do
	padstr "${grays[i]}" 41 .
	printf "|"
	padstr "${colors[i]}" 41 .
	printf "\n"
done

