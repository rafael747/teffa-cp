#!/bin/bash

set -e

ajuda()
{
	echo -e "dependencies:\n"
	
	for i in nc dd pv md5sum awk file stat cut 
	do
		if a=`which $i` && test -x $a
		then
			echo -e "\t$i\tOK!"
		else
			echo -e "\t$i\tFAIL!"
		fi
	done 

	echo -e "usage:\n\n\tTo send a file: `basename $0` <file> <host>"
	echo -e "\tTo receive a file: `basename $0`"
	exit
} 

if [[ "$1" == "-h" ]]
then
	ajuda
fi

#Client
if [[ "$#" -eq "0" ]]
then
	echo "Listening on 2000/tcp..."

	#get the message
	msg=`nc -vl 2000 2>&1`

	#Parsing fields
	host=`echo -e $msg|grep -o "from .* port"|grep -o '[0-9].*[0-9]'`
	name=`echo -e $msg|awk '$1 ~ /file/ {print $0}'|sed 's/file: //1'`
	size=`echo -e $msg|awk '$1 ~ /sizeb/ {print $2}'`
	md5="`echo -e $msg|awk '$1 ~ /md5/ {print $2}'` $name"

	trap '{ nc $host 2000 <<< n; echo -e "\nFile rejected!"; exit 0; }' INT

	#show the message
	echo -e "$msg\n"|sed '/sizeb/d'|sed  '/Listening/d'
	
	# if the file already exists
	if [ -e "$name" ]
	then
		echo "*** file exists, WILL OVERWRITE THE FILE ***"
	fi

	echo -n "Accept the file? (Y/n): "

	#get the answer
	read n

	if [[ "$n" == "n" ]] || [[ "$n" == "N" ]]
	then
        	echo "File rejected!"
       		echo "n"|nc $host 2000
        	exit 1
	else
        	echo "file accepted!"
        	echo "y"|nc $host 2000 || (echo "connection closed!";exit 1)
        	nc -l 2000|pv -s $size|dd count=$size 2> >(tail -n1 1>&2) |cat - > "$name"
       		echo "checking the md5 hash"
		md5sum -c <<< "$md5"
        	exit 0
	fi

#Server
elif [[ "$#" -eq "2" ]]
then
	#create fields
	name=`basename "$1"`
	size=`ls -sh "$1" |awk '{print $1}'`
	sizeb=`stat -c %s "$1"`
	tipo=`file "$1" -b|cut -d " " -f 1-7`
	md5=`md5sum "$1"|awk '{print $1}'`

	#create msg
	msg="\nfile: $name\nsize: $size\ntype: $tipo\nmd5: $md5\nsizeb: $sizeb"

	# offer the file
	echo "Offering the file: $1"
	echo  $msg|nc $2 2000 || (echo "host not listening!";exit 1)

	sleep .5

	# wait for the response
	res=`nc -l 2000`
	echo $res

	if [[ "$res" == "y" ]]
	then
       		echo "File accepted! Uploading $1..."
        	sleep .5
        	cat "$1"|pv -s $sizeb|nc $2 2000
        	echo "Success!"
	else
        	echo "File rejected!"
	fi
#ajuda	
else
	ajuda

fi

