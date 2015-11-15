
#
################################################################
# findRelativePath
################################################################
sub findRelativePath {
    my ($dirName, $rootName) = @_;
    my $relDirName = substr($dirName, length($rootName) + 1);
 
    #print("AAA - relDirName = '$relDirName'\n");

    return ($relDirName);
}


################################################################
# findDirContent
################################################################
sub findDirContent {
    my ($dirName) = @_;
    my @contents = ();

    opendir DIR, $dirName or return;
    @contents =
        map "$dirName$_",
        sort grep !/^\.\.?$/,
        readdir DIR;
    closedir DIR;

    return (@contents);
}

################################################################
# createDestinationFolder
################################################################
sub createDestinationFolder {
    my ($dirName) = @_;
    my $driveName;
    my $pathName;

    if( -e $dirName) {
	print("Destination folder '$dirName' exists\n");
	return (0);
    }
    else {
	## create the destination folder
	print("Creating the destination folder '$dirName'\n");

	# We have to strip off the drive: portion before starting
	($driveName, $pathName) = split( /:\\/, $dirName);
	$driveName = $driveName . ":\\";

	createSubFolders($pathName, $driveName);
 	return (1);
    }
}

################################################################
# createSubFolders
################################################################
sub createSubFolders {
    my ($dirName, $rootFolder) = @_;
    my @paths;
    my $path = $rootFolder;
    my $tmpPath;
    my $lastDirName = "";

    # If the dirName is the same as before, then don't waste time
    if ($dirName ne $lastDirName) {

        # Assume that the $dirName is a hierarchical name, so create each folder needed
        @paths = split( /\\/, $dirName);

        foreach $tmpPath (@paths) {
	    $path = $path . "\\" . $tmpPath;
            #print("AAA - path is '$path'\n");
            if(! -e $path) {
	        ## create the destination folder
	        print("\tCreating the folder '$path'\n");
	        mkdir($path);
	    }
        }

	$lastDirName = $dirName;
    }
}
################################################################
# createWantedNames
# Syntax of the mapping file is:
# # <Comment>
# Name		This translates to s/^Name*/Name/
# Name1:Name2	This translates to s/^Name1*/Name2/
# Note that Name2 can refer to a hierarchic path. (e.g. Name1:Name2\Name3)
################################################################
sub createWantedNames {
    my ($srcFolder, $wantedFoldersFileName, $wantedFolderName) = @_;
    %namesWanted;
    my $tmpFileName;
    my $dirNameWanted;
    my $tmpKey;
    my $searchString;
    my $name1;
    my $name2;

    ## open up the file that contains the dirNames wanted
    if( $wantedFolderName ne "none") {
	($name1, $name2) = parseSearchString( $wantedFolderName );
        $namesWanted{ $name2 } = $name1;
    }
    else {
        $tmpFileName = "$srcFolder\\$wantedFoldersFileName";
        print("Reading the wanted Folders file '$tmpFileName'\n");
        open(IN, "$tmpFileName") or die "Can't open '$tmpFileName' for read: $!";
        while ($line = <IN>) {
	    ($searchString) = split( / *$/, $line);
	    #print("AAA - searchString = '$searchString'\n");

	    # Ignore comment lines and blank lines in the file
	    if($searchString !~ /\s*#.*/ && $searchString !~ /^\n/) {

		# Here if not a comment
	   	($name1, $name2) = parseSearchString( $searchString );

	        #Check to see if these names have already been entered into the file
	        for $tmpKey (sort keys %namesWanted) {
		    if( lc($namesWanted{ $tmpKey }) eq lc($name1) ) {
		        print("\nERROR: Found duplicate search string (Name1) '$name1' in '$wantedFoldersFileName'\n");
		        exit 1;
		    }
		    elsif( lc($tmpKey) eq lc($name2) ) {
		        print("\nERROR: Found duplicate entry for target dirName (Name2) '$name2' in '$wantedFoldersFileName'\n");
		        exit 1;
		    }
	        }

		# Check to see if name2 is supposed to be hierarchic. If yes, then escape any '\' found
		$name2 =~ s/\s*\\/\\\\/g;
		#print ("AAA - name2 = '$name2'\n");
	        $namesWanted{ $name2 } = $name1;
	    }

        }
        close (IN );
    }

    return (%namesWanted);
}

