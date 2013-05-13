# NetApp.rb: Rubyesque library to interface with NetApp Filers (via NMSDK)

## Introduction
NetApp Manageability SDK and OnCommand SDK offer the posibility to directly interact with NetApp Filers on an API basis. The SDK provides for complete functional control of all subsets and configuration details provided by NetApp Filers. The API is extensive and interfacing to it can be a pain since the port to Ruby (and Python) was not done with Ruby typical programming paradigms in mind (at least in my opinon).

This project tries to ease the interaction with NetApp filers significantly. Although this library is far from complete, it already gives access a substential feature set to interact with NetApp storage components such as:

* Filer statistics and diagnostics
* Aggregate management and statistics
* Volume managment and statistics
* Snapshot managment and statistics
* Qtree and Quota managment, statistics
* vFiler creation, deletion

Development of this libary will be continued and contributions are very welcome. Please consider opening a pull-request if a feature you are looking for is missing. Extending upon this library should be fairly easy.

### Resources
* NetApp NM SDK Download - http://support.netapp.com/NOW/download/software/nmsdk/5.1/download.shtml
* NetApp SDK and API Documentation - https://communities.netapp.com/community/interfaces_and_tools/developer/apidoc
* NetApp ONTAP Simulator - http://support.netapp.com/NOW/cgi-bin/simulator

## Getting Started
Since the API from NetApp itself is not Open-Source, i cannot include it in this Project directly. Download the NM SDK with the link provided above (you do not have to be a NetApp customer, just register as a developer). You might want to download the ONTAP Simulator (VM) and API Documentation as well for testing purposes before running scripts on actual Filers.

Copy the Ruby API from the Manageability SDK (path/to/sdk/lib/ruby/NetApp) to the NetApp.rb's "lib" folder and rename it to "NMSDK-Ruby" (or change the require statement in lib/netapp.rb).

Start writing your Apps.

### Example
See also: `examples/`

