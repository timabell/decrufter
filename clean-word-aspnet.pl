#!/usr/bin/perl

#  Script for cleaning word cruft from asp.net files
#  Copyright (C) 2009 Tim Abell

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Data::Dumper; #for debug output
use File::Slurp;
use HTML::Parser; #for empty span remover


#package WordCleaner;

print "Script for cleaning word cruft from asp.net files\n";
print "Licensed under GPL v3. See COPYING for full licence.\n";
print "Tim Abell 2009\n";

# get arguments
# arg1 is text file with one regex per line to be run
# the following args is the list of files to process

my $regexFileName = shift(@ARGV);
my @filesToProcess = @ARGV;

my @regexs = getRegexList();
print "loaded " . length(@regexs) . " regular expressions to run\n";

print "processing files ...\n";
foreach my $targetFile (@filesToProcess)
{
	print "processing file $targetFile ...\n";
	processFile($targetFile)
}

print "finished.\n";


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
		warn $@ if $@; #show any errors
	}
	print "writing back to file ...\n";
	write_file($targetFilename, $cleanedData);
#	warn Dumper \$cleanedData;
	removeSpans($targetFilename);
}

# remove empty spans
# http://stackoverflow.com/questions/667130/how-can-i-remove-unused-nested-html-span-tags-with-a-perl-regex

sub removeSpans()
{
	print "removing empty spans from file...\n";
	my $targetFilename = $_[0];
	my @print_span;
	my @cleanedData;
	my $p = HTML::Parser->new(
		start_h => [ sub {
			my ($text, $name, $attr) = @_;
			if ( $name eq 'span' ) {
				my $print_tag = %$attr;
				push @print_span, $print_tag;
				return if !$print_tag;
			}
			push(@cleanedData, $text);
		}, 'text,tagname,attr'],
		end_h => [ sub {
			my ($text, $name) = @_;
			if ( $name eq 'span' ) {
				return if !pop @print_span;
			}
			push(@cleanedData, $text);
		}, 'text,tagname'],
		default_h => [ sub { push(@cleanedData, shift) }, 'text'],
	);
	$p->parse_file($targetFilename) or die "Err: $!";
	$p->eof;
	print "writing back to file ...\n";
	write_file($targetFilename, @cleanedData);
}

