using System.ComponentModel.DataAnnotations;

namespace tour_of_heroes_api.Models
{
    /// <summary>
    /// Represents a hero in the Tour of Heroes application.
    /// </summary>
    public class Hero
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="Hero"/> class with the specified name and alter ego.
        /// </summary>
        /// <param name="Name">The name of the hero.</param>
        /// <param name="AlterEgo">The alter ego of the hero.</param>
        public Hero(string Name, string AlterEgo)
        {
            this.Name = Name;
            this.AlterEgo = AlterEgo;
        }

        /// <summary>
        /// Gets or sets the ID of the hero.
        /// </summary>
        [Key]
        public int Id { get; set; }

        /// <summary>
        /// Gets or sets the name of the hero.
        /// </summary>
        [Required]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets the alter ego of the hero.
        /// </summary>
        [Required]
        public string AlterEgo { get; set; }

        /// <summary>
        /// Gets or sets the description of the hero.
        /// </summary>
        public string? Description { get; set; }
    }
}