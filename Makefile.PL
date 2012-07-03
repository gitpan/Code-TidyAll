
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Tidy and validate code in many ways at once',
  'AUTHOR' => 'Jonathan Swartz <swartz@pobox.com>',
  'BUILD_REQUIRES' => {
    'Test::Class::Most' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Code-TidyAll',
  'EXE_FILES' => [
    'bin/tidyall'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Code::TidyAll',
  'PREREQ_PM' => {
    'Capture::Tiny' => '0.12',
    'Config::INI::Reader' => '0',
    'Date::Format' => '0',
    'Digest::SHA1' => '0',
    'File::Basename' => '0',
    'File::Find' => '0',
    'File::Path' => '0',
    'File::Slurp' => '0',
    'File::Temp' => '0',
    'File::Zglob' => '0',
    'Hash::MoreUtils' => '0',
    'List::MoreUtils' => '0',
    'List::Pairwise' => '0',
    'Object::Tiny' => '0',
    'Time::Duration::Parse' => '0',
    'Try::Tiny' => '0'
  },
  'VERSION' => '0.02',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



