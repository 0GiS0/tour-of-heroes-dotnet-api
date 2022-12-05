using System.ComponentModel.DataAnnotations;

namespace tour_of_heroes_api.Models
{
    public class Villain
    {
        [Key]
        public int VillainId { get; set; }
        [Required]
        public string Name { get; set; }
        public int HeroId { get; set; }
        public Hero? Hero { get; set; }
        public string Description { get; set; }
    }
}
