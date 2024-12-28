using System.Collections.Generic;
using tour_of_heroes_api.Models;

/// <summary>
/// Represents a repository for managing heroes.
/// </summary>
public interface IHeroRepository
{
    /// <summary>
    /// Retrieves all heroes.
    /// </summary>
    /// <returns>An enumerable collection of heroes.</returns>
    IEnumerable<Hero> GetAll();

    /// <summary>
    /// Retrieves a hero by its ID.
    /// </summary>
    /// <param name="id">The ID of the hero.</param>
    /// <returns>The hero with the specified ID.</returns>
    Hero? GetById(int id);

    /// <summary>
    /// Adds a new hero.
    /// </summary>
    /// <param name="hero">The hero to add.</param>
    void Add(Hero hero);

    /// <summary>
    /// Updates an existing hero.
    /// </summary>
    /// <param name="hero">The hero to update.</param>
    void Update(Hero hero);

    /// <summary>
    /// Deletes a hero by its ID.
    /// </summary>
    /// <param name="id">The ID of the hero to delete.</param>
    void Delete(int id);
}