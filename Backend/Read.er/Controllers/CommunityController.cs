using Amazon.S3;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using Amazon.S3;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Read.er.Data;
using Read.er.DTOs.Community;
using Read.er.Enumeracoes;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.Communities;
using Read.er.Models.Posts;

namespace Read.er.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CommunityController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly ITokenService _tokenService;
    private readonly S3Service _s3Service;

    public CommunityController(AppDbContext context, ITokenService tokenService, S3Service s3Service)
    {
        _context = context;
        _tokenService = tokenService;
        _s3Service = s3Service;
    }


    /// <summary>
    /// Creates a new community based on the provided community details.
    /// The caller must be a valid user with the role of Leitor.
    /// The community name must be unique and non-empty, and the description must not exceed 255 characters.
    /// </summary>
    /// <param name="model">An instance of CreateCommunityDto containing the details of the community to be created, including the name and description.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the community is created successfully.
    /// - Returns NotFound if the user is not found.
    /// - Returns Forbid if the user does not have the necessary permissions.
    /// - Returns Conflict if a community with the same name already exists.
    /// - Returns BadRequest if required fields are missing or invalid.
    /// </returns>
    [HttpPost("CreateCommunity")]
    public async Task<IActionResult> CreateCommunity([FromBody] CreateCommunityDto model)
    {
        var adminId = _tokenService.GetUserIdByToken();


        var user = await _context.Users.FindAsync(adminId);
        if (user == null) return NotFound("Utilizador não encontrado.");


        if (user.Role != Role.Leitor)
            return Forbid("Apenas utilizadores do tipo LEITOR podem criar e entrar em comunidades.");

        var existingCommunity = await _context.Communities
            .FirstOrDefaultAsync(c => c.Name == model.CommunityName);
        if (existingCommunity != null) return Conflict("Já existe uma comunidade com esse nome.");

        if (string.IsNullOrEmpty(model.CommunityName)) return BadRequest("O nome da Comunidade é obrigatório.");
        if (string.IsNullOrEmpty(model.CommunityDescritpion))
            return BadRequest("A descrição da comunidade é obrigatória.");

        if (model.CommunityName.Length > 50)
            return BadRequest("A descrição da comunidade não pode exceder 255 caracteres.");

        if (model.CommunityDescritpion.Length > 255)
            return BadRequest("A descrição da comunidade não pode exceder 255 caracteres.");

        var community = new Community
        {
            Name = model.CommunityName,
            AdminId = adminId,
            Description = model.CommunityDescritpion
        };

        _context.Communities.Add(community);
        await _context.SaveChangesAsync();

        var adminMember = new UserCommunity
        {
            UserId = adminId,
            CommunityId = community.Id,
            MemberNumber = 1,
            IsPending = false,
            Role = CommunityRole.Moderator
        };

        _context.UserCommunity.Add(adminMember);
        await _context.SaveChangesAsync();

        return Ok(new
        {
            Message = "Comunidade criada com sucesso e administrador adicionado como primeiro membro!", CommunityId = community.Id
        });
    }


    /// <summary>
    /// Submits a request for the current user to join a specified community.
    /// The user must have a Leitor role to make the request.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community the user wishes to join.</param>
    /// <param name="role">The role that the user requests within the community, which can be Member or Moderator.</param>
    /// <returns>
    /// An IActionResult indicating the outcome of the operation:
    /// - Returns Ok if the request is successfully created.
    /// - Returns NotFound if the user or community is not found.
    /// - Returns Forbid if the requester does not have the appropriate user role.
    /// - Returns BadRequest if there is an existing pending request or if the user is already a community member.
    /// </returns>
    [HttpPost("JoinRequest/{communityId}/{role}")]
    public async Task<IActionResult> JoinCommunityRequest(int communityId, CommunityRole role)
    {
        var userId = _tokenService.GetUserIdByToken();

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return NotFound("Utilizador não encontrado.");

        var community = await _context.Communities.FindAsync(communityId);
        if (community == null)
            return NotFound("Comunidade não encontrada.");

        if (community.IsBlocked)
            return BadRequest("Comunidade bloqueada");
        
        var existingRequest = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId);

        if (user.Role != Role.Leitor)
            return Forbid("Apenas utilizadores do tipo LEITOR podem criar e entrar em comunidades.");

        if (existingRequest != null)
        {
            if (existingRequest.IsPending)
                return BadRequest("Já existe um pedido pendente para esta comunidade.");
            return BadRequest("O utilizador já é membro da comunidade.");
        }

        // Criar um novo pedido de adesão
        var memberRequest = new UserCommunity
        {
            UserId = userId,
            CommunityId = communityId,
            IsPending = true,
            Role = role
        };

        _context.UserCommunity.Add(memberRequest);
        await _context.SaveChangesAsync();

        return Ok("Pedido enviado com sucesso!");
    }


    //ACCEPT REQUEST
    /// <summary>
    /// Accepts a pending join request for a specified community, allowing the user to become a member.
    /// The caller must be a moderator of the community for the request to be accepted.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community where the join request exists.</param>
    /// <param name="userId">The unique identifier of the user whose join request is being accepted.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the join request is successfully accepted and the user becomes a member.
    /// - Returns NotFound if either the community or the pending join request is not found.
    /// - Returns Unauthorized if the authenticated user is not a moderator of the community.
    /// </returns>
    [HttpPost("AcceptJoinRequest/{communityId}/{userId}")]
    public async Task<IActionResult> AcceptJoinRequest(int communityId, int userId)
    {
        var adminId = _tokenService.GetUserIdByToken(); // Obter o ID do utilizador autenticado

        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        // Verificar se o utilizador autenticado é o administrador ou moderador da comunidade
        var userRole = community.Members
            .FirstOrDefault(m => m.UserId == adminId && !m.IsPending)?.Role;

        if (userRole != CommunityRole.Moderator)
            return Unauthorized("Apenas administradores ou moderadores podem aceitar pedidos de adesão.");

        // Verificar se o pedido de adesão do utilizador está pendente
        var joinRequest = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId && uc.IsPending);

        if (joinRequest == null) return NotFound("Pedido de adesão pendente não encontrado para este utilizador.");

        // Determinar o próximo MemberNumber para o novo membro da comunidade
        var nextMemberNumber = await _context.UserCommunity
            .Where(uc => uc.CommunityId == communityId && !uc.IsPending)
            .MaxAsync(uc => (int?)uc.MemberNumber) ?? 0;

        // Atualizar o pedido de adesão para aceito
        joinRequest.IsPending = false;
        joinRequest.MemberNumber = nextMemberNumber + 1;

        await _context.SaveChangesAsync();

        return Ok("Pedido de adesão aceito com sucesso.");
    }

    //REJECT REQUEST
    /// <summary>
    /// Rejects a pending join request for a specified user in a community.
    /// The authenticated user must have the role of Moderator within the community to perform this operation.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community from which the join request should be rejected.</param>
    /// <param name="userId">The unique identifier of the user whose join request is to be rejected.</param>
    /// <returns>
    /// An IActionResult representing the outcome of the operation:
    /// - Returns Ok if the join request is successfully rejected.
    /// - Returns NotFound if the community or pending join request does not exist.
    /// - Returns Unauthorized if the user does not have the required permissions to reject the join request.
    /// </returns>
    [HttpDelete("RejectJoinRequest/{communityId}/{userId}")]
    public async Task<IActionResult> RejectJoinRequest(int communityId, int userId)
    {
        var adminId = _tokenService.GetUserIdByToken(); // Obter o ID do utilizador autenticado

        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        // Verificar se o utilizador autenticado é o administrador ou moderador da comunidade
        var userRole = community.Members
            .FirstOrDefault(m => m.UserId == adminId && !m.IsPending)?.Role;

        if (userRole != CommunityRole.Moderator)
            return Unauthorized("Apenas administradores ou moderadores podem rejeitar pedidos de adesão.");

        // Verificar se o pedido de adesão do utilizador está pendente
        var joinRequest = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId && uc.IsPending);

        if (joinRequest == null) return NotFound("Pedido de adesão pendente não encontrado para este utilizador.");

        // Remover o pedido de adesão
        _context.UserCommunity.Remove(joinRequest);
        await _context.SaveChangesAsync();

        return Ok("Pedido de adesão rejeitado com sucesso.");
    }

    /// <summary>
    /// Retrieves the list of pending join requests for a specified community.
    /// Only the community administrator can perform this operation.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community for which to retrieve pending join requests.</param>
    /// <returns>
    /// An IActionResult containing the result of the operation:
    /// - Returns Ok with a list of pending members if the operation is successful.
    /// - Returns NotFound if the community does not exist.
    /// - Returns Unauthorized if the requester is not the community administrator.
    /// </returns>
    [HttpGet("GetRequests/{communityId}")]
    public async Task<IActionResult> GetJoinCommunityRequest(int communityId)
    {
        var adminId = _tokenService.GetUserIdByToken(); // Obter o ID do utilizador autenticado

        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não foi encontrada.");

        // Verificar se o utilizador autenticado é o administrador da comunidade
        if (community.AdminId != adminId) return Unauthorized("Não tem permissões de administrador.");

        // Obter os membros com pedido pendente
        var pendingMembers = await _context.UserCommunity
            .Where(uc => uc.CommunityId == communityId && uc.IsPending)
            .Include(uc => uc.User) // Incluir os dados do usuário para acesso ao username
            .Select(uc => new
            {
                uc.Id,
                uc.UserId,
                Username = uc.User.Username, // Inclui apenas o username do usuário
                uc.CommunityId,
                uc.MemberNumber,
                uc.IsPending,
                uc.EntryDate,
                uc.Role
            })
            .ToListAsync();

        return Ok(pendingMembers);
    }


    /// <summary>
    /// Removes a member from a specified community based on their member number.
    /// Only moderators are authorized to perform this operation.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community from which to remove the member.</param>
    /// <param name="memberNumber">The member number of the user to be removed from the community.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the member is successfully removed.
    /// - Returns NotFound if the community is not found or the member does not exist in the community.
    /// - Returns Unauthorized if the user does not have the necessary permissions to remove members.
    /// - Returns BadRequest if an attempt is made to remove the community administrator.
    /// </returns>
    [HttpDelete("RemoveMember/{communityId}/{memberNumber}")]
    public async Task<IActionResult> RemoveMember(int communityId, int memberNumber)
    {
        var userId = _tokenService.GetUserIdByToken(); // Obter o ID do utilizador autenticado

        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        // Verificar se o utilizador autenticado é o administrador ou moderador da comunidade
        var userRole = community.Members
            .FirstOrDefault(m => m.UserId == userId && !m.IsPending)?.Role;

        if (userRole != CommunityRole.Moderator)
            return Unauthorized("Apenas administradores ou moderadores podem remover membros.");

        // Verificar se o membro a ser removido existe na comunidade usando o MemberNumber
        var memberToRemove = community.Members.FirstOrDefault(m => m.MemberNumber == memberNumber && !m.IsPending);
        if (memberToRemove == null) return NotFound("Membro não encontrado na comunidade.");

        // Não permitir que o administrador remova a si próprio
        if (community.AdminId == memberToRemove.UserId)
            return BadRequest("O administrador não pode remover a si próprio da comunidade.");

        // Remover o membro
        _context.UserCommunity.Remove(memberToRemove);
        await _context.SaveChangesAsync();

        return Ok("Membro removido com sucesso.");
    }


    /// <summary>
    /// Retrieves a list of all members within a specified community, including their user IDs, usernames, roles, and member numbers.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community for which to list the members.</param>
    /// <returns>
    /// An IActionResult containing the result of the operation:
    /// - Returns Ok with a list of members if the community is found and contains members.
    /// - Returns NotFound if the community does not exist.
    /// </returns>
    [HttpGet("ListCommunityMembers/{communityId}")]
    public async Task<IActionResult> ListCommunityMembers(int communityId)
    {
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        // Usar AsEnumerable() para realizar a segunda parte da seleção no lado do cliente
        var members = community.Members.AsEnumerable().Select(m => new
        {
            m.UserId,
            _context.Users.FirstOrDefault(u => u.Id == m.UserId)?.Username,
            m.Role,
            m.MemberNumber
        }).ToList();

        return Ok(members);
    }


    /// <summary>
    /// Retrieves the member number associated with a specific user's membership in a community.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community to check membership for.</param>
    /// <returns>
    /// An IActionResult containing the result of the operation:
    /// - Returns Ok with the member number if the user is a member of the specified community.
    /// - Returns Unauthorized if the user is not authenticated.
    /// - Returns NotFound if the user's membership association with the community is not found.
    /// </returns>
    [HttpGet("GetUserCommunityId/{communityId}")]
    public async Task<IActionResult> GetUserCommunityId(int communityId)
    {
        var userIdClaim = User.FindFirst("userId");
        if (userIdClaim == null) return Unauthorized("Utilizador não autenticado.");
        var userId = int.Parse(userIdClaim.Value);

        var userCommunity = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId);

        if (userCommunity == null) return NotFound("Associação do utilizador com a comunidade não encontrada.");

        // Retorna o `MemberNumber` em vez de `IdUserCommunity`
        return Ok(new { userCommunity.MemberNumber });
    }


    /// <summary>
    /// Retrieves all posts from a specified community.
    /// Includes each post's content, creation date, and type, along with user data who made the post.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community whose posts are to be retrieved.</param>
    /// <returns>
    /// An IActionResult containing a list of posts if the community exists:
    /// - Returns Ok with a list of posts if the community is found.
    /// - Returns NotFound if the community is not found.
    /// </returns>
    [HttpGet("GetCommunityPosts/{communityId}")]
    public async Task<IActionResult> GetCommunityPosts(int communityId)
    {
        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.Posts)
            .ThenInclude(p => p.User) // Incluir os dados do utilizador que fez a publicação
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        // Retornar lista de publicações com campos adicionais
        var posts = community.Posts.Select(p => new
        {
            ID_Post = p.Id,
            Conteudo = p.Conteudo,
            Data_Criacao = p.DataCriacao,
            Tipo = p.TipoPublicacao,
            Username = p.User.Username, // Nome do autor do post
            CommunityName = community.Name, // Nome da comunidade
            NumberOfReactions = _context.PostReactions.Count(r => r.PostId == p.Id), // Contar reações do post
            NumberOfComments = _context.Comments.Count(c => c.PostId == p.Id),       // Contar comentários do post
            //NumberOfReposts = _context.PostReposts.Count(r => r.PostId == p.Id)     // Contar reposts do post
        }).ToList();

        return Ok(posts);
    }


    /// <summary>
    /// Deletes all posts associated with a specific topic within a community.
    /// The caller must be a community administrator or moderator.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community where the posts are located.</param>
    /// <param name="topicId">The unique identifier of the topic whose posts need to be deleted.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the posts are successfully deleted.
    /// - Returns NotFound if the community is not found.
    /// - Returns Unauthorized if the user does not have the necessary permissions.
    /// </returns>
    [HttpDelete("DeletePostsByTopic/{communityId}/{topicId}")]
    public async Task<IActionResult> DeletePostsByTopic(int communityId, int topicId)
    {
        var userId = _tokenService.GetUserIdByToken(); // Obter ID do utilizador autenticado

        // Verificar se o utilizador é administrador ou moderador da comunidade
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null) return NotFound("Comunidade não encontrada.");

        var userRole = community.Members
            .FirstOrDefault(m => m.UserId == userId && !m.IsPending)?.Role;

        if (userRole != CommunityRole.Moderator)
            return Unauthorized("Apenas administradores ou moderadores podem excluir posts.");

        // Encontrar e excluir todos os posts associados ao tópico
        var postsToDelete = await _context.Posts
            .Where(p => p.CommunityId == communityId && p.TopicId == topicId)
            .ToListAsync();

        if (postsToDelete.Any())
        {
            _context.Posts.RemoveRange(postsToDelete);
            await _context.SaveChangesAsync();
        }

        return Ok("Posts do tópico selecionado foram excluídos.");
    }

    /// <summary>
    /// Toggles the blocked status of a topic within a community.
    /// Only users with the role of Moderator or higher can perform this action.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community containing the topic.</param>
    /// <param name="topicId">The unique identifier of the topic to have its status toggled.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the topic status is successfully toggled.
    /// - Returns Unauthorized if the user is not a moderator or higher in the community.
    /// - Returns NotFound if the topic is not found within the specified community.
    /// </returns>
    [HttpPost("ToggleTopicStatus/{communityId}/{topicId}")]
    public async Task<IActionResult> ToggleTopicStatus(int communityId, int topicId)
    {
        var userId = _tokenService.GetUserIdByToken();

        // Verificar se o utilizador é administrador ou moderador da comunidade
        var isAdminOrModerator = await _context.UserCommunity
            .AnyAsync(uc => uc.UserId == userId && uc.CommunityId == communityId && uc.Role == CommunityRole.Moderator);

        if (!isAdminOrModerator)
            return Unauthorized("Apenas administradores ou moderadores podem bloquear/desbloquear tópicos.");

        // Encontrar a relação entre comunidade e tópico
        var communityTopic = await _context.CommunityTopics
            .FirstOrDefaultAsync(ct => ct.CommunityId == communityId && ct.TopicId == topicId);

        if (communityTopic == null) return NotFound("Tópico não encontrado na comunidade.");

        // Alterar o status de bloqueio do tópico
        communityTopic.IsBlocked = !communityTopic.IsBlocked;
        await _context.SaveChangesAsync();

        return Ok($"Tópico {(communityTopic.IsBlocked ? "bloqueado" : "desbloqueado")} com sucesso para a comunidade.");
    }


    // Endpoint para excluir um post específico
    /// <summary>
    /// Deletes a specific post from the community. Only users with the role of
    /// Moderator are authorized to perform this action.
    /// </summary>
    /// <param name="communityId">The identifier of the community from which the post should be deleted.</param>
    /// <param name="postId">The identifier of the post to be deleted.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the post is deleted successfully.
    /// - Returns NotFound if the community or post could not be found.
    /// - Returns Unauthorized if the user does not have the necessary permissions.
    /// </returns>
    [HttpDelete("DeletePost/{communityId}/{postId}")]
    public async Task<IActionResult> DeletePost(int communityId, int postId)
    {
        var userId = _tokenService.GetUserIdByToken(); // Obter ID do utilizador autenticado

        // Verificar se o utilizador é administrador ou moderador da comunidade
        var community = await _context.Communities
            .Include(c => c.Members)
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null)
            return NotFound("Comunidade não encontrada.");

        var userRole = community.Members
            .FirstOrDefault(m => m.UserId == userId && !m.IsPending)?.Role;

        if (userRole != CommunityRole.Moderator)
            return Unauthorized("Apenas administradores ou moderadores podem excluir posts.");

        // Procurar o post a ser excluído
        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == postId && p.CommunityId == communityId);

        if (post == null)
            return NotFound("Post não encontrado na comunidade.");

        // Excluir o post
        _context.Posts.Remove(post);
        await _context.SaveChangesAsync();

        return Ok("Post excluído com sucesso.");
    }
    
    [HttpGet("RecommendedCommunities")]
    public async Task<IActionResult> GetRecommendedCommunities()
    {
        var userId = 0;
        try
        {
            userId = _tokenService.GetUserIdByToken();
        }
        catch (UnauthorizedAccessException)
        {
        }

        var communities = await _context.Communities
            .Include(c => c.Members)
            .ThenInclude(uc => uc.User)
            .Where(c => c.Members.All(m => m.UserId != userId))
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.Description,
                MemberCount = c.Members.Count(),
                ProfilePicture = c.ProfilePictureUrl,
                MemberImages = c.Members
                    .Take(4)
                    .Select(m => m.User.ProfilePictureUrl)
                    .ToList()

            })
            .OrderByDescending(c => c.MemberCount)
            .ToListAsync();

        return Ok(communities);
    }

    /// <summary>
    /// Creates a new topic within a specified community. If the topic already exists, it will be associated with the community.
    /// The topic's name is required and should be unique within the context of this creation operation.
    /// </summary>
    /// <param name="communityId">The identifier of the community where the topic will be created or associated.</param>
    /// <param name="topicName">The name of the topic to be created. This is a required parameter.</param>
    /// <returns>
    /// An IActionResult indicating the outcome of the creation process:
    /// - Returns Ok with a success message if the topic is created and associated successfully.
    /// - Returns BadRequest if the topic name is missing or empty.
    /// - Returns NotFound if the specified community does not exist.
    /// </returns>
    [HttpPost("UploadCommunityPhoto/{communityId}")]
    public async Task<IActionResult> UploadCommunityPhoto(int communityId, [FromForm] IFormFile file)
    {
        try
        {
            // Verificar se o arquivo é válido
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { Message = "Nenhum arquivo foi enviado ou o arquivo é inválido." });
            }

            // Buscar a comunidade no banco de dados
            var community = await _context.Communities.FindAsync(communityId);
            if (community == null)
            {
                return NotFound(new { Message = "Comunidade não encontrada." });
            }

            // Gerar o nome do arquivo para armazenar no S3
            var fileName = $"community_photos/{communityId}/{Guid.NewGuid()}_{file.FileName}";

            // Fazer o upload para o S3
            using (var stream = file.OpenReadStream())
            {
                var fileUrl = await _s3Service.UploadFileAsync(stream, fileName, file.ContentType);

                // Atualizar o URL da foto na comunidade
                community.ProfilePictureUrl = fileUrl;
                await _context.SaveChangesAsync();

                // Retornar sucesso com o URL da imagem
                return Ok(new { ProfilePictureUrl = fileUrl });
            }
        }
        catch (AmazonS3Exception ex)
        {
            // Erro específico do AWS S3
            Console.WriteLine($"Erro ao fazer upload para o S3: {ex.Message}");
            return StatusCode(500, new { Message = "Erro ao salvar arquivo no AWS S3.", Details = ex.Message });
        }
        catch (Exception ex)
        {
            // Erro genérico
            Console.WriteLine($"Erro interno: {ex.Message}");
            return StatusCode(500, new { Message = "Erro interno no servidor.", Details = ex.Message });
        }
    }



    [HttpGet("GetCommunityTopics/{communityId}")]
    public async Task<IActionResult> GetCommunityTopics(int communityId)
    {
        // Verificar se a comunidade existe
        var community = await _context.Communities
            .Include(c => c.CommunityTopics) // Inclui os tópicos associados à comunidade
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null)
        {
            return NotFound("Comunidade não encontrada.");
        }

        // Obter os tópicos da comunidade com o status bloqueado/desbloqueado
        var topics = await _context.CommunityTopics
            .Where(ct => ct.CommunityId == communityId)
            .Select(ct => new
            {
                ct.Topic.Id,
                ct.Topic.Name,
                ct.IsBlocked
            })
            .ToListAsync();

        return Ok(topics);
    }
    [HttpGet("GetCommunityDetails/{communityId}")]
    public async Task<IActionResult> GetCommunityDetails(int communityId)
    {
        var community = await _context.Communities
            .Include(c => c.Members)  // Inclui os membros da comunidade
            .ThenInclude(uc => uc.User) // Incluir dados do usuário
            .FirstOrDefaultAsync(c => c.Id == communityId);

        if (community == null)
            return NotFound("Comunidade não encontrada.");

        // Contar membros válidos (não pendentes)
        var memberCount = community.Members.Count(uc => !uc.IsPending);

        // Verificar se o usuário está na comunidade
        var userId = _tokenService.GetUserIdByToken();
        var userInCommunity = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId);

        // Definir URL padrão para ProfilePictureUrl caso seja null
        var defaultProfilePictureUrl = "https://example.com/default-profile-picture.png";
        var profilePictureUrl = string.IsNullOrEmpty(community.ProfilePictureUrl)
            ? defaultProfilePictureUrl
            : community.ProfilePictureUrl;

        var response = new
        {
            community.Id,
            community.Name,
            community.Description,
            ProfilePictureUrl = profilePictureUrl,
            memberCount,
            isMember = userInCommunity != null && !userInCommunity.IsPending,
            isPending = userInCommunity?.IsPending ?? false
        };

        return Ok(response);
    }



    [HttpDelete("LeaveCommunity/{communityId}")]
    public async Task<IActionResult> LeaveCommunity(int communityId)
    {
        var userId = _tokenService.GetUserIdByToken(); // Obtém o ID do utilizador autenticado

        // Verifica se a associação entre o utilizador e a comunidade existe
        var userCommunity = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId);

        if (userCommunity == null)
        {
            return NotFound("O utilizador não pertence a esta comunidade ou a comunidade não existe.");
        }

        // Não permite que o administrador saia da comunidade
        var community = await _context.Communities.FindAsync(communityId);
        if (community == null) return NotFound("Comunidade não encontrada.");

        if (community.AdminId == userId)
        {
            return BadRequest("O administrador não pode sair da comunidade.");
        }

        // Remove o utilizador da comunidade
        _context.UserCommunity.Remove(userCommunity);
        await _context.SaveChangesAsync();

        return Ok("Saiu da comunidade com sucesso.");
    }



    [HttpPost("CreateTopic")]
    public async Task<IActionResult> CreateTopic(int communityId, [FromBody] string topicName)
    {
        if (string.IsNullOrEmpty(topicName)) return BadRequest("O nome do tópico é obrigatório.");

        // Verificar se a comunidade existe
        var community = await _context.Communities.FindAsync(communityId);
        if (community == null) return NotFound("Comunidade não encontrada.");

        if (community.IsBlocked)
            return BadRequest("Comunidade bloqueada");
        
        // Verificar se o tópico já existe
        var existingTopic = await _context.Topics.FirstOrDefaultAsync(t => t.Name == topicName);
        if (existingTopic == null)
        {
            // Se o tópico ainda não existe cria um novo
            existingTopic = new Topic { Name = topicName };
            _context.Topics.Add(existingTopic);
            await _context.SaveChangesAsync();
        }

        // Criar uma associação entre o tópico e a comunidade com o `IsBlocked` padrão (desbloqueado)
        var communityTopic = new CommunityTopic
        {
            CommunityId = communityId,
            TopicId = existingTopic.Id,
            IsBlocked = false
        };

        _context.CommunityTopics.Add(communityTopic);
        await _context.SaveChangesAsync();

        return Ok($"Tópico '{topicName}' criado e associado à comunidade com sucesso.");
    }

    [HttpGet("GetUserCommunities")]
    public async Task<IActionResult> GetUserCommunities()
    {
        var userId = _tokenService.GetUserIdByToken();

        var communities = await _context.UserCommunity
            .Where(uc => uc.UserId == userId && !uc.IsPending)
            .Select(uc => new
            {
                id = uc.Community.Id, // Renomeie para 'id' no JSON
                name = uc.Community.Name,
                description = uc.Community.Description,
                adminId = uc.Community.AdminId
            })
            .ToListAsync();

        return Ok(communities);
    }

    [HttpGet("IsUserMember/{communityId}")]
    public async Task<IActionResult> IsUserMember(int communityId)
    {
        // Aqui, você pode obter o ID do usuário da requisição
        var userId = _tokenService.GetUserIdByToken();
        try
        {
            var isMember = await IsUserMemberAsync(userId, communityId);

            return Ok(new { isMember });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Erro ao verificar a adesão do usuário.", error = ex.Message });
        }
    }
    private async Task<bool> IsUserMemberAsync(int userId, int communityId)
    {
        var membership = await _context.UserCommunity
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.CommunityId == communityId);

        return membership != null;
    }


    [HttpGet("GetUserOwnedCommunities")]
    public async Task<IActionResult> GetUserOwnedCommunities()
    {
        // Obter o ID do usuário a partir do token
        var userId = _tokenService.GetUserIdByToken();

        // Verificar se o usuário existe
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return NotFound("Utilizador não encontrado.");

        // Buscar comunidades onde o usuário é o proprietário
        var ownedCommunities = await _context.Communities
            .Where(c => c.AdminId == userId)
            .ToListAsync();

        // Retornar a lista de comunidades
        return Ok(ownedCommunities.Select(c => new
        {
            c.Id,
            c.Name,
            c.Description,
            c.ProfilePictureUrl,
        }));
    }



        /// <summary>
    /// Checks whether a specified community is currently blocked.
    /// Only accessible by users with the Admin role.
    /// </summary>
    /// <param name="communityId">The unique identifier of the community to be checked.</param>
    /// <returns>
    /// A boolean value indicating the blocked status of the community:
    /// - Returns true if the community is blocked.
    /// - Returns false if the community is not blocked or does not exist.
    /// </returns>
    [Authorize(Roles = "Admin")]
    [HttpGet("{communityId}/is-blocked")]
    public async Task<bool> IsCommunityBlocked(int communityId)
    {
        var community = await _context.Communities.FindAsync(communityId);
        return community != null && community.IsBlocked;
    }

    /// <summary>
    /// Blocks a specific community identified by the given community ID.
    /// This operation is restricted to users with the Admin role.
    /// </summary>
    /// <param name="communityId">The identifier of the community to be blocked.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the community is successfully blocked.
    /// - Returns NotFound if the community with the given ID does not exist.
    /// </returns>
    [Authorize(Roles = "Admin")]
    [HttpPost("{communityId}/block")]
    public async Task<IActionResult> BlockCommunity(int communityId)
    {
        var community = await _context.Communities.FindAsync(communityId);
        if (community == null) return NotFound("Comunidade nao encontrada.");
        community.IsBlocked = true;
        await _context.SaveChangesAsync();
        return Ok("Comunidade bloqueada com sucesso.");
    }

    /// <summary>
    /// Unblocks a previously blocked community identified by the given community ID.
    /// Only accessible to users with the Admin role.
    /// </summary>
    /// <param name="communityId">The ID of the community to unblock.</param>
    /// <returns>
    /// An IActionResult indicating the result of the operation:
    /// - Returns Ok if the community is successfully unblocked.
    /// - Returns NotFound if the specified community is not found.
    /// </returns>
    [Authorize(Roles = "Admin")]
    [HttpPost("{communityId}/unblock")]
    public async Task<IActionResult> UnblockCommunity(int communityId)
    {
        var community = await _context.Communities.FindAsync(communityId);
        if (community == null) return NotFound("Comunidade nao encontrada.");
        community.IsBlocked = false;
        await _context.SaveChangesAsync();
        return Ok("Comunidade desbloqueada com sucesso.");
    }

}