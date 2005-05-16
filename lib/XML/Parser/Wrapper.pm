# -*-perl-*-
# Creation date: 2005-04-23 22:39:14
# Authors: Don
# Change log:
# $Id: Wrapper.pm,v 1.7 2005/05/16 14:29:10 don Exp $
#
# Copyright (c) 2005 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

 XML::Parser::Wrapper - A simple object wrapper around XML::Parser

=head1 SYNOPSIS

 use XML::Parser::Wrapper;

 my $xml = qq{<foo><head id="a">Hello World!</head><head2><test_tag id="b"/></head2></foo>};
 my $root = XML::Parser::Wrapper->new($xml);

 my $root2 = XML::Parser::Wrapper->new({ file => '/tmp/test.xml' });

 my $root_tag_name = $root->name;
 my $roots_children = $root->elements;

 foreach my $element (@$roots_children) {
     if ($element->name eq 'head') {
         my $id = $element->attr('id');
         my $hello_world_text = $element->text; # eq "Hello World!"
     }
 }

 my $head_element = $root->element('head2');
 my $head_elements = $root->elements('head2');
 my $test = $root->element('head2')->element('test_tag');

=head1 DESCRIPTION

 XML::Parser::Wrapper provides a simple object around XML::Parser
 to make it more convenient to deal with the parse tree returned
 by XML::Parser.

=head1 METHODS

=cut

use strict;
use XML::Parser ();

