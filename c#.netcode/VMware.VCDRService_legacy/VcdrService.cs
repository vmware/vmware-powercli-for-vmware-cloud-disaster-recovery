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
    using System.Linq;

    public class VcdrService  
    {



        public string OrgId
        {
            get
            {
                return (TokenDetails != null) ? TokenDetails.OrgId : String.Empty;
            }
        }

        private readonly string Token;

        
        public Boolean Verbose { get; set; }

#pragma warning disable IDE0052 // Remove unread private members
        private readonly Timer? timer;
#pragma warning restore IDE0052 // Remove unread private members
        private readonly CloudServicePlatform csp;
        private ApiTokenDetailsDto? TokenDetails { get; set; }
        private List<TenantDeployment> VcdrDeployment { get; set; }
        private Dictionary<String, VCDRServer> VcdrInstances { get; set; }

        public VCDRServer ActiveVcdrInstance { get; private set; }
        public string AccessToken { get; private set; }
         

        private readonly VcdrBackendPlatform VcdrBackend;

        private readonly HttpClient _httpClient;
        public VcdrService(String token, String? cspBaseUrl = null, String? vcdrBackendUrl = null)
        {
            this.Token = token;
            _httpClient = new HttpClient();
            VcdrInstances = new Dictionary<string, VCDRServer>();
            csp = new CloudServicePlatform(_httpClient);
            if (!String.IsNullOrEmpty(cspBaseUrl))
            {
                csp.BaseUrl = cspBaseUrl;
            }
            var _accessCode = csp.GetApiTokenAuthorize(new GetAccessTokenByApiRefreshTokenRequest() { Refresh_token = this.Token });
            if (_accessCode != null)
            {
                SetDefaultRequestHeaders(_accessCode.Access_token);
                AccessToken = _accessCode.Access_token;
                var tokenExpiration = _accessCode.Expires_in;
                var renewal = TimeSpan.FromSeconds(tokenExpiration - tokenExpiration / 4);
                timer = new Timer(callback: Callback, null, renewal, renewal);
                TokenDetails = csp.GetApiTokenDetails(new GetApiTokenDetailsRequest() { TokenValue = token });
                VcdrBackend = new VcdrBackendPlatform(_httpClient);
                if (!String.IsNullOrEmpty(vcdrBackendUrl))
                {
                    VcdrBackend.BaseUrl = vcdrBackendUrl;
                }
                VcdrDeployment = GetVCDRList(OrgId);
                foreach (var item in VcdrDeployment)
                {
                    var httpClient = new HttpClient();
                    httpClient.DefaultRequestHeaders.Add("x-da-access-token", AccessToken);
                    VCDRServer server = new VCDRServer(httpClient, item);
                    VcdrInstances.Add(item.Config.Cloud_provider.Region, server);
                }
                ActiveVcdrInstance = SelectRegion();
            }
            else throw new VcdrException("Connection failed", 1);
        }

        public void Disconnect()
        {
            if (Verbose)
            {
                System.Console.WriteLine("Start Disconnect");
            }
            if (timer != null)
                timer.Dispose();
            if (_httpClient != null)
                _httpClient.Dispose();
            if (Verbose)
            {
                System.Console.WriteLine("End Disconnect");
            }

        }

        public Boolean CompareToken(String token)
        {
            return token == Token;
        }
        /*
         *  
            us-east-2	US East (Ohio)
            us-east-1	US East (N. Virginia)
            us-west-1	US West (N. California)
            us-west-2	US West (Oregon)
            af-south-1	Africa (Cape Town)
            ap-east-1	Asia Pacific (Hong Kong)
            ap-southeast-3	Asia Pacific (Jakarta)
            ap-south-1	Asia Pacific (Mumbai)
            ap-northeast-3	Asia Pacific (Osaka)
            ap-northeast-2	Asia Pacific (Seoul)
            ap-southeast-1	Asia Pacific (Singapore)
            ap-southeast-2	Asia Pacific (Sydney)
            ap-northeast-1	Asia Pacific (Tokyo)
            ca-central-1	Canada (Central)
            eu-central-1	Europe (Frankfurt)
            eu-west-1	Europe (Ireland)
            eu-west-2	Europe (London)
            eu-south-1	Europe (Milan)
            eu-west-3	Europe (Paris)
            eu-north-1	Europe (Stockholm)
            me-south-1	Middle East (Bahrain)
            sa-east-1	South America (São Paulo)
        */


        public List<VcdrSummary> GetVcdrInstances()
        {
            var result = new List<VcdrSummary>();
            foreach (var item in VcdrInstances.Values)
            {
                result.Add(new VcdrSummary(item));

            }
            return result;
        }

        public VCDRServer SelectRegion(String region = "")
        { 
            
            if (VcdrInstances.ContainsKey(region)) { return VcdrInstances[region]; }
            foreach (var item in VcdrDeployment)
            {
                if (String.IsNullOrEmpty(region))
                {
                    ActiveVcdrInstance = VcdrInstances.ElementAt(0).Value;
                    return ActiveVcdrInstance;
                }
                else if (item.Config.Cloud_provider.Region == region)
                {
                    ActiveVcdrInstance = VcdrInstances[region];
                    return ActiveVcdrInstance;
                }
            }
            throw new VcdrException("Region: " + region + " - No VCDR instances in the region or the region doesn't exist", 10);
        }

        private void SetDefaultRequestHeaders(String accessToken)
        {
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("csp-auth-token", accessToken);
        }

        public List<String> GetActiveRegions()
        {
            var result = new List<String>();
            foreach (var item in VcdrDeployment)
            {
                if (item.State == DeploymentStatesEnum.READY)
                {
                    result.Add(item.Config.Cloud_provider.Region);
                }
            }
            return result;
        }

        private List<TenantDeployment> GetVCDRList(String org)
        {
            var result = new List<TenantDeployment>();
            var deployments = VcdrBackend.GetDeployments(org);
            foreach (var item in deployments)
            {
                if (item.State == DeploymentStatesEnum.READY)
                {
                    result.Add(item);
                }
            }
            return result;
        }
      
        public virtual TenantDeployment? GetOrchestrator(String region, String org = "")
        {
            if (String.IsNullOrEmpty(org))
                org = OrgId;
            var deployments = VcdrBackend.GetDeployments(org);
            foreach (var item in deployments)
            {
                if (item.State == DeploymentStatesEnum.READY && item.Config.Cloud_provider.Region == region)
                {
                    return item;
                }
            }
            return null;
        }
        public void Callback(object? state)
        {
            if (Verbose)
            {
                System.Console.WriteLine("Start renew token Endpoint:" + csp.BaseUrl);
            }
            var _accessCode = csp.GetApiTokenAuthorize(new GetAccessTokenByApiRefreshTokenRequest() { Refresh_token = Token });
            SetDefaultRequestHeaders(_accessCode.Refresh_token);

            if (Verbose)
            {
                System.Console.WriteLine("End renew token  Endpoint:" + csp.BaseUrl);
            }
        }
    }
    

}
