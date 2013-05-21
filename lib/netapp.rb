#!/usr/bin/env ruby
#
# NetApp.rb:
#   * Ruby library for NetApp filer administration via NetApp NMSDK
#   * https://github.com/azet/NetApp.rb
#
# LICENSE: 
#   MIT License (http://opensource.org/licenses/MIT)
#
# AUTHORS:
#   Aaron <azet@azet.org> Zauner
#

# Include NetApp Manageability SDK for Ruby
$:.unshift 'NMSDK-Ruby' # set this to your actual NMSDK path!
require 'NaServer'

#
#  "Style is what gives value and currency to thoughts." -- Schopenhauer
#

# connect to filer, assign object
class Filer
    def initialize(filer, username, password, secure=nil)
        @@filer = NaServer.new(filer, 1, 17) # specifies API version (1.17)
        if secure
            # implement me
            return false
        else
            @@filer.set_admin_user(username, password)
        end
    end
    def self.is_clustered?
        sys_version = @@filer.invoke("system-get-version")
        raise sys_version.results_reason \
              if sys_version.results_status == 'failed'
        return sys_version.child_get_string("version") \
               =~ /Cluster-Mode/ ? true : false
    end
    def self.is_ha?
        cf_status = @@filer.invoke("cf-status")
        return false if cf_status.results_status == 'failed' \
                     and cf_status.results_reason == 'monitor not initialiazed'
        raise cf_status.results_reason if cf_status.results_status == 'failed'
        return result = cf_status.child_get_string("is-enabled")
    end
    def self.set_vfiler(vfilername)
        return true if @@filer.set_vfiler(vfilername)
    end
    def self.info
        system_info = @@filer.invoke("system-get-info") 
        raise system_info.results_reason \
              if system_info.results_status == 'failed'
        result = {}
        system_info.child_get("system-info").children_get.each do |key|
            result = {
                systemid:                      key.child_get_string("system-id"),
                systemname:                    key.child_get_string("system-name"),
                systemmodel:                   key.child_get_string("system-model"),
                systemmachinetype:             key.child_get_string("system-machine-type"),
                systemrev:                     key.child_get_string("system-revision"),
                systemserialno:                key.child_get_string("system-serial-number"),
                vendorid:                      key.child_get_string("vendor-id"),
                prodtype:                      key.child_get_string("prod-type"),
                partnersystemid:               key.child_get_string("partner-system-id"),
                partnersystemname:             key.child_get_string("partner-system-name"),
                partnersystemserialno:         key.child_get_string("partner-system-serial-number"),
                backplanepartno:               key.child_get_string("backplane-part-number"),
                backplanerev:                  key.child_get_string("backplane-revision"),
                processorsno:                  key.child_get_string("number-of-processors"),
                memorysize:                    key.child_get_string("memory-size"),
                cpuserialno:                   key.child_get_string("cpu-serial-number"),
                cpurev:                        key.child_get_string("cpu-revision"),
                cputype:                       key.child_get_string("cpu-processor-type"),
                cpuid:                         key.child_get_string("cpu-processor-id"),
                cpupartno:                     key.child_get_string("cpu-part-number"),
                cpumicrocodeversion:           key.child_get_string("cpu-microcode-version"),
                cpufirmwarerel:                key.child_get_string("cpu-firmware-release"),
                cpuciobrevid:                  key.child_get_string("cpu-ciob-revision-id"),
                supportsraidarray:             key.child_get_string("supports-raid-array"),
                controlleraddress:             key.child_get_string("controller-address"),
                boardtype:                     key.child_get_string("board-type"),
                boardspeed:                    key.child_get_string("board-speed")
            }
        end
	return result
    end
end

