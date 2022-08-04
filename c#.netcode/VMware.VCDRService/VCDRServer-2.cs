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

namespace VMware.VCDRService
{
    using System;
    using System.Threading;
    using System.Net.Http;
    using System.Collections.Generic;
    using System.Net;

    public partial class VCDRServer
    {
        public string BaseUrl
        {
            get { return String.Concat("https://", Irr.Server, "/api/vcdr/", Version); }
        }

        public string Version { get; set; }

        public string Region { get; private set; }
        public string OrgId { get; private set; }
        public CloudProvidersEnum Provider { get; }
        public IrrServer Irr { get; private set; }
        public Boolean Verbose { get; set; }

        public VCDRServer(System.Net.Http.HttpClient httpClient, VcdrDeployment item)
            : this(httpClient)
        {
            Version = "v1alpha";
            Irr = new IrrServer(item.Irr);
            Region = item.Region;
            OrgId = item.OrgId;
            Provider = item.Provider;
        }

        public VCDRServer(System.Net.Http.HttpClient httpClient, Uri irr,String orgId,String region)
            : this(httpClient)
        {
            Version = "v1alpha";
            Irr = new IrrServer
            {

                Ip = Dns.GetHostAddresses(irr.Host)[0].ToString(),
                Url = irr.ToString(),
                Version = this.Version,
                Server = irr.Host
            };
            Region = region;
            OrgId = orgId;
            //Provider = item.Provider;
        }



        partial void UpdateJsonSerializerSettings(Newtonsoft.Json.JsonSerializerSettings settings)
        {
            settings.MaxDepth = 120;
        }

