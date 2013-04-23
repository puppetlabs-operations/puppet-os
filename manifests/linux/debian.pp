class os::linux::debian  {

  include harden

  $packages = [
    'lsb-release',
    'keychain',
    'ca-certificates',
    'less',
  ]

  package { $packages: ensure => latest; }

  # Install rubygems on all debian machines so we can use the gem command/provider.
  include ruby

  # For some reason, we keep getting mpt installed on things. Not
  # cool.
  if $is_virtual == 'true' {
    package{ 'mpt-status':
      ensure => purged,
    }
  }

  # Make sure open-vm-tools is installed for VMWare VMs.
  include vmware

  # ----------
  # Apt Configuration
  # ----------
  case $domain {
    default: {
      # Setup apt settings specific to the lan
      file { '/etc/apt/apt.conf': ensure => absent }
      $proxy = hiera("proxy")
      apt::conf { "proxy":
        priority => '01',
        content  => "Acquire::http::Proxy \"${proxy}\";\n";
      }
      apt::source { "pkgs.puppetlabs.lan":
        location    => "http://pkgs.puppetlabs.lan",
        key         => '27D8D6F1',
        key_source  => 'http://pkgs.puppetlabs.lan/pubkey.gpg',
        include_src => false,
      }
    }
    "puppetlabs.com": {
    }
  }

  class { 'apt':
    purge_sources_list   => true,
    purge_sources_list_d => true,
    purge_preferences_d  => true,
  }

  apt::conf { "norecommends":
      priority => '00',
      content  => "Apt::Install-Recommends 0;\nApt::AutoRemove::InstallRecommends 1;\n",
  }

  cron { "apt-get update":
    ensure  => $apt_get_update_ensure,
    command => "/usr/bin/apt-get -qq update",
    user    => root,
    minute  => 20,
    hour    => 1,
  }

  # Debian Specific things
  case $operatingsystem {
    Debian: {
      apt::source { "main":
        location => "http://ftp.us.debian.org/debian",
      }
    }
    default: { }
  }

  # Testing (currently Wheezy) doesn't have security branches nor
  # backports as it's a moving target/rolling release.
  if !($lsbdistrelease in ['testing', 'unstable']) and !($lsbdistcodename in ['wheezy']) {

    # We want backports, this doesn't pin anything, just throws the
    # option of it being there in (and pins for auto-updating, as
    # reccomended).
    include apt::backports

    # ----------
    # Apt Repo Sources
    # ----------
    apt::source {
      "security":
        location  => $lsbdistid ? {
          "debian" => "http://security.debian.org/",
          "ubuntu" => "http://security.ubuntu.com/ubuntu",
        },
        release   => $lsbdistid ? {
          "debian" => "${lsbdistcodename}/updates",
          "ubuntu" => "${lsbdistcodename}-security",
        },
        repos     => $lsbdistid ? {
          "debian" => "main",
          "ubuntu" => "main universe",
        },
    }

    apt::source { "updates":
      location => $lsbdistid ? {
        "debian" => "http://ftp.us.debian.org/debian/",
        "ubuntu" => "http://us.archive.ubuntu.com/ubuntu/",
      },
      release  => "${lsbdistcodename}-updates",
      repos    => $lsbdistid ? {
        "debian" => "main",
        "ubuntu" => "universe",
      },
    }

  }

}

