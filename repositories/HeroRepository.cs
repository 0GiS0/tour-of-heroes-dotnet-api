using System.Collections.Generic;
using tour_of_heroes_api.Models;
using System.Linq;

public class HeroRepository : IHeroRepository
{
    private readonly HeroContext _context;
    public HeroRepository(HeroContext context) => _context = context;

    public IEnumerable<Hero> GetAll() => _context.Heroes.ToList();

    public Hero GetById(int id) => _context.Heroes.FirstOrDefault(h => h.Id == id);

    public void Add(Hero hero)
    {
        _context.Heroes.Add(hero);
        _context.SaveChanges();
    }

    public void Delete(int id)
    {
        _context.Heroes.Remove(GetById(id));
        _context.SaveChanges();
    }

    public void Update(Hero hero)
    {
        _context.Heroes.Update(hero);
        _context.SaveChanges();
    }
}