# function definitions to interface with NetApp filers
class Aggregate < Filer
    def self.create(aggr, diskcount, raidtype="raid_dp")
        aggr_create = @@filer.invoke("aggr-create", 
                                     "aggregate", aggr, 
                                     "disk-count", diskcount,
                                     "raid-type", raidtype)
        raise aggr_create.results_reason \
              if aggr_create.results_status == 'failed'
        return true
    end
    def self.purge(aggr)
        aggr_destroy = @@filer.invoke("aggr-destroy", 
                                      "aggregate", aggr)
        raise aggr_destroy.results_reason \
              if aggr_destroy.results_status == 'failed'
        return true
    end
    def self.add(aggr)
        # implement me!
        return false
    end
    def self.online(aggr)
        aggr_online = @@filer.invoke("aggr-online", 
                                     "aggregate", aggr)
        raise aggr_online.results_reason \
              if aggr_online.results_status == 'failed'
        return true
    end
    def self.offline(aggr)
        aggr_offline = @@filer.invoke("aggr-offline", 
                                      "aggregate", aggr)
        raise aggr_offline.results_reason \
              if aggr_offline.results_status == 'failed'
        return true
    end
    def self.rename(aggr, newname)
        aggr_rename = @@filer.invoke("aggr-rename", 
                                     "aggregate", aggr,
                                     "new-aggregate-name", newname)
        raise aggr_rename.results_reason \
              if aggr_rename.results_status == 'failed'
        return true
    end
    def self.list
        aggr_list_info = @@filer.invoke("aggr-list-info")
        raise aggr_list_info.results_reason \
              if aggr_list_info.results_status == 'failed'
        result = []
        aggr_list_info.child_get("aggregates").children_get.each do |key|
            result << key.child_get_string("name")
        end
        return result
    end
    def self.info(aggr, verbose=true)
        aggr_list_info = @@filer.invoke("aggr-list-info", 
                                        "aggregate", aggr,
                                        "verbose", verbose)
        raise aggr_list_info.results_reason \
              if aggr_list_info.results_status == 'failed'
        result = {}
        aggr_list_info.child_get("aggregates").children_get.each do |key|
            volumes = []
            key.child_get("volumes").children_get.each { |vol| 
                volumes << vol.child_get_string("name")
            }
            plexes = {}
            key.child_get("plexes").children_get.each { |plx| 
                plexes[name: plx.child_get_string("name")] = { 
                    isonline:         plx.child_get_string("is-online"),
                    isresyncing:      plx.child_get_string("is-resyncing"),
                    resyncpercentage: plx.child_get_string("resyncing-percentage")
                }
            }
            result = {
                name:               key.child_get_string("name"),
                uuid:               key.child_get_string("uuid"),
                state:              key.child_get_string("state"),
                type:               key.child_get_string("type"),
                haslocalroot:       key.child_get_string("has-local-root"),
                haspartnerroot:     key.child_get_string("has-partner-root"),
                checksumstatus:     key.child_get_string("checksum-status"),
                isinconsistent:     key.child_get_string("is-inconsistent"),
                sizetotal:          key.child_get_string("size-total"),
                sizeused:           key.child_get_string("size-used"),
                sizeavail:          key.child_get_string("size-available"),
                sizepercentage:     key.child_get_string("size-percentage-used"),
                filestotal:         key.child_get_string("files-total"),
                filesused:          key.child_get_string("files-used"),
                isnaplock:          key.child_get_string("is-snaplock"),
                snaplocktype:       key.child_get_string("snaplock-type"),
                mirrorstatus:       key.child_get_string("mirror-status"),
                raidsize:           key.child_get_string("raid-size"),
                raidstatus:         key.child_get_string("raid-status"),
                diskcount:          key.child_get_string("disk-count"),
                volumecount:        key.child_get_string("volume-count"),
                volstripeddvcount:  key.child_get_string("volume-count-striped-dv"),
                volstripedmdvcount: key.child_get_string("volume-count-striped-mdv"),
                volumes:            volumes,
                plexcount:          key.child_get_string("plex-count"),
                plexes:             plexes
            }
        end
        return result
    end
end

