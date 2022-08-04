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

#pragma warning disable CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.
#pragma warning disable CS8602 // Dereference of a possibly null reference.

namespace VMware.VCDRService
{
    using System;
    using System.Threading;
    using System.Net.Http;

    /// <summary>
    /// Detailed information about an individual cloud file system.
    /// </summary>
    public class CloudFileSystem : CloudFileSystemDetails
    {
        public string IRRServer { get; set; }
        public VCDRServer Server { get; set; }

        public CloudFileSystem(VCDRServer server, CloudFileSystemDetails c)
        {
            this.Server = server;
            // copy base class properties.
            foreach (var prop in c.GetType().GetProperties())
            {
                var prop2 = c.GetType().GetProperty(prop.Name);
                prop2.SetValue(this, prop.GetValue(c, null), null);
            }
        }
    }

    /// <summary>
    /// Detailed information for protection groups.
    /// </summary>
    public class ProtectionGroup : ProtectionGroupDetails
    {
        /// <summary>
        /// Cloud file system unique identifier.
        /// </summary>
        public CloudFileSystem CloudFileSystem { get; set; }
        public VCDRServer Server
        {
            get { return CloudFileSystem.Server; }
        }

        public ProtectionGroup(ProtectionGroupDetails c)
        {
            // copy base class properties.
            foreach (var prop in c.GetType().GetProperties())
            {
                var prop2 = c.GetType().GetProperty(prop.Name);
                prop2.SetValue(this, prop.GetValue(c, null), null);
            }
        }
    }

    /// <summary>
    /// Detailed information about protected sites.
    /// </summary>
    public class ProtectedSite : ProtectedSiteDetails
    {
        /// <summary>
        /// Cloud file system unique identifier.
        /// </summary>
        public CloudFileSystem CloudFileSystem { get; set; }

        public ProtectedSite(ProtectedSiteDetails c)
        {
            // copy base class properties.
            foreach (var prop in c.GetType().GetProperties())
            {
                var prop2 = c.GetType().GetProperty(prop.Name);
                prop2.SetValue(this, prop.GetValue(c, null), null);
            }
        }
    }

    public class ProtectionGroupSnapshot : ProtectionGroupSnapshotDetails
    {
        /// <summary>
        /// Cloud file system unique identifier.
        /// </summary>
        public CloudFileSystem CloudFileSystem
        {
            get { return ProtectionGroup.CloudFileSystem; }
        }
        public ProtectionGroup ProtectionGroup { get; set; }

        public ProtectionGroupSnapshot(ProtectionGroupSnapshotDetails c)
        {
            // copy base class properties.
            foreach (var prop in c.GetType().GetProperties())
            {
                var prop2 = c.GetType().GetProperty(prop.Name);
                prop2.SetValue(this, prop.GetValue(c, null), null);
            }
        }
    }

    /// <summary>
    /// Detailed information about Recovery SDDCs.
    /// </summary>
    public class RecoverySddc : RecoverySddcDetails
    {
        public RecoverySddc(RecoverySddcDetails c)
        {
            // copy base class properties.
            foreach (var prop in c.GetType().GetProperties())
            {
                var prop2 = c.GetType().GetProperty(prop.Name);
                prop2.SetValue(this, prop.GetValue(c, null), null);
            }
        }
    }
}

#pragma warning restore CS8602 // Dereference of a possibly null reference.
#pragma warning restore CS8618 // Non-nullable field must contain a non-null value when exiting constructor. Consider declaring as nullable.
