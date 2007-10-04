# -*-perl-*-
# Creation date: 2005-04-23 22:39:14
# Authors: Don
# Change log:
# $Id: Wrapper.pm,v 1.16 2007/10/04 02:04:29 don Exp $
#
# Copyright (c) 2005,2007 Don Owens
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

 my $new_element = $root->add_child('test4', { attr1 => 'val1' });
 $new_element->add_child('child', { myattr => 'stuff' }, 'bleh');

 my $new_xml = $root->to_xml;

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
    
    $VERSION = '0.06';

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
        my $self = shift;
        if (@$self and defined($self->[0])) {
            return $self->[0] eq '0';
        }
        return;

        # return $self->[0] eq '0';
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

=head2 to_xml()

 Convert the node back to XML.  The ordering of attributes may
 not be the same as in the original XML, and CDATA sections may
 become plain text elements, or vice versa.

 Aliases: toXml()

=cut
    sub to_xml {
        my $self = shift;

        if ($self->is_text) {
            return $self->escape_xml($self->text);
        }
        
        my $attributes = $self->attributes;
        my $name = $self->name;
        my $kids = $self->kids;

        my $xml = qq{<$name};
        if ($attributes and %$attributes) {
            my @pairs;
            foreach my $key (keys %$attributes) {
                push @pairs, $key . '=' . '"' . $self->escape_xml($attributes->{$key}) . '"';
            }
            $xml .= ' ' . join(' ', @pairs);
        }
        if ($kids and @$kids) {
            $xml .= '>' . join('', map { $_->to_xml } @$kids);
            $xml .= "</$name>";
        }
        else {
            $xml .= '/>';
        }
    }
    *toXml = \&to_xml;

=pod

=head2 add_child($tag_name, \%attributes, $text_value)

 Add a child to the current node.  If $text_value is defined, it
 will be used as the text between the opening and closing tags.
 The return value is the newly created node (XML::Parser::Wrapper
 object) that can then in turn have child nodes added to it.

    my $root = XML::Parser::Wrapper->new($input);

    my $new_element = $root->add_child('test4', { attr1 => 'val1' });
    $new_element->add_child('child', { myattr => 'stuff' }, 'bleh');

 Aliases: addChild()

=cut
    sub add_child {
        my ($self, $tag_name, $attr, $val) = @_;

        unless (defined($tag_name)) {
            return undef;
        }

        my $attr_to_add;
        if ($attr and %$attr) {
            $attr_to_add = $attr;
        }
        else {
            $attr_to_add = { };
        }

        my $stuff = [ $attr_to_add ];
        # my $to_add = [ $tag_name, [ $attr_to_add ] ];
        if (defined($val)) {
            # push @{$to_add->[1]}, '0', $val;
            push @$stuff, '0', $val;
        }

        push @{$self->[1]}, $tag_name, $stuff;
        # print Data::Dumper->Dump([ $self->[1] ], [ 'index_1' ]) . "\n";

        return $self->new_element([ $tag_name, $stuff ]);
    }
    *addChild = \&add_child;

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
    *get_attributes = \&attributes;
    *get_attrs = \&attributes;

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

=pod

=head2 simple_data()

 Assume a data structure of hashes, arrays, and strings are
 represented in the xml with no attributes.  Return the data
 structure, leaving out the root tag.

=cut
    # Assume a data structure of hashes, arrays, and strings are
    # represented in the xml with no attributes.  Return the data
    # structure, leaving out the root tag.
    sub simple_data {
        my $self = shift;

        return _convert_xml_node_to_perl($self);        
    }

    sub _convert_xml_node_to_perl {
        my $node = shift;

        my $new_data;
        if ($node->is_text) {
            $new_data = $node->text;
        }
        else {
            $new_data = {};
            my $ignore_whitespace_kids;
            my $kids = $node->kids;
            my $attr = $node->attributes;

            if (scalar(@$kids) == 0) {
                return ($attr and %$attr) ? { %$attr } : undef;
            }
            elsif (scalar(@$kids) == 1) {
                if ($kids->[0]->is_text) {
                    return $kids->[0]->text;
                }
            }
            else {
                $ignore_whitespace_kids = 1;
            }

            foreach my $kid (@$kids) {
                if ($ignore_whitespace_kids and $kid->is_text and $kid->text =~ /^\s*$/) {
                    next;
                }

                my $kid_data = _convert_xml_node_to_perl($kid);
                my $node_name = $kid->name;
                if (exists($new_data->{$node_name})) {
                    unless (ref($new_data->{$node_name}) eq 'ARRAY') {
                        $new_data->{$node_name} = [ $new_data->{$node_name} ];
                    }
                    push @{$new_data->{$node_name}}, $kid_data
                }
                else {
                    $new_data->{$node_name} = $kid_data;
                }
            }

        }

        return $new_data;
    }

=pod
 
=head2 dump_simple_data($data)

 The reverse of simple_data() -- return xml representing the data
 structure passed.

=cut
    # the reverse of simple_data() -- return xml representing the data structure provided
    sub dump_simple_data {
        my $self = shift;
        my $data = shift;

        my $xml = '';
        if (ref($data) eq 'ARRAY') {
            foreach my $element (@$data) {
                $xml .= $self->dump_simple_data($element);
            }
        }
        elsif (ref($data) eq 'HASH') {
            foreach my $key (keys %$data) {
                if (ref($data->{$key}) eq 'ARRAY') {
                    foreach my $element ( @{$data->{$key}} ) {
                        $xml .= '<' . $key . '>' . $self->dump_simple_data($element)
                            . '</' . $key . '>';
                    }
                }
                else {
                    $xml .= '<' . $key . '>' . $self->dump_simple_data($data->{$key})
                        . '</' . $key . '>';
                }
            }
        }
        else {
            return $self->escape_xml($data);
        }

        return $xml;
    }

    
}

1;

__END__

=pod

=head1 EXAMPLES


=head1 AUTHOR

 Don Owens <don@regexguy.com>

=head1 CONTRIBUTORS

 David Bushong

=head1 COPYRIGHT

 Copyright (c) 2003-2007 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 0.05a

=cut
