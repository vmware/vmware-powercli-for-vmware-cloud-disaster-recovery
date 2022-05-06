using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using VMware.VCDRService;

namespace VCDRTest
{
    internal class VCDRtest
    {
        private void Doit(String server, String token)
        { 
            Console.WriteLine("Hello, VCDR!"); 
            var client = new VCDRServer(token, VMCEnviroment.Production)
            { 
                Server = server 
            };


            var rSddcs = client.GetRecoverySddc();
            if (rSddcs.Data != null)
            {
                foreach (var rSddc in rSddcs.Data)
                {
                    var rsddcDetails = client.GetRecoverySddcDetails(rSddc.Id);
                    Console.WriteLine(rsddcDetails.Id + " " + rsddcDetails.Name + " " + rsddcDetails.Region + " " + rsddcDetails.Availability_zones);
                }
            }

            var list = client.GetCloudFileSystems();
            if (list.Cloud_file_systems != null)
            {
                foreach (var p in list.Cloud_file_systems)
                {
                    var p133 = client.GetCloudFileSystemDetails(p.Id);
                    Console.WriteLine(p.Id + " " + p.Name);
                    ProtectedSitesFilterSpec protectedSitesFilterSpec = new ProtectedSitesFilterSpec
                    {
                        Protection_group_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };
                    protectedSitesFilterSpec.Protection_group_ids.Add("");
                    protectedSitesFilterSpec.Vcenter_ids.Add("");

                    String? cursor = null;

                    var ps = client.GetProtectedSites(p.Id, null, protectedSitesFilterSpec, cursor);
                    if (ps.Protected_sites != null)
                    {
                        foreach (var p3 in ps.Protected_sites)
                        {
                            var psd = client.GetProtectedSiteDetails(p.Id, p3.Id);
                            Console.WriteLine(psd.Id + " " + psd.Name + " " + psd.Type);

                        }
                    }

                    VmsFilterSpec vmsFilter = new VmsFilterSpec()
                    {
                        Protection_group_ids = new List<string>(),
                        Protection_group_snapshot_id = new List<string>(),
                        Site_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };

                    var vms = client.GetProtectedVirtualMachines(p.Id, null, vmsFilter, cursor);
                    if (vms.Vms != null)
                    {
                        foreach (var vm in vms.Vms)
                        {
                            Console.WriteLine(vm.Id + " " + vm.Name + " " + vm.Size);
                        }
                    }
                    cursor = null;
                    ProtectionGroupsFilterSpec protectionGroupsFilterSpec = new ProtectionGroupsFilterSpec
                    {
                        Site_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };
                    var pgg = client.GetProtectionGroups(p.Id, null, protectionGroupsFilterSpec, cursor);
                    if (pgg.Protection_groups != null)
                    {
                        foreach (var protectionGroup in pgg.Protection_groups)
                        {
                            cursor = null;
                            var pgsnaphot = client.GetProtectionGroupSnapshots(p.Id, protectionGroup.Id, null, cursor);
                            if (pgsnaphot.Snapshots != null)
                            {
                                cursor = pgsnaphot.Cursor;

                                foreach (var p4 in pgsnaphot.Snapshots)
                                {
                                    var protectionGroupSnapshotDetails = client.GetProtectionGroupSnapshotDetails(p.Id, protectionGroup.Id, p4.Id);
                                    Console.WriteLine(protectionGroupSnapshotDetails.Id + " " + protectionGroupSnapshotDetails.Name);
                                }

                                var pgdetails = client.GetProtectionGroupDetails(p.Id, protectionGroup.Id);
                                Console.WriteLine(pgdetails.Id + " " + pgdetails.Name);

                            }
                        }
                    }

                }
            }




        }

        public static int Main(string[] args)
        {
            if (args.Length != 2)
            {
                System.Console.WriteLine("Please enter a server and token arguments.");
                return 1;
            }
            var p = new VCDRtest();
            p.Doit(args[0],args[1]);

            Console.WriteLine("Bye!");
            return 0;
        }
    }
}