
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/tidyall',
    'lib/Code/TidyAll.pm',
    'lib/Code/TidyAll/Cache.pm',
    'lib/Code/TidyAll/Config/INI/Reader.pm',
    'lib/Code/TidyAll/Git/Precommit.pm',
    'lib/Code/TidyAll/Git/Prereceive.pm',
    'lib/Code/TidyAll/Git/Util.pm',
    'lib/Code/TidyAll/Plugin.pm',
    'lib/Code/TidyAll/Plugin/CSSUnminifier.pm',
    'lib/Code/TidyAll/Plugin/JSBeautify.pm',
    'lib/Code/TidyAll/Plugin/JSHint.pm',
    'lib/Code/TidyAll/Plugin/JSLint.pm',
    'lib/Code/TidyAll/Plugin/JSON.pm',
    'lib/Code/TidyAll/Plugin/MasonTidy.pm',
    'lib/Code/TidyAll/Plugin/PHPCodeSniffer.pm',
    'lib/Code/TidyAll/Plugin/PerlCritic.pm',
    'lib/Code/TidyAll/Plugin/PerlTidy.pm',
    'lib/Code/TidyAll/Plugin/PodChecker.pm',
    'lib/Code/TidyAll/Plugin/PodSpell.pm',
    'lib/Code/TidyAll/Plugin/PodTidy.pm',
    'lib/Code/TidyAll/Plugin/SortLines.pm',
    'lib/Code/TidyAll/Result.pm',
    'lib/Code/TidyAll/SVN/Precommit.pm',
    'lib/Code/TidyAll/SVN/Util.pm',
    'lib/Code/TidyAll/Util.pm',
    'lib/Code/TidyAll/Util/Zglob.pm',
    'lib/Test/Code/TidyAll.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/Basic.t',
    't/Conf.t',
    't/Zglob.t',
    't/author-Git.t',
    't/author-Plugin-CSSUnminifier.t',
    't/author-Plugin-JSBeautify.t',
    't/author-Plugin-JSHint.t',
    't/author-Plugin-JSLint.t',
    't/author-Plugin-MasonTidy.t',
    't/author-Plugin-PHPCodeSniffer.t',
    't/author-Plugin-PerlCritic.t',
    't/author-Plugin-PerlTidy.t',
    't/author-Plugin-PodChecker.t',
    't/author-Plugin-PodSpell.t',
    't/author-Plugin-PodTidy.t',
    't/author-Plugin-SortLines.t',
    't/author-Util.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-tidy-and-critic.t',
    't/lib/Code/TidyAll/Test/Class.pm',
    't/lib/Code/TidyAll/Test/Plugin/AToZ.pm',
    't/lib/Code/TidyAll/Test/Plugin/CheckUpper.pm',
    't/lib/Code/TidyAll/Test/Plugin/RepeatFoo.pm',
    't/lib/Code/TidyAll/Test/Plugin/ReverseFoo.pm',
    't/lib/Code/TidyAll/Test/Plugin/UpperText.pm',
    't/lib/Test/Code/TidyAll/Basic.pm',
    't/lib/Test/Code/TidyAll/Conf.pm',
    't/lib/Test/Code/TidyAll/Git.pm',
    't/lib/Test/Code/TidyAll/Plugin.pm',
    't/lib/Test/Code/TidyAll/Plugin/CSSUnminifier.pm',
    't/lib/Test/Code/TidyAll/Plugin/JSBeautify.pm',
    't/lib/Test/Code/TidyAll/Plugin/JSHint.pm',
    't/lib/Test/Code/TidyAll/Plugin/JSLint.pm',
    't/lib/Test/Code/TidyAll/Plugin/MasonTidy.pm',
    't/lib/Test/Code/TidyAll/Plugin/PHPCodeSniffer.pm',
    't/lib/Test/Code/TidyAll/Plugin/PerlCritic.pm',
    't/lib/Test/Code/TidyAll/Plugin/PerlTidy.pm',
    't/lib/Test/Code/TidyAll/Plugin/PodChecker.pm',
    't/lib/Test/Code/TidyAll/Plugin/PodSpell.pm',
    't/lib/Test/Code/TidyAll/Plugin/PodTidy.pm',
    't/lib/Test/Code/TidyAll/Plugin/SortLines.pm',
    't/lib/Test/Code/TidyAll/SVN.pm',
    't/lib/Test/Code/TidyAll/Util.pm',
    't/lib/Test/Code/TidyAll/Zglob.pm',
    't/release-cpan-changes.t',
    't/release-pod-no404s.t',
    't/release-pod-syntax.t'
);

notabs_ok($_) foreach @files;
done_testing;
