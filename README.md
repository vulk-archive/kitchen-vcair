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
    vcair_net: [ROUTED_NETWORK_WITH_ACCESS_TO_CHEF_SERVER]
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

Execution:

    KITCHEN_YAML=.kitchen.vcair.yml kitchen test

Known Issues / Work Arounds
---------------------------

##### ssh authentication happens via password only and public_key auth isn't available

You must populate :vcair_ssh_password in your kitchen.yml

##### vCloud Air VMs default to an isolated network

You must populate :vcair_net _OR_ create a non-isolated network (it will use the first available)

##### SSH access to nodes requires default firewall policy open port 22

You may find it easier to use a provisioning node within the same network you nodes will be provisioned on

Feature Requests
----------------

##### Windows and non CentOS64-64BIT image support

CentoOS64-64BIT is the only image that allowed setting the password
CentOS and Ubuntu failed to set the password correctly

##### NAT support

Only routed networks supported for now

Walkthru of kitchen-vcair
-------------------------

* [github.com/vulk/kitchen-vcair](https://www.youtube.com/watch?v=5srDko69XJ0&t=03)
* [vchs.vmware.com](https://www.youtube.com/watch?v=5srDko69XJ0&t=15)
* [Walkthrough steps for cloning, building gem](https://www.youtube.com/watch?v=5srDko69XJ0&t=30)
* [git clone git@github.com:/vulk/kitchen-vcair.git](https://www.youtube.com/watch?v=5srDko69XJ0&t=68)
* [cd kitchen-vcair](https://www.youtube.com/watch?v=5srDko69XJ0&t=94)
* [gem build kitchen-vcair.gemspec](https://www.youtube.com/watch?v=5srDko69XJ0&t=100)
* [gem install ./kitchen-vcair-0.1.0.gem](https://www.youtube.com/watch?v=5srDko69XJ0&t=120)
* [quick look through code  ](https://www.youtube.com/watch?v=5srDko69XJ0&t=126)
* [git clone git@github.com:chef-cookbooks/httpd.git ](https://www.youtube.com/watch?v=5srDko69XJ0&t=173)
* [walkthrough of .kitchen.vcair.yml](https://www.youtube.com/watch?v=5srDko69XJ0&t=199)
* [walkthrough of environment variables](https://www.youtube.com/watch?v=5srDko69XJ0&t=247)
* [kitchen test](https://www.youtube.com/watch?v=5srDko69XJ0&t=282)
* [vchs.vmware.com virtualmachine list, showing creation of helloworldtest VM](https://www.youtube.com/watch?v=5srDko69XJ0&t=296)
* [knife vcair server list showing creation of helloworld test VM](https://www.youtube.com/watch?v=5srDko69XJ0&t=326)
* [instance provisionied, waiting for ssh](https://www.youtube.com/watch?v=5srDko69XJ0&t=355)
* [ssh available, installing chef-client](https://www.youtube.com/watch?v=5srDko69XJ0&t=400)
* [chef-client starting](https://www.youtube.com/watch?v=5srDko69XJ0&t=499)
* [chef-client finished, apache install completed](https://www.youtube.com/watch?v=5srDko69XJ0&t=515)
* [Kitchen Setup and Verify](https://www.youtube.com/watch?v=5srDko69XJ0&t=516)
* [Kitichen Destroy](https://www.youtube.com/watch?v=5srDko69XJ0&t=517)
* [Kitchen is finished](https://www.youtube.com/watch?v=5srDko69XJ0&t=525)
* [vchs.vmware.com and knife vcair shows vm destroyed](https://www.youtube.com/watch?v=5srDko69XJ0&t=530)

Contributing
------------

1. Fork it
2. `bundle install`
3. Create your feature branch (`git checkout -b my-new-feature`)
4. `bundle exec rake` must pass
5. Commit your changes (`git commit -am 'Add some feature'`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create new Pull Request
