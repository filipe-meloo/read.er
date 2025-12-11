using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Read.er.Models.Posts;

namespace Read.er.Models.Communities;

/// <summary>
/// Represents a relationship between a community and a topic, detailing which topics belong to which communities.
/// </summary>
public class CommunityTopic
{
    [Key]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Required] public int CommunityId { get; set; }
    public Community Community { get; set; }

    [Required] public int TopicId { get; set; }
    public Topic Topic { get; set; }

    [Required] public bool IsBlocked { get; set; } = false;
}