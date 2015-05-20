Kitchen::Vcair
==================

A vCloud Air Servers driver for Test Kitchen!

Originally based on the [Rackspace driver](https://github.com/test-kitchen/kitchen-rackspace) (from [Jonathan Hartman's](https://github.com/RoboticCheese)) 


Installation
------------

Add this line to your application's Gemfile:

    gem 'kitchen-vcair'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kitchen-vcair

Usage
-----

Provide, at a minimum, the required driver options in your `.kitchen.yml` file:

    driver:
      name: vcair
      vcair_username: [Your vCloud Air username]
      vcair_password: [Your vCloud Air password]
      vcair_api_host: [Your vCloud Air API Host]
      vcair_ssh_password: [Initial system password used for bootstrap]
      vcair_org: [Your vCloud Air Organization ID]
      require_chef_omnibus: [e.g. 'true' or a version number if you need Chef]
    platforms:
      - name: [A PLATFORM NAME, e.g. 'centos-6']

By default, the driver will spawn a 1GB server on the base image for your
specified platform. Additional, optional overrides can be provided:

    image_id: [SERVER IMAGE ID]
    flavor_id: [SERVER FLAVOR ID]
    server_name: [A FRIENDLY SERVER NAME]
    public_key_path: [PATH TO YOUR PUBLIC SSH KEY]
    wait_for: [NUM OF SECONDS TO WAIT BEFORE TIMING OUT, DEFAULT 600]
    no_ssh_tcp_check: [DEFAULTS TO false, SKIPS TCP CHECK WHEN true]
    no_ssh_tcp_check_sleep: [NUM OF SECONDS TO SLEEP IF no_ssh_tcp_check IS SET]

You also have the option of providing some configs via environment variables:

    export VCAIR_API_HOST='API_HOST.vchs.vmware.com'
    export VCAIR_SSH_PASSWORD='SOME_INITIAL_PASSWORD'
    export VCAIR_ORG='MNNNNNNNNN-NNNN'
    export VCAIR_USERNAME='YOUR_USERNAME'
    export VCAIR_PASSWORD='YOUR_PASSWORD'


Contributing
------------

1. Fork it
2. `bundle install`
3. Create your feature branch (`git checkout -b my-new-feature`)
4. `bundle exec rake` must pass
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create new Pull Request
