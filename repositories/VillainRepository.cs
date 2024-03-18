using tour_of_heroes_api.Models;
using tour_of_heroes_api.Interfaces;


public class VillainRepository : IVillainRepository
{
    private readonly HeroContext _context;

    public VillainRepository(HeroContext context)
    {
        _context = context;
    }

    public void Add(Villain villain)
    {
        _context.Villains.Add(villain);
        _context.SaveChanges();
    }

    public void Delete(Villain villain)
    {
        _context.Villains.Remove(villain);
        _context.SaveChanges();
    }

    public IEnumerable<Villain> GetAll()
    {
        return _context.Villains.ToList();
    }

    public Villain GetById(int id)
    {
        return _context.Villains.FirstOrDefault(v => v.Id == id);
    }

    public void Update(Villain villain)
    {
        _context.Villains.Update(villain);
        _context.SaveChanges();
    }
}