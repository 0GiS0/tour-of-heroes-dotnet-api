using System.Collections.Generic;
using System.Linq;
using tour_of_heroes_api.Models;
using tour_of_heroes_api.Interfaces;

namespace tour_of_heroes_api.Repositories;

public class HeroRepository : IHeroRepository
{
    private readonly HeroContext _context;
    public HeroRepository(HeroContext context) => _context = context;

    public IEnumerable<Hero> GetAll() => _context.Heroes.ToList();

    public Hero? GetById(int id) => _context.Heroes.FirstOrDefault(h => h.Id == id);

    public void Add(Hero hero)
    {
        _context.Heroes.Add(hero);
        _context.SaveChanges();
    }

    public void Delete(int id)
    {
        var hero = GetById(id);

        if (hero == null) return;        

        _context.Heroes.Remove(hero);
        _context.SaveChanges();
    }

    public void Update(Hero hero)
    {
        _context.Heroes.Update(hero);
        _context.SaveChanges();
    }
}