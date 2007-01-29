use ExtUtils::MakeMaker;
WriteMakefile(
	PL_FILES     => {},
	INSTALLDIRS  => 'site',
	NAME         => 'Test::TAP::Model',
	EXE_FILES    => [],
	VERSION_FROM => 'lib/Test/TAP/Model.pm',
	SIGN         => 1,
	PREREQ_PM    => {
		'Test::Harness'  => '2.64',
		'Test::More'     => '0.53',
		'Hash::AsObject' => 0,
		'Method::Alias'  => 0
	},
);
