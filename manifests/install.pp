# vim: set expandtab sw=2 ts=2 ci :
class alice_xrootd::install {
  if $alice_xrootd::package_manage {
    package {
      [
        'alicexrdplugins',
        'mlsensor'
      ]:
        ensure          => present;
    }
  }
}