################################################################
# parseSearchString
################################################################
sub parseSearchString {
    my ($searchString) = @_;
    my $name1 = "";
    my $name2 = "";

    # Is line of the form '<Name>:<Name>' ?
    if($searchString =~ m/^\s*(.+) *:\s*(.+)\s*$/) {
	# Here if yes.	
	$name1 = $1;
	$name2 = $2;
	$name1 =~ s/\s*$//; # The prior search doesn't strip out white space before the '#'
	#print("TwoMatch - Name1 = '$name1', Name2 = '$name2'\n");
    }
    #Is line of the form '<Name>:' (which is really a two name case that the above search doesn't catch) ?
    elsif ($searchString =~ m/^\s*(.+) *:\s*$/) {
	#Here if yes.
	$name1 = $1;
	$name2 = $1;
	#print("TwoMatch - Name1 = '$name1', Name2 = '$name2'\n");
    }
    #Is line of the form '<Name>' ?
    elsif ($searchString =~ /^\s*(.+)\s*$/) {
	#Here if yes. $1 is the search string
	$name1 = $1;
	$name2 = $1;
	#print("OneMatch - Name1 = '$name1'\n");
    }
    else {
	# Here if invalid syntax
	print("ERROR: parseSearchString - Invalid syntax in string 'parseSearchString'\n");
	exit 1;
    }

    return($name1, $name2);
}