class Volume < Filer
    def self.create(aggr, volname, size)
        vol_create = @@filer.invoke("volume-create", 
                                    "containing-aggr-name", aggr, 
                                    "volume", volname, 
                                    "size", size)
        raise vol_create.results_reason \
              if vol_create.results_status == 'failed'
        return true
    end
    def self.purge(volname)
        vol_destroy = @@filer.invoke("volume-destroy", 
                                     "name", volname)
        raise vol_destroy.results_reason \
              if vol_destroy.results_status == 'failed'
        return true
    end    
    def self.add(volname)
        # implement me!
        return false
    end
    def self.online(volname)
        vol_online = @@filer.invoke("volume-online", 
                                    "name", volname)
        raise vol_online.results_reason \
              if vol_online.results_status == 'failed'
        return true
    end
    def self.offline(volname)
        vol_offline = @@filer.invoke("volume-offline", 
                                     "name", volname)
        raise vol_offline.results_reason \
              if vol_offline.results_status == 'failed'
        return true
    end
    def self.container(volname)
        vol_container = @@filer.invoke("volume-container",
                                       "volume", volname)
        raise vol_container.results_reason \
              if vol_container.results_status == 'failed'
        return result = vol_container.child_get_string("containing-aggregate")
    end
    def self.rename(volname, newname)
        vol_rename = @@filer.invoke("volume-rename", 
                                    "volume", volname,
                                    "new-volume-name", newname)
        raise vol_rename.results_reason \
              if vol_rename.results_status == 'failed'
        return true
    end
    def self.list
        vol_list_info = @@filer.invoke("volume-list-info")
        raise vol_list_info.results_reason \
              if vol_list_info.results_status == 'failed'
        result = []
        vol_list_info.child_get("volumes").children_get.each do |key|
            result << key.child_get_string("name")
        end
        return result
    end
    def self.info(volname, verbose=true)
        vol_list_info = @@filer.invoke("volume-list-info", 
                                       "volume", volname,
                                       "verbose", verbose)
        raise vol_list_info.results_reason \
              if vol_list_info.results_status == 'failed'
        result = {}
        vol_list_info.child_get("volumes").children_get.each do |key|
            plexes = {}
            key.child_get("plexes").children_get.each { |plx| 
                plexes[name: plx.child_get_string("name")] = { 
                    isonline:         plx.child_get_string("is-online"),
                    isresyncing:      plx.child_get_string("is-resyncing"),
                    resyncpercentage: plx.child_get_string("resyncing-percentage")
                }
            }
            result = {
                name:                  key.child_get_string("name"),
                uuid:                  key.child_get_string("uuid"),
                type:                  key.child_get_string("type"), 
                containingaggr:        key.child_get_string("containing-aggregate"),
                sizetotal:             key.child_get_string("size-total"),
                sizeused:              key.child_get_string("size-used"),
                sizeavail:             key.child_get_string("size-available"),
                percentageused:        key.child_get_string("percentage-used"),
                filestotal:            key.child_get_string("files-total"),
                filesused:             key.child_get_string("files-used"),
                cloneparent:           key.child_get_string("clone-parent"),
                clonechildren:         key.child_get_string("clone-children"),
                ischecksumenabled:     key.child_get_string("is-checksum-enabled"),
                checksumstyle:         key.child_get_string("checksum-style"),
                compression:           key.child_get_string("compression"), 
                isinconsistent:        key.child_get_string("is-inconsistent"),
                isinvalid:             key.child_get_string("is-invalid"), 
                isunrecoverable:       key.child_get_string("is-unrecoverable"), 
                iswraparound:          key.child_get_string("is-wraparound"), 
                issnaplock:            key.child_get_string("is-snaplock"), 
                expirydate:            key.child_get_string("expiry-date"), 
                mirrorstatus:          key.child_get_string("mirror-status"), 
                raidsize:              key.child_get_string("raid-size"),
                raidstatus:            key.child_get_string("raid-status"),
                owningvfiler:          key.child_get_string("owning-vfiler"), 
                quotainit:             key.child_get_string("quota-init"), 
                remotelocation:        key.child_get_string("remote-location"), 
                reserve:               key.child_get_string("reserve"), 
                reserverequired:       key.child_get_string("reserve-required"), 
                reserveused:           key.child_get_string("reserve-used"), 
                reservedusedact:       key.child_get_string("reserve-used-actual"), 
                snaplocktype:          key.child_get_string("snaplock-type"), 
                snapshotblkreserved:   key.child_get_string("snapshot-blocks-reserved"), 
                snapshotperreserved:   key.child_get_string("snapshot-percent-reserved"), 
                spacereserveenabled:   key.child_get_string("space-reserve-enabled"), 
                spacereserve:          key.child_get_string("space-reserve"), 
                diskcount:             key.child_get_string("disk-count"), 
                plexcount:             key.child_get_string("plex-count"),
                plexes:                plexes
                # add SIS and snaplock data
            }
        end
        return result
    end
    def self.size(volname)
        vol_size = @@filer.invoke("volume-size", 
                                  "volume", volname)
        raise vol_size.results_reason \
              if vol_size.results_status == 'failed'
        return result = vol_size.child_get_string("volume-size")
    end
    def self.resize(volname, newsize)
        vol_resize = @@filer.invoke("volume-size", 
                                    "volume", volname,
                                    "new-size", newsize)
        raise vol_resize.results_reason \
              if vol_resize.results_status == 'failed'
        return true
    end
    # TODO: 
    # implement volume-move-*
