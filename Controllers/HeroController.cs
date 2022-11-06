using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using tour_of_heroes_api.Models;
using Dapr.Client;
using System.Collections.Generic;

namespace tour_of_heroes_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HeroController : ControllerBase
    {
        private readonly HeroContext _context;
        private DaprClient _client;
        string DAPR_STORE_NAME = "statestore";

        public HeroController(HeroContext context, DaprClient client)
        {
            _context = context;
            _client = client;
        }

        // GET: api/Hero
        [HttpGet]
        public async Task<IEnumerable<Hero>> GetHeroes()
        {

            // return await _context.Heroes.ToListAsync();           

            var heroes = await _client.GetStateAsync<List<Hero>>(DAPR_STORE_NAME, "heroes");

            if (heroes == null)
            {

                heroes = await UpdateCache();
            }

            return heroes;
        }

        // GET: api/Hero/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Hero>> GetHero(int id)
        {
            var hero = await _context.Heroes.FindAsync(id);

            if (hero == null)
            {
                return NotFound();
            }

            return hero;
        }

        // PUT: api/Hero/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutHero(int id, Hero hero)
        {
            if (id != hero.Id)
            {
                return BadRequest();
            }

            _context.Entry(hero).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!HeroExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // POST: api/Hero
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public async Task<ActionResult<Hero>> PostHero(Hero hero)
        {
            // _context.Heroes.Add(hero);
            // await _context.SaveChangesAsync();

            using var client = new DaprClientBuilder().Build();

            await client.SaveStateAsync(DAPR_STORE_NAME, "heroes", hero);

            return CreatedAtAction(nameof(GetHero), new { id = hero.Id }, hero);
        }

        // DELETE: api/Hero/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteHero(int id)
        {
            var hero = await _context.Heroes.FindAsync(id);
            if (hero == null)
            {
                return NotFound();
            }

            _context.Heroes.Remove(hero);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool HeroExists(int id)
        {
            return _context.Heroes.Any(e => e.Id == id);
        }

        private async Task<List<Hero>> UpdateCache()
        {
            var heroes = await _context.Heroes.ToListAsync();

            await _client.SaveStateAsync<List<Hero>>(DAPR_STORE_NAME, "heroes", heroes);

            return heroes;
        }
    }
}
