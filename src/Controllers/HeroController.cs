using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using tour_of_heroes_api.Models;
using System.Linq;

namespace tour_of_heroes_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HeroController : ControllerBase
    {

        private IHeroRepository _heroRepository;
        public HeroController(IHeroRepository heroRepository)
        {
            _heroRepository = heroRepository;
        }

        // GET: api/Hero
        [HttpGet]
        public ActionResult<IEnumerable<Hero>> GetHeroes()
        {
            var heroes = _heroRepository.GetAll();
            return Ok(heroes);
        }

        // GET: api/Hero/5
        [HttpGet("{id}")]
        public ActionResult<Hero> GetHero(int id)
        {
            var hero = _heroRepository.GetById(id);

            if (hero == null)
            {
                return NotFound();
            }

            return Ok(hero);
        }

        // PUT: api/Hero/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public ActionResult PutHero(int id, Hero hero)
        {

            var heroToUpdate = _heroRepository.GetById(id);

            if (heroToUpdate == null)
            {
                return NotFound();
            }

            heroToUpdate.Name = hero.Name;
            heroToUpdate.AlterEgo = hero.AlterEgo;
            heroToUpdate.Description = hero.Description;

            _heroRepository.Update(heroToUpdate);

            return NoContent();

        }

        // POST: api/Hero
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public ActionResult<Hero> PostHero(Hero hero)
        {
            if (hero == null)
            {
                return BadRequest("Hero cannot be null.");
            }

            try
            {
                _heroRepository.Add(hero);
                return CreatedAtAction(nameof(GetHero), new { id = hero.Id }, hero);
            }
            catch (Exception ex)
            {
                // Log the exception (ex) here if necessary
                return StatusCode(500, "Internal server error");
            }
        }

        // DELETE: api/Hero/5
        [HttpDelete("{id}")]
        public IActionResult DeleteHero(int id)
        {
            _heroRepository.Delete(id);

            return NoContent();
        }
    }
}
