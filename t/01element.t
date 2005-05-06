#!/usr/bin/env perl -w
# $Id: 01element.t,v 1.1 2005/05/06 01:58:08 don Exp $

use strict;

# main
{
    use Test;
    BEGIN { plan tests => 3 }
    
    use XML::Parser::Wrapper;

    my $xml = q{<store><field name="" class="Hash" id="a"><field name="array1" class="Array" id="b"><element name="" class="String" id="c">data with ]]&gt;</element><element name="" class="String" id="d">another element</element></field><field name="test1" class="String" id="e">val1</field><field name="test2" class="String" id="f">val2</field><field name="test3" class="String" id="g">val&gt;3</field></field></store>};

    my $root = XML::Parser::Wrapper->new($xml);

    ok($root->name eq 'store');
    ok($root->kid('field')->attribute('id') eq $root->kids('field')->[0]->attribute('id'));
    ok($root->kid('field')->kid('field')->kid('element')->text eq 'data with ]]>');
}

exit 0;

###############################################################################
# Subroutines

