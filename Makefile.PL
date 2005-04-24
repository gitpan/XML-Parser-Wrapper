#!/usr/bin/perl

# Creation date: 2005-04-24 11:29:18
# Authors: Don
# Change log:
# $Id: Makefile.PL,v 1.1 2005/04/24 19:35:24 don Exp $

use strict;

# main
{
    use ExtUtils::MakeMaker;

    WriteMakefile(
                  NAME => 'XML::Parser::Wrapper',
                  DISTNAME => 'XML-Parser-Wrapper',
                  VERSION_FROM => 'lib/XML/Parser/Wrapper.pm',
                  ABSTRACT => 'Simple object wrapper around XML::Parser',
                  AUTHOR => 'DON OWENS <don@owensnet.com>',
                  PM => { 'lib/XML/Parser/Wrapper.pm' => '$(INST_LIBDIR)/Wrapper.pm',
                        },
                  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
                  DIR => [],
                  EXE_FILES => [],
                  PREREQ_PM => { 'XML::Parser' => 0 },
                 );

}

exit 0;

###############################################################################
# Subroutines

