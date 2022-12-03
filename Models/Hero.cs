using System.ComponentModel.DataAnnotations;

namespace tour_of_heroes_api.Models
{
    public class Hero
    {
        [Key]
        public int HeroId { get; set; }
        public string Name { get; set; }
        public string AlterEgo { get; set; }
        public string Description { get; set; }
    }
}
