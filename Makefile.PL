use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Hook::LexWrap',
    AUTHOR              => 'Damian Conway (damian@conway.org)',
    VERSION_FROM        => 'lib/Hook/LexWrap.pm',
    ABSTRACT_FROM       => 'lib/Hook/LexWrap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
    },
    ($ExtUtils::MakeMaker::VERSION ge '6.31'? 
     ('LICENSE'		=> 'perl', ) : ()),
    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
     ('MIN_PERL_VERSION' => 5.006,) : ()),
    clean               => { FILES => 'Hook-LexWrap-*' },
);
