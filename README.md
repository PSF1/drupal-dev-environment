## Welcome to drupal-dev-environment

Script to setup a Drupal dev environment.

This script do a insecure system, DON'T RUN IT IN YOUR MAIN SYSTEM !! It's build to run in VMs like LXC, VirtualBox or Vagrant.

You are advised !!

## Usage instructions:

### Ubuntu 16.04

```
wget https://raw.githubusercontent.com/PSF1/drupal-dev-environment/ubuntu.16.04/drupal-dev-environment.sh
chmod +x drupal-dev-environment.sh
sudo ./drupal-dev-environment.sh -h
rm drupal-dev-environment.sh
```

<script type='text/javascript'>
function _dmBootstrap(file) {
    var _dma = document.createElement('script');
    _dma.type = 'text/javascript';
    _dma.async = true;
    _dma.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + file;
    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(_dma);
}
function _dmFollowup(file) { if (typeof DMAds === 'undefined') _dmBootstrap('cdn2.DeveloperMedia.com/a.min.js'); }
(function () { _dmBootstrap('cdn1.DeveloperMedia.com/a.min.js'); setTimeout(_dmFollowup, 2000); })();
</script>
