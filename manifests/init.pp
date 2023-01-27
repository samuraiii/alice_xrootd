# vim: set expandtab sw=2 ts=2 ci :
class alice_xrootd (
  String $se_name,
  String $manager_hostname,
  String $monalisa_host,
  Boolean $is_manager = false,
  Variant[Undef, Array[String]] $xrd_data_dirs = undef,
  Integer[1,65535] $xrd_manager_port = 1094,
  Integer[1,65535] $xrd_server_port = 1094,
  Integer[1,65535] $cms_port = 3122,
  String $xrd_rundir = '/var/run/xrootd',
  String $acc_lib = 'libXrdAliceTokenAcc.so',
  String $xrd_conf_file = '/etc/xrootd/xrootd-alice.cfg',
  String $xrd_logdir = '/var/log/xrootd',
  String $xrootd_custom_cli_params = '',
  String $cmsd_custom_cli_params = '',
  Variant[Undef, String] $namespace_root_param = undef,
  Variant[Undef, String] $namespace_backup_location_param = undef,
  Boolean $enable_backup = true,
  Boolean $manage_backup_directory = true,
  Boolean $package_manage = true,
  Boolean $service_manage = true,
  Enum['running', 'stopped'] $service_ensure = 'running',
  Boolean $service_enable = true,
  Boolean $tweak_ssh = true,
  Boolean $tweak_kernel = true,
  Boolean $manage_bdii = true,
  Variant[Undef, String] $bdii_site_name = undef,
  Boolean $readonly = false,
  String $group_name = 'aliprod',
  Integer[1,default] $group_id = 2004,
  Integer[1,default] $user_id = 2004,
  String $user_name = 'aliprod',
  Boolean $manage_user_home = true,
  Variant[Undef, String] $user_home_param = undef,
){
  if !$is_manager {
    if $xrd_data_dirs == undef {
      fail('Service set to server mode, but no data directories were specified (param $xrd_data_dirs)')
    }

    $namespace_root = $namespace_root_param ? {
      String[1] => $namespace_root_param,
      default   => "${xrd_data_dirs[0]}/xrdnamespace"
    }

    $namespace_backup_location = $namespace_backup_location_param ? {
      String[1] => $namespace_backup_location_param,
      default   => "${xrd_data_dirs[-1]}/xrdnamespace",
    }
    if $namespace_backup_location == $namespace_root {
      fail("Namespace backup location can't be same as the namespace location (${namespace_root})!")
    }
  }
  else {
    $namespace_root = undef
    $namespace_backup_location = undef
  }

  $user_home = $user_home_param ? {
    String[1] => $user_home_param,
    default   => "/var/lib/${user_name}_home",
  }

  contain alice_xrootd::install
  contain alice_xrootd::config
  contain alice_xrootd::service

  Class['alice_xrootd::install']
  ->Class['alice_xrootd::config']
  ~>Class['alice_xrootd::service']

}
