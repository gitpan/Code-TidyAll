#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use Code::TidyAll::t::Plugin::CSSUnminifier;
Code::TidyAll::t::Plugin::CSSUnminifier->runtests;
