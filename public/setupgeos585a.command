#!/bin/sh

# Setup a working direcory for MATLAB directly under the user's home
# directory containg all the necessary files for the Applied Time
# Series Analysis course.

# Copyright (C) 2009 Laboratory of Tree-Ring Research

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Written by Martin Munro.

# Pattern for the path as originally hard-coded into the .m and other files
datdir="[Cc]:\\\\[Gg]eos585a\\\\"

# Default name of input data file hard-coded into the .m and other files
datfile="spring09"

# The following shell variables can be overriden from the environment........

# The default directory for input data
if [ "x$SETUP_WORKING_DIRECTORY" = "x" ]; then 
    workingdirectory=geos585a
else
    workingdirectory=$SETUP_WORKING_DIRECTORY
fi

# The default data file name
if [ "x$SETUP_DATA_FILENAME" != "x" ]; then 
    datafilename=$SETUP_DATA_FILENAME
elif [ "x$USER" != "x" ]; then 
    datafilename=$USER
else
	datafilename="${datfile}_copy"
fi

# Name of the program to uncompress pkzip files
if [ "x$SETUP_UNZIP_PROGRAM" = "x" ]; then 
    unzipprogram=unzip
else
    unzipprogram=$SETUP_UNZIP_PROGRAM
fi

# Name of the local curl program (for downloading)
if [ "x$SETUP_CURL_PROGRAM" = "x" ]; then 
    curlprogram=curl
else
    curlprogram=$SETUP_CURL_PROGRAM
fi

# Name of the local wget program (for downloading)
if [ "x$SETUP_WGET_PROGRAM" = "x" ]; then 
    wgetprogram=wget
else
    wgetprogram=$SETUP_WGET_PROGRAM
fi

# Name of the pkzip-compressed archive containing all the files
if [ "x$SETUP_ZIP_FILENAME" = "x" ]; then 
    zipfilename=tsfiles.zip
else
    zipfilename=$SETUP_ZIP_FILENAME
fi

# URL used to test downloads & as the root of the file retrieval URL
if [ "x$SETUP_BASE_FILE_URL" = "x" ]; then 
    baseurl="http://www.ltrr.arizona.edu/~dmeko/"
else
    baseurl=$SETUP_BASE_FILE_URL
fi

# URL used to automatically download the .zip file
if [ "x$SETUP_ZIP_FILE_URL" = "x" ]; then 
    zipfileurl="$baseurl/$zipfilename"
else
    zipfileurl=$SETUP_ZIP_FILE_URL
fi

# Make sure an unadorned name really is in the current directory
(unset CDPATH) > /dev/null 2>&1 && unset CDPATH

# Start in the user's home directory
cd > /dev/null 2>&1 ||
{
    echo "*** Unable to change to the home directory." >&2
    exit 1
}

# Check for the unzip program
$unzipprogram -v > /dev/null 2>&1 ||
{
    echo "*** Cannot find the $unzipprogram to uncompress .zip files." >&2
    exit 1
}

# Check for a pre-existing directory
if [ -d $workingdirectory ]; then
    echo "*** A directory called $workingdirectory already exists." >&2
    echo "If this is an old working directory for this course," >&2
    echo "try re-naming it to something else, then try again." >&2
    exit 1
fi

# Has the user already downloaded the zip file?
if [ -r $zipfilename ]; then
    echo "Found the zipped file $zipfilename." >&2
    setup_has_zipfile=YES
fi

# Check for file download tools.
if $curlprogram $baseurl > /dev/null 2>&1 ; then
    echo "Found the $curlprogram program (for downloading files)." >&2
    setup_has_curl=YES
fi
if $wgetprogram --version > /dev/null 2>&1 ; then
    echo "Found the $wgetprogram program (for downloading files)." >&2
    setup_has_wget=YES
fi

# Give up if there's no way to find the .zip file
if [ "x$setup_has_zipfile" = "x" ] && [ "x$setup_has_curl" = "x" ] && [ "x$setup_has_wget" = "x" ]; then
    echo "*** Found neither the file $zipfilename in your home directory," >&2
    echo "nor any way to automatically download it from the Internet at" >&2
    echo "$zipfileurl" >&2
    exit 1
fi

# Try downloading the .zip file if it's not alredy present
if [ "x$setup_has_zipfile" = "x" ] && [ "x$setup_has_curl" != "x" ] &&
    $curlprogram $zipfileurl > $zipfilename ; then
    setup_has_zipfile=YES
fi
if [ "x$setup_has_zipfile" = "x" ] && [ "x$setup_has_wget" != "x" ] &&
    $wgetprogram --no-clobber $zipfileurl ; then
    setup_has_zipfile=YES
fi
if [ "x$setup_has_zipfile" = "x" ]; then
    echo "*** Was unable to download the file $zipfilename from the Internet at" >&2
    echo "$zipfileurl" >&2
    exit 1
fi
# Note that wget will always use the filename from the URL, 
# which may conflict with $zipfilename. Investigate this if the download works,
# but subsequent steps can't find the .zip file.

# Create what will be the course working directory
mkdir $workingdirectory > /dev/null 2>&1  ||
{
    echo "*** Unable to create to the $workingdirectory directory." >&2
    exit 1
}

# Change to the working directory, or clean up
cd $workingdirectory > /dev/null 2>&1 ||
{
    echo "*** Unable to change to the $workingdirectory directory." >&2
    rmdir $workingdirectory > /dev/null 2>&1
    exit 1
}

# Unzip the .zip archive within the working directory, or clean up
$unzipprogram ../$zipfilename > /dev/null 2>&1 ||
{
    echo "*** Unable to unzip $zipfilename in the $workingdirectory directory." >&2
    cd ..  > /dev/null 2>&1
    # Dangerous, so display any errors
    rm -rf $workingdirectory
    exit 1
}

# Search & replace the hard-coded working directory & file paths in the files
ourworking=`pwd`
for f in * ; do
    modifiedf="${f}_setback"
    if sed "s|$datdir|$ourworking/|g" $f | sed "s|datfile='$datfile'|datfile='$datafilename'|" > $modifiedf ; then
        mv $modifiedf $f > /dev/null 2>&1 || { echo "Warning: kept old version of $f" >&2 ; }
    else
        echo "Warning: could not edit $f" >&2
    fi
done
# Note that if this last step didn't work we just leave whatever mess was produced.