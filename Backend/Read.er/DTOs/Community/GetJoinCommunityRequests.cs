using System;
using System.ComponentModel.DataAnnotations;

namespace Read.er.DTOs.Community;

/// <summary>
/// Represents a request to join a community, identified by the CommunityId.
/// </summary>
public class GetJoinCommunityRequests
{

    [Required]
    public int CommunityId { get; set; }
}



