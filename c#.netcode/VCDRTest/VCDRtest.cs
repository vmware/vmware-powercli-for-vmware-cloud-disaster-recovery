/*******************************************************************************
* Copyright (C) 2022, VMware Inc
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*    this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the documentation
*    and/or other materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
******************************************************************************/

using System;
using System.Collections.Generic; 
using VMware.VCDRService; 

namespace VCDRTest
{
    internal class VcdrTest
    {

        const String StageCSP = "https://console-stg.cloud.vmware.com/csp/gateway/am/api";
        const String StageVCDRBackend = "https://vcdrsp-stg-vcdr-backend-res01-stg-us-west-2.vdp-int-stg.vmware.com/api/vcdr";




        private void DoitService(String token, String region, Boolean production = true)
        {
            Console.WriteLine("Hello, VCDR!");
            VcdrService clientService = (production) ? new VcdrService(token) : new VcdrService(token, StageCSP, StageVCDRBackend);

            var client = clientService.SelectRegion(region);

            RunTest(client);
        }

        private void DoitService(String token, Uri server, Boolean production = true)
        {
            Console.WriteLine("Hello, VCDR!");
            VcdrService clientService = (production) ? new VcdrService(token, server) : new VcdrService(token, server,StageCSP);

            var client = clientService.SelectRegion( );

            RunTest(client);
        }


        internal void RunTest(VCDRServer client)
        { 
            var rSddcs = client.GetRecoverySddc();
            if (rSddcs.Data != null)
            {
                Console.WriteLine("Recovery SDDCs");
                foreach (var rSddc in rSddcs.Data)
                {
                    var rsddcDetails = client.GetRecoverySddcDetails(rSddc.Id);
                    Console.Write("Id: " + rsddcDetails.Id + " Name: " + rsddcDetails.Name + "  Region: " + rsddcDetails.Region + " Availability Zones: ");

                    foreach (var item in rsddcDetails.Availability_zones)
                    {
                        Console.Write(item + " ");
                    }
                    Console.WriteLine();
                }
            }

            var list = client.GetCloudFileSystems();
            if (list.Cloud_file_systems != null)
            {
                Console.WriteLine("CloudFile Systems:");
                foreach (var cfs in list.Cloud_file_systems)
                {
                    var cloudFileSystem = client.GetCloudFileSystemDetails(cfs.Id);
                    Console.WriteLine("Id: " + cloudFileSystem.Id + " Name: " + cloudFileSystem.Name + " IRRServer(URL):" + cloudFileSystem.IRRServer + " Capacity(GB): " + cloudFileSystem.Capacity_gib + " Used Capacity (GB): " + cloudFileSystem.Used_gib + " Recovery SDDC Id: " + cloudFileSystem.Recovery_sddc_id);
                    ProtectedSitesFilterSpec protectedSitesFilterSpec = new ProtectedSitesFilterSpec
                    {
                        Protection_group_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };
                    protectedSitesFilterSpec.Protection_group_ids.Add("");
                    protectedSitesFilterSpec.Vcenter_ids.Add("");

                    String cursor = String.Empty;
                    Console.WriteLine("ProtectedSite: ");
                    do
                    {
                        var ps = client.GetProtectedSites(cloudFileSystem, null, protectedSitesFilterSpec, cursor);
                        if (ps.Protected_sites != null)
                        {
                            foreach (var p3 in ps.Protected_sites)
                            {
                                var psd = client.GetProtectedSiteDetails(cloudFileSystem, p3.Id);
                                Console.WriteLine("Id: " + psd.Id + " Name: " + psd.Name + " Type:" + psd.Type + "CFS Id:" + psd.CloudFileSystem.Id);

                            }
                        }
                        cursor = ps.Cursor;
                    } while (!String.IsNullOrEmpty(cursor));

                    VmsFilterSpec vmsFilter = new VmsFilterSpec()
                    {
                        Protection_group_ids = new List<string>(),
                        Protection_group_snapshot_id = new List<string>(),
                        Site_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };
                    cursor = String.Empty;
                    do
                    {
                        var vms = client.GetProtectedVirtualMachines(cloudFileSystem, null, vmsFilter, cursor);
                        if (vms.Vms != null)
                        {
                            foreach (var vm in vms.Vms)
                            {
                                Console.WriteLine("Name: " + vm.Name +" id:"+vm.Id.Id +" Size (MB): " + vm.Size * 1024F);
                            }
                        }
                        cursor = vms.Cursor;
                    } while (!String.IsNullOrEmpty(cursor));
                    ProtectionGroupsFilterSpec protectionGroupsFilterSpec = new ProtectionGroupsFilterSpec
                    {
                        Site_ids = new List<string>(),
                        Vcenter_ids = new List<string>()
                    };
                    cursor = String.Empty;
                    do
                    {
                        var pgg = client.GetProtectionGroups(cloudFileSystem, null, protectionGroupsFilterSpec, cursor);
                        if (pgg.Protection_groups != null)
                        {
                            foreach (var protectionGroup in pgg.Protection_groups)
                            {
                                cursor = String.Empty;
                                do
                                {
                                    var pgdetails = client.GetProtectionGroupDetails(cloudFileSystem, protectionGroup.Id);
                                    Console.WriteLine(pgdetails.Id + " " + pgdetails.Name);
                                    var pgsnaphot = client.GetProtectionGroupSnapshots(pgdetails, null, cursor);
                                    if (pgsnaphot.Snapshots != null)
                                    {

                                        foreach (var p4 in pgsnaphot.Snapshots)
                                        {
                                            var protectionGroupSnapshotDetails = client.GetProtectionGroupSnapshotDetails(pgdetails, p4.Id);
                                            Console.WriteLine(protectionGroupSnapshotDetails.Id + " " + protectionGroupSnapshotDetails.Name);
                                        }


                                    }
                                    cursor = pgsnaphot.Cursor;
                                } while (!String.IsNullOrEmpty(cursor));
                            }
                        }
                        cursor = pgg.Cursor;
                    } while (!String.IsNullOrEmpty(cursor));

                }
            }
        }
        private static void Help()
        {
            Console.WriteLine("Help");
        }
        public static int Main(string[] args)
        { 
            Boolean production = true;
            String token = String.Empty;
            Uri? server = null;
            String region = String.Empty;  
            if (args.Length < 1 && args.Length > 3)
            {
                Help();
                return 1;
            }
            var p = new VcdrTest();

            for (int index = 0; index < args.Length; index += 2)
            {
                switch (args[index])
                {
                    case "-server":  
                        server = new UriBuilder("https", args[index + 1]).Uri;
                        break;
                    case "-env":
                        if (args[index + 1].Equals("production", StringComparison.OrdinalIgnoreCase))
                        {
                            production = true;
                        }
                        else if (args[index + 1].Equals("stage", StringComparison.OrdinalIgnoreCase))
                        {
                            production = false;
                        }
                        else
                        {
                            Console.WriteLine("Unknow enviroment " + args[index + 1] + " !!! Valid environment are production and stage");
                        }
                        break;
                    case "-token": token = args[index + 1]; break;
                    case "-region": region = args[index + 1]; break;
                    default:
                        Console.WriteLine("Help");
                        Help();
                        System.Environment.Exit(1);
                        break;
                }

            }
            if (!String.IsNullOrEmpty(token))
            {
                if (server != null)
                    p.DoitService(token, server, production);
                else
                    p.DoitService(token, region, production);

            }

            else
            {
                Console.WriteLine("token is required");
                Help();
            }

            Console.WriteLine("Bye!");
            return 0;
        }
    }
}