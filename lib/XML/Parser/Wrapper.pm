# -*-perl-*-
# Creation date: 2005-04-23 22:39:14
# Authors: Don
# Change log:
# $Id: Wrapper.pm,v 1.1 2005/04/24 19:35:24 don Exp $
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

 my $xml = qq{<foo><head id="a">Hello World!</head></foo>};
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
    
    $VERSION = '0.1';

=pod

=head2 new($xml), new({ file => $filename })

 Calls XML::Parser to parse the given XML and returns a new
 XML::Parser::Wrapper object using the parse tree output from
 XML::Parser.

=cut
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

=head2 elements()

 Returns an array of child elements.

 Aliases: getElements(), kids(), getKids(), children(), getChildren()

=cut
    sub kids {
        my $self = shift;
        my $val = $self->[1];

        my $i = 1;
        my $kids = [];
        if (ref($val) eq 'ARRAY') {
            my $stop = $#$val;
            while ($i < $stop) {
                my $kid;
                my $tag = $val->[$i];
                $kid = XML::Parser::Wrapper->new_element([ $tag, $val->[$i + 1] ]);
                $i += 2;
                push @$kids, $kid;
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

=head2 first_element()

 Returns the first child element of this element.

 Aliases: getFirstElement(), kid(), first_kid()

=cut
    sub kid {
        my $self = shift;
        my $val = $self->[1];
        if (ref($val) eq 'ARRAY') {
            return XML::Parser::Wrapper->new_element([ $val->[1], $val->[2] ]);
        } else {
            return $val;
        }
    }
    *first_element = \&kid;
    *getFirstElement = \&kid;
    *first_kid = \&kid;
}

1;

__END__

=pod

=head1 EXAMPLES


=head1 AUTHOR

    Don Owens <don@owensnet.com>

=head1 COPYRIGHT

    Copyright (c) 2003-2005 Don Owens

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself.

=head1 VERSION

$Id: Wrapper.pm,v 1.1 2005/04/24 19:35:24 don Exp $

=cut
