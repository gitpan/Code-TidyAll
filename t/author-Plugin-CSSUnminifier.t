#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use lib 't/lib';
use Test::Code::TidyAll::Plugin::CSSUnminifier;
Test::Code::TidyAll::Plugin::CSSUnminifier->runtests;