```Ruby
rb(main):001:0> require './lib/netapp.rb'
=> true
irb(main):002:0> Filer.new("192.168.55.10", "root", "rootr00t")
=> #<Filer:0x007fc3340a8f08>
irb(main):005:0> puts Filer.is_ha?
false
=> nil
irb(main):007:0> puts Volume.list
testvol
vol0
=> nil
irb(main):011:0> puts Snapshot.info("testvol")
{:name=>"hourly.2", :accesstime=>"1366891242", :busy=>"false", :containslunclones=>nil, :cumpercentageblockstotal=>"0", :cumpercentageblocksused=>"68", :cumtotal=>"468", :dependency=>"", :percentageblockstotal=>"0", :percentageblocksused=>"30", :total=>"96"}
=> nil
irb(main):012:0> puts Snapshot.delta("testsnapshot", "testsnapshot2", "testvol")
{:consumedsize=>"73728", :elapsedtime=>"13"}
=> nil
irb(main):013:0> puts Snapshot.delta_to_volume("testsnapshot", "testvol")
{:consumedsize=>"217088", :elapsedtime=>"17456"}
=> nil
irb(main):014:0> puts Snapshot.schedule("testvol")
{:days=>"2", :hours=>"6", :minutes=>"0", :weeks=>"0", :whichhours=>"8,12,16,20", :whichminutes=>" "}
=> nil
irb(main):015:0> Snapshot.create("snapshot22", "testvol")
=> true
irb(main):017:0> Snapshot.purge("testsnapshot", "testvol")
=> true
irb(main):018:0> puts Volume.container("testvol")
testaggr
=> nil
irb(main):019:0> puts Aggregate.info("testaggr")
{:name=>"testaggr", :uuid=>"b1d00ed9-ac53-11e2-87d9-123478563412", :state=>"online", :type=>"aggr", :haslocalroot=>"false", :haspartnerroot=>"false", :checksumstatus=>"active", :isinconsistent=>"false", :sizetotal=>"6606028800", :sizeused=>"1080606720", :sizeavail=>"5525422080", :sizepercentage=>"16", :filestotal=>"31142", :filesused=>"96", :isnaplock=>"false", :snaplocktype=>nil, :mirrorstatus=>"unmirrored", :raidsize=>"16", :raidstatus=>"raid_dp", :diskcount=>"9", :volumecount=>"1", :volstripeddvcount=>nil, :volstripedmdvcount=>nil, :volumes=>["testvol"], :plexcount=>"1", :plexes=>{{:name=>"/testaggr/plex0"}=>{:isonline=>"true", :isresyncing=>"false", :resyncpercentage=>nil}}}
=> nil
irb(main):022:0> Volume.offline("testvol") && Volume.purge("testvol")
=> true
irb(main):023:0> Aggregate.offline("testaggr")
=> true
irb(main):024:0> Aggregate.purge("testaggr")
=> true
irb(main):025:0> Aggregate.list
=> ["aggr0"]
irb(main):026:0> Diag.status
=> "OK"
irb(main):028:0* Aggregate.create("testaggr2", 10) #name, no. disks
=> true
irb(main):029:0> Aggregate.info("testaggr2")
=> {:name=>"testaggr2", :uuid=>"3031cf33-ae0c-11e2-ad23-123478563412", :state=>"creating", :type=>"aggr", :haslocalroot=>"false", :haspartnerroot=>"false", :checksumstatus=>"active", :isinconsistent=>"false", :sizetotal=>"0", :sizeused=>"0", :sizeavail=>"0", :sizepercentage=>"0", :filestotal=>"18446744073709551552", :filesused=>"0", :isnaplock=>"false", :snaplocktype=>nil, :mirrorstatus=>"unmirrored", :raidsize=>"16", :raidstatus=>"raid_dp, initializing", :diskcount=>"0", :volumecount=>"0", :volstripeddvcount=>nil, :volstripedmdvcount=>nil, :volumes=>[], :plexcount=>"1", :plexes=>{{:name=>"/testaggr2/plex0"}=>{:isonline=>"false", :isresyncing=>"false", :resyncpercentage=>nil}}}
irb(main):030:0> Volume.create("testaggr2", "testvol2", "5g") 
=> true
irb(main):031:0> puts Volume.info("testvol2")
{:name=>"testvol2", :uuid=>"aaa2008d-ae0c-11e2-ad23-123478563412", :type=>"flex", :containingaggr=>"testaggr2", :sizetotal=>"5100273664", :sizeused=>"135168", :sizeavail=>"5100134400", :percentageused=>"0", :filestotal=>"155630", :filesused=>"96", :cloneparent=>nil, :clonechildren=>nil, :ischecksumenabled=>"true", :checksumstyle=>"block", :compression=>nil, :isinconsistent=>"false", :isinvalid=>"false", :isunrecoverable=>"false", :iswraparound=>nil, :issnaplock=>"false", :expirydate=>nil, :mirrorstatus=>"unmirrored", :raidsize=>"16", :raidstatus=>"raid_dp", :owningvfiler=>nil, :quotainit=>"0", :remotelocation=>nil, :reserve=>"0", :reserverequired=>"0", :reserveused=>"0", :reservedusedact=>"0", :snaplocktype=>nil, :snapshotblkreserved=>"262144", :snapshotperreserved=>"5", :spacereserveenabled=>"true", :spacereserve=>"volume", :diskcount=>"10", :plexcount=>"1", :plexes=>{{:name=>"/testaggr2/plex0"}=>{:isonline=>"true", :isresyncing=>"false", :resyncpercentage=>nil}}}
=> nil
irb(main):032:0> Aggregate.info("testaggr2")
=> {:name=>"testaggr2", :uuid=>"3031cf33-ae0c-11e2-ad23-123478563412", :state=>"online", :type=>"aggr", :haslocalroot=>"false", :haspartnerroot=>"false", :checksumstatus=>"active", :isinconsistent=>"false", :sizetotal=>"7549747200", :sizeused=>"5398806528", :sizeavail=>"2150940672", :sizepercentage=>"72", :filestotal=>"31142", :filesused=>"96", :isnaplock=>"false", :snaplocktype=>nil, :mirrorstatus=>"unmirrored", :raidsize=>"16", :raidstatus=>"raid_dp", :diskcount=>"10", :volumecount=>"1", :volstripeddvcount=>nil, :volstripedmdvcount=>nil, :volumes=>["testvol2"], :plexcount=>"1", :plexes=>{{:name=>"/testaggr2/plex0"}=>{:isonline=>"true", :isresyncing=>"false", :resyncpercentage=>nil}}}
```


## Authors and License
* Aaron <azet@azet.org> Zauner

http://opensource.org/licenses/MIT

    The MIT License (MIT)

    Copyright (c) 2013  Aaron Zauner

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
