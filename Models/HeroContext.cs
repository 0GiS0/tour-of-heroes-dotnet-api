using Microsoft.EntityFrameworkCore;

namespace tour_of_heroes_api.Models
{
    public class HeroContext : DbContext
    {
        public HeroContext(DbContextOptions<HeroContext> options) : base(options)
        {
            Database.EnsureCreated();
        }
        public DbSet<Hero> Heroes { get; set; }
    }
}