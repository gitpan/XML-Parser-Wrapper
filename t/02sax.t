#!/usr/bin/env perl

# Creation date: 2009-01-04T07:40:56Z
# Authors: don

use strict;
use warnings;

use Test;

eval 'use XML::LibXML::SAX;';
if ($@) {
    # don't have the module, so skip
    plan tests => 1;

    print "# Skipping SAX test since I can't find XML::LibXML::SAX\n";
    skip(1, 1);

    exit 0;
}

use File::Spec ();
BEGIN {
    my $path = File::Spec->rel2abs($0);
    (my $dir = $path) =~ s{(?:/[^/]+){2}\Z}{};
    unshift @INC, $dir . "/lib";
}

plan tests => 3;

use XML::Parser::Wrapper;

my $xml = qq{<response><stuff>stuff val</stuff><more><stuff><foo><stuff>Hidden Stuff</stuff></foo></stuff></more><deep><deep_var1>deep val 1</deep_var1><deep_var2>deep val 2</deep_var2></deep><stuff>more stuff</stuff><some_cdata><![CDATA[blah]]></some_cdata><tricky><![CDATA[foo]]> bar</tricky></response>};

my @text;

my $handler = sub {
    my ($root) = @_;
    
    my $text = $root->text;
    push @text, $text;
};

my $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                  handler => $handler,
                                                  start_tag => 'stuff',
                                                  # start_depth => 2,
                                                }, $xml);

ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');

@text = ();
$root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                               handler => $handler,
                                               start_tag => 'stuff',
                                               start_depth => 2,
                                             }, $xml);
ok(scalar(@text) == 1 and $text[0] eq 'Hidden Stuff');


my $file = "t/data/sax_test.xml";
if (-e $file) {
    @text = ();

    $root = XML::Parser::Wrapper->new_sax_parser({ class => 'XML::LibXML::SAX',
                                                   handler => $handler,
                                                   start_tag => 'stuff',
                                                   # start_depth => 2,
                                                 }, { file => $file });
    
    ok(scalar(@text) == 2 and $text[0] eq 'stuff val' and $text[1] eq 'more stuff');


}
else {
    skip("Skip cuz couldn't find test file", 1);
}
