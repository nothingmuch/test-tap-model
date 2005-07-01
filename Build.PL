#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Test::TAP::Model',
	license => 'perl',
	requires => {
		'perl'				=> '>= 5.008',
	},
	build_requires => {
		'Test::More' => "0.53",
		'Method::Alias' => "0",
	},
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;

