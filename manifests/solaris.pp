class os::solaris {

  if $operatingsystemrelease =~ /11/ {
    #  Whoops, IPS provider support coming in Telly...
    # $ipspackages_to_have = [ 'ruby-18' ]

    # # Puppet is not in Oracle's repos and OpenCSW hasn't
    # # finished their IPS packages yet...
    # package { $ipspackages_to_have:
    #   ensure => present,
    #   before => [ File[ '/usr/bin/ruby' ], File[ '/usr/bin/gem' ] ],
    # }

    $ruby_bin_path = '/usr/ruby/1.8/bin'
  } else {

    exec { 'ensure-pkgutil':
      command => '/usr/sbin/pkgadd -d get.opencsw.org/now',
      unless  => 'which pkgutil',
    }

    $cswpackages_to_have = [ 'CSWack' ]
    package{ $cswpackages_to_have:
      ensure   => present,
      provider => pkgutil,
      require  => Exec[ 'ensure-pkgutil' ],
      before   => Service[ '/network/cswpuppetd' ],
    }

    # As we run from cron, ensure the puppet service is stopped.
    service{ '/network/cswpuppetd':
      ensure => stopped,
      enable => false,
    }

    $ruby_bin_path = '/opt/csw/bin'
  }

  file{ [ '/usr/local/', '/usr/local/bin', '/usr/local/sbin' ]:
    ensure => directory,
    owner  => 'root',
    group  => 'bin',
    mode   => '0755',
    before => [ Class['zfs'], Class['zfs::snapshots'], File['/usr/bin/ruby'] ],
  }

  # Another vile addition, but this makes having the default PATH
  # tolerable for ruby.
  file{ '/usr/bin/ruby':
    ensure => link,
    target => "$ruby_bin_path/ruby",
  }

  # Solaris 11 installs all of ruby's utils as '<name>18' so default Gem
  # and Ruby won't work unless we symlink/rename
  file{ '/usr/bin/gem':
    ensure => link,
    target => "$ruby_bin_path/gem",
  }

  if $haszfs == true or $haszfs == 'true' {
    include zfs
    include zfs::snapshots
  }

}