        /// <summary>
        /// Get a list of all deployed cloud file systems in your VMware Cloud DR organization.
        /// </summary>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetCloudFileSystemsResponse GetCloudFileSystems()
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetCloudFileSystemsAsync(System.Threading.CancellationToken.None)
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// Get a list of all protected sites associated with an individual cloud file system.
        /// </summary>
        /// <param name="cloudFileSystem">Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of all protected sites.</param>
        /// <param name="limit">The maximum number of results to return with the call. The maximum is 500, and the default is 50 results. &lt;p&gt;&lt;b&gt;Note&lt;/b&gt;&amp;colon; The pre-release version of this API differs from this documentation. This parameter is ignored.</param>
        /// <param name="filter_spec">Used to filter the results. &lt;p&gt;&lt;b&gt;Note&lt;/b&gt;&amp;colon; The pre-release version of this API differs from this documentation. This parameter is ignored. All protected sites are returned.</param>
        /// <param name="cursor">An opaque string previously returned by this API that can be passed to this API in order to get the next set of results. If this property is not passed, enumeration of starts from the beginning. &lt;p&gt;&lt;b&gt;Note&lt;/b&gt;&amp;colon; The pre-release version of this API differs from this documentation. This parameter is ignored. All protected sites are returned when making this API call.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetProtectedSitesResponse GetProtectedSites(
            CloudFileSystem cloudFileSystem,
            int? limit,
            ProtectedSitesFilterSpec filter_spec,
            string cursor
        )
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectedSitesAsync(
                            cloudFileSystem.Id,
                            limit,
                            filter_spec,
                            cursor,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// Get a list of all protected VMs currently being replicated to the specified cloud file system. VMs will not be returned if they are not contained within at least one protection group snapshot in the specified cloud file system.
        /// </summary>
        /// <param name="cloudFileSystem">Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system from where you want to get a list of all protected VMs.</param>
        /// <param name="limit">The maximum number of results to return with the call. The maximum is 500, and the default is 50 results.</param>
        /// <param name="filter_spec">Used to filter the results.</param>
        /// <param name="cursor">An opaque string previously returned by this API that can be passed to this API in order to get the next set of results. If this property is not passed, enumeration of starts from the beginning.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetProtectedVirtualMachinesResponse GetProtectedVirtualMachines(
            CloudFileSystem cloudFileSystem,
            int? limit,
            VmsFilterSpec filter_spec,
            string cursor
        )
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectedVirtualMachinesAsync(
                            cloudFileSystem.Id,
                            limit,
                            filter_spec,
                            cursor,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// List VMware Cloud (VMC) Recovery Software-Defined Datacenters (SDDCs).
        /// </summary>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetRecoverySddcResponse GetRecoverySddc()
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () => await GetRecoverySddcAsync(System.Threading.CancellationToken.None)
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// Get a list of all snapshots in a specific protection group.
        /// </summary>
        /// <param name="protectionGroup">Unique identifier of the protection group you want to get a list of snapshots from.</param>
        /// <param name="limit">The maximum number of results to return with the call. The maximum is 500, and the default is 50 results.</param>
        /// <param name="cursor">An opaque string previously returned by this API that can be passed to this API in order to get the next set of results. If this property is not passed, enumeration of starts from the beginning.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetProtectionGroupSnapshotsResponse GetProtectionGroupSnapshots(
            ProtectionGroup protectionGroup,
            int? limit,
            string cursor
        )
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectionGroupSnapshotsAsync(
                            protectionGroup.CloudFileSystem.Id,
                            protectionGroup.Id,
                            limit,
                            cursor,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// Get a list of all protection groups associated with an individual cloud file system.
        /// </summary>
        /// <param name="cloudFileSystem">Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system from where you want to get a list of all protected VMs.</param>
        /// <param name="limit">The maximum number of results to return with the call. The maximum is 500, and the default is 50 results.</param>
        /// <param name="filter_spec">Used to filter the results.</param>
        /// <param name="cursor">An opaque string previously returned by this API that can be passed to this API in order to get the next set of results. If this property is not passed, enumeration of starts from the beginning.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual GetProtectionGroupsResponse GetProtectionGroups(
            CloudFileSystem cloudFileSystem,
            int? limit,
            ProtectionGroupsFilterSpec filter_spec,
            string cursor
        )
        {
            return System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectionGroupsAsync(
                            cloudFileSystem.Id,
                            limit,
                            filter_spec,
                            cursor,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
        }

        /// <summary>
        /// Get details about an individual protected site.
        /// </summary>
        /// <param name="cloudFileSystem">Unique identifier of an individual cloud file system. Use the cloud file system ID of the cloud file system for which you want to get a list of all protected sites.</param>
        /// <param name="id">The unique identifier of the individual protected site for which you want to get details.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual ProtectedSite GetProtectedSiteDetails(
            CloudFileSystem cloudFileSystem,
            string id
        )
        {
            var p = System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectedSiteDetailsAsync(
                            cloudFileSystem.Id,
                            id,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
            var result = new ProtectedSite(p) { CloudFileSystem = cloudFileSystem };
            return result;
        }

        /// <summary>
        /// Get details for the requested protection group.
        /// </summary>
        /// <param name="cloudFileSystem">The cloud file system containing the protection group of interest.</param>
        /// <param name="id">The protection group of interest.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual ProtectionGroup GetProtectionGroupDetails(
            CloudFileSystem cloudFileSystem,
            string id
        )
        {
            var p = System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectionGroupDetailsAsync(
                            cloudFileSystem.Id,
                            id,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
            ProtectionGroup result = new ProtectionGroup(p) { CloudFileSystem = cloudFileSystem };
            return result;
        }

        /// <summary>
        /// Get details of a specific Recovery SDDC.
        /// </summary>
        /// <param name="id">The Recovery SDDC of interest.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual RecoverySddc GetRecoverySddcDetails(string id)
        {
            var p = System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetRecoverySddcDetailsAsync(
                            id,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
            var result = new RecoverySddc(p);
            return result;
        }

        /// <summary>
        /// Get detailed information for a protection group snapshot.
        /// </summary>
        /// <param name="protectionGroup">The protection group associated with the protection group snapshot of interest.</param>
        /// <param name="id">The protection group snapshot of interest.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual ProtectionGroupSnapshotDetails GetProtectionGroupSnapshotDetails(
            ProtectionGroup protectionGroup,
            string id
        )
        {
            var p = System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetProtectionGroupSnapshotDetailsAsync(
                            protectionGroup.CloudFileSystem.Id,
                            protectionGroup.Id,
                            id,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
            var result = new ProtectionGroupSnapshot(p) { ProtectionGroup = protectionGroup };
            return result;
        }

        /// <summary>
        /// Get details for an individual cloud file system.
        /// </summary>
        /// <param name="id">The identifier of the cloud file system.</param>
        /// <returns>OK. The request succeeded.</returns>
        /// <exception cref="ApiException">A server side error occurred.</exception>
        public virtual CloudFileSystem GetCloudFileSystemDetails(string id)
        {
            var p = System.Threading.Tasks.Task
                .Run(
                    async () =>
                        await GetCloudFileSystemDetailsAsync(
                            id,
                            System.Threading.CancellationToken.None
                        )
                )
                .GetAwaiter()
                .GetResult();
            var result = new CloudFileSystem(this, p) { IRRServer = this.Irr.Server };
            return result;
        }
    }
}
