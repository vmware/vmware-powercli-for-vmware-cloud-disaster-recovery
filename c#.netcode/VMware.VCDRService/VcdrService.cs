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

        private const String UNKNOW_REGION = "unknow";



        public string OrgId
        {
            get
            {
                return (TokenDetails != null) ? TokenDetails.OrgId : String.Empty;
            }
        }

        private readonly string Token;

        
        public Boolean Verbose { get; set; } 
        private readonly Timer? timer; 
        private readonly CloudServicePlatform csp;
        private ApiTokenDetailsDto? TokenDetails { get; set; }
        private List<TenantDeployment> VcdrDeployment { get; set; }
        private Dictionary<String, VCDRServer> VcdrInstances { get; set; } 
        public VCDRServer? ActiveVcdrInstance { get; private set; }
        public string AccessToken { get; private set; }
         

        private readonly VcdrBackendPlatform? VcdrBackend;

        private readonly HttpClient _httpClient;

        public int NumberOfRegions { get; private set; }


        public VcdrService(String token, String? cspBaseUrl = null, String? vcdrBackendUrl = null)
        {
            if (Verbose) System.Console.WriteLine("Start Constructor");
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
                    VCDRServer vcdrServer = new VCDRServer(httpClient, new VcdrDeployment(item));
                    VcdrInstances.Add(vcdrServer.Region, vcdrServer);
                    if (ActiveVcdrInstance == null) ActiveVcdrInstance = vcdrServer;
                }
                NumberOfRegions = VcdrInstances.Count;

            }
            else throw new VcdrException("Connection failed", 1);
            if (Verbose) System.Console.WriteLine("End Constructor");
        }



        public VcdrService(String token, Uri server, String? cspBaseUrl = null)
        {
            if (Verbose) System.Console.WriteLine("Start Constructor");
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
                VcdrDeployment = new List<TenantDeployment>();

                var httpClient = new HttpClient();
                httpClient.DefaultRequestHeaders.Add("x-da-access-token", AccessToken);
                VCDRServer vcdrServer = new VCDRServer(httpClient, server, OrgId, UNKNOW_REGION);                
                VcdrInstances.Add(vcdrServer.Region, vcdrServer);
                ActiveVcdrInstance = vcdrServer;
                NumberOfRegions = VcdrInstances.Count;

            }
            else throw new VcdrException("Connection failed", 1);
            if (Verbose) System.Console.WriteLine("End Constructor");
        }


        public void Disconnect()
        {
            if (Verbose) System.Console.WriteLine("Start Disconnect");
            if (timer != null)
                timer.Dispose();
            if (_httpClient != null)
                _httpClient.Dispose();
            if (Verbose) System.Console.WriteLine("End Disconnect");
        }

        public Boolean CompareToken(String token)
        {
            return token == Token;
        }
       


        public List<VcdrSummary> GetVcdrInstances(String region = "")
        {
            var result = new List<VcdrSummary>();
            foreach (var item in VcdrInstances.Values)
            {
                if (String.IsNullOrEmpty(region))
                {
                    result.Add(new VcdrSummary(item));
                }
                else if (item.Region == region)
                {
                    result.Add(new VcdrSummary(item)); 
                    break;
                }
            }
            return result;
        }

        public VCDRServer SelectRegion(String region = "")
        {
            if (String.IsNullOrEmpty (region) )
            {
                ActiveVcdrInstance = VcdrInstances.ElementAt(0).Value;
                return ActiveVcdrInstance;
            }
            if (VcdrInstances.ContainsKey(region))
            {
                ActiveVcdrInstance = VcdrInstances[region];
                return VcdrInstances[region];
            }
            foreach (var item in VcdrDeployment)
            {
              if (item.Config.Cloud_provider.Region == region)
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
         
        /// <summary>
        /// Get Active Region
        /// </summary>
        /// <returns></returns>
        public List<String> GetActiveRegions()
        {
            var result = new List<String>();
            if (VcdrDeployment.Count==0)
            {
                result.Add(UNKNOW_REGION);
            }
            else
            {
                foreach (var item in VcdrDeployment)
                {
                    if (item.State == DeploymentStatesEnum.READY)
                    {
                        result.Add(item.Config.Cloud_provider.Region);
                    }
                }
            }
            return result;
        }

        private List<TenantDeployment> GetVCDRList(String org)
        {
            var result = new List<TenantDeployment>();
            if (VcdrBackend != null)
            {
           //     VcdrBackend.ReadResponseAsString = true;
                var deployments = VcdrBackend.GetVcdrDeployments(new Guid(org));
                foreach (var item in deployments)
                {
                    if (item.State == DeploymentStatesEnum.READY)
                    {
                        result.Add(item);
                    }
                }
            }
            return result;
        }
      
        public virtual TenantDeployment? GetOrchestrator(String region, String org = "")
        {
            if (String.IsNullOrEmpty(org))
            {
                org = OrgId;
            }
            if (VcdrBackend != null)
            {
                var deployments = VcdrBackend.GetVcdrDeployments(new Guid(org));
                foreach (var item in deployments)
                {
                    if (item.State == DeploymentStatesEnum.READY && item.Config.Cloud_provider.Region == region)
                    {
                        return item;
                    }
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
