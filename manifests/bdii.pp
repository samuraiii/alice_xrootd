# vim: set expandtab sw=2 ts=2 ci :
class alice_xrootd::bdii {

  if $alice_xrootd::bdii_site_name == undef {
    fail('To configure bdii, the proper (WLCG) site name must be specified')
  }

  if alice_xrootd::package_manage {
    package {
      'bdii':
        ensure => present;
    }
  }

  $bdii_content = @("BDII_HD")
    #!/bin/sh
    # Managed by puppet by the alice_xrootd module
    /usr/bin/glite-info-se-xrootd --site ${alice_xrootd::bdii_site_name} --vo alice --proto 2.9.6 --sec tkauthz --host ${alice_xrootd::manager_hostname} --xrd /usr/bin/xrd
    | BDII_HD

  file {
    '/usr/bin/glite-info-se-xrootd' :
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      source  => 'puppet:///modules/alice_xrootd/glite-info-se-xrootd',
      mode    => '0755';

    '/var/lib/bdii/gip/provider/se-xrootd' :
      ensure  => file,
      owner   => 'ldap',
      group   => 'ldap',
      mode    => '0755',
      require => File['/usr/bin/glite-info-se-xrootd'],
      content => $bdii_content;
  }

  if $alice_xrootd::service_manage {
    service {
      'bdii':
        ensure    => 'running',
        enable    => true,
        subscribe => File['/var/lib/bdii/gip/provider/se-xrootd','/usr/bin/glite-info-se-xrootd'];
    }
  }
}
