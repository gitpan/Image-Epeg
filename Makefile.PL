use ExtUtils::MakeMaker;

$ROOT       = "/usr/local";

WriteMakefile
(
	'NAME'			=> 'Image::EPEG',
	'VERSION_FROM'	=> 'EPEG.pm',
    'PREREQ_PM'		=> {},
	($] >= 5.005 ?
		(ABSTRACT_FROM	=> 'EPEG.pm',
		AUTHOR			=> 'Michael Curtis (mcurtis@yahoo-inc.com)') : ()),
	'LIBS'			=> [''],
	'LIBS'			=> "-L$ROOT/lib -lepeg" . "$LDLIBS",
	'DEFINE'		=> '',
	'INC'			=> ''
);