################################################################
# oneDirMatch
################################################################
sub oneDirMatch {
    my ($srcDirName, $searchName, $targetName) = @_;
    my @pathParts;
    my $folderName;

    #Strip out the folder name from the srcDirName ("aaa\bbb\folderName")
    @pathParts = split(/\\/, $srcDirName);
    $folderName = pop( @pathParts);

    #print("oneDirMatch: folderName = '$folderName', searchName= '$searchName', targetName = '$targetName'\n");

    if ($folderName =~ /^$searchName.*/i) {
	#print("Found Dir match for '$srcDirName'. Returning the name '$targetName'\n");
	return ( $targetName );
    }
    else {
        #print("'$srcDirName' didn't match the search pattern '$searchName'\n");
        return ( "none" );
    }
}
################################################################
# trim
################################################################
sub trim {
	my ($string) = @_;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

################################################################
# parseCommandLine
################################################################
sub parseCommandLine {
    my (%SWITCHES) = @_;
    my $numCmdLineArgs = scalar(@ARGV);
    my %cmdLineArgs = @ARGV;
    my $switch;
    my $tmpSwitch;
    my %cmdLineVars;
    my $debug = 1;
    my $value;

    #initialize the global variables
    $cmdLineVars{"srcFolder"} = "C:\\Scanned_Pictures";
    $cmdLineVars{"destFolder"} = "";
    $cmdLineVars{"outputFolder"} = "";
    $cmdLineVars{"wantedFolder"} = "";
    $cmdLineVars{"finalFolder"} = "";
    $cmdLineVars{"wantedFoldersFileName"} = "aberscanWantedFolderMappings.txt";
    $cmdLineVars{"wantedFolderName"} = "none";
    $cmdLineVars{"fileRootName"} = "photo";
    $cmdLineVars{"fileStartNumber"} = 1;
    $cmdLineVars{"photoMappingFile"} = "aberscanPhotoMappings.txt";
    $cmdLineVars{"includeSource"} = 0;
    $cmdLineVars{"useOrigFileName"} = 0;
    $cmdLineVars{"removeOrigFileName"} = 0;
    $cmdLineVars{"createOutputDir"} = 1;
    $cmdLineVars{"tagFileName"} = "aberscanAddresses.csv";

    # add a default setting that isn't in the command line
    $cmdLineVars{"rootDestFolder"} = "C:\\AberscanInProgress";

    usage(%SWITCHES) if (defined($cmdLineArgs{-help}));

    if ($numCmdLineArgs % 2 != 0) {
        print STDERR "\nERROR: One or more switches don't have associated values\n";
        helpAndExit();
    }

    # filter out invalid options
    for $switch (keys %cmdLineArgs) {
         if (! defined($SWITCHES{$switch})) {
	      print STDERR "\nERROR: invalid switch '$switch'\n";
	      helpAndExit();
         }
    }

    # verify that required options are all specified,
    for $switch (keys %SWITCHES) {
        if ($SWITCHES{$switch} eq 'required') {
	      if (! defined $cmdLineArgs{$switch}) {
	          print STDERR "\nERROR: missing required switch '$switch <value>'\n";
	          helpAndExit();
	      }
        }
    }

    # Now parse what was specified on the command line
    for $switch (keys %SWITCHES) {
        if (defined $cmdLineArgs{$switch}) {
	    $tmpSwitch = $switch;
	    $tmpSwitch =~ s/-//;
	    $cmdLineVars{$tmpSwitch} = $cmdLineArgs{$switch};
	    if( $switch eq "-includeSource") { 
    		if ($cmdLineVars{"includeSource"} != 1 && $cmdLineVars{"includeSource"} != 0) {
		    $value = $cmdLineVars{"includeSource"};
		    print STDERR "\nERROR: invalid value '$value' for the -includeSource switch\n";
		    helpAndExit();
    		}
	    }
	    if( $switch eq "-useOrigFileName") { 
    		if ($cmdLineVars{"useOrigFileName"} != 1 && $cmdLineVars{"useOrigFileName"} != 0 && $cmdLineVars{"useOrigFileName"} != 2) {
		    $value = $cmdLineVars{"useOrigFileName"};
		    print STDERR "\nERROR: invalid value '$value' for the -useOrigFileName switch\n";
		    helpAndExit();
    		}
	    }
	    if( $switch eq "-removeOrigFileName") { 
    		if ($cmdLineVars{"removeOrigFileName"} != 1 && $cmdLineVars{"removeOrigFileName"} != 0) {
		    $value = $cmdLineVars{"removeOrigFileName"};
		    print STDERR "\nERROR: invalid value '$value' for the -removeOrigFileName switch\n";
		    helpAndExit();
    		}
	    }
	    if( $switch eq "-createOutputDir") { 
    		if ($cmdLineVars{"createOutputDir"} != 1 && $cmdLineVars{"createOutputDir"} != 0) {
		    $value = $cmdLineVars{"createOutputDir"};
		    print STDERR "\nERROR: invalid value '$value' for the -createOutputDir switch\n";
		    helpAndExit();
    		}
	    }

	    #fix up the disk name on paths
            if ($switch eq "-destFolder") {
	        $cmdLineVars{"destFolder"} =~ s/c:/C:/;
            }

            if ($switch eq "-srcFolder" ) { 
	        $cmdLineVars{"srcFolder"} =~ s/c:/C:/;
            }

            if ($switch eq "-outputFolder") {
	        $cmdLineVars{"outputFolder"} =~ s/c:/C:/;
            }

            if ($switch eq "-finalFolder") {
	        $cmdLineVars{"finalFolder"} =~ s/c:/C:/;
	    }
	}
    }

    if ($debug == 1) {
	print STDOUT "Command Line Summary:\n";
        for $switch (sort keys %SWITCHES) {
	    $tmpSwitch = $switch;
	    $tmpSwitch =~ s/-//;
	    if($tmpSwitch ne "help") { print STDOUT "\t$tmpSwitch = '$cmdLineVars{$tmpSwitch}'\n"; }
	}
    }

return (%cmdLineVars);
}

################################################################
# helpAndExit
#
# Desc: Print out the command Line Usage instructions
################################################################
sub helpAndExit {
    print STDERR "\tType '$0 -help yes' for a full description of command line options\n";
    exit 1;
} #helpAndExit

################################################################
# usage
#
# Desc: Print out the command Line Usage instructions
################################################################
sub usage {
    my (%SWITCHES) = @_;
    my $usageText = "";
    my $switch;

    print STDERR "Options can contain the following:\n";

    for $switch (sort keys %SWITCHES) {
	if( $switch eq "-srcFolder") { 
print STDERR "\n\n -srcFolder <folderNamer>
\tThe top level source folder that you want to recurse. The folders to
\tbe searched for are listed in the file specified using the 
\t'wantedFoldersFileName'
\tDefault: C:/Scanned_Pictures";
	}
	elsif( $switch eq "-destFolder") { 
print STDERR "\n\n -destFolder <folderName>
\tThe name of the folder where you want the folder copy to go, with 
\trenumbered files";
	}
	elsif( $switch eq "-outputFolder") { 
print STDERR "\n\n -outputFolder <folderName>
\tThe name of the folder where you want the (flat) output to
\tgo, along with the mapping file";
	}
	elsif( $switch eq "-finalFolder") { 
print STDERR "\n\n -finalFolder <folderName>
\tName of folder that you want subFolders created within";
	}
	elsif( $switch eq "-fileRootName") { 
print STDERR "\n\n -fileRootName <rootName>
\tThe new root name for each new file created in the output folder
\tDefault: photo";
	}
	elsif( $switch eq "-fileStartNumber") { 
print STDERR "\n\n -fileStartNumber <number>
\tThe starting number to be appended to the first file.
\tSubsequent files will increment this starting number
\tDefault: 1";
	}
	elsif( $switch eq "-photoMappingFile") { 
print STDERR "\n\n -photoMappingFile <fileName>
\tThis is the name of the file in the output folder 'outputFolder' that
\tcontains the mappings between the photo file name, and the name of 
\tthe folder where the photo is to ultimately reside once done with 
\tPhotoshop processing. The syntax of this photo mapping file is:
\t\t<Name of Final Folder>,<Name of Photo File>
\t\t<Name of Final Folder>,<Name of Photo File>
\t\t...
\tThe step of putting the photo files back into their correct folder is
\tdone using the perl script 'createEpsonFinalFolders'";
	}
	elsif( $switch eq "-wantedFoldersFileName") { 
print STDERR "\n\n -wantedFoldersFileName <fileName>
\tThis is the name of the file in the source folder 'srcFolder' that
\tcontains the search strings used to match subdirectories within the 
\tsource folder. If there is a match, then all the photos (jpg)  
\tfound recursively in that folder are copied to the output folder. 
\tThe syntax of this file is:
\t\t<FolderSearchStringToBeMatched>
\t\t<FolderSearchStringToBeMatched>
\tDefault: aberscanWantedFolderMappings.txt";
	}
	elsif( $switch eq "-wantedFolderName") { 
print STDERR "\n\n -wantedFolderName <folderName>
\tAdd a single folder name. Use this rather than creating the 
\t'aberscanWantedFolderMappings.txt' with just one name";
	}
	elsif( $switch eq "-includeSource") { 
print STDERR "\n\n -includeSource <1|0>
\tSpecifies whether the source name shows up in destination 
\tfile name - no (0), yes (1)";
	}
	elsif( $switch eq "-useOrigFileName") { 
print STDERR "\n\n -useOrigFileName <1|0>
\tSpecifies whether to keep the original file name or generate a new name 
\tfile name - no (0), yes (1), use just the text part of the name (e.g. photo) (2)";
	}
	elsif( $switch eq "-tagFileName") { 
print STDERR "\n\n -tagFileName <fileName>
\tSpecifies the name of the input tag file"; 
	}
	elsif( $switch eq "-help") { }
	else {
	    print STDERR "\nERROR: usage - cmdLine variable not known\n";
	}
    }

    exit 1;
}
1;