end

class Snapshot < Filer
    def self.create(name, volname)
        snapshot_create = @@filer.invoke("snapshot-create", 
                                         "snapshot", name, 
                                         "volume", volname)
        raise snapshot_create.results_reason \
              if snapshot_create.results_status == 'failed'
        return true
    end
    def self.purge(name, volname)
        snapshot_delete = @@filer.invoke("snapshot-delete", 
                                         "snapshot", name,
                                         "volume", volname)
        raise snapshot_delete.results_reason \
              if snapshot_delete.results_status == 'failed'
        return true
    end
    def self.rename(volume, name, newname)
        snapshot_rename = @@filer.invoke("snapshot-rename", 
                                         "volume", volname,
                                         "current-name", name,
                                         "new-name", newname)
        raise snapshot_rename.results_reason \
              if snapshot_rename.results_status == 'failed'
        return true
    end
    def self.delta(snap1, snap2, volname)
        snapshot_delta = @@filer.invoke("snapshot-delta-info", 
                                        "volume", volname,
                                        "snapshot1", snap1,
                                        "snapshot2", snap2)
        raise snapshot_delta.results_reason \
              if snapshot_delta.results_status == 'failed'
        result = {}
        return result = {
            consumedsize:     snapshot_delta.child_get_string("consumed-size"),
            elapsedtime:      snapshot_delta.child_get_string("elapsed-time")
        }
    end
    def self.delta_to_volume(snap, volname)
        snapshot_delta = @@filer.invoke("snapshot-delta-info", 
                                        "volume", volname,
                                        "snapshot1", snap)
        raise snapshot_delta.results_reason \
              if snapshot_delta.results_status == 'failed'
        result = {}
        return result = {
            consumedsize:     snapshot_delta.child_get_string("consumed-size"),
            elapsedtime:      snapshot_delta.child_get_string("elapsed-time")
        }
    end
    def self.reserve(volname)
        snapshot_reserve = @@filer.invoke("snapshot-get-reserve", 
                                          "volume", volname)
        raise snapshot_reserve.results_reason \
              if snapshot_reserve.results_status == 'failed'
        result = {}
        return result = {
            blocksreserved:     snapshot_reserve.child_get_string("blocks-reserved"),
            percentreserved:    snapshot_reserve.child_get_string("percent-reserved")
        }
    end
    def self.schedule(volname)
        snapshot_schedule = @@filer.invoke("snapshot-get-schedule", 
                                           "volume", volname)
        raise snapshot_schedule.results_reason \
              if snapshot_schedule.results_status == 'failed'
        result = {}
        return result = {
            days:          snapshot_schedule.child_get_string("days"),
            hours:         snapshot_schedule.child_get_string("hours"),
            minutes:       snapshot_schedule.child_get_string("minutes"),
            weeks:         snapshot_schedule.child_get_string("weeks"),
            whichhours:    snapshot_schedule.child_get_string("which-hours"),
            whichminutes:  snapshot_schedule.child_get_string("which-minutes")
        }
    end
    def self.info(volname)
        snapshot_info = @@filer.invoke("snapshot-list-info", 
                                       "volume", volname)
        raise snapshot_info.results_reason \
              if snapshot_info.results_status == 'failed'
        result = {}
        snapshot_info.child_get("snapshots").children_get.each do |key|
            result = {
                name:                     key.child_get_string("name"),
                accesstime:               key.child_get_string("access-time"),
                busy:                     key.child_get_string("busy"),
                containslunclones:        key.child_get_string("contains-lun-clones"), 
                cumpercentageblockstotal: key.child_get_string("cumulative-percentage-of-total-blocks"),
                cumpercentageblocksused:  key.child_get_string("cumulative-percentage-of-used-blocks"),
                cumtotal:                 key.child_get_string("cumulative-total"),
                dependency:               key.child_get_string("dependency"),
                percentageblockstotal:    key.child_get_string("percentage-of-total-blocks"),
                percentageblocksused:     key.child_get_string("percentage-of-used-blocks"),
                total:                    key.child_get_string("total")
            }
        end
        return result
    end
end

