use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'license' => 'perl',
  'add_to_cleanup' => ['Hook-LexWrap-*'],
  'build_requires' => {
    'Test::More' => 0
  },
  'dist_author' => 'Damian Conway (damian@conway.org)',
  'module_name' => 'Hook::LexWrap',
  'requires' => {
    'perl' => '5.006'
  },
  'meta_merge' => {
    'resources' => {
      'repository' => 'http://github.com/chorny/Hook-LexWrap',
    }
  },
  'dist_version_from' => 'lib/Hook/LexWrap.pm'
  'auto_configure_requires' => 0,
);

$build->create_build_script();
