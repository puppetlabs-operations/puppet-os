class os::freebsd (
  $headless = hiera('os::freebsd::headless', 'true')
){

  # ZFS
  if $haszfs == true or $haszfs == 'true' {
    include zfs
    include zfs::snapshots
    if $virtual == 'physical' {
      include smartmon  # If we have ZFS, we care about disks.
    }
  }

  # Useful to manging rc.conf, provider will drop service enables here
  file { '/etc/rc.conf.d':
    ensure => directory,
    owner  => 'root',
    group  => '0',
    mode   => '0644',
  }

  # PkgNG is cool.  We should use it if we can.
  if $pkgng_supported {
    class { 'pkgng': packagesite => 'http://fbsd-build.ops.puppetlabs.net/90amd64-default'; }
  }

  $packages_to_install = [  'sysutils/tmux',
                            'sysutils/pv',
                            'sysutils/screen',
                            'ports-mgmt/portmaster',
                            'ports-mgmt/portupgrade',
                            'net/netcat',
                            'security/ca_root_nss',
                            'sysutils/lsof',
                            'textproc/p5-ack',
                            'editors/vim-lite' ]

  # Install some basic packages. Nothing too spicy.
  package{ $packages_to_install:
    ensure   => present,
  }

  package{ 'ports-mgmt/portaudit':
    ensure => installed,
    notify => Exec['/usr/local/sbin/portaudit -Fda'];
  }

  exec{ '/usr/local/sbin/portaudit -Fda':
    user        => root,
    refreshonly => true;
  }

  #
  # This is horrible, but it stops a lot of things breaking (concat for example)
  #
  file{ '/bin/bash':
    ensure  => link,
    target  => '/usr/local/bin/bash',
  }

  file{ '/bin/zsh':
    ensure  => link,
    target  => '/usr/local/bin/zsh',
  }

  # This just makes our lives easier.
  file{ '/etc/puppet':
    ensure  => link,
    target  => '/usr/local/etc/puppet',
  }

  file{ '/usr/bin/ruby':
    ensure => link,
    target => '/usr/local/bin/ruby',
  }

  # 'fix' gem provider.
  file{ '/usr/bin/gem':
    ensure => link,
    target => '/usr/local/bin/gem',
  }

  #
  # Begin promotion of portsnap and deprecation of cvsup
  cron{ 'update ports':
    minute  => fqdn_rand( 60 ),
    hour    => 20,
    user    => root,
    command => '/usr/sbin/portsnap cron',
  }

  # Set periodic, so we can control a bit more what we get emailed
  # about.
  file{ '/etc/periodic.conf':
    ensure => file,
    owner  => 'root',
    group  => 'wheel',
    mode   => '0644',
    source => 'puppet:///modules/os/freebsd/etc/periodic.conf',
  }

  ## Limit number of processes per user/manage login.conf
  # https://projects.puppetlabs.com/issues/14971
  file{ '/etc/login.conf':
    ensure => file,
    owner  => 'root',
    group  => 'wheel',
    mode   => '0644',
    source => 'puppet:///modules/os/freebsd/etc/login.conf',
    notify => Exec['update login database'],
  }

  exec{ 'update login database':
    command     => '/usr/bin/cap_mkdb /etc/login.conf',
    refreshonly => true,
  }

  # https://projects.puppetlabs.com/issues/10681
  # Manage /etc/make.conf for building things.
  # Perhaps this can be templatized, maybe some concat even.
  file{ '/etc/make.conf':
    ensure  => 'file',
    group   => 'wheel',
    mode    => '0644',
    owner   => 'root',
    replace => false,
    source  => 'puppet:///modules/os/freebsd/etc/make.conf',
  }

  file_line { "include make.conf.local":
    path => '/etc/make.conf',
    line => '.include "/etc/make.conf.local"',
  }

  concat::fragment { "make.conf.local header":
    target  => '/etc/make.conf.local',
    content => "# Managed by puppet\n",
    order   => '00',
  }

  # Some local make options.  This is mostly unnecessary if we are using out
  # PkgNG build host, so I am just bringing in old options.  We could
  # re-evaluate the usefulness of the following.

  if ($headless == 'true') {
    concat::fragment { "make.conf.local WITHOUT_X11":
      target  => '/etc/make.conf.local',
      content => "WITHOUT_X11=TRUE\n",
    }

    concat::fragment { "make.conf.local WITHOUT_GNOME":
      target  => '/etc/make.conf.local',
      content => "WITHOUT_GNOME=TRUE\n",
    }

    concat::fragment { "make.conf.local WITHOUT_KDE":
      target  => '/etc/make.conf.local',
      content => "WITHOUT_KDE=TRUE\n",
    }

    concat::fragment { "make.conf.local WITHOUT_KDE4":
      target  => '/etc/make.conf.local',
      content => "WITHOUT_KDE4=TRUE\n",
    }

    concat::fragment { "make.conf.local WITHOUT_JAVA":
      target  => '/etc/make.conf.local',
      content => "WITHOUT_JAVA=TRUE\n",
    }
  }

  # Why wouldn't we want IPv6?
  concat::fragment { "make.conf.local WITH_IPV6":
    target  => '/etc/make.conf.local',
    content => "WITH_IPV6=yes\n",
  }

  # Why wouldn't we want SSL?
  concat::fragment { "make.conf.local WITH_SSL":
    target  => '/etc/make.conf.local',
    content => "WITH_SSL=yes\n",
  }

  concat { "/etc/make.conf.local": }

  # /home does not get created using our installation method.
  file{ '/home':
    ensure => directory,
    owner  => root,
    group  => 0,
    mode   => 0755,
  }

}