class Qtree < Filer
    def self.create(qtreename, volname)
        qtree_create = @@filer.invoke("qtree-create", 
                                      "qtree", qtreename, 
                                      "volume", volname)
        raise qtree_create.results_reason \
              if qtree_create.results_status == 'failed'
        return true
    end
    def self.purge(qtreename)
        qtree_delete = @@filer.invoke("qtree-delete", 
                                      "qtree", qtreename)
        raise qtree_delete.results_reason \
              if qtree_delete.results_status == 'failed'
        return true
    end
    def self.list
        qtree_list = @@filer.invoke("qtree-list")
        raise qtree_list.results_reason \
              if qtree_list.results_status == 'failed'
        result = {}
        qtree_list.child_get("qtrees").children_get.each do |key|
            result[qtree: key.child_get_string("qtree")] = {
                volume: key.child_get_string("volume")
            }
        end
        return result
    end
    def self.info(volname)
        qtree_list = @@filer.invoke("qtree-list",
                                    "volume", volname)
        raise qtree_list.results_reason \
              if qtree_list.results_status == 'failed'
        result = {}
        qtree_list.child_get("qtrees").children_get.each do |key|
            result[id: key.child_get_string("id")] = {
                qtree:          key.child_get_string("qtree"),
                volume:         key.child_get_string("volume"),
                status:         key.child_get_string("status"),
                oplocks:        key.child_get_string("oplocks"),
                owningvfiler:   key.child_get_string("owning-vfiler"),
                securitystyle:  key.child_get_string("security-style")
            }
        end
        return result
    end
end

class Quota < Filer
    def self.create(qtreename="", volname, path, quotasize, type)
        quota_create = @@filer.invoke("quota-add-entry", 
                                      "qtree", qtreename, 
                                      "volume", volname, 
                                      "quota-target", path, 
                                      "soft-disk-limit", quotasize, 
                                      "quota-type", type) 
        raise quota_create.results_reason \
              if quota_create.results_status == 'failed'
        return true
    end
    def self.purge(qtreename="", volname, path, type)
        quota_delete = @@filer.invoke("quota-delete-entry", 
                                      "qtree", qtreename, 
                                      "volume", volname, 
                                      "quota-target", path, 
                                      "quota-type", type) 
        raise quota_delete.results_reason \
              if quota_delete.results_status == 'failed'
        return true
    end
    def self.on(volname)
        quota_on = @@filer.invoke("quota-on", 
                                  "volume", volname) 
        raise quota_on.results_reason \
              if quota_on.results_status == 'failed'
        return true
    end
    def self.off(volname)
        quota_off = @@filer.invoke("quota-off", 
                                   "volume", volname) 
        raise quota_off.results_reason \
              if quota_off.results_status == 'failed'
        return true
    end
    def self.get_entry(qtreename, volname, path, type)
        quota_get_entry = @@filer.invoke("quota-get-entry", 
                                         "qtree", qtreename, 
                                         "volume", volname, 
                                         "quota-target", path, 
                                         "quota-type", type) 
        raise quota_get_entry.results_reason \
              if quota_get_entry.results_status == 'failed'
        return true
    end
    def self.list
        quota_list_entries = @@filer.invoke("quota-list-entries")
        raise quota_list_entries.results_reason \
              if quota_list_entries.results_status == 'failed'
        result = {}
        quota_list_entries.child_get("quota-entries").children_get.each do |key|
            result[qtree: key.child_get_string("qtree")] = {
                line:           key.child_get_string("line"),
                volume:         key.child_get_string("volume"),
                quotaerror:     key.child_get_string("quota-error"),
                quotatarget:    key.child_get_string("quota-target"),
                quotatype:      key.child_get_string("quota-type")
            }
        end
    end
    def self.status(volname)
        quota_status = @@filer.invoke("quota-status", 
                                      "volume", volname) 
        raise quota_status.results_reason \
              if quota_status.results_status == 'failed'
        return result = quota_status.child_get_string("status")
    end
    # XXX: no longer supported in NMSDK API as it seems
    #def self.user(userid, username, usertype)
    #    quota_user = @@filer.invoke("quota-user", 
    #                                "quota-user-id", userid,
    #                                "quota-user-name", username,
    #                                "quota-user-type", usertype) 
    #    if quota_user.results_status == 'failed'
    #        raise quota_user.results_reason
    #    end
    #end
end

