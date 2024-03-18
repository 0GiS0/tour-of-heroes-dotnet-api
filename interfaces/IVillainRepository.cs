
using tour_of_heroes_api.Models;

namespace tour_of_heroes_api.Interfaces;
public interface IVillainRepository
{
    IEnumerable<Villain> GetAll();
    Villain GetById(int id);
    void Add(Villain villain);
    void Update(Villain villain);
    void Delete(Villain villain);
}