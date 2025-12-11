﻿using Microsoft.EntityFrameworkCore;
using Read.er.Models;
using Read.er.Interfaces;
using Read.er.Models.Book;
using Read.er.Models.Communities;
using Read.er.Models.Posts;
using Read.er.Models.SaleTrades;
using Read.er.Models.Users;
using Read.er.Models.SaleTrades;

namespace Read.er.Data
{
    /// <summary>
    /// AppDbContext is the primary class responsible for interacting with the underlying
    /// database using Entity Framework Core. It defines DbSet properties for various
    /// entities representing tables within the database, such as PersonalLibrary, Wishlist,
    /// User, Post, WriterBook, Community, and more. The class facilitates CRUD operations
    /// across these tables and manages the database connection.
    /// </summary>
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<PersonalLibrary> PersonalLibraries { get; set; }
        public DbSet<Wishlist> Wishlists { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Post> Posts { get; set; }
        public DbSet<WriterBook> WriterBooks { get; set; }
        public DbSet<Community> Communities { get; set; }
        public DbSet<UserCommunity> UserCommunity { get; set; }
        public DbSet<Topic> Topics { get; set; }
        public DbSet<CommunityTopic> CommunityTopics { get; set; }
        public DbSet<PostReaction> PostReactions { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<UserFriendship> UserFriendship { get; set; }
        public DbSet<SaleTrade> SaleTrades { get; set; }
        public DbSet<SaleTradeOffer> SaleTradeOffers { get; set; }
        public DbSet<CompletedSaleTrade> CompletedSaleTrades { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<BookReview> BookReviews { get; set; }
        public DbSet<SaleTradeReview> SaleTradeReviews { get; set; }
        public DbSet<CacheBook> CachedBooks { get; set; }
        public DbSet<ReadingGoal> ReadingGoals { get; set; }
        public DbSet<FollowAuthors> FollowAuthors { get; set; }


        /// <summary>
        /// Configures the model relationships and keys for the database context during model creation.
        /// </summary>
        /// <param name="modelBuilder">
        /// The builder being used to construct the model for the context. It allows configuration of entity properties, keys,
        /// relationships, and much more by using a fluent API.
        /// </param>
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<PersonalLibrary>()
                .HasKey(pl => new { pl.UserId, pl.Isbn });

            modelBuilder.Entity<Wishlist>()
                .HasKey(w => new { w.UserId, w.SaleTradeId });

            modelBuilder.Entity<Post>()
               .HasOne(p => p.User)
               .WithMany(u => u.Posts)
               .HasForeignKey(p => p.IdUser);

            modelBuilder.Entity<User>()
                .HasKey(u => u.Id);
            modelBuilder.Entity<Community>()
                .HasKey(c => c.Id);

            modelBuilder.Entity<UserCommunity>()
                .HasKey(uc => uc.Id);

            modelBuilder.Entity<CommunityTopic>()
                .HasOne(ct => ct.Community)
                .WithMany(c => c.CommunityTopics)
                .HasForeignKey(ct => ct.CommunityId);

            modelBuilder.Entity<CommunityTopic>()
                .HasOne(ct => ct.Topic)
                .WithMany(t => t.CommunityTopics)
                .HasForeignKey(ct => ct.TopicId);

            modelBuilder.Entity<UserFriendship>()
                .HasKey(uf => new { uf.RequesterId, uf.ReceiverId });

            modelBuilder.Entity<UserFriendship>()
                .HasOne(uf => uf.Requester)
                .WithMany(u => u.SentFriendRequests)
                .HasForeignKey(uf => uf.RequesterId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<UserFriendship>()
                .HasOne(uf => uf.Receiver)
                .WithMany(u => u.ReceivedFriendRequests)
                .HasForeignKey(uf => uf.ReceiverId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<FollowAuthors>()
                .HasKey(fa => new { fa.UserId, fa.AuthorId });

            modelBuilder.Entity<FollowAuthors>()
                .HasOne(fa => fa.Leitor)
                .WithMany(u => u.Following)
                .HasForeignKey(fa => fa.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<FollowAuthors>()
                .HasOne(fa => fa.Author)
                .WithMany(u => u.Followers)
                .HasForeignKey(fa => fa.AuthorId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<SaleTradeOffer>()
                .HasKey(sto => sto.IdOffer);

            modelBuilder.Entity<SaleTradeOffer>()
                .HasIndex(sto => new { sto.IdUser, sto.IdSaleTrade })
                .IsUnique();

            modelBuilder.Entity<SaleTradeOffer>()
                .HasOne(sto => sto.SaleTrade)
                .WithMany(st => st.Offers)
                .HasForeignKey(sto => sto.IdSaleTrade)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<BookReview>()
                .HasOne(br => br.User)
                .WithMany(u => u.BookReviews)
                .HasForeignKey(br => br.UserId)
                .OnDelete(DeleteBehavior.Cascade);


            modelBuilder.Entity<SaleTradeReview>()
                .HasOne(r => r.TradeOffer)
                .WithMany()
                .HasForeignKey(r => r.TradeOfferId)
                .OnDelete(DeleteBehavior.Cascade); // Configura o comportamento de exclusão



            base.OnModelCreating(modelBuilder);
        }
    }
}
