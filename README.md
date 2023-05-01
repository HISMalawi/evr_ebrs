eBRS for eVR
-
eBRS for eVR is an extended version of the Baobab Health Trust's eBRS application. It is built to complement the need for 
create birth reports in eVR, another Baobab Health Trust application. 

Getting Started
-
The steps below will help you get a copy of the project onto you machine for development, testing, deployment. 
It will also give you guidance if you intend to contribute to the development of the system.

Prerequisites
-
Make sure you have all the prerequisites available: Follow through with the below

Dependencies
-
    Ruby 2.2.2p95 
    Rails 4.2.6
    mysql Ver 14.14 Distrib 5.x.x
    
Cloning/Downloading
-
Get the application from github by cloning/downloading it from Baobab Health Trust's github account on the link below;

Using HTTPS:
-
    https://github.com/BaobabHealthTrust/evr_ebrs/
    
Using SSH:
-
    git@github.com:BaobabHealthTrust/evr_ebrs.git
    
Configuration
-
Copy and configure all the required configuration files. Below are the necessary files and what needs to be modified.
Run the below commands for configuration file if you intend to use the terminal. Also, make sure you run the commands
from the root directory of the application.

couchdb.yml
-
    cp config/couchdb.yml.example config/couchdb.yml

database.yml
-
    cp config/database.yml.example config/database.yml

elasticsearchsetting.yml
-
    cp config/elasticsearchsetting.yml.example config/elasticsearchsetting.yml

settings.yml
-
    cp config/settings.yml config/settings.yml
what to configure in settings.yml
-
    application_mode: FC #meanig Facility Application
    location_id: 35077  #facility_id
    scan_from_remote: true #to allow scanning from ART
    remote_user_name: username #username of an existing user in the remote ART application
    remote_user_password: password #password of an existing user in the remote ART application
    enable_role_privileges: true 
    remote_url: http://192.168.5.89:5000 #url to ART application to use 
    
Installation
-
Install the required dependencies by running the below command:
    
    Run bundle install --local

Run the command 
-
If successful with installing dependencies above, run the following to setup the system. Replace "RAILS_ENVIRONMENT" 
with the environment you are setting up the application in. i.e. production or development

    ./setup.sh RAILS_ENVIRONMENT metadata.sql

Deployment
-

Contributing
-
If you happen to make changes to the code in this system, you need to create a PR (Pull Request) for the changes to be merged.

Versioning
-
This system uses [SemVer](http://semver.org/) for versioning.
For all available tags if any, click [here](https://github.com/BaobabHealthTrust/evr_ebrs/tags)

Authors
-
* [Baobab Health Trust developers](https://github.com/orgs/BaobabHealthTrust/teams/developers/members)

Contributors
-
Contributors to the existing versions of the system can be found on the
[All contributors](https://github.com/BaobabHealthTrust/evr_ebrs/graphs/contributors) page.

License
-
This project is an OpenSource project.

Acknowledgements
-
* [BHT eDRS Team](), for it's beautiful navigational side pane feature.

