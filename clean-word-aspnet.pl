#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper; #for debug output
use File::Slurp;

#package WordCleaner;

print "Script for cleaning word cruft from asp.net files\n";
print "Tim Abell 2009\n";

# get arguments
# arg1 is text file with one regex per line to be run
# the following args is the list of files to process

my $regexFileName = shift(@ARGV);
my @filesToProcess = @ARGV;

#warn Dumper \@filesToProcess;
#my $name = 'tim';
#warn Dumper \$name;

my @regexs = getRegexList();
print "loaded " . length(@regexs) . " regular expressions to run\n";

print "processing files ...\n";
foreach my $targetFile (@filesToProcess)
{
	print "processing file $targetFile ...\n";
	processFile($targetFile)
}



## subroutines ##

sub getRegexList
{
	# open regex file and read regex list
	print "loading regex list from $regexFileName ...\n";
	open (my $regexfh, $regexFileName) or die "could not open $regexFileName\n";
	my @regexList = ();
	while(<$regexfh>)
	{
		my $regex = $_;
		chomp($regex);
		if ($regex and (substr($regex,0,1) ne "#"))
		{
			push(@regexList, $regex);
		}
	}
	close($regexfh) or die "Could not close $regexFileName\n";
	return @regexList;
}

sub processFile
{
	my $targetFilename = $_[0];
	print "reading file contents ...\n";
	my $fileData = read_file($targetFilename);
#	warn Dumper \$fileData;
	print "applying regexes ...\n";
	my $cleanedData = $fileData;
	foreach my $regex (@regexs)
	{
		print "applying $regex\n";
#		warn Dumper $regex;
		eval "\$cleanedData =~ $regex";
	}
	print "writing back to file ...\n";
	write_file($targetFilename, $cleanedData);
#	warn Dumper \$cleanedData;
}