{   package XML::Parser::Wrapper;

    use vars qw($VERSION);
    
    $VERSION = '0.03';

=pod

=head2 new($xml), new({ file => $filename })

 Calls XML::Parser to parse the given XML and returns a new
 XML::Parser::Wrapper object using the parse tree output from
 XML::Parser.

=cut

    # Takes the 'Tree' style output from XML::Parser and wraps in in objects.
    # A parse tree looks like the following:
    #
    #          [foo, [{}, head, [{id => "a"}, 0, "Hello ",  em, [{}, 0, "there"]],
    #                      bar, [         {}, 0, "Howdy",  ref, [{}]],
    #                        0, "do"
    #                ]
    #          ]
    sub new {
        my $proto = shift;
        my $arg = shift;
        my $parser = XML::Parser->new(Style => 'Tree');
        my $tree = [];
        if (ref($arg) eq 'HASH') {
            if (exists($arg->{file})) {
                $tree = $parser->parsefile($arg->{file});
            }
        } else {
            $tree = $parser->parse($arg);
        }
        my $self = bless $tree, ref($proto) || $proto;
        return $self;
    }

    sub new_element {
        my $proto = shift;
        my $tree = shift || [];

        return bless $tree, ref($proto) || $proto;
    }

=pod

=head2 name()

 Returns the name of the element represented by this object.

 Aliases: tag(), getName(), getTag()

=cut
    sub tag {
        my $tag = shift()->[0];
        return '' if $tag eq '0';
        return $tag;
    }
    *name = \&tag;
    *getTag = \&tag;
    *getName = \&tag;

=pod

=head2 is_text()

 Returns a true value if this element is a text element, false
 otherwise.

 Aliases: isText()

=cut
    sub is_text {
        return shift()->[0] eq '0';
    }
    *isText = \&is_text;

=pod

=head2 text()

 If this element is a text element, the text is returned.
 Otherwise, return the text from the first child text element, or
 undef if there is not one.

 Aliases: content(), getText(), getContent()

=cut
    sub text {
        my $self = shift;
        if ($self->is_text) {
            return $self->[1];
        } else {
            my $kids = $self->kids;
            foreach my $kid (@$kids) {
                return $kid->text if $kid->is_text;
            }
            return undef;
        }
    }
    *content = \&text;
    *contents = \&text;
    *getText = \&text;
    *getContent = \&text;
    *getContents = \&text;

=pod

=head2 html()

 Like text(), except HTML-escape the text (escape &, <, >, and ")
 before returning it.

 Aliases: content_html(), getContentHtml()

=cut
    sub html {
        my $self = shift;

        return $self->escape_html($self->text);
    }
    *content_html = \&html;
    *getContentHtml = \&html;

=pod

=head2 xml()

 Like text(), except XML-escape the text (escape &, <, >, and ")
 before returning it.

 Aliases: content_xml(), getContentXml()

=cut
    sub xml {
        my $self = shift;

        return $self->escape_xml($self->text);
    }
    *content_xml = \&html;
    *getContentXml = \&html;

=pod

=head2 attributes(), attributes($name1, $name2, ...)

 If no arguments are given, returns a hash of attributes for this
 element.  If arguments are present, an array of corresponding
 attribute values is returned.  Returns an array in array context
 and an array reference if called in scalar context.

 E.g.,

     <field name="foo" id="42">bar</field>

     my ($name, $id) = $element->attributes('name', 'id');

 Aliases: attrs(), getAttributes(), getAttrs()

=cut
    sub attributes {
        my $self = shift;
        my $val = $self->[1];

        if (ref($val) eq 'ARRAY' and scalar(@$val) > 0) {
            my $attr = $val->[0];
            if (@_) {
                my @keys;
                if (ref($_[0]) eq 'ARRAY') {
                    @keys = @{$_[0]};
                } else {
                    @keys = @_;
                }
                return wantarray ? @$attr{@keys} : [ @$attr{@keys} ];
            }
            return wantarray ? %$attr : $attr;
        } else {
            return {};
        }
    }
    *attrs = \&attributes;
    *getAttributes = \&attributes;
    *getAttrs = \&attributes;

=pod

=head2 attribute($name)

 Similar to attributes(), but only returns one value.

 Aliases: attr(), getAttribute(), getAttr()

=cut
    sub attribute {
        my $self = shift;
        my $attr_name = shift;
        return $self->attributes()->{$attr_name};
    }
    *attr = \&attribute;
    *getAttribute = \&attribute;
    *getAttr = \&attribute;

=pod

=head2 elements(), elements($element_name)

 Returns an array of child elements.  If $element_name is passed,
 a list of child elements with that name is returned.

 Aliases: getElements(), kids(), getKids(), children(), getChildren()

=cut
    sub kids {
        my $self = shift;
        my $tag = shift;
        
        my $val = $self->[1];
        my $i = 1;
        my $kids = [];
        if (ref($val) eq 'ARRAY') {
            my $stop = $#$val;
            while ($i < $stop) {
                my $this_tag = $val->[$i];
                if (defined($tag)) {
                    push @$kids, XML::Parser::Wrapper->new_element([ $this_tag, $val->[$i + 1] ])
                        if $this_tag eq $tag;
                } else {
                    push @$kids, XML::Parser::Wrapper->new_element([ $this_tag, $val->[$i + 1] ]);
                }
                
                $i += 2;
            }
        }
        
        return wantarray ? @$kids : $kids;
    }
    *elements = \&kids;
    *getKids = \&kids;
    *getElements = \&kids;
    *children = \&kids;
    *getChildren = \&kids;

=pod

=head2 first_element(), first_element($element_name)

 Returns the first child element of this element.  If
 $element_name is passed, returns the first child element with
 that name is returned.

 Aliases: getFirstElement(), kid(), first_kid()

=cut
    sub kid {
        my $self = shift;
        my $tag = shift;
        
        my $val = $self->[1];
        if (ref($val) eq 'ARRAY') {
            if (defined($tag)) {
                my $i = 1;
                my $stop = $#$val;
                while ($i < $stop) {
                    my $kid;
                    my $this_tag = $val->[$i];
                    if ($this_tag eq $tag) {
                        return XML::Parser::Wrapper->new_element([ $this_tag, $val->[$i + 1] ]);
                    }
                    $i += 2;
                }
                return undef;
            } else {
                return XML::Parser::Wrapper->new_element([ $val->[1], $val->[2] ]);
            }
        } else {
            return $val;
        }
    }
    *first_element = \&kid;
    *getFirstElement = \&kid;
    *first_kid = \&kid;

=pod

=head2 first_element_if($element_name)

 Like first_element(), except if there is no corresponding child,
 return an object that will work instead of undef.  This allows
 for reliable chaining, e.g.

 my $class = $root->kid_if('field')->kid_if('field')->kid_if('element')
              ->kid_if('field')->attribute('class');

 Aliases: getFirstElementIf(), kidIf(), first_kid_if()

=cut
    sub kid_if {
        my $self = shift;
        my $tag = shift;
        my $kid = $self->kid($tag);

        return $kid if defined $kid;

        return XML::Parser::Wrapper->new_element([ undef, [ {} ] ]);
    }
    *kidIf = \&kid_if;
    *first_element_if = \&kid_if;
    *first_kid_if = \&kid_if;
    *getFirstElementIf = \&kid_if;

    sub escape_html {
        my ($self, $text) = @_;
        return undef unless defined $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;

        return $text;
    }

    sub escape_xml {
        my ($self, $text) = @_;
        return undef unless defined $text;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;

        return $text;
    }

}

1;

__END__

=pod

=head1 EXAMPLES


=head1 AUTHOR

 Don Owens <don@owensnet.com>

=head1 CONTRIBUTORS

 David Bushong

=head1 COPYRIGHT

 Copyright (c) 2003-2005 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 0.03

=cut
