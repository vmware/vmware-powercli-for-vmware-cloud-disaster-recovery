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
    using System.Collections.Generic;
    using System.Text;

    public class VcdrDeployment
    {
        public String Region { get; set; }

        public IrrServer Irr { get; set; }
        public CloudProvidersEnum Provider { get; set; }

        public string OrgId { get; set; }

        public VcdrDeployment(TenantDeployment item)
        {
            Region = item.Config.Cloud_provider.Region;
            Irr = new IrrServer
            {
                Server = new Uri(item.Config.Orchestrator.Url).Host,
                Ip = item.Config.Orchestrator.Ip,
                Url = item.Config.Orchestrator.Url,
                Id = item.Id
            };

            OrgId = item.Org_id;
            Provider = item.Config.Cloud_provider.Provider;
        }

     
    }
}
