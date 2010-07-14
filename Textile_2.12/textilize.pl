#!/usr/bin/perl

use	Text::Textile;

my $text;
{
	local $/;               # Slurp the whole file
	$text = <>;
}

my $tt = new Text::Textile;
$tt->charset("utf-8");
print $tt->process($text);