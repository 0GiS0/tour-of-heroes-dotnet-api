using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using tour_of_heroes_api.Interfaces;
using tour_of_heroes_api.Models;

namespace tour_of_heroes_api.Controllers
{
    public class VillainController : ControllerBase
    {
        private IVillainRepository _villainRepository;
        public VillainController(IVillainRepository villainRepository)
        {
            _villainRepository = villainRepository;
        }

        // GET: api/Villain
        [HttpGet]
        public ActionResult<IEnumerable<Villain>> GetVillains()
        {
            var villains = _villainRepository.GetAll();
            return Ok(villains);
        }

        // GET: api/Villain/5
        [HttpGet("{id}")]
        public ActionResult<Villain> GetVillain(int id)
        {
            var villain = _villainRepository.GetById(id);

            if (villain == null)
            {
                return NotFound();
            }

            return Ok(villain);
        }

        // PUT: api/Villain/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public ActionResult PutVillain(int id, Villain villain)
        {

            var villainToUpdate = _villainRepository.GetById(id);

            if (villainToUpdate == null)
            {
                return NotFound();
            }

            villainToUpdate.Name = villain.Name;
            villainToUpdate.AlterEgo = villain.AlterEgo;
            villainToUpdate.Description = villain.Description;

            _villainRepository.Update(villainToUpdate);

            return NoContent();

        }

        // POST: api/Villain
        [HttpPost]
        public ActionResult<Villain> PostVillain(Villain villain)
        {
            _villainRepository.Add(villain);
            return CreatedAtAction("GetVillain", new { id = villain.Id }, villain);
        }

        // DELETE: api/Villain/5
        [HttpDelete("{id}")]
        public ActionResult<Villain> DeleteVillain(int id)
        {
            var villain = _villainRepository.GetById(id);
            if (villain == null)
            {
                return NotFound();
            }

            _villainRepository.Delete(villain);

            return NoContent();
        }
    }
}