class NFS < Filer
    def self.on
        nfs_on = @@filer.invoke("nfs-enable") 
        raise nfs_on.results_reason \
              if nfs_on.results_status == 'failed'
        return true
    end
    def self.off
        nfs_off = @@filer.invoke("nfs-disable") 
        raise nfs_off.results_reason \
              if nfs_off.results_status == 'failed'
        return true
    end
    def self.add_export(pathname, type, anon=false, nosuid=false, allhosts=false, exports)
        #
        # - type = read-only || read-write || root 
        # - exports  = string (hostname, IP, subnet [CIDR])

        raise "unkown argument in type" unless type == "read-only" or \
                                               type == "read-write" or \
                                               type == "root"
        raise "empty pathname" if pathname.empty?

        nfs_exports_rule_info = NaElement.new("exports-rule-info")
        nfs_exports_rule_info.child_add_string("anon", anon) if anon
        nfs_exports_rule_info.child_add_string("nosuid", nosuid) if nosuid
        nfs_exports_rule_info.child_add_string("pathname", pathname)

        nfs_exports = NaElement.new(type)
        nfs_exports_host = NaElement.new("exports-hostname-info")
        nfs_exports_host.child_add_string("all-hosts", true) if allhosts == true
        nfs_exports_host.child_add_string("name", exports) if exports

        nfs_exports.child_add(nfs_exports_host)
        nfs_exports_rule_info.child_add(nfs_exports)

        nfs_rules = NaElement.new("rules")
        nfs_rules.child_add(nfs_exports_rule_info)

        nfs_exports_invoke = NaElement.new("nfs-exportfs-append-rules")
        nfs_exports_invoke.child_add(nfs_rules)
        nfs_exports_invoke.child_add_string("verbose", true)

        nfs_add_export = @@filer.invoke_elem(nfs_exports_invoke)
        raise nfs_add_export.results_reason \
              if nfs_add_export.results_status == 'failed'
        return true
    end
    def self.del_export(pathname)
        nfs_exports_path_del = NaElement.new("pathname-info")
        nfs_exports_path_del.child_add_string("name", pathname)

        nfs_pathnames = NaElement.new("pathnames")
        nfs_pathnames.child_add(nfs_exports_path_del)

        nfs_exports_invoke = NaElement.new("nfs-exportfs-delete-rules")
        nfs_exports_invoke.child_add(nfs_pathnames)
        nfs_exports_invoke.child_add_string("verbose", true)

        nfs_del_export = @@filer.invoke_elem(nfs_exports_invoke)
        raise nfs_del_export.results_reason \
              if nfs_del_export.results_status == 'failed'
        return true
    end
    def self.status
        nfs_status = @@filer.invoke("nfs-status")
        raise nfs_status.results_reason \
              if nfs_status.results_status == 'failed'
        return result = {
            isdrained:          nfs_status.child_get_string("is-drained"),
            isenabled:          nfs_status.child_get_string("is-enabled")
        }
    end
end

class Vfiler < Filer
    def self.create(name, ipaddr, storage)
        vfiler_create = @@filer.invoke("vfiler-create", 
                                       "vfiler", name,
                                       "ip-addresses", ipaddr,
                                       "storage-units", storage) 
        raise vfiler_create.results_reason \
              if vfiler_create.results_status == 'failed'
        return true
    end
    def self.purge(name)
        vfiler_delete = @@filer.invoke("vfiler-destroy", 
                                       "vfiler", name) 
        raise vfiler_delete.results_reason \
              if vfiler_delete.results_status == 'failed'
        return true
    end
    def self.add_storage(name, storage)
        vfiler_add_stroage = @@filer.invoke("vfiler-add-storage", 
                                            "vfiler", name,
                                            "storage-path", storage) 
        raise vfiler_add_stroage.results_reason \
              if vfiler_add_stroage.results_status == 'failed'
        return true
    end
    # vfiler-add-ipaddress, setup, start, stop, migrate, status, list
end

class Diag < Filer
    def self.status
        # "Overall system health (ok,ok-with-suppressed,degraded,
        # unreachable) as determined by the diagnosis framework"
        diag_status = @@filer.invoke("diagnosis-status-get") 
        raise diag_status.results_reason \
              if diag_status.results_status == 'failed'
        stat = diag_status.child_get("attributes").children_get
        stat.each { |k| return k.child_get_string("status") }
    end
end

#EOF
