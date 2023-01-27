# vim: set expandtab sw=2 ts=2 ci :
class alice_xrootd::config {

  if $alice_xrootd::is_manager {
    $role = 'manager'
  } else {
    $role = 'server'
  }

  group {
    $alice_xrootd::group_name :
      ensure => present,
      gid    => $alice_xrootd::group_id;
  }
  -> user {
    $alice_xrootd::user_name :
      ensure     => present,
      gid        => $alice_xrootd::group_id,
      uid        => $alice_xrootd::user_id,
      managehome => $alice_xrootd::manage_user_home,
      home       => $alice_xrootd::user_home;
  }

  $xrootd_run_tmpfiles = @("XROOTD_RUN")
    ##      Managed by puppet
    ##      Overrides defaults file at /usr/lib/tmpfiles.d/xrootd.conf
    d /var/run/xrootd - ${alice_xrootd::user_name} ${alice_xrootd::group_name} -
    | XROOTD_RUN

  file {
    [
      "/etc/systemd/system/xrootd@${role}.service.d",
      "/etc/systemd/system/cmsd@${role}.service.d"
    ]:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0644';

    '/etc/tmpfiles.d/xrootd.conf':
      ensure  => file,
      mode    => '0644',
      group   => 'root',
      owner   => 'root',
      content => $xrootd_run_tmpfiles;
  }
  -> file {
    $alice_xrootd::xrd_conf_file:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('alice_xrootd/xrootd-alice.erb');

    "/etc/systemd/system/xrootd@${role}.service.d/override_xrootd.conf":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Exec['reload_systemd_daemon_by_aliceXrootd'],
      content => template('alice_xrootd/override_xrootd.erb');

    "/etc/systemd/system/cmsd@${role}.service.d/override_cmsd.conf":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Exec['reload_systemd_daemon_by_aliceXrootd'],
      content => template('alice_xrootd/override_cmsd.erb');

    $alice_xrootd::xrd_rundir:
      ensure  => directory,
      owner   => $alice_xrootd::user_name,
      group   => $alice_xrootd::group_name,
      mode    => '0700',
      require => [ User[$alice_xrootd::user_name], Group[$alice_xrootd::group_name]];

    '/var/log/xrootd':
      ensure  => directory,
      owner   => $alice_xrootd::user_name,
      group   => $alice_xrootd::group_name,
      mode    => '0755',
      require => [ User[$alice_xrootd::user_name], Group[$alice_xrootd::group_name]];

    '/etc/mlsensor/mlsensor.properties':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('alice_xrootd/mlsensor-xrootd.properties.erb');
  }
  exec {
    'reload_systemd_daemon_by_aliceXrootd':
      command     => '/bin/systemctl daemon-reload',
      refreshonly => true;
  }


  if alice_xrootd::tweak_ssh {
    augeas {
      '/etc/ssh/sshd_config':
        context => '/files/etc/ssh/sshd_config/',
        changes => [
            'set UsePrivilegeSeparation no',
            'rm PAMAuthenticationViaKbdInt yes',
          ],
        notify  => Service['sshd'];
    }
  }

  if alice_xrootd::tweak_kernel {
    sysctl {
      'fs.file-max':
        value       => '70000',
        permanent   => 'yes';
      'net.core.netdev_max_backlog':
        value       => '30000',
        permanent   => 'yes';
      'net.ipv4.tcp_no_metrics_save':
        value       => '1',
        permanent   => 'yes';
    }
  }

  if $role == 'server' and $alice_xrootd::enable_backup {
    $backup_script_ensure = file
    $backup_cron_ensure = present
    if $alice_xrootd::manage_backup_directory {
      $backup_directory_parent = regsubst($alice_xrootd::namespace_backup_location, '/[^/]+/?$', '')
      if defined(Mount[$backup_directory_parent]) {
        $backup_directory_require = Mount[$backup_directory_parent]
      }
      else {
        $backup_directory_require = undef
      }
      file {
        $alice_xrootd::namespace_backup_location:
          ensure  => directory,
          require => $backup_directory_require;
      }
    }
  }
  else {
    $backup_script_ensure = absent
    $backup_cron_ensure = absent
  }

  $xrdnamespacebackup_content = @("XRD_NAMESPACE_BACKUP"/$)
    #!/bin/bash
    if /usr/bin/test -f /dev/shm/xrdnamspace-sync.lock
    then
      exit 0
    else
      /bin/touch /dev/shm/xrdnamspace-sync.lock
    fi
    if /usr/bin/test -d ${alice_xrootd::namespace_root} && /usr/bin/test -d ${alice_xrootd::namespace_backup_location}
    then
      /usr/bin/rsync -a --del ${alice_xrootd::namespace_root}/ ${alice_xrootd::namespace_backup_location}
    fi
    /bin/rm /dev/shm/xrdnamspace-sync.lock
    exit
    | XRD_NAMESPACE_BACKUP
  file {
    '/opt/xrdnamespacebackup.sh':
      ensure  => $backup_script_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => $xrdnamespacebackup_content;
  }
  -> cron {
    'xrdnamespace backup':
      ensure  => $backup_cron_ensure,
      command => '/opt/xrdnamespacebackup.sh',
      user    => 'root',
      hour    => [
          fqdn_rand(5, 'i9OS3cHcOTNNCg0pSImrZmQ6yV/F'),
          (fqdn_rand(5, 'i9OS3cHcOTNNCg0pSImrZmQ6yV/F')+6),
          (fqdn_rand(5, 'i9OS3cHcOTNNCg0pSImrZmQ6yV/F')+12),
          (fqdn_rand(5, 'i9OS3cHcOTNNCg0pSImrZmQ6yV/F')+18)
        ],
      minute  => fqdn_rand(59, 'mEu3tMAd2JOy+WcIc5VhYAMhrAHF'),
  }

  if $role == 'manager' and alice_xrootd::manage_bdii {
    include alice_xrootd::bdii
  }
}
