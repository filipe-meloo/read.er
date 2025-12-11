using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.WebSockets;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Read.er.Data;
using Read.er.Interfaces;
using Read.er.Models;
using Read.er.Models.SaleTrades;
using Read.er.Services;
using TokenService = Read.er.Services.TokenService;

var builder = WebApplication.CreateBuilder(args);
var config = builder.Configuration;

// Adicionar serviços ao contêiner
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Adicionar GoogleBooksService e NotificationService
builder.Services.AddSingleton<GoogleBooksService>();
builder.Services.AddScoped<IGoogleBooksService, GoogleBooksService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
// Em Program.cs ou Startup.cs
builder.Services.AddScoped<LibraryService>();
builder.Services.AddScoped<ILibraryService, LibraryService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddSingleton<S3Service>();
// Bind as configurações do AWS para o modelo S3Settings
builder.Services.Configure<S3Settings>(builder.Configuration.GetSection("AWS"));

// Adicionar configuração do Stripe
builder.Services.Configure<StripeSettings>(builder.Configuration.GetSection("Stripe"));


builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Insira o token JWT com 'Bearer' antes. Exemplo: 'Bearer {token}'",
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] { }
        }
    });
});

// Configuração de leitura de appsettings
builder.Configuration
    .AddJsonFile("appsettings.json", false, true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", true, true)
    .AddJsonFile("appsettings.secret.json", true, true)
    .AddEnvironmentVariables();

// Configuração do DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    var serverVersion = ServerVersion.AutoDetect(connectionString);
    options.UseMySql(connectionString, serverVersion);
});

// Configuração de autenticação JWT
builder.Services.AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
        };

        // Evento para verificar se o usuário está ativo
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userService = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var userId = int.Parse(context.Principal.FindFirst("userId").Value);
                var user = await userService.Users.FindAsync(userId);

                if (user == null || !user.IsActive) context.Fail("A conta está desativada.");
            }
        };
    });

// Adicionar o RecommendationService
builder.Services.AddScoped<RecommendationService>();

// Leia o caminho do modelo do appsettings.json e configure o EmbeddingService
var modelPath = builder.Configuration["ModelPath"];
builder.Services.AddScoped<EmbeddingService>(provider => new EmbeddingService(modelPath));

// Configuração do JSON para enumerações
builder.Services.AddControllers()
    .AddJsonOptions(options => { options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()); });

builder.Services.AddWebSockets(options => { options.KeepAliveInterval = TimeSpan.FromSeconds(120); });

builder.Services.AddHttpClient();
builder.Services.AddSingleton<WsManager>();

var app = builder.Build();

// Configuração do pipeline de solicitações HTTP
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "API v1");
        c.RoutePrefix = string.Empty;
        c.DefaultModelsExpandDepth(-1);
    });
}

app.UseCors(builder =>
    builder.AllowAnyOrigin()
        .AllowAnyMethod()
        .AllowAnyHeader());

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.UseWebSockets();

try
{
    app.Run();
}
catch (Exception ex)
{
    Console.WriteLine($"Erro ao executar a aplicação: {ex.Message}");
    throw;
}