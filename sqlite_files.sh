#!/bin/bash

#################### REFERENCES ##########################
#SQLite. (n.d.). Command Line Shell For SQLite. Retrieved from https://www.sqlite.org/cli.html
#Zoe. (2008). unix - Check if a directory exists in a shell script - Stack Overflow. Stack Overflow. Retrieved from http://stackoverflow.com/questions/59838/check-if-a-directory-exists-in-a-shell-script
#check that file path paramter has been supplied
if [[ $# -lt 1 ]] ; then
	echo Error. No directory path has been supplied
	exit 1
fi

path=$1
if [[ ! -d "$path" ]] ; then
	echo Error. Cannot find path specified
	exit 2
fi

#check if database table exists. file gets created automatically
echo Checking for images table...
table=( $(sqlite3 -line "images.db" .tables) )
if [[ "$table" != "images" ]] ; then
	#if the database file does not exist make a new table
	sqlite3  "images.db" "create table images(filename, size);"
	echo Made new table
else
	#if the table exists in database delete all records so as not to duplicate
	sqlite3 "images.db" "delete from images;"
	echo Emtpied the table
fi

#get size ordered list using ls command putting result in array
#this command puts file size in odd index and file name in even index
#the array is twice as long as the number of files plus a column header which is sipped
list=( $(ls -1sS $path) )
let len=${#list[*]}
for (( i=2 ; i < len ; i+=2 )) ; do
	#add record to database
	let j=($i+1)
	str="insert into images (filename, size) values ('${list[$j]}', ${list[$i]});"
	sqlite3 "images.db" "$str"
done

sqlite3 -list "images.db" "select * from images;"
