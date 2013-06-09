# Manic Baker

Manic Baker lets you do all the stuff you want for a full
continuous deployment cycle on Joyent:

1. Spin up a new Joyent base image
1. Bootstrap the new node into Chefable condition
1. Parbake your application code
1. Run your runlist using soloist
1. Snapshot the Joyent instance
1. Scale instances up or down using a snapshot id

## Installation

Add this line to your application's Gemfile:

    gem 'manic_baker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install manic_baker

## Usage

Manic Baker has a totally baller command line interface.

    $ manic parbake 1d6af-is-that-a-sha

        start  base image '0000-2bad-54e5-a-ba7'
          run  bootstrap.sh
        rsync  copying this directory to /opt/app
         chef  not_sql::default
         chef  your_awesome_application::default
         chef  runit::your_awesome_application
     snapshot  created with id '1d6af-is-that-a-sha'
         stop  build complete

    $ manic parbake 1d6af-is-that-a-sha

          oop  snapshot '1d6af-is-that-a-sha' already exists

    $ manic boot no-snapshot-called-this

          oop  snapshot 'no-snapshot-called-this' not found

    $ manic boot 1d6af-is-that-a-sha

        start  snapshot '1d6af-is-that-a-sha' booting
      waiting  ...
        bound  instance is now available at 192.168.0.1

    $ manic boot 1d6af-is-that-a-sha

         nope  an instance of '1d6af-is-that-a-sha' is running

    $ manic boot --plz --scale=2 1d6af-is-that-a-sha

         fine  whatever
        panic  running over instance at 192.168.0.1
      waiting  ...
         done  it was looking at me funny
        start  snapshot '1d6af-is-that-a-sha' booting
      waiting  ...
      scale.1  instance is now available at 192.168.0.2
      scale.2  instance is now available at 192.168.0.3

    $ manic panic 1d6af-is-that-a-sha

        panic  slandering instance at 192.168.0.2
        panic  posting pictures of instance at 192.168.0.3
         done  their lives are ruined for a reason

## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. If you are making changes in the lib/ directory, add tests.
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request
