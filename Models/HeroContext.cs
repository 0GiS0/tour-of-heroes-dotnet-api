using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using tour_of_heroes_api.Models;


namespace tour_of_heroes_api.Models
{
    public class HeroContext : DbContext
    {
        public HeroContext(DbContextOptions<HeroContext> options) : base(options)
        {
        }

        public DbSet<Hero> Heroes { get; set; }
    }